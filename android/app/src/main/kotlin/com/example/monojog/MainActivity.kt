package com.example.monojog

import android.app.AppOpsManager
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Process
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val FOCUS_CHANNEL = "com.monojog.app/focus"
    private val BLOCK_CHANNEL = "com.monojog.app/blocker"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ---------------------------
        // Blocked Apps Channel
        // ---------------------------
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BLOCK_CHANNEL)
            .setMethodCallHandler { call, result ->

                when (call.method) {

                    "saveBlockedApps" -> {
                        val blockedApps = call.arguments as List<String>
                        BlockedAppsStorage.saveBlockedApps(this, blockedApps)
                        result.success(true)
                    }

                    else -> result.notImplemented()
                }
            }

        // ---------------------------
        // Focus Channel
        // ---------------------------
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, FOCUS_CHANNEL)
            .setMethodCallHandler { call, result ->

                when (call.method) {

                    // ---------------------------
                    // Installed Apps
                    // ---------------------------
                    "getInstalledApps" -> {
                        try {
                            val pm = packageManager
                            val packages = pm.getInstalledApplications(0)

                            val appList = packages
                                .filter {
                                    pm.getLaunchIntentForPackage(it.packageName) != null
                                }
                                .map {
                                    mapOf(
                                        "packageName" to it.packageName,
                                        "appName" to pm.getApplicationLabel(it).toString()
                                    )
                                }
                                .sortedBy { it["appName"].toString().lowercase() }

                            result.success(appList)

                        } catch (e: Exception) {
                            result.error("ERROR", e.message, null)
                        }
                    }

                    // ---------------------------
                    // Permission Check
                    // ---------------------------
                    "checkPermissions" -> {

                        result.success(
                            mapOf(
                                "hasUsagePermission" to hasUsageStatsPermission(),
                                "hasOverlayPermission" to Settings.canDrawOverlays(this),
                                "hasAccessibilityPermission" to isAccessibilityEnabled(),
                                "hasDndPermission" to hasDndPermission()
                            )
                        )
                    }

                    // ---------------------------
                    // Request Usage Permission
                    // ---------------------------
                    "requestUsagePermission" -> {
                        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        result.success(true)
                    }

                    // ---------------------------
                    // Request Overlay
                    // ---------------------------
                    "requestOverlayPermission" -> {
                        if (!Settings.canDrawOverlays(this)) {
                            val intent = Intent(
                                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                Uri.parse("package:$packageName")
                            )
                            startActivity(intent)
                        }
                        result.success(true)
                    }

                    // ---------------------------
                    // Open Accessibility
                    // ---------------------------
                    "openAccessibilitySettings" -> {
                        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        result.success(true)
                    }

                    // ---------------------------
                    // Enable DND
                    // ---------------------------
                    "enableDND" -> {
                        enableDnd()
                        result.success(true)
                    }

                    // ---------------------------
                    // Disable DND
                    // ---------------------------
                    "disableDND" -> {
                        disableDnd()
                        result.success(true)
                    }

                    // ---------------------------
                    // Start Focus Mode
                    // ---------------------------
                    "startFocusMode" -> {

                        val args = call.arguments as Map<*, *>
                        val blockedApps = args["blockedApps"] as List<String>
                        val duration = args["durationMinutes"] as Int

                        BlockedAppsStorage.saveBlockedApps(this, blockedApps)

                        val intent = Intent(this, AppBlockAccessibilityService::class.java)
                        intent.putExtra("focus_active", true)
                        intent.putExtra("duration", duration)
                        startService(intent)

                        result.success(true)
                    }

                    // ---------------------------
                    // Stop Focus Mode
                    // ---------------------------
                    "stopFocusMode" -> {
                        val intent = Intent(this, AppBlockAccessibilityService::class.java)
                        intent.putExtra("focus_active", false)
                        startService(intent)

                        result.success(true)
                    }

                    // ---------------------------
                    // Widget Sync
                    // ---------------------------
                    "updateHomeWidget" -> {
                        result.success(true)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    // ===============================
    // PERMISSION HELPERS
    // ===============================

    private fun hasUsageStatsPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOps.checkOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            Process.myUid(),
            packageName
        )
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun isAccessibilityEnabled(): Boolean {
        val expectedComponent =
            packageName + "/" + AppBlockAccessibilityService::class.java.canonicalName

        val enabledServices = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false

        return enabledServices.contains(expectedComponent)
    }

    private fun hasDndPermission(): Boolean {
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            nm.isNotificationPolicyAccessGranted
        } else true
    }

    // ===============================
    // DND CONTROL
    // ===============================

    private fun enableDnd() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            if (nm.isNotificationPolicyAccessGranted) {
                nm.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_NONE)
            } else {
                val intent = Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
                startActivity(intent)
            }
        }
    }

    private fun disableDnd() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_ALL)
        }
    }
}