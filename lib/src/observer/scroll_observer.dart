// import 'dart:async';
// import 'dart:math';

// import 'package:flutter/foundation.dart';
// import 'package:flutter/rendering.dart';
// import 'package:flutter/widgets.dart';

// import 'scroll_extent.dart';
// import 'onstage_strategy.dart';
// import 'observer_interface.dart';

// // todo: handle memory pressure when there are too much models

// /// [ScrollObserver.multiChild] could observe [RenderSliver] that has multi child,
// ///  e.g., [SliverList]/[SliverGrid].
// /// [ScrollObserver.singleChild] could observer [RenderSliver] that has a single child,
// ///  e.g., [SliverAppBar].
// /// [ScrollObserver] relies on [RenderObserverProxy] to capture the most recent layout result,
// /// and therefore, [RenderSliver]'s child/children must be wrapped in [ObserverProxy],
// /// so that [ObserverProxy] could notify [ScrollObserver] to invoke [onLayout] and [doFinishLayout].
// ///
// /// See also:
// /// * [ObserverProxy], which proxies layout between [RenderSliver] and its child/children
// abstract class ScrollObserver extends ObserverScrollInterface
//     with ObserverScrollImpl {
//   final String? label;

//   bool get hasMultiChild;

//   ScrollObserver._({this.label, int? itemCount, int? maxTraceCount})
//       : _itemCount = itemCount,
//         maxTraceCount = maxTraceCount ?? 50;

//   /// if [hasMultiChild] is true, it should create [_MultiChildObserver]
//   /// to observe multi children whose ancestor [RenderSliver] is [sliver].
//   ///
//   /// if [hasMultiChild] is false, it should create [_SingleChildObserver]
//   /// to observer the only [sliver] self.
//   ///
//   /// currently we could not know if the [sliver] has multi child or not in advance,
//   /// so it is the responsibility of users to specify the [hasMultiChild] parameter correctly
//   /// when creating a [ScrollObserver].
//   ///
//   /// if [hasMultiChild] does not match the type of [sliver]: [RenderObjectWithChildMixin]
//   /// or [ContainerRenderObjectMixin], it may result in unexpected behavior.
//   ///
//   /// See also:
//   ///   * [PositionedScrollController], which allows users to manage their [ScrollObserver] conveniently
//   factory ScrollObserver({
//     String? label,
//     int? itemCount,
//     bool hasMultiChild = true,
//     int? maxTraceCount,
//   }) {
//     if (hasMultiChild) {
//       return _MultiChildObserver(
//         label: label,
//         itemCount: itemCount,
//         maxTraceCount: maxTraceCount,
//       );
//     } else {
//       return _SingleChildObserver(
//         label: label,
//         itemCount: itemCount,
//         maxTraceCount: maxTraceCount,
//       );
//     }
//   }

//   /// create a [ScrollObserver] that observes a [RenderSliver] with multi children
//   factory ScrollObserver.multiChild({
//     String? label,
//     int? itemCount,
//     int? maxTraceCount,
//   }) =>
//       _MultiChildObserver(
//         label: label,
//         itemCount: itemCount,
//         maxTraceCount: maxTraceCount,
//       );

//   /// create a [ScrollObserver] that observes a [RenderSliver] with single child
//   factory ScrollObserver.singleChild({
//     String? label,
//     int? maxTraceCount,
//   }) =>
//       _SingleChildObserver(
//         label: label,
//         maxTraceCount: maxTraceCount,
//       );

//   int? _itemCount;

//   /// [itemCount] is not required if you intentionally creates an infinite scrolling list/grid.
//   /// if you ensure the list/grid has a finite [itemCount], it should not be null,
//   /// and also must be consistent to the itemCount of list/grid.
//   /// [itemCount] would have no effects for [ScrollObserver.singleChild].
//   int? get itemCount => _itemCount;
//   set itemCount(int? value) {
//     if (_itemCount != value) {
//       _itemCount = value;
//     }
//   }

//   /// whether this observer should start observing the [RenderObserverProxy].
//   /// typically, it should be true
//   bool _observing = true;
//   @override
//   bool get isObserving => _observing;

//   /// sometimes, [ObserverProxy] may not be descendants of [RenderSliver] temporarily,
//   /// e.g., [ReorderableListView] is ordering.
//   /// using [pause] to stop observing temporarily.
//   void pause() {
//     _observing = false;
//   }

