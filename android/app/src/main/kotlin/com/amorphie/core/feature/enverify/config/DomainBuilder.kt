package com.amorphie.core.feature.enverify.config


class DomainBuilder {

    private lateinit var domainType: DomainType
    private var isMediaServerClosed = false
    fun withDomain(domainType: DomainType, isMediaServerClosed: Boolean): DomainBuilder {
        this.domainType = domainType
        this.isMediaServerClosed = isMediaServerClosed
        return this
    }

    fun build(): EnverifyDomain {
        return when (domainType) {
            DomainType.test -> EnverifyDomain(
                domainName = EnverifyConstants.v_50,
                turnNamePort = EnverifyConstants.v_52,
                stunNamePort = EnverifyConstants.v_53,
                signalServer = if (isMediaServerClosed) EnverifyConstants.v_54 else EnverifyConstants.v_54ms,
                backOfficeBaseURL = EnverifyConstants.v_59
            )

            DomainType.pilot -> EnverifyDomain(
                domainName = EnverifyConstants.v_90,
                turnNamePort = EnverifyConstants.v_92,
                stunNamePort = EnverifyConstants.v_93,
                signalServer = if (isMediaServerClosed) EnverifyConstants.v_95 else EnverifyConstants.v_95ms,
                backOfficeBaseURL = EnverifyConstants.v_96
            )

            DomainType.preprod -> EnverifyDomain(
                domainName = EnverifyConstants.v_60,
                turnNamePort = EnverifyConstants.v_62,
                stunNamePort = EnverifyConstants.v_63,
                signalServer = if (isMediaServerClosed) EnverifyConstants.v_65 else EnverifyConstants.v_65ms,
                backOfficeBaseURL = EnverifyConstants.v_66
            )

            DomainType.prod -> EnverifyDomain(
                domainName = EnverifyConstants.v_67,
                turnNamePort = EnverifyConstants.v_69,
                stunNamePort = EnverifyConstants.v_70,
                signalServer = if (isMediaServerClosed) EnverifyConstants.v_71 else EnverifyConstants.v_71ms,
                backOfficeBaseURL = EnverifyConstants.v_76
            )
        }
    }
}

data class EnverifyDomain(
    val domainName: String,
    val turnNamePort: String,
    val stunNamePort: String,
    val signalServer: String,
    val backOfficeBaseURL: String,
)

