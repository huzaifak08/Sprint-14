package com.zaifii.sprint_14

import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity(){
    private val channel = "flutter_channel"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine){
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channel
        ).setMethodCallHandler{ call, result ->
            if(call.method == "getAppVersion"){
                val appVersion = getAppVersionName()
                if(appVersion != null){
                    result.success(appVersion)
                }else{
                    result.error("UNAVAILABLE", "Could not fetch application version name.", null)
                }
            }else{
                result.notImplemented()
            }
        }
    }

    private fun getAppVersionName():String? {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU){
                packageManager.getPackageInfo(packageName, PackageManager.PackageInfoFlags.of(0)).versionName
            }else{
                @Suppress("DEPRECATION")
                packageManager.getPackageInfo(packageName, 0).versionName
            }

        }catch (e: PackageManager.NameNotFoundException){
            null
        }
    }
}
