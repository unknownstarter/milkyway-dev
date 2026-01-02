package com.whatif.milkyway

import android.os.Build
import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

/// FlutterActivity는 기본적으로 IME(Input Method Editor)를 지원하므로
/// 추가 설정 없이 한글 입력을 포함한 모든 입력 방법을 지원합니다.
class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Android 15 (API 35) 이상에서 Edge-to-Edge 활성화
        // Google Play 정책 준수: SDK 35 타겟팅 앱은 Edge-to-Edge 지원 필요
        // 지원 중단된 Window.setStatusBarColor, setNavigationBarColor API 대신
        // WindowCompat를 사용하여 Edge-to-Edge 모드 활성화
        if (Build.VERSION.SDK_INT >= 35) { // Android 15 (API 35)
            WindowCompat.setDecorFitsSystemWindows(window, false)
        }
    }
}
