import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';

/// 메모 관련 에러를 처리하고 사용자에게 표시하는 유틸리티 클래스
class MemoErrorHandler {
  /// 에러를 분석하여 사용자 친화적인 메시지를 반환
  static String getErrorMessage(dynamic error) {
    if (error is PlatformException) {
      switch (error.code) {
        case 'camera_access_denied':
          return '카메라 접근 권한이 필요합니다';
        case 'camera_unavailable':
          return '카메라를 사용할 수 없습니다';
        case 'photo_access_denied':
          return '사진 접근 권한이 필요합니다';
        default:
          return '이미지 선택 중 오류가 발생했습니다';
      }
    }
    
    if (error is SocketException) {
      return '네트워크 연결을 확인해주세요';
    }
    
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('network') || errorString.contains('connection')) {
      return '네트워크 연결을 확인해주세요';
    }
    
    if (errorString.contains('permission') || errorString.contains('권한')) {
      return '접근 권한이 필요합니다';
    }
    
    if (errorString.contains('upload') || errorString.contains('업로드')) {
      return '이미지 업로드에 실패했습니다';
    }
    
    if (errorString.contains('save') || errorString.contains('저장')) {
      return '저장 중 오류가 발생했습니다';
    }
    
    return '오류가 발생했습니다';
  }

  /// 에러를 회색 스낵바로 표시
  static void showErrorSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Pretendard',
            fontSize: 14,
          ),
        ),
        backgroundColor: const Color(0xFF838383),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(
          bottom: 20,
          left: 20,
          right: 20,
        ),
      ),
    );
  }

  /// 에러를 분석하여 회색 스낵바로 표시
  static void showError(BuildContext context, dynamic error) {
    final message = getErrorMessage(error);
    showErrorSnackBar(context, message);
  }
}

