package com.example.monojog

import android.content.Context

object BlockedAppsStorage {

    private const val PREF_NAME = "blocked_apps_prefs"
    private const val KEY_BLOCKED_APPS = "blocked_apps"

    fun saveBlockedApps(context: Context, apps: List<String>) {
        val prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
        prefs.edit().putStringSet(KEY_BLOCKED_APPS, apps.toSet()).apply()
    }

    fun getBlockedApps(context: Context): Set<String> {
        val prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
        return prefs.getStringSet(KEY_BLOCKED_APPS, emptySet()) ?: emptySet()
    }
}