//   /// using [resume] to continue observing.
//   void resume() {
//     _observing = true;
//   }

//   /// [maxTraceCount] is used when:
//   ///
//   /// 1) [RenderObserverProxy] try to find its closest [RenderSliver] and [SliverMultiBoxAdaptorParentData],
//   /// since there are many other [RenderObject] between its closest [RenderSliver] and [RenderObserverProxy],
//   /// so we use [maxTraceCount] to guarantee not going into an infinite loop.
//   ///
//   /// 2) [showInViewport] to find its closest [RenderViewportBase].
//   ///
//   /// By using [maxTraceCount], we would try to find the target no more than [maxTraceCount] loop times,
//   /// instead of using a while-loop that might be infinite for some rare error usage.
//   int maxTraceCount;

//   /// [sliver] is the [RenderSliver] that is observed by this [ScrollObserver].
//   /// [sliver] would be the [RenderSliver] closest to [RenderObserverProxy].
//   /// if [sliver] is null, this observer should not be [isActive].
//   RenderSliver? _sliver;
//   @protected
//   RenderSliver? get sliver => _sliver;

//   /// invoking in [RenderObserverProxy.performLayout] to tell [ScrollObserver] the size of the item.
//   /// if [sliver] changes, marking [_shouldUpdateOffset] as true,
//   /// to indicate [ScrollObserver] requires updating [origin].
//   /// for [_MultiChildObserver], [parentData] must be [SliverMultiBoxAdaptorParentData].
//   /// for [_SingleChildObserver], [parentData] is useless.
//   ///
//   /// as long as [onLayout] is invoked for at least one item, marking [_shouldDoFinishLayout] is true.
//   /// By doing so, we could invoke [doFinishLayout] on time and reduce unnecessary invocations for [doFinishLayout].
//   ///
//   /// See:
//   ///   * [_MultiChildObserver.onLayout]
//   ///   * [_SingleChildObserver.onLayout]
//   @mustCallSuper
//   void onLayout(
//     RenderSliver value, {
//     required Size size,
//     ParentData? parentData,
//   }) {
//     if (_sliver != value) {
//       _sliver = value;
//       _shouldUpdateOffset = true;
//     }

//     _shouldDoFinishLayout = true;
//   }

//   bool _shouldDoFinishLayout = false;

//   /// [doFinishLayout] would be invoked by [RenderObserverProxy] when painting.
//   /// [_shouldDoFinishLayout] is set as true when [onLayout] is invoked.
//   /// However, once [doFinishLayout] is executed, [_shouldDoFinishLayout] must be set as false,
//   /// avoiding redundant invocations for those items that are laid out in the same frame.
//   ///
//   /// [doFinishLayout] should setup [ItemScrollExtent] for each item attached to the same [sliver].
//   ///
//   /// See also:
//   ///   * [_MultiChildObserver.doFinishLayout], which setup for multi items that have been laid out
//   ///   * [_SingleChildObserver.doFinishLayout], which setup for [sliver] self
//   @mustCallSuper
//   void doFinishLayout() {
//     assert(
//       sliver != null,
//       "[RenderSliver] should be given in [onLayout]. Please calling $runtimeType.onLayout "
//       "to specify a [RenderSliver] for this observer before calling this method.",
//     );
//     _updateSliverOffset();
//   }

//   bool _shouldUpdateOffset = false;
//   bool _scheduledOffsetUpdate = false;

//   bool get scheduledOffsetUpdate => _scheduledOffsetUpdate;

//   /// the global offset relative to [sliver]'s parent [RenderViewportBase].
//   /// [estimateScrollOffset] may use [origin] to convert
//   /// the local scroll offset (item relative to [sliver]) to
//   /// the global scroll offset (item relative to [RenderViewportBase]).
//   RevealedOffset? _origin;
//   @protected
//   RevealedOffset get origin {
//     assert(_origin != null,
//         "This getter should be accessed after $runtimeType.doFinishLayout");
//     return _origin!;
//   }

