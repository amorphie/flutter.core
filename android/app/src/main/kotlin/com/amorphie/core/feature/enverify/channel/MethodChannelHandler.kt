package com.amorphie.core.feature.enverify.channel


import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MethodChannelHandler(engine: FlutterEngine) {

    private val METHOD_CHANNEL = "com.amorpihe.core/enverify/methods"
    private var methodChannelListener: MethodChannelListener? = null

    init {
        MethodChannel(engine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler {
            // This method is invoked on the main thread.
                c, r ->
            if (c.method == EnverifyMethods.start.name) {

            } else if (c.method == EnverifyMethods.stop.name) {

            } else {
                r.notImplemented()
            }
        }
    }

    fun setListener(listener: MethodChannelListener) {
        methodChannelListener = listener
    }

    private fun nativeEnverifyStart(name: String, lastName: String, callType: String) {
        methodChannelListener?.onSDKInit(name, lastName, callType)
    }

    private fun nativeEnverifyStop() {
        methodChannelListener?.onSDKStopped()
    }
}


