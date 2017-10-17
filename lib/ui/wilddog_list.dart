import 'dart:collection';

import '../wilddog_sync.dart' show DataSnapshot, Event, Query;
import 'utils/stream_subscriber_mixin.dart';

typedef void ChildCallback(int index, DataSnapshot snapshot);
typedef void ChildMovedCallback(
    int fromIndex, int toIndex, DataSnapshot snapshot);
typedef void ValueCallback(DataSnapshot snapshot);

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

  final Query query;

  final ChildCallback onChildAdded;

  final ChildCallback onChildRemoved;

  final ChildCallback onChildChanged;

  final ChildMovedCallback onChildMoved;

  final ValueCallback onValue;

  final List<DataSnapshot> _snapshots = <DataSnapshot>[];

  @override
  int get length => _snapshots.length;

  @override
  set length(int value) {
    throw new UnsupportedError("列表无法修改");
  }

  @override
  DataSnapshot operator [](int index) => _snapshots[index];

  @override
  void operator []=(int index, DataSnapshot value) {
    throw new UnsupportedError("列表无法修改");
  }

  int _indexForKey(String key) {
    assert(key != null);
    for (int index = 0; index < _snapshots.length; index++) {
      if (key == _snapshots[index].key) {
        return index;
      }
    }
    return null;
  }

  void _onChildAdded(Event event) {
    int index = 0;
    if (event.previousSiblingKey != null) {
      index = _indexForKey(event.previousSiblingKey) + 1;
    }
    _snapshots.insert(index, event.snapshot);
    onChildAdded(index, event.snapshot);
  }

  void _onChildRemoved(Event event) {
    final int index = _indexForKey(event.snapshot.key);
    _snapshots.removeAt(index);
    onChildRemoved(index, event.snapshot);
  }

  void _onChildChanged(Event event) {
    final int index = _indexForKey(event.snapshot.key);
    _snapshots[index] = event.snapshot;
    onChildChanged(index, event.snapshot);
  }

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