//   /// updating the global offset relative to [sliver]'s closest [RenderViewportBase].
//   ///
//   /// however, if the [RenderViewportBase] is the ancestor of [sliver],
//   /// [RenderViewportBase.getOffsetToReveal] may access the intermediate [RenderSliver]'s [SliverGeometry] that may not be ready,
//   /// since the parent [RenderSliver] would set its geometry only after its child/children are laid out.
//   ///
//   /// consequently, the [sliver]'s geometry is ready, while the intermediate [RenderSliver]
//   /// between [sliver] and [RenderViewportBase] may not be ready.
//   ///
//   /// therefore, we should catch the potential exception and schedule this updating later if happens
//   /// Particularly, [scheduleMicrotask] is only executed as soon s possible, and as a result of that,
//   /// we could not guarantee [_updateSliverOffset] would complete before [SchedulePhase.postFrameCallback]
//   ///
//   /// if [firstLayoutFinished] is true, we could assert [_updateSliverOffset] is done successfully.
//   void _updateSliverOffset() {
//     assert(sliver != null);

//     if (_shouldUpdateOffset && isObserving) {
//       try {
//         // final viewport = ObserverUtil.findClosestViewport(sliver!);

//         // _origin = viewport.getOffsetToReveal(sliver!, 0.0);

//         final viewport = RenderAbstractViewport.of(_sliver);
//         _origin = viewport.getOffsetToReveal(sliver!, 0.0);

//         _shouldUpdateOffset = false;
//         _scheduledOffsetUpdate = false;
//       } catch (e) {
//         ///! if the sliver is the descendant of another sliver, its ancestor SliverGeometry mat not be ready
//         ///! when its geometry is ready;
//         ///! consequently, addPostFrameCallback to jump to the nested sliver may not work before origin is calculated

//         if (!_scheduledOffsetUpdate) {
//           scheduleMicrotask(() {
//             _scheduledOffsetUpdate = true;
//             _updateSliverOffset();
//           });
//         }
//       }
//     }
//   }

//   @override
//   void showInViewport(
//     ViewportOffset offset, {
//     Duration duration = Duration.zero,
//     Curve curve = Curves.ease,
//   }) {
//     if (!isActive) return;

//     final viewport = RenderAbstractViewport.of(_sliver);

//     viewport.showOnScreen(
//       descendant: _sliver,
//       duration: duration,
//       curve: curve,
//     );
//   }

//   @override
//   Axis get axis => sliver!.constraints.axis;

//   @override
//   double getTrailingEdgeFromScroll(ScrollExtent scrollExtent) {
//     final sliverConstraints = sliver!.constraints;

//     return scrollExtent.current +
//         sliverConstraints.viewportMainAxisExtent -
//         sliverConstraints.overlap;
//   }

//   @override
//   bool get isActive => _sliver != null;

//   @mustCallSuper
//   @override
//   bool get firstLayoutFinished => isActive && !_shouldUpdateOffset;

//   /// if [sliver] is visible
//   @override
//   bool get renderVisible =>
//       isActive && sliver!.geometry != null && sliver!.geometry!.visible;

//   /// See:
//   ///   * [_MultiChildObserver.estimateScrollOffset], which implements the rules of estimation
//   ///    for [RenderSliver] with multi children
//   ///   * [_SingleChildObserver.estimateScrollOffset], which implements the rules of estimation
//   ///    for [RenderSliver] with single child
//   @mustCallSuper
//   @override
//   double estimateScrollOffset(
//     int target, {
//     required ScrollExtent scrollExtent,
//   }) {
//     checkFirstLayoutFinished();
//     return origin.offset;
//   }

//   @override
//   void debugCheckOnstageItems({
//     required ScrollExtent scrollExtent,
//     PredicatorStrategy strategy = PredicatorStrategy.tolerance,
//   }) {}

//   @mustCallSuper
//   @override
//   void clear() {
//     super.clear();
//     _sliver = null;
//     _origin = null;
//   }
// }

// class _SingleChildObserver extends ScrollObserver {
//   _SingleChildObserver({
//     String? label,
//     int? itemCount,
//     int? maxTraceCount,
//   }) : super._(
//           label: label,
//           itemCount: itemCount,
//           maxTraceCount: maxTraceCount,
//         );

//   @override
//   @nonVirtual
//   bool get hasMultiChild => false;

//   Size? _size;
//   ItemScrollExtent? _itemScrollExtent;

