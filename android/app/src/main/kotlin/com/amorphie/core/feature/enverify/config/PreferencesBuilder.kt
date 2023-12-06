package com.amorphie.core.feature.enverify.config

import com.enqura.enverify.EnVerifyApi

class PreferencesBuilder {
    private var isMediaServerClosed: Boolean = false
    private var isCanAutoClose: Boolean = false
    fun withPrefs(isMediaServerClosed: Boolean, isCanAutoClose: Boolean) {
        this.isMediaServerClosed = isMediaServerClosed
        this.isCanAutoClose = isCanAutoClose
    }

    fun build(): Preferences {
        return Preferences(setMediaServer = !isMediaServerClosed, isCanAutoClose = isCanAutoClose)
    }

}

data class Preferences(
    //Göz okutma derecesi / 0.1 zorlaştırır, 1.0 kolaylaştırır / default 0.3
    val eyeCloseCalibration: Double = 0.3,
    //Gülümseme okutma derecesi. 0.1 kolaylaştırır 1.0 zorlaştırır - default 0.7
    val smilingCalibration: Double = 0.7,
    //NFC ekranında kimlik okutma sırasında toast mesajları engeller.(false)
    val isNFCToastMessages: Boolean = false,
    // true set edildiğinde görüntülü görüşmenin doğrunda relay(turn) üzerinden yapılmasını sağlar, ilk bağlantı hızını arttırır.
    val isICRelay: Boolean = true,
    val callWaitTimeout: Int = 6000,
    val videoResolution: Int = 720,
    //** SDK 1.1 feature** // MediaServer üzerinden calismayı aktif hale getirir.
    val setMediaServer: Boolean,
    //force hange-up ı tetikleyebilir.
    val iceCheckingTimeout: Int = 60,
    //3 hard - 30 easy (default 10)
    val faceDetectTimeout: Int = 30,
    val fFaceEyeSmileAngleTimeout: Int = 30,
    val ocrMode: Int = EnVerifyApi.TR_FAST_MODE,
    // 10 hard - 50 easy (default 50) TR_STRICT_MODE kullanıldığında set edilmeli 30 un altına düşerken dikkat ediniz.
    val ocrCheckSize: Int = 50,
    val isCameraCloseNFC: Boolean = true,
    val isCanAutoClose: Boolean,


    )