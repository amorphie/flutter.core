package com.amorphie.core.feature.enverify.config

class CredentialBuilder {

    private lateinit var domainType: DomainType

    fun withCredential(domainType: DomainType): CredentialBuilder {
        this.domainType = domainType
        return this
    }

    fun build(): EnverifyCredential {
        return when (domainType) {
            DomainType.test, DomainType.pilot, DomainType.preprod -> EnverifyCredential(
                credentialName = EnverifyConstants.v_55,
                credentialPassword = EnverifyConstants.v_56,
                turnUsername = EnverifyConstants.v_57,
                turnPassword = EnverifyConstants.v_58
            )

            DomainType.prod -> EnverifyCredential(
                credentialName = EnverifyConstants.v_72,
                credentialPassword = EnverifyConstants.v_73,
                turnUsername = EnverifyConstants.v_74,
                turnPassword = EnverifyConstants.v_75
            )
        }
    }
}

data class EnverifyCredential(
    val credentialName: String,
    val credentialPassword: String,
    val turnUsername: String,
    val turnPassword: String,
    val msPrivateKey: String = EnverifyConstants.v_700
)