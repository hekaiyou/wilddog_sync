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
  private final MethodChannel channel;
  private static final String EVENT_TYPE_CHILD_ADDED = "_EventType.childAdded";
  private static final String EVENT_TYPE_CHILD_REMOVED = "_EventType.childRemoved";
  private static final String EVENT_TYPE_CHILD_CHANGED = "_EventType.childChanged";
  private static final String EVENT_TYPE_CHILD_MOVED = "_EventType.childMoved";
  private static final String EVENT_TYPE_VALUE = "_EventType.value";

  private int nextHandle = 0;
  private final SparseArray<EventObserver> observers = new SparseArray<>();

  public static void registerWith(PluginRegistry.Registrar registrar) {
    final MethodChannel channel =
            new MethodChannel(registrar.messenger(), "wilddog_sync");
    channel.setMethodCallHandler(new WilddogSyncPlugin(channel));
  }

  private WilddogSyncPlugin(MethodChannel channel) {
    this.channel = channel;
  }

  /**
   * 获取一个SyncReference实例
   * @param arguments 通道传递的参数Map
   * @return SyncReference实例
   */
  private SyncReference getReference(Map<String, Object> arguments) {
    String path = (String) arguments.get("path");
    // 获取SyncReference实例
    SyncReference reference = WilddogSync.getInstance().getReference();
    // child()用来定位到某个节点。
    if (path != null) reference = reference.child(path);
    return reference;
  }

  private Query getQuery(Map<String, Object> arguments) {
    Query query = getReference(arguments);
    @SuppressWarnings("unchecked")
    Map<String, Object> parameters = (Map<String, Object>) arguments.get("parameters");
    if (parameters == null) return query;
    Object orderBy = parameters.get("orderBy");
    if ("child".equals(orderBy)) {
      query = query.orderByChild((String) parameters.get("orderByChildKey"));
    } else if ("key".equals(orderBy)) {
      query = query.orderByKey();
    } else if ("value".equals(orderBy)) {
      query = query.orderByValue();
    } else if ("priority".equals(orderBy)) {
      query = query.orderByPriority();
    }
    if (parameters.containsKey("startAt")) {
      Object startAt = parameters.get("startAt");
      if (parameters.containsKey("startAtKey")) {
        String startAtKey = (String) parameters.get("startAtKey");
        if (startAt instanceof Boolean) {
          query = query.startAt((Boolean) startAt, startAtKey);
        } else if (startAt instanceof String) {
          query = query.startAt((String) startAt, startAtKey);
        } else {
          query = query.startAt(((Number) startAt).doubleValue(), startAtKey);
        }
      } else {
        if (startAt instanceof Boolean) {
          query = query.startAt((Boolean) startAt);
        } else if (startAt instanceof String) {
          query = query.startAt((String) startAt);
        } else {
          query = query.startAt(((Number) startAt).doubleValue());
        }
      }
    }
    if (parameters.containsKey("endAt")) {
      Object endAt = parameters.get("endAt");
      if (parameters.containsKey("endAtKey")) {
        String endAtKey = (String) parameters.get("endAtKey");
        if (endAt instanceof Boolean) {
          query = query.endAt((Boolean) endAt, endAtKey);
        } else if (endAt instanceof String) {
          query = query.endAt((String) endAt, endAtKey);
        } else {
          query = query.endAt(((Number) endAt).doubleValue(), endAtKey);
        }
      } else {
        if (endAt instanceof Boolean) {
          query = query.endAt((Boolean) endAt);
        } else if (endAt instanceof String) {
          query = query.endAt((String) endAt);
        } else {
          query = query.endAt(((Number) endAt).doubleValue());
        }
      }
    }
    if (parameters.containsKey("equalTo")) {
      Object equalTo = parameters.get("equalTo");
      if (equalTo instanceof Boolean) {
        query = query.equalTo((Boolean) equalTo);
      } else if (equalTo instanceof String) {
        query = query.equalTo((String) equalTo);
      } else {
        query = query.equalTo(((Number) equalTo).doubleValue());
      }
    }
    if (parameters.containsKey("limitToFirst")) {
      query = query.limitToFirst((int) parameters.get("limitToFirst"));
    }
    if (parameters.containsKey("limitToLast")) {
      query = query.limitToLast((int) parameters.get("limitToLast"));
    }
    return query;
  }

  /**
   * 默认的回调完成监听器
   */
  private class DefaultCompletionListener implements SyncReference.CompletionListener {
    private final Result result;

    DefaultCompletionListener(Result result) {
      this.result = result;
    }

    @Override
    public void onComplete(SyncError error, SyncReference ref) {
      if (error != null) {
        result.error(String.valueOf(error.getErrCode()), error.getMessage(), error.getDetails());
      } else {
        result.success(null);
      }
    }
  }

  private class EventObserver implements ChildEventListener, ValueEventListener {
    private String requestedEventType;
    private int handle;

    EventObserver(String requestedEventType, int handle) {
      this.requestedEventType = requestedEventType;
      this.handle = handle;
    }

    private void sendEvent(String eventType, DataSnapshot snapshot, String previousChildName) {
      if (eventType.equals(requestedEventType)) {
        Map<String, Object> arguments = new HashMap<>();
        Map<String, Object> snapshotMap = new HashMap<>();
        snapshotMap.put("key", snapshot.getKey());
        snapshotMap.put("value", snapshot.getValue());
        arguments.put("handle", handle);
        arguments.put("snapshot", snapshotMap);
        arguments.put("previousSiblingKey", previousChildName);
        channel.invokeMethod("Event", arguments);
      }
    }

    @Override
    public void onCancelled(SyncError error) {}

    @Override
    public void onChildAdded(DataSnapshot snapshot, String previousChildName) {
      sendEvent(EVENT_TYPE_CHILD_ADDED, snapshot, previousChildName);
    }

    @Override
    public void onChildRemoved(DataSnapshot snapshot) {
      sendEvent(EVENT_TYPE_CHILD_REMOVED, snapshot, null);
    }

    @Override
    public void onChildChanged(DataSnapshot snapshot, String previousChildName) {
      sendEvent(EVENT_TYPE_CHILD_CHANGED, snapshot, previousChildName);
    }

    @Override
    public void onChildMoved(DataSnapshot snapshot, String previousChildName) {
      sendEvent(EVENT_TYPE_CHILD_MOVED, snapshot, previousChildName);
    }

    @Override
    public void onDataChange(DataSnapshot snapshot) {
      sendEvent(EVENT_TYPE_VALUE, snapshot, null);
    }
  }

  @Override
  public void onMethodCall(MethodCall call, final Result result) {
    switch (call.method) {
      case "WilddogSync#goOnline":
      {
        WilddogSync.getInstance().goOnline();
        result.success(null);
        break;
      }

      case "WilddogSync#goOffline":
      {
        WilddogSync.getInstance().goOffline();
        result.success(null);
        break;
      }

      case "WilddogSync#setPersistenceEnabled":
      {
        Boolean isEnabled = (Boolean) call.arguments;
        try {
          WilddogSync.getInstance().setPersistenceEnabled(isEnabled);
          result.success(true);
        } catch (Exception e) {
          // 数据库已经在使用，比如在热重启或重启以后。
          result.success(false);
        }
        break;
      }

      case "SyncReference#set":
      {
        Map<String, Object> arguments = call.arguments();
        Object value = arguments.get("value");
        // priority存储通道传递的节点优先级
        Object priority = arguments.get("priority");
        SyncReference reference = getReference(arguments);
        if (priority != null) {
          // setValue()方法用于向指定节点写入数据。此方法会先清空指定节点，再写入数据。
          // 该方法可设置回调方法来获取操作的结果。
          reference.setValue(value, priority, new DefaultCompletionListener(result));
        } else {
          reference.setValue(value, new DefaultCompletionListener(result));
        }
        break;
      }

      case "SyncReference#update":
      {
        Map<String, Object> arguments = call.arguments();
        Map value = (Map) arguments.get("value");
        SyncReference reference = getReference(arguments);
        reference.updateChildren(value, new DefaultCompletionListener(result));
        break;
      }

      case "SyncReference#setPriority":
      {
        Map<String, Object> arguments = call.arguments();
        Object priority = arguments.get("priority");
        SyncReference reference = getReference(arguments);
        reference.setPriority(priority, new DefaultCompletionListener(result));
        break;
      }

      case "Query#keepSynced":
      {
        //Map<String, Object> arguments = call.arguments();
        //boolean value = (Boolean) arguments.get("value");
        //getQuery(arguments).keepSynced(value);
        result.success(null);
        break;
      }

      case "Query#observe":
      {
        Map<String, Object> arguments = call.arguments();
        String eventType = (String) arguments.get("eventType");
        int handle = nextHandle++;
        EventObserver observer = new EventObserver(eventType, handle);
        observers.put(handle, observer);
        if (eventType.equals(EVENT_TYPE_VALUE)) {
          getQuery(arguments).addValueEventListener(observer);
        } else {
          getQuery(arguments).addChildEventListener(observer);
        }
        result.success(handle);
        break;
      }

      case "Query#removeObserver":
      {
        Map<String, Object> arguments = call.arguments();
        Query query = getQuery(arguments);
        int handle = (Integer) arguments.get("handle");
        EventObserver observer = observers.get(handle);
        if (observer != null) {
          if (observer.requestedEventType.equals(EVENT_TYPE_VALUE)) {
            query.removeEventListener((ValueEventListener) observer);
          } else {
            query.removeEventListener((ChildEventListener) observer);
          }
          observers.delete(handle);
          result.success(null);
          break;
        } else {
          result.error("unknown_handle", "removeObserver called on an unknown handle", null);
          break;
        }
      }

      default:
      {
        result.notImplemented();
        break;
      }
    }
  }
}
