package com.amorphie.core

import android.content.Intent
import android.os.Bundle
import android.os.PersistableBundle
import androidx.appcompat.app.AppCompatActivity
import com.amorphie.core.feature.common.MethodChannelHandler
import com.amorphie.core.feature.common.MethodChannelListener
import com.amorphie.core.feature.enverify.EnverifyActivity

import com.amorphie.core.util.Nlog
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine


class MainActivity : FlutterFragmentActivity() {

    private val methodHandler: MethodChannelHandler by lazy {
        MethodChannelHandler(FlutterEngine(this)).also {
            moveTaskToBack(true)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?, persistentState: PersistableBundle?) {
        super.onCreate(savedInstanceState, persistentState)
        //setContentView(R.layout.activity_sample)
        methodHandler.setListener(object : MethodChannelListener {
            override fun onEnverifySDKPrepared(config: String) {
                navigateToEnverify()
            }
        })
    }

    private fun navigateToEnverify() {
        val intent = Intent(this, EnverifyActivity::class.java)
        startActivity(intent)
    }
}


