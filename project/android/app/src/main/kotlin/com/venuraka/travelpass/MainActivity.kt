package com.venuraka.travelpass

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.pm.PackageManager
import android.os.Build
import java.security.MessageDigest
import java.util.Locale

class MainActivity : FlutterActivity() {

    private val CONFIG_CHANNEL = "com.travelpass.app/config"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 🔑 Config Channel — reads secrets from AndroidManifest meta-data at runtime
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CONFIG_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getGoogleMapsApiKey" -> {
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
                    }
                    "getOpenWeatherApiKey" -> {
                        try {
                            val appInfo = packageManager.getApplicationInfo(
                                packageName,
                                PackageManager.GET_META_DATA
                            )
                            val key = appInfo.metaData?.getString("com.travelpass.OPEN_WEATHER_API_KEY") ?: ""
                            result.success(key)
                        } catch (e: Exception) {
                            result.error("NOT_FOUND", "OpenWeather API key not found in AndroidManifest", null)
                        }
                    }
                    "getPayhereMerchantId" -> {
                        try {
                            val appInfo = packageManager.getApplicationInfo(
                                packageName,
                                PackageManager.GET_META_DATA
                            )
                            val key = appInfo.metaData?.getString("com.travelpass.PAYHERE_MERCHANT_ID") ?: ""
                            result.success(key)
                        } catch (e: Exception) {
                            result.error("NOT_FOUND", "Payhere Merchant ID not found", null)
                        }
                    }
                    "getPayhereMerchantSecret" -> {
                        try {
                            val appInfo = packageManager.getApplicationInfo(
                                packageName,
                                PackageManager.GET_META_DATA
                            )
                            val key = appInfo.metaData?.getString("com.travelpass.PAYHERE_MERCHANT_SECRET") ?: ""
                            result.success(key)
                        } catch (e: Exception) {
                            result.error("NOT_FOUND", "Payhere Merchant Secret not found", null)
                        }
                    }
                    "getAndroidCertificateHash" -> {
                        val hash = getCertificateFingerprint(packageManager, packageName)
                        if (hash != null) {
                            result.success(hash)
                        } else {
                            result.error("NOT_FOUND", "Could not retrieve certificate hash", null)
                        }
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
    }

    private fun getCertificateFingerprint(packageManager: PackageManager, packageName: String): String? {
        try {
            val packageInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNING_CERTIFICATES)
            } else {
                @Suppress("DEPRECATION")
                packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNATURES)
            }

            val signatures = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                packageInfo.signingInfo?.signingCertificateHistory
            } else {
                @Suppress("DEPRECATION")
                packageInfo.signatures
            }

            if (signatures == null) return null

            for (signature in signatures) {
                val md = MessageDigest.getInstance("SHA-1")
                val publicKey = md.digest(signature.toByteArray())
                val hexString = StringBuilder()
                for (aPublicKey in publicKey) {
                    val appendString = Integer.toHexString(0xFF and aPublicKey.toInt()).uppercase(Locale.US)
                    if (appendString.length == 1) hexString.append("0")
                    hexString.append(appendString)
                }
                return hexString.toString().lowercase(Locale.US)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return null
    }
}
