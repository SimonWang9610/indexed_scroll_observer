import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'package:flutter/widgets.dart';

import 'scroll_extent.dart';
import 'visibility_strategy.dart';

typedef IndexConverter = int Function(int);

void _scheduleAsPostFrameCallback(void Function(Duration) callback) {
  WidgetsBinding.instance.addPostFrameCallback(callback);
}

/// the tolerance between the scroll offset of items and the current pixels of [ScrollPosition]
const double _kPixelDiffTolerance = 5;

const Duration _kDefaultAdjustDuration = Duration(milliseconds: 60);

abstract class ObserverScrollInterface {
  /// indicates that if some children have been laid out completely and are being painted on the screen,
  bool get firstLayoutFinished;

  double get mainAxisExtent;

  /// if the observing [RenderSliver] is visible in its closest ancestor [RenderViewportBase]
  bool get renderVisible;

  /// the origin of [RenderObject] that is being observed
  RevealedOffset? get origin;

  /// indicates whether a [RenderSliver] is being observed by this observer.
  /// If false, it would throw errors to report illegal usage,
  /// only when [isActive] is true, the observer could work normally.
  bool get isActive;

  /// used by [estimateScrollOffset] to calculate the trailing offset for an item.
  /// See:
  ///   * [ItemScrollExtent.getTrailingOffset]
  Axis get axis;

  /// sometimes, the target index to which users want to scroll may not be same as the current render index,
  /// by using [targetToRenderIndex], users could define how to map the target index to a render index.

  /// e.g., when using [ListView.separated], the item index may not be equal to its render index,
  /// since separators would be also counted as the children of [RenderSliver].
  ///
  /// e.g., when using [ReorderableListView], items may be reordered, as a result, the target index may not be
  /// same as its render index.
  ///
  /// By setting [targetToRenderIndex] and [renderToTargetIndex], users could have better control.
  /// [jumpToIndex]/[animateToIndex] may use [targetToRenderIndex] if applicable before doing normalized;
  /// when checking those revealed items, [renderToTargetIndex] may be used
  IndexConverter? targetToRenderIndex;

  /// sometimes, the render index may not be the target index to which users want to scroll.
  /// by setting [renderToTargetIndex], users could define how to convert the render index to the target index.
  IndexConverter? renderToTargetIndex;

  /// make its observed [RenderObject] visible in its closest ancestor [RenderViewportBase]
  /// we guarantee that [RenderAbstractViewport.of] would find an [RenderAbstractViewport] ancestor,
  /// since the scrollable content is always wrapped in a kind of [RenderAbstractViewport].
  /// [alignment] indicates how you want to align the [RenderObject] on the screen when [RenderObject] is visible.
  /// if [alignment] is 0.0, [RenderObject] would try closing to [ScrollPosition.pixels] as much as possible;
  /// if [alignment] is 1.0, [RenderObject] would try closing to [ScrollPosition.maxScrollExtent] as much as possible;
  /// if [alignment] is 0.5, [RenderObject] would try closing to the center between [ScrollPosition.pixels] and [ScrollPosition.maxScrollExtent]
  /// as much as possible.
  void showInViewport(
    ViewportOffset offset, {
    double alignment = 0.0,
    Duration duration = Duration.zero,
    Curve curve = Curves.ease,
  });

  /// calculate the visible part of the [RenderObject] relative to the main axis extent of its viewport.
  /// for example, the observed [RenderObject] has 200 pixels painted on the screen, while the viewport has
  /// 500 pixels painting extent. The ratio would be 200/500 = 0.4.
  /// The result would never over 1.0, since the visible part can not be greater than the viewport's painting extent.
  /// typically, it is used for multi slivers in a custom scroll view to see if how many ratio of which the sliver is visible in the viewport
  double visibleRatioInViewport(ScrollExtent scrollExtent);

  // todo: need testing
  double? relativePositionInViewport(
    int index, {
    required ScrollExtent scrollExtent,
    double alignment = 0.0,
    bool shouldNormalized = true,
    bool shouldConvert = false,
  }) {
    index = shouldConvert ? targetToRenderIndex?.call(index) ?? index : index;
    final validIndex = shouldNormalized ? normalizeIndex(index) : index;

    final itemScrollExtent = getItemScrollExtent(validIndex);
    final itemSize = getItemSize(validIndex);

    if (!renderVisible ||
        !firstLayoutFinished ||
        itemScrollExtent == null ||
        itemSize == null) {
      return null;
    }

    final leadingOffset = itemScrollExtent.getLeadingOffset(origin!.offset);
    final shift = itemScrollExtent.getMainAxisExtent(axis, itemSize) *
        clampDouble(alignment, 0, 1.0);

    final distanceToLeading = leadingOffset + shift - scrollExtent.current;

    /// index is not painted on the screen
    if (distanceToLeading < 0 || distanceToLeading > mainAxisExtent) {
      return null;
    } else {
      return distanceToLeading / mainAxisExtent;
    }
  }

