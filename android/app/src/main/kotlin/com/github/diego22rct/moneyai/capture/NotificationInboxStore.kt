package com.github.diego22rct.moneyai.capture

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import java.security.MessageDigest

/**
 * Transient on-device queue of raw wallet notifications.
 *
 * The listener writes here (works even when the app is killed). Flutter drains the queue
 * through [NotificationCapturePlugin] and acknowledges (deletes) processed rows.
 * Nothing in this store ever leaves the device.
 */
class NotificationInboxStore private constructor(context: Context) :
    SQLiteOpenHelper(context.applicationContext, DB_NAME, null, DB_VERSION) {

    override fun onCreate(db: SQLiteDatabase) {
        db.execSQL(
            """
            CREATE TABLE $TABLE (
                $COL_ID INTEGER PRIMARY KEY AUTOINCREMENT,
                $COL_PACKAGE TEXT NOT NULL,
                $COL_TITLE TEXT,
                $COL_TEXT TEXT,
                $COL_SUB_TEXT TEXT,
                $COL_POSTED_AT INTEGER NOT NULL,
                $COL_KEY TEXT,
                $COL_HASH TEXT NOT NULL UNIQUE,
                $COL_RECEIVED_AT INTEGER NOT NULL
            )
            """.trimIndent(),
        )
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
        // v1 only. Future migrations go here.
    }

    /**
     * Inserts a notification unless an equivalent one was already queued.
     *
     * The dedupe hash ignores the notification key and uses a 2-minute time bucket so
     * re-posted/updated notifications collapse into one row, while two identical
     * purchases a few minutes apart are still captured separately.
     *
     * @return true when a new row was inserted.
     */
    @Synchronized
    fun insert(
        packageName: String,
        title: String,
        text: String,
        subText: String?,
        postedAt: Long,
        notificationKey: String?,
    ): Boolean {
        val bucket = postedAt / DEDUPE_BUCKET_MS
        val hash = sha256("$packageName|$title|$text|$bucket")
        val values = ContentValues().apply {
            put(COL_PACKAGE, packageName)
            put(COL_TITLE, title)
            put(COL_TEXT, text)
            put(COL_SUB_TEXT, subText)
            put(COL_POSTED_AT, postedAt)
            put(COL_KEY, notificationKey)
            put(COL_HASH, hash)
            put(COL_RECEIVED_AT, System.currentTimeMillis())
        }
        val db = writableDatabase
        val id = db.insertWithOnConflict(TABLE, null, values, SQLiteDatabase.CONFLICT_IGNORE)
        if (id > 0) {
            trimQueue(db)
        }
        return id > 0
    }

    @Synchronized
    fun fetchPending(limit: Int): List<Map<String, Any?>> {
        val rows = mutableListOf<Map<String, Any?>>()
        readableDatabase.query(
            TABLE,
            null,
            null,
            null,
            null,
            null,
            "$COL_ID ASC",
            limit.coerceIn(1, MAX_ROWS).toString(),
        ).use { cursor ->
            while (cursor.moveToNext()) {
                rows.add(
                    mapOf(
                        "id" to cursor.getLong(cursor.getColumnIndexOrThrow(COL_ID)),
                        "packageName" to cursor.getString(cursor.getColumnIndexOrThrow(COL_PACKAGE)),
                        "title" to cursor.getString(cursor.getColumnIndexOrThrow(COL_TITLE)),
                        "text" to cursor.getString(cursor.getColumnIndexOrThrow(COL_TEXT)),
                        "subText" to cursor.getString(cursor.getColumnIndexOrThrow(COL_SUB_TEXT)),
                        "postedAt" to cursor.getLong(cursor.getColumnIndexOrThrow(COL_POSTED_AT)),
                        "dedupeKey" to cursor.getString(cursor.getColumnIndexOrThrow(COL_HASH)),
                    ),
                )
            }
        }
        return rows
    }

    @Synchronized
    fun delete(ids: List<Long>) {
        if (ids.isEmpty()) return
        val db = writableDatabase
        db.beginTransaction()
        try {
            ids.forEach { id ->
                db.delete(TABLE, "$COL_ID = ?", arrayOf(id.toString()))
            }
            db.setTransactionSuccessful()
        } finally {
            db.endTransaction()
        }
    }

    private fun trimQueue(db: SQLiteDatabase) {
        db.execSQL(
            "DELETE FROM $TABLE WHERE $COL_ID NOT IN " +
                "(SELECT $COL_ID FROM $TABLE ORDER BY $COL_ID DESC LIMIT $MAX_ROWS)",
        )
    }

    private fun sha256(value: String): String {
        val digest = MessageDigest.getInstance("SHA-256").digest(value.toByteArray(Charsets.UTF_8))
        return digest.joinToString("") { "%02x".format(it) }
    }

    companion object {
        private const val DB_NAME = "notification_inbox.db"
        private const val DB_VERSION = 1
        private const val TABLE = "raw_notifications"
        private const val COL_ID = "id"
        private const val COL_PACKAGE = "package_name"
        private const val COL_TITLE = "title"
        private const val COL_TEXT = "text"
        private const val COL_SUB_TEXT = "sub_text"
        private const val COL_POSTED_AT = "posted_at"
        private const val COL_KEY = "notification_key"
        private const val COL_HASH = "dedupe_hash"
        private const val COL_RECEIVED_AT = "received_at"
        private const val MAX_ROWS = 500
        private const val DEDUPE_BUCKET_MS = 2 * 60 * 1000L

        @Volatile
        private var instance: NotificationInboxStore? = null

        fun get(context: Context): NotificationInboxStore =
            instance ?: synchronized(this) {
                instance ?: NotificationInboxStore(context).also { instance = it }
            }
    }
}
