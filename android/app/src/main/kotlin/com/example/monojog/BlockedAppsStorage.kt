package com.example.monojog

import android.content.Context

object BlockedAppsStorage {

    private const val PREF_NAME = "blocked_apps_prefs"
    private const val KEY_BLOCKED_APPS = "blocked_apps"
    private const val KEY_FOCUS_ACTIVE = "focus_active"
    private const val KEY_FOCUS_END_TIME = "focus_end_time"

    // ── Blocked Apps ──

    fun saveBlockedApps(context: Context, apps: List<String>) {
        val prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
        prefs.edit().putStringSet(KEY_BLOCKED_APPS, apps.toSet()).apply()
    }

    fun getBlockedApps(context: Context): Set<String> {
        val prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
        return prefs.getStringSet(KEY_BLOCKED_APPS, emptySet()) ?: emptySet()
    }

    // ── Focus State ──

    fun setFocusActive(context: Context, active: Boolean) {
        val prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
        prefs.edit().putBoolean(KEY_FOCUS_ACTIVE, active).apply()
    }

    fun isFocusActive(context: Context): Boolean {
        val prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
        val isActive = prefs.getBoolean(KEY_FOCUS_ACTIVE, false)

        // Auto-expire check
        if (isActive) {
            val endTime = prefs.getLong(KEY_FOCUS_END_TIME, 0L)
            if (endTime > 0 && System.currentTimeMillis() > endTime) {
                // Focus session expired — auto-deactivate
                setFocusActive(context, false)
                setFocusEndTime(context, 0L)
                return false
            }
        }
        return isActive
    }

    fun setFocusEndTime(context: Context, endTimeMillis: Long) {
        val prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
        prefs.edit().putLong(KEY_FOCUS_END_TIME, endTimeMillis).apply()
    }

    fun getFocusEndTime(context: Context): Long {
        val prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
        return prefs.getLong(KEY_FOCUS_END_TIME, 0L)
    }
}