import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'scroll_extent.dart';
import 'onstage_strategy.dart';
import '../util.dart';

// todo: handle memory pressure when there are too much models

/// [ScrollObserver.multiChild] could observe [RenderSliver] that has multi child, e.g., [SliverList]/[SliverGrid]
/// [ScrollObserver.singleChild] could observer [RenderSliver] that has a single child, e.g., [SliverAppBar]
/// since [ScrollObserver] relies on [RenderObserverProxy] to capture the most recent layout result
/// therefore, [RenderSliver]'s child/children should be wrapped in [ObserverProxy]
/// so that [ObserverProxy] could pass the layout result of each child to their closest [RenderSliver] ancestor
///
/// See also:
///
/// * [ObserverProxy], which proxies layout between [RenderSliver] and its child/children
abstract class ScrollObserver {
  final String? label;

  bool get hasMultiChild;

  ScrollObserver._({this.label, int? itemCount}) : _itemCount = itemCount;

  int? _itemCount;

  /// [itemCount] is not required if you intentionally creates an infinite scrolling list/grid
  /// if you ensure the list/grid has a finite [itemCount], it should not be null
  /// and also must be consistent to the itemCount of list/grid
  int? get itemCount => _itemCount;
  set itemCount(int? value) {
    if (_itemCount != value) {
      _itemCount = value;
    }
  }

  /// if [hasMultiChild] is true, it should create [_MultiChildObserver]
  /// to observe multi children whose ancestor [RenderSliver] is [sliver]
  /// if [hasMultiChild] is false, it should create [_SingleChildObserver] to observer the only [sliver] self
  ///
  /// however, currently we could not know if the [sliver] has multi child or not
  /// it is the responsibility of users to specify the [hasMultiChild] parameter correctly when creating a [ScrollObserver]
  /// if [hasMultiChild] does not match the type of [sliver]: [RenderObjectWithChildMixin] or [ContainerRenderObjectMixin]
  /// it would may result in unexpected behavior
  factory ScrollObserver(
      {String? label, int? itemCount, bool hasMultiChild = true}) {
    if (hasMultiChild) {
      return _MultiChildObserver(
        label: label,
        itemCount: itemCount,
      );
    } else {
      return _SingleChildObserver(
        label: label,
        itemCount: itemCount,
      );
    }
  }

  factory ScrollObserver.multiChild({String? label, int? itemCount}) =>
      _MultiChildObserver(
        label: label,
        itemCount: itemCount,
      );

  factory ScrollObserver.singleChild({String? label, int? itemCount}) =>
      _SingleChildObserver(
        label: label,
        itemCount: itemCount,
      );

  /// [sliver] represents the [RenderSliver] that control one or more [RenderBox]s
  /// [RenderObserverProxy] would behave as a proxy to invoke [onLayout] after its child/children are laid out
  /// [sliver] would be the [RenderSliver] closest to [RenderObserverProxy]
  RenderSliver? _sliver;
  RenderSliver? get sliver => _sliver;

  /// invoking in [RenderObserverProxy.performLayout] to tell [ScrollObserver] the size of the item
  /// if [sliver] changes, marking [_shouldUpdateOffset] as true
  /// to indicate [ScrollObserver] requires updating [origin]
  /// for [_MultiChildObserver], [parentData] must be [SliverMultiBoxAdaptorParentData]
  /// for [_SingleChildObserver], [parentData] is useless
  @mustCallSuper
  void onLayout(
    RenderSliver value, {
    required Size size,
    ParentData? parentData,
  }) {
    if (_sliver != value) {
      _sliver = value;
      _shouldUpdateOffset = true;
    }
  }

  bool get isActive => _sliver != null;

  /// for [_SingleChildObserver], it does nothing except trying to [_updateSliverOffset]
  /// for [_MultiChildObserver], [SliverIndexedProxyDelegate] would invoke [onFinishLayout] once it is notified by [SliverMultiBoxAdaptorElement]
  /// and it would first try to [_updateSliverOffset]
  /// then may trace up [sliver]'s children if [shouldObserve] is true
  @mustCallSuper
  void onFinishLayout(int firstIndex, int lastIndex) {
    assert(
      sliver != null,
      "[RenderSliver] should be given in [onLayout]. Please calling $runtimeType.onLayout "
      "to specify a [RenderSliver] for this observer before calling this method.",
    );
    _updateSliverOffset();
  }

