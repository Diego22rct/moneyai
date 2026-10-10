package com.github.diego22rct.moneyai.capture

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel

/**
 * Bridges "new capture queued" pings from the listener to Flutter while the engine is alive.
 * When no engine is attached, [emit] is a no-op; Flutter will drain the queue on next start.
 */
object CaptureEventBus {
    private val mainHandler = Handler(Looper.getMainLooper())

    @Volatile
    private var sink: EventChannel.EventSink? = null

    fun attach(eventSink: EventChannel.EventSink) {
        sink = eventSink
    }

    fun detach() {
        sink = null
    }

    fun emit() {
        mainHandler.post { sink?.success("new_capture") }
    }
}
