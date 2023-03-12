import 'dart:math';

import 'package:flutter/widgets.dart';

import '../observer/scroll_observer.dart';
import 'indexed_child_delegate.dart';

class IndexedListView extends ListView {
  @override
  final SliverIndexedProxyDelegate childrenDelegate;
  final bool addProxy;
  final ScrollObserver? observer;

  IndexedListView({
    super.key,
    super.scrollDirection,
    super.reverse,
    super.controller,
    super.primary,
    super.physics,
    super.shrinkWrap,
    super.padding,
    super.itemExtent,
    super.prototypeItem,
    super.addAutomaticKeepAlives,
    super.addRepaintBoundaries,
    super.addSemanticIndexes,
    super.cacheExtent,
    super.children,
    super.semanticChildCount,
    super.dragStartBehavior,
    super.keyboardDismissBehavior,
    super.restorationId,
    super.clipBehavior,
    this.addProxy = true,
    this.observer,
  })  : assert(
          itemExtent == null || prototypeItem == null,
          'You can only pass itemExtent or prototypeItem, not both.',
        ),
        assert(
          observer == null || observer.itemCount == children.length,
          "[ScrollObserver] should have the same item count as children.length",
        ),
        childrenDelegate = IndexedChildListDelegate(
          children,
          addProxy: addProxy,
          observer: observer,
          addAutomaticKeepAlives: addAutomaticKeepAlives,
          addRepaintBoundaries: addAutomaticKeepAlives,
          addSemanticIndexes: addSemanticIndexes,
        );

  IndexedListView.builder({
    super.key,
    super.scrollDirection,
    super.reverse,
    super.controller,
    super.primary,
    super.physics,
    super.shrinkWrap,
    super.padding,
    super.itemExtent,
    super.prototypeItem,
    required NullableIndexedWidgetBuilder itemBuilder,
    ChildIndexGetter? findChildIndexCallback,
    super.addAutomaticKeepAlives,
    super.addRepaintBoundaries,
    super.addSemanticIndexes,
    super.cacheExtent,
    super.semanticChildCount,
    super.dragStartBehavior,
    super.keyboardDismissBehavior,
    super.restorationId,
    super.clipBehavior,
    this.addProxy = true,
    this.observer,
    int? itemCount,
  })  : assert(itemCount == null || itemCount >= 0),
        assert(semanticChildCount == null || semanticChildCount <= itemCount!),
        assert(
          itemExtent == null || prototypeItem == null,
          'You can only pass itemExtent or prototypeItem, not both.',
        ),
        assert(observer == null || observer.itemCount == itemCount),
        childrenDelegate = IndexedChildBuilderDelegate(
          itemBuilder,
          childCount: itemCount,
          addAutomaticKeepAlives: addAutomaticKeepAlives,
          addRepaintBoundaries: addAutomaticKeepAlives,
          addSemanticIndexes: addSemanticIndexes,
          findChildIndexCallback: findChildIndexCallback,
          addProxy: addProxy,
          observer: observer,
        );

  IndexedListView.separated({
    super.key,
    super.scrollDirection,
    super.reverse,
    super.controller,
    super.primary,
    super.physics,
    super.shrinkWrap,
    super.padding,
    required NullableIndexedWidgetBuilder itemBuilder,
    ChildIndexGetter? findChildIndexCallback,
    required IndexedWidgetBuilder separatorBuilder,
    super.addAutomaticKeepAlives,
    super.addRepaintBoundaries,
    super.addSemanticIndexes,
    super.cacheExtent,
    super.dragStartBehavior,
    super.keyboardDismissBehavior,
    super.restorationId,
    super.clipBehavior,
    this.addProxy = true,
    this.observer,
    required int itemCount,
  }) : childrenDelegate = IndexedChildBuilderDelegate(
          (context, index) {
            final itemIndex = index ~/ 2;
            if (index.isEven) {
              return itemBuilder(context, itemIndex);
            } else {
              return separatorBuilder(context, itemIndex);
            }
          },
          childCount: _computeActualChildCount(itemCount),
          addProxy: addProxy,
          observer: observer?..itemCount = _computeActualChildCount(itemCount),
          addAutomaticKeepAlives: addAutomaticKeepAlives,
          addRepaintBoundaries: addAutomaticKeepAlives,
          addSemanticIndexes: addSemanticIndexes,
          findChildIndexCallback: findChildIndexCallback,
          semanticIndexCallback: (Widget _, int index) {
            return index.isEven ? index ~/ 2 : null;
          },
        );

  static int _computeActualChildCount(int itemCount) {
    return max(0, itemCount * 2 - 1);
  }
}
