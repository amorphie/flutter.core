package com.amorphie.core

import android.content.Intent
import android.os.Bundle
import android.os.PersistableBundle
import com.amorphie.core.feature.enverify.EnverifyActivity
import io.flutter.embedding.android.FlutterActivity


class MainActivity : FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?, persistentState: PersistableBundle?) {
        super.onCreate(savedInstanceState, persistentState)
        val intent = Intent(this, EnverifyActivity::class.java)
        startActivity(intent)

    }
}


