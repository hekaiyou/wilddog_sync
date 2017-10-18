part of wilddog_sync;

/// SyncReference表示WilddogSync中的特定位置，可用于读取或写入数据到该位置。
///
/// 这个类是所有WilddogSync操作的起点，
/// 通过WilddogSync.reference()获得第一个SyncReference后，
/// 可以使用它读取数据（即"onChildAdded"），写入数据（即"set"），
/// 并创建新的SyncReference（即child"）。
class SyncReference extends Query {
  SyncReference._(WilddogSync database, List<String> pathComponents)
      : super._(database: database, pathComponents: pathComponents);

  /*
  List.from会创建一个包含所有元素的列表。
  addAll方法将所有可迭代的对象附加到此列表的末尾。
  split方法使用指定字符将字符串拆分，并返回一个子字符串列表。
   */
  /// 获取指定相对位置的SyncReference路径，相对路径可以是简单的子Key（例如"fred"）
  /// 或更深的斜线分隔的路径（例如"fred/name/first"）。
  SyncReference child(String path) {
    return new SyncReference._(_database,
        (new List<String>.from(_pathComponents)..addAll(path.split('/'))));
  }

  SyncReference parent() {
    if (_pathComponents.isEmpty) {
      return null;
    }
    return new SyncReference._(
        _database, (new List<String>.from(_pathComponents)..removeLast()));
  }

  SyncReference root() {
    return new SyncReference._(_database, <String>[]);
  }

  String get key => _pathComponents.last;

  /// 使用唯一Key生成新的子节点并返回一个SyncReference。
  /// 当WilddogSync位置的子节点项目是列表时是很有用的。
  ///
  /// 由自定义PushIdGenerator类生成的唯一密钥以客户端生成的时间戳为前缀，
  /// 以便生成的列表将按时间顺序排序。
  SyncReference push() {
    final String key = PushIdGenerator.generatePushChildName();
    final List<String> childPath = new List<String>.from(_pathComponents)
      ..add(key);
    return new SyncReference._(_database, childPath);
  }

  /*
  invokeMethod使用指定的参数调用此通道上的一个方法。
  自定义的priority参数可以设置节点的优先级，默认值为0。
   */
  /// 将value写入具有指定的优先级的位置（如果适用）。
  ///
  /// 操作将覆盖此位置及其所有子位置的所有数据。
  ///
  /// 允许的数据类型是String、boolean、int、double、Map和List。
  ///
  /// 写入的效果将立即可见，相应的事件将被触发，对WilddogSync服务器的数据同步也将开始。
  ///
  /// 为value设置为null意味着此位置及其所有子位置的所有数据都将被删除。
  Future<Null> set(dynamic value, {dynamic priority=0}) {
    return _database._channel.invokeMethod(
      'SyncReference#set',
      <String, dynamic>{'path': path, 'value': value, 'priority': priority},
    );
  }

  Future<Null> update(Map<String, dynamic> value) {
    return _database._channel.invokeMethod(
      'SyncReference#update',
      <String, dynamic>{'path': path, 'value': value},
    );
  }

  Future<Null> setPriority(dynamic priority) async {
    return _database._channel.invokeMethod(
      'SyncReference#setPriority',
      <String, dynamic>{'path': path, 'priority': priority},
    );
  }

  Future<Null> remove() => set(null);
}

class ServerValue {
  static const Map<String, String> timestamp = const <String, String>{
    '.sv': 'timestamp'
  };
}