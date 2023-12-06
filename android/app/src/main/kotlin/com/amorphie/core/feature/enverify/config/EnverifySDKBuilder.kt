package com.amorphie.core.feature.enverify.config

import android.content.Context
import com.enqura.enverify.EnVerifyApi
import com.enqura.enverify.models.User

class EnverifySDKBuilder private constructor() {
    private val domainBuilder: DomainBuilder = DomainBuilder()
    private val credentialBuilder: CredentialBuilder = CredentialBuilder()
    private val preferenceBuilder: PreferencesBuilder = PreferencesBuilder()
    private val userBuilder: UserBuilder = UserBuilder()
    private var context: Context? = null
    fun withUserData(context: Context, name: String, surname: String, callType: String): EnverifySDKBuilder {
        this.context = context
        userBuilder.withUserData(name, surname, callType)
        return this
    }

    fun withDomain(domainType: DomainType, isMediaServerClosed: Boolean): EnverifySDKBuilder {
        domainBuilder.withDomain(domainType, isMediaServerClosed)
        return this
    }

    fun withCredential(domainType: DomainType): EnverifySDKBuilder {
        credentialBuilder.withCredential(domainType)
        return this
    }

    fun withPrefs(isMediaServerClosed: Boolean, isCanAutoClose: Boolean): EnverifySDKBuilder {
        preferenceBuilder.withPrefs(isMediaServerClosed, isCanAutoClose)
        return this
    }

    fun build(): EnVerifyApi {
        val enVerifyApi = EnVerifyApi.getInstance()
        val user = User.getInstance()
        context?.let {
            user.init(context)
            userBuilder.build()?.let { u ->
                user.firstName = u.name
                user.lastName = u.surname
                user.callType = u.callType
            }
        }


        domainBuilder.build().let {
            enVerifyApi.setDomain(it.domainName, it.turnNamePort, it.stunNamePort, it.signalServer)
        }
        credentialBuilder.build()?.let {
            enVerifyApi.setCredentials(it.credentialName, it.credentialPassword)
            enVerifyApi.setTurnCredentials(it.turnUsername, it.turnPassword)
            enVerifyApi.setMSPrivateKey(it.msPrivateKey)
        }
        preferenceBuilder.build()?.let {
            enVerifyApi.setEyeCloseCalibration(it.eyeCloseCalibration)
            enVerifyApi.setSmilingCalibration(it.smilingCalibration)
            enVerifyApi.setNFCToastMessages(it.isNFCToastMessages)
            enVerifyApi.setICRelay(it.isNFCToastMessages)
            enVerifyApi.setCallWaitTimeout(it.callWaitTimeout)
            enVerifyApi.setVideoResolution(it.videoResolution)
            enVerifyApi.setMediaServer(it.setMediaServer)
            enVerifyApi.setIceCheckingTimeout(it.iceCheckingTimeout)
            enVerifyApi.setFaceDetectTimeout(it.faceDetectTimeout)
            enVerifyApi.setFaceEyeSmileAngleTimeout(it.fFaceEyeSmileAngleTimeout)
            enVerifyApi.setOCRMode(it.ocrMode)
            enVerifyApi.setOCRCheckSize(it.ocrCheckSize)
            enVerifyApi.isCameraCloseNFC = it.isCameraCloseNFC
            enVerifyApi.setCanAutoClose(it.isCanAutoClose)

        }



        return enVerifyApi
    }

    companion object {
        fun create(): EnverifySDKBuilder {
            return EnverifySDKBuilder()
        }
    }
}