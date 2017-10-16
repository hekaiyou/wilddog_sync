part of wilddog_sync;

class SyncReference extends Query {
  SyncReference._(WilddogSync database, List<String> pathComponents)
      : super._(database: database, pathComponents: pathComponents);

  ///拆分路径为String列表，比如将"counter/abc"拆为"[counter, abc]"
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

  SyncReference push() {
    final String key = PushIdGenerator.generatePushChildName();
    final List<String> childPath = new List<String>.from(_pathComponents)
      ..add(key);
    return new SyncReference._(_database, childPath);
  }

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