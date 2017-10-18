part of wilddog_sync;

enum _EventType {
  childAdded,
  childRemoved,
  childChanged,
  childMoved,
  value,
}

/// "Event"封装了一个DataSnapshot，也可能是它之前的兄弟姐妹的Key，可以用来命令快照。
class Event {
  Map<String, dynamic> _data;
  Event._(this._data) : snapshot = new DataSnapshot._(_data['snapshot']);

  final DataSnapshot snapshot;
  String get previousSiblingKey => _data['previousSiblingKey'];
}

/// DataSnapshot包含来自WilddogSync位置的数据，
/// 每当读取Wilddog数据时，将收到DataSnapshot数据。
class DataSnapshot {
  Map<String, dynamic> _data;
  DataSnapshot._(this._data);

  /// 生成此DataSnapshot的位置的key值。
  String get key => _data['key'];

  /// 以本机类型返回此数据快照的value值。
  dynamic get value => _data['value'];
}