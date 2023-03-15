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

1. using `jumpToIndex` and `animateToIndex` to scroll to the specific `index`
2. No breaking for your current sliver widgets, e.g., `ListView`/`GridView`, `SliverList`/`SliverGrid`/`SliverAppBar`

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

### Usage for slivers, e.g., `SliverList`, `SliverGrid` and so on.

<div style="float: left">
    <img src="https://github.com/SimonWang9610/indexed_scroll_observer/blob/main/snapshots/custom.gif?raw=true" width="320">
    <img src="https://github.com/SimonWang9610/indexed_scroll_observer/blob/main/snapshots/grid.gif?raw=true" width="320">
    <img src="https://github.com/SimonWang9610/indexed_scroll_observer/blob/main/snapshots/reorderable.gif?raw=true" width="320">
    <img src="https://github.com/SimonWang9610/indexed_scroll_observer/blob/main/snapshots/separated.gif?raw=true" width="320">

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

## FAQ

TODO

## Contributions

Feel free to contribute to this project.

If you find a bug or want a feature, but don't know how to fix/implement it, please [fill an issue](https://github.com/SimonWang9610/indexed_scroll_observer/issues).

If you fixed a bug or implemented a feature, please [send a pull request](https://github.com/SimonWang9610/indexed_scroll_observer/pulls)
