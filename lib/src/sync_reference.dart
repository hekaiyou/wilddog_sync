part of wilddog_sync;

/// SyncReference表示WilddogSync中的特定位置，可用于读取或写入数据到该位置。
///
/// 这个类是所有WilddogSync操作的起点，
/// 通过`WilddogSync.reference()`获得第一个SyncReference后，
/// 可以使用它读取数据（即`onChildAdded`），写入数据（即`set`），
/// 并创建新的`SyncReference`（即`child`）。
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

  /// 获取父位置的SyncReference。
  /// 如果此实例引用您的WilddogSync的根，它没有父，因此parent()将返回null。
  SyncReference parent() {
    if (_pathComponents.isEmpty) {
      return null;
    }
    return new SyncReference._(
        _database, (new List<String>.from(_pathComponents)..removeLast()));
  }

  /// 获取根位置的WDGSyncReference。
  SyncReference root() {
    return new SyncReference._(_database, <String>[]);
  }

  /// 获取WilddogSync位置中的最后一个令牌，
  /// 例如https://SampleChat.firebaseIO-demo.com/users/fred中的fred’。
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
  /// 将`value`写入具有指定`priority`的位置（如果适用）。
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

  /// 用`value`更新节点。
  Future<Null> update(Map<String, dynamic> value) {
    return _database._channel.invokeMethod(
      'SyncReference#update',
      <String, dynamic>{'path': path, 'value': value},
    );
  }

  /// 为此WilddogSync位置的数据设置优先级。
  ///
  /// 优先级可以为某个位置的子节点提供自定义排序，如果没有指定优先级，则按key排序子节点。
  ///
  /// 您不能在空的位置设置优先级，因此，当设置具有特定优先级的初始数据时应使用set()，
  /// 并且在更新现有数据的优先级时应使用setPriority()。
  ///
  /// 使用以下规则，将根据此优先级对子节点进行排序：
  ///
  /// 没有优先权的子节点先来了，接下来有数字优先的子节点，它们按优先级排序从小到大排序。
  /// 以字符串为优先的子节点来到最后，它们按照字典顺序排列。
  /// 每当两个子节点具有相同的优先级时，它们按key排序。
  /// 数字键首先按数字大小排序，其次剩余的key按字典排序。
  ///
  /// 请注意，优先级被解析为IEEE 754双精度浮点数排序。
  /// key总是作为字符串存储，只有当它们可以被解析为32位整数时才被视为数字。
  Future<Null> setPriority(dynamic priority) async {
    return _database._channel.invokeMethod(
      'SyncReference#setPriority',
      <String, dynamic>{'path': path, 'priority': priority},
    );
  }

  /// 在这个WilddogSync位置删除数据，所有子节点的数据也将被删除。
  ///
  /// 删除的效果将立即可见，相应的事件将被触发，对WilddogSync服务器的数据同步也将开始。
  ///
  /// remove()等效于调用set(null)。
  Future<Null> remove() => set(null);
}

class ServerValue {
  static const Map<String, String> timestamp = const <String, String>{
    '.sv': 'timestamp'
  };
}