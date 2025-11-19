import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:developer' as developer;

/// 에러 타입 enum
enum ErrorType {
  network,
  permission,
  upload,
  save,
  create,
  update,
  delete,
  auth,
  server,
  unknown,
}

/// 앱 전체에서 사용하는 공통 에러 핸들러
/// 
/// 네트워크 오류, 권한 오류 등을 사용자 친화적인 메시지로 변환하여
/// 회색 스낵바로 표시하고, 에러 로그를 기록합니다.
class ErrorHandler {
  /// 에러 타입을 코드로 변환 (넘버링 포함)
  static String _getErrorCode(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return 'ERR_1001'; // 네트워크 연결 오류
      case ErrorType.permission:
        return 'ERR_1002'; // 권한 오류
      case ErrorType.upload:
        return 'ERR_2001'; // 업로드 오류
      case ErrorType.save:
        return 'ERR_3001'; // 저장 오류
      case ErrorType.create:
        return 'ERR_3002'; // 등록 오류
      case ErrorType.update:
        return 'ERR_3003'; // 수정 오류
      case ErrorType.delete:
        return 'ERR_3004'; // 삭제 오류
      case ErrorType.auth:
        return 'ERR_4001'; // 인증 오류
      case ErrorType.server:
        return 'ERR_5001'; // 서버 오류
      case ErrorType.unknown:
        return 'ERR_9999'; // 알 수 없는 오류
    }
  }

  /// 에러 타입 분석
  static ErrorType _getErrorType(dynamic error) {
    if (error is SocketException) {
      return ErrorType.network;
    }
    
    if (error is PlatformException) {
      if (error.code.contains('permission') || 
          error.code.contains('denied') ||
          error.code.contains('access')) {
        return ErrorType.permission;
      }
    }
    
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('network') || 
        errorString.contains('connection') ||
        errorString.contains('internet') ||
        errorString.contains('timeout')) {
      return ErrorType.network;
    }
    
    if (errorString.contains('permission') || 
        errorString.contains('권한') ||
        errorString.contains('denied')) {
      return ErrorType.permission;
    }
    
    if (errorString.contains('upload') || 
        errorString.contains('업로드') ||
        errorString.contains('storage')) {
      return ErrorType.upload;
    }
    
    if (errorString.contains('create') || errorString.contains('등록')) {
      return ErrorType.create;
    }
    
    if (errorString.contains('update') || errorString.contains('수정')) {
      return ErrorType.update;
    }
    
    if (errorString.contains('delete') || errorString.contains('삭제')) {
      return ErrorType.delete;
    }
    
    if (errorString.contains('auth') || 
        errorString.contains('인증') ||
        errorString.contains('unauthorized') ||
        errorString.contains('forbidden')) {
      return ErrorType.auth;
    }
    
    if (errorString.contains('server') || 
        errorString.contains('500') ||
        errorString.contains('503')) {
      return ErrorType.server;
    }
    
    if (errorString.contains('save') || errorString.contains('저장')) {
      return ErrorType.save;
    }
    
    return ErrorType.unknown;
  }
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
          return '작업 중 오류가 발생했습니다';
      }
    }
    
    if (error is SocketException) {
      return '네트워크 연결을 확인해주세요';
    }
    
    final errorString = error.toString().toLowerCase();
    
    // 네트워크 관련 오류
    if (errorString.contains('network') || 
        errorString.contains('connection') ||
        errorString.contains('internet') ||
        errorString.contains('timeout') ||
        errorString.contains('failed host lookup')) {
      return '네트워크 연결을 확인해주세요';
    }
    
    // 권한 관련 오류
    if (errorString.contains('permission') || 
        errorString.contains('권한') ||
        errorString.contains('denied')) {
      return '접근 권한이 필요합니다';
    }
    
    // 업로드 관련 오류
    if (errorString.contains('upload') || 
        errorString.contains('업로드') ||
        errorString.contains('storage')) {
      return '업로드에 실패했습니다';
    }
    
    // 저장 관련 오류
    if (errorString.contains('save') || 
        errorString.contains('저장') ||
        errorString.contains('create') ||
        errorString.contains('update') ||
        errorString.contains('delete')) {
      if (errorString.contains('create') || errorString.contains('등록')) {
        return '등록에 실패했습니다';
      }
      if (errorString.contains('update') || errorString.contains('수정')) {
        return '수정에 실패했습니다';
      }
      if (errorString.contains('delete') || errorString.contains('삭제')) {
        return '삭제에 실패했습니다';
      }
      return '저장에 실패했습니다';
    }
    
    // 인증 관련 오류
    if (errorString.contains('auth') || 
        errorString.contains('인증') ||
        errorString.contains('unauthorized') ||
        errorString.contains('forbidden')) {
      return '인증이 필요합니다';
    }
    
    // 서버 관련 오류
    if (errorString.contains('server') || 
        errorString.contains('500') ||
        errorString.contains('503')) {
      return '서버 오류가 발생했습니다';
    }
    
    // 기본 메시지
    return '작업 중 오류가 발생했습니다';
  }

  /// 에러를 회색 스낵바로 표시하고 로그를 기록
  /// 
  /// [context] BuildContext
  /// [message] 표시할 메시지 (null이면 에러를 분석하여 메시지 생성)
  /// [error] 에러 객체 (message가 null일 때 사용)
  /// [operation] 작업 이름 (예: '메모 삭제', '프로필 수정')
  static void showErrorSnackBar(
    BuildContext context, {
    String? message,
    dynamic error,
    String? operation,
  }) {
    if (!context.mounted) return;
    
    final displayMessage = message ?? getErrorMessage(error ?? '알 수 없는 오류');
    
    // 에러 로그 기록
    if (error != null) {
      final errorType = _getErrorType(error);
      final errorCode = _getErrorCode(errorType);
      final operationName = operation ?? '작업';
      
      developer.log(
        '[$errorCode] $operationName 실패',
        name: 'ErrorHandler',
        error: error,
        stackTrace: error is Error ? error.stackTrace : null,
      );
      
      developer.log(
        '에러 타입: $errorType | 사용자 메시지: $displayMessage',
        name: 'ErrorHandler',
      );
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          displayMessage,
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

  /// 에러를 분석하여 회색 스낵바로 표시하고 로그를 기록
  /// 
  /// [context] BuildContext
  /// [error] 에러 객체
  /// [operation] 작업 이름 (예: '메모 삭제', '프로필 수정')
  static void showError(
    BuildContext context,
    dynamic error, {
    String? operation,
  }) {
    showErrorSnackBar(context, error: error, operation: operation);
  }
}
