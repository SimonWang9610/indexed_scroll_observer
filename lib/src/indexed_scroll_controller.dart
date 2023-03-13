import 'dart:async';

import 'package:flutter/widgets.dart';
import 'observer/scroll_observer.dart';

import 'observer/scroll_extent.dart';
import 'observer/onstage_strategy.dart';

/// [IndexedScrollController] would extend the ability of [ScrollController]
/// so that users could use [jumpToIndex] and [animateToIndex] to display a specific widget
///
/// if users just want to use a single [ScrollObserver] for [ListView]/[GridView]
/// using [IndexedScrollController.singleObserver] to only enable one [ScrollObserver]
///
/// This is a sample to use [IndexedScrollController.singleObserver]

/// if users need to observe multi slivers, e.g., [ListView]/[GridView]/[SliverList]/[SliverGrid]
/// users must use [IndexedScrollController.multiObserver] to create [ScrollObserver] for those slivers respectively

/// however, for [_SingleScrollController], the observer key is not required since only one [ScrollObserver] is active
/// for [_MultiScrollController]
/// users must specify unique keys for each sliver to identify which sliver they want to [jumpToIndex]/[animateToIndex]
///
abstract class IndexedScrollController extends ScrollController
    with ScrollMixin {
  IndexedScrollController({
    super.initialScrollOffset,
    super.keepScrollOffset,
    super.debugLabel,
  });

  factory IndexedScrollController.multiObserver({
    double initialScrollOffset = 0.0,
    bool keepScrollOffset = true,
    String? debugLabel,
  }) =>
      _MultiScrollController(
        initialScrollOffset: initialScrollOffset,
        keepScrollOffset: keepScrollOffset,
        debugLabel: debugLabel,
      );

  factory IndexedScrollController.singleObserver({
    double initialScrollOffset = 0.0,
    bool keepScrollOffset = true,
    String? debugLabel,
  }) =>
      _SingleScrollController(
        initialScrollOffset: initialScrollOffset,
        keepScrollOffset: keepScrollOffset,
        debugLabel: debugLabel,
      );

  @override
  void dispose() {
    super.dispose();
    _clear();
  }

  /// create a [ScrollObserver] if not exist for the [observerKey]
  /// otherwise, obtain the [ScrollObserver] bound with [observerKey]
  /// [observerKey] is required for [_MultiScrollController],
  /// while it has no effect for [_SingleScrollController]
  ///
  /// [hasMultiChild] would specify if [ScrollObserver] would observe a sliver that has multi children
  /// e.g., [SliverList]/[SliverGrid]
  /// if true, it would create a [ScrollObserver.multiChild]
  /// otherwise, it would create a [ScrollObserver.singleChild]
  /// therefore, users must specify the correct [hasMultiChild] for the sliver
  /// for example:
  /// [hasMultiChild] should be true for [SliverGrid]/[SliverList]
  /// [hasMultiChild] should be false for [SliverAppBar]
  ///
  /// [itemCount] should be the number of items for this [ScrollObserver] and same as the item count of the sliver
  /// however, for [ListView.separated], [itemCount] should also include the number of separators, for example:
  /// you specify [ListView.separated] has 30 items, the actual [itemCount] for [ScrollObserver] should be 60
  /// since each separator would also be indexed and rendered in the viewport
  ///
  /// if [itemCount] is null, [ScrollObserver] would treat the sliver as scrolling infinitely
  /// unless [hasMultiChild] is false (that would create [ScrollObserver.singleChild])
  ///
  /// NOTE:
  /// [IndexedScrollController.multiObserver] and [IndexedScrollController.singleObserver]
  /// would not know if their [ScrollObserver] have multi child when creating a [ScrollObserver]
  /// for both [IndexedScrollController], their [ScrollObserver]s could be any type
  ///
  /// the only difference between [IndexedScrollController.multiObserver] and [IndexedScrollController.singleObserver]
  /// is the number of [ScrollObserver]s they manage
  ScrollObserver createOrObtainObserver({
    bool hasMultiChild = true,
    String? observerKey,
    int? itemCount,
    int? maxTraceCount,
  }) {
    final existedObserver = _obtainObserver(observerKey);

    if (existedObserver != null &&
        existedObserver.hasMultiChild != hasMultiChild) {
      throw ErrorDescription(
        "The existing [${existedObserver.runtimeType}] whose key is '$observerKey' has the 'hasMultiChild' property: ${existedObserver.hasMultiChild}, "
        "but you want to obtain a [ScrollObserver] for '$observerKey' has the 'hasMultiChild' property is $hasMultiChild. "
        "Please ensure the $observerKey is bound with the same type [ScrollObserver]",
      );
    }

    if (existedObserver?.itemCount != itemCount && itemCount != null) {
      existedObserver?.itemCount = itemCount;
    }

    if (existedObserver?.maxTraceCount != maxTraceCount &&
        maxTraceCount != null) {
      existedObserver?.maxTraceCount = maxTraceCount;
    }

    return existedObserver ??
        _createObserver(
          hasMultiChild: hasMultiChild,
          observerKey: observerKey,
          itemCount: itemCount,
          maxTraceCount: maxTraceCount,
        );
  }

  /// show the sliver bound with [observerKey] in its closest viewport ancestor
  /// [observerKey] is required for [IndexedScrollController.multiObserver]
  /// it would take effects only when [observerKey] has a [ScrollObserver] that is active
  ///
  /// if you ensure [observerKey]'s sliver would definitely have an ancestor [RenderViewportBase]
  /// but it is not shown on the screen, you could try increasing [maxTraceCount] to allow tracing up further
  ///
  /// the [RenderSliver]'s scroll offset would be determined by the [ScrollView.reverse]
  /// if the sliver if [observerKey] is in a [CustomScrollView] and only has one child
  /// its scroll offset would be determined by the [CustomScrollView.reverse] and its index in [CustomScrollView.slivers]
  /// currently, such a case happens to [SliverAppBar]
  ///

  void showInViewport({
    String? observerKey,
    Duration duration = Duration.zero,
    Curve curve = Curves.ease,
  }) {
    final observer = _obtainObserver(observerKey);

    if (observer != null && observer.isActive) {
      observer.showInViewport(
        position,
        duration: duration,
        curve: curve,
      );
    }
  }

  /// for [IndexedScrollController.multiObserver], [whichObserver] is required
  /// if [closeEdge] is false, [jumpToIndex] only ensure [index] is visible on the screen
  /// if [closeEdge] is true, try to scroll [index] at the leading edge if not overscrolling
  /// the leading edge would depend on the [ScrollView.reverse]
  /// if [ScrollView.reverse] is false, the leading edge is the top of the viewport
  /// if [ScrollView.reverse] is true, the leasing edge is the bottom of the viewport
  void jumpToIndex(int index, {String? whichObserver, bool closeEdge = true}) {
    final observer = _obtainObserver(whichObserver);

    if (observer != null) {
      observer.jumpToIndex(index, position: position);
    }
  }

  /// for [IndexedScrollController.multiObserver], [whichObserver] is required
  /// if [closeEdge] is false, [jumpToIndex] only ensure [index] is visible on the screen
  /// if [closeEdge] is true, try to scroll [index] at the leading edge if not overscrolling
  /// the leading edge would depend on the [ScrollView.reverse]
  /// if [ScrollView.reverse] is false, the leading edge is the top of the viewport
  /// if [ScrollView.reverse] is true, the leasing edge is the bottom of the viewport

  /// if [animateToIndex] is invoked when [_animationRevealing] is not completed
  /// we schedule revealing [index] after the previous revealing ends
  /// if no [_animationRevealing] is active, we start animating instantly
  /// By doing so, we might avoid conflicts between two continuous revealing animation
  Future<bool> animateToIndex(
    int index, {
    required Duration duration,
    required Curve curve,
    bool closeEdge = true,
    String? whichObserver,
  }) async {
    final observer = _obtainObserver(whichObserver);

    if (observer != null) {
      return observer.animateToIndex(
        index,
        position: position,
        duration: duration,
        curve: curve,
      );
    } else {
      return Future.value(false);
    }
  }

  ScrollObserver _createObserver({
    bool hasMultiChild = true,
    String? observerKey,
    int? itemCount,
    int? maxTraceCount,
  });

  ScrollObserver? _obtainObserver([
    String? observerKey,
  ]);

  @protected
  void _clear();

  void debugCheckOnstageItems() {}
}

