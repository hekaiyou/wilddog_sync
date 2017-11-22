# Flutter插件一野狗云实时通信

[![pub package](https://img.shields.io/pub/v/wilddog_sync.svg)](https://pub.dartlang.org/packages/wilddog_sync)

使用[野狗实时通信引擎（Wilddog Sync）](https://docs.wilddog.com/sync/Web/index.html)的Flutter插件。野狗实时通信引擎即Sync，可以帮助开发者解决应用的实时通信问题，开发者通过API，即可为应用建立客户端之间的长连接，并实时地双向同步数据。

开发者使用Sync能快速实现三大功能：实时数据通信、实时数据分发以及实时数据存储，以下介绍Sync常见的应用场景。

- 实时聊天：可用于直播或社交应用中的实时聊天，完成消息同步、房间信息存储、在线状态检测等功能。
- 实时协作：适用于多人在线文档协同编辑，资料实时同步、在线问答、需求沟通、项目管理等场景。
- 实时金融：适用金融服务中大量的 Sync 业务、包括股票行情、实盘演示；期货、黄金、债券、证券等金融领域的实时新闻推送。
- 实时定位：结合 GPS 数据，可以应用于外卖配送、物流定位等互动场景；也可应用于打车应用中的司机、乘客实时定位；社交应用中，最常见的场景就是：分享我的位置。

*注意*：此插件还不是很完善，有些功能仍在开发中，如果你发现任何问题，请加入QQ群：271733776【Flutter程序员】，期待你的反馈。

## 安装与配置

打开[野狗云官网](https://www.wilddog.com/)，注册一个野狗云帐号，已有账号的直接登陆。

### 创建一个新Wilddog项目

在Flutter项目上配置Wilddog Sync的第一步是创建一个新的Wilddog项目，在浏览器中打开[Wilddog控制台](https://www.wilddog.com/dashboard)，选择“创建应用”，输入项目名称，然后单击“创建”。

![这里写图片描述](http://img.blog.csdn.net/20171017184950843?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvaGVrYWl5b3U=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast)

Wilddog生成了一个App ID的字符串，这是Wilddog项目唯一ID，用于连接到刚创建的Wilddog服务。复制这个ID字符串值，下面在Android、iOS平台上配置Wilddog时需要用到这个值。

注意，新项目需要*开启实时通信引擎服务*才能正常使用，不然会报无权限异常。

### 将插件添加到应用程序

将以下内容添加到的Flutter项目的`pubspec.yaml`文件中。

```
dependencies:
  wilddog_sync: "^0.0.4"
```

更新并保存此文件后，点击顶部的“Packages Get”，等待下载完成。打开`main.dart`文件，IntelliJ IDEA或其他编辑器可能会在上方显示一个提示，提醒我们重新加载`pubspec.yaml`文件，点击“Get dependencies”以检索其他软件包，并在Flutter项目中使用它们。

开发iOS必须使用macOS，而在macOS中，想要在Flutter应用程序中使用Flutter插件，需要安装[homebrew](https://brew.sh/index_zh-cn.html)，并打开终端运行以下命令来安装CocoaPods。

```
brew install cocoapods
pod setup
```

### 为Android配置Wilddog

启动Android Studio后选择项目的`android`文件夹，打开Flutter项目的Android部分，然后再打开“android/app/src/main/java/<项目名>”文件夹中的`MainActivity.java`文件，将Wilddog的初始化代码添加到文件中。

```
//...
import com.wilddog.wilddogcore.WilddogOptions;
import com.wilddog.wilddogcore.WilddogApp;

public class MainActivity extends FlutterActivity {
  @Override
  protected void onCreate(Bundle savedInstanceState) {
    //...
    WilddogOptions options = new WilddogOptions.Builder().setSyncUrl("https://<前面复制的AppID>.wilddogio.com/").build();
    WilddogApp.initializeApp(this, options);
  }
}
```

注意，如果应用程序编译时出现文件重复导致的编译错误时，可以选择在`android/app/build.gradle`中添加“packagingOptions”。

```
android {
    //...
    packagingOptions {
        exclude 'META-INF/services/com.fasterxml.jackson.core.ObjectCodec'
        exclude 'META-INF/services/com.fasterxml.jackson.core.JsonFactory'
        exclude 'META-INF/maven/com.squareup.okhttp/okhttp/pom.properties'
        exclude 'META-INF/maven/com.fasterxml.jackson.core/jackson-core/pom.xml'
        exclude 'META-INF/maven/com.squareup.okio/okio/pom.properties'
        exclude 'META-INF/maven/com.fasterxml.jackson.core/jackson-databind/pom.xml'
        exclude 'META-INF/maven/com.fasterxml.jackson.core/jackson-databind/pom.properties'
        exclude 'META-INF/maven/com.fasterxml.jackson.core/jackson-core/pom.properties'
        exclude 'META-INF/maven/com.squareup.okio/okio/pom.xml'
        exclude 'META-INF/maven/com.squareup.okhttp/okhttp/pom.xml'
        exclude 'META-INF/maven/com.fasterxml.jackson.core/jackson-annotations/pom.properties'
        exclude 'META-INF/maven/com.fasterxml.jackson.core/jackson-annotations/pom.xml'
        exclude 'META-INF/maven/com.wilddog.client/wilddog-core-android/pom.xml'
        exclude 'META-INF/maven/com.wilddog.client/wilddog-core-android/pom.properties'
        exclude 'META-INF/maven/com.wilddog.client/wilddog-auth-android/pom.xml'
        exclude 'META-INF/maven/com.wilddog.client/wilddog-auth-android/pom.properties'
        exclude 'META-INF/NOTICE'
        exclude 'META-INF/LICENSE'
        exclude 'META-INF/notice'
        exclude 'META-INF/notice.txt'
        exclude 'META-INF/license'
        exclude 'META-INF/license.txt'
    }
}
```

完成配置后，建议先在IntelliJ IDEA中执行一次项目，编译Android应用程序，以确保Flutter项目下载所有依赖文件。

### 为iOS配置Wilddog

在Flutter项目的`ios`目录下，使用Xcode打开“Runner.xcworkspace”文件。然后打开“ios/Runner”文件夹中的`AppDelegate.m`文件，将Wilddog的初始化代码添加到文件中。

```
//...
#import "Wilddog.h"
//...
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  //...
  WDGOptions *option = [[WDGOptions alloc] initWithSyncURL:@"https://<前面复制的AppID>.wilddogio.com/"];
  [WDGApp configureWithOptions:option];
  //...
}
```

完成配置后，建议先在IntelliJ IDEA中执行一次项目，编译iOS应用程序，以确保Flutter项目下载所有依赖文件。

## 使用与入门

要使用Flutter的平台插件，必须在Dart代码中导入对应包，使用以下代码导入`wilddog_sync`包。

```
import 'package:wilddog_sync/wilddog_sync.dart';
```

### 基础概念

Sync的数据以JSON格式存储，它是键值对（Key-Value）的集合，其中每一个键值对（Key-Value）都称之为节点。一个节点包含`key`和`value` ，例如，以下聊天室示例的数据结构中，“name”是key，“username1”是“name”对应的value，它们共同组成一个节点。

![这里写图片描述](http://img.blog.csdn.net/20171017215902340?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvaGVrYWl5b3U=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast)

某个节点下的所有节点，统称为该节点的子节点，例如，聊天室示例中“user1”是“users”的子节点。路径用于标识数据在Sync中存储的位置，根据路径可以访问指定的数据，例如，聊天室示例中“name”的路径是“users/user1/name”。

### 写入数据

使用`WilddogSync.instance.reference()`会获取一个指向根节点的SyncReference实例，`child`方法用来定位到某个子节点。

使用`set`方法可以向指定节点写入数据，此方法会先清空指定节点，再写入数据。通过设置`priority`参数可以节点的优先级，默认值为“0”。

如果子节点的value是列表时，可以使用`push`方法。push方法使用唯一key生成新的子节点并返回一个SyncReference实例，唯一key以客户端生成的时间戳为前缀，以便生成的列表将按时间顺序排序。

```
SyncReference _counterRef = WilddogSync.instance.reference().child('counter');
SyncReference _messagesRef = WilddogSync.instance.reference().child('messages');

_counterRef.set('666');
_messagesRef.push().set(<String, String>{
  'content': 'message1Content',
  'userId': 'user1',
});
```

### 设置优先级

`setPriority()`方法用于设置节点的优先级，每个节点都能设置优先级，用于实现节点按优先级排序。优先级是节点的隐藏属性，默认为“0”。

```
_counterRef.setPriority(100);
```

### 更新数据

`update`方法用于更新指定子节点。

```
_messagesRef.child('messagesID').update({
  'content': 'message2Content',
  'userId': 'user2',
});
```

### 获取数据

使用`once()`方法可以获取当前节点的`DataSnapshot`实例，并通过DataSnapshot查看当前节点的key和value。由于获取数据是异步操作，因此需要导入相关的包并设置方法的返回值为Future类型。

```
// import 'dart:async';
Future<Null> _chestnuts() async {
  DataSnapshot snapshot = await _counterRef.once();
  print('${onValue.key} : ${onValue.value}');
}
```

或者使用Future的抽象方法`then`，注册一个在Future完成时调用的回调。

```
_counterRef.once().then((onValue){
  print('${onValue.key} : ${onValue.value}');
});
```

### 删除数据

`remove`方法用于删除指定节点。

```
_counterRef.remove();
```

### 监听数据

#### 监听节点

`onValue`方法会返回一个监听当前节点值的Stream，再将其添加至`StreamSubscription`实例中。这样每当节点的值发生更改时，应用程序都会收到更改后的值。需要注意的是，在应用程序结束时，要关闭所有的StreamSubscription实例。

```
StreamSubscription<Event> _counterSubscription;

@override
void initState() {
  super.initState();
  _counterSubscription = _counterRef.onValue.listen((Event event) {
    print(event.snapshot.value);
  });
}

@override
void dispose() {
  super.dispose();
  _counterSubscription.cancel();
}
```

#### 监听子节点

监听子节点事件的方法有四种，分别是以下的方法。

- onChildAdded：子节点加入时触发事件。
- onChildRemoved：子节点被移除时触发事件。
- onChildChanged：子节点改变时触发事件。
- onChildMoved：子节点被移动时触发事件。

以`onChildAdded`方法为例，当前节点下添加了一个子节点时，应用程序会立即收到刚刚添加的子节点数据。要注意的是，在这四个方法中，onChildAdded方法会返回所有的子节点数据。

```
StreamSubscription<Event> _messagesSubscription;

@override
void initState() {
  super.initState();
  _messagesSubscription = _messagesRef.onChildAdded.listen((Event event){
    print('子节点增加了: ${event.snapshot.value}');
  });
}

@override
void dispose() {
  super.dispose();
  _messagesSubscription.cancel();
}
```

#### 子节点排序

将监听到的子节点排序有四种方法，分别是以下的方法。

- orderByChild(String key)：生成按特定子key的value排序的数据视图。
- orderByKey()：生成按Key排序的数据视图。
- orderByValue()：生成按Value排序的数据视图。
- orderByPriority()：生成按Priority排序的数据视图。

以`orderByChild(String key)`方法为例，将所有子节点按特定子key的value排序，每当有新的子节点时，都会加入排序。

```
_messagesSubscription = _messagesRef.orderByChild("content").onChildAdded.listen((Event event){
  print('子节点增加了: ${event.snapshot.value}');
});
```

#### 有限的监听

将监听到的子节点排序有两种方法，分别是以下的方法。

- limitToFirst(int limit)：从开头开始有限制的监听子节点。
- limitToLast(int limit)：从末尾（最新的子节点）开始有限制的监听子节点。

以`limitToFirst(int limit)`方法为例，只监听从末尾开始的十个子节点。

```
_messagesSubscription = _messagesRef.limitToLast(10).onChildAdded.listen((Event event) {
  print('子节点增加了: ${event.snapshot.value}');
});
```

### 野狗动画列表

`WilddogAnimatedList`控件是一个绑定到Wilddog查询的滚动容器。在当前查询的节点下插入或移除子节点，会产生动画效果，使用户体验更好。在当前查询的节点下修改子节点，WilddogAnimatedList控件也会实时更新数据。

```
// import 'package:wilddog_sync/ui/wilddog_animated_list.dart';
// import 'dart:async';
new WilddogAnimatedList(
  query: _messagesRef,
  sort: (DataSnapshot a, DataSnapshot b) => b.key.compareTo(a.key),
  itemBuilder: (BuildContext context, DataSnapshot snapshot, Animation<double> animation, int index) {
    return new SizeTransition(
      sizeFactor: animation,
      child: new Text("$index: ${snapshot.value}"),
    );
  },
),
```

| 属性| 说明 | 参数类型|
| ---------- | ---------- | ----------|
| key | 全局密钥 | GlobalKey |
| query | 用于填充列表的Wilddog查询 | SyncReference |
| itemBuilder | 根据需要调用的构建列表项控件 | WilddogAnimatedListItemBuilder |
| sort | 用于在排序列表时比较快照的方法（可选），默认值是按key对快照进行排序 | Comparator< DataSnapshot > |
| defaultChild | 在query加载时显示的控件，默认为空的Container() | Widget |
| scrollDirection | 滚动视图中滚动轴的方向，默认为Axis.vertical | Axis |
| reverse | 滚动视图是否在阅读方向滚动，默认为false，即从左到右滚动、从上到下滚动 | bool |
| controller | 用于控制滚动视图中滚动条位置的控制器对象 | ScrollController |
| primary | 这是否是与父PrimaryScrollController关联的主滚动视图 | bool |
| physics | 滚动视图应如何响应用户输入，默认为匹配平台约定 | ScrollPhysics |
| shrinkWrap | scrollDirection中滚动视图的范围是否应由正在查看的内容确定，默认为false | bool |
| padding |  插入子控件的空间量 | EdgeInsets |
| duration | 插入和删除动画的持续时间，默认为300毫秒 | Duration |

### 数据本地持久化

数据本地持久化是针对移动网络稳定性差而开发的功能。默认情况下，Wilddog Sync的数据存储在内存中，一旦重启，内存数据将被清除。开启数据本地持久化功能，可以使设备重启后无需再同步云端，有助于节省流量和提升重启后的访问速度。

`setPersistenceEnabled(bool enabled)`方法用于设置数据库持久性是否开启。必须在调用数据库引用方法之前设置此属性，并且每个应用程序只需要调用一次。

```
WilddogSync.instance.setPersistenceEnabled(true);
```

Wilddog Sync可以在查询数据前同步指定节点下的数据，并将数据存储到设备中，以此提升访问速度。通过在某个位置调用`keepSynced(true)`，即使没有为该位置附加任何监听器，该位置的数据也将自动下载并保持同步。

```
_counterRef.keepSynced(true);
```
