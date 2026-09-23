package com.example.shared_upi_payment

import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.Drawable
import android.net.Uri
import android.util.Base64
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import java.io.ByteArrayOutputStream

class SharedUpiPaymentPlugin : FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.ActivityResultListener {
    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private var pendingResult: Result? = null

    private val UPI_PAYMENT_REQUEST_CODE = 2026

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "fam_ledge/upi")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getInstalledUpiApps" -> {
                try {
                    val apps = getInstalledUpiApps()
                    result.success(apps)
                } catch (e: Exception) {
                    result.error("ERROR", e.localizedMessage, null)
                }
            }
            "launchUpiPayment" -> {
                val upiUri = call.argument<String>("upiUri")
                val packageName = call.argument<String>("packageName")

                Log.d("SharedUpiPayment", "launchUpiPayment -> uri: $upiUri, package: $packageName")

                if (upiUri.isNullOrEmpty()) {
                    result.error("INVALID_ARGS", "UPI URI cannot be empty", null)
                    return
                }

                if (activity == null) {
                    result.error("NO_ACTIVITY", "Activity is not available", null)
                    return
                }

                try {
                    if (pendingResult != null) {
                        pendingResult?.error("CONCURRENT_CALL", "Another payment attempt is pending", null)
                        pendingResult = null
                    }

                    val intent = Intent(Intent.ACTION_VIEW, Uri.parse(upiUri))
                    intent.addCategory(Intent.CATEGORY_DEFAULT)

                    if (!packageName.isNullOrEmpty()) {
                        intent.setPackage(packageName)
                    } else {
                        intent.addCategory(Intent.CATEGORY_BROWSABLE)
                    }

                    pendingResult = result
                    activity?.startActivityForResult(intent, UPI_PAYMENT_REQUEST_CODE)
                } catch (e: Exception) {
                    pendingResult = null
                    Log.e("SharedUpiPayment", "Launch failed: ${e.localizedMessage}")
                    result.error("LAUNCH_FAILED", "Failed to launch UPI payment: ${e.localizedMessage}", null)
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun getInstalledUpiApps(): List<Map<String, String>> {
        if (activity == null) return emptyList()
        val pm = activity!!.packageManager
        
        val upiIntent = Intent(Intent.ACTION_VIEW, Uri.parse("upi://pay"))
        upiIntent.addCategory(Intent.CATEGORY_DEFAULT)
        
        val resolveInfoList = pm.queryIntentActivities(upiIntent, PackageManager.MATCH_DEFAULT_ONLY)

        val appList = mutableListOf<Map<String, String>>()
        val addedPackages = mutableSetOf<String>()

        for (info in resolveInfoList) {
            val packageName = info.activityInfo.packageName
            if (addedPackages.contains(packageName)) continue
            addedPackages.add(packageName)

            val appName = info.loadLabel(pm).toString()
            val appMap = mutableMapOf<String, String>(
                "packageName" to packageName,
                "appName" to appName
            )
            
            try {
                val iconDrawable = info.loadIcon(pm)
                val iconBase64 = drawableToBase64(iconDrawable)
                appMap["icon"] = iconBase64
            } catch (e: Exception) {
            }

            appList.add(appMap)
        }

        val popularPackages = listOf(
            "com.google.android.apps.nfc.phonebank" to "Google Pay",
            "com.phonepe.app" to "PhonePe",
            "net.one97.paytm" to "Paytm",
            "in.org.npci.upiapp" to "BHIM",
            "com.dreamplug.androidapp" to "CRED",
            "com.amazon.mShop.android.shopping" to "Amazon Pay",
            "com.whatsapp" to "WhatsApp",
            "com.freecharge.android" to "Freecharge",
            "com.axis.mobile" to "Axis Mobile",
            "com.icicibank.mobilebanking" to "iMobile Pay"
        )

        for ((pkgName, defaultName) in popularPackages) {
            if (addedPackages.contains(pkgName)) continue
            try {
                val appInfo = pm.getApplicationInfo(pkgName, 0)
                val appName = pm.getApplicationLabel(appInfo).toString().ifEmpty { defaultName }
                addedPackages.add(pkgName)

                val appMap = mutableMapOf<String, String>(
                    "packageName" to pkgName,
                    "appName" to appName
                )
                try {
                    val iconDrawable = pm.getApplicationIcon(appInfo)
                    appMap["icon"] = drawableToBase64(iconDrawable)
                } catch (e: Exception) {
                }

                appList.add(appMap)
            } catch (e: Exception) {
            }
        }

        return appList
    }

    private fun drawableToBase64(drawable: Drawable): String {
        val width = if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth else 96
        val height = if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight else 96
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, canvas.width, canvas.height)
        drawable.draw(canvas)

        val outputStream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, outputStream)
        return Base64.encodeToString(outputStream.toByteArray(), Base64.NO_WRAP)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == UPI_PAYMENT_REQUEST_CODE) {
            if (pendingResult == null) return true

            val responseMap = mutableMapOf<String, Any?>()
            responseMap["resultCode"] = resultCode

            if (data != null) {
                var responseStr = data.getStringExtra("response") ?: data.dataString

                val extrasMap = mutableMapOf<String, String?>()
                data.extras?.let { bundle ->
                    val pairs = mutableListOf<String>()
                    for (key in bundle.keySet()) {
                        val value = bundle.get(key)?.toString()
                        extrasMap[key] = value
                        if (value != null) {
                            pairs.add("$key=$value")
                        }
                    }
                    if (responseStr.isNullOrEmpty() && pairs.isNotEmpty()) {
                        responseStr = pairs.joinToString("&")
                    }
                }
                responseMap["response"] = responseStr
                responseMap["extras"] = extrasMap
            } else {
                responseMap["response"] = null
            }

            pendingResult?.success(responseMap)
            pendingResult = null
            return true
        }
        return false
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activity = null
    }
}
