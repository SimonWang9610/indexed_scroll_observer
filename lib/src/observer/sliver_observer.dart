import 'package:flutter/rendering.dart';
import 'package:positioned_scroll_observer/src/observer/layout_observer.dart';
import 'package:positioned_scroll_observer/src/observer/observer_interface.dart';

import 'scroll_extent.dart';
import 'onstage_strategy.dart';
import 'item_estimation.dart';
import 'util.dart';

abstract class SliverScrollObserver extends LayoutObserver<RenderSliver>
    with ObserverScrollInterface, ObserverScrollImpl {
  @override
  bool get hasMultiChild =>
      super.hasMultiChild && this is MultiChildSliverObserver;

  @override
  bool get renderVisible =>
      isActive &&
      renderObject!.geometry != null &&
      renderObject!.geometry!.visible;

  /// [isRevealed] may use this to calculate the trailing offset for an item
  @override
  Axis get axis {
    assert(isActive);
    return renderObject!.constraints.axis;
  }

  /// if the viewport is overlapped by the previous [RenderSliver],
  /// the trailing edge should subtract the overlapped area
  @override
  double getTrailingEdgeFromScroll(ScrollExtent scrollExtent) {
    final sliverConstraints = renderObject!.constraints;

    return scrollExtent.current +
        sliverConstraints.viewportMainAxisExtent -
        sliverConstraints.overlap;
  }
}

class SingleChildSliverObserver extends SliverScrollObserver
    with SingleChildEstimation {
  SingleChildSliverObserver();

  /// any [ParentData] would be accept for single child sliver,
  /// since it would never use [parentData] internally
  @override
  bool isDesiredParentData(ParentData? parentData) => true;

  /// it should be regarded as revealed as long as [renderVisible],
  /// since no other child for this sliver with single child
  @override
  bool isRevealed(
    int index, {
    required ScrollExtent scrollExtent,
    PredicatorStrategy strategy = PredicatorStrategy.tolerance,
    bool shouldNormalized = true,
    bool shouldConvert = false,
  }) =>
      renderVisible;

  @override
  void onLayout(
    RenderSliver value, {
    required Size size,
    ParentData? parentData,
  }) {
    assert(value is SingleChildRenderBox,
        "$runtimeType is designed for single child sliver, but ${value.runtimeType} is not suitable for this scroll observer");
    super.onLayout(value, size: size, parentData: parentData);
    this.size = size;
  }

  @override
  void doFinishLayout() {
    super.doFinishLayout();

    if (shouldDoFinishLayout && isObserving) {
      assert(size != null,
          "The size of child should be observed before finishing layout");
      itemScrollExtent = ItemScrollExtent.empty();
      shouldDoFinishLayout = false;
    }
  }
}

class MultiChildSliverObserver extends SliverScrollObserver
    with MultiChildEstimation {
  MultiChildSliverObserver({int? itemCount}) {
    itemCount = itemCount;
  }

  @override
  bool isDesiredParentData(ParentData? parentData) =>
      parentData != null && parentData is SliverMultiBoxAdaptorParentData;

  @override
  void onLayout(
    RenderSliver value, {
    required Size size,
    ParentData? parentData,
  }) {
    assert(value is MultiChildSliver,
        "$runtimeType is designed for multi children slivers, but ${value.runtimeType} is not suitable for this scroll observer");
    super.onLayout(value, size: size, parentData: parentData);

    if (!isDesiredParentData(parentData)) {
      throw ErrorDescription(
          "Expected [SliverMultiBoxAdaptorParentData], but got ${parentData.runtimeType}");
    }

    sizes[(parentData as SliverMultiBoxAdaptorParentData).index!] = size;
  }

  @override
  void doFinishLayout() {
    super.doFinishLayout();

    assert(
      renderObject is MultiChildSliver,
      "${renderObject.runtimeType} does not contain multi box-based children",
    );

    if (shouldDoFinishLayout && isObserving) {
      shouldDoFinishLayout = false;

      RenderBox? child =
          (renderObject as RenderSliverMultiBoxAdaptor).firstChild;

      double totalExtent = 0;
      int count = 0;

      int? first;
      int? last;

      while (child != null) {
        final currentParentData =
            child.parentData! as SliverMultiBoxAdaptorParentData;

        assert(sizes.containsKey(currentParentData.index));
        //! not using [RenderBox.size] directly to avoid assertions failed in debug mode

        final item = ItemScrollExtent.fromSliverData(currentParentData);

        items[item.index] = item;

        totalExtent += getMainAxisExtent(item.index);

        first = lessFirst(first, item.index);
        last = greaterLast(last, item.index);

        child = currentParentData.nextSibling;
        count++;
      }

      updateRange(first, last);
      updateEstimation(totalExtent, count);
    }
  }
}
