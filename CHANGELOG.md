## 2.2.0

1. support check the visible ratio of the observed RenderObject in a viewport
2. support aligning the observed RenderObject when showing it in the viewport.
3. add the GroupList example to show the usage of visibleRatioInViewport.

- see details: [pull request](https://github.com/SimonWang9610/indexed_scroll_observer/pull/8)

## 2.1.1

- deprecate `RetainableScrollController`, and introduce `PositionRetainedScrollPhysics` to achieve same goals.
- See details: [pull request](https://github.com/SimonWang9610/indexed_scroll_observer/pull/7)

## 2.1.0

- [new feature]: support `RetainableScrollController` to keep scroll offset when inserting a new item into the top of the `ListView`.

- See details: [pull request](https://github.com/SimonWang9610/indexed_scroll_observer/pull/6)

## 2.0.1

- fix: [Issue #4](https://github.com/SimonWang9610/indexed_scroll_observer/issues/4)

## 2.0.0 (break change)

See [PR details](https://github.com/SimonWang9610/indexed_scroll_observer/issues/2) about the below changes.

- support `SingleChildScrollView` and `ListWheelScrollView`
- remove `PositionedScrollController`
- break changes of the design for supporting `SliverScrollObserver` and `BoxScrollObserver`.

## 1.0.2

- fix: not animating if item has been visible. [Issue #1](https://github.com/SimonWang9610/indexed_scroll_observer/issues/1)

## 1.0.1 (2023-03-13)

- improve documentation
- fix: determine if the given index is visible when [SliverAppBar] is overlapped with other slivers.

## 1.0.0 (2023-03-13)

- init release
