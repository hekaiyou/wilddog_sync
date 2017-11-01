#import "WilddogSyncPlugin.h"
#import "Wilddog.h"

// 声明NSError类
@interface NSError (FlutterError)
// 声明一个FlutterError类型的对象
// 使用readonly时表示编译器会自动生成getter方法，同时不会生成setter方法
// 原子性的控制使用nanatomic，不进行监控，线程不安全的
@property(readonly, nonatomic) FlutterError *flutterError;
// 类的声明已结束
@end

// 实现WilddogSyncPlugin类
@implementation NSError (FlutterError)
- (FlutterError *)flutterError {
  return [FlutterError errorWithCode:[NSString stringWithFormat:@"Error %ld", self.code]
    message:self.domain
    details:self.localizedDescription];
}
// 类的实现已结束
@end

// 获取一个WDGSyncReference实例
// 参数arguments是从客户端传递的调用参数
WDGSyncReference *getReference(NSDictionary *arguments) {
  // 声明定义节点路径变量，并获取调用参数中的节点路径
  NSString *path = arguments[@"path"];
  // 返回根路径的WDGSyncReference实例
  WDGSyncReference *ref = [WDGSync sync].reference;
  // 节点路径变量的长度是否大于0
  // child用来定位到某个节点
  if ([path length] > 0) ref = [ref child:path];
  // 返回WDGSyncReference实例
  return ref;
}

// 获取查询的方法
// 参数arguments是从客户端传递的调用参数
WDGSyncQuery *getQuery(NSDictionary *arguments) {
  // WDGSyncQuery类，查询指定位置和指定条件下的数据
  // 声明定义WDGSyncQuery变量，并获取WDGSyncReference实例
  WDGSyncQuery *query = getReference(arguments);
  // 声明定义参数词典，并获取调用参数中的参数词典
  NSDictionary *parameters = arguments[@"parameters"];
  // 声明定义排序依据变量，并获取调用参数中的排序依据
  NSString *orderBy = parameters[@"orderBy"];
  // 指定字符串是否与排序依据变量一样
  if ([orderBy isEqualToString:@"child"]) {
    // queryOrderedByChild方法用于按子节点的指定值（value）对结果排序
    query = [query queryOrderedByChild:parameters[@"orderByChildKey"]];
  } else if ([orderBy isEqualToString:@"key"]) {
    // queryOrderedByKey方法用于按节点的键（key）对结果排序
    query = [query queryOrderedByKey];
  } else if ([orderBy isEqualToString:@"value"]) {
    // queryOrderedByValue方法，可以按照子节点的值进行排序
    query = [query queryOrderedByValue];
  } else if ([orderBy isEqualToString:@"priority"]) {
    // queryOrderedByPriority方法用于根据子节点的优先级（priority）进行排序
    query = [query queryOrderedByPriority];
  }
  // id是一种通用的对象类型，它可以指向属于任何类的对象，也可以理解为万能指针
  // 声明定义startAt变量，并获取调用参数中的startAt
  id startAt = parameters[@"startAt"];
  // startAt变量是否为真，即有值
  if (startAt) {
    // 声明定义startAtKey变量，并获取调用参数中的startAtKey
    id startAtKey = parameters[@"startAtKey"];
    // startAtKey变量是否为真，即有值
    if (startAtKey) {
      // queryStartingAtValue方法返回大于或等于指定的key、value或priority的节点
      // 具体取决于所选的排序方法
      query = [query queryStartingAtValue:startAt childKey:startAtKey];
    } else {
      // 不传childKey参数的queryStartingAtValue方法
      query = [query queryStartingAtValue:startAt];
    }
  }
  // 声明定义endAt变量，并获取调用参数中的endAt
  id endAt = parameters[@"endAt"];
  // endAt变量是否为真，即有值
  if (endAt) {
    // 声明定义endAtKey变量，并获取调用参数中的endAtKey
    id endAtKey = parameters[@"endAtKey"];
    // endAtKey变量是否为真，即有值
    if (endAtKey) {
      // queryEndingAtValue方法返回小于或等于指定的key、value或priority的节点
      // 具体取决于所选的排序方法
      query = [query queryEndingAtValue:endAt childKey:endAtKey];
    } else {
      // 不传childKey参数的queryEndingAtValue方法
      query = [query queryEndingAtValue:endAt];
    }
  }
  // 声明定义equalTo变量，并获取调用参数中的equalTo
  id equalTo = parameters[@"equalTo"];
  // equalTo变量是否为真，即有值
  if (equalTo) {
    // queryEqualToValue方法返回等于指定的key、value或priority的节点
    // 具体取决于所选的排序方法，可用于精确查询
    query = [query queryEqualToValue:equalTo];
  }
  // 声明定义limitToFirst变量，并获取调用参数中的limitToFirst
  NSNumber *limitToFirst = parameters[@"limitToFirst"];
  // limitToFirst变量是否为真，即有值
  if (limitToFirst) {
    // queryLimitedToFirst方法设置从第一条开始，一共返回多少个节点
    query = [query queryLimitedToFirst:limitToFirst.intValue];
  }
  // 声明定义limitToLast变量，并获取调用参数中的limitToLast
  NSNumber *limitToLast = parameters[@"limitToLast"];
  // limitToLast变量是否为真，即有值
  if (limitToLast) {
    // queryLimitedToLast方法设置从最后一条开始，一共返回多少个节点
    // 返回结果仍是升序，降序要自己处理
    query = [query queryLimitedToLast:limitToLast.intValue];
  }
  // 返回query变量
  return query;
}

