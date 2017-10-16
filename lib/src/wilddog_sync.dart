part of wilddog_sync;

class WilddogSync {
  final MethodChannel _channel = const MethodChannel('wilddog_sync');

  static final Map<int, StreamController<Event>> _observers =
  <int, StreamController<Event>>{};

  WilddogSync._() {
    _channel.setMethodCallHandler((MethodCall call) {
      if (call.method == 'Event') {
        final Event event = new Event._(call.arguments);
        _observers[call.arguments['handle']].add(event);
      }
    });
  }

  static WilddogSync _instance = new WilddogSync._();

  //获取默认Wilddog应用程序的WilddogSync实例。
  static WilddogSync get instance => _instance;

  //获取WilddogSync根目录的一个SyncReference。
  SyncReference reference() => new SyncReference._(this, <String>[]);

  Future<bool> setPersistenceEnabled(bool enabled) {
    return _channel.invokeMethod(
      'SyncReference#setPersistenceEnabled',
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