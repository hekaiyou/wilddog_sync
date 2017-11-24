package com.hekaiyou.wilddogsync;

import android.util.SparseArray;
import com.wilddog.client.ChildEventListener;
import com.wilddog.client.DataSnapshot;
import com.wilddog.client.SyncError;
import com.wilddog.client.SyncReference;
import com.wilddog.client.WilddogSync;
import com.wilddog.client.Query;
import com.wilddog.client.ValueEventListener;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.PluginRegistry;
import java.util.HashMap;
import java.util.Map;

public class WilddogSyncPlugin implements MethodCallHandler {
  // 声明私有、不可变的方法通道
  private final MethodChannel channel;
  /**
   * 私有、静态、不可变的字符串
   * EVENT_TYPE_CHILD_ADDED：初始化监听或有新增子节点事件
   * EVENT_TYPE_CHILD_REMOVED：子节点被删除事件
   * EVENT_TYPE_CHILD_CHANGED：子节点数据发生更改事件
   * EVENT_TYPE_CHILD_MOVED：子节点排序发生变化事件
   * EVENT_TYPE_VALUE：初始化监听或向指定节点及子节点数据发生变化事件
   */
  private static final String EVENT_TYPE_CHILD_ADDED = "_EventType.childAdded";
  private static final String EVENT_TYPE_CHILD_REMOVED = "_EventType.childRemoved";
  private static final String EVENT_TYPE_CHILD_CHANGED = "_EventType.childChanged";
  private static final String EVENT_TYPE_CHILD_MOVED = "_EventType.childMoved";
  private static final String EVENT_TYPE_VALUE = "_EventType.value";

  // 声明定义私有的下一个句柄编号变量
  private int nextHandle = 0;
  // 声明私有、不可变的事件监听SparseArray
  private final SparseArray<EventObserver> observers = new SparseArray<>();

  /**
   * 注册Android方法通道
   * @param registrar 客户端传递的通道注册信息
   */
  public static void registerWith(PluginRegistry.Registrar registrar) {
    // 声明定义不可变的方法通道实例
    final MethodChannel channel =
            new MethodChannel(registrar.messenger(), "wilddog_sync");
    // 设置方法通道实例的方法调用处理程序
    channel.setMethodCallHandler(new WilddogSyncPlugin(channel));
  }

  /**
   * 方法通道的方法调用处理程序
   * @param channel 局部的方法通道实例
   */
  private WilddogSyncPlugin(MethodChannel channel) {
    // 将局部方法通道赋予全局方法通道
    this.channel = channel;
  }

  /**
   * 获取SyncReference实例
   * @param arguments 从客户端传递的调用参数
   * @return SyncReference实例
   */
  private SyncReference getReference(Map<String, Object> arguments) {
  	// 声明定义节点路径变量，并获取调用参数中的节点路径
    String path = (String) arguments.get("path");
    // 获取SyncReference实例
    SyncReference reference = WilddogSync.getInstance().getReference();
    // child()用来定位到某个节点
    if (path != null) reference = reference.child(path);
    // 返回SyncReference实例
    return reference;
  }

