package com.gongsin.app

import android.app.*
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.os.*
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.widget.TextView
import androidx.core.app.NotificationCompat

class AppBlockingService : Service() {

    companion object {
        const val ACTION_START = "com.gongsin.app.START_BLOCKING"
        const val ACTION_STOP = "com.gongsin.app.STOP_BLOCKING"
        const val ACTION_UPDATE_WHITELIST = "com.gongsin.app.UPDATE_WHITELIST"
        const val NOTIFICATION_CHANNEL_ID = "gongsin_focus_mode"
        const val NOTIFICATION_ID = 1001
        private const val CHECK_INTERVAL_MS = 1000L
    }

    private var whitelistedPackages = mutableSetOf<String>()
    private var handler: Handler? = null
    private var checkRunnable: Runnable? = null
    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private var isOverlayShowing = false

    // Always allow these system apps
    private val systemWhitelist = setOf(
        "com.android.dialer",
        "com.samsung.android.dialer",
        "com.android.mms",
        "com.samsung.android.messaging",
        "com.android.deskclock",
        "com.sec.android.app.clockpackage",
        "com.android.calculator2",
        "com.sec.android.app.popupcalculator",
        "com.android.calendar",
        "com.samsung.android.calendar",
        "com.android.settings",
        "com.gongsin.app", // Our own app
    )

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        handler = Handler(Looper.getMainLooper())
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                startForeground(NOTIFICATION_ID, buildNotification())
                startMonitoring()
            }
            ACTION_STOP -> {
                stopMonitoring()
                hideOverlay()
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
            }
            ACTION_UPDATE_WHITELIST -> {
                val packages = intent.getStringArrayListExtra("packages") ?: arrayListOf()
                whitelistedPackages.clear()
                whitelistedPackages.addAll(packages)
                whitelistedPackages.addAll(systemWhitelist)
            }
        }
        return START_STICKY
    }

    private fun startMonitoring() {
        checkRunnable = object : Runnable {
            override fun run() {
                checkForegroundApp()
                handler?.postDelayed(this, CHECK_INTERVAL_MS)
            }
        }
        handler?.post(checkRunnable!!)
    }

    private fun stopMonitoring() {
        checkRunnable?.let { handler?.removeCallbacks(it) }
        checkRunnable = null
    }

    private fun checkForegroundApp() {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val endTime = System.currentTimeMillis()
        val beginTime = endTime - 5000

        val usageStats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_BEST, beginTime, endTime
        )

        if (usageStats.isNullOrEmpty()) return

        val currentApp = usageStats
            .filter { it.lastTimeUsed > 0 }
            .maxByOrNull { it.lastTimeUsed }
            ?.packageName ?: return

        val allWhitelisted = whitelistedPackages + systemWhitelist

        if (!allWhitelisted.contains(currentApp)) {
            showOverlay()
        } else {
            hideOverlay()
        }
    }

    private fun showOverlay() {
        if (isOverlayShowing) return
        if (!android.provider.Settings.canDrawOverlays(this)) return

        try {
            val params = WindowManager.LayoutParams(
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.MATCH_PARENT,
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                else
                    @Suppress("DEPRECATION")
                    WindowManager.LayoutParams.TYPE_PHONE,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                        WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                        WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
                PixelFormat.TRANSLUCENT
            )
            params.gravity = Gravity.CENTER

            overlayView = createOverlayView()
            windowManager?.addView(overlayView, params)
            isOverlayShowing = true
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun createOverlayView(): View {
        val view = View(this)
        view.setBackgroundColor(0xF0F8F7FC.toInt()) // Light pastel background

        // Using a simple approach - in production, use a proper layout
        val textView = TextView(this).apply {
            text = "지금은 집중 시간이에요\n\n공신 앱으로 돌아가서\n공부를 계속하세요 💪"
            textSize = 18f
            setTextColor(0xFF2D2D3A.toInt())
            gravity = Gravity.CENTER
            setPadding(48, 48, 48, 48)
        }

        // Wrap in a simple layout
        val layout = android.widget.FrameLayout(this)
        layout.setBackgroundColor(0xF0F8F7FC.toInt())
        layout.addView(textView, android.widget.FrameLayout.LayoutParams(
            android.widget.FrameLayout.LayoutParams.WRAP_CONTENT,
            android.widget.FrameLayout.LayoutParams.WRAP_CONTENT,
            Gravity.CENTER
        ))

        layout.setOnClickListener {
            // Open Gongsin app when overlay is tapped
            val intent = packageManager.getLaunchIntentForPackage(packageName)
            intent?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
        }

        return layout
    }

    private fun hideOverlay() {
        if (!isOverlayShowing) return
        try {
            overlayView?.let { windowManager?.removeView(it) }
            overlayView = null
            isOverlayShowing = false
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "집중 모드",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "집중 모드가 활성화되어 있습니다"
                setShowBadge(false)
            }
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(): Notification {
        val pendingIntent = PendingIntent.getActivity(
            this, 0,
            packageManager.getLaunchIntentForPackage(packageName),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setContentTitle("공신 집중 모드")
            .setContentText("허용된 앱만 사용할 수 있습니다")
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setOngoing(true)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    override fun onDestroy() {
        stopMonitoring()
        hideOverlay()
        super.onDestroy()
    }
}
