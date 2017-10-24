import 'package:flutter/material.dart';

import '../wilddog_sync.dart';
import 'wilddog_list.dart';
import 'wilddog_sorted_list.dart';

typedef Widget WilddogAnimatedListItemBuilder(
  BuildContext context,
  DataSnapshot snapshot,
  Animation<double> animation,
  int index,
);

/// 绑定到查询的AnimatedList控件。
class WilddogAnimatedList extends StatefulWidget {
  /// 创建一个滚动容器，在插入或移除项目时使其动画化。
  WilddogAnimatedList({
    Key key,
    this.query,
    this.itemBuilder,
    this.sort,
    this.defaultChild,
    this.scrollDirection: Axis.vertical,
    this.reverse: false,
    this.controller,
    this.primary,
    this.physics,
    this.shrinkWrap: false,
    this.padding,
    this.duration: const Duration(milliseconds: 300),
  })
      : super(key: key) {
    assert(itemBuilder != null);
  }

  /// 用于填充动画列表的Wilddog查询。
  final Query query;

  /// 用于在排序列表时比较快照（可选功能）。
  ///
  /// 默认值是按key对快照进行排序。
  final Comparator<DataSnapshot> sort;

  /// 在query加载时显示的按件，默认为空的Container()。
  final Widget defaultChild;

  /// 根据需要调用构建列表项控件。
  ///
  /// 列表项目仅在滚动到视图时构建。
  ///
  /// [DataSnapshot]参数指示应用于构建项目的快照。
  ///
  /// 此回调的实现应该假定[AnimatedList.removeItem]立即删除一个项目。
  final WilddogAnimatedListItemBuilder itemBuilder;

  /// 滚动视图中滚动轴方向。
  ///
  /// 默认为[Axis.vertical]。
  final Axis scrollDirection;

  /// 滚动视图是否在阅读方向滚动。
  ///
  /// 例如，如果读取方向是从左到右，[scrollDirection]是[Axis.horizontal]，
  /// 则当[reverse]为false时，滚动视图从左到右滚动，当[reverse]为true时，从右到左滚动。
  ///
  /// 类似地，如果[scrollDirection]是[Axis.vertical]，
  /// 则当[reverse]为false时，滚动视图从上到下滚动，当[reverse]为true时，从下到上滚动。
  ///
  /// 默认为false。
  final bool reverse;

  /// 可用于控制滚动视图滚动到的位置的控制器对象。
  ///
  /// 如果[primary]为true，则必须为null。
  final ScrollController controller;

  /// 这是否是与父[PrimaryScrollController]关联的主滚动视图。
  ///
  /// 在iOS上，这会标识将滚动到顶部的滚动视图，以响应状态栏中的点击。
  ///
  /// 当[scrollDirection]为[Axis.vertical]和[controller]为null时，默认为true。
  final bool primary;

  /// 滚动视图应如何响应用户输入。
  ///
  /// 或者例如，在用户停止拖动滚动视图之后，确定滚动视图如何继续动画。
  ///
  /// 默认为匹配平台约定。
  final ScrollPhysics physics;

  /// [scrollDirection]中滚动视图的范围是否应由正在查看的内容确定。
  ///
  /// 如果滚动视图不收缩包装，则滚动视图将扩展为[scrollDirection]中允许的最大尺寸。
  /// 如果滚动视图在[scrollDirection]中有无限制的约束，则[shrinkWrap]必须为true。
  ///
  /// 滚动视图的内容收缩显着地比扩展到允许的最大尺寸要贵得多，
  /// 因为在滚动期间内容可以扩展和收缩，这意味着每当滚动位置改变时，
  /// 需要重新计算滚动视图的大小。
  ///
  /// 默认为false。
  final bool shrinkWrap;

  /// 插入子控件的空间量。
  final EdgeInsets padding;

  /// 插入和删除动画的持续时间。
  ///
  /// 默认为const持续时间（300毫秒）。
  final Duration duration;

  @override
  WilddogAnimatedListState createState() => new WilddogAnimatedListState();
}

class WilddogAnimatedListState extends State<WilddogAnimatedList> {
  final GlobalKey<AnimatedListState> _animatedListKey =
  new GlobalKey<AnimatedListState>();
  List<DataSnapshot> _model;
  bool _loaded = false;

