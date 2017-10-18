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

### 将插件添加到应用程序

将以下内容添加到的Flutter项目的`pubspec.yaml`文件中：

```
dependencies:
  wilddog_sync: "^0.0.1"
```

更新并保存此文件后，点击顶部的“Packages Get”，等待下载完成。打开`main.dart`文件，IntelliJ IDEA或其他编辑器可能会在上方显示一个提示，提醒我们重新加载`pubspec.yaml`文件，点击“Get dependencies”以检索其他软件包，并在Flutter项目中使用它们。

开发iOS必须使用macOS，而在macOS中，想要在Flutter应用程序中使用Flutter插件，需要安装[homebrew](https://brew.sh/index_zh-cn.html)，并打开终端运行以下命令来安装CocoaPods：

```
brew install cocoapods
pod setup
```

### 为Android配置Wilddog

启动Android Studio后选择项目的`android`文件夹，打开Flutter项目的Android部分，然后再打开`android/app/src/main/java/<项目名>`文件夹中的`MainActivity.java`文件，将Wilddog的初始化代码添加到文件中：

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

注意，如果应用程序编译时出现文件重复导致的编译错误时，可以选择在`android/app/build.gradle`中添加`packagingOptions`：

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

在Flutter项目的`ios`目录下，使用Xcode打开`Runner.xcworkspace`文件。然后打开`ios/Runner`文件夹中的`AppDelegate.m`文件，将Wilddog的初始化代码添加到文件中：

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

要使用Flutter的平台插件，必须在Dart代码中导入对应包，使用以下代码导入`wilddog_sync`包：

```
import 'package:wilddog_sync/wilddog_sync.dart';
```

### 基础概念

Sync的数据以JSON格式存储，它是键值对（Key-Value）的集合，其中每一个键值对（Key-Value）都称之为节点。一个节点包含`key`和`value` ，例如，以下聊天室示例的数据结构中，“name”是`key`，“username1”是“name”对应的`value`，它们共同组成一个节点。

![这里写图片描述](http://img.blog.csdn.net/20171017215902340?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvaGVrYWl5b3U=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast)

某个节点下的所有节点，统称为该节点的子节点，例如，聊天室示例中“user1”是“users”的子节点。路径用于标识数据在Sync中存储的位置，根据路径可以访问指定的数据，例如，聊天室示例中“name”的路径是“users/user1/name”。

### 写入数据

使用`WilddogSync.instance.reference()`会获取一个指向根节点的`SyncReference`实例，`child`用来定位到某个子节点（），

```
SyncReference _counterRef = WilddogSync.instance.reference().child('counter');
SyncReference _messagesRef = WilddogSync.instance.reference().child('messages');

_counterRef.set('666');
_messagesRef.push().set(<String, String>{
  'content': 'message1Content',
  'userId': 'user1',
});
```