  bool _shouldUpdateOffset = false;
  bool _scheduledOffsetUpdate = false;

  bool get scheduledOffsetUpdate => _scheduledOffsetUpdate;

  /// the global offset relative to [sliver]'s parent [RenderViewportBase]
  /// [estimateScrollOffset] may use [origin] to convert
  /// the local scroll offset (item relative to [sliver]) to
  /// the global scroll offset (item relative to [RenderViewportBase])
  RevealedOffset? _origin;
  @protected
  RevealedOffset get origin {
    assert(_origin != null,
        "This getter should be accessed after $runtimeType.didFinishLayout");
    return _origin!;
  }

  /// updating the global offset relative to [sliver]'s closest [RenderViewportBase]
  /// however, if the [RenderViewportBase] is the ancestor of [sliver],
  /// [RenderViewportBase.getOffsetToReveal] may access the intermediate [RenderSliver]'s [SliverGeometry] that may not be ready
  /// since the parent [RenderSliver] would set its geometry only after its child/children are laid out
  /// consequently, the [sliver]'s geometry is ready,
  /// while the intermediate [RenderSliver] between [sliver] and [RenderViewportBase] may not be ready
  /// therefore, we should catch the exception and schedule this updating later.
  /// Particularly, [scheduleMicrotask] is only executed as soon s possible
  /// so we could not guarantee [_updateSliverOffset] would complete before [SchedulePhase.postFrameCallback]
  /// todo: delay [jumpToIndex]/[animatedToIndex] if [_scheduledOffsetUpdate] is true
  void _updateSliverOffset() {
    assert(sliver != null);

    if (_shouldUpdateOffset) {
      try {
        final viewport = ObserverUtil.findClosestViewport(sliver!);

        _origin = viewport.getOffsetToReveal(sliver!, 0.0);

        _shouldUpdateOffset = false;
        _scheduledOffsetUpdate = false;
      } catch (e) {
        ///! if the sliver is the descendant of another sliver, its ancestor SliverGeometry mat not be ready
        ///! when its geometry is ready;
        ///! consequently, addPostFrameCallback to jump to the nested sliver may not work before origin is calculated

        if (!_scheduledOffsetUpdate) {
          scheduleMicrotask(() {
            _scheduledOffsetUpdate = true;
            _updateSliverOffset();
          });
        }
      }
    }
  }

  /// show [sliver] in its closest [RenderViewportBase]
  /// [maxTraceCount] restricts the max tracing up depth between [sliver] and its closest viewport
  /// but uses should ensure [sliver] would eventually find an ancestor viewport in [maxTraceCount]
  void showInViewport(
    ViewportOffset offset, {
    Duration duration = Duration.zero,
    Curve curve = Curves.ease,
    int maxTraceCount = 5,
  }) {
    if (!isActive) return;

    final viewport = ObserverUtil.findClosestViewport(
      _sliver!,
      maxTraceCount: maxTraceCount,
    );

    RenderViewportBase.showInViewport(
      descendant: _sliver,
      viewport: viewport,
      offset: offset,
      duration: duration,
      curve: curve,
    );
  }

  /// for [_SingleChildObserver], it would always return 0 as it only observes one child
  ///
  /// for [_MultiChildObserver]
  /// 1) [itemCount] is null, we treat it is observing an infinite list/grid, so return [index] directly
  /// 2) clamp [index] between [0, [itemCount - 1])
  int normalizeIndex(int index);