  /*
  当此State对象的依赖关系发生变化时调用。

  例如，如果之前对build的调用引用了随后更改的InheritedWidget，
  则框架将调用此方法来通知此对象有关更改。

  这个方法也是在initState之后立即调用的。
  从这个方法调用BuildContext.inheritFromWidgetOfExactType是安全的。

  子类很少重写此方法，因为框架总是在依赖关系更改后调用build。
  某些子类确实会覆盖此方法，因为它们的依赖关系发生变化时需要做一些昂贵的工作（如网络提取），
  而且这些工作对于每个build来说都是太贵了。
   */
  @override
  void didChangeDependencies() {
    if (widget.sort != null) {
      _model = new WilddogSortedList(
        query: widget.query,
        comparator: widget.sort,
        onChildAdded: _onChildAdded,
        onChildRemoved: _onChildRemoved,
        onChildChanged: _onChildChanged,
        onValue: _onValue,
      );
    } else {
      _model = new WilddogList(
        query: widget.query,
        onChildAdded: _onChildAdded,
        onChildRemoved: _onChildRemoved,
        onChildChanged: _onChildChanged,
        onChildMoved: _onChildMoved,
        onValue: _onValue,
      );
    }
    super.didChangeDependencies();
  }

  void _onChildAdded(int index, DataSnapshot snapshot) {
    if (!_loaded) {
      // AnimatedList尚未创建。
      return;
    }
    _animatedListKey.currentState.insertItem(index, duration: widget.duration);
  }

  void _onChildRemoved(int index, DataSnapshot snapshot) {
    // 现在该子节点已经从模型中移除了。
    assert(index >= _model.length || _model[index].key != snapshot.key);

    /*
    currentState属性表示当前控件树中具有此全局密钥的控件的State。

    removeItem方法用于删除index（索引）处的项目，并启动一个动画，
    当项目可见时，该动画将传递给builder（构建器）。

    项目会立即被删除，一个项目被删除后，其索引将不再传递给AnimatedList.itemBuilder。
    但是，项目仍将持续显示在列表中，在此期间，构建器必须根据需要构建其控件。
     */
    _animatedListKey.currentState.removeItem(
      index,
      (BuildContext context, Animation<double> animation) {
        return widget.itemBuilder(context, snapshot, animation, index);
      },
      duration: widget.duration,
    );
  }

  // 没有动画，只是更新内容。
  void _onChildChanged(int index, DataSnapshot snapshot) {
    setState(() {});
  }

  // 没有动画，只是更新内容。
  void _onChildMoved(int fromIndex, int toIndex, DataSnapshot snapshot) {
    setState(() {});
  }

  void _onValue(DataSnapshot _) {
    setState(() {
      _loaded = true;
    });
  }

  Widget _buildItem(
      BuildContext context, int index, Animation<double> animation) {
    return widget.itemBuilder(context, _model[index], animation, index);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      // 如果defaultChild（在query加载时显示的按件）为空，则返回空的Container()
      return widget.defaultChild ?? new Container();
    }

    /*
    AnimatedList控件是一个滚动容器，当插入或移除项目时，会播放动画。

    该控件的AnimatedListState可用于动态插入或删除项目。
    引用AnimatedListState提供一个GlobalKey，或从一个项目的输入回调中使用静态的of方法。

    这个控件类似于ListView.builder创建的。

    属性如下
    itemBuilder：根据需要调用构建列表项控件。
    initialItemCount：列表开始的项目数。
    scrollDirection：滚动视图滚动的轴。
    reverse：滚动视图是否在阅读方向滚动。
    controller：可用于控制滚动视图滚动到的位置的对象。
    primary：这是否是与父PrimaryScrollController相关联的主滚动视图。
    physics：滚动视图应如何响应用户输入。
    shrinkWrap：scrollDirection中的滚动视图的范围是否应由正在查看的内容确定。
    padding：插入子控件的空间量。
     */
    return new AnimatedList(
      key: _animatedListKey,
      itemBuilder: _buildItem,
      initialItemCount: _model.length,
      scrollDirection: widget.scrollDirection,
      reverse: widget.reverse,
      controller: widget.controller,
      primary: widget.primary,
      physics: widget.physics,
      shrinkWrap: widget.shrinkWrap,
      padding: widget.padding,
    );
  }
}