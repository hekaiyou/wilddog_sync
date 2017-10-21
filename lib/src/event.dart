part of wilddog_sync;

/*
枚举类_EventType，定义事件类型。
childAdded为子节点增加事件，childRemoved为子节点被移除事件，
childChanged为子节点更改事件，childMoved为子节点移动事件，
value为获取节点的值事件。
 */
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