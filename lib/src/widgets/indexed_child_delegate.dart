import 'package:flutter/widgets.dart';

import '../observer/scroll_observer.dart';
import 'observer_proxy.dart';

class IndexedChildListDelegate extends SliverIndexedProxyDelegate {
  final List<Widget> children;
  final Map<Key?, int>? _keyToIndex;

  IndexedChildListDelegate(
    this.children, {
    super.addAutomaticKeepAlives,
    super.addProxy,
    super.addRepaintBoundaries,
    super.addSemanticIndexes,
    super.semanticIndexCallback,
    super.semanticIndexOffset,
    super.observer,
  }) : _keyToIndex = {null: 0};

  @override
  Widget? buildItem(BuildContext context, int index) => children[index];

  @override
  int get estimatedChildCount => children.length;
  @override
  bool shouldRebuild(covariant IndexedChildListDelegate oldDelegate) =>
      oldDelegate.children != children;

  bool get _isConstantInstance => _keyToIndex == null;

  @override
  int? _findChildIndex(Key key) {
    if (_isConstantInstance) {
      return null;
    }
    // Lazily fill the [_keyToIndex].
    if (!_keyToIndex!.containsKey(key)) {
      int index = _keyToIndex![null]!;
      while (index < children.length) {
        final Widget child = children[index];
        if (child.key != null) {
          _keyToIndex![child.key] = index;
        }
        if (child.key == key) {
          // Record current index for next function call.
          _keyToIndex![null] = index + 1;
          return index;
        }
        index += 1;
      }
      _keyToIndex![null] = index;
    } else {
      return _keyToIndex![key];
    }
    return null;
  }
}

class IndexedChildBuilderDelegate extends SliverIndexedProxyDelegate {
  final ChildIndexGetter? findChildIndexCallback;
  final NullableIndexedWidgetBuilder builder;
  final int? childCount;

  IndexedChildBuilderDelegate(
    this.builder, {
    required this.childCount,
    this.findChildIndexCallback,
    super.addAutomaticKeepAlives,
    super.addProxy,
    super.addRepaintBoundaries,
    super.addSemanticIndexes,
    super.semanticIndexCallback,
    super.semanticIndexOffset,
    super.observer,
  });

  @override
  int? _findChildIndex(Key key) {
    if (findChildIndexCallback != null) {
      return findChildIndexCallback!(key);
    }
    return null;
  }

  @override
  Widget? buildItem(BuildContext context, int index) => builder(context, index);

  @override
  int? get estimatedChildCount => childCount;
  @override
  bool shouldRebuild(covariant IndexedChildBuilderDelegate oldDelegate) =>
      oldDelegate.builder != builder || childCount != oldDelegate.childCount;
}

/// only [addProxy] is true and [observer] is null, would use [ObserverProxy] to wrap the item widget
/// we should enable [ScrollObserver] to be notified when [SliverChildDelegate.didFinishLayout]
/// so we create [SliverIndexedProxyDelegate] to override [SliverChildDelegate.didFinishLayout]
/// in future, we may no need to use this extended delegate
/// if we could pass [didFinishLayout] callback for [SliverChildBuilderDelegate]/[SliverChildListDelegate]
/// to have better compatibility
///
/// For convenience, using [IndexedListView]/[IndexedGridView] directly
/// See also:
///   * [IndexedListView], extends the official [ListView] to use [SliverIndexedProxyDelegate]
///   * [IndexedGridView], extends the official [GridView] to use [SliverIndexedProxyDelegate]
abstract class SliverIndexedProxyDelegate extends SliverChildDelegate {
  final bool addAutomaticKeepAlives;
  final bool addRepaintBoundaries;
  final bool addSemanticIndexes;
  final bool addProxy;
  final int semanticIndexOffset;
  final SemanticIndexCallback semanticIndexCallback;
  final ScrollObserver? observer;

  SliverIndexedProxyDelegate({
    this.observer,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
    this.addProxy = true,
    this.semanticIndexOffset = 0,
    this.semanticIndexCallback = _kDefaultSemanticIndexCallback,
  }) : super();

  Widget? buildItem(BuildContext context, int index);

  int? _findChildIndex(Key key);

  @override
  int? findIndexByKey(Key key) {
    final Key childKey;
    if (key is ProxyKey) {
      final ProxyKey saltedValueKey = key;
      childKey = saltedValueKey.value;
    } else {
      childKey = key;
    }
    return _findChildIndex(childKey);
  }

  ///! SliverList must use this proxy delegate for capturing didFinishLayout event
  // @override
  // void didFinishLayout(int firstIndex, int lastIndex) {
  //   // observer?.onFinishLayout(firstIndex, lastIndex);
  // }

  @override
  Widget? build(BuildContext context, int index) {
    assert(observer != null && observer!.hasMultiChild,
        "For list/grid that is a kind of slivers, should use [MultiChildScrollObserver], but got ${observer.runtimeType}");

    if (index < 0 ||
        (estimatedChildCount == null || index >= estimatedChildCount!)) {
      return null;
    }

    Widget? child;
    try {
      child = buildItem(context, index);
    } catch (exception, stackTrace) {
      child = _createErrorWidget(exception, stackTrace);
    }

    if (child == null) {
      return null;
    }

    final Key? key = child.key != null ? ProxyKey(child.key!) : null;
    if (addRepaintBoundaries) {
      child = RepaintBoundary(child: child);
    }
    if (addSemanticIndexes) {
      final int? semanticIndex = semanticIndexCallback(child, index);
      if (semanticIndex != null) {
        child = IndexedSemantics(
            index: semanticIndex + semanticIndexOffset, child: child);
      }
    }

    if (addProxy && observer != null) {
      child = ObserverProxy(
        observer: observer,
        child: child,
      );
    }

    // todo: [_SelectionKeepAlive] is necessary?
    if (addAutomaticKeepAlives) {
      child = AutomaticKeepAlive(child: child);
    }
    return KeyedSubtree(key: key, child: child);
  }

  @override
  bool shouldRebuild(covariant SliverIndexedProxyDelegate oldDelegate) =>
      observer != oldDelegate.observer;
}

class ProxyKey extends ValueKey {
  const ProxyKey(super.key) : assert(key != null);
}

int _kDefaultSemanticIndexCallback(Widget _, int localIndex) => localIndex;

// Return a Widget for the given Exception
Widget _createErrorWidget(Object exception, StackTrace stackTrace) {
  final FlutterErrorDetails details = FlutterErrorDetails(
    exception: exception,
    stack: stackTrace,
    library: 'widgets library',
    context: ErrorDescription('building'),
  );
  FlutterError.reportError(details);
  return ErrorWidget.builder(details);
}
