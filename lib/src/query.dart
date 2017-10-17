part of wilddog_sync;

class Query {
  Query._(
      {WilddogSync database,
        List<String> pathComponents,
        Map<String, dynamic> parameters})
      : _database = database,
        _pathComponents = pathComponents,
        _parameters = parameters ??
            new Map<String, dynamic>.unmodifiable(<String, dynamic>{}),
        assert(database != null);

  final WilddogSync _database;
  final List<String> _pathComponents;
  final Map<String, dynamic> _parameters;

  // 斜杠分隔的路径，表示此查询的数据库位置。
  String get path => _pathComponents.join('/');

  Query _copyWithParameters(Map<String, dynamic> parameters) {
    return new Query._(
      database: _database,
      pathComponents: _pathComponents,
      parameters: new Map<String, dynamic>.unmodifiable(
        new Map<String, dynamic>.from(_parameters)..addAll(parameters),
      ),
    );
  }

  Map<String, dynamic> buildArguments() {
    return new Map<String, dynamic>.from(_parameters)
      ..addAll(<String, dynamic>{
        'path': path,
      });
  }

  Stream<Event> _observe(_EventType eventType) {
    Future<int> _handle;
    // 一旦所有订阅者取消，StreamController就会被当成垃圾收集，忽略分析仪的警告。
    StreamController<Event> controller;
    controller = new StreamController<Event>.broadcast(
      onListen: () {
        _handle = _database._channel.invokeMethod(
          'Query#observe',
          <String, dynamic>{
            'path': path,
            'parameters': _parameters,
            'eventType': eventType.toString(),
          },
        );
        _handle.then((int handle) {
          WilddogSync._observers[handle] = controller;
        });
      },
      onCancel: () {
        _handle.then((int handle) async {
          await _database._channel.invokeMethod(
            'Query#removeObserver',
            <String, dynamic>{
              'path': path,
              'parameters': _parameters,
              'handle': handle,
            },
          );
          WilddogSync._observers.remove(handle);
        });
      },
    );
    return controller.stream;
  }

  // 侦听单个值事件，然后停止侦听。
  Future<DataSnapshot> once() async => (await onValue.first).snapshot;

  // 子节点加入时触发。
  Stream<Event> get onChildAdded => _observe(_EventType.childAdded);

  // 子节点被移除时触发，previousChildKey为null。
  Stream<Event> get onChildRemoved => _observe(_EventType.childRemoved);

  // 子节点改变时触发。
  Stream<Event> get onChildChanged => _observe(_EventType.childChanged);

  // 子节点被改动时触发。
  Stream<Event> get onChildMoved => _observe(_EventType.childMoved);

  // 当该节点的数据更新时触发，previousChildKey为null。
  Stream<Event> get onValue => _observe(_EventType.value);

  Query startAt(dynamic value, {String key}) {
    assert(!_parameters.containsKey('startAt'));
    assert(value is String || value is bool || value is double || value is int);
    final Map<String, dynamic> parameters = <String, dynamic>{'startAt': value};
    if (key != null) parameters['startAtKey'] = key;
    return _copyWithParameters(parameters);
  }

  Query endAt(dynamic value, {String key}) {
    assert(!_parameters.containsKey('endAt'));
    assert(value is String || value is bool || value is double || value is int);
    final Map<String, dynamic> parameters = <String, dynamic>{'endAt': value};
    if (key != null) parameters['endAtKey'] = key;
    return _copyWithParameters(parameters);
  }

  Query equalTo(dynamic value, {String key}) {
    assert(!_parameters.containsKey('equalTo'));
    assert(value is String || value is bool || value is double || value is int);
    return _copyWithParameters(
      <String, dynamic>{'equalTo': value, 'equalToKey': key},
    );
  }

  Query limitToFirst(int limit) {
    assert(!_parameters.containsKey('limitToFirst'));
    return _copyWithParameters(<String, dynamic>{'limitToFirst': limit});
  }

  // 创建一个有限制的查询并将其锚定到窗口的末尾。
  Query limitToLast(int limit) {
    assert(!_parameters.containsKey('limitToLast'));
    return _copyWithParameters(<String, dynamic>{'limitToLast': limit});
  }

  Query orderByChild(String key) {
    assert(key != null);
    assert(!_parameters.containsKey('orderBy'));
    return _copyWithParameters(
      <String, dynamic>{'orderBy': 'child', 'orderByChildKey': key},
    );
  }

  Query orderByKey() {
    assert(!_parameters.containsKey('orderBy'));
    return _copyWithParameters(<String, dynamic>{'orderBy': 'key'});
  }

  Query orderByValue() {
    assert(!_parameters.containsKey('orderBy'));
    return _copyWithParameters(<String, dynamic>{'orderBy': 'value'});
  }

  Query orderByPriority() {
    assert(!_parameters.containsKey('orderBy'));
    return _copyWithParameters(<String, dynamic>{'orderBy': 'priority'});
  }

  SyncReference reference() =>
      new SyncReference._(_database, _pathComponents);

  /*
   * 通过在一个位置调用keepSynced(true)，这个位置将被自动下载并保持同步的数据，即使没有听众也一样。
   * 此外，在一个位置保持同步，它将不会被驱逐出持续的磁盘高速缓存。
   */
  Future<Null> keepSynced(bool value) {
    return _database._channel.invokeMethod(
      'Query#keepSynced',
      <String, dynamic>{
        'path': path,
        'parameters': _parameters,
        'value': value
      },
    );
  }
}