//   @override
//   void onLayout(
//     RenderSliver value, {
//     required Size size,
//     ParentData? parentData,
//   }) {
//     assert(value is RenderObjectWithChildMixin<RenderBox>,
//         "$runtimeType is designed for single child sliver, but ${value.runtimeType} is not suitable for this scroll observer");
//     super.onLayout(value, size: size, parentData: parentData);
//     _size = size;
//   }

//   @override
//   bool get firstLayoutFinished =>
//       _size != null && _itemScrollExtent != null && super.firstLayoutFinished;

//   @override
//   void doFinishLayout() {
//     super.doFinishLayout();

//     if (_shouldDoFinishLayout && isObserving) {
//       assert(_size != null,
//           "The size of child should be observed before finishing layout");
//       _itemScrollExtent = ItemScrollExtent.empty();
//       _shouldDoFinishLayout = false;
//     }
//   }

//   @override
//   bool isRevealed(
//     int index, {
//     required ScrollExtent scrollExtent,
//     PredicatorStrategy strategy = PredicatorStrategy.tolerance,
//     bool shouldNormalized = true,
//     bool shouldConvert = false,
//   }) =>
//       renderVisible;

//   @override
//   double estimateScrollOffset(
//     int target, {
//     required ScrollExtent scrollExtent,
//   }) {
//     super.estimateScrollOffset(target, scrollExtent: scrollExtent);
//     return scrollExtent.current;
//   }

//   @override
//   int normalizeIndex(int index) => 0;

//   @override
//   ItemScrollExtent? getItemScrollExtent([int index = 0]) => _itemScrollExtent;

//   @override
//   Size? getItemSize(int index) => _size;

//   @override
//   void debugCheckOnstageItems({
//     required ScrollExtent scrollExtent,
//     PredicatorStrategy strategy = PredicatorStrategy.tolerance,
//   }) {
//     debugPrint("[$label]: $renderVisible for $runtimeType ");
//   }

//   @override
//   void clear() {
//     _size = null;
//     _itemScrollExtent = null;
//     super.clear();
//   }
// }

// class _MultiChildObserver extends ScrollObserver {
//   final Map<int, ItemScrollExtent> _items = {};

//   _MultiChildObserver({
//     String? label,
//     int? itemCount,
//     int? maxTraceCount,
//   }) : super._(
//           label: label,
//           itemCount: itemCount,
//           maxTraceCount: maxTraceCount,
//         );

//   @override
//   @nonVirtual
//   bool get hasMultiChild => true;

//   @override
//   void onLayout(
//     RenderSliver value, {
//     required Size size,
//     ParentData? parentData,
//   }) {
//     assert(
//         value is ContainerRenderObjectMixin<RenderBox,
//             SliverMultiBoxAdaptorParentData>,
//         "$runtimeType is designed for multi children slivers, but ${value.runtimeType} is not suitable for this scroll observer");
//     super.onLayout(value, size: size, parentData: parentData);

//     _observeSize(size, parentData: parentData);
//   }

//   final Map<int, Size> _sizes = {};

//   /// since Flutter will assert failed if we access the [sliver]'s children's [Size] in debug mode
//   /// so we use [_observeSize] standalone to store each item's size
//   void _observeSize(Size size, {ParentData? parentData}) {
//     assert(parentData != null && parentData is SliverMultiBoxAdaptorParentData);
//     _sizes[(parentData as SliverMultiBoxAdaptorParentData).index!] = size;
//   }

//   @override
//   bool get firstLayoutFinished =>
//       _first != null && _last != null && super.firstLayoutFinished;

//   /// the current laid out first child of [sliver]
//   int? _first;

//   /// the current laid out last child of [sliver]
//   int? _last;

//   double _estimatedAveragePageGap = 0;

//   @override
//   void doFinishLayout() {
//     super.doFinishLayout();

//     assert(
//         sliver is ContainerRenderObjectMixin<RenderBox,
//             SliverMultiBoxAdaptorParentData>,
//         "${sliver.runtimeType} does not contain multi box-based children");

//     if (_shouldDoFinishLayout && isObserving) {
//       RenderBox? child = (sliver as RenderSliverMultiBoxAdaptor).firstChild;

//       double totalExtent = 0;
//       int count = 0;

//       int? first;
//       int? last;

//       while (child != null) {
//         final currentParentData =
//             child.parentData! as SliverMultiBoxAdaptorParentData;

