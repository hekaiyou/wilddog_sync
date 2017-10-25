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

  /// 尝试将数据库持久性设置为[enabled]。
  ///
  /// 必须在调用数据库引用方法之前设置此属性，并且每个应用程序只需要调用一次。
  /// 如果操作成功，则返回的[Future]将以`true`完成，
  /// 如果不能设置持久性（因为已创建数据库引用），则返回`false`。
  ///
  /// WilddogSync客户端将缓存同步的数据，并跟踪您在应用程序运行时发起的所有写入。
  /// 当网络连接恢复时，它可以无缝地处理间歇性网络连接并重新发送写入操作。
  ///
  /// 但是，默认情况下，您的写入操作和缓存数据仅存储在内存中，并在应用程序重新启动时丢失。
  /// 通过将[enabled]设置为`true`，数据将被持久保存到设备（磁盘）存储中，
  /// 并在应用重新启动时再次可用（即使当时没有网络连接）。
  Future<bool> setPersistenceEnabled(bool enabled) {
    return _channel.invokeMethod(
      'WilddogSync#setPersistenceEnabled',
      enabled,
    );
  }

  /// 在以前的[goOffline]调用之后，恢复与WilddogSync后端的连接。
  Future<Null> goOnline() {
    return _channel.invokeMethod('WilddogSync#goOnline');
  }

  /// 关闭与WilddogSync后端的连接，直到[goOnline]被调用。
  Future<Null> goOffline() {
    return _channel.invokeMethod('WilddogSync#goOffline');
  }
}