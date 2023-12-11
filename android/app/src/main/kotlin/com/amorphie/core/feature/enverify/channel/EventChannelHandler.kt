package com.amorphie.core.feature.enverify.channel

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

class EventChannelHandler(engine: FlutterEngine) {

    private val EVENT_CHANNEL = "com.amorphie.core/enverify/events"
    private var eventSink: EventChannel.EventSink? = null

    init {
        EventChannel(engine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {

                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    stopEvents()
                }

            })
    }

    fun sendIntialData() {
        eventSink?.let {
            val data = "Event Hello from Native!"
            it.success(data)
        }
    }

    fun sendMessage(message: String) {
        eventSink?.let {
            it.success(message)
        }
    }

    fun stopEvents() {
        eventSink?.let {
            val msg = "Stop"
            it.success(msg)
        }
    }


}