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
3. support almost official `RenderSliver` that has single child or multi children

<img src="https://github.com/SimonWang9610/indexed_scroll_observer/snapshots/custom_scroll_view_demo.gif">
<img src="https://github.com/SimonWang9610/indexed_scroll_observer/snapshots/grid_view_demo.gif">
<img src="https://github.com/SimonWang9610/indexed_scroll_observer/snapshots/reorderable_demo.gif">
<img src="https://github.com/SimonWang9610/indexed_scroll_observer/snapshots/separated_list_view_demo.gif">
<img src="https://github.com/SimonWang9610/indexed_scroll_observer/snapshots/list_view_demo.gif">

## Getting started

### Use `ScrollController`

1. create a `ScrollObserver`

```dart
  final ScrollController _controller = ScrollController();
  late final ScrollObserver _observer =
      ScrollObserver.multiChild(itemCount: _itemCount);
```

2. bind `ScrollObserver` with the item widget/builder that must be wrapped by `ObserverProxy`

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

3. use `jumpToIndex`/`animateToIndex`

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

There you go

### Use `PositionedScrollController` for `ListView` that only has a single `RenderSliver`

1. create `PositionedScrollController`

```dart
final PositionedScrollController _controller =
      PositionedScrollController.singleObserver();
```

2. bind `ScrollObserver` to item widget/builder

```dart
    ListView.builder(
      controller: _controller,
      itemBuilder: (context, index) => ObserverProxy(
        observer: _controller.createOrObtainObserver(
            itemCount: _itemCount,
        ),
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

3. use `jumpToIndex`/`animateToIndex`

```dart
_controller.jumpToIndex(index);

 _controller.animateToIndex(
    index,
    duration: const Duration(milliseconds: 200),
    curve: Curves.fastLinearToSlowEaseIn,
);
```

There you go

## Usage

1. The item widget/builder must be wrapped using `ObserverProxy`
2. `ScrollObserver` would observe all children for slivers, e.g., `SliverList`/`SliverGrid`,
   so all items should have the same `ScrollObserver` instead of creating a different `ScrollObserver` for each item.

### Observing a single sliver

- if you want to use `ScrollController` directly,
  you could create a standalone `ScrollObserver` by using:

  1. `ScrollObserver.singleChild` for a sliver with a single child, such as `SliverAppBar`
  2. `ScrollObserver.multiChild` for a sliver with multi children, such as `SliverList`/`SliverGrid`

- if you prefer using `PositionedScrollController` that would manage `ScrollObserver` created by you, you could create a controller by `PositionedScrollController.singleObserver`. Then, you could create a standalone `ScrollObserver` by using: `PositionedScrollController.createOrObtainObserver`:
  1. `hasMultiChild` indicates if this observer is for a sliver with multi children

### Observing multiple slivers (typically for `CustomScrollView` that has multiple slivers)

- if using `ScrollController`, you have to create multiple `ScrollObserver`s manually and bind them to different slivers. Each sliver should have an unique `ScrollObserver` that must adopt its type: single child or multi children

- if using `PositionedScrollController`, you could create `PositionedScrollController.multiObserver` to manage
  multiple `ScrollObserver`s automatically. Then, using `PositionedScrollController.createOrObtainObserver` to create a corresponding `ScrollObserver` for each sliver.

### `PositionedScrollController`

It has all methods of `ScrollController` by extends `ScrollController` and then help you to manage `ScrollObserver`.

- `PositionedScrollController.singleObserver` manage only a single `ScrollObserver` that may have single child or multi children
- `PositionedScrollController.multiObserver` manage multiple `ScrollObserver` that may have single child or multi children

- `createOrObtainObserver`
  | parameter | required | default | description |
  |:--------- |:---------|:-----------|:------------|
  | hasMultiChild | YES | true | determine if the `ScrollObserver` is for a sliver that has multi children|
  | itemCount | No | null | the sliver's item count. if null, the observer would behave as a infinite scroll view|
  |maxTraceCount| NO | null | the maximum count when tracing `ObserverProxy`'s ancestor `RenderSliver` and `ParentData`. Default to `50` internally, only setting it when you ensure you need to trace more nodes.|
  | targetToRenderIndex | NO | null| sometimes, the target index to which users want to scroll may not be same as the current render index. By using [targetToRenderIndex], users could define how to map the target index to a render index, e.g., `ListView.separated`/`ReorderableListView`. Users could set it on an instance of `ScrollObserver` not only when creating it. Setting it only when you ensure you need it. |
  | renderToTargetIndex | NO| null | same as `targetToRenderIndex` but in converting reversely. |

- `jumpToIndex` and `animateToIndex`. (should pass `duration` and `Curve` if using `animateToIndex`)
  | parameter | required | default | description |
  | :-------- | :------- | :------ | :---------- |
  | index | YES | N/A | the item's index for a sliver. No effects if `ScrollObserver.hasMultiChild` is `false`|
  | whichObserver | NO | null | the specific `ScrollObserver` that is observing a sliver. It is required if `ScrollObserver.hasMultiChild` is `true`|
  | closeToEdge | YES | `true` | try to scroll `index` at the leading edge if not over scrolling; otherwise, only ensure the `index` is visible on the screen.|

### `ScrollObserver`

- `ScrollObserver.multiChild`: create a `ScrollObserver` that observes a `RenderSliver` with multi children
- `ScrollObserver.singleChild`: create a `ScrollObserver` that observes a `RenderSliver` with a single child

- `jumpToIndex` and `animateToIndex`. (should pass `duration` and `Curve` if using `animateToIndex`)
  | parameter | required | default | description |
  | :-------- | :------- | :------ | :---------- |
  | index | YES | N/A | the item's index for a sliver. No effects if `ScrollObserver.hasMultiChild` is `false`|
  | closeToEdge | YES | `true` | try to scroll `index` at the leading edge if not over scrolling; otherwise, only ensure the `index` is visible on the screen.|
  | position | YES | N/A | the `ScrollPosition` attached to a `ScrollController`|
