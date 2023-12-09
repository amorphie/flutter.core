package com.amorphie.core.util

import android.util.Log

object Nlog {
    /*
    fun d(tag: String, msg: String, exp: Throwable? = null) {
        if (BuildConfig.DEBUG) {
            Log.d(tag, msg, exp)
        }
    }


    fun e(tag: String, msg: String, exp: Throwable? = null) {
        if (BuildConfig.DEBUG) {
            Log.e(tag, msg, exp)
        }
    }


    fun e(tag: String, exp: Throwable) {
        if (BuildConfig.DEBUG) {
            Log.e(tag, null, exp)
        }
    }

    fun i(tag: String, msg: String, exp: Throwable? = null) {
        if (BuildConfig.DEBUG) {
            Log.i(tag, msg, exp)
        }
    }


    fun v(tag: String, msg: String, exp: Throwable? = null) {
        if (BuildConfig.DEBUG) {
            Log.v(tag, msg, exp)
        }
    }


    fun w(tag: String, msg: String, exp: Throwable? = null) {
        if (BuildConfig.DEBUG) {
            Log.w(tag, msg, exp)
        }
    }

    fun w(tag: String, msgResId: Int, exp: Throwable? = null) {
        if (BuildConfig.DEBUG) {
            Log.w(tag, app.getString(msgResId), exp)
        }
    }
*/
    fun x(msg: Any) {
        //TODO: check is it DEBUG BUILD
        val sb = StringBuilder()
        val stackTrace = Throwable().stackTrace[1]
        var fileName = stackTrace.fileName ?: ""
        sb.append(stackTrace.methodName)
            .append("(").append(fileName).append(":")
            .append(stackTrace.lineNumber).append(")")
            .append(" *** ").append(msg.toString())
        Log.d("_", sb.toString())

    }

    fun x(tag: String?, msg: Any) {
        //TODO: check is it DEBUG BUILD
        val sb = StringBuilder()
        val stackTrace = Throwable().stackTrace[1]
        var fileName = stackTrace.fileName ?: ""
        sb.append(stackTrace.methodName)
            .append("(").append(fileName).append(":")
            .append(stackTrace.lineNumber).append(")")
            .append(" *** ").append(msg.toString())
        Log.d("${tag ?: '_'}", sb.toString())

    }

}