  /// for [_SingleChildObserver], it would just return [visible]
  /// for [_MultiChildObserver]
  /// if [shouldNormalized] is true, [index] would be first [normalizeIndex] to ensure its valid
  /// if [shouldNormalized] is false, [index] would keep unchanged
  ///
  /// [PredicatorStrategy] is used to compare the visible ratio of the item
  /// so as to determine if the item should be regarded as visible in the [SliverConstraints.viewportMainAxisExtent]
  ///
  /// See also:
  /// * [ScrollExtent], which describes the current [ScrollPosition] information
  bool isOnStage(
    int index, {
    required ScrollExtent scrollExtent,
    PredicatorStrategy strategy = PredicatorStrategy.tolerance,
    bool shouldNormalized = true,
  }) {
    final validIndex = shouldNormalized ? normalizeIndex(index) : index;

    final itemScrollModel = getItemScrollExtent(validIndex);
    final itemSize = getItemSize(validIndex);

    if (!visible || itemScrollModel == null || itemSize == null) return false;

    final sliverConstraints = sliver!.constraints;
    final leadingOffset = origin.offset + itemScrollModel.mainAxisOffset;

    final double trailingOffset;

    switch (sliverConstraints.axis) {
      case Axis.vertical:
        trailingOffset = leadingOffset + itemSize.height;
        break;
      case Axis.horizontal:
        trailingOffset = leadingOffset + itemSize.width;
        break;
    }

    final trailingEdge =
        scrollExtent.current + sliverConstraints.viewportMainAxisExtent;

    return OnstagePredicator.predict(
      leadingOffset,
      trailingOffset,
      leadingEdge: scrollExtent.current,
      trailingEdge: trailingEdge,
      maxScrollExtent: scrollExtent.max,
    );
  }

  /// if [sliver] is visible
  bool get visible =>
      sliver != null && sliver!.geometry != null && sliver!.geometry!.visible;

  /// estimate the scroll offset for [target]
  /// for [_SingleChildObserver], it would return [ScrollExtent.current] to indicate that no need to estimate
  /// since we could use [showInViewport] to ensure [sliver] is visible
  ///
  /// for [_MultiChildObserver], we would compare [target] and the current first and last child index
  /// then estimate [target]'s scroll offset based on their difference and the previous estimated page extent
  double estimateScrollOffset(
    int target, {
    required ScrollExtent scrollExtent,
  });

  ItemScrollExtent? getItemScrollExtent(int index);
  Size? getItemSize(int index);

  /// if we should continue observing when [onFinishLayout] is invoked
  /// since each child would invoke [onLayout] and [onFinishLayout]
  /// using [shouldObserve] could avoid tracing [sliver] redundantly
  /// for [_MultiChildObserver], as long as the index for first or last child changes
  /// we would trace up [sliver] to update each item's [ItemScrollExtent] in [onFinishLayout]
  bool shouldObserve(int first, int last) => true;

  void debugCheckOnstageItems({
    required ScrollExtent scrollExtent,
    PredicatorStrategy strategy = PredicatorStrategy.tolerance,
  }) {}

  @mustCallSuper
  void clear() {
    _sliver = null;
    _origin = null;
  }
}

// if the [sliver] self represents its item
/// currently we do not need to use its [ParentData] to know its offset in [onFinishLayout]
/// since we could use [showInViewport] to ensure the sliver is visible in the viewport
///
/// As a result, we also do not need to use [PredicatorStrategy] to determine if the item is visible
/// since its visibility is same as [sliver]
///
/// Once users want to [jumpToIndex] or [animateToIndex], we only need to first [showInViewport]
/// then, [estimateScrollOffset] just return the current [ScrollPosition.pixels] to avoid adjusting the scroll offset
class _SingleChildObserver extends ScrollObserver {
  _SingleChildObserver({String? label, int? itemCount})
      : super._(
          label: label,
          itemCount: itemCount,
        );

  @override
  @nonVirtual
  bool get hasMultiChild => false;

  Size? _size;
  ItemScrollExtent? _itemScrollExtent;

  @override
  void onLayout(
    RenderSliver value, {
    required Size size,
    ParentData? parentData,
  }) {
    assert(value is RenderObjectWithChildMixin<RenderBox>,
        "$runtimeType is designed for single child sliver, but ${value.runtimeType} is not suitable for this scroll observer");
    super.onLayout(value, size: size, parentData: parentData);
    _size = size;
  }