class _MultiScrollController extends IndexedScrollController {
  final Map<Object, ScrollObserver> _observers;

  _MultiScrollController({
    Map<Object, ScrollObserver>? observers,
    super.initialScrollOffset,
    super.keepScrollOffset,
    super.debugLabel,
  }) : _observers = observers ?? {};

  @override
  ScrollObserver _createObserver({
    bool hasMultiChild = true,
    String? observerKey,
    int? itemCount,
    int? maxTraceCount,
  }) {
    _checkObserverKey(observerKey);

    assert(
      !_observers.containsKey(observerKey),
      "The specified $observerKey has been created, please use _obtainObserver internally",
    );

    final observer = ScrollObserver(
      label: observerKey,
      itemCount: itemCount,
      hasMultiChild: hasMultiChild,
      maxTraceCount: maxTraceCount,
    );

    _observers[observerKey!] = observer;
    return observer;
  }

  @override
  ScrollObserver? _obtainObserver([
    String? observerKey,
  ]) {
    _checkObserverKey(observerKey);
    return _observers[observerKey];
  }

  @override
  void jumpToIndex(int index, {String? whichObserver, bool closeEdge = true}) {
    _checkObserverKey(whichObserver);

    super.jumpToIndex(
      index,
      whichObserver: whichObserver,
      closeEdge: closeEdge,
    );
  }

