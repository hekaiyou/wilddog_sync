part of wilddog_sync;

/// 表示对特定位置的数据的查询。
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

  /*
  _database存储当前WilddogSync的实例。
  _pathComponents存储当前SyncReference路径的字符串列表。
  _parameters存储当前查询的参数列表。
   */
  final WilddogSync _database;
  final List<String> _pathComponents;
  final Map<String, dynamic> _parameters;

  /// 斜杠分隔的路径，表示此查询的数据库位置。
  String get path => _pathComponents.join('/');

  /// 在当前Query实例的参数列表中添加新参数。
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

  /*
  StreamController类是能控制`stream`的控制器。
  构造函数`StreamController.broadcast`创建一个控制器，其中stream可以被多次监听。

  `Stream`返回的stream是广播流，它可以监听多次。

  一个stream应该是惰性的，直到用户开始监听（使用`onListen`回调开始生成事件）。
  当没有用户在stream上监听时，stream不应该泄漏资源（例如websockets）。

  当没有监听器时，广播流不缓冲事件。

  当调用`add`、`addError`或`close`时，控制器会将任何事件分配给所有当前订阅的监听器。
  在前一次调用返回之前，不允许调用add、addError或close。
  控制器没有任何内部事件队列，如果在事件添加时没有监听器，它将被丢弃，
  或者如果是错误，则报告为未被捕获。

  每个监听器订阅是独立处理的，如果一个暂停，只有暂停监听器受到影响。
  暂停的监听器将在内部缓冲事件，直到取消暂停或取消。

  如果sync是true，则在add、addError或close调用期间，stream的订阅可能直接触发事件。
  返回的stream控制器是`SynchronousStreamController`，须谨慎使用，不要中断stream合同。

  如果sync为false，则在添加事件的代码完成后，事件将始终被触发。
  在这种情况下，对于多个监听器获取事件的时间不作任何保证，
  除了每个监听器将以正确的顺序获取所有事件。每个订阅单独处理事件。
  如果两个事件在具有两个监听器的异步控制器上发送，
  其中一个监听器可能会在另一个监听器获得任何事件之前获取这两个事件。
  当事件被启动时（即调用`add`时）以及事件以后发送时，必须同时订阅一个监听器，以便接收事件。

  当第一个监听器被订阅时，调用`onListen`回调，当不再有任何活动的监听器时调用`onCancel`。
  如果稍后再添加一个监听器，在调用onCancel之后，再次调用onListen。
   */
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

  /// 监听单个值事件，然后停止监听。
  Future<DataSnapshot> once() async => (await onValue.first).snapshot;

  // 子节点加入时触发。
  Stream<Event> get onChildAdded => _observe(_EventType.childAdded);

  // 子节点被移除时触发，previousChildKey为null。
  Stream<Event> get onChildRemoved => _observe(_EventType.childRemoved);

  // 子节点改变时触发。
  Stream<Event> get onChildChanged => _observe(_EventType.childChanged);

  // 子节点被改动时触发。
  Stream<Event> get onChildMoved => _observe(_EventType.childMoved);

  /// 当该节点的数据更新时触发，previousChildKey为null。
  Stream<Event> get onValue => _observe(_EventType.value);

  /// 创建一个限制为仅使用大于或等于给定value的子节点返回的查询，
  /// 使用给定的orderBy指令或优先级作为默认值，
  /// 以及可选择仅包含key大于或等于给定key的子节点。
  Query startAt(dynamic value, {String key}) {
    // 如果assert的判断为true，则继续执行下面的语句，反之则会丢出异常。
    assert(!_parameters.containsKey('startAt'));
    // 如果Map包含给定的key，则containsKey方法返回true。
    // value必须是String、bool、double和int类型的一种类型。
    assert(value is String || value is bool || value is double || value is int);
    final Map<String, dynamic> parameters = <String, dynamic>{'startAt': value};
    if (key != null) parameters['startAtKey'] = key;
    return _copyWithParameters(parameters);
  }

  /// 创建一个限制为只返回小于或等于给定value的子节点的查询，
  /// 使用给定的orderBy指令或优先级作为默认值，
  /// 并且可选择仅包含key小于或等于给定key的子节点。
  Query endAt(dynamic value, {String key}) {
    assert(!_parameters.containsKey('endAt'));
    assert(value is String || value is bool || value is double || value is int);
    final Map<String, dynamic> parameters = <String, dynamic>{'endAt': value};
    if (key != null) parameters['endAtKey'] = key;
    return _copyWithParameters(parameters);
  }

  /// 创建一个限制为只返回带有`value`和`key`的子节点的查询。
  ///
  /// 如果提供了一个key，最多只有一个这样的子节点，因为名字是唯一的。
  Query equalTo(dynamic value, {String key}) {
    assert(!_parameters.containsKey('equalTo'));
    assert(value is String || value is bool || value is double || value is int);
    return _copyWithParameters(
      <String, dynamic>{'equalTo': value, 'equalToKey': key},
    );
  }

  /// 创建一个有限制的查询并将其锚定到窗口的开头。
  Query limitToFirst(int limit) {
    assert(!_parameters.containsKey('limitToFirst'));
    return _copyWithParameters(<String, dynamic>{'limitToFirst': limit});
  }

  /// 创建一个有限制的查询并将其锚定到窗口的末尾。
  Query limitToLast(int limit) {
    assert(!_parameters.containsKey('limitToLast'));
    return _copyWithParameters(<String, dynamic>{'limitToLast': limit});
  }

  /// 生成按特定子key的value排序的数据视图。
  ///
  /// 预期与[startAt]、[endAt]或[equalTo]组合使用。
  Query orderByChild(String key) {
    assert(key != null);
    assert(!_parameters.containsKey('orderBy'));
    return _copyWithParameters(
      <String, dynamic>{'orderBy': 'child', 'orderByChildKey': key},
    );
  }

  /// 生成按Key排序的数据视图。
  ///
  /// 预期与[startAt]、[endAt]或[equalTo]组合使用。
  Query orderByKey() {
    assert(!_parameters.containsKey('orderBy'));
    return _copyWithParameters(<String, dynamic>{'orderBy': 'key'});
  }

  /// 生成按Value排序的数据视图。
  ///
  /// 预期与[startAt]、[endAt]或[equalTo]组合使用。
  Query orderByValue() {
    assert(!_parameters.containsKey('orderBy'));
    return _copyWithParameters(<String, dynamic>{'orderBy': 'value'});
  }

  /// 生成按Priority排序的数据视图。
  ///
  /// 预期与[startAt]、[endAt]或[equalTo]组合使用。
  Query orderByPriority() {
    assert(!_parameters.containsKey('orderBy'));
    return _copyWithParameters(<String, dynamic>{'orderBy': 'priority'});
  }

  /// 获取对应于此查询的位置的SyncReference。
  SyncReference reference() =>
      new SyncReference._(_database, _pathComponents);

  /// 通过在某个位置调用keepSynced(true)，即使没有为该位置附加任何监听器，
  /// 该位置的数据也将自动下载并保持同步。
  /// 另外，当一个位置被保持同步时，它不会从永久磁盘缓存中被逐出。
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