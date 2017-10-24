import 'dart:collection';

import '../wilddog_sync.dart' show DataSnapshot, Event, Query;
import 'utils/stream_subscriber_mixin.dart';

typedef void ChildCallback(int index, DataSnapshot snapshot);
typedef void ChildMovedCallback(
    int fromIndex, int toIndex, DataSnapshot snapshot);
typedef void ValueCallback(DataSnapshot snapshot);

/// 使用`DataSnapshot.key`在客户端上排序`query`的结果。
class WilddogList extends ListBase<DataSnapshot>
    with StreamSubscriberMixin<Event> {
  WilddogList({
    this.query,
    this.onChildAdded,
    this.onChildRemoved,
    this.onChildChanged,
    this.onChildMoved,
    this.onValue,
  }) {
    assert(query != null);
    listen(query.onChildAdded, _onChildAdded);
    listen(query.onChildRemoved, _onChildRemoved);
    listen(query.onChildChanged, _onChildChanged);
    listen(query.onChildMoved, _onChildMoved);
    listen(query.onValue, _onValue);
  }

  /// Sync查询用于填充列表。
  final Query query;

  /// 当子节点被添加时调用。
  final ChildCallback onChildAdded;

  /// 当子节点被删除时调用。
  final ChildCallback onChildRemoved;

  /// 当子节点发生变化时调用。
  final ChildCallback onChildChanged;

  /// 当子节点移动时调用。
  final ChildMovedCallback onChildMoved;

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

  // 根据key获取对应的索引。
  int _indexForKey(String key) {
    assert(key != null);
    for (int index = 0; index < _snapshots.length; index++) {
      if (key == _snapshots[index].key) {
        return index;
      }
    }
    return null;
  }

  // 关于加入的子节点。
  void _onChildAdded(Event event) {
    int index = 0;
    if (event.previousSiblingKey != null) {
      index = _indexForKey(event.previousSiblingKey) + 1;
    }
    // List的insert方法在该列表中的位置索引处插入对象。
    _snapshots.insert(index, event.snapshot);
    onChildAdded(index, event.snapshot);
  }

  // 关于子节点被删除时。
  void _onChildRemoved(Event event) {
    final int index = _indexForKey(event.snapshot.key);
    // removeAt方法从该列表中移除位置索引处的对象。
    _snapshots.removeAt(index);
    onChildRemoved(index, event.snapshot);
  }

  // 关于在子节点改变时。
  void _onChildChanged(Event event) {
    final int index = _indexForKey(event.snapshot.key);
    _snapshots[index] = event.snapshot;
    onChildChanged(index, event.snapshot);
  }

  // 关于对子节点移动时。
  void _onChildMoved(Event event) {
    final int fromIndex = _indexForKey(event.snapshot.key);
    _snapshots.removeAt(fromIndex);

    int toIndex = 0;
    if (event.previousSiblingKey != null) {
      final int prevIndex = _indexForKey(event.previousSiblingKey);
      if (prevIndex != null) {
        toIndex = prevIndex + 1;
      }
    }
    _snapshots.insert(toIndex, event.snapshot);
    onChildMoved(fromIndex, toIndex, event.snapshot);
  }

  void _onValue(Event event) {
    onValue(event.snapshot);
  }
}