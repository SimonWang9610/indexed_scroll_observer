import 'package:flutter/rendering.dart';

import 'dart:async';

import 'package:flutter/widgets.dart';

import 'scroll_extent.dart';
import 'onstage_strategy.dart';

typedef IndexConverter = int Function(int);

/// the tolerance between the scroll offset of items and the current pixels of [ScrollPosition]
const double _kPixelDiffTolerance = 5;

const Duration _kDefaultAdjustDuration = Duration(milliseconds: 120);

abstract class ObserverScrollInterface {
  /// if this observer is observing multi children for a [RenderSliver]
  bool get hasMultiChild;

  /// if some children have been laid out completely
  /// indicates some required information to estimate scroll offset for a certain item is ready to use
  /// if [firstLayoutFinished] is false, it would throw errors to report illegal usage
  bool get firstLayoutFinished;

  /// if the observing [RenderSliver] is visible in its closest ancestor [RenderViewportBase]
  bool get sliverVisible;

  /// if a [RenderSliver] is being observed by this observer
  /// if false, it would throw errors to report illegal usage
  /// only when [isActive] is true, the observer could work normally
  bool get isActive;

  /// this observer should start observing the [RenderObserverProxy]
  /// typically, it should be true
  bool _observing = true;
  bool get isObserving => _observing;

  /// sometimes, [ObserverProxy] may not be descendants of [RenderSliver] temporarily
  /// e.g., [ReorderableListView] is ordering
  /// using [pause] to stop observing temporarily
  /// using [resume] to continue observing
  void pause() {
    _observing = false;
  }

  void resume() {
    _observing = true;
  }

  /// sometimes, the target index to which users want to scroll may not be same as the current render index
  /// by using [targetToRenderIndex], users could define how to map the target index to a render index
  /// sometimes, the render index may not be the target index to which users want to scroll
  /// by setting [renderToTargetIndex], users could define how to convert the render index to the target index
  ///
  /// e.g., when using [ListView.separated], the item index may not be equal to its render index
  /// since separators would be also counted as the children of [RenderSliver]
  ///
  /// e.g., when using [ReorderableListView], items may be reordered, as a result, the target index may not be
  /// same as its render index
  ///
  /// by setting [targetToRenderIndex] and [renderToTargetIndex], users could have better control
  /// [jumpToIndex]/[animateToIndex] may use [targetToRenderIndex] if applicable before doing normalized;
  /// when checking those revealed items, [renderToTargetIndex] may be used
  IndexConverter? targetToRenderIndex;

  IndexConverter? renderToTargetIndex;

  /// make the observed [RenderSliver] visible in its closest ancestor [RenderViewportBase]
  void showInViewport(
    ViewportOffset offset, {
    Duration duration = Duration.zero,
    Curve curve = Curves.ease,
  });

  /// if [index] is revealed in its closest ancestor [RenderSliver]
  /// typically, [index] must have been observed before checking [isRevealed]
  /// [strategy] is used to determine the threshold of which [index] should be regarded as revealed/visible
  /// [shouldNormalized] indicates if we need to [normalizeIndex] into a valid range
  /// [ScrollExtent] is the current scroll extent built from [ScrollPosition] to
  /// indicate the current min/max scroll extent and pixels
  /// if [shouldConvert] is true, it would try to use [targetToRenderIndex] to convert [index] to its render index
  /// [shouldConvert] is always false when using internally for [jumpToIndex] and [animateToIndex]
  bool isRevealed(
    int index, {
    required ScrollExtent scrollExtent,
    PredicatorStrategy strategy = PredicatorStrategy.tolerance,
    bool shouldNormalized = true,
    bool shouldConvert = false,
  });

  /// estimate the scroll offset for [target]
  /// if [target] has been observed, it should return the observed scroll offset
  /// if not, it would use some other information to estimate the scroll offset for [target]
  /// See:
  ///   * [ScrollObserver.singleChild], which implements how to do estimation for slivers with single child
  ///   * [ScrollObserver.multiChild], which implements how to do estimation for slivers with multi children
  double estimateScrollOffset(
    int target, {
    required ScrollExtent scrollExtent,
  });

  /// normalize [index] to a valid range.
  /// typically for a [ScrollObserver] with a finite item count
  /// See:
  ///   * [ScrollObserver.singleChild]
  ///   * [ScrollObserver.multiChild]
  int normalizeIndex(int index);

