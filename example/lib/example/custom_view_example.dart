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

  final ScrollController _controller = ScrollController();

  late final keepAlive = ScrollObserver.sliverMulti(itemCount: _itemCount);
  late final grid = ScrollObserver.sliverMulti(itemCount: _itemCount);
  late final list = ScrollObserver.sliverMulti(itemCount: _itemCount);
  late final appbar = ScrollObserver.sliverSingle();

  @override
  void dispose() {
    keepAlive.clear();
    grid.clear();
    list.clear();
    appbar.clear();
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
            label: "KeepAlive Jump",
            onJump: (index) {
              keepAlive.jumpToIndex(
                index,
                position: _controller.position,
              );
            },
          ),
          SliverJumpWidget(
            label: "AppBar Animate",
            force: true,
            onJump: (index) {
              appbar.animateToIndex(
                index,
                position: _controller.position,
                duration: const Duration(milliseconds: 200),
                curve: Curves.bounceIn,
                alignment: 0.1,
              );
            },
          ),
          SliverJumpWidget(
            label: "Grid Jump",
            onJump: (index) {
              grid.jumpToIndex(
                index,
                position: _controller.position,
              );
            },
          ),
          SliverJumpWidget(
            label: "List Jump",
            onJump: (index) {
              list.jumpToIndex(
                index,
                position: _controller.position,
              );
            },
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
                      label: "KeepAlive",
                      index: index,
                    ),
                    addRepaintBoundaries: false,
                    addSemanticIndexes: true,
                    addAutomaticKeepAlives: true,
                    observer: keepAlive,
                  ),
                ),
                SliverAppBar.medium(
                  pinned: true,
                  floating: true,
                  automaticallyImplyLeading: false,
                  title: ObserverProxy(
                    observer: appbar,
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
                      (context, index) => DecoratedBox(
                        decoration: BoxDecoration(
                          color:
                              Colors.primaries[index % Colors.primaries.length],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          key: ValueKey<int>(index),
                          leading: const CircleAvatar(
                            child: Text("Grid"),
                          ),
                          title: Text("Grid $index"),
                        ),
                      ),
                      addRepaintBoundaries: false,
                      addSemanticIndexes: true,
                      addAutomaticKeepAlives: true,
                      observer: grid,
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
                      leading: const CircleAvatar(
                        child: Text("List"),
                      ),
                      title: Text("list $index"),
                    ),
                    addRepaintBoundaries: false,
                    addSemanticIndexes: true,
                    addAutomaticKeepAlives: true,
                    observer: list,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final scrollExtent = ScrollExtent.fromPosition(_controller.position);
          keepAlive.getVisibleItems(scrollExtent: scrollExtent);
          appbar.getVisibleItems(scrollExtent: scrollExtent);
          grid.getVisibleItems(
              scrollExtent: scrollExtent, strategy: VisibilityStrategy.inside);
          list.getVisibleItems(scrollExtent: scrollExtent);
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
