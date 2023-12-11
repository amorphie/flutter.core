package com.amorphie.core.feature.common


import android.content.Context
import com.amorphie.core.util.Nlog


import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall

import io.flutter.plugin.common.MethodChannel

class MethodChannelHandler(engine: FlutterEngine) {

    private val METHOD_CHANNEL = "com.amorphie.core/common/methods"
    private var methodChannelListener: MethodChannelListener? = null

    init {
        if (engine==null){
            Nlog.x("NULL NULL")
        }else{
            Nlog.x("NOT NULL")
        }
        MethodChannel(engine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler {
            // This method is invoked on the main thread.
                call, result ->
                Nlog.x("Native Method Call: ${call.method}")
            if (call.method == MethodNames.prepareEnverifySDK.name) {
                prepareEnverifySDK(call, result)
            } else if (call.method == "") {

            } else {
               // result.notImplemented()
            }
        }
    }

    fun setListener(listener: MethodChannelListener) {
        methodChannelListener = listener
    }

    private fun prepareEnverifySDK(call: MethodCall, result: MethodChannel.Result) {
        val name: String? = call.argument(MethodKeys.configEnverifySDK.name)
        //TODO: handle proper way incoming parameters and result
        methodChannelListener?.onEnverifySDKPrepared(name!!)
        result.success(true)
    }


}


