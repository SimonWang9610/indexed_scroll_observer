bool _outside(
  double leadingOffset,
  double trailingOffset, {
  required double leadingEdge,
  required double trailingEdge,
  required double maxScrollExtent,
  double? tolerance,
}) {
  return trailingOffset <= leadingEdge || leadingOffset >= trailingEdge;
}

bool _inside(
  double leadingOffset,
  double trailingOffset, {
  required double leadingEdge,
  required double trailingEdge,
  required double maxScrollExtent,
  double? tolerance,
}) {
  return leadingOffset >= leadingEdge && trailingOffset <= trailingEdge;
}

bool _contain(
  double leadingOffset,
  double trailingOffset, {
  required double leadingEdge,
  required double trailingEdge,
  required double maxScrollExtent,
  double? tolerance,
}) =>
    leadingOffset < leadingEdge && trailingOffset > trailingEdge;

bool _tolerate(
  double leadingOffset,
  double trailingOffset, {
  required double leadingEdge,
  required double trailingEdge,
  required double maxScrollExtent,
  double? tolerance = 0.3,
}) {
  assert(tolerance != null);

  if (_outside(
    leadingOffset,
    trailingOffset,
    leadingEdge: leadingEdge,
    trailingEdge: trailingEdge,
    maxScrollExtent: maxScrollExtent,
    tolerance: tolerance,
  )) {
    return false;
  } else if (_inside(
    leadingOffset,
    trailingOffset,
    leadingEdge: leadingEdge,
    trailingEdge: trailingEdge,
    maxScrollExtent: maxScrollExtent,
    tolerance: tolerance,
  )) {
    return true;
  } else if (_contain(
    leadingOffset,
    trailingOffset,
    leadingEdge: leadingEdge,
    trailingEdge: trailingEdge,
    maxScrollExtent: maxScrollExtent,
    tolerance: tolerance,
  )) {
    return (trailingEdge - leadingEdge) / (trailingOffset - leadingOffset) >
        tolerance!;
  } else {
    final total = trailingOffset - leadingOffset;

    final part = leadingOffset < leadingEdge
        ? trailingOffset - leadingEdge
        : trailingEdge - leadingOffset;
    return part / total > tolerance!;
  }
}

typedef OnstagePredictorHandler = bool Function(
  double leadingOffset,
  double trailingOffset, {
  required double leadingEdge,
  required double trailingEdge,
  required double maxScrollExtent,
  double? tolerance,
});

/// if [VisibilityStrategy.tolerance],
/// the item would be predicated as visible only when the visible ratio is greater than [tolerance].
/// if [VisibilityStrategy.inside],
/// the item would be predicted as visible only when the total item is visible in the viewport
/// [leadingOffset] would be the global scroll Offset for the item starts.
/// [trailingOffset] would be the global scroll offset that is calculated:[leadingOffset] + itemSize.
/// [leadingEdge] is [ScrollPosition.pixels], and
/// [trailingEdge] would be calculated: [leadingEdge] + [SliverConstraints.viewportMainAxisExtent].
enum VisibilityStrategy {
  inside(_inside),
  tolerance(_tolerate);

  final OnstagePredictorHandler handle;

  const VisibilityStrategy(this.handle);
}
