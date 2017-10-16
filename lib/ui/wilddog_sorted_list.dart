import 'dart:collection';

import 'package:meta/meta.dart';

import '../wilddog_sync.dart' show DataSnapshot, Event, Query;
import 'wilddog_list.dart' show ChildCallback, ValueCallback;
import 'utils/stream_subscriber_mixin.dart';

class WilddogSortedList extends ListBase<DataSnapshot>
    with StreamSubscriberMixin<Event> {
  WilddogSortedList({
    @required this.query,
    @required this.comparator,
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

  final Query query;

  final Comparator<DataSnapshot> comparator;

  final ChildCallback onChildAdded;

  final ChildCallback onChildRemoved;

  final ChildCallback onChildChanged;

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

  void _onChildAdded(Event event) {
    _snapshots.add(event.snapshot);
    _snapshots.sort(comparator);
    onChildAdded(_snapshots.indexOf(event.snapshot), event.snapshot);
  }

  void _onChildRemoved(Event event) {
    final DataSnapshot snapshot =
    _snapshots.firstWhere((DataSnapshot snapshot) {
      return snapshot.key == event.snapshot.key;
    });
    final int index = _snapshots.indexOf(snapshot);
    _snapshots.removeAt(index);
    onChildRemoved(index, snapshot);
  }

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