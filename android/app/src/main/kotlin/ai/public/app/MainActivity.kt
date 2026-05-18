package ai.public.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import android.os.Build
import android.os.Bundle
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.webkit.CookieManager
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsControllerCompat

class MainActivity : FlutterActivity() {
    private lateinit var backgroundStreamingHandler: BackgroundStreamingHandler

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Enable edge-to-edge display for all Android versions
        // This is the official way to enable edge-to-edge that works with Android 15+
        WindowCompat.setDecorFitsSystemWindows(window, false)

        // Configure system bar appearance for edge-to-edge
        val windowInsetsController = WindowCompat.getInsetsController(window, window.decorView)
        windowInsetsController.isAppearanceLightStatusBars = false
        windowInsetsController.isAppearanceLightNavigationBars = false
    }
    
    private val CHANNEL = "ai.public.app/assistant"
    private val NATIVE_AUTH_CHANNEL = "com.publicai.app/native_browser_auth"
    private val OAUTH_PREFS = "native_oauth"
    private val KEY_PENDING = "pendingNativeOauth"
    private val KEY_STATE = "state"
    private val KEY_STARTED_AT = "startedAtMillis"
    private val KEY_ORPHAN_CALLBACK = "orphanCallback"
    private val OAUTH_CALLBACK_TTL_MILLIS = 10 * 60 * 1000L
    private var methodChannel: io.flutter.plugin.common.MethodChannel? = null
    private var pendingNativeAuthResult: io.flutter.plugin.common.MethodChannel.Result? = null
    private lateinit var oauthPrefs: SharedPreferences

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Initialize background streaming handler
        backgroundStreamingHandler = BackgroundStreamingHandler(this)
        backgroundStreamingHandler.setup(flutterEngine)

        methodChannel = io.flutter.plugin.common.MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        oauthPrefs = getSharedPreferences(OAUTH_PREFS, MODE_PRIVATE)

        val nativeAuthChannel = io.flutter.plugin.common.MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            NATIVE_AUTH_CHANNEL
        )
        nativeAuthChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "authenticate" -> authenticateWithNativeBrowser(call, result)
                "consumePendingCallback" -> consumePendingCallback(result)
                else -> result.notImplemented()
            }
        }
        
        // Setup cookie manager channel for WebView cookie access
        val cookieChannel = io.flutter.plugin.common.MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.conduit.app/cookies"
        )
        
        cookieChannel.setMethodCallHandler { call, result ->
            if (call.method == "getCookies") {
                val url = call.argument<String>("url")
                if (url == null) {
                    result.error("INVALID_ARGS", "Invalid URL", null)
                    return@setMethodCallHandler
                }
                
                // Get cookies from Android's CookieManager (shared with WebView)
                val cookieManager = CookieManager.getInstance()
                val cookieString = cookieManager.getCookie(url)
                
                val cookieMap = mutableMapOf<String, String>()
                if (cookieString != null) {
                    // Parse cookie string: "name1=value1; name2=value2"
                    cookieString.split(";").forEach { cookie ->
                        val parts = cookie.trim().split("=", limit = 2)
                        if (parts.size == 2) {
                            cookieMap[parts[0].trim()] = parts[1].trim()
                        }
                    }
                }
                
                result.success(cookieMap)
            } else {
                result.notImplemented()
            }
        }
        
        // Check if started with context
        handleIntent(intent)
    }

    override fun onNewIntent(intent: android.content.Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    override fun onResume() {
        super.onResume()
        cancelAbandonedNativeAuthIfNeeded()
    }

    private fun isNativeOAuthCallback(uri: Uri?): Boolean {
        return uri != null &&
            uri.scheme == "publicai" &&
            uri.host == "auth" &&
            uri.path == "/callback"
    }

    private fun authenticateWithNativeBrowser(
        call: io.flutter.plugin.common.MethodCall,
        result: io.flutter.plugin.common.MethodChannel.Result
    ) {
        if (pendingNativeAuthResult != null) {
            result.error("AUTH_IN_PROGRESS", "Native auth is already in progress", null)
            return
        }

        val url = call.argument<String>("url")
        val state = call.argument<String>("state")
        if (url.isNullOrBlank()) {
            result.error("INVALID_ARGS", "Missing native auth URL", null)
            return
        }

        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url)).apply {
            addCategory(Intent.CATEGORY_BROWSABLE)
        }
        if (intent.resolveActivity(packageManager) == null) {
            result.error("NO_BROWSER", "No browser available for native auth", null)
            return
        }

        pendingNativeAuthResult = result
        oauthPrefs.edit()
            .putBoolean(KEY_PENDING, true)
            .putString(KEY_STATE, state)
            .putLong(KEY_STARTED_AT, System.currentTimeMillis())
            .apply()

        try {
            startActivity(intent)
        } catch (e: Exception) {
            pendingNativeAuthResult = null
            clearPendingNativeAuth()
            result.error("START_FAILED", "Failed to start native auth", null)
        }
    }

    private fun consumePendingCallback(result: io.flutter.plugin.common.MethodChannel.Result) {
        val callback = oauthPrefs.getString(KEY_ORPHAN_CALLBACK, null)
        if (callback == null) {
            result.success(null)
            return
        }
        val state = oauthPrefs.getString(KEY_STATE, null)
        val startedAt = oauthPrefs.getLong(KEY_STARTED_AT, 0L)
        val isExpired = startedAt <= 0L ||
            System.currentTimeMillis() - startedAt > OAUTH_CALLBACK_TTL_MILLIS
        if (isExpired) {
            clearPendingNativeAuth()
            oauthPrefs.edit().remove(KEY_ORPHAN_CALLBACK).apply()
            result.success(null)
            return
        }
        oauthPrefs.edit()
            .remove(KEY_ORPHAN_CALLBACK)
            .remove(KEY_PENDING)
            .remove(KEY_STATE)
            .remove(KEY_STARTED_AT)
            .apply()
        result.success(mapOf("callback" to callback, "state" to state))
    }

    private fun completeNativeOAuthCallback(uri: Uri): Boolean {
        if (!isNativeOAuthCallback(uri)) return false

        val callback = uri.toString()
        val pendingResult = pendingNativeAuthResult
        if (pendingResult != null) {
            pendingNativeAuthResult = null
            clearPendingNativeAuth()
            pendingResult.success(callback)
        } else {
            oauthPrefs.edit()
                .putString(KEY_ORPHAN_CALLBACK, callback)
                .apply()
        }
        return true
    }

    private fun clearPendingNativeAuth() {
        oauthPrefs.edit()
            .remove(KEY_PENDING)
            .remove(KEY_STATE)
            .remove(KEY_STARTED_AT)
            .apply()
    }

    private fun cancelAbandonedNativeAuthIfNeeded() {
        val pendingResult = pendingNativeAuthResult ?: return
        if (!oauthPrefs.getBoolean(KEY_PENDING, false)) return

        pendingNativeAuthResult = null
        clearPendingNativeAuth()
        pendingResult.error("CANCELED", "Native auth was canceled", null)
    }

    private fun handleIntent(intent: android.content.Intent) {
        val data = intent.data
        if (data != null && completeNativeOAuthCallback(data)) {
            return
        }

        android.util.Log.d("MainActivity", "handleIntent called")
        android.util.Log.d("MainActivity", "Intent extras: ${intent.extras?.keySet()}")

        val screenContext = intent.getStringExtra("screen_context")
        val screenshotPath = intent.getStringExtra("screenshot_path")
        val startVoiceCall = intent.getBooleanExtra("start_voice_call", false)
        val startNewChat = intent.getBooleanExtra("start_new_chat", false)

        android.util.Log.d("MainActivity", "screenContext: $screenContext")
        android.util.Log.d("MainActivity", "screenshotPath: $screenshotPath")
        android.util.Log.d("MainActivity", "startVoiceCall: $startVoiceCall")
        android.util.Log.d("MainActivity", "startNewChat: $startNewChat")
        android.util.Log.d("MainActivity", "methodChannel: $methodChannel")

        if (startVoiceCall) {
            android.util.Log.d("MainActivity", "Invoking startVoiceCall")
            methodChannel?.invokeMethod("startVoiceCall", null)
        } else if (startNewChat) {
            android.util.Log.d("MainActivity", "Invoking startNewChat")
            methodChannel?.invokeMethod("startNewChat", null)
        } else if (screenContext != null) {
            android.util.Log.d("MainActivity", "Invoking analyzeScreen")
            methodChannel?.invokeMethod("analyzeScreen", screenContext)
        } else if (screenshotPath != null) {
            android.util.Log.d("MainActivity", "Invoking analyzeScreenshot with path: $screenshotPath")
            methodChannel?.invokeMethod("analyzeScreenshot", screenshotPath)
        } else {
            android.util.Log.d("MainActivity", "No screen context or screenshot path found")
        }
    }
    
    override fun onDestroy() {
        super.onDestroy()
        if (::backgroundStreamingHandler.isInitialized) {
            backgroundStreamingHandler.cleanup()
        }
    }
}
