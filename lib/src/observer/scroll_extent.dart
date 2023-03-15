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

  /// the hashCode of [ParentData] for this item;
  final int dataHashCode;

  const ItemScrollExtent({
    required this.index,
    required this.mainAxisOffset,
    required this.dataHashCode,
    this.crossAxisOffset,
  });

  /// placeholder for observers implemented with [SingleChildEstimation]
  factory ItemScrollExtent.empty() =>
      const ItemScrollExtent(index: 0, mainAxisOffset: 0, dataHashCode: -1);

  /// used for [SliverScrollObserver] implemented with [MultiChildEstimation]
  factory ItemScrollExtent.fromSliverData(
      SliverMultiBoxAdaptorParentData parentData) {
    return ItemScrollExtent(
      index: parentData.index!,
      mainAxisOffset: parentData.layoutOffset!,
      dataHashCode: parentData.hashCode,
      crossAxisOffset: parentData is SliverGridParentData
          ? parentData.crossAxisOffset!
          : null,
    );
  }

  /// used for [BoxScrollObserver] implemented with [MultiChildEstimation]
  factory ItemScrollExtent.fromBoxData(
      int index, BoxParentData parentData, Axis axis) {
    double mainAxisOffset = 0.0;
    double crossAxisOffset = 0.0;

    switch (axis) {
      case Axis.vertical:
        mainAxisOffset = parentData.offset.dy;
        crossAxisOffset = parentData.offset.dx;
        break;
      case Axis.horizontal:
        mainAxisOffset = parentData.offset.dx;
        crossAxisOffset = parentData.offset.dy;
        break;
    }

    return ItemScrollExtent(
      index: index,
      dataHashCode: parentData.hashCode,
      mainAxisOffset: mainAxisOffset,
      crossAxisOffset: crossAxisOffset,
    );
  }

  /// get the scroll offset relative to its ancestor [RenderObject]
  /// based on its ancestor's [origin].
  double getLeadingOffset(double origin) {
    return origin + mainAxisOffset;
  }

  /// get the trailing scroll offset based on the given [Axis] and its leading scroll offset [leading].
  double getTrailingOffset(double leading,
      {required Axis axis, required Size size}) {
    switch (axis) {
      case Axis.vertical:
        return size.height + leading;
      case Axis.horizontal:
        return size.width + leading;
    }
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
