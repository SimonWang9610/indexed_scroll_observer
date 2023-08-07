import 'package:flutter/material.dart';
import 'package:positioned_scroll_observer/positioned_scroll_observer.dart';
import 'sliver_jump.dart';

class ListWheelExample extends StatefulWidget {
  const ListWheelExample({super.key});

  @override
  State<ListWheelExample> createState() => _ListWheelExampleState();
}

class _ListWheelExampleState extends State<ListWheelExample> {
  final ScrollController _controller = ScrollController();

  final _observer = ScrollObserver.boxMulti(
    axis: Axis.vertical,
    itemCount: 30,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Single Child Scroll View example"),
      ),
      body: Column(
        children: [
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
                curve: Curves.easeInSine,
              );
            },
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: ListWheelScrollView(
                controller: _controller,
                itemExtent: 100,
                children: [
                  for (int i = 0; i < 30; i++)
                    ObserverProxy(
                      observer: _observer,
                      child: DecoratedBox(
                        decoration: BoxDecoration(border: Border.all()),
                        child: Center(
                          child: Text("List Wheel $i"),
                        ),
                      ),
                    )
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _observer.getVisibleItems(
            scrollExtent: ScrollExtent.fromPosition(_controller.position),
          );
        },
        child: const Icon(Icons.visibility),
      ),
    );
  }
}
