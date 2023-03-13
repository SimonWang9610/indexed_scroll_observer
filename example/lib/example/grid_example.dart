import 'dart:math';

import 'package:flutter/material.dart';
import 'package:positioned_scroll_observer/positioned_scroll_observer.dart';

import 'sliver_jump.dart';

class PositionedGridExample extends StatefulWidget {
  const PositionedGridExample({super.key});

  @override
  State<PositionedGridExample> createState() => _PositionedGridExampleState();
}

class _PositionedGridExampleState extends State<PositionedGridExample> {
  int _itemCount = 30;

  final PositionedScrollController _controller =
      PositionedScrollController.singleObserver();

  final String observerKey = "grid";
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
        title: const Text("Grid View Example"),
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
            onJump: (index) => _controller.jumpToIndex(
              index,
            ),
          ),
          SliverJumpWidget(
            label: "animation",
            onJump: (index) {
              _controller.animateToIndex(
                index,
                duration: const Duration(milliseconds: 200),
                curve: Curves.bounceInOut,
              );
              // _controller.animateToIndex(
              //   _itemCount - index,
              //   duration: const Duration(milliseconds: 200),
              //   curve: Curves.bounceInOut,
              // );
            },
          ),
          Expanded(
            child: GridView.custom(
              controller: _controller,
              childrenDelegate: PositionedChildBuilderDelegate(
                (context, index) => ListTile(
                  key: ValueKey<int>(index),
                  leading: const CircleAvatar(
                    child: Text("G"),
                  ),
                  title: Text("Positioned Grid Example $index"),
                ),
                childCount: _itemCount,
                observer:
                    _controller.createOrObtainObserver(itemCount: _itemCount),
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
              ),
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
  }
}
