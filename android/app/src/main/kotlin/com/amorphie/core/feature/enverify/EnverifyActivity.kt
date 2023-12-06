package com.amorphie.core.feature.enverify

import android.os.Bundle
import com.amorphie.core.feature.enverify.channel.EventChannelHandler
import com.amorphie.core.feature.enverify.channel.MethodChannelHandler
import com.amorphie.core.feature.enverify.channel.MethodChannelListener
import com.amorphie.core.feature.enverify.config.DomainType
import com.amorphie.core.feature.enverify.config.EnverifySDKBuilder
import com.enqura.enverify.EnVerifyCallback
import com.enqura.enverify.models.enums.CloseSessionStatus
import com.smartvist.idverify.models.IDVerifyFailureCode
import com.smartvist.idverify.models.IDVerifyState
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.swagger.client.model.VerifyCallResultModel

class EnverifyActivity : FlutterActivity(), EnVerifyCallback {

    private val eventHandler: EventChannelHandler by lazy {
        EventChannelHandler(FlutterEngine(this))
    }
    private val methodHandler: MethodChannelHandler by lazy {
        MethodChannelHandler(FlutterEngine(this)).also {
            moveTaskToBack(true)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)


    }

    override fun onStart() {
        super.onStart()
        val api = EnverifySDKBuilder.create()
            .withUserData(applicationContext, "name", "surname", "call")
            .withDomain(DomainType.pilot, true)
            .withPrefs(true, true)
            .withCredential(domainType = DomainType.pilot)
            .build()

        eventHandler.sendIntialData()
        
        methodHandler.setListener(object : MethodChannelListener {
            override fun onSDKInit(name: String, lastName: String, callType: String) {
                TODO("Not yet implemented")
            }

            override fun onSDKStopped() {
                TODO("Not yet implemented")
            }

        })

    }

    override fun videoCallReady() {
        TODO("Not yet implemented")
    }

    override fun selfServiceReady() {
        TODO("Not yet implemented")
    }

    override fun idVerifyReady() {
        TODO("Not yet implemented")
    }

    override fun idSelfVerifyReady() {
        TODO("Not yet implemented")
    }

    override fun idRetry() {
        TODO("Not yet implemented")
    }

    override fun idTypeVerified() {
        TODO("Not yet implemented")
    }

    override fun idDocCompleted() {
        TODO("Not yet implemented")
    }

    override fun idDocVerified() {
        TODO("Not yet implemented")
    }

    override fun nfcReady() {
        TODO("Not yet implemented")
    }

    override fun nfcRetry() {
        TODO("Not yet implemented")
    }

    override fun nfcCompleted() {
        TODO("Not yet implemented")
    }

    override fun nfcVerified() {
        TODO("Not yet implemented")
    }

    override fun faceReady() {
        TODO("Not yet implemented")
    }

    override fun faceRetry() {
        TODO("Not yet implemented")
    }

    override fun faceDetected() {
        TODO("Not yet implemented")
    }

    override fun smileDetected() {
        TODO("Not yet implemented")
    }

    override fun faceCompleted() {
        TODO("Not yet implemented")
    }

    override fun faceVerified() {
        TODO("Not yet implemented")
    }

    override fun restartVerification() {
        TODO("Not yet implemented")
    }

    override fun onFailure(p0: IDVerifyState?, p1: IDVerifyFailureCode?, p2: String?) {
        TODO("Not yet implemented")
    }

    override fun fakeChecked() {
        TODO("Not yet implemented")
    }

    override fun eyeCloseDetected() {
        TODO("Not yet implemented")
    }

    override fun eyeCloseIntervalDetected() {
        TODO("Not yet implemented")
    }

    override fun rightEyeCloseDetected() {
        TODO("Not yet implemented")
    }

    override fun leftEyeCloseDetected() {
        TODO("Not yet implemented")
    }

    override fun faceLeftDetected() {
        TODO("Not yet implemented")
    }

