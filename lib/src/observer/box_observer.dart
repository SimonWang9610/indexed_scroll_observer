import 'package:flutter/rendering.dart';
import 'package:positioned_scroll_observer/src/observer/layout_observer.dart';
import 'package:positioned_scroll_observer/src/observer/observer_interface.dart';

import 'scroll_extent.dart';
import 'visibility_strategy.dart';
import 'item_estimation.dart';
import 'util.dart';

/// When observing [RenderBox], [axis] must be given to indicate the scroll direction.
/// Typically, [BoxScrollObserver] is used for [SingleChildScrollView] and [ListWheelScrollView]
/// that have not [RenderSliver] between [RenderAbstractViewport] and its descendants.
///
/// If items would have an [RenderSliver] ancestor, please use [SliverScrollObserver].
///
/// See also:
///   * [SingleChildSliverObserver], which observe a sliver with single child
///   * [MultiChildSliverObserver], which observer a sliver with multi children
abstract class BoxScrollObserver<T extends RenderObject>
    extends LayoutObserver<T> with ObserverScrollInterface, ObserverScrollImpl {
  BoxScrollObserver({
    required Axis axis,
    int? itemCount,
  }) : _axis = axis {
    itemCount = itemCount;
  }

  @override
  bool get hasMultiChild =>
      super.hasMultiChild && this is MultiChildBoxObserver;

  Axis _axis;
  @override
  Axis get axis => _axis;

  set axis(Axis value) {
    if (_axis != value) {
      _axis = value;
      renderObject?.markNeedsLayout();
    }
  }

  /// once some items of [renderObject] have been painted,
  /// we could ensure a part of [renderObject] is visible,
  @override
  bool get renderVisible => isActive && _hasChildPainted;

  @override
  bool get firstLayoutFinished => _hasChildPainted && super.firstLayoutFinished;

  bool _hasChildPainted = false;

  @override
  void doFinishLayout() {
    if (shouldUpdateOrigin && isObserving) {
      _findViewportMainAxisExtent();
    }
    _hasChildPainted = true;

    super.doFinishLayout();
  }

  @override
  double get mainAxisExtent => _mainAxisExtent;

  /// for [BoxScrollObserver], its closest [RenderAbstractViewport] is typically
  /// has no [SliverConstraints], and therefore, we use its [paintBounds] to indicate
  /// how many pixels it could use along the main axis
  double _mainAxisExtent = 0;

  void _findViewportMainAxisExtent() {
    final viewport = RenderAbstractViewport.of(renderObject);

    final paintBound = viewport.paintBounds;
    switch (axis) {
      case Axis.vertical:
        _mainAxisExtent = paintBound.height;
        break;
      case Axis.horizontal:
        _mainAxisExtent = paintBound.width;
        break;
    }
  }

  @override
  double getTrailingEdgeFromScroll(ScrollExtent scrollExtent) =>
      scrollExtent.current + _mainAxisExtent;
}

/// [MultiChildBoxObserver] would only observe the closest [MultiChildRenderBox] ancestor
/// Since the [renderObject] may not give its children a index, so we store items' size
/// by items' [ParentData.hashCode]
class MultiChildBoxObserver extends BoxScrollObserver<MultiChildRenderBox>
    with MultiChildEstimation {
  MultiChildBoxObserver({required super.axis, super.itemCount});

  @override
  bool isDesiredParentData(ParentData? parentData) =>
      parentData != null && parentData is ContainerBoxParentData<RenderBox>;

  @override
  void onLayout(
    MultiChildRenderBox value, {
    required Size size,
    ParentData? parentData,
  }) {
    super.onLayout(value, size: size, parentData: parentData);

    if (!isDesiredParentData(parentData)) {
      throw ErrorDescription(
          "Expected [ContainerBoxParentData<RenderBox>], but got ${parentData.runtimeType}");
    }

    sizes[parentData!.hashCode] = size;
  }

  @override
  void doFinishLayout() {
    super.doFinishLayout();

    assert(
      renderObject is MultiChildRenderBox,
      "${renderObject.runtimeType} does not have multi box-based children",
    );

    if (shouldDoFinishLayout && isObserving) {
      shouldDoFinishLayout = false;

      RenderBox? child = (renderObject as MultiChildRenderBox).firstChild;

      int count = 0;
      double totalExtent = 0;

      int? first;
      int? last;

      while (child != null) {
        final parentData =
            child.parentData! as ContainerBoxParentData<RenderBox>;

        final index = _getIndex(parentData, count);

        assert(
          sizes.containsKey(parentData.hashCode),
          "The child's size should be observed before doFinishLayout",
        );

        final item = ItemScrollExtent.fromBoxData(index, parentData, axis);

        items[item.index] = item;

        totalExtent += getMainAxisExtent(item.index);

        first = lessFirst(first, item.index);
        last = greaterLast(last, item.index);

        child = parentData.nextSibling;
        count++;
      }

      updateRange(first, last);
      updateEstimation(totalExtent, count);
    }
  }

  int _getIndex(ContainerBoxParentData parentData, int fallback) {
    if (parentData is ListWheelParentData) {
      return parentData.index!;
    } else {
      return fallback;
    }
  }

  @override
  Size? getItemSize(int index) {
    final dataHash = getItemScrollExtent(index)?.dataHashCode;

    return dataHash != null ? sizes[dataHash] : null;
  }

  @override
  List<int> getVisibleItems({
    required ScrollExtent scrollExtent,
    VisibilityStrategy strategy = VisibilityStrategy.tolerance,
  }) {
    List<int> onstageItems = [];

    for (final key in items.keys) {
      if (isRevealed(key, scrollExtent: scrollExtent, strategy: strategy)) {
        onstageItems.add(renderToTargetIndex?.call(key) ?? key);
      }
    }

    debugPrint("$runtimeType: $onstageItems");

    return onstageItems;
  }
}

// todo: waiting testing
class SingleChildBoxObserver extends BoxScrollObserver<SingleChildRenderBox>
    with SingleChildEstimation {
  SingleChildBoxObserver({required super.axis});

  @override
  bool isDesiredParentData(ParentData? parentData) => parentData != null;

  @override
  bool isRevealed(
    int index, {
    required ScrollExtent scrollExtent,
    VisibilityStrategy strategy = VisibilityStrategy.tolerance,
    bool shouldNormalized = true,
    bool shouldConvert = false,
    double tolerance = 0,
  }) =>
      renderVisible;

  @override
  void onLayout(
    SingleChildRenderBox value, {
    required Size size,
    ParentData? parentData,
  }) {
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
