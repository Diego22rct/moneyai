package com.github.diego22rct.moneyai.capture

import android.content.Context
import android.content.pm.ApplicationInfo

/**
 * Local preferences for wallet notification capture.
 *
 * Stored in private SharedPreferences so the [MoneyAiNotificationListener] can read them
 * even when the Flutter engine is not running.
 */
class CapturePrefs(context: Context) {
    private val appContext = context.applicationContext
    private val prefs = appContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    var enabled: Boolean
        get() = prefs.getBoolean(KEY_ENABLED, true)
        set(value) {
            prefs.edit().putBoolean(KEY_ENABLED, value).apply()
        }

    var allowedPackages: Set<String>
        get() = prefs.getStringSet(KEY_PACKAGES, null)?.toSet() ?: DEFAULT_PACKAGES
        set(value) {
            prefs.edit().putStringSet(KEY_PACKAGES, value.toSet()).apply()
        }

    /**
     * Packages actually listened to. Debuggable builds also accept notifications posted
     * from `adb shell cmd notification post ...` to allow manual testing.
     */
    fun effectiveAllowedPackages(): Set<String> {
        val isDebuggable = (appContext.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
        return if (isDebuggable) allowedPackages + ADB_SHELL_PACKAGE else allowedPackages
    }

    companion object {
        private const val PREFS_NAME = "moneyai_notification_capture"
        private const val KEY_ENABLED = "enabled"
        private const val KEY_PACKAGES = "allowed_packages"
        private const val ADB_SHELL_PACKAGE = "com.android.shell"

        val DEFAULT_PACKAGES: Set<String> = setOf(
            "com.google.android.apps.walletnfcrel", // Google Wallet
            "com.google.android.apps.nbu.paisa.user", // Google Pay
        )
    }
}
