package com.amorphie.core.feature.enverify.channel


import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MethodChannelHandler(engine: FlutterEngine) {

    private val METHOD_CHANNEL = "com.amorphie.core/enverify/methods"
    private var methodChannelListener: MethodChannelListener? = null

    init {
        MethodChannel(engine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler {
            // This method is invoked on the main thread.
                call, result ->
            if (call.method == MethodNames.startSDK.name) {
                nativeEnverifyStart(call, result)
            } else if (call.method == MethodNames.stopSDK.name) {

            } else {
                result.notImplemented()
            }
        }
    }

    fun setListener(listener: MethodChannelListener) {
        methodChannelListener = listener
    }


    private fun nativeEnverifyStart(call: MethodCall, result: MethodChannel.Result) {
        val name: String? = call.argument(MethodKeys.firstName.name)
        val lastName: String? = call.argument(MethodKeys.lastName.name)
        val callType: String? = call.argument(MethodKeys.callType.name)
        //TODO: handle proper way incoming parameters
        //result.error()
        methodChannelListener?.onSDKInit(name!!, lastName!!, callType!!)
        result.success(true)
    }

    private fun nativeEnverifyStop() {
        methodChannelListener?.onSDKStopped()
    }
}


