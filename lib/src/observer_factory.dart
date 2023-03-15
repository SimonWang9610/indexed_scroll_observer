import 'package:flutter/rendering.dart';

import 'observer/sliver_observer.dart';
import 'observer/box_observer.dart';

class ScrollObserver {
  /// create a [ScrollObserver] for observing a sliver with single child, e.g., [SliverAppBar]
  static SliverScrollObserver sliverSingle() => SingleChildSliverObserver();

  /// create a [ScrollObserver] for observing a sliver with multi children, e.g., [SliverList]/[SliverGrid]
  static SliverScrollObserver sliverMulti({int? itemCount}) =>
      MultiChildSliverObserver(
        itemCount: itemCount,
      );

  /// create a [ScrollObserver] for observing a [RenderBox] with single child.
  /// typically, this is a rare case.
  static BoxScrollObserver boxSingle(Axis axis) =>
      SingleChildBoxObserver(axis: axis);

  /// create a [ScrollObserver] for observing a [RenderBox] with multi children, e.g., [ListWheelScrollView].
  /// Also used for [SingleChildScrollView] whose child has multi children,
  /// see: example/example/single_child_scroll_view_example.dart.
  static BoxScrollObserver boxMulti({required Axis axis, int? itemCount}) =>
      MultiChildBoxObserver(
        axis: axis,
        itemCount: itemCount,
      );
}