    override fun faceRightDetected() {
        TODO("Not yet implemented")
    }

    override fun faceUpDetected() {
        TODO("Not yet implemented")
    }

    override fun retryFaceVerification() {
        TODO("Not yet implemented")
    }

    override fun retryNFCVerification() {
        TODO("Not yet implemented")
    }

    override fun retryTextVerification() {
        TODO("Not yet implemented")
    }

    override fun localHangedUp() {
        TODO("Not yet implemented")
    }

    override fun callWait() {
        TODO("Not yet implemented")
    }

    override fun callStarted() {
        TODO("Not yet implemented")
    }

    override fun remoteHangedUp() {
        TODO("Not yet implemented")
    }

    override fun resolutionChanged() {
        TODO("Not yet implemented")
    }

    override fun faceStoreCompleted() {
        TODO("Not yet implemented")
    }

    override fun forceHangup() {
        TODO("Not yet implemented")
    }

    override fun agentRequest(p0: String?) {
        TODO("Not yet implemented")
    }

    override fun cardFrontDetected() {
        TODO("Not yet implemented")
    }

    override fun cardBackDetected() {
        TODO("Not yet implemented")
    }

    override fun cardHoloDetected() {
        TODO("Not yet implemented")
    }

    override fun idFrontCompleted() {
        TODO("Not yet implemented")
    }

    override fun screenRecorderOnStart() {
        TODO("Not yet implemented")
    }

    override fun screenRecorderOnComplete() {
        TODO("Not yet implemented")
    }

    override fun screenRecorderOnError(p0: Int, p1: String?) {
        TODO("Not yet implemented")
    }

    override fun screenRecorderOnAppend() {
        TODO("Not yet implemented")
    }

    override fun onIntegrationSucceed() {
        TODO("Not yet implemented")
    }

    override fun onIntegrationFailed() {
        TODO("Not yet implemented")
    }

    override fun onResultGetSucceed(p0: VerifyCallResultModel?) {
        TODO("Not yet implemented")
    }

    override fun onResultGetFailed() {
        TODO("Not yet implemented")
    }

    override fun onSessionStartFailed() {
        TODO("Not yet implemented")
    }

    override fun onSessionStartSucceed(p0: Boolean, p1: String?) {
        TODO("Not yet implemented")
    }

    override fun idDocStored() {
        TODO("Not yet implemented")
    }

    override fun idDocStoreFailed() {
        TODO("Not yet implemented")
    }

    override fun nfcStored() {
        TODO("Not yet implemented")
    }

    override fun nfcStoreFailed() {
        TODO("Not yet implemented")
    }

    override fun faceStored() {
        TODO("Not yet implemented")
    }

    override fun faceStoreFailed() {
        TODO("Not yet implemented")
    }

    override fun onRoomIDSendSucceed() {
        TODO("Not yet implemented")
    }

    override fun onRoomIDSendFailed() {
        TODO("Not yet implemented")
    }

    override fun agentCameraDisabled() {
        TODO("Not yet implemented")
    }

    override fun agentCameraEnabled() {
        TODO("Not yet implemented")
    }

    override fun nfcBACDataFailure() {
        TODO("Not yet implemented")
    }

    override fun callSessionCloseResult(p0: CloseSessionStatus?) {
        TODO("Not yet implemented")
    }

    override fun maximumCallTimeExpired() {
        TODO("Not yet implemented")
    }

    override fun onVideoAddSucceed() {
        TODO("Not yet implemented")
    }

    override fun onVideoAddFailure(p0: String?) {
        TODO("Not yet implemented")
    }

    override fun signingSucceed() {
        TODO("Not yet implemented")
    }

    override fun signingFailed() {
        TODO("Not yet implemented")
    }

    override fun sessionUpdateSucceed() {
        TODO("Not yet implemented")
    }

    override fun sessionUpdateFailed() {
        TODO("Not yet implemented")
    }
}