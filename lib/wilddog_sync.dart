import 'dart:async';

import 'package:flutter/services.dart';

class WilddogSync {
  static const MethodChannel _channel =
      const MethodChannel('wilddog_sync');

  static Future<String> get platformVersion =>
      _channel.invokeMethod('getPlatformVersion');
}
