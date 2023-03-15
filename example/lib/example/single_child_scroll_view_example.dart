import 'package:flutter/material.dart';
import 'package:positioned_scroll_observer/positioned_scroll_observer.dart';
import 'sliver_jump.dart';

class SingleChildScrollExample extends StatefulWidget {
  const SingleChildScrollExample({super.key});

  @override
  State<SingleChildScrollExample> createState() =>
      _SingleChildScrollExampleState();
}

class _SingleChildScrollExampleState extends State<SingleChildScrollExample> {
  final ScrollController _controller = ScrollController();

  late final MultiChildBoxObserver _observer = MultiChildBoxObserver(
    axis: _axis,
    itemCount: 30,
  );

  Axis _axis = Axis.horizontal;

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
            child: SingleChildScrollView(
              controller: _controller,
              scrollDirection: _axis,
              child: Row(
                children: [
                  for (int i = 0; i < 30; i++)
                    BoxObserverProxy(
                      observer: _observer,
                      child: DecoratedBox(
                        decoration: BoxDecoration(border: Border.all()),
                        child: SizedBox(
                          height: 100,
                          width: 100,
                          child: Center(
                            child: Text("Column item $i"),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
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
        child: const Icon(Icons.visibility),
      ),
    );
  }
}
