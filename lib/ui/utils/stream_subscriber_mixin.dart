import 'dart:async';

abstract class StreamSubscriberMixin<T> {
  List<StreamSubscription<T>> _subscriptions = <StreamSubscription<T>>[];

  void listen(Stream<T> stream, void onData(T data)) {
    if (stream != null) {
      _subscriptions.add(stream.listen(onData));
    }
  }

  void dispose() {
    _subscriptions
        .forEach((StreamSubscription<T> subscription) => subscription.cancel());
  }
}