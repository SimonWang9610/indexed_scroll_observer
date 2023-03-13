import 'package:flutter/material.dart';
import 'package:positioned_scroll_observer/positioned_scroll_observer.dart';

import 'sliver_jump.dart';

class CustomViewExample extends StatefulWidget {
  const CustomViewExample({super.key});

  @override
  State<CustomViewExample> createState() => _CustomViewExampleState();
}

class _CustomViewExampleState extends State<CustomViewExample> {
  int _itemCount = 30;

  final PositionedScrollController _controller =
      PositionedScrollController.multiObserver();

  final keepAliveObserverKey = "keepAlive";
  final gridObserverKey = "grid";
  final listObserverKey = "list";
  final appbarObserverKey = "appbar";

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Custom Scroll View Example"),
      ),
      body: Column(
        children: [
          SliverJumpWidget(
            label: keepAliveObserverKey,
            onJump: (index) => _controller.jumpToIndex(
              index,
              whichObserver: keepAliveObserverKey,
            ),
          ),
          SliverJumpWidget(
            label: gridObserverKey,
            onJump: (index) => _controller.jumpToIndex(
              index,
              whichObserver: gridObserverKey,
            ),
          ),
          SliverJumpWidget(
            label: listObserverKey,
            onJump: (index) => _controller.jumpToIndex(
              index,
              whichObserver: listObserverKey,
            ),
          ),
          SliverJumpWidget(
            label: appbarObserverKey,
            force: true,
            onJump: (index) => _controller.animateToIndex(
              index,
              whichObserver: appbarObserverKey,
              duration: const Duration(milliseconds: 120),
              curve: Curves.bounceInOut,
            ),
          ),
          Expanded(
            child: CustomScrollView(
              controller: _controller,
              reverse: false,
              slivers: [
                SliverList(
                  delegate: PositionedChildBuilderDelegate(
                    childCount: _itemCount,
                    (context, index) => IndexedKeepAliveItem(
                      label: keepAliveObserverKey,
                      index: index,
                    ),
                    addRepaintBoundaries: false,
                    addSemanticIndexes: true,
                    addAutomaticKeepAlives: true,
                    observer: _controller.createOrObtainObserver(
                      itemCount: _itemCount,
                      observerKey: keepAliveObserverKey,
                    ),
                  ),
                ),
                SliverAppBar.medium(
                  pinned: true,
                  floating: true,
                  automaticallyImplyLeading: false,
                  title: ObserverProxy(
                    observer: _controller.createOrObtainObserver(
                      hasMultiChild: false,
                      observerKey: appbarObserverKey,
                    ),
                    child: const Text("Pinned App bar"),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 30,
                  ),
                  sliver: SliverGrid(
                    delegate: PositionedChildBuilderDelegate(
                      childCount: _itemCount,
                      (context, index) => ListTile(
                        key: ValueKey<int>(index),
                        leading: const CircleAvatar(
                          child: Text("Grid"),
                        ),
                        title: Text("Grid $index"),
                      ),
                      addRepaintBoundaries: false,
                      addSemanticIndexes: true,
                      addAutomaticKeepAlives: true,
                      observer: _controller.createOrObtainObserver(
                        itemCount: _itemCount,
                        observerKey: gridObserverKey,
                      ),
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                    ),
                  ),
                ),
                SliverList(
                  delegate: PositionedChildBuilderDelegate(
                    childCount: _itemCount,
                    (context, index) => ListTile(
                      key: ValueKey<int>(index),
                      leading: CircleAvatar(
                        child: Text(listObserverKey),
                      ),
                      title: Text("$listObserverKey $index"),
                    ),
                    addRepaintBoundaries: false,
                    addSemanticIndexes: true,
                    addAutomaticKeepAlives: true,
                    observer: _controller.createOrObtainObserver(
                      itemCount: _itemCount,
                      observerKey: listObserverKey,
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _controller.debugCheckOnstageItems();
        },
        child: const Icon(Icons.visibility_off_rounded),
      ),
    );
  }
}

class IndexedKeepAliveItem extends StatefulWidget {
  final String label;
  final int index;

  const IndexedKeepAliveItem({
    super.key,
    required this.label,
    required this.index,
  });

  @override
  State<IndexedKeepAliveItem> createState() => _IndexedKeepAliveItemState();
}

class _IndexedKeepAliveItemState extends State<IndexedKeepAliveItem>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    print("disposing: ${widget.index}");
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ListTile(
      key: ValueKey<int>(widget.index),
      leading: CircleAvatar(
        child: Text(
          widget.label[0].toUpperCase(),
        ),
      ),
      title: Text("${widget.label} ${widget.index}"),
      subtitle: Text("${widget.index}" * widget.index),
    );
  }
}
