import 'dart:math';

import 'package:flutter/material.dart';
import 'package:positioned_scroll_observer/positioned_scroll_observer.dart';
import 'sliver_jump.dart';

class OfficialListExample extends StatefulWidget {
  const OfficialListExample({super.key});

  @override
  State<OfficialListExample> createState() => _OfficialListExampleState();
}

class _OfficialListExampleState extends State<OfficialListExample> {
  int _itemCount = 100;

  // final ScrollController _controller = ScrollController();
  final RetainableScrollController _controller = RetainableScrollController();

  late final SliverScrollObserver _observer =
      MultiChildSliverObserver(itemCount: _itemCount);

  late final List<Widget> _items = List.generate(_itemCount, (index) => index)
      .map(
        (index) => ObserverProxy(
          observer: _observer,
          child: ListTile(
            leading: const CircleAvatar(
              child: Text("L"),
            ),
            title: Text("Positioned List Example $index"),
          ),
        ),
      )
      .toList();

  @override
  void dispose() {
    _controller.dispose();
    _observer.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ListView.builder(
      controller: _controller,
      itemBuilder: (context, index) => ObserverProxy(
        observer: _observer,
        child: ListTile(
          key: ValueKey<int>(index),
          leading: const CircleAvatar(
            child: Text("L"),
          ),
          title: Text("Positioned List Example $index"),
        ),
      ),
      itemCount: _itemCount,
    );
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
                duration: const Duration(milliseconds: 1000),
                curve: Curves.fastLinearToSlowEaseIn,
              );
            },
          ),
          Expanded(
            child: ListView.builder(
              controller: _controller,
              reverse: true,
              itemBuilder: (context, index) => _items[index],
              itemCount: _itemCount,
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _observer.debugCheckOnstageItems(
            scrollExtent: ScrollExtent.fromPosition(_controller.position),
          );
        },
        child: const Icon(Icons.visibility_off_rounded),
      ),
    );
  }

  void _goStart() {
    _observer.showInViewport(_controller.position);
  }

  void _addItem() {
    _itemCount++;
    _observer.itemCount = _itemCount;
    _items.insert(
      0,
      ObserverProxy(
        observer: _observer,
        child: ListTile(
          leading: const CircleAvatar(
            child: Text("L"),
          ),
          title: Text("Positioned List Example $_itemCount"),
        ),
      ),
    );
    _checkScrollOffset();
    // _observer.standBy(_controller.position);
    _controller.retainOffset();

    setState(() {});

    final double old = _controller.position.pixels;
    final double oldMax = _controller.position.maxScrollExtent;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScrollOffset();

      // if (old > 0.0) {
      //   final diff = _controller.position.maxScrollExtent - oldMax;
      //   _controller.jumpTo(old + diff);
      //   final current = _controller.position.pixels;
      //   final max = _controller.position.maxScrollExtent;
      //   print("[post frame]: $diff, current: $current, max: $max");
      // }
    });
  }

  void _deleteItem() {
    _itemCount = max(--_itemCount, 0);
    _observer.itemCount = _itemCount;

    _items.removeLast();

    final double old = _controller.position.pixels;
    final double oldMax = _controller.position.maxScrollExtent;

    _checkScrollOffset();
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScrollOffset();
    });
  }

  void _checkScrollOffset() {
    final max = _controller.position.maxScrollExtent;
    final current = _controller.position.pixels;
    print("current: $current, max: $max");
  }
}

class OfficialSeparatedListExample extends StatefulWidget {
  const OfficialSeparatedListExample({super.key});

  @override
  State<OfficialSeparatedListExample> createState() =>
      _OfficialSeparatedListExampleState();
}

class _OfficialSeparatedListExampleState
    extends State<OfficialSeparatedListExample> {
  int _itemCount = 1000;

  final ScrollController _controller = ScrollController();

  late final _observer = ScrollObserver.sliverMulti(
    itemCount: _computeActualChildCount(_itemCount),
  )
    ..targetToRenderIndex = _toRenderIndex
    ..renderToTargetIndex = _toTargetIndex;

  @override
  void dispose() {
    _controller.dispose();
    _observer.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Separated List View Example"),
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
            child: ListView.separated(
              controller: _controller,
              itemBuilder: (_, index) => ObserverProxy(
                observer: _observer,
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Text("L"),
                  ),
                  title: Text("Positioned List Example $index"),
                ),
              ),
              separatorBuilder: (_, index) {
                return ObserverProxy(
                  observer: _observer,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Center(
                      child: Text("--Separator $index--"),
                    ),
                  ),
                );
              },
              itemCount: _itemCount,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _observer.debugCheckOnstageItems(
            scrollExtent: ScrollExtent.fromPosition(_controller.position),
          );
        },
        child: const Icon(Icons.visibility_off_rounded),
      ),
    );
  }

  void _goStart() {
    _observer.showInViewport(_controller.position);
  }

  void _addItem() {
    _itemCount++;
    _observer.itemCount = _computeActualChildCount(_itemCount);
    setState(() {});
  }

  void _deleteItem() {
    _itemCount = max(--_itemCount, 0);
    _observer.itemCount = _computeActualChildCount(_itemCount);

    setState(() {});
  }

  int _toRenderIndex(int index) => index * 2;

  int _toTargetIndex(int renderIndex) => renderIndex ~/ 2;

  int _computeActualChildCount(int count) {
    return max(0, count * 2 - 1);
  }
}