// 把Flutter事件类型解析为iOS平台事件类型
WDGDataEventType parseEventType(NSString *eventTypeString) {
  // 指定字符串是否为当前Flutter事件类型
  if ([@"_EventType.childAdded" isEqual:eventTypeString]) {
    // 返回初始化监听或有新增子节点的事件类型
    return WDGDataEventTypeChildAdded;
  } else if ([@"_EventType.childRemoved" isEqual:eventTypeString]) {
    // 返回子节点被移除的事件类型
    return WDGDataEventTypeChildRemoved;
  } else if ([@"_EventType.childChanged" isEqual:eventTypeString]) {
    // 返回子节点数据发生更改的事件类型
    return WDGDataEventTypeChildChanged;
  } else if ([@"_EventType.childMoved" isEqual:eventTypeString]) {
    // 返回子节点排序发生变化的事件类型
    return WDGDataEventTypeChildMoved;
  } else if ([@"_EventType.value" isEqual:eventTypeString]) {
    // 返回初始化监听或指定节点及子节点数据发生变化的事件类型
    return WDGDataEventTypeValue;
  }
  assert(false);
  return 0;
}

// 当存储int时，Wilddog的iosSDK有时会返回双精度
// 我们检测到可以转换为int的双精度，而不会损失精度并进行转换
id roundDoubles(id value) {
  // 测试value是不是NSNumber的实例或者其子类的实例
  if ([value isKindOfClass:[NSNumber class]]) {
    // CF是在MAC、iOS里的C程序的接口，也是混合的低端常规和修饰函数集合
    CFNumberType type = CFNumberGetType((CFNumberRef)value);
    // type是Double型或是Float型数据
    if (type == kCFNumberDoubleType || type == kCFNumberFloatType) {
      if ((double)(long long)[value doubleValue] == [value doubleValue]) {
        return [NSNumber numberWithLongLong:(long long)[value doubleValue]];
      }
    }
  // 测试value是不是NSArray的实例或者其子类的实例
  } else if ([value isKindOfClass:[NSArray class]]) {
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:[value count]];
    [value enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      [result addObject:roundDoubles(obj)];
    }];
    return result;
  // 测试value是不是NSDictionary的实例或者其子类的实例
  } else if ([value isKindOfClass:[NSDictionary class]]) {
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:[value count]];
    [value enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
      result[key] = roundDoubles(obj);
    }];
    return result;
  }
  return value;
}

