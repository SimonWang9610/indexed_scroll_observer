import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

typedef MultiChildRenderBox
    = ContainerRenderObjectMixin<RenderBox, ContainerBoxParentData<RenderBox>>;

typedef SingleChildRenderBox = RenderObjectWithChildMixin<RenderBox>;

typedef MultiChildSliver
    = ContainerRenderObjectMixin<RenderBox, SliverMultiBoxAdaptorParentData>;

/// Other kinds of observers should extends [LayoutObserver]
/// to override the functions of [onLayout] and [doFinishLayout] that are used in [RenderScrollObserverProxy]
///
/// By extending [LayoutObserver], the subclasses could be used in [ObserverProxy] and enable to report
/// the layout information for items that they are observing.
///
/// See also:
///   * [RenderObserverProxy], which invoke [LayoutObserver.onLayout] and [LayoutObserver.doFinishLayout]
///   to complete the process of observing
abstract class LayoutObserver<T extends RenderObject> {
  T? _renderObject;

  /// [RenderObject] is being observed
  @protected
  T? get renderObject => _renderObject;

  /// if there is a [RenderObject] that is observed
  bool get isActive => _renderObject != null;

  /// if the first layout is completed.
  /// it should be true as long as [doFinishLayout] is invoked at least once.
  /// once [firstLayoutFinished] is true, indicating that all operations on this
  /// observer could be completed safely.
  bool get firstLayoutFinished => isActive && !shouldUpdateOrigin;

  /// should update the origin for [renderObject]
  bool _shouldUpdateOrigin = false;
  bool get shouldUpdateOrigin => _shouldUpdateOrigin;

  /// once [onLayout] is invoked, it would be true to indicate
  /// that it require invoking [doFinishLayout] at least once.
  /// Users typically do not set [shouldDoFinishLayout] directly.
  @protected
  bool shouldDoFinishLayout = false;

  /// the [renderObject]'s origin
  /// calculated differently for [RenderSliver] and [RenderBox]
  @protected
  RevealedOffset? origin;

  int? _itemCount;
  int? get itemCount => _itemCount;

  set itemCount(int? value) {
    if (_itemCount != value) {
      _itemCount = value;
    }
  }

  bool get hasMultiChild => itemCount == null || itemCount! > 1;

  /// set [renderObject] if both are not identical,
  /// and mark [shouldUpdateOrigin] as true to do [_updateRenderOrigin].
  /// Meanwhile, it should mark [shouldDoFinishLayout] as true since some items are laid out
  @mustCallSuper
  void onLayout(
    T value, {
    required Size size,
    ParentData? parentData,
  }) {
    if (_renderObject != value) {
      _renderObject = value;
      _shouldUpdateOrigin = true;
    }

    shouldDoFinishLayout = true;
  }

  /// active items have been laid out, and some of them are painting,
  /// at this time, we know the layout for [renderObject] must be completed,
  /// so we could [doFinishLayout] safely
  @mustCallSuper
  void doFinishLayout() {
    assert(
      _renderObject != null,
      "No $T is being observed",
    );
    _updateRenderOrigin();
  }

  /// if [renderObject] is [RenderAbstractViewport], the [origin] should be zero,
  /// since all items' scroll offsets are relative to the closest [RenderAbstractViewport];
  /// otherwise, we should find the closest viewport to calculate its [origin]
  void _updateRenderOrigin() {
    if (_shouldUpdateOrigin && isObserving) {
      if (_renderObject is RenderAbstractViewport) {
        final paintBounds = _renderObject!.paintBounds;

        origin = RevealedOffset(offset: 0, rect: paintBounds);
      } else {
        origin = alignVisibleOffset(0.0);
      }

      _shouldUpdateOrigin = false;
    }
  }

  void clear() {
    _renderObject = null;
    _shouldUpdateOrigin = false;
    shouldDoFinishLayout = false;
  }

  /// make the [renderObject] is visible ont the screen.
  /// we guarantee that [RenderAbstractViewport.of] would find an [RenderAbstractViewport] ancestor
  /// for [renderObject], since the scrollable content is always wrapped in a kind of [RenderAbstractViewport].
  /// [alignment] indicates how you want to align the [renderObject] on the screen when [renderObject] is visible.
  /// if [alignment] is 0.0, [renderObject] would try closing to [ScrollPosition.pixels] as much as possible;
  /// if [alignment] is 1.0, [renderObject] would try closing to [ScrollPosition.maxScrollExtent] as much as possible;
  void showInViewport(
    ViewportOffset offset, {
    double alignment = 0.0,
    Duration duration = Duration.zero,
    Curve curve = Curves.ease,
  }) {
    if (!isActive) return;

    final targetOffset = alignVisibleOffset(clampDouble(alignment, 0, 1.0));

    if (targetOffset != null) {
      offset.moveTo(
        targetOffset.offset,
        duration: duration,
        curve: curve,
        clamp: true,
      );
    }
  }

  /// Calculate the position of [renderObject] using the given alignment
  /// See also:
  ///   * [RenderAbstractViewport.getOffsetToReveal], which calculates a [RenderObject]'s position in the viewport.
  RevealedOffset? alignVisibleOffset(double alignment) {
    if (!isActive) return null;

    final viewport = RenderAbstractViewport.of(_renderObject);

    return viewport.getOffsetToReveal(_renderObject!, alignment);
  }

  /// whether this observer should start observing the [RenderObserverProxy].
  /// typically, it should be true
  bool _observing = true;
  bool get isObserving => _observing;

  /// sometimes, [ObserverProxy] may not be descendants of [RenderSliver] temporarily,
  /// e.g., [ReorderableListView] is ordering.
  /// using [pause] to stop observing temporarily.
  void pause() {
    _observing = false;
  }

  /// using [resume] to continue observing.
  void resume() {
    _observing = true;
  }

  /// the available painting extent along the main axis for a viewport
  double get mainAxisExtent;

  /// check if [parentData] is desired for an observer.
  /// it should be implemented by the subclasses of [LayoutObserver]
  bool isDesiredParentData(ParentData? parentData);
}