  /// get the observed [ItemScrollExtent] for [index]
  ItemScrollExtent? getItemScrollExtent(int index);

  /// get the observed [Size] for [index]
  Size? getItemSize(int index);

  /// releasing some resources hold by this observer, e.g., [RenderSliver]
  void clear();

  /// ensure [firstLayoutFinished] is true to guarantee legal usage for [estimateScrollOffset] before continuing
  void checkFirstLayoutFinished() {
    if (!firstLayoutFinished) {
      throw ErrorDescription(
        "[ScrollObserver] has never been observed since no [doFinishLayout] is invoked. "
        "At this time, estimate item's scroll offset cannot be completed",
      );
    }
  }
}

void _scheduleAsPostFrameCallback(void Function(Duration) callback) {
  WidgetsBinding.instance.addPostFrameCallback(callback);
}

mixin ObserverScrollImpl on ObserverScrollInterface {
  @override
  void clear() {
    if (_revealing != null && !_revealing!.isCompleted) {
      _revealing?.complete(false);
    }
    _revealing = null;
    _observing = false;
    targetToRenderIndex = null;
    renderToTargetIndex = null;
  }

  /// jump to [index] based on the given [position]
  /// this [ScrollObserver] and [position] should be associated/attached to the same [ScrollController]
  /// if [closeToEdge] is true, we would try scrolling [index] to the edge of [ScrollView.reverse] if not over scrolling
  void jumpToIndex(
    int index, {
    required ScrollPosition position,
    bool closeToEdge = true,
  }) {
    index = targetToRenderIndex?.call(index) ?? index;

    _jumpToUnrevealedIndex(
      index,
      position: position,
      closeToEdge: closeToEdge,
    );
  }

  Completer<bool>? _revealing;

  /// animate to [index] based on the given [position]
  ///
  /// if a revealing task  is ongoing, schedule and execute this task once the previous task is completed
  /// by doing so, we could avoid multi revealing tasks ongoing
  /// the returned result indicates if all chained tasks are completed successfully
  ///
  /// this [ScrollObserver] and [position] should be associated/attached to the same [ScrollController]
  /// if [closeToEdge] is true, we would try scrolling [index] to the edge of [ScrollView.reverse] if not over scrolling
  Future<bool> animateToIndex(
    int index, {
    required ScrollPosition position,
    required Duration duration,
    required Curve curve,
    bool closeToEdge = true,
  }) async {
    index = targetToRenderIndex?.call(index) ?? index;

    if (_revealing != null && !_revealing!.isCompleted) {
      return _revealing!.future.then(
        (canSchedule) {
          if (canSchedule) {
            return animateToIndex(
              index,
              position: position,
              duration: duration,
              curve: curve,
              closeToEdge: closeToEdge,
            );
          }
          return canSchedule;
        },
      );
    } else {
      _revealing = null;
      _revealing = Completer();

      _animateToUnrevealedIndex(
        index,
        position: position,
        duration: duration,
        curve: curve,
        closeToEdge: closeToEdge,
      );
      return _revealing!.future;
    }
  }

  /// [position] is the current attached [ScrollPosition]
  /// if [sliverVisible] or [firstLayoutFinished] is false, it turns out we could not estimate scroll offset now
  /// so we schedule it at the next frame so as to some required information is ready for estimation
  /// then, we would estimate the scroll offset for [index] to jump to [index] gradually
  /// if [closeToEdge] is true, we would try scrolling [index] to the edge of [ScrollView.reverse] if not over scrolling
  void _jumpToUnrevealedIndex(
    int index, {
    required ScrollPosition position,
    bool closeToEdge = true,
  }) {
    _checkActive();

    if (!sliverVisible || !firstLayoutFinished) {
      if (!sliverVisible) {
        showInViewport(position);
      }

      _scheduleAsPostFrameCallback(
        (_) {
          _jumpToUnrevealedIndex(
            index,
            position: position,
            closeToEdge: closeToEdge,
          );
        },
      );
    } else {
      index = normalizeIndex(index);

      final indexRevealed = isRevealed(
        index,
        scrollExtent: ScrollExtent.fromPosition(position),
        strategy: PredicatorStrategy.inside,
      );

      if (!indexRevealed) {
        _moveWithoutCheck(index, position: position);
        _scheduleAsPostFrameCallback(
          (_) {
            _jumpToUnrevealedIndex(
              index,
              position: position,
              closeToEdge: closeToEdge,
            );
          },
        );
      } else if (indexRevealed && closeToEdge) {
        _adjustScrollWithTolerance(index, position: position);
      }
    }
  }

  /// [position] is the current attached [ScrollPosition]
  /// if [sliverVisible] or [firstLayoutFinished] is false, it turns out we could not estimate scroll offset now
  /// so we schedule it at the next frame so as to some required information is ready for estimation
  /// then, we would estimate the scroll offset for [index] to animate to [index] gradually
  /// if [closeToEdge] is true, we would try scrolling [index] to the edge of [ScrollView.reverse] if not over scrolling
  FutureOr<void> _animateToUnrevealedIndex(
    int index, {
    required ScrollPosition position,
    required Duration duration,
    required Curve curve,
    bool closeToEdge = true,
  }) async {
    assert(_revealing != null);

    _checkActive();

    if (!sliverVisible) {
      showInViewport(position, duration: duration, curve: curve);
      Future.delayed(duration, () {
        _animateToUnrevealedIndex(
          index,
          position: position,
          duration: duration,
          curve: curve,
          closeToEdge: closeToEdge,
        );
      });
    } else if (!firstLayoutFinished) {
      _scheduleAsPostFrameCallback((_) {
        _animateToUnrevealedIndex(
          index,
          position: position,
          duration: duration,
          curve: curve,
          closeToEdge: closeToEdge,
        );
      });
    } else {
      index = normalizeIndex(index);

      final indexRevealed = isRevealed(
        index,
        scrollExtent: ScrollExtent.fromPosition(position),
        strategy: PredicatorStrategy.inside,
      );

      if (!indexRevealed) {
        await _moveWithoutCheck(
          index,
          position: position,
          curve: curve,
          duration: duration,
        );

        _scheduleAsPostFrameCallback((_) {
          _animateToUnrevealedIndex(
            index,
            position: position,
            duration: duration,
            curve: curve,
            closeToEdge: closeToEdge,
          );
        });
      } else if (indexRevealed && closeToEdge) {
        await _adjustScrollWithTolerance(
          index,
          position: position,
          curve: curve,
        );
        _revealing?.complete(true);
      } else {
        _revealing?.complete(true);
      }
    }
  }

  /// move [index] to the estimated scroll offset calculated by [estimateScrollOffset]
  FutureOr<void> _moveWithoutCheck(
    int index, {
    required ScrollPosition position,
    Duration? duration,
    Curve? curve,
  }) {
    final targetOffset = estimateScrollOffset(
      index,
      scrollExtent: ScrollExtent.fromPosition(position),
    );

    return position.moveTo(
      targetOffset,
      duration: duration,
      curve: curve,
    );
  }

  /// adjust [index] to the leading edge
  /// by comparing the difference between the estimated scroll offset and the current pixels of [ScrollPosition]
  /// finalize moving only if the diff is over [_kPixelDiffTolerance] and not over scrolling
  FutureOr<void> _adjustScrollWithTolerance(
    int index, {
    required ScrollPosition position,
    Curve? curve,
  }) {
    final estimated = estimateScrollOffset(
      index,
      scrollExtent: ScrollExtent.fromPosition(position),
    );
    final pixelDiff = estimated - position.pixels;

    // print(
    //     "estimated: $estimated, current: ${position.pixels} diff: $pixelDiff");

    final canScroll =
        position.maxScrollExtent > position.pixels || position.pixels > 0;
    final shouldAdjust = pixelDiff.abs() > _kPixelDiffTolerance;

    if (canScroll && shouldAdjust) {
      return position.moveTo(
        estimated,
        duration: (!hasMultiChild) ? _kDefaultAdjustDuration : null,
        curve: curve ?? Curves.bounceInOut,
      );
    }
    return null;
  }

  void _checkActive() {
    if (!isActive) {
      throw ErrorDescription(
        "[ScrollObserver] is not be active (no [RenderSliver] is being observed by it). "
        "Please ensure each item is wrapped by [ObserverProxy]. items that belong to the same [RenderSliver] should share "
        "the same [ScrollObserver] instead of creating a different [ScrollObserver] for each. "
        "If you ensure they are wrapped by [ObserverProxy], this error may be caused by "
        "the first build is not completed when invoking [State.initState]. "
        "You could use jumpToIndex/animateToIndex by adding them as post frame callbacks. "
        "See [WidgetsBinding.instance.addPostFrameCallback].",
      );
    }
  }
}