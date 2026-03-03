package com.example.monojog

import android.app.Activity
import android.os.Bundle
import android.widget.TextView
import android.view.Gravity

class BlockActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val textView = TextView(this)
        textView.text = "🚫 This app is blocked!"
        textView.textSize = 24f
        textView.gravity = Gravity.CENTER

        setContentView(textView)
    }
}