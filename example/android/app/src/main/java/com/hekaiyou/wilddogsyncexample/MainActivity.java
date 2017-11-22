package com.hekaiyou.wilddogsyncexample;

import android.os.Bundle;

import io.flutter.app.FlutterActivity;
import io.flutter.plugins.GeneratedPluginRegistrant;

import com.wilddog.wilddogcore.WilddogOptions;
import com.wilddog.wilddogcore.WilddogApp;

public class MainActivity extends FlutterActivity {
  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    WilddogOptions options = new WilddogOptions.Builder().setSyncUrl("https://wd7039035262bkoubk.wilddogio.com/").build();
    WilddogApp.initializeApp(this, options);
    GeneratedPluginRegistrant.registerWith(this);
  }
}
