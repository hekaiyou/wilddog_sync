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

class WilddogAnimatedList extends StatefulWidget {
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

  final Query query;

  final Comparator<DataSnapshot> sort;

  final Widget defaultChild;

  final WilddogAnimatedListItemBuilder itemBuilder;

  final Axis scrollDirection;

  final bool reverse;

  final ScrollController controller;

  final bool primary;

  final ScrollPhysics physics;

  final bool shrinkWrap;

  final EdgeInsets padding;

  final Duration duration;

  @override
  WilddogAnimatedListState createState() => new WilddogAnimatedListState();
}

class WilddogAnimatedListState extends State<WilddogAnimatedList> {
  final GlobalKey<AnimatedListState> _animatedListKey =
  new GlobalKey<AnimatedListState>();
  List<DataSnapshot> _model;
  bool _loaded = false;

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
      return;
    }
    _animatedListKey.currentState.insertItem(index, duration: widget.duration);
  }

  void _onChildRemoved(int index, DataSnapshot snapshot) {
    assert(index >= _model.length || _model[index].key != snapshot.key);
    _animatedListKey.currentState.removeItem(
      index,
          (BuildContext context, Animation<double> animation) {
        return widget.itemBuilder(context, snapshot, animation, index);
      },
      duration: widget.duration,
    );
  }

  void _onChildChanged(int index, DataSnapshot snapshot) {
    setState(() {});
  }

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
      return widget.defaultChild ?? new Container();
    }
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