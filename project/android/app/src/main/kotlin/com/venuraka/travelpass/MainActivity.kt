package com.venuraka.travelpass

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.pm.PackageManager

class MainActivity : FlutterActivity() {

    private val CONFIG_CHANNEL = "com.travelpass.app/config"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 🔑 Config Channel — reads secrets from AndroidManifest meta-data at runtime
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CONFIG_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "getGoogleMapsApiKey") {
                    try {
                        val appInfo = packageManager.getApplicationInfo(
                            packageName,
                            PackageManager.GET_META_DATA
                        )
                        val key = appInfo.metaData?.getString("com.google.android.geo.API_KEY") ?: ""
                        result.success(key)
                    } catch (e: Exception) {
                        result.error("NOT_FOUND", "Google Maps API key not found in AndroidManifest", null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }
}
