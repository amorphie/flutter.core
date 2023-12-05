package com.amorphie.core.feature.enverify.config

class UserBuilder {

    private var name: String = ""
    private var surname: String = ""
    private var callType: String = ""

    fun withUserData(name: String, surname: String, callType: String) {
        this.name = name
        this.surname = surname
        this.callType = callType
    }

    fun build() = EnverifyUser(name, surname, callType)

}

data class EnverifyUser(
    val name: String,
    val surname: String,
    val callType: String,
)
