#import "WilddogSyncPlugin.h"
#import "Wilddog.h"

@interface NSError (FlutterError)
@property(readonly, nonatomic) FlutterError *flutterError;
@end

@implementation NSError (FlutterError)
- (FlutterError *)flutterError {
  return [FlutterError errorWithCode:[NSString stringWithFormat:@"Error %ld", self.code]
    message:self.domain
    details:self.localizedDescription];
}
@end

// 获取一个WDGSyncReference实例。
WDGSyncReference *getReference(NSDictionary *arguments) {
  NSString *path = arguments[@"path"];
  // 返回根路径的WDGSyncReference实例。
  WDGSyncReference *ref = [WDGSync sync].reference;
  // child用来定位到某个节点。
  if ([path length] > 0) ref = [ref child:path];
  return ref;
}

WDGSyncQuery *getQuery(NSDictionary *arguments) {
  // WDGSyncQuery：查询指定位置和指定条件下的数据。
  WDGSyncQuery *query = getReference(arguments);
  NSDictionary *parameters = arguments[@"parameters"];
  NSString *orderBy = parameters[@"orderBy"];
  if ([orderBy isEqualToString:@"child"]) {
    query = [query queryOrderedByChild:parameters[@"orderByChildKey"]];
  } else if ([orderBy isEqualToString:@"key"]) {
    query = [query queryOrderedByKey];
  } else if ([orderBy isEqualToString:@"value"]) {
    query = [query queryOrderedByValue];
  } else if ([orderBy isEqualToString:@"priority"]) {
    query = [query queryOrderedByPriority];
  }
  id startAt = parameters[@"startAt"];
  if (startAt) {
    id startAtKey = parameters[@"startAtKey"];
    if (startAtKey) {
      query = [query queryStartingAtValue:startAt childKey:startAtKey];
    } else {
      query = [query queryStartingAtValue:startAt];
    }
  }
  id endAt = parameters[@"endAt"];
  if (endAt) {
    id endAtKey = parameters[@"endAtKey"];
    if (endAtKey) {
      query = [query queryEndingAtValue:endAt childKey:endAtKey];
    } else {
      query = [query queryEndingAtValue:endAt];
    }
  }
  id equalTo = parameters[@"equalTo"];
  if (equalTo) {
    query = [query queryEqualToValue:equalTo];
  }
  NSNumber *limitToFirst = parameters[@"limitToFirst"];
  if (limitToFirst) {
    query = [query queryLimitedToFirst:limitToFirst.intValue];
  }
  NSNumber *limitToLast = parameters[@"limitToLast"];
  if (limitToLast) {
    query = [query queryLimitedToLast:limitToLast.intValue];
  }
  return query;
}

WDGDataEventType parseEventType(NSString *eventTypeString) {
  if ([@"_EventType.childAdded" isEqual:eventTypeString]) {
    return WDGDataEventTypeChildAdded;
  } else if ([@"_EventType.childRemoved" isEqual:eventTypeString]) {
    return WDGDataEventTypeChildRemoved;
  } else if ([@"_EventType.childChanged" isEqual:eventTypeString]) {
    return WDGDataEventTypeChildChanged;
  } else if ([@"_EventType.childMoved" isEqual:eventTypeString]) {
    return WDGDataEventTypeChildMoved;
  } else if ([@"_EventType.value" isEqual:eventTypeString]) {
    return WDGDataEventTypeValue;
  }
  assert(false);
  return 0;
}

id roundDoubles(id value) {
  //当存储int时，Wilddog iOS SDK有时会返回双精度，我们检测到可以转换为int的双精度，而不会损失精度并进行转换。
  if ([value isKindOfClass:[NSNumber class]]) {
    CFNumberType type = CFNumberGetType((CFNumberRef)value);
    if (type == kCFNumberDoubleType || type == kCFNumberFloatType) {
      if ((double)(long long)[value doubleValue] == [value doubleValue]) {
        return [NSNumber numberWithLongLong:(long long)[value doubleValue]];
      }
    }
  } else if ([value isKindOfClass:[NSArray class]]) {
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:[value count]];
    [value enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      [result addObject:roundDoubles(obj)];
    }];
    return result;
  } else if ([value isKindOfClass:[NSDictionary class]]) {
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:[value count]];
    [value enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
      result[key] = roundDoubles(obj);
    }];
    return result;
  }
  return value;
}

