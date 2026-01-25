import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:positioned_scroll_observer/positioned_scroll_observer.dart';

class ObserverProxy<T extends LayoutObserver>
    extends SingleChildRenderObjectWidget {
  final T observer;

  const ObserverProxy({
    super.key,
    super.child,
    required this.observer,
  });

  @override
  RenderScrollObserverProxy<T> createRenderObject(BuildContext context) {
    return RenderScrollObserverProxy<T>(observer: observer);
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderScrollObserverProxy renderObject) {
    renderObject.observer = observer;
  }
}

class RenderScrollObserverProxy<T extends LayoutObserver>
    extends RenderProxyBox {
  T? _observer;

  RenderScrollObserverProxy({
    RenderBox? child,
    T? observer,
  })  : _observer = observer,
        super(child);

  set observer(T? newObserver) {
    if (_observer == newObserver) return;

    assert(
      _observer == null || _observer.runtimeType == newObserver.runtimeType,
      "The new observer does not have the same runtimeType (${newObserver.runtimeType}) "
      "compare to the previous observer (${_observer.runtimeType}).",
    );
    _observer?.clear();

    _observer = newObserver;
    markNeedsLayout();
    markNeedsSemanticsUpdate();
  }

  @override
  void performLayout() {
    super.performLayout();

    final ancestor = _findAncestorRenderObject();

    if (ancestor != null) {
      _observer!.onLayout(
        ancestor,
        size: size,
        parentData: _findDesiredParentData(ancestor),
      );
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);

    if (_observer != null && _observer!.isObserving) {
      _observer?.doFinishLayout();
    }
  }

  RenderObject? _findAncestorRenderObject() {
    if (child == null || _observer == null || !_observer!.isObserving) {
      return null;
    }

    RenderObject? ancestor = parent;

    while (ancestor != null) {
      if (_observer!.isDesiredRenderObject(ancestor)) {
        return ancestor;
      } else {
        ancestor = ancestor.parent;
      }
    }
    return null;
  }

  ParentData? _findDesiredParentData(RenderObject ancestor) {
    if (_observer == null || _observer!.isDesiredParentData(parentData)) {
      return parentData;
    }

    RenderObject? node = parent;
    ParentData? ancestorData = node?.parentData;

    while (ancestorData != null && node != ancestor) {
      if (_observer!.isDesiredParentData(ancestorData)) {
        return ancestorData;
      } else {
        node = node?.parent;
        ancestorData = node?.parentData;
      }
    }

    return null;
  }
}
