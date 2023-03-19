<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages).
-->

[![pub package](https://img.shields.io/pub/v/positioned_scroll_observer?color=blue&style=plastic)](https://pub.dev/packages/positioned_scroll_observer)
[![GitHub Repo stars](https://img.shields.io/github/stars/SimonWang9610/indexed_scroll_observer?color=black&logoColor=black&style=social)](https://github.com/SimonWang9610/indexed_scroll_observer)

## Features

1. Using `jumpToIndex` and `animateToIndex` to scroll to the specific `index`

2. Jumping/animating to the position by specifying a ratio in a scroll view. See [how to align the render object](#jumpanimate-to-a-ratio-position-in-a-viewport). That would be very useful if you want to quickly jump to the top, middle or end of a list/grid.

3. Using `PositionRetainedScrollPhysics` to retain the old offset to avoid scrolling when adding new items into the top of `ListView`. See [retain old scroll offset](#using-positionretainedscrollphysics-for-retaining-the-old-scroll-offset).

4. Check if the specific `index` is visible on the screen. See [check visibility](#checking-index-is-visible-on-the-screen).

5. Check the visible ratio of the observed `RenderObject` in a viewport. See [how to use it in a GroupList](https://github.com/SimonWang9610/indexed_scroll_observer/blob/main/example/lib/example/group_list_example.dart)

6. No breaking for your current sliver widgets, e.g., `ListView`/`GridView`, `SliverList`/`SliverGrid`/`SliverAppBar`, just wrapping your item widgets using `ObserverProxy`. Supported:

- [x] ListView
- [x] GridView
- [x] CustomScrollView
- [x] SingleChildScrollView
- [x] ListWheelScrollView
- [ ] NestedScrollView (waiting testing)

## Getting started

1. First, creating and binding the observer to all items. (See [box scroll observer](#usage-for-scroll-views-that-do-not-rely-on-rendersliver-eg-singlechildscrollview-and-listwheelscrollview) and [sliver scroll observer](#usage-for-slivers-eg-sliverlist-slivergrid-and-so-on))

2. then, using the observer like:

   ```dart
   _observer.jumpToIndex(
       index,
       position: _controller.position,
   );

   _observer.animateToIndex(
       index,
       position: _controller.position,
       duration: const Duration(milliseconds: 200),
       curve: Curves.fastLinearToSlowEaseIn,
   );
   ```

### Usage for scroll views that do not rely on `RenderSliver`, e.g., `SingleChildScrollView` and `ListWheelScrollView`

<div style="float: left">
    <img src="https://github.com/SimonWang9610/indexed_scroll_observer/blob/main/snapshots/single_scroll_view.gif?raw=true" width="320">
    <img src="https://github.com/SimonWang9610/indexed_scroll_observer/blob/main/snapshots/list_wheel.gif?raw=true" width="320">
</div>

1. create a `BoxScrollObserver` for observing the box with multi children.

   ```dart
     final ScrollController _controller = ScrollController();
     late final _observer = ScrollObserver.boxMulti(
       axis: _axis,
       itemCount: 30,
     );
   ```

2. bind the observer to the box's children. (Using `ObserverProxy` to wrap each item).

   ```dart
   SingleChildScrollView(
     controller: _controller,
     scrollDirection: _axis,
     child: Column(
       children: [
         for (int i = 0; i < 30; i++)
           ObserverProxy(
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
     );
   ```

### Usage for slivers widgets.

<div style="float: left">
    <img src="https://github.com/SimonWang9610/indexed_scroll_observer/blob/main/snapshots/custom.gif?raw=true" width="320">
    <img src="https://github.com/SimonWang9610/indexed_scroll_observer/blob/main/snapshots/grid.gif?raw=true" width="320">
    <img src="https://github.com/SimonWang9610/indexed_scroll_observer/blob/main/snapshots/reorderable.gif?raw=true" width="320">
    <img src="https://github.com/SimonWang9610/indexed_scroll_observer/blob/main/snapshots/separated.gif?raw=true" width="320">
    <img src="https://github.com/SimonWang9610/indexed_scroll_observer/blob/main/snapshots/group_list_demo.gif?raw=true" width="320">
</div>

1. create a `SliverScrollObserver` for observing the sliver with multi children.

   ```dart
     final ScrollController _controller = ScrollController();
     late final _observer = ScrollObserver.sliverMulti(itemCount: 30);
   ```

2. bind the observer to each item for the sliver.

   ```dart
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
   ```

> For `ListView.custom` and `GridView.custom`, you could also use `PositionedChildListDelegate` and `PositionedChildBuilderDelegate` for wrapping items in `ObserverProxy` conveniently

## Usage

### For observing slivers:

1. observing a sliver with single child, using `ScrollObserver.sliverSingle` to create.
2. observing a sliver with multi children, using `ScrollObserver.sliverMulti` to create.

### For observing other scroll views that have no sliver descendants.

1. observing a box with single child, using `ScrollObserver.boxSingle` to create. (rare cases and need more testing)
2. observing a box with multi children, using `ScrollObserver.boxMulti` to create.

### Checking `index` is visible on the screen

By invoking `YourObserver.isRevealed` to check if the `index`'s `RenderObject` is visible on the screen.

- `index`: your specific index
- `scrollExtent`: You could get the `ScrollExtent` by using `ScrollExtent.fromPosition(ScrollController.position)`
- `strategy` indicates how to determine if the `index` is visible.
  1. `PredicatorStrategy.tolerance` would tolerate the visual ratio is not less `50%`
  2. `PredicatorStrategy.inside` would ensure the entire `index` is visible

More details, see [API reference](https://pub.dev/documentation/positioned_scroll_observer/latest/positioned_scroll_observer/SliverScrollObserver/isRevealed.html).

### Using `PositionRetainedScrollPhysics` for retaining the old scroll offset

<div> 
    <img src="https://github.com/SimonWang9610/indexed_scroll_observer/blob/main/snapshots/retain.gif?raw=true" width="320">
</div>

```dart
ListView.builder(
  controller: _controller,
  reverse: true,
  physics: const PositionRetainedScrollPhysics(),
  itemBuilder: (context, index) => _items[index],
  itemCount: _itemCount,
);
```

### Jump/animate to a ratio position in a viewport

<div> 
    <img src="https://github.com/SimonWang9610/indexed_scroll_observer/blob/main/snapshots/ratio_jump.gif?raw=true" width="320">
</div>

```dart
_observer.showInViewport(
  _controller.position,
  alignment: 0.5,
);
```

By setting different `alignment`, you could jump/animate to the position according to the ratio: `alignment`.

1. for `alignment = 0.0`, it would align the render object' leading to the leading of the viewport's main axis extent.
2. for `alignment = 0.5`, it would align the render object's center to the center of the viewport;s main axis extent.
3. for `alignment = 1.0`, it would align the render object's trailing to the trailing of the viewport's main axis extent.

> you could also specify `alignment` as the number between `[0, 1]`

### Pay attention

- **The item widget/builder must be wrapped using `ObserverProxy`**
- All observers would `normalizeIndex` to ensure the `index` is in a valid range determined by `itemCount` of observers, so developers should also update observers' `itemCount` when the scroll views' item count changes.
- Items that have the same `RenderObject` observed by an observer should share the same observer instance, instead of creating different observers for each item.
- When using `ScrollObserver.boxMulti`, `axis` is required so that the observer could estimate the scroll offset along the correct main axis.

## Examples:

- [ListView example](https://github.com/SimonWang9610/indexed_scroll_observer/blob/main/example/lib/example/official_list_example.dart)
- [GridView example](https://github.com/SimonWang9610/indexed_scroll_observer/blob/main/example/lib/example/grid_example.dart)
- [CustomScrollView example](https://github.com/SimonWang9610/indexed_scroll_observer/blob/main/example/lib/example/custom_view_example.dart)
- [ReorderableListView example](https://github.com/SimonWang9610/indexed_scroll_observer/blob/main/example/lib/example/reorderable_list_example.dart)
- [ListWheelScrollView example](https://github.com/SimonWang9610/indexed_scroll_observer/blob/main/example/lib/example/list_wheel_example.dart)
- [SingleChildScrollView example](https://github.com/SimonWang9610/indexed_scroll_observer/blob/main/example/lib/example/single_child_scroll_view_example.dart)
- [GroupList example](https://github.com/SimonWang9610/indexed_scroll_observer/blob/main/example/lib/example/group_list_example.dart)

## FAQ

TODO

## Contributions

Feel free to contribute to this project.

If you find a bug or want a feature, but don't know how to fix/implement it, please [fill an issue](https://github.com/SimonWang9610/indexed_scroll_observer/issues).

If you fixed a bug or implemented a feature, please [send a pull request](https://github.com/SimonWang9610/indexed_scroll_observer/pulls)
