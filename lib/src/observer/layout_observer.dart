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
  bool get firstLayoutFinished => isActive && !shouldUpdateOrigin;

  /// should update the origin for [renderObject]
  bool _shouldUpdateOrigin = false;
  bool get shouldUpdateOrigin => _shouldUpdateOrigin;

  /// once [onLayout] is invoked, it would be true to indicate
  /// that it require invoking [doFinishLayout] at least once
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
  /// since all items' scroll offsets are relative to the closest [RenderAbstractViewport;
  /// otherwise, we should find the closest viewport to calculate its [origin]
  void _updateRenderOrigin() {
    if (_shouldUpdateOrigin && isObserving) {
      if (_renderObject is RenderAbstractViewport) {
        final paintBounds = _renderObject!.paintBounds;

        origin = RevealedOffset(offset: 0, rect: paintBounds);
      } else {
        final viewport = RenderAbstractViewport.of(_renderObject);

        origin = viewport.getOffsetToReveal(_renderObject!, 0.0);
      }

      _shouldUpdateOrigin = false;
    }
  }

  void clear() {
    _renderObject = null;
    _shouldUpdateOrigin = false;
    shouldDoFinishLayout = false;
  }

  void showInViewport(
    ViewportOffset offset, {
    Duration duration = Duration.zero,
    Curve curve = Curves.ease,
  }) {
    if (!isActive) return;

    final viewport = RenderAbstractViewport.of(_renderObject);

    viewport.showOnScreen(
      descendant: _renderObject,
      duration: duration,
      curve: curve,
    );
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

  bool isDesiredParentData(ParentData? parentData);
}
