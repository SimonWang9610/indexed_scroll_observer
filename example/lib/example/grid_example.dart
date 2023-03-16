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
  int _itemCount = 100;

  final ScrollController _controller = ScrollController();
  late final grid = ScrollObserver.sliverMulti(itemCount: _itemCount);

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
            onJump: (index) {
              grid.jumpToIndex(index, position: _controller.position);
            },
          ),
          SliverJumpWidget(
            label: "animation",
            onJump: (index) {
              grid.animateToIndex(
                index,
                position: _controller.position,
                duration: const Duration(milliseconds: 200),
                curve: Curves.linear,
              );
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
                observer: grid,
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
          final scrollExtent = ScrollExtent.fromPosition(_controller.position);
          grid.debugCheckOnstageItems(scrollExtent: scrollExtent);
        },
        child: const Icon(Icons.visibility_off_rounded),
      ),
    );
  }

  void _goStart() {
    grid.showInViewport(_controller.position);
  }

  void _addItem() {
    _itemCount++;
    setState(() {});
  }

  void _deleteItem() {
    _itemCount = max(--_itemCount, 0);
  }
}