  @override
  void onFinishLayout(int firstIndex, int lastIndex) {
    super.onFinishLayout(firstIndex, lastIndex);

    assert(sliver is RenderObjectWithChildMixin<RenderBox>,
        "${sliver.runtimeType} does not contain single box-based child");

    if (shouldObserve(firstIndex, lastIndex)) {
      assert(_size != null,
          "The size of child should be observed before finishing layout");

      // final closestSliver = _findClosestSliverInViewport();
      // final parentData = closestSliver.parentData;

      // if (parentData != null) {
      //   _itemScrollExtent = ItemScrollModel.single(
      //     parentData as SliverPhysicalParentData,
      //     _size!,
      //     axis: sliver!.constraints.axis,
      //   );
      // } else {}

      _itemScrollExtent = ItemScrollExtent.empty();
    }
  }

  @override
  bool isOnStage(
    int index, {
    required ScrollExtent scrollExtent,
    PredicatorStrategy strategy = PredicatorStrategy.tolerance,
    bool shouldNormalized = true,
  }) =>
      visible;

  // todo: after hot restart, the estimated offset would be not accurate for SliverAppBar
  @override
  double estimateScrollOffset(
    int target, {
    required ScrollExtent scrollExtent,
  }) {
    assert(_itemScrollExtent != null);
    return scrollExtent.current;
  }

  @override
  int normalizeIndex(int index) => 0;

  @override
  ItemScrollExtent? getItemScrollExtent([int index = 0]) => _itemScrollExtent;

  @override
  Size? getItemSize(int index) => _size;

  @override
  void debugCheckOnstageItems({
    required ScrollExtent scrollExtent,
    PredicatorStrategy strategy = PredicatorStrategy.tolerance,
  }) {
    print("[$label]: $visible for $runtimeType ");
  }

  @override
  void clear() {
    _size = null;
    _itemScrollExtent = null;
    super.clear();
  }
}

class _MultiChildObserver extends ScrollObserver {
  final Map<int, ItemScrollExtent> _items = {};

  _MultiChildObserver({String? label, int? itemCount})
      : super._(
          label: label,
          itemCount: itemCount,
        );

  @override
  @nonVirtual
  bool get hasMultiChild => true;

  @override
  void onLayout(
    RenderSliver value, {
    required Size size,
    ParentData? parentData,
  }) {
    assert(
        value is ContainerRenderObjectMixin<RenderBox,
            SliverMultiBoxAdaptorParentData>,
        "$runtimeType is designed for multi children slivers, but ${value.runtimeType} is not suitable for this scroll observer");
    super.onLayout(value, size: size, parentData: parentData);

    _observeSize(size, parentData: parentData);
  }

  final Map<int, Size> _sizes = {};

  /// if the current laid out range [firstIndex], [lastIndex] is changed,
  /// we should observer/update [_items] for items whose index is between [firstIndex, lastIndex]
  /// we would use [SliverMultiBoxAdaptorParentData] to know the local scroll offset of each item
  /// besides, we also average [_estimatedAveragePageGap] so as to [estimateScrollOffset] better
  /// in further, we may need to use better methods to estimate the scroll offset for an index
  /// todo: optimize if [sliver] has fixed extent or prototyped
  @override
  void onFinishLayout(int firstIndex, int lastIndex) {
    super.onFinishLayout(firstIndex, lastIndex);

    assert(
        sliver is ContainerRenderObjectMixin<RenderBox,
            SliverMultiBoxAdaptorParentData>,
        "${sliver.runtimeType} does not contain multi box-based children");

    final bool shouldObserveModel = shouldObserve(firstIndex, lastIndex);

    if (shouldObserveModel) {
      RenderBox? child = (sliver as RenderSliverMultiBoxAdaptor).firstChild;

      double totalExtent = 0;
      int count = 0;

      while (child != null) {
        final currentParentData =
            child.parentData! as SliverMultiBoxAdaptorParentData;

        assert(
          currentParentData.index! >= firstIndex &&
              currentParentData.index! <= lastIndex,
          "The ${currentParentData.index!}-th child is not in the given range: [$firstIndex, $lastIndex]."
          "Typically, $runtimeType.onFinishLayout should be invoked by [SliverIndexedProxyDelegate] to "
          "ensure the given range [$firstIndex, $lastIndex] is valid.",
        );
        print("[$label]: ${currentParentData.index}");

        assert(_sizes.containsKey(currentParentData.index));
        //! not using [RenderBox.size] directly to avoid assertions failed in debug mode

        final item = ItemScrollExtent.multi(currentParentData);

        _items[item.index] = item;

        totalExtent += item.mainAxisOffset;
        count++;

        child = currentParentData.nextSibling;
      }

      //! if the sliver enables keepAlive for items, the below assertion would failed
      // assert(
      //   count == lastIndex - firstIndex + 1,
      //   "$count items are observed for $sliver, but the given range is [$firstIndex, $lastIndex]."
      //   "Please ensure not invoking [$label] $runtimeType.onFinishLayout manually unless you ensure the given range is valid",
      // );

      _first = firstIndex;
      _last = lastIndex;

      if (count == 0) {
        count = 1;
      }

      _estimatedAveragePageGap =
          (_estimatedAveragePageGap + totalExtent / count) / 2;
    }
  }

