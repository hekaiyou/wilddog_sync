import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wilddog_sync/wilddog_sync.dart';
import 'package:wilddog_sync/ui/wilddog_animated_list.dart';

void main() {
  runApp(new MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Database Example',
      home: new MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter;
  final SyncReference _counterRef =
  WilddogSync.instance.reference().child('counter');
  final SyncReference _messagesRef =
  WilddogSync.instance.reference().child('messages');
  StreamSubscription<Event> _counterSubscription;
  StreamSubscription<Event> _messagesSubscription;
  bool _anchorToBottom = false;

  String _kTestKey = 'Hello';
  String _kTestValue = 'world!';

  @override
  void initState() {
    super.initState();
    WilddogSync.instance.setPersistenceEnabled(true);
    _counterRef.keepSynced(true);
    _counterSubscription = _counterRef.onValue.listen((Event event) {
      setState(() {
        _counter = event.snapshot.value ?? 0;
      });
    });
    _messagesSubscription =
        _messagesRef.limitToLast(10).onChildAdded.listen((Event event) {
          print('Child added: ${event.snapshot.value}');
        });
  }

  @override
  void dispose() {
    super.dispose();
    _messagesSubscription.cancel();
    _counterSubscription.cancel();
  }

  Future<Null> _increment() async {
    final DataSnapshot snapshot = await _counterRef.once();
    setState(() {
      _counter = (snapshot.value ?? 0) + 1;
    });
    _counterRef.set(_counter);
    _messagesRef
        .push()
        .set(<String, String>{_kTestKey: '$_kTestValue $_counter'});
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: const Text('Flutter Database Example'),
      ),
      body: new Column(
        children: <Widget>[
          new Flexible(
            child: new Center(
              child: new Text(
                'Button tapped $_counter time${ _counter == 1 ? '' : 's' }.\n\n'
                    'This includes all devices, ever.',
              ),
            ),
          ),
          new ListTile(
            leading: new Checkbox(
              onChanged: (bool value) {
                setState(() {
                  _anchorToBottom = value;
                });
              },
              value: _anchorToBottom,
            ),
            title: const Text('Anchor to bottom'),
          ),
          new Flexible(
            child: new WilddogAnimatedList(
              key: new ValueKey<bool>(_anchorToBottom),
              query: _messagesRef,
              reverse: _anchorToBottom,
              sort: _anchorToBottom
                  ? (DataSnapshot a, DataSnapshot b) => b.key.compareTo(a.key)
                  : null,
              itemBuilder: (BuildContext context, DataSnapshot snapshot,
                  Animation<double> animation, int index) {
                return new SizeTransition(
                  sizeFactor: animation,
                  child: new Text("$index: ${snapshot.value.toString()}"),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: new FloatingActionButton(
        onPressed: _increment,
        tooltip: 'Increment',
        child: new Icon(Icons.add),
      ),
    );
  }
}
