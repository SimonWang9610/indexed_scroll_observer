import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:positioned_scroll_observer/src/observer/layout_observer.dart';
import 'package:positioned_scroll_observer/src/observer/observer_interface.dart';
import 'package:positioned_scroll_observer/src/observer/scroll_extent.dart';

import 'visibility_strategy.dart';

/// Used for observers whose [hasMultiChild] is true.
/// Such observers need to observe multi children for a [RenderObject],
/// and [estimateScrollOffset] when developers want to scroll to a specific index.
mixin MultiChildEstimation<T extends RenderObject>
    on LayoutObserver<T>, ObserverScrollInterface {
  final Map<int, ItemScrollExtent> _items = {};
  final Map<int, Size> _sizes = {};

  /// the estimated average extent for each item.
  /// updated when [doFinishLayout] actually observes some items.
  /// If the item has a fixed extent, it should be equal to the fixed item extent after serval jump/animate.
  double _averageExtentForEachIndex = 0;

  int _estimatedCrossCount = 1;

  int? _first;
  int? _last;

  @override
  bool get firstLayoutFinished =>
      _first != null && _last != null && super.firstLayoutFinished;

  /// record those children that have been laid out
  void updateRange(int? first, int? last) {
    _first = first;
    _last = last;
  }

  /// the [Size] of laid out children, the key may be its index for [SliverScrollObserver],
  /// or [ParentData.hashCode] for [BoxScrollObserver]
  Map<int, Size> get sizes => _sizes;

  /// the items whose [ItemScrollExtent] have been observed after [doFinishLayout]
  Map<int, ItemScrollExtent> get items => _items;

  /// estimate the scroll offset for [target] based on either its [ItemScrollExtent] or
  /// [_averageExtentForEachIndex].
  /// Use [_first] or [_last] to indicate if scroll up or scroll down.
  /// The final estimation would be clamped between [ScrollExtent.min] and [ScrollExtent.max]
  /// to avoid over scrolling.
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

    double estimated = origin!.offset;

    if (_items.containsKey(target)) {
      estimated += getItemScrollExtent(target)!.mainAxisOffset;
    } else {
      final shouldScrollUp = target < _first!;

      final indexGap = shouldScrollUp ? target - _first! : target - _last!;
      final anchor = shouldScrollUp
          ? getItemScrollExtent(_first!)!.mainAxisOffset
          : getItemScrollExtent(_last!)!.mainAxisOffset;

      estimated += anchor +
          (indexGap / _estimatedCrossCount) * _averageExtentForEachIndex;
    }

    final leadingEdge = max(origin!.offset, scrollExtent.min);

    return clampDouble(estimated, leadingEdge, scrollExtent.max);
  }

  /// average [_averageExtentForEachIndex] based on the current observed [totalExtent],
  /// maybe we should have a better way to summarize the previous estimation: [_averageExtentForEachIndex]
  /// and the current exact extent: [totalExtent]
  void updateEstimation(double totalExtent, int count) {
    final average = count == 0 ? totalExtent : totalExtent / count;

    if (_averageExtentForEachIndex == 0) {
      _averageExtentForEachIndex = average;
    } else {
      _averageExtentForEachIndex = (average + _averageExtentForEachIndex) / 2;
    }
  }

  /// [maxCrossOffset] is cross axis offset of the left/bottom most item
  /// [maxCrossCount] increments when [maxCrossOffset] increments
  void updateMaxCrossCount({
    required int maxCrossCount,
    required double maxCrossOffset,
    required double crossAxisExtent,
  }) {
    if (maxCrossOffset > 0 && maxCrossCount > 0) {
      final crossExtentForEach =
          maxCrossCount > 1 ? maxCrossOffset / maxCrossCount : maxCrossOffset;

      _estimatedCrossCount = (crossAxisExtent / crossExtentForEach).round();
    }
  }

  @override
  ItemScrollExtent? getItemScrollExtent(int index) => items[index];

  /// Different observers may override [getItemSize] base on how they store sizes of items.
  /// e.g., [BoxScrollObserver] would override this method since [sizes]'s key is [ParentData.hashCode]
  /// instead of its [index]
  @override
  Size? getItemSize(int index) => sizes[index];

  ///
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
  double visibleRatioInViewport(ScrollExtent scrollExtent) {
    if (!renderVisible || !firstLayoutFinished) {
      return 0.0;
    } else {
      final leadingEdge = scrollExtent.current;
      final trailingEdge = leadingEdge + mainAxisExtent;
      final totalVisible = trailingEdge - leadingEdge;

      int start = _first!;

      double visibleStart = 0.0;
      double visibleEnd = 0.0;

      bool hasVisibleStart = false;

      while (start <= _last!) {
        final itemScrollExtent = getItemScrollExtent(start)!;
        final leadingOffset = itemScrollExtent.getLeadingOffset(origin!.offset);
        final itemSize = getItemSize(start)!;

        final trailingOffset = itemScrollExtent.getTrailingOffset(
          leadingOffset,
          axis: axis,
          size: itemSize,
        );

        if (!hasVisibleStart) {
          visibleStart = max(leadingEdge, leadingOffset);
          hasVisibleStart = true;
        }

        if (leadingOffset < trailingEdge) {
          visibleEnd = min(trailingEdge, trailingOffset);
        } else {
          break;
        }

        start++;
      }

      final visibleExtent = visibleEnd - visibleStart;

      return clampDouble(visibleExtent / totalVisible, 0, 1);
    }
  }

  @override
  List<int> getVisibleItems({
    required ScrollExtent scrollExtent,
    VisibilityStrategy strategy = VisibilityStrategy.tolerance,
  }) {
    List<int> visibleItems = [];

    for (final key in items.keys) {
      if (isRevealed(key, scrollExtent: scrollExtent, strategy: strategy)) {
        visibleItems.add(renderToTargetIndex?.call(key) ?? key);
      }
    }

    debugPrint("$runtimeType: $visibleItems");
    return visibleItems;
  }

  @override
  void clear() {
    super.clear();
    _items.clear();
    _sizes.clear();
    _first = null;
    _last = null;
    _averageExtentForEachIndex = 0;
  }
}