  /**
   * 获取查询的方法
   * @param arguments 参数Map
   */
  private Query getQuery(Map<String, Object> arguments) {
  	// 声明定义Query变量，并获取SyncReference实例
    Query query = getReference(arguments);
    // 屏蔽警告信息，使用过期的方法或所给的参数类型不对
    @SuppressWarnings("unchecked")
    // 声明定义参数Map，并获取调用参数中的参数Map
    Map<String, Object> parameters = (Map<String, Object>) arguments.get("parameters");
    // 如果参数Map为null，则直接返回query变量
    if (parameters == null) return query;
    // 声明定义排序依据变量，并获取调用参数中的排序依据
    Object orderBy = parameters.get("orderBy");
    // 指定字符串是否与排序依据变量一样
    if ("child".equals(orderBy)) {
      // orderByChild()方法用于按子节点的指定值（value）对结果排序
      query = query.orderByChild((String) parameters.get("orderByChildKey"));
    } else if ("key".equals(orderBy)) {
      // orderByKey()方法用于按节点的键（key）对结果排序
      query = query.orderByKey();
    } else if ("value".equals(orderBy)) {
      // orderByValue()方法用于按节点的值（value）对结果排序
      query = query.orderByValue();
    } else if ("priority".equals(orderBy)) {
      // orderByPriority()方法用于按节点的优先级（priority）对结果排序
      query = query.orderByPriority();
    }
    // 参数Map中是否包含一个startAt的key
    if (parameters.containsKey("startAt")) {
      // 声明定义startAt变量，并获取调用参数中的startAt
      Object startAt = parameters.get("startAt");
      //  参数Map中是否包含一个startAtKey的key
      if (parameters.containsKey("startAtKey")) {
      	// 声明定义startAtKey变量，并获取调用参数中的startAtKey
        String startAtKey = (String) parameters.get("startAtKey");
        // startAt变量是Boolean、String还是Number类型
        if (startAt instanceof Boolean) {
          /**
      	   * startAt()方法返回大于或等于指定的key、value或priority的节点
      	   * 具体取决于所选的排序方法
      	   */
          query = query.startAt((Boolean) startAt, startAtKey);
        } else if (startAt instanceof String) {
          query = query.startAt((String) startAt, startAtKey);
        } else {
          query = query.startAt(((Number) startAt).doubleValue(), startAtKey);
        }
      } else {
      	// startAt变量是Boolean、String还是Number类型
        if (startAt instanceof Boolean) {
          /**
      	   * startAt()方法返回大于或等于指定的key、value或priority的节点
      	   * 具体取决于所选的排序方法
      	   */
          query = query.startAt((Boolean) startAt);
        } else if (startAt instanceof String) {
          query = query.startAt((String) startAt);
        } else {
          query = query.startAt(((Number) startAt).doubleValue());
        }
      }
    }
    // 参数Map中是否包含一个endAt的key
    if (parameters.containsKey("endAt")) {
      // 声明定义endAt变量，并获取调用参数中的endAt
      Object endAt = parameters.get("endAt");
      // 参数Map中是否包含一个endAtKey的key
      if (parameters.containsKey("endAtKey")) {
      	// 声明定义endAtKey变量，并获取调用参数中的endAtKey
        String endAtKey = (String) parameters.get("endAtKey");
        // endAt变量是Boolean、String还是Number类型
        if (endAt instanceof Boolean) {
          /**
      	   * endAt()方法返回小于或等于指定的key、value或priority的节点
      	   * 具体取决于所选的排序方法
      	   */
          query = query.endAt((Boolean) endAt, endAtKey);
        } else if (endAt instanceof String) {
          query = query.endAt((String) endAt, endAtKey);
        } else {
          query = query.endAt(((Number) endAt).doubleValue(), endAtKey);
        }
      } else {
      	// endAt变量是Boolean、String还是Number类型
        if (endAt instanceof Boolean) {
          /**
      	   * endAt()方法返回小于或等于指定的key、value或priority的节点
      	   * 具体取决于所选的排序方法
      	   */
          query = query.endAt((Boolean) endAt);
        } else if (endAt instanceof String) {
          query = query.endAt((String) endAt);
        } else {
          query = query.endAt(((Number) endAt).doubleValue());
        }
      }
    }
    // 参数Map中是否包含一个equalTo的key
    if (parameters.containsKey("equalTo")) {
      // 声明定义equalTo变量，并获取调用参数中的equalTo
      Object equalTo = parameters.get("equalTo");
      // equalTo变量是Boolean、String还是Number类型
      if (equalTo instanceof Boolean) {
      	/**
      	 * equalTo()方法返回等于指定的key、value或priority的节点
      	 * 具体取决于所选的排序方法，可用于精确查询
      	 */
        query = query.equalTo((Boolean) equalTo);
      } else if (equalTo instanceof String) {
        query = query.equalTo((String) equalTo);
      } else {
        query = query.equalTo(((Number) equalTo).doubleValue());
      }
    }
    // 参数Map中是否包含一个limitToFirst的key
    if (parameters.containsKey("limitToFirst")) {
      /**
       * limitToFirst()方法用于获取从第一条
       * （或startAt()方法指定的位置）开始向后指定数量的子节点
       */
      query = query.limitToFirst((int) parameters.get("limitToFirst"));
    }
    // 参数Map中是否包含一个limitToLast的key
    if (parameters.containsKey("limitToLast")) {
      /**
       * limitToLast()方法用于获取从最后一条
       * （或endAt()方法指定的位置）开始向前指定数量的子节点
       */
      query = query.limitToLast((int) parameters.get("limitToLast"));
    }
    // 返回query变量
    return query;
  }

  /**
   * 默认的回调完成监听器类
   */
  private class DefaultCompletionListener implements SyncReference.CompletionListener {
  	// 声明定义私有、不可变的Result变量
    private final Result result;

    /**
     * 类的构造方法
     * @param result 当前Result变量
     */
    DefaultCompletionListener(Result result) {
      // 将构造参数中的Result变量赋予类的Result变量
      this.result = result;
    }

	/**
     * 覆盖onComplete方法
     * @param error SyncError实例
     * @param ref SyncReference实例
     */
    @Override
    public void onComplete(SyncError error, SyncReference ref) {
      /**
       * 错误是否不等于null
       * 是则返回result.error(获得错误代码的字符串,获取错误消息,获取错误细节)
       * 否则返回result.success(null)
       */
      if (error != null) {
        result.error(String.valueOf(error.getErrCode()), error.getMessage(), error.getDetails());
      } else {
        result.success(null);
      }
    }
  }

