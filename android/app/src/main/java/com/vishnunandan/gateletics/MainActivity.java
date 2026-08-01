package com.vishnunandan.gateletics;

import android.os.Build;
import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.vishnunandan.gateletics/system_color";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    if (call.method.equals("getSystemAccentColor")) {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            try {
                                int colorInt = getContext().getColor(android.R.color.system_accent1_500);
                                result.success(colorInt);
                                return;
                            } catch (Exception e) {
                                // Fallback
                            }
                        }
                        result.success(null);
                    } else {
                        result.notImplemented();
                    }
                });
    }
}
