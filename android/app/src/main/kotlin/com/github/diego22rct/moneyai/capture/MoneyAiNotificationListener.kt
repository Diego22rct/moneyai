package com.github.diego22rct.moneyai.capture

import android.app.Notification
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log

/**
 * Listens to notifications from allowlisted wallet apps (Google Wallet / Google Pay first)
 * and queues them locally in [NotificationInboxStore].
 *
 * Bound by the system once the user grants Notification access, so it keeps working
 * while the Flutter UI is closed. No parsing happens here: the raw text is handed to Dart.
 */
class MoneyAiNotificationListener : NotificationListenerService() {

    override fun onListenerConnected() {
        super.onListenerConnected()
        // Catch notifications posted while the listener was unbound (e.g. after a force-stop).
        // Already-queued ones are ignored by the dedupe hash.
        try {
            activeNotifications?.forEach { capture(it) }
        } catch (error: Exception) {
            Log.w(TAG, "Unable to scan active notifications", error)
        }
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        if (sbn == null) return
        try {
            capture(sbn)
        } catch (error: Exception) {
            Log.w(TAG, "Unable to capture notification", error)
        }
    }

    private fun capture(sbn: StatusBarNotification) {
        if (sbn.packageName == packageName) return

        val prefs = CapturePrefs(this)
        if (!prefs.enabled || sbn.packageName !in prefs.effectiveAllowedPackages()) return

        val notification = sbn.notification ?: return
        if (notification.flags and Notification.FLAG_GROUP_SUMMARY != 0) return
        if (sbn.isOngoing) return

        val extras = notification.extras ?: return
        val title = (
            extras.getCharSequence(Notification.EXTRA_TITLE_BIG)
                ?: extras.getCharSequence(Notification.EXTRA_TITLE)
            )?.toString()?.trim().orEmpty()

        val lines = extras.getCharSequenceArray(Notification.EXTRA_TEXT_LINES)
            ?.joinToString("\n") { it.toString() }
        val text = (
            extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString()
                ?: lines
                ?: extras.getCharSequence(Notification.EXTRA_TEXT)?.toString()
            )?.trim().orEmpty()

        if (title.isBlank() && text.isBlank()) return

        val postedAt = if (notification.`when` > 0) notification.`when` else sbn.postTime
        val inserted = NotificationInboxStore.get(this).insert(
            packageName = sbn.packageName,
            title = title,
            text = text,
            subText = extras.getCharSequence(Notification.EXTRA_SUB_TEXT)?.toString(),
            postedAt = postedAt,
            notificationKey = sbn.key,
        )

        if (inserted) {
            CaptureEventBus.emit()
        }
    }

    companion object {
        private const val TAG = "MoneyAiCapture"
    }
}