  /// since Flutter will assert failed if we access the [sliver]'s children's [Size] in debug mode
  /// so we use [_observeSize] standalone to store each item's size
  void _observeSize(Size size, {ParentData? parentData}) {
    assert(parentData != null && parentData is SliverMultiBoxAdaptorParentData);
    _sizes[(parentData as SliverMultiBoxAdaptorParentData).index!] = size;
  }

  double _estimatedAveragePageGap = 0;

  /// 1) if we could find [ItemScrollModel] for [target], it turns out [target] has been laid out
  /// so we could use [origin] to estimate [target]'s scroll offset (actually it would be the accurate offset)
  ///
  /// 2) if [target] is less than [_first], we should go the previous page based on [_first]'s [ItemScrollModel]
  /// 3) if [target] is greater than [_last], we should go the next page based on [_last]'s [ItemScrollModel]
  /// the page offset is estimated as [_estimatedAveragePageGap] that is frequently updated during [onFinishLayout]
  @override
  double estimateScrollOffset(
    int target, {
    required ScrollExtent scrollExtent,
  }) {
    assert(
      _items.containsKey(_first) && _items.containsKey(_last),
      "[ItemScrollModel] for index $_first and $_last should be observed "
      "during $runtimeType.onFinishLayout.",
    );

    double estimated = origin.offset;

    if (_items.containsKey(target)) {
      estimated += getItemScrollExtent(target)!.mainAxisOffset;
    } else {
      /// avoid division by zero when estimating
      final currentIndexGap = _last - _first > 0 ? _last - _first : 1;

      if (target < _first) {
        estimated += getItemScrollExtent(_first)!.mainAxisOffset +
            (target - _first) / currentIndexGap * _estimatedAveragePageGap;
      } else if (target > _last) {
        estimated += getItemScrollExtent(_last)!.mainAxisOffset +
            (target - _last) / currentIndexGap * _estimatedAveragePageGap;
      } else {
        assert(
          false,
          "This line should never reach. Since $target is in [$_first, $_last], "
          "its [itemScrollModel] should be observed during $runtimeType.didFinishLayout",
        );
      }
    }

    final leadingEdge = max(origin.offset, scrollExtent.min);

    return clampDouble(estimated, leadingEdge, scrollExtent.max);
  }

  /// the current laid out first child of [sliver]
  int _first = -1;

  /// the current laid out last child of [sliver]
  int _last = 0;

  @override
  bool shouldObserve(int first, int last) {
    return _first != first || _last != last;
  }

  @override
  int normalizeIndex(int index) {
    if (itemCount == null) {
      return index;
    } else {
      final smaller = min(index, itemCount! - 1);
      final normalized = max(0, smaller);
      return normalized;
    }
  }

  @override
  ItemScrollExtent? getItemScrollExtent(int index) => _items[index];

  @override
  Size? getItemSize(int index) => _sizes[index];

  @override
  void clear() {
    _items.clear();
    _sizes.clear();
    super.clear();
  }

  @override
  void debugCheckOnstageItems({
    required ScrollExtent scrollExtent,
    PredicatorStrategy strategy = PredicatorStrategy.tolerance,
  }) {
    List<int> onstageItems = [];

    for (final key in _items.keys) {
      if (isOnStage(key, scrollExtent: scrollExtent, strategy: strategy)) {
        onstageItems.add(key);
      }
    }

    print("[$label]: $onstageItems for $runtimeType");
  }
}
