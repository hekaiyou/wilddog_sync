import 'dart:collection';

import '../wilddog_sync.dart' show DataSnapshot, Event, Query;
import 'wilddog_list.dart' show ChildCallback, ValueCallback;
import 'utils/stream_subscriber_mixin.dart';

/// 在客户端使用`comparator`对`query`的结果进行排序。
class WilddogSortedList extends ListBase<DataSnapshot>
    with StreamSubscriberMixin<Event> {
  WilddogSortedList({
    this.query,
    this.comparator,
    this.onChildAdded,
    this.onChildRemoved,
    this.onChildChanged,
    this.onValue,
  }) {
    assert(query != null);
    assert(comparator != null);
    listen(query.onChildAdded, _onChildAdded);
    listen(query.onChildRemoved, _onChildRemoved);
    listen(query.onChildChanged, _onChildChanged);
    listen(query.onValue, _onValue);
  }

  /// Sync查询用于填充列表。
  final Query query;

  /// comparator用于对客户端上的列表进行排序。
  final Comparator<DataSnapshot> comparator;

  /// 当子节点被添加时调用。
  final ChildCallback onChildAdded;

  /// 当子节点被删除时调用。
  final ChildCallback onChildRemoved;

  /// 当子节点发生变化时调用。
  final ChildCallback onChildChanged;

  /// 当列表的数据加载完成时调用。
  final ValueCallback onValue;

  /// ListBase实现。
  final List<DataSnapshot> _snapshots = <DataSnapshot>[];

  // 覆盖get()方法。
  @override
  int get length => _snapshots.length;

  // 覆盖set()方法
  @override
  set length(int value) {
    throw new UnsupportedError("列表无法修改");
  }

  // 重写DataSnapshot类型的[]运算符。
  @override
  DataSnapshot operator [](int index) => _snapshots[index];

  // 重写[]运算符。
  @override
  void operator []=(int index, DataSnapshot value) {
    throw new UnsupportedError("列表无法修改");
  }

  // 关于加入的子节点。
  void _onChildAdded(Event event) {
    _snapshots.add(event.snapshot);
    // List的sort方法根据比较方法指定的顺序排列此列表。
    _snapshots.sort(comparator);
    onChildAdded(_snapshots.indexOf(event.snapshot), event.snapshot);
  }

  // 关于子节点被删除时。
  void _onChildRemoved(Event event) {
    /*
    firstWhere方法返回满足给定谓词测试的第一个元素。
    通过元素迭代并返回第一个来满足测试。
    如果没有元素满足测试，则返回调用orElse函数的结果。
    如果orElse被省略，则默认将抛出一个StateError。
     */
    final DataSnapshot snapshot =
    _snapshots.firstWhere((DataSnapshot snapshot) {
      return snapshot.key == event.snapshot.key;
    });
    // indexOf方法返回此列表中元素的第一个索引。
    final int index = _snapshots.indexOf(snapshot);
    // removeAt方法从该列表中移除位置索引处的对象。
    _snapshots.removeAt(index);
    onChildRemoved(index, snapshot);
  }

  // 关于在子节点改变时。
  void _onChildChanged(Event event) {
    final DataSnapshot snapshot =
    _snapshots.firstWhere((DataSnapshot snapshot) {
      return snapshot.key == event.snapshot.key;
    });
    final int index = _snapshots.indexOf(snapshot);
    _snapshots[index] = event.snapshot;
    onChildChanged(index, event.snapshot);
  }

  void _onValue(Event event) {
    onValue(event.snapshot);
  }
}