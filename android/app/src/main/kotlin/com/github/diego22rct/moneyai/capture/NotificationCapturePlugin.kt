package com.github.diego22rct.moneyai.capture

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.service.notification.NotificationListenerService
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/**
 * Platform channels exposing the native capture queue and settings to Dart.
 *
 * MethodChannel `moneyai/notification_capture`:
 *  - isAccessGranted, openAccessSettings, openAppDetails
 *  - fetchPending {limit}, acknowledge {ids}
 *  - getConfig, configure {enabled, packages}
 * EventChannel `moneyai/notification_capture/events`: ping when a new capture is queued.
 */
object NotificationCapturePlugin {
    private const val METHOD_CHANNEL = "moneyai/notification_capture"
    private const val EVENT_CHANNEL = "moneyai/notification_capture/events"

    private val ioExecutor: ExecutorService = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    fun register(context: Context, messenger: BinaryMessenger) {
        val appContext = context.applicationContext

        MethodChannel(messenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            handle(appContext, call, result)
        }

        EventChannel(messenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    CaptureEventBus.attach(events)
                }

                override fun onCancel(arguments: Any?) {
                    CaptureEventBus.detach()
                }
            },
        )

        if (isAccessGranted(appContext)) {
            requestRebind(appContext)
        }
    }

    private fun handle(context: Context, call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isAccessGranted" -> result.success(isAccessGranted(context))

            "openAccessSettings" -> {
                openAccessSettings(context)
                result.success(null)
            }

            "openAppDetails" -> {
                val intent = Intent(
                    Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                    Uri.fromParts("package", context.packageName, null),
                ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                context.startActivity(intent)
                result.success(null)
            }

            "fetchPending" -> {
                val limit = call.argument<Int>("limit") ?: 100
                runIo(result) { NotificationInboxStore.get(context).fetchPending(limit) }
            }

            "acknowledge" -> {
                val ids = call.argument<List<*>>("ids")
                    ?.mapNotNull { (it as? Number)?.toLong() }
                    .orEmpty()
                runIo(result) {
                    NotificationInboxStore.get(context).delete(ids)
                    null
                }
            }

            "getConfig" -> {
                val prefs = CapturePrefs(context)
                result.success(
                    mapOf(
                        "enabled" to prefs.enabled,
                        "packages" to prefs.allowedPackages.toList(),
                    ),
                )
            }

            "configure" -> {
                val prefs = CapturePrefs(context)
                call.argument<Boolean>("enabled")?.let { prefs.enabled = it }
                call.argument<List<*>>("packages")?.let { packages ->
                    prefs.allowedPackages = packages.filterIsInstance<String>().toSet()
                }
                if (prefs.enabled && isAccessGranted(context)) {
                    requestRebind(context)
                }
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    private fun runIo(result: MethodChannel.Result, block: () -> Any?) {
        ioExecutor.execute {
            try {
                val value = block()
                mainHandler.post { result.success(value) }
            } catch (error: Exception) {
                mainHandler.post { result.error("capture_store_error", error.message, null) }
            }
        }
    }

    private fun listenerComponent(context: Context): ComponentName =
        ComponentName(context, MoneyAiNotificationListener::class.java)

    private fun isAccessGranted(context: Context): Boolean {
        val enabled = Settings.Secure.getString(
            context.contentResolver,
            "enabled_notification_listeners",
        ) ?: return false
        val component = listenerComponent(context)
        return enabled.split(":").any { entry ->
            ComponentName.unflattenFromString(entry) == component
        }
    }

    private fun openAccessSettings(context: Context) {
        val detailIntent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            Intent(Settings.ACTION_NOTIFICATION_LISTENER_DETAIL_SETTINGS).putExtra(
                Settings.EXTRA_NOTIFICATION_LISTENER_COMPONENT_NAME,
                listenerComponent(context).flattenToString(),
            )
        } else {
            null
        }

        val fallbackIntent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)

        val intent = (detailIntent ?: fallbackIntent).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        try {
            context.startActivity(intent)
        } catch (_: Exception) {
            context.startActivity(fallbackIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        }
    }

    private fun requestRebind(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            try {
                NotificationListenerService.requestRebind(listenerComponent(context))
            } catch (_: Exception) {
                // Best effort: the system binds the listener on its own when access is granted.
            }
        }
    }
}
