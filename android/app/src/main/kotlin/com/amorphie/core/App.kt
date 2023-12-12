package com.amorphie.core

import android.app.Application
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant

class App : Application() {

    override fun onCreate() {
        super.onCreate()
        GeneratedPluginRegistrant.registerWith(FlutterEngine(applicationContext))
    }
}



