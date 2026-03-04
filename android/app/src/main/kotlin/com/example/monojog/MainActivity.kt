package com.example.monojog

import android.app.AppOpsManager
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
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

        // ─────────────────────────────
        // Blocked Apps Channel
        // ─────────────────────────────
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

        // ─────────────────────────────
        // Focus Channel
        // ─────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, FOCUS_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    // ── Installed Apps ──
                    "getInstalledApps" -> {
                        try {
                            val pm = packageManager
                            val packages = pm.getInstalledApplications(0)

                            val appList = packages
                                .filter {
                                    pm.getLaunchIntentForPackage(it.packageName) != null &&
                                            it.packageName != packageName  // Exclude self
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

                    // ── All Permission Check ──
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

                    // ── Check All Required Permissions ──
                    "hasAllBlockingPermissions" -> {
                        val hasAll = hasUsageStatsPermission() &&
                                Settings.canDrawOverlays(this) &&
                                isAccessibilityEnabled()
                        result.success(hasAll)
                    }

                    // ── Request Usage Permission ──
                    "requestUsagePermission" -> {
                        try {
                            val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("ERROR", "Cannot open usage settings: ${e.message}", null)
                        }
                    }

                    // ── Request Overlay ──
                    "requestOverlayPermission" -> {
                        try {
                            if (!Settings.canDrawOverlays(this)) {
                                val intent = Intent(
                                    Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                    Uri.parse("package:$packageName")
                                )
                                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                startActivity(intent)
                            }
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("ERROR", "Cannot open overlay settings: ${e.message}", null)
                        }
                    }

                    // ── Open Accessibility ──
                    "openAccessibilitySettings" -> {
                        try {
                            val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("ERROR", "Cannot open accessibility settings: ${e.message}", null)
                        }
                    }

                    // ── Request DND Permission ──
                    "requestDndPermission" -> {
                        try {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                                val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                                if (!nm.isNotificationPolicyAccessGranted) {
                                    val intent = Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
                                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                    startActivity(intent)
                                }
                            }
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("ERROR", "Cannot open DND settings: ${e.message}", null)
                        }
                    }

                    // ── Enable DND ──
                    "enableDND" -> {
                        enableDnd()
                        result.success(true)
                    }

                    // ── Disable DND ──
                    "disableDND" -> {
                        disableDnd()
                        result.success(true)
                    }

                    // ── Start Focus Mode ──
                    "startFocusMode" -> {
                        try {
                            val args = call.arguments as Map<*, *>
                            val blockedApps = args["blockedApps"] as List<String>
                            val duration = args["durationMinutes"] as Int

                            // Save blocked apps
                            BlockedAppsStorage.saveBlockedApps(this, blockedApps)

                            // Set focus active with end time
                            BlockedAppsStorage.setFocusActive(this, true)
                            val endTime = System.currentTimeMillis() + (duration * 60 * 1000L)
                            BlockedAppsStorage.setFocusEndTime(this, endTime)

                            result.success(true)
                        } catch (e: Exception) {
                            result.error("ERROR", "Failed to start focus: ${e.message}", null)
                        }
                    }

                    // ── Stop Focus Mode ──
                    "stopFocusMode" -> {
                        BlockedAppsStorage.setFocusActive(this, false)
                        BlockedAppsStorage.setFocusEndTime(this, 0L)
                        result.success(true)
                    }

                    // ── Check Focus State ──
                    "isFocusActive" -> {
                        result.success(BlockedAppsStorage.isFocusActive(this))
                    }

                    // ── Widget Sync ──
                    "updateHomeWidget" -> {
                        result.success(true)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    // ═══════════════════════════════
    // PERMISSION HELPERS
    // ═══════════════════════════════

    private fun hasUsageStatsPermission(): Boolean {
        return try {
            val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
            val mode = appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName
            )
            mode == AppOpsManager.MODE_ALLOWED
        } catch (e: Exception) {
            false
        }
    }

    private fun isAccessibilityEnabled(): Boolean {
        return try {
            val expectedComponent =
                "$packageName/${AppBlockAccessibilityService::class.java.canonicalName}"

            val enabledServices = Settings.Secure.getString(
                contentResolver,
                Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
            ) ?: return false

            enabledServices.contains(expectedComponent)
        } catch (e: Exception) {
            false
        }
    }

    private fun hasDndPermission(): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                nm.isNotificationPolicyAccessGranted
            } else true
        } catch (e: Exception) {
            false
        }
    }

    // ═══════════════════════════════
    // DND CONTROL
    // ═══════════════════════════════

    private fun enableDnd() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (nm.isNotificationPolicyAccessGranted) {
                nm.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_NONE)
            } else {
                val intent = Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
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