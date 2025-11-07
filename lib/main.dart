import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/config/env_config.dart';
import 'core/services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // iOS/Android에서는 assets에서, 다른 플랫폼에서는 파일 시스템에서 읽기
    if (Platform.isIOS || Platform.isAndroid) {
      await dotenv.load(fileName: ".env");
    } else {
      await dotenv.load(fileName: ".env");
    }
  } catch (e) {
    // .env 파일이 없어도 계속 진행 (환경 변수는 빈 값으로 설정됨)
    print(
        'Warning: .env file not found. Please create .env file from .env.example');
    print('Error details: $e');
  }

  timeago.setLocaleMessages('ko', timeago.KoMessages());

  final supabaseUrl = EnvConfig.supabaseUrl;
  final supabaseAnonKey = EnvConfig.supabaseAnonKey;

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    print(
        'Error: Supabase credentials are missing. Please check your .env file.');
    // 앱을 계속 실행하되, Supabase 초기화는 건너뜀
    // 실제로는 여기서 에러를 표시하거나 종료해야 할 수도 있습니다
  } else {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  await FirebaseService.initialize();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'WhatIf MilkyWay',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: MediaQuery.of(context).textScaler.clamp(
                  minScaleFactor: 0.8,
                  maxScaleFactor: 1.2,
                ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