  @override
  Future<bool> animateToIndex(
    int index, {
    required Duration duration,
    required Curve curve,
    bool closeEdge = true,
    String? whichObserver,
  }) async {
    _checkObserverKey(whichObserver);

    return super.animateToIndex(
      index,
      duration: duration,
      curve: curve,
      whichObserver: whichObserver,
      closeEdge: closeEdge,
    );
  }

  @override
  void showInViewport({
    String? observerKey,
    Duration duration = Duration.zero,
    Curve curve = Curves.ease,
  }) {
    _checkObserverKey(observerKey);

    super.showInViewport(
      observerKey: observerKey,
      curve: curve,
      duration: duration,
    );
  }

  @override
  void _clear() {
    for (final observer in _observers.values) {
      observer.clear();
    }
    _observers.clear();
  }

  @override
  void debugCheckOnstageItems() {
    for (final observer in _observers.values) {
      observer.debugCheckOnstageItems(
        scrollExtent: ScrollExtent.fromPosition(position),
      );
    }
  }

  void _checkObserverKey(String? observerKey) {
    if (observerKey == null) {
      throw ErrorDescription(
        "Must give the observer key(whichObserver) to specify which [ScrollObserver] you want to use "
        "for [IndexedScrollController.multiObserver]. If you only need a single [ScrollObserver], "
        "please use [IndexedScrollController.singleObserver]",
      );
    }
  }
}

class _SingleScrollController extends IndexedScrollController {
  _SingleScrollController({
    ScrollObserver? observer,
    super.initialScrollOffset,
    super.keepScrollOffset,
    super.debugLabel,
  }) : _observer = observer;

  ScrollObserver? _observer;

  @override
  ScrollObserver _createObserver({
    bool hasMultiChild = true,
    String? observerKey,
    int? itemCount,
    int? maxTraceCount,
  }) {
    assert(
      _observer == null,
      "[ScrollObserver] has been created, please use _obtainObserver to get it",
    );
    _observer = ScrollObserver(
      label: observerKey ?? "SingleScrollController",
      itemCount: itemCount,
      hasMultiChild: hasMultiChild,
      maxTraceCount: maxTraceCount,
    );
    return _observer!;
  }

  @override
  ScrollObserver? _obtainObserver([
    String? observerKey,
  ]) =>
      _observer;

  @override
  void _clear() {
    _observer?.clear();
    _observer = null;
  }

  @override
  void debugCheckOnstageItems() {
    _observer!.debugCheckOnstageItems(
        scrollExtent: ScrollExtent.fromPosition(position));
  }
}

const double _kPixelDiffTolerance = 5;

const Duration _kDefaultDuration = Duration(milliseconds: 60);

mixin ScrollMixin on ScrollController {
  FutureOr<void> _adjustScrollWithTolerance(
    ScrollObserver observer,
    int index, {
    Duration? duration,
    Curve? curve,
  }) {
    final estimated = observer.estimateScrollOffset(
      index,
      scrollExtent: ScrollExtent.fromPosition(position),
    );
    final pixelDiff = estimated - position.pixels;

    print(
        "estimated: $estimated, current: ${position.pixels} diff: $pixelDiff");

    final canScroll =
        position.maxScrollExtent > position.pixels || position.pixels > 0;
    final shouldAdjust = pixelDiff.abs() > _kPixelDiffTolerance;

    if (canScroll && shouldAdjust) {
      final effectiveDuration =
          duration ?? ((!observer.hasMultiChild) ? _kDefaultDuration : null);
      return position.moveTo(estimated,
          duration: effectiveDuration, curve: curve);
    }
    return null;
  }

  FutureOr<void> _jumpWithoutCheck(
    ScrollObserver observer,
    int index, {
    Duration? duration,
    Curve? curve,
  }) {
    final targetOffset = observer.estimateScrollOffset(
      index,
      scrollExtent: ScrollExtent.fromPosition(position),
    );

    return position.moveTo(
      targetOffset,
      duration: duration,
      curve: curve,
    );
  }

  void _scheduleAsPostFrameCallback(void Function(Duration) callback) {
    WidgetsBinding.instance.addPostFrameCallback(callback);
  }
}
