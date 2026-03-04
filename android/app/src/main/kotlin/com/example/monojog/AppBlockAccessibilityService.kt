package com.example.monojog

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Intent
import android.util.Log
import android.view.accessibility.AccessibilityEvent

class AppBlockAccessibilityService : AccessibilityService() {

    companion object {
        private const val TAG = "APP_BLOCKER"

        private val SYSTEM_PACKAGES = setOf(
            "com.android.systemui",
            "com.android.launcher",
            "com.android.launcher3",
            "com.google.android.apps.nexuslauncher",
            "com.motorola.launcher3",
            "com.android.settings",
            "com.android.dialer",
            "com.android.phone",
            "com.android.server.telecom",
            "com.android.incallui",
            "com.android.emergency",
            "com.android.providers.telephony",
            "com.android.stk",
            "com.google.android.dialer",
            "com.google.android.packageinstaller",
            "com.android.packageinstaller",
            "com.android.permissioncontroller",
            "com.google.android.permissioncontroller",
            "com.android.vending",
        )

        private val SAFE_PREFIXES = listOf(
            "com.android.systemui",
            "com.android.launcher",
            "com.motorola.launcher",
            "com.android.settings",
            "com.android.providers",
            "android",
        )
    }

    private var lastBlockedTime: Long = 0
    private var lastBlockedPackage: String = ""

    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.d(TAG, "✅ onServiceConnected called!")

        // ═══════════════════════════════════════════
        // THIS IS THE KEY!
        // Force-set service config programmatically
        // XML config alone is NOT reliable on all devices
        // ═══════════════════════════════════════════
        try {
            val info = serviceInfo ?: AccessibilityServiceInfo()
            info.eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
            info.feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            info.flags = AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS or
                    AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS
            info.notificationTimeout = 100
            // packageNames intentionally NOT set = monitor ALL apps
            serviceInfo = info
            Log.d(TAG, "✅ Service configured! eventTypes=${info.eventTypes}, feedbackType=${info.feedbackType}")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to configure: ${e.message}")
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return

        val packageName = event.packageName?.toString() ?: return

        Log.d(TAG, "📱 Window → $packageName")

        // 1️⃣ Skip own app
        if (packageName == applicationContext.packageName) return

        // 2️⃣ Skip system apps
        if (isSystemApp(packageName)) return

        // 3️⃣ Skip BlockActivity loop
        if (packageName.contains("BlockActivity")) return

        // 4️⃣ Check focus active
        val focusActive = BlockedAppsStorage.isFocusActive(this)
        if (!focusActive) {
            // Don't spam logs — only log once per app
            return
        }

        // 5️⃣ Check blocked list
        val blockedApps = BlockedAppsStorage.getBlockedApps(this)
        if (!blockedApps.contains(packageName)) return

        // 6️⃣ Debounce 1.5s
        val now = System.currentTimeMillis()
        if (packageName == lastBlockedPackage && (now - lastBlockedTime) < 1500) return

        lastBlockedPackage = packageName
        lastBlockedTime = now

        Log.d(TAG, "🚫 BLOCKING: $packageName")

        val intent = Intent(this, BlockActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            putExtra("blocked_package", packageName)
        }
        startActivity(intent)
    }

    private fun isSystemApp(packageName: String): Boolean {
        if (SYSTEM_PACKAGES.contains(packageName)) return true
        return SAFE_PREFIXES.any { packageName.startsWith(it) }
    }

    override fun onInterrupt() {
        Log.w(TAG, "⚠️ Service interrupted")
    }
}