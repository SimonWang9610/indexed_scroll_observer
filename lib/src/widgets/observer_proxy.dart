import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../observer/scroll_observer.dart';

/// A widget to proxy the child layout to [ScrollObserver.sliver]
///
/// after laid out [child], [RenderObserverProxy] would invoke [ScrollObserver.onLayout]
/// to bind its closest [RenderSliver] with [observer] and tell [observer] its [Size]
///
/// if [observer] has multi child, [SliverIndexedProxyDelegate] would be responsible for
/// invoking [ScrollObserver.onFinishLayout] to tell [observer] to collect [ItemScrollExtent] for items
/// that have been laid out
///
/// if [observer] only has one child, [RenderObserverProxy] would invoke [ScrollObserver.onFinishLayout] instantly
///
/// Usage:
///
/// for [SliverList]/[SliverGrid], please use [IndexedChildBuilderDelegate]/[IndexedChildListDelegate]
/// to wrap each item in [ObserverProxy]
///
/// for [SliverAppBar], use like:
///
/// {@tool snippet}
/// ```dart
/// final IndexedScrollController _controller =
///       IndexedScrollController.multiObserver();
///
/// <...other code>
///
/// SliverAppBar.medium(
///   pinned: true,
///   floating: true,
///   automaticallyImplyLeading: false,
///   title: ObserverProxy(
///     observer: _controller.createOrObtainObserver(
///       hasMultiChild: false,
///       observerKey: appbarObserverKey,
///     ),
///     child: const Text("Pinned App bar"),
///   ),
/// )
/// <...other code>
///
/// ```
/// {@end tool}
class ObserverProxy extends SingleChildRenderObjectWidget {
  final ScrollObserver? observer;
  const ObserverProxy({
    super.key,
    super.child,
    required this.observer,
  });

  @override
  RenderObserverProxy createRenderObject(BuildContext context) =>
      RenderObserverProxy(
        observer: observer,
      );

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderObserverProxy renderObject) {
    renderObject.observer = observer;
  }
}

class RenderObserverProxy extends RenderProxyBox {
  RenderObserverProxy({
    RenderBox? child,
    ScrollObserver? observer,
  })  : _observer = observer,
        super(child);

  ScrollObserver? _observer;

  set observer(ScrollObserver? newObserver) {
    if (_observer == newObserver) return;
    _observer = newObserver;
    markNeedsPaint();
  }

  @override
  void performLayout() {
    super.performLayout();

    final sliver = _findParentSliver();

    if (sliver != null) {
      _observer?.onLayout(
        sliver,
        size: size,
        parentData: _findSliverParentData(sliver),
      );
    }
  }

  /// when painting [child], [child] must be laid out
  /// so we could invoke [ScrollObserver.doFinishLayout] safely
  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);

    _observer?.doFinishLayout();
  }

  /// find the closest [RenderSliver] so that [_observer] could bind it when invoking [ScrollObserver.onLayout]
  /// typically, there might have other [RenderObject] between [RenderSliver] and [RenderObserverProxy]
  /// consequently, [parentData] may not be correct for [_observer] to collect [child]'s index and scroll offset
  RenderSliver? _findParentSliver() {
    if (child == null || _observer == null) return null;

    AbstractNode? parentSliver = parent;

    int traceCount = 0;

    while (
        traceCount < _observer!.maxTraceCount && parentSliver is RenderObject) {
      if (parentSliver is RenderSliver) {
        break;
      } else {
        parentSliver = parentSliver.parent;
        traceCount++;
      }
    }

    assert(
      parentSliver != null,
      "Cannot find a [RenderObject] who has [SliverMultiBoxAdaptorParentData] "
      "between its ancestors and $this during ${_observer!.maxTraceCount} times tracing"
      "In future, custom max tracing depth would be supported.",
    );

    if (parentSliver == null || parentSliver is! RenderSliver) return null;
    return parentSliver;
  }

  ParentData? _findSliverParentData(RenderSliver sliver) {
    if (parentData is SliverMultiBoxAdaptorParentData ||
        !_observer!.hasMultiChild) {
      return parentData!;
    } else {
      RenderObject node = parent as RenderObject;
      ParentData? data;
      int traceCount = 0;

      while (node != sliver && traceCount < _observer!.maxTraceCount) {
        data = node.parentData!;

        if (data is SliverMultiBoxAdaptorParentData) {
          break;
        } else {
          node = node.parent! as RenderObject;
          traceCount++;
        }
      }

      assert(
        data != null,
        "Cannot find a [RenderObject] who has [SliverMultiBoxAdaptorParentData] "
        "between its ancestor $sliver and $this during ${_observer!.maxTraceCount} times tracing",
      );
      return data!;
    }
  }
}
