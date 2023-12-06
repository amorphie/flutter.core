package com.amorphie.core.feature.enverify.channel



interface MethodChannelListener {

    fun onSDKInit(name:String,lastName:String,callType:String);

    fun onSDKStopped();
}