  /**
   * 事件监听类
   */
  private class EventObserver implements ChildEventListener, ValueEventListener {
  	// 声明私有的请求事件类型变量
    private String requestedEventType;
    // 声明私有的句柄变量
    private int handle;

    /**
     * 类的构造方法
     * @param requestedEventType 请求事件类型
     * @param handle 句柄
     */
    EventObserver(String requestedEventType, int handle) {
      // 将构造参数中的requestedEventType变量赋予类的requestedEventType变量
      this.requestedEventType = requestedEventType;
      // 将构造参数中的handle变量赋予类的handle变量
      this.handle = handle;
    }

    /**
     * 类的构造方法
     * @param eventType 事件类型
     * @param snapshot 快照
     * @param previousChildName 上一个子节点的名称
     */
    private void sendEvent(String eventType, DataSnapshot snapshot, String previousChildName) {
      // 事件类型是否与类成员变量的请求事件类型一样
      if (eventType.equals(requestedEventType)) {
      	// 声明包含参数的Map变量
        Map<String, Object> arguments = new HashMap<>();
        // 声明包含快照的Map变量
        Map<String, Object> snapshotMap = new HashMap<>();
        // 在快照Map中将key与snapshot的key关联
        snapshotMap.put("key", snapshot.getKey());
        // 在快照Map中将value与snapshot的value关联
        snapshotMap.put("value", snapshot.getValue());
        // 在参数Map中将handle与类的handle变量关联
        arguments.put("handle", handle);
        // 在参数Map中将snapshot与快照Map关联
        arguments.put("snapshot", snapshotMap);
        // 在参数Map中将previousSiblingKey与previousChildName关联
        arguments.put("previousSiblingKey", previousChildName);
        // 方法通道实例的调用方法
        channel.invokeMethod("Event", arguments);
      }
    }

    /**
     * 覆盖onCancelled方法
     * @param error SyncError实例
     */
    @Override
    public void onCancelled(SyncError error) {}

    /**
     * 覆盖onChildAdded方法
     * @param snapshot DataSnapshot实例
     * @param previousChildName 上一个子节点的名称
     */
    @Override
    public void onChildAdded(DataSnapshot snapshot, String previousChildName) {
      sendEvent(EVENT_TYPE_CHILD_ADDED, snapshot, previousChildName);
    }

    /**
     * 覆盖onChildRemoved方法
     * @param DataSnapshot DataSnapshot实例
     */
    @Override
    public void onChildRemoved(DataSnapshot snapshot) {
      sendEvent(EVENT_TYPE_CHILD_REMOVED, snapshot, null);
    }

    /**
     * 覆盖onChildChanged方法
     * @param DataSnapshot DataSnapshot实例
     * @param previousChildName 上一个子节点的名称
     */
    @Override
    public void onChildChanged(DataSnapshot snapshot, String previousChildName) {
      sendEvent(EVENT_TYPE_CHILD_CHANGED, snapshot, previousChildName);
    }

    /**
     * 覆盖onChildMoved方法
     * @param DataSnapshot DataSnapshot实例
     * @param previousChildName 上一个子节点的名称
     */
    @Override
    public void onChildMoved(DataSnapshot snapshot, String previousChildName) {
      sendEvent(EVENT_TYPE_CHILD_MOVED, snapshot, previousChildName);
    }

    /**
     * 覆盖onDataChange方法
     * @param DataSnapshot DataSnapshot实例
     */
    @Override
    public void onDataChange(DataSnapshot snapshot) {
      sendEvent(EVENT_TYPE_VALUE, snapshot, null);
    }
  }

