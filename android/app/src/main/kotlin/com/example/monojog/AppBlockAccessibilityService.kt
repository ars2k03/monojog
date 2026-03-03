package com.example.monojog

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.content.Intent

class AppBlockAccessibilityService : AccessibilityService() {

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {

        if (event?.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED)
            return

        val packageName = event.packageName?.toString() ?: return

        android.util.Log.d("APP_BLOCKER", "Opened app: $packageName")

        if (isBlocked(packageName)) {
            android.util.Log.d("APP_BLOCKER", "BLOCKING: $packageName")

            val intent = Intent(this, BlockActivity::class.java)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
        }
    }

    override fun onInterrupt() {}

    private fun isBlocked(packageName: String): Boolean {
        val blockedApps = BlockedAppsStorage.getBlockedApps(this)
        return blockedApps.contains(packageName)
    }
}