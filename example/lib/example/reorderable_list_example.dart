import 'package:flutter/material.dart';
import 'package:positioned_scroll_observer/positioned_scroll_observer.dart';
import 'sliver_jump.dart';

class OfficialReorderableListExample extends StatefulWidget {
  const OfficialReorderableListExample({super.key});

  @override
  State<OfficialReorderableListExample> createState() =>
      _OfficialReorderableListExampleState();
}

class _OfficialReorderableListExampleState
    extends State<OfficialReorderableListExample> {
  final ScrollController _controller = ScrollController();

  late final _observer = ScrollObserver.sliverMulti(itemCount: _items.length)
    ..targetToRenderIndex = _toRenderIndex
    ..renderToTargetIndex = _toTargetIndex;

  late final List<int> _items = List.generate(
    30,
    (index) => index,
  );

  @override
  void dispose() {
    _controller.dispose();
    _observer.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color oddItemColor = colorScheme.secondary.withOpacity(0.05);
    final Color evenItemColor = colorScheme.secondary.withOpacity(0.15);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("List View Example"),
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton(
                onPressed: _addItem,
                child: const Text("Add Item"),
              ),
              OutlinedButton(
                onPressed: _deleteItem,
                child: const Text("Delete Item"),
              ),
              OutlinedButton(
                onPressed: _goStart,
                child: const Text("Scroll to edge"),
              ),
            ],
          ),
          SliverJumpWidget(
            label: "without animation",
            onJump: (index) {
              _observer.jumpToIndex(
                index,
                position: _controller.position,
              );
            },
          ),
          SliverJumpWidget(
            label: "animation",
            onJump: (index) {
              _observer.animateToIndex(
                index,
                position: _controller.position,
                duration: const Duration(milliseconds: 200),
                curve: Curves.fastLinearToSlowEaseIn,
              );
            },
          ),
          Expanded(
            child: ReorderableListView.builder(
              scrollController: _controller,
              padding: const EdgeInsets.symmetric(horizontal: 40),
              itemCount: _items.length,
              onReorder: _onReorder,
              onReorderStart: _pauseObserving,
              onReorderEnd: _resumeObserving,
              itemBuilder: (_, index) => ObserverProxy(
                key: ValueKey<int>(index),
                observer: _observer,
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Text("R"),
                  ),
                  tileColor: _items[index].isOdd ? oddItemColor : evenItemColor,
                  title: Text("Reorderable List Example ${_items[index]}"),
                ),
              ),
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _observer.getVisibleItems(
            scrollExtent: ScrollExtent.fromPosition(_controller.position),
          );
        },
        child: const Icon(Icons.visibility_off_rounded),
      ),
    );
  }

  void _onReorder(int oldIndex, int newIndex) {
    _observer.resume();
    _observer.itemCount = _items.length;

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final int item = _items.removeAt(oldIndex);
    _items.insert(newIndex, item);

    setState(() {});
  }

  void _pauseObserving(int index) {
    _observer.pause();
  }

  void _resumeObserving(int index) {
    _observer.resume();
  }

  void _goStart() {
    _observer.showInViewport(_controller.position);
  }

  void _addItem() {
    _items.add(_items.length);
    _observer.itemCount = _items.length;

    setState(() {});
  }

  void _deleteItem() {
    _items.removeLast();
    _observer.itemCount = _items.length;

    setState(() {});
  }

  int _toRenderIndex(int index) {
    final renderIndex = _items.indexOf(index);
    return renderIndex;
  }

  int _toTargetIndex(int index) {
    return _items[index];
  }
}
