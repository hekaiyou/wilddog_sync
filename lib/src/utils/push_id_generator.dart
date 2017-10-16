import 'dart:math';

class PushIdGenerator {
  static const String PUSH_CHARS =
      '-0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz';

  static final Random _random = new Random();

  static int _lastPushTime;

  static final List<int> _lastRandChars = new List<int>(12);

  static String generatePushChildName() {
    int now = new DateTime.now().millisecondsSinceEpoch;
    final bool duplicateTime = (now == _lastPushTime);
    _lastPushTime = now;

    final List<String> timeStampChars = new List<String>(8);
    for (int i = 7; i >= 0; i--) {
      timeStampChars[i] = PUSH_CHARS[now % 64];
      now = (now / 64).floor();
    }
    assert(now == 0);

    final StringBuffer result = new StringBuffer(timeStampChars.join());

    if (!duplicateTime) {
      for (int i = 0; i < 12; i++) {
        _lastRandChars[i] = _random.nextInt(64);
      }
    } else {
      _incrementArray();
    }
    for (int i = 0; i < 12; i++) {
      result.write(PUSH_CHARS[_lastRandChars[i]]);
    }
    assert(result.length == 20);
    return result.toString();
  }

  static void _incrementArray() {
    for (int i = 11; i >= 0; i--) {
      if (_lastRandChars[i] != 63) {
        _lastRandChars[i] = _lastRandChars[i] + 1;
        return;
      }
      _lastRandChars[i] = 0;
    }
  }
}