package com.hepsiradyo.hepsiradyo

import android.os.Build
import android.os.Bundle
import android.view.Display
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableHighRefreshRate()
    }

    private fun enableHighRefreshRate() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val display = display
            if (display != null) {
                val modes = display.supportedModes
                var maxMode: Display.Mode? = null
                var maxFps = 0f
                for (mode in modes) {
                    if (mode.refreshRate > maxFps) {
                        maxFps = mode.refreshRate
                        maxMode = mode
                    }
                }
                if (maxMode != null) {
                    val layoutParams = window.attributes
                    layoutParams.preferredDisplayModeId = maxMode.modeId
                    window.attributes = layoutParams
                }
            }
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val layoutParams = window.attributes
            layoutParams.preferredRefreshRate = 120f
            window.attributes = layoutParams
        }
    }
}
