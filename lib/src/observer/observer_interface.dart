import 'package:flutter/rendering.dart';

import 'dart:async';

import 'package:flutter/widgets.dart';

import 'scroll_extent.dart';
import 'onstage_strategy.dart';

abstract class ObserverScrollInterface {
  bool get hasMultiChild;
  bool get firstLayoutFinished;
  bool get sliverVisible;
  bool get isActive;

  void showInViewport(
    ViewportOffset offset, {
    Duration duration = Duration.zero,
    Curve curve = Curves.ease,
  });

  bool isOnStage(
    int index, {
    required ScrollExtent scrollExtent,
    PredicatorStrategy strategy = PredicatorStrategy.tolerance,
    bool shouldNormalized = true,
  });

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

  /// [ScrollObserver] that has only on child would always return 0
  /// the below rules are applied for [ScrollObserver] that has multi children
  /// 1) [itemCount] is null, we treat it is observing an infinite list/grid, so return [index] directly
  /// 2) clamp [index] between [0, [itemCount - 1])
  int normalizeIndex(int index);

  ItemScrollExtent? getItemScrollExtent(int index);
  Size? getItemSize(int index);

  void clear();

  void checkFirstLayoutFinished() {
    if (!firstLayoutFinished) {
      throw ErrorDescription(
        "[ScrollObserver] has never been observed since no [doFinishLayout] is invoked. "
        "At this time, estimate item's scroll offset cannot be completed",
      );
    }
  }
}

const double _kPixelDiffTolerance = 5;

const Duration _kDefaultDuration = Duration(milliseconds: 60);

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
  }

  void jumpToIndex(
    int index, {
    required ScrollPosition position,
    bool closeToEdge = true,
  }) {
    _jumpToUnrevealedIndex(
      index,
      position: position,
      closeToEdge: closeToEdge,
    );
  }

  Completer<bool>? _revealing;

  /// animate to index using the given [ScrollPosition]
  /// if a revealing task  is ongoing, schedule and execute this task  once the previous task is completed
  /// by doing so, we could avoid multi revealing tasks ongoing
  /// the returned result indicates if all chained tasks are completed successfully
  Future<bool> animateToIndex(
    int index, {
    required ScrollPosition position,
    required Duration duration,
    required Curve curve,
    bool closeToEdge = true,
  }) async {
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

      final indexRevealed = isOnStage(
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

      final indexRevealed = isOnStage(
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
          duration: duration,
        );
        _revealing?.complete(true);
      } else {
        _revealing?.complete(true);
      }
    }
  }

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

  FutureOr<void> _adjustScrollWithTolerance(
    int index, {
    required ScrollPosition position,
    Duration? duration,
    Curve? curve,
  }) {
    final estimated = estimateScrollOffset(
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
          duration ?? ((!hasMultiChild) ? _kDefaultDuration : null);
      return position.moveTo(estimated,
          duration: effectiveDuration, curve: curve);
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
