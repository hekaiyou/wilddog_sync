part of wilddog_sync;

/// 访问WilddogSync的入口点，您可以通过调用"WilddogSync.instance"获取一个实例。
/// 要访问数据库中的位置并读取或写入数据，请使用"reference()"。
class WilddogSync {
  /*
  MethodChannel类是一个使用异步方法调用与平台插件通信的命名通道，
  这里创建一个指定名称为'wilddog_sync'的MethodChannel。
   */
  final MethodChannel _channel = const MethodChannel('wilddog_sync');

  /*
  StreamController类是能控制`stream`的控制器。
  add方法会发送数据事件。
   */
  static final Map<int, StreamController<Event>> _observers =
  <int, StreamController<Event>>{};

  WilddogSync._() {
    /*
    setMethodCallHandler方法在此通道上设置接收方法调用的回调。
    MethodCall类表示调用命名方法的命令对象。
    method属性是要调用的方法的名称。
    arguments属性是该方法的参数，返回的是dynamic(动态)类型数据。
     */
    _channel.setMethodCallHandler((MethodCall call) {
      if (call.method == 'Event') {
        final Event event = new Event._(call.arguments);
        _observers[call.arguments['handle']].add(event);
      }
    });
  }

  static WilddogSync _instance = new WilddogSync._();

  /// 获取默认Wilddog应用程序的WilddogSync实例。
  static WilddogSync get instance => _instance;

  /// 获取WilddogSync根目录的一个SyncReference。
  SyncReference reference() => new SyncReference._(this, <String>[]);

  Future<bool> setPersistenceEnabled(bool enabled) {
    return _channel.invokeMethod(
      'WilddogSync#setPersistenceEnabled',
      enabled,
    );
  }

  Future<Null> goOnline() {
    return _channel.invokeMethod('WilddogSync#goOnline');
  }

  Future<Null> goOffline() {
    return _channel.invokeMethod('WilddogSync#goOffline');
  }
}