@interface WilddogSyncPlugin ()
@property(nonatomic, retain) FlutterMethodChannel *channel;
@end

@implementation WilddogSyncPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
                                  methodChannelWithName:@"wilddog_sync"
                                  binaryMessenger:[registrar messenger]];
  WilddogSyncPlugin* instance = [[WilddogSyncPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
  instance.channel = channel;
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (instancetype)init {
  self = [super init];
  if (self) {
    if (![WDGApp defaultApp]) {
      [WDGApp defaultApp];
    }
  }
  return self;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  void (^defaultCompletionBlock)(NSError *, WDGSyncReference *) =
  ^(NSError *error, WDGSyncReference *ref) {
    result(error.flutterError);
  };
  if ([@"WilddogSync#goOnline" isEqualToString:call.method]) {
    [[WDGSync sync] goOnline];
    result(nil);
  } else if ([@"WilddogSync#goOffline" isEqualToString:call.method]) {
    [[WDGSync sync] goOffline];
    result(nil);
  } else if ([@"WilddogSync#setPersistenceEnabled" isEqualToString:call.method]) {
    NSNumber *value = call.arguments;
    @try {
      [WDGSync sync].persistenceEnabled = value.boolValue;
      result([NSNumber numberWithBool:YES]);
    } @catch (NSException *exception) {
      if ([@"WDGSyncAlreadyInUse" isEqualToString:exception.name]) {
        //当数据库已经在使用，比如在热重启或重启后
        result([NSNumber numberWithBool:NO]);
      } else {
        @throw;
      }
    }
  } else if ([@"SyncReference#set" isEqualToString:call.method]) {
    // setValue在WDGSyncReference当前路径写入一个值，这会覆盖当前路径和子路径的所有数据。
    // andPriority在写入数据的同时为当前节点设置优先值，优先值被用来排序。
    // 优先值只能是NSNumber和NSString类型，默认值为nil
    [getReference(call.arguments) setValue:call.arguments[@"value"]
                                  andPriority: call.arguments[@"priority"]
                                  withCompletionBlock:defaultCompletionBlock];
  } else if ([@"SyncReference#update" isEqualToString:call.method]) {
    // updateChildValues方法用于更新指定子节点。
    [getReference(call.arguments) updateChildValues:call.arguments[@"value"]
                                  withCompletionBlock:defaultCompletionBlock];
  } else if ([@"SyncReference#setPriority" isEqualToString:call.method]) {
    // setPriority:方法用于设置节点的优先级，优先级是节点的隐藏属性，默认为null。
    [getReference(call.arguments) setPriority:call.arguments[@"priority"]
                                  withCompletionBlock:defaultCompletionBlock];
  } else if ([@"Query#observe" isEqualToString:call.method]) {
    //andPreviousSiblingKeyWithBlock：监听指定节点的数据，这是从WilddogSync云端监听数据的主要方式。
    //当监听到当前节点的初始数据或当前节点的数据发生改变时，将会触发指定事件对应的回调block。
    WDGDataEventType eventType = parseEventType(call.arguments[@"eventType"]);
    __block WDGSyncHandle handle = [getQuery(call.arguments) observeEventType:eventType
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
  } else if ([@"Query#removeObserver" isEqualToString:call.method]) {
    WDGSyncHandle handle = [call.arguments[@"handle"] unsignedIntegerValue];
    [getQuery(call.arguments) removeObserverWithHandle:handle];
    result(nil);
  } else if ([@"Query#keepSynced" isEqualToString:call.method]) {
    NSNumber *value = call.arguments[@"value"];
    //通过在一个节点处通过调用keepSynced:YES方法，即使该节点处没有进行过监听，此节点的数据也将自动下载存储并与云端保持同步
    [getQuery(call.arguments) keepSynced:value.boolValue];
    result(nil);
  } else {
    result(FlutterMethodNotImplemented);
  }
}

@end
