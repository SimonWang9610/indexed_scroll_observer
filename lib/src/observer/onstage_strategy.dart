import 'package:flutter/foundation.dart';

bool _outside(
  double leadingOffset,
  double trailingOffset, {
  required double leadingEdge,
  required double trailingEdge,
}) {
  return trailingOffset <= leadingEdge || leadingOffset >= trailingEdge;
}

bool _inside(
  double leadingOffset,
  double trailingOffset, {
  required double leadingEdge,
  required double trailingEdge,
}) {
  return leadingOffset >= leadingEdge && trailingOffset <= trailingEdge;
}

bool _contain(
  double leadingOffset,
  double trailingOffset, {
  required double leadingEdge,
  required double trailingEdge,
}) =>
    leadingOffset < leadingEdge && trailingOffset > trailingEdge;

bool _tolerate(
  double leadingOffset,
  double trailingOffset, {
  required double leadingEdge,
  required double trailingEdge,
  required double maxScrollExtent,
  double tolerance = 0.3,
}) {
  if (_outside(leadingOffset, trailingOffset,
      leadingEdge: leadingEdge, trailingEdge: trailingEdge)) {
    return false;
  } else if (_inside(leadingOffset, trailingOffset,
      leadingEdge: leadingEdge, trailingEdge: trailingEdge)) {
    return true;
  } else if (_contain(leadingOffset, trailingOffset,
      leadingEdge: leadingEdge, trailingEdge: trailingEdge)) {
    return (trailingEdge - leadingEdge) / (trailingOffset - leadingOffset) >
        tolerance;
  } else {
    final total = trailingOffset - leadingOffset;

    final part = leadingOffset < leadingEdge
        ? trailingOffset - leadingEdge
        : trailingEdge - leadingOffset;
    return part / total > tolerance;
  }
}

/// the leading edge would be [ScrollExtent.current]
/// the trailing edge would be: the leading edge + [SliverConstraints.viewportMainAxisExtent]
enum PredicatorStrategy {
  /// this strategy would check if (leadingOffset > leadingEdge && trailingOffset < trailingEdge)
  inside,

  /// this strategy would check using [_tolerate] to see if the visible part is greater than the specified tolerance
  /// the specific tolerance should be in [0, 1.0]
  tolerance,
}

class OnstagePredicator {
  /// if [PredicatorStrategy.tolerance],
  /// the item would be predicated as visible only when the visible ratio is greater than [tolerance].
  /// if [PredicatorStrategy.inside],
  /// the item would be predicted as visible only when the total item is visible in [leadingEdge] and [trailingEdge].
  /// [leadingOffset] would be the global scroll Offset for the item starts.
  /// [trailingOffset] would be the global scroll offset that is calculated:[leadingOffset] + itemSize.
  /// [leadingEdge] is [ScrollPosition.pixels], and
  /// [trailingEdge] would be calculated: [leadingEdge] + [SliverConstraints.viewportMainAxisExtent].
  static bool predict(
    double leadingOffset,
    double trailingOffset, {
    required double leadingEdge,
    required double trailingEdge,
    required double maxScrollExtent,
    double tolerance = 0.5,
    PredicatorStrategy strategy = PredicatorStrategy.tolerance,
  }) {
    switch (strategy) {
      case PredicatorStrategy.tolerance:
        return _tolerate(
          leadingOffset,
          trailingOffset,
          leadingEdge: leadingEdge,
          trailingEdge: trailingEdge,
          tolerance: clampDouble(tolerance, 0, 1.0),
          maxScrollExtent: maxScrollExtent,
        );
      case PredicatorStrategy.inside:
        return _inside(
          leadingOffset,
          trailingOffset,
          leadingEdge: leadingEdge,
          trailingEdge: trailingEdge,
        );
    }
  }
}
