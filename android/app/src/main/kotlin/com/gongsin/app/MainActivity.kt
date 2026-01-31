package com.gongsin.app

import android.app.AppOpsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Process
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.gongsin.app/blocking"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInstalledApps" -> {
                    result.success(getInstalledApps())
                }
                "hasUsagePermission" -> {
                    result.success(hasUsageStatsPermission())
                }
                "requestUsagePermission" -> {
                    requestUsageStatsPermission()
                    result.success(null)
                }
                "hasOverlayPermission" -> {
                    result.success(hasOverlayPermission())
                }
                "requestOverlayPermission" -> {
                    requestOverlayPermission()
                    result.success(null)
                }
                "startBlocking" -> {
                    startBlockingService()
                    result.success(null)
                }
                "stopBlocking" -> {
                    stopBlockingService()
                    result.success(null)
                }
                "updateWhitelist" -> {
                    val packages = call.argument<List<String>>("packages") ?: emptyList()
                    updateWhitelist(packages)
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun getInstalledApps(): List<Map<String, String>> {
        val pm = packageManager
        val apps = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.getInstalledApplications(PackageManager.ApplicationInfoFlags.of(0))
        } else {
            @Suppress("DEPRECATION")
            pm.getInstalledApplications(PackageManager.GET_META_DATA)
        }

        return apps
            .filter { app ->
                // Only show launchable apps (exclude system services)
                pm.getLaunchIntentForPackage(app.packageName) != null
            }
            .map { app ->
                mapOf(
                    "packageName" to app.packageName,
                    "appName" to pm.getApplicationLabel(app).toString()
                )
            }
            .sortedBy { it["appName"]?.lowercase() }
    }

    private fun hasUsageStatsPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOps.checkOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            Process.myUid(),
            packageName
        )
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun requestUsageStatsPermission() {
        startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
    }

    private fun hasOverlayPermission(): Boolean {
        return Settings.canDrawOverlays(this)
    }

    private fun requestOverlayPermission() {
        val intent = Intent(
            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
            Uri.parse("package:$packageName")
        )
        startActivity(intent)
    }

    private fun startBlockingService() {
        val intent = Intent(this, AppBlockingService::class.java).apply {
            action = AppBlockingService.ACTION_START
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun stopBlockingService() {
        val intent = Intent(this, AppBlockingService::class.java).apply {
            action = AppBlockingService.ACTION_STOP
        }
        startService(intent)
    }

    private fun updateWhitelist(packages: List<String>) {
        val intent = Intent(this, AppBlockingService::class.java).apply {
            action = AppBlockingService.ACTION_UPDATE_WHITELIST
            putStringArrayListExtra("packages", ArrayList(packages))
        }
        startService(intent)
    }
}
