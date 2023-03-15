import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:positioned_scroll_observer/src/observer/layout_observer.dart';
import 'package:positioned_scroll_observer/src/observer/observer_interface.dart';
import 'package:positioned_scroll_observer/src/observer/scroll_extent.dart';

import 'onstage_strategy.dart';

mixin MultiChildEstimation<T extends RenderObject>
    on LayoutObserver<T>, ObserverScrollInterface {
  final Map<int, ItemScrollExtent> _items = {};
  final Map<int, Size> _sizes = {};

  double _estimatedAveragePageGap = 0;

  int? _first;
  int? _last;

  @override
  bool get firstLayoutFinished =>
      _first != null && _last != null && super.firstLayoutFinished;

  void updateRange(int? first, int? last) {
    _first = first;
    _last = last;
  }

  Map<int, Size> get sizes => _sizes;
  Map<int, ItemScrollExtent> get items => _items;

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
      /// avoid division by zero when estimating
      final currentIndexGap = _last! - _first! > 0 ? _last! - _first! : 1;

      if (target < _first!) {
        estimated += getItemScrollExtent(_first!)!.mainAxisOffset +
            (target - _first!) / currentIndexGap * _estimatedAveragePageGap;
      } else if (target > _last!) {
        estimated += getItemScrollExtent(_last!)!.mainAxisOffset +
            (target - _last!) / currentIndexGap * _estimatedAveragePageGap;
      } else {
        assert(
          false,
          "This line should never reach. Since $target is in [$_first, $_last], "
          "its [itemScrollModel] should be observed during $runtimeType.didFinishLayout",
        );
      }
    }

    final leadingEdge = max(origin!.offset, scrollExtent.min);

    return clampDouble(estimated, leadingEdge, scrollExtent.max);
  }

  void updateEstimation(double totalExtent, int count) {
    final average = count == 0 ? totalExtent : totalExtent / count;

    _estimatedAveragePageGap = (average + _estimatedAveragePageGap) / 2;
  }

  @override
  ItemScrollExtent? getItemScrollExtent(int index) => items[index];

  @override
  Size? getItemSize(int index) => sizes[index];

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
  void debugCheckOnstageItems({
    required ScrollExtent scrollExtent,
    PredicatorStrategy strategy = PredicatorStrategy.tolerance,
  }) {
    List<int> onstageItems = [];

    for (final key in items.keys) {
      if (isRevealed(key, scrollExtent: scrollExtent, strategy: strategy)) {
        onstageItems.add(renderToTargetIndex?.call(key) ?? key);
      }
    }

    print("$runtimeType: $onstageItems");
  }

  @override
  void clear() {
    super.clear();
    _items.clear();
    _sizes.clear();
    _first = null;
    _last = null;
    _estimatedAveragePageGap = 0;
  }
}

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

  @override
  double estimateScrollOffset(
    int target, {
    required ScrollExtent scrollExtent,
  }) {
    return scrollExtent.current;
  }

  @override
  void debugCheckOnstageItems({
    required ScrollExtent scrollExtent,
    PredicatorStrategy strategy = PredicatorStrategy.tolerance,
  }) {
    print("$runtimeType: $renderVisible");
  }

  @override
  void clear() {
    super.clear();
    _size = null;
    _itemScrollExtent = null;
  }
}
