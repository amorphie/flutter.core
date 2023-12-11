package com.amorphie.core

import android.content.Intent
import android.os.Bundle
import android.os.PersistableBundle
import androidx.annotation.NonNull
import com.amorphie.core.feature.common.MethodChannelHandler
import com.amorphie.core.feature.common.MethodChannelListener
import com.amorphie.core.feature.enverify.SampleActivity
import com.amorphie.core.util.Nlog
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine


class MainActivity : FlutterFragmentActivity() {

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannelHandler(engine = flutterEngine).let {
            it.setListener(object : MethodChannelListener {
                override fun onEnverifySDKPrepared(config: String) {
                    Nlog.x("Native Method Call: onEnverifySDKPrepared $config - ${Thread.currentThread().name}")
                    this@MainActivity.navigateToEnverify()
                }
            })
        }
    }


    override fun onCreate(savedInstanceState: Bundle?, persistentState: PersistableBundle?) {
        super.onCreate(savedInstanceState, persistentState)
        setContentView(R.layout.activity_sample)

    }

    private fun navigateToEnverify() {
        val intent = Intent(this, SampleActivity::class.java)
        startActivity(intent)
    }
}