/// Used for observers whose [hasMultiChild] is false.
/// [itemCount] for such observers is always 1, since it only has one child.
/// therefore, the setter of [itemCount] is always setting as 1.
mixin SingleChildEstimation<T extends RenderObject>
    on LayoutObserver<T>, ObserverScrollInterface {
  Size? _size;
  ItemScrollExtent? _itemScrollExtent;

  Size? get size => _size;
  set size(Size? value) => _size = value;

  ItemScrollExtent? get itemScrollExtent => _itemScrollExtent;
  set itemScrollExtent(ItemScrollExtent? value) => _itemScrollExtent = value;

  @override
  bool get firstLayoutFinished =>
      _size != null && _itemScrollExtent != null && super.firstLayoutFinished;

  @override
  int get itemCount => 1;

  @override
  int normalizeIndex(int index) => 0;

  @override
  ItemScrollExtent? getItemScrollExtent([int index = 0]) => _itemScrollExtent;

  @override
  Size? getItemSize(int index) => _size;

  /// Since we would use [showInViewport] to display the [renderObject] on the screen,
  /// therefore, we could guarantee the child of [renderObject] is also visible on the screen.
  /// As a result, we should never adjust the position of the child.
  @override
  double estimateScrollOffset(
    int target, {
    required ScrollExtent scrollExtent,
  }) {
    return scrollExtent.current;
  }

  @override
  double visibleRatioInViewport(ScrollExtent scrollExtent) {
    if (!renderVisible || !firstLayoutFinished) {
      return 0.0;
    } else {
      double ratio;
      switch (axis) {
        case Axis.vertical:
          ratio = _size!.height / mainAxisExtent;
          break;
        case Axis.horizontal:
          ratio = _size!.width / mainAxisExtent;
          break;
      }

      return clampDouble(ratio, 0, 1.0);
    }
  }

  @override
  List<int> getVisibleItems({
    required ScrollExtent scrollExtent,
    VisibilityStrategy strategy = VisibilityStrategy.tolerance,
  }) {
    debugPrint("$runtimeType: $renderVisible");
    return renderVisible ? [0] : [];
  }

  @override
  void clear() {
    super.clear();
    _size = null;
    _itemScrollExtent = null;
  }
}