  /**
   * 接受客户端参数并调用方法
   * @param call 客户端传递的调用参数
   * @param result 返回客户端的结果
   */
  @Override
  public void onMethodCall(MethodCall call, final Result result) {
    switch (call.method) {

      // 手动建立WilddogSync连接
      case "WilddogSync#goOnline":
      {
      	// goOnline()方法用于手动建立连接
        WilddogSync.getInstance().goOnline();
        result.success(null);
        break;
      }

      // 手动断开WilddogSync连接
      case "WilddogSync#goOffline":
      {
      	// goOffline()方法用于手动断开连接
        WilddogSync.getInstance().goOffline();
        result.success(null);
        break;
      }

      // 设置启用持久性
      case "WilddogSync#setPersistenceEnabled":
      {
      	// 声明定义是否启用变量，并获取调用参数中的是否启用
        Boolean isEnabled = (Boolean) call.arguments;
        try {
          // setPersistenceEnabled方法用于开启数据持久化
          WilddogSync.getInstance().setPersistenceEnabled(isEnabled);
          // 返回true给客户端
          result.success(true);
        } catch (Exception e) {
          // 返回false给客户端
          // 数据库已经在使用，比如在热重启或重启以后
          result.success(false);
        }
        break;
      }

      // 设置节点的值
      case "SyncReference#set":
      {
        Map<String, Object> arguments = call.arguments();
        // 声明定义值变量，并获取调用参数中的值
        Object value = arguments.get("value");
        Object priority = arguments.get("priority");
        SyncReference reference = getReference(arguments);
        /*
         * 优选级是否不等于null
         * 是则返回指定优先级的setValue()方法
         * 否则返回不指定优先级的setValue()方法
         */
        if (priority != null) {
          /*
           * setValue()方法用于向指定节点写入数据
           * 此方法会先清空指定节点，再写入数据
           * 该方法可以设置回调方法来获取操作的结果
           */
          reference.setValue(value, priority, new DefaultCompletionListener(result));
        } else {
          reference.setValue(value, new DefaultCompletionListener(result));
        }
        break;
      }

      // 更新节点的值
      case "SyncReference#update":
      {
        Map<String, Object> arguments = call.arguments();
        @SuppressWarnings("unchecked")
        Map<String, Object> value = (Map<String, Object>) arguments.get("value");
        SyncReference reference = getReference(arguments);
        // updateChildren()方法用于更新指定子节点的值
        reference.updateChildren(value, new DefaultCompletionListener(result));
        break;
      }

      // 设置节点优先级
      case "SyncReference#setPriority":
      {
      	// 从客户端传递的调用参数中获取调用参数
        Map<String, Object> arguments = call.arguments();
        // 声明定义优先级变量，并获取调用参数中的优先级
        Object priority = arguments.get("priority");
        // 获取SyncReference实例
        SyncReference reference = getReference(arguments);
        // setPriority(priority)方法用于设置节点的优先级，优先级是节点的隐藏属性
        reference.setPriority(priority, new DefaultCompletionListener(result));
        break;
      }

      // 设置提前同步
      case "Query#keepSynced":
      {
        // WilddogSync的AndroidSDK暂不支持此设置
        result.success(null);
        break;
      }

      // 添加事件监听实例
      case "Query#observe":
      {
      	// 从客户端传递的调用参数中获取调用参数
        Map<String, Object> arguments = call.arguments();
        // 声明定义事件类型变量，并获取调用参数中的事件类型
        String eventType = (String) arguments.get("eventType");
        // 声明定义句柄变量，并获取成员变量nextHandle自增后的结果
        int handle = nextHandle++;
        // 声明定义事件监听实例
        EventObserver observer = new EventObserver(eventType, handle);
        // 在事件监听SparseArray中将句柄变量与事件监听实例关联
        observers.put(handle, observer);
        // 事件类型变量是否与类的EVENT_TYPE_VALUE变量一样
        if (eventType.equals(EVENT_TYPE_VALUE)) {
          // addValueEventListener()方法添加值事件监听器
          getQuery(arguments).addValueEventListener(observer);
        } else {
          // addChildEventListener()方法添加子节点事件监听器
          getQuery(arguments).addChildEventListener(observer);
        }
        // 返回句柄
        result.success(handle);
        break;
      }

      // 移除事件监听实例
      case "Query#removeObserver":
      {
      	// 从客户端传递的调用参数中获取调用参数
        Map<String, Object> arguments = call.arguments();
        // 声明定义Query实例，并获取查询方法
        Query query = getQuery(arguments);
        // 声明定义句柄变量，并获取调用参数中的句柄
        int handle = (Integer) arguments.get("handle");
        // 声明定义事件监听实例，并在事件监听SparseArray中获取指定实例
        EventObserver observer = observers.get(handle);
        /**
         * 事件监听实例是否不等于null
         * 是则移除事件监听实例
         * 否则返回错误提示
         */
        if (observer != null) {
          // 事件类型变量是否与类的EVENT_TYPE_VALUE变量一样
          if (observer.requestedEventType.equals(EVENT_TYPE_VALUE)) {
          	// removeEventListener()方法移除值事件监听器
            query.removeEventListener((ValueEventListener) observer);
          } else {
          	// removeEventListener()方法移除子节点事件监听器
            query.removeEventListener((ChildEventListener) observer);
          }
          // 在事件监听SparseArray中删除对应的句柄变量与事件监听实例
          observers.delete(handle);
          result.success(null);
          break;
        } else {
          // 返回错误信息给客户端
          result.error("unknown_handle", "removeObserver调用了未知句柄", null);
          break;
        }
      }

      // 未实现的方法
      default:
      {
        // 返回未实现方法的提示
        result.notImplemented();
        break;
      }
    }
  }
}