//         assert(_sizes.containsKey(currentParentData.index));
//         //! not using [RenderBox.size] directly to avoid assertions failed in debug mode

//         final item = ItemScrollExtent.multi(currentParentData);

//         _items[item.index] = item;

//         totalExtent += item.mainAxisOffset;
//         count++;

//         first = _lessFirst(first, item.index);
//         last = _greaterLast(last, item.index);

//         child = currentParentData.nextSibling;
//       }

//       _first = first;
//       _last = last;

//       if (count == 0) {
//         count = 1;
//       }

//       if (sliver is RenderSliverGrid) {}

//       _estimatedAveragePageGap =
//           (_estimatedAveragePageGap + totalExtent / count) / 2;

//       _shouldDoFinishLayout = false;
//     }
//   }

//   /// 1) if we could find [ItemScrollModel] for [target], it turns out [target] has been laid out,
//   /// so we could use [origin] to estimate [target]'s scroll offset (actually it would be the accurate offset).
//   ///
//   /// 2) if [target] is less than [_first], we should go the previous page based on [_first]'s [ItemScrollModel].
//   /// 3) if [target] is greater than [_last], we should go the next page based on [_last]'s [ItemScrollModel].
//   /// the page offset is estimated as [_estimatedAveragePageGap] that is frequently updated during [onFinishLayout].
//   @override
//   double estimateScrollOffset(
//     int target, {
//     required ScrollExtent scrollExtent,
//   }) {
//     double estimated =
//         super.estimateScrollOffset(target, scrollExtent: scrollExtent);

//     assert(
//       _items.containsKey(_first) && _items.containsKey(_last),
//       "[ItemScrollModel] for index $_first and $_last should be observed "
//       "during $runtimeType.onFinishLayout.",
//     );

//     if (_items.containsKey(target)) {
//       estimated += getItemScrollExtent(target)!.mainAxisOffset;
//     } else {
//       /// avoid division by zero when estimating
//       final currentIndexGap = _last! - _first! > 0 ? _last! - _first! : 1;

//       if (target < _first!) {
//         estimated += getItemScrollExtent(_first!)!.mainAxisOffset +
//             (target - _first!) / currentIndexGap * _estimatedAveragePageGap;
//       } else if (target > _last!) {
//         estimated += getItemScrollExtent(_last!)!.mainAxisOffset +
//             (target - _last!) / currentIndexGap * _estimatedAveragePageGap;
//       } else {
//         assert(
//           false,
//           "This line should never reach. Since $target is in [$_first, $_last], "
//           "its [itemScrollModel] should be observed during $runtimeType.didFinishLayout",
//         );
//       }
//     }

//     final leadingEdge = max(origin.offset, scrollExtent.min);

//     return clampDouble(estimated, leadingEdge, scrollExtent.max);
//   }

//   @override
//   int normalizeIndex(int index) {
//     if (itemCount == null) {
//       return index;
//     } else {
//       final smaller = min(index, itemCount! - 1);
//       final normalized = max(0, smaller);
//       return normalized;
//     }
//   }

//   @override
//   ItemScrollExtent? getItemScrollExtent(int index) => _items[index];

//   @override
//   Size? getItemSize(int index) => _sizes[index];

//   @override
//   void clear() {
//     _estimatedAveragePageGap = 0;
//     _first = null;
//     _last = null;
//     _items.clear();
//     _sizes.clear();

//     super.clear();
//   }

//   @override
//   void debugCheckOnstageItems({
//     required ScrollExtent scrollExtent,
//     PredicatorStrategy strategy = PredicatorStrategy.tolerance,
//   }) {
//     List<int> onstageItems = [];

//     for (final key in _items.keys) {
//       if (isRevealed(key, scrollExtent: scrollExtent, strategy: strategy)) {
//         onstageItems.add(renderToTargetIndex?.call(key) ?? key);
//       }
//     }

//     debugPrint(
//         "[$label]: $onstageItems for $runtimeType, first: $_first, last: $_last");
//   }
// }

// int _lessFirst(int? first, int current) {
//   if (first == null) {
//     return current;
//   } else {
//     return min(first, current);
//   }
// }

// int _greaterLast(int? last, int current) {
//   if (last == null) {
//     return current;
//   } else {
//     return max(last, current);
//   }
// }
