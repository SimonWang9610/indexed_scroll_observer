import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:positioned_scroll_observer/positioned_scroll_observer.dart';

class ObserverProxy extends SingleChildRenderObjectWidget {
  final LayoutObserver observer;

  const ObserverProxy({
    super.key,
    super.child,
    required this.observer,
  });

  @override
  RenderScrollObserverProxy createRenderObject(BuildContext context) {
    assert(
      () {
        return observer is LayoutObserver<RenderSliver> ||
            observer is LayoutObserver<MultiChildRenderBox> ||
            observer is LayoutObserver<SingleChildRenderBox>;
      }(),
      "Currently, [ObserverProxy] only supports four kinds of observers: [MultiChildSliverObserver], "
      "[SingleChildSliverObserver] for slivers and [MultiChildBoxObserver] and [SingleChildBoxObserver], "
      "for boxes.",
    );

    if (observer is LayoutObserver<RenderSliver>) {
      return RenderScrollObserverProxy<RenderSliver>(
        observer: observer as LayoutObserver<RenderSliver>,
      );
    } else if (observer is LayoutObserver<MultiChildRenderBox>) {
      return RenderScrollObserverProxy<MultiChildRenderBox>(
        observer: observer as LayoutObserver<MultiChildRenderBox>,
      );
    } else {
      return RenderScrollObserverProxy<SingleChildRenderBox>(
        observer: observer as LayoutObserver<SingleChildRenderBox>,
      );
    }
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderScrollObserverProxy renderObject) {
    renderObject.observer = observer;
  }
}

class SliverObserverProxy extends SingleChildRenderObjectWidget {
  final SliverScrollObserver observer;

  const SliverObserverProxy({
    super.key,
    super.child,
    required this.observer,
  });

  @override
  RenderScrollObserverProxy createRenderObject(BuildContext context) {
    return RenderScrollObserverProxy<RenderSliver>(
      observer: observer,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderScrollObserverProxy renderObject) {
    renderObject.observer = observer;
  }
}

class BoxObserverProxy extends SingleChildRenderObjectWidget {
  final BoxScrollObserver observer;

  const BoxObserverProxy({
    super.key,
    super.child,
    required this.observer,
  });

  @override
  RenderScrollObserverProxy createRenderObject(BuildContext context) {
    if (observer.hasMultiChild) {
      return RenderScrollObserverProxy<MultiChildRenderBox>(
        observer: observer as LayoutObserver<MultiChildRenderBox>,
      );
    } else {
      return RenderScrollObserverProxy<SingleChildRenderBox>(
        observer: observer as LayoutObserver<SingleChildRenderBox>,
      );
    }
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderScrollObserverProxy renderObject) {
    renderObject.observer = observer;
  }
}

class RenderScrollObserverProxy<T extends RenderObject> extends RenderProxyBox {
  LayoutObserver<T>? _observer;

  RenderScrollObserverProxy({
    RenderBox? child,
    LayoutObserver<T>? observer,
  })  : _observer = observer,
        super(child);

  set observer(LayoutObserver<T>? newObserver) {
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

  T? _findAncestorRenderObject() {
    if (child == null || _observer == null || !_observer!.isObserving) {
      return null;
    }

    RenderObject? ancestor = parent as RenderObject?;

    while (ancestor != null) {
      if (ancestor is T) {
        return ancestor;
      } else {
        ancestor = ancestor.parent as RenderObject?;
      }
    }
    return null;
  }

  ParentData? _findDesiredParentData(RenderObject ancestor) {
    if (_observer == null ||
        !_observer!.hasMultiChild ||
        _observer!.isDesiredParentData(parentData)) {
      return parentData;
    }

    RenderObject? node = parent as RenderObject?;
    ParentData? ancestorData = node?.parentData;

    while (ancestorData != null && node != ancestor) {
      if (_observer!.isDesiredParentData(ancestorData)) {
        return ancestorData;
      } else {
        node = node?.parent as RenderObject?;
        ancestorData = node?.parentData;
      }
    }

    return null;
  }
}