  /// if [index] is revealed in its closest ancestor [RenderSliver].
  /// typically, [index] must have been observed before checking [isRevealed].
  ///
  /// [strategy] is used to determine the threshold of which [index] should be regarded as revealed/visible.
  ///
  /// [shouldNormalized] indicates if we need to [normalizeIndex] into a valid range.
  ///
  /// [ScrollExtent] is the current scroll extent built from [ScrollPosition] to
  /// indicate the current min/max scroll extent and pixels.
  ///
  /// if [shouldConvert] is true, it would try to use [targetToRenderIndex] to convert [index] to its render index.
  /// [shouldConvert] is always false when using internally for [jumpToIndex] and [animateToIndex].
  ///
  /// Note that [isRevealed] should only be used when [firstLayoutFinished] is completed and [isActive]
  bool isRevealed(
    int index, {
    required ScrollExtent scrollExtent,
    VisibilityStrategy strategy = VisibilityStrategy.tolerance,
    double tolerance = 0.1,
    bool shouldNormalized = true,
    bool shouldConvert = false,
  }) {
    assert(isActive && firstLayoutFinished);

    index = shouldConvert ? targetToRenderIndex?.call(index) ?? index : index;

    final validIndex = shouldNormalized ? normalizeIndex(index) : index;

    final itemScrollExtent = getItemScrollExtent(validIndex);
    final itemSize = getItemSize(validIndex);

    if (!renderVisible || itemScrollExtent == null || itemSize == null) {
      return false;
    }

    final leadingOffset = itemScrollExtent.getLeadingOffset(origin!.offset);

    final double trailingOffset = itemScrollExtent.getTrailingOffset(
      leadingOffset,
      axis: axis,
      size: itemSize,
    );

    final trailingEdge = getTrailingEdgeFromScroll(scrollExtent);

    return strategy.handle(
      leadingOffset,
      trailingOffset,
      leadingEdge: scrollExtent.current,
      trailingEdge: trailingEdge,
      maxScrollExtent: scrollExtent.max,
      tolerance: tolerance,
    );
  }

  /// get the trailing edge for the viewport
  double getTrailingEdgeFromScroll(ScrollExtent scrollExtent);

  /// get the [index]'s main axis extent based on [axis]
  double getMainAxisExtent(int index) {
    final size = getItemSize(index);

    if (size != null) {
      switch (axis) {
        case Axis.vertical:
          return size.height;
        case Axis.horizontal:
          return size.width;
      }
    }
    return 0.0;
  }

  /// estimate the scroll offset for [target].
  /// if [target] has been observed, it should return the observed scroll offset.
  /// if not, it would use some other information to estimate the scroll offset for [target].
  ///
  /// For [SingleChildEstimation], it would return the current [ScrollPosition.pixels] since there is only one child.
  /// For [MultiChildEstimation], it would return the observed scroll offset for [target] if [target] has been observed.
  ///
  /// See:
  ///   * [SingleChildEstimation], which implements how to do estimation for [RenderObject] with single child
  ///   * [MultiChildEstimation], which implements how to do estimation for [RenderObject] with multi children
  double estimateScrollOffset(
    int target, {
    required ScrollExtent scrollExtent,
  });

  /// normalize [index] to a valid range.
  /// typically for a [LayoutObserver] with a finite item count.
  /// See:
  ///   * [MultiChildEstimation], which implements the logic how to normalize for [RenderObject] with multi children
  ///   * [SingleChildEstimation], which implements the logic how to normalize for [RenderObject] with single child
  int normalizeIndex(int index);

  /// get the observed [ItemScrollExtent] for [index]
  ItemScrollExtent? getItemScrollExtent(int index);

  /// get the observed [Size] for [index]
  Size? getItemSize(int index);

  /// releasing some resources hold by this observer, e.g., [RenderSliver]
  void clear() {}

  /// ensure [firstLayoutFinished] is true to guarantee legal usage for [estimateScrollOffset] before continuing
  void checkFirstLayoutFinished() {
    if (!firstLayoutFinished) {
      throw ErrorDescription(
        "[ScrollObserver] has never been observed since no [doFinishLayout] is invoked. "
        "At this time, estimate item's scroll offset cannot be completed",
      );
    }
  }

  void debugCheckOnstageItems({
    required ScrollExtent scrollExtent,
    VisibilityStrategy strategy = VisibilityStrategy.tolerance,
  }) {}
}

