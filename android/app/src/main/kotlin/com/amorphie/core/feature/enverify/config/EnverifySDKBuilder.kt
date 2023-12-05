package com.amorphie.core.feature.enverify.config

import com.enqura.enverify.EnVerifyApi

class EnverifySDKBuilder {
    private val domainBuilder: DomainBuilder = DomainBuilder()
    private val credentialBuilder: CredentialBuilder = CredentialBuilder()
    private val preferenceBuilder: PreferencesBuilder = PreferencesBuilder()
    private val userBuilder: UserBuilder = UserBuilder()
    fun withDomain(domainType: DomainType, isMediaServerClosed: Boolean): EnverifySDKBuilder {
        domainBuilder.withDomain(domainType, isMediaServerClosed)
        return this
    }

    fun withCredential(domainType: DomainType): EnverifySDKBuilder {
        credentialBuilder.withCredential(domainType)
        return this
    }

    fun build(): EnVerifyApi {
        val enVerifyApi = EnVerifyApi.getInstance()

        domainBuilder.build().let {
            enVerifyApi.setDomain(it.domainName, it.turnNamePort, it.stunNamePort, it.signalServer)
        }
        credentialBuilder.build()?.let {
            enVerifyApi.setCredentials(it.credentialName, it.credentialPassword)
            enVerifyApi.setTurnCredentials(it.turnUsername, it.turnPassword)
        }


        return enVerifyApi
    }

    companion object {
        fun create(): EnverifySDKBuilder {
            return EnverifySDKBuilder()
        }
    }
}