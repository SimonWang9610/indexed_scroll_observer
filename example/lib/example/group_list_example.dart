import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:positioned_scroll_observer/positioned_scroll_observer.dart';

class GroupObservers {
  final SliverScrollObserver titleObserver;
  final SliverScrollObserver itemObserver;

  GroupObservers({required this.itemObserver, required this.titleObserver});

  void clear() {
    titleObserver.clear();
    itemObserver.clear();
  }
}

class GroupList extends StatefulWidget {
  const GroupList({super.key});

  @override
  State<GroupList> createState() => _GroupListState();
}

class _GroupListState extends State<GroupList> {
  final ScrollController _controller = ScrollController();

  final List<String> _groups = ["Group A", "Group B", "Group C", "Group D"];
  final List<int> _groupCounts = [30, 5, 5, 40];

  late final ValueNotifier<int> _selectedIndex = ValueNotifier(0);

  final Map<int, GroupObservers> _observers = {};
  @override
  void initState() {
    super.initState();

    for (int i = 0; i < _groups.length; i++) {
      _observers[i] = GroupObservers(
        titleObserver: ScrollObserver.sliverSingle(),
        itemObserver: ScrollObserver.sliverMulti(itemCount: _groupCounts[i]),
      );
    }

    _controller.addListener(_listenScroll);
    _selectedIndex.addListener(_listenIndexChange);
  }

  @override
  void dispose() {
    for (final groupObserver in _observers.values) {
      groupObserver.clear();
    }
    _controller.removeListener(_listenScroll);
    _selectedIndex.removeListener(_listenIndexChange);
    _controller.dispose();
    _selectedIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("GroupList Example"),
      ),
      body: Column(
        children: [
          GroupListTabBar(
            tabCount: _groups.length,
            tabBuilder: (_, index) => _buildTab(index),
            selected: _selectedIndex,
          ),
          Expanded(
            child: CustomScrollView(
              controller: _controller,
              slivers: [
                for (int i = 0; i < _groups.length; i++) ..._buildSubList(i),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTab(int index) {
    return Text(
      _groups[index],
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: _selectedIndex.value == index ? Colors.red : Colors.black,
      ),
    );
  }

  List<Widget> _buildSubList(int index) {
    final title = SliverToBoxAdapter(
      child: ObserverProxy(
        observer: _observers[index]!.titleObserver,
        child: Center(
          child: Text(
            _groups[index],
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
    ;
    final list = SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, itemIndex) => _buildGroupItem(index, itemIndex),
        childCount: _groupCounts[index],
      ),
    );
    return [title, list];
  }

  Widget _buildGroupItem(int groupIndex, int itemIndex) {
    return ObserverProxy(
      observer: _observers[groupIndex]!.itemObserver,
      child: ListTile(
        title: Text("${_groups[groupIndex]}: $itemIndex"),
      ),
    );
  }

  void _listenIndexChange() {
    final groupObserver = _observers[_selectedIndex.value]!;

    final scrollDirection = _controller.position.userScrollDirection;

    if (scrollDirection != ScrollDirection.idle) return;

    if (!groupObserver.titleObserver.renderVisible) {
      groupObserver.titleObserver.showInViewport(
        _controller.position,
        duration: const Duration(milliseconds: 300),
      );
    }
  }

  void _listenScroll() {
    final scrollDirection = _controller.position.userScrollDirection;

    if (scrollDirection == ScrollDirection.idle) return;

    final currentRatio = _getSubListRatio(_selectedIndex.value);

    final candidate = scrollDirection == ScrollDirection.forward
        ? _selectedIndex.value - 1
        : _selectedIndex.value + 1;

    final candidateRatio = _getSubListRatio(candidate);

    if (candidateRatio > currentRatio) {
      _selectedIndex.value = candidate;
    }
  }

  double _getSubListRatio(int index) {
    if (!_observers.containsKey(index)) return 0.0;

    final scrollExtent = ScrollExtent.fromPosition(_controller.position);
    final groupObserver = _observers[index]!;

    final titleRatio =
        groupObserver.titleObserver.visibleRatioInViewport(scrollExtent);
    final itemRatio =
        groupObserver.itemObserver.visibleRatioInViewport(scrollExtent);

    return titleRatio + itemRatio;
  }
}

class GroupListTabBar extends StatefulWidget {
  final int tabCount;
  final IndexedWidgetBuilder tabBuilder;
  final ValueNotifier<int> selected;
  const GroupListTabBar({
    super.key,
    required this.tabCount,
    required this.tabBuilder,
    required this.selected,
  });

  @override
  State<GroupListTabBar> createState() => _GroupListTabBarState();
}

class _GroupListTabBarState extends State<GroupListTabBar>
    with SingleTickerProviderStateMixin {
  late final TabController _controller = TabController(
    length: widget.tabCount,
    vsync: this,
  );

  @override
  void initState() {
    super.initState();
    widget.selected.addListener(_onIndexChange);
  }

  void _select(int index) {
    widget.selected.value = index;
  }

  void _onIndexChange() {
    print("current tab: ${widget.selected.value}");
    _controller.animateTo(
      widget.selected.value,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    widget.selected.removeListener(_onIndexChange);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: _controller,
      isScrollable: true,
      indicator: const BoxDecoration(),
      tabs: List.generate(
        widget.tabCount,
        (index) => ValueListenableBuilder(
          valueListenable: widget.selected,
          builder: (_, selected, child) {
            return DecoratedBox(
              decoration: BoxDecoration(
                color: selected == index ? Colors.green : Colors.grey,
              ),
              child: widget.tabBuilder(_, index),
            );
          },
        ),
      ),
      onTap: _select,
    );
  }
}