mixin ObserverScrollImpl on ObserverScrollInterface {
  @override
  void clear() {
    super.clear();
    if (_revealing != null && !_revealing!.isCompleted) {
      _revealing?.complete(false);
    }
    _revealing = null;
    targetToRenderIndex = null;
    renderToTargetIndex = null;
  }

  /// jump to [index] based on the given [position].
  /// this observer and [position] should be associated/attached to the same [ScrollController].
  /// if [closeToEdge] is true, we would try scrolling [index] to the edge of [ScrollView.reverse] if not over scrolling.
  /// [alignment] only takes effects when the observed [RenderObject] is not visible on the screen,
  /// if the [RenderObject] has been visible on the screen, [alignment] is ignored.
  void jumpToIndex(
    int index, {
    required ScrollPosition position,
    bool closeToEdge = true,
    double alignment = 0.0,
  }) {
    index = targetToRenderIndex?.call(index) ?? index;

    _jumpToUnrevealedIndex(
      index,
      position: position,
      closeToEdge: closeToEdge,
    );
  }

  Completer<bool>? _revealing;

  /// animate to [index] based on the given [position].
  ///
  /// if a revealing task  is ongoing, schedule and execute this task once the previous task is completed.
  /// by doing so, we could avoid multi revealing tasks ongoing.
  /// the returned result indicates if all chained tasks are completed successfully.
  ///
  /// this observer and [position] should be associated/attached to the same [ScrollController].
  /// if [closeToEdge] is true, we would try scrolling [index] to the edge of [ScrollView.reverse] if not over scrolling
  /// [alignment] only takes effects when the observed [RenderObject] is not visible on the screen,
  /// if the [RenderObject] has been visible on the screen, [alignment] is ignored.
  Future<bool> animateToIndex(
    int index, {
    required ScrollPosition position,
    required Duration duration,
    required Curve curve,
    bool closeToEdge = true,
    double alignment = 0.0,
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
              alignment: alignment,
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
        alignment: alignment,
      );
      return _revealing!.future;
    }
  }

  /// [position] is the current attached [ScrollPosition].
  /// if [renderVisible] or [firstLayoutFinished] is false, it turns out we could not estimate scroll offset now,
  /// so we schedule it at the next frame so as to some required information is ready for estimation.
  /// then, we would estimate the scroll offset for [index] to jump to [index] gradually.
  /// if [closeToEdge] is true, we would try scrolling [index] to the edge of [ScrollView.reverse] if not over scrolling.
  void _jumpToUnrevealedIndex(
    int index, {
    required ScrollPosition position,
    bool closeToEdge = true,
    double alignment = 0.0,
  }) {
    _checkActive();

    if (!renderVisible || !firstLayoutFinished) {
      if (!renderVisible) {
        showInViewport(position, alignment: alignment);
      }

      _scheduleAsPostFrameCallback(
        (_) {
          _jumpToUnrevealedIndex(
            index,
            position: position,
            closeToEdge: closeToEdge,
            alignment: alignment,
          );
        },
      );
    } else {
      index = normalizeIndex(index);

      final indexRevealed = isRevealed(
        index,
        scrollExtent: ScrollExtent.fromPosition(position),
        strategy: VisibilityStrategy.inside,
      );

      if (!indexRevealed) {
        _moveWithoutCheck(index, position: position);
        _scheduleAsPostFrameCallback(
          (_) {
            _jumpToUnrevealedIndex(
              index,
              position: position,
              closeToEdge: closeToEdge,
              alignment: alignment,
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
    double alignment = 0.0,
  }) async {
    if (_revealing == null) return;

    _checkActive();

    if (!renderVisible) {
      showInViewport(
        position,
        duration: duration,
        curve: curve,
        alignment: alignment,
      );
      Future.delayed(duration, () {
        _animateToUnrevealedIndex(
          index,
          position: position,
          duration: duration,
          curve: curve,
          closeToEdge: closeToEdge,
          alignment: alignment,
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
          alignment: alignment,
        );
      });
    } else {
      index = normalizeIndex(index);

      final indexRevealed = isRevealed(
        index,
        scrollExtent: ScrollExtent.fromPosition(position),
        strategy: VisibilityStrategy.inside,
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
            alignment: alignment,
          );
        });
      } else if (indexRevealed && closeToEdge) {
        await _adjustScrollWithTolerance(
          index,
          position: position,
          curve: curve,
          allowImplicitAnimating: true,
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
    // print(
    //     "[MOVE]: index : $index, estimated: $targetOffset, current: ${position.pixels} diff: ${targetOffset - position.pixels}");

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
    bool allowImplicitAnimating = false,
    Curve? curve,
  }) {
    final estimated = estimateScrollOffset(
      index,
      scrollExtent: ScrollExtent.fromPosition(position),
    );
    final pixelDiff = estimated - position.pixels;

    // print(
    //     "[ADJUST] index : $index, estimated: $estimated, current: ${position.pixels} diff: $pixelDiff");

    final canScroll =
        position.maxScrollExtent > position.pixels || position.pixels > 0;
    final shouldAdjust = pixelDiff.abs() > _kPixelDiffTolerance;

    if (canScroll && shouldAdjust) {
      return position.moveTo(
        estimated,
        duration: allowImplicitAnimating ? _kDefaultAdjustDuration : null,
        curve: curve,
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
