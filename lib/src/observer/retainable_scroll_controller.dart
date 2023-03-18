import 'package:flutter/widgets.dart';

/// A [ScrollController] enables retaining the current scroll offset.
/// When inserting/adding a new item into the first index of [ListView.children],
/// it would scroll up/down pixels that represents the main axis size of the new item,
/// since the [ScrollPosition.maxScrollExtent] is changed after layouting the new added item.
/// However, the [ScrollPosition.pixels] does not change, and therefore, the existing items would
/// try to use the old pixels to calculate their painting offsets.
///
/// By using [retainOffset], [RetainableScrollPosition] would try to correct existing items' scroll offset,
/// if the max scroll extent happens.
///
/// See also:
///   * [RetainableScrollPosition], which would correct existing items' scroll offsets and not scroll them up/down,
///   when the new item is inserting at the first index of [ListView.children]
class RetainableScrollController extends ScrollController {
  RetainableScrollController({
    super.initialScrollOffset,
    super.keepScrollOffset,
    super.debugLabel,
  });

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) {
    return RetainableScrollPosition(
      physics: physics,
      context: context,
      initialPixels: initialScrollOffset,
      keepScrollOffset: keepScrollOffset,
      oldPosition: oldPosition,
      debugLabel: debugLabel,
    );
  }

  void retainOffset() {
    position.retainOffset();
  }

  @override
  RetainableScrollPosition get position =>
      super.position as RetainableScrollPosition;
}

class RetainableScrollPosition extends ScrollPositionWithSingleContext {
  RetainableScrollPosition({
    required super.physics,
    required super.context,
    super.initialPixels = 0.0,
    super.keepScrollOffset,
    super.oldPosition,
    super.debugLabel,
  });

  double? _oldPixels;
  double? _oldMaxScrollExtent;

  bool get shouldRestoreRetainedOffset =>
      _oldMaxScrollExtent != null && _oldPixels != null;

  void retainOffset() {
    if (!hasPixels) return;
    _oldPixels = pixels;
    _oldMaxScrollExtent = maxScrollExtent;
  }

  /// when the viewport layouts its children, it would invoke [applyContentDimensions] to
  /// update the [minScrollExtent] and [maxScrollExtent].
  /// When it happens, [shouldRestoreRetainedOffset] would determine if correcting the current [pixels],
  /// so that the final scroll offset is matched to the previous items' scroll offsets.
  /// Therefore, avoiding scrolling down/up when the new item is inserted into the first index of the list.
  @override
  bool applyContentDimensions(double minScrollExtent, double maxScrollExtent) {
    final applied =
        super.applyContentDimensions(minScrollExtent, maxScrollExtent);

    bool isPixelsCorrected = false;

    if (shouldRestoreRetainedOffset) {
      final diff = maxScrollExtent - _oldMaxScrollExtent!;
      if (_oldPixels! > minScrollExtent && diff > 0) {
        correctPixels(pixels + diff);
        isPixelsCorrected = true;
      }
      _oldMaxScrollExtent = null;
      _oldPixels = null;
    }

    return applied && !isPixelsCorrected;
  }
}
