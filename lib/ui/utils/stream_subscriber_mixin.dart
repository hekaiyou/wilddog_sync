import 'dart:async';

abstract class StreamSubscriberMixin<T> {
  // 抽象类StreamSubscription<T>表示来自Stream的事件的订阅。
  List<StreamSubscription<T>> _subscriptions = <StreamSubscription<T>>[];

  void listen(Stream<T> stream, void onData(T data)) {
    if (stream != null) {
      /*
      List的add方法将值添加到此列表的末尾，将长度延长一个。

      listen方法向此流添加订阅。返回一个StreamSubscription，
      它使用提供的onData、onError和onDone处理程序处理流中的事件。
      处理程序可以在订阅上更改，但是它们作为提供的功能开始。
       */
      _subscriptions.add(stream.listen(onData));
    }
  }

  void dispose() {
    _subscriptions
        .forEach((StreamSubscription<T> subscription) => subscription.cancel());
  }
}