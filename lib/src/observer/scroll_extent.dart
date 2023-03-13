import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';

@immutable
class ScrollExtent {
  /// the min scroll extent of [ScrollPosition]
  final double min;

  /// the max scroll extent of [ScrollPosition]
  final double max;

  /// the current scroll offset of [ScrollPosition]
  final double current;

  const ScrollExtent({
    this.min = 0.0,
    this.max = 0.0,
    this.current = 0.0,
  });

  factory ScrollExtent.fromPosition(ScrollPosition position) {
    return ScrollExtent(
      min: position.minScrollExtent,
      max: position.maxScrollExtent,
      current: position.pixels,
    );
  }

  @override
  bool operator ==(covariant ScrollExtent other) {
    return identical(this, other) || (hashCode == other.hashCode);
  }

  @override
  int get hashCode => min.hashCode ^ max.hashCode ^ current.hashCode;

  @override
  String toString() =>
      ("ScrollExtent(min: $min, max: $max, current: $current)");
}

/// [ItemScrollExtent.multi] is for items who have an ancestor [RenderSliver] that has multi child.
/// [ItemScrollExtent.single] is for the item who has an ancestor [RenderSliver] that only has on child.
class ItemScrollExtent {
  final int index;
  final double mainAxisOffset;
  final double? crossAxisOffset;

  const ItemScrollExtent({
    required this.index,
    required this.mainAxisOffset,
    this.crossAxisOffset,
  });

  factory ItemScrollExtent.empty() =>
      const ItemScrollExtent(index: 0, mainAxisOffset: 0);

  factory ItemScrollExtent.multi(SliverMultiBoxAdaptorParentData parentData) {
    return ItemScrollExtent(
      index: parentData.index!,
      mainAxisOffset: parentData.layoutOffset!,
      crossAxisOffset: parentData is SliverGridParentData
          ? parentData.crossAxisOffset!
          : null,
    );
  }

  factory ItemScrollExtent.single(
      SliverPhysicalParentData parentData, Size size,
      {required Axis axis}) {
    double mainAxisOffset = 0.0;
    double crossAxisOffset = 0.0;

    switch (axis) {
      case Axis.vertical:
        mainAxisOffset = parentData.paintOffset.dy;
        crossAxisOffset = parentData.paintOffset.dx;
        break;
      case Axis.horizontal:
        mainAxisOffset = parentData.paintOffset.dx;
        crossAxisOffset = parentData.paintOffset.dy;
        break;
    }

    return ItemScrollExtent(
      index: 0,
      mainAxisOffset: mainAxisOffset,
      crossAxisOffset: crossAxisOffset,
    );
  }

  @override
  bool operator ==(covariant ItemScrollExtent other) {
    return identical(this, other) || hashCode == other.hashCode;
  }

  @override
  int get hashCode =>
      index.hashCode ^
      mainAxisOffset.hashCode ^
      (crossAxisOffset?.hashCode ?? 0);

  @override
  String toString() {
    return "ItemScrollExtent(index: $index, mainAxisOffset: $mainAxisOffset, crossAxisOffset: $crossAxisOffset)";
  }
}
