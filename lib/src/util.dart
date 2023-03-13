import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart';

class ObserverUtil {
  /// find the closest [RenderViewportBase] for the given [sliver]
  /// and the distance between them is restricted to the [maxTraceCount]
  /// if you guarantee a [RenderViewportBase] will be found definitely
  /// you could increase [maxTraceCount] to allow more times tracing up
  static RenderViewportBase findClosestViewport(
    RenderSliver sliver, {
    int maxTraceCount = 5,
  }) {
    AbstractNode? viewport = sliver.parent;

    int traceCount = 0;

    while (traceCount < maxTraceCount) {
      if (viewport is RenderViewportBase) {
        break;
      } else {
        viewport = viewport!.parent;
        traceCount++;
      }
    }

    assert(
      viewport != null,
      "Not found a [RenderViewportBase] ancestor for $sliver in the tracing depth: $maxTraceCount. "
      "If you ensure the sliver has a [RenderViewportBase] ancestor, you could increase [maxTraceCount] to allow trace more ancestor nodes",
    );

    return viewport! as RenderViewportBase;
  }

  /// if [sliver] is a child of a [RenderViewportBase], return itself directly
  /// otherwise, find the [RenderSliver] that is closest to the [sliver]'s closest [RenderViewportBase]
  /// tracing up would be no more than [maxTraceCount]
  /// the closest [RenderSliver] typically has a [SliverPhysicalParentData] that setup by [RenderViewportBase] directly
  static RenderSliver findClosestSliver(
    RenderSliver sliver, {
    int maxTraceCount = 5,
  }) {
    if (sliver.parent is RenderViewportBase) {
      return sliver;
    } else {
      int traceCount = 0;
      AbstractNode? closest = sliver.parent;
      while (traceCount < maxTraceCount && closest != null) {
        if (closest.parent is RenderViewportBase) {
          break;
        } else {
          closest = closest.parent;
          traceCount++;
        }
      }
      assert(
        closest != null,
        "$sliver must have a [RenderViewportBase] ancestor but not found during [$maxTraceCount] tracing up"
        "If you guarantee there is a [RenderViewportBase] ancestor for $sliver, you could use a greater maxTraceCount",
      );

      return closest! as RenderSliver;
    }
  }
}