// 声明WilddogSyncPlugin类
@interface WilddogSyncPlugin ()
// 声明一个FlutterMethodChannel类型的对像
// 原子性的控制使用nanatomic，不进行监控，线程不安全的
// 语义设置为retain，常用于对象类型（如自定义类）、数组NSArray
@property(nonatomic, retain) FlutterMethodChannel *channel;
// 类的声明已结束
@end

// 实现WilddogSyncPlugin类
@implementation WilddogSyncPlugin

// 注册iOS方法通道
// registrar是客户端传递的通道注册信息
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  // 定义FlutterMethodChannel对像实例
  FlutterMethodChannel* channel = [FlutterMethodChannel
                                  methodChannelWithName:@"wilddog_sync"
                                  binaryMessenger:[registrar messenger]];
  // 初始化WilddogSyncPlugin对象实例
  //
  // alloc方法会返回一个未被初始化的对象实例
  //
  // init负责初始化对象，这意味着此时此对象处于可用状态
  // 即对象的实例变量可以被赋予合理有效值
  WilddogSyncPlugin* instance = [[WilddogSyncPlugin alloc] init];
  // 设置WilddogSyncPlugin对象实例的通道为channel对象实例
  instance.channel = channel;
  // addMethodCallDelegate的值为WilddogSyncPlugin对像实例
  // channel表示通道，值为FlutterMethodChannel对像实例
  [registrar addMethodCallDelegate:instance channel:channel];
}

// 重写对象的init方法
- (instancetype)init {
  // 调用父类的初始化方法
  self = [super init];
  // 初始化是否成功
  if (self) {
    // defaultApp方法返回默认的WDGApp实例，即通过configureWithOptions:配置的实例
    // 如果默认app不存在，则返回nil，这个方法是线程安全的
    if (![WDGApp defaultApp]) {
      // 返回默认的WDGApp实例
      [WDGApp defaultApp];
    }
  }
  // 即self不为nil的情况下，就可以开始做子类的初始化
  return self;
}

