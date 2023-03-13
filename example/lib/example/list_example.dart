import 'dart:math';

import 'package:flutter/material.dart';
import 'package:positioned_scroll_observer/positioned_scroll_observer.dart';
import 'sliver_jump.dart';

class PositionedListExample extends StatefulWidget {
  const PositionedListExample({super.key});

  @override
  State<PositionedListExample> createState() => _PositionedListExampleState();
}

class _PositionedListExampleState extends State<PositionedListExample> {
  int _itemCount = 30;

  final PositionedScrollController _controller =
      PositionedScrollController.singleObserver();

  @override
  Widget build(BuildContext context) {
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
              _controller.jumpToIndex(index);
            },
          ),
          SliverJumpWidget(
            label: "animation",
            onJump: (index) {
              _controller.animateToIndex(
                index,
                duration: const Duration(milliseconds: 200),
                curve: Curves.fastLinearToSlowEaseIn,
              );
            },
          ),
          Expanded(
            // child: ListView.custom(
            //   controller: _controller,
            //   childrenDelegate: IndexedChildBuilderDelegate(
            //     (context, index) => ListTile(
            //       key: ValueKey<int>(index),
            //       leading: const CircleAvatar(
            //         child: Text("L"),
            //       ),
            //       title: Text("Positioned List Example $index"),
            //     ),
            //     childCount: _itemCount,
            //     observer:
            //         _controller.createOrObtainObserver(itemCount: _itemCount),
            //   ),
            // ),
            child: PositionedListView.builder(
              controller: _controller,
              itemBuilder: (context, index) => ListTile(
                key: ValueKey<int>(index),
                leading: const CircleAvatar(
                  child: Text("L"),
                ),
                title: Text("Positioned List Example $index"),
              ),
              itemCount: _itemCount,
              observer:
                  _controller.createOrObtainObserver(itemCount: _itemCount),
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

  void _goStart() {
    _controller.showInViewport();
  }

  void _addItem() {
    _itemCount++;
    setState(() {});
  }

  void _deleteItem() {
    _itemCount = max(--_itemCount, 0);
    setState(() {});
  }
}

class SeparatedPositionedListExample extends StatefulWidget {
  const SeparatedPositionedListExample({super.key});

  @override
  State<SeparatedPositionedListExample> createState() =>
      _SeparatedPositionedListExampleState();
}

class _SeparatedPositionedListExampleState
    extends State<SeparatedPositionedListExample> {
  int _itemCount = 30;

  final PositionedScrollController _controller =
      PositionedScrollController.singleObserver();

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
              _controller.jumpToIndex(_toRenderIndex(index));
            },
          ),
          SliverJumpWidget(
            label: "animation",
            onJump: (index) {
              _controller.animateToIndex(
                _toRenderIndex(index),
                duration: const Duration(milliseconds: 200),
                curve: Curves.fastLinearToSlowEaseIn,
              );
            },
          ),
          // Expanded(
          //   child: ListView.custom(
          //     controller: _controller,
          //     childrenDelegate: IndexedChildBuilderDelegate(
          //       (context, index) {
          //         if (index.isEven) {
          //           return ListTile(
          //             key: ValueKey<int>(index),
          //             leading: const CircleAvatar(
          //               child: Text("L"),
          //             ),
          //             title: Text("Positioned List Example $index"),
          //           );
          //         } else {
          //           return const Padding(
          //             padding: EdgeInsets.symmetric(vertical: 5),
          //             child: Center(
          //               child: Text("----"),
          //             ),
          //           );
          //         }
          //       },
          //       childCount: _computeActualChildCount(_itemCount),
          //       observer: _controller.createOrObtainObserver(
          //         itemCount: _computeActualChildCount(_itemCount),
          //       ),
          //     ),
          //   ),
          // ),
          Expanded(
            child: PositionedListView.separated(
              controller: _controller,
              itemBuilder: (_, index) => ListTile(
                // key: ValueKey<int>(index),
                leading: const CircleAvatar(
                  child: Text("L"),
                ),
                title: Text("Positioned List Example $index"),
              ),
              separatorBuilder: (_, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Center(
                    child: Text("--Separator $index--"),
                  ),
                );
              },
              itemCount: _itemCount,
              observer: _controller.createOrObtainObserver(
                itemCount: _itemCount,
              ),
            ),
          ),
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

  int _computeActualChildCount(int itemCount) {
    return max(0, itemCount * 2 - 1);
  }

  void _goStart() {
    _controller.showInViewport();
  }

  void _addItem() {
    _itemCount++;
    setState(() {});
  }

  void _deleteItem() {
    _itemCount = max(--_itemCount, 0);
    setState(() {});
  }

  int _toRenderIndex(int index) => index * 2;
}

class OfficialListExample extends StatefulWidget {
  const OfficialListExample({super.key});

  @override
  State<OfficialListExample> createState() => _OfficialListExampleState();
}

class _OfficialListExampleState extends State<OfficialListExample> {
  int _itemCount = 30;

  final PositionedScrollController _controller =
      PositionedScrollController.singleObserver();

  @override
  void initState() {
    super.initState();
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   _controller.jumpToIndex(5);
    // });
  }

  @override
  Widget build(BuildContext context) {
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
              _controller.jumpToIndex(index);
            },
          ),
          SliverJumpWidget(
            label: "animation",
            onJump: (index) {
              _controller.animateToIndex(
                index,
                duration: const Duration(milliseconds: 200),
                curve: Curves.fastLinearToSlowEaseIn,
              );
            },
          ),
          Expanded(
            child: ListView.builder(
              controller: _controller,
              itemBuilder: (context, index) => ObserverProxy(
                observer:
                    _controller.createOrObtainObserver(itemCount: _itemCount),
                child: ListTile(
                  key: ValueKey<int>(index),
                  leading: const CircleAvatar(
                    child: Text("L"),
                  ),
                  title: Text("Positioned List Example $index"),
                ),
              ),
              itemCount: _itemCount,
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

  void _goStart() {
    _controller.showInViewport();
  }

  void _addItem() {
    _itemCount++;
    setState(() {});
  }

  void _deleteItem() {
    _itemCount = max(--_itemCount, 0);
    setState(() {});
  }
}