// 接受客户端参数并调用方法
// call为客户端传递的调用参数，result为返回客户端的结果
- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  // 默认完成块
  void (^defaultCompletionBlock)(NSError *, WDGSyncReference *) =
  // 参数为NSError与WDGSyncReference实例
  ^(NSError *error, WDGSyncReference *ref) {
    // 返回error.flutterError，即Flutter错误信息
    result(error.flutterError);
  };
  // 手动建立WilddogSync连接
  if ([@"WilddogSync#goOnline" isEqualToString:call.method]) {
    // goOnline方法用于手动建立连接
    [[WDGSync sync] goOnline];
    result(nil);
  // 手动断开WilddogSync连接
  } else if ([@"WilddogSync#goOffline" isEqualToString:call.method]) {
    // goOffline方法用于手动断开连接
    [[WDGSync sync] goOffline];
    result(nil);
  // 设置启用持久性
  } else if ([@"WilddogSync#setPersistenceEnabled" isEqualToString:call.method]) {
    // 声明定义是否启用变量，并获取调用参数中的是否启用
    NSNumber *value = call.arguments;
    @try {
      // persistenceEnabled方法用于开启数据持久化
      [WDGSync sync].persistenceEnabled = value.boolValue;
      // 返回true给客户端
      result([NSNumber numberWithBool:YES]);
    } @catch (NSException *exception) {
      // 指定字符串是否为当前错误名称
      if ([@"WDGSyncAlreadyInUse" isEqualToString:exception.name]) {
        // 当数据库已经在使用，比如在热重启或重启后
        // 返回false给客户端
        result([NSNumber numberWithBool:NO]);
      } else {
        @throw;
      }
    }
  // 设置节点的值
  } else if ([@"SyncReference#set" isEqualToString:call.method]) {
    // setValue在WDGSyncReference当前路径写入一个值，这会覆盖当前路径和子路径的所有数据
    // andPriority在写入数据的同时为当前节点设置优先值，优先值被用来排序
    // 优先值只能是NSNumber和NSString类型，默认值为nil
    [getReference(call.arguments) setValue:call.arguments[@"value"]
                                  andPriority: call.arguments[@"priority"]
                                  withCompletionBlock:defaultCompletionBlock];
  // 更新节点的值
  } else if ([@"SyncReference#update" isEqualToString:call.method]) {
    // updateChildValues方法用于更新指定子节点。
    [getReference(call.arguments) updateChildValues:call.arguments[@"value"]
                                  withCompletionBlock:defaultCompletionBlock];
  // 设置节点优先级
  } else if ([@"SyncReference#setPriority" isEqualToString:call.method]) {
    // setPriority方法用于设置节点的优先级，优先级是节点的隐藏属性，默认为null
    [getReference(call.arguments) setPriority:call.arguments[@"priority"]
                                  withCompletionBlock:defaultCompletionBlock];
  // 添加事件监听实例
  } else if ([@"Query#observe" isEqualToString:call.method]) {
    // 声明定义iOS平台事件类型变量，并把Flutter事件类型解析为iOS平台事件类型
    WDGDataEventType eventType = parseEventType(call.arguments[@"eventType"]);
    // observeEventType:andPreviousSiblingKeyWithBlock:
    // 监听指定节点的数据，这是从WilddogSync云端监听数据的主要方式
    // 当监听到当前节点的初始数据或当前节点的数据发生改变时
    // 将会触发指定事件对应的回调block
    __block WDGSyncHandle handle = [getQuery(call.arguments) observeEventType:eventType
      // eventType参数为WDGDataEventType 类型，表示监听的事件类型
      //
      // block参数为当监听到当前节点的初始数据或当前节点的数据改变时
      // 将会触发指定事件对应的回调block
      // block将传输一个WDGDataSnapshot类型的数据和前一个节点的key值
      andPreviousSiblingKeyWithBlock:^(WDGDataSnapshot *snapshot, NSString *previousSiblingKey) {
        [self.channel invokeMethod:@"Event" arguments:@{
          @"handle" : [NSNumber numberWithUnsignedInteger:handle],
          @"snapshot" : @{
            @"key" : snapshot.key ?: [NSNull null],
            @"value" : roundDoubles(snapshot.value) ?: [NSNull null],
          },
          @"previousSiblingKey" : previousSiblingKey ?: [NSNull null],
        }];
      }];
    result([NSNumber numberWithUnsignedInteger:handle]);
  // 移除事件监听实例
  } else if ([@"Query#removeObserver" isEqualToString:call.method]) {
    // 声明定义WDGSyncHandle变量，并获取调用参数中的WDGSyncHandle
    WDGSyncHandle handle = [call.arguments[@"handle"] unsignedIntegerValue];
    // 调用WDGSyncHandle值的方法removeObserverWithHandle:移除这个监听
    [getQuery(call.arguments) removeObserverWithHandle:handle];
    result(nil);
  // 设置提前同步
  } else if ([@"Query#keepSynced" isEqualToString:call.method]) {
    // 声明定义值变量，并获取调用参数中的值
    NSNumber *value = call.arguments[@"value"];
    // 通过在一个节点处通过调用keepSynced:YES方法，即使该节点处没有进行过监听
    // 此节点的数据也将自动下载存储并与云端保持同步
    [getQuery(call.arguments) keepSynced:value.boolValue];
    result(nil);
  // 未实现的方法
  } else {
    // 返回未实现方法的提示
    result(FlutterMethodNotImplemented);
  }
}

// 类的实现已结束
@end
