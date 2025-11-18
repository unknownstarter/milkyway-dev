import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/onboarding_provider.dart';
import '../../../../core/utils/random_nickname_generator.dart';
import '../../../../core/providers/analytics_provider.dart';

class NicknameScreen extends ConsumerStatefulWidget {
  const NicknameScreen({super.key});

  @override
  ConsumerState<NicknameScreen> createState() => _NicknameScreenState();
}

class _NicknameScreenState extends ConsumerState<NicknameScreen> {
  final _nicknameController = TextEditingController();
  bool _isButtonEnabled = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nicknameController.addListener(_validateInput);
    ref.read(analyticsProvider).logScreenView('nickname_screen');
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  void _validateInput() {
    final nickname = _nicknameController.text;
    final hasSpecialCharacters = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(nickname);

    setState(() {
      _isButtonEnabled = nickname.length >= 2 &&
          nickname.length <= 20 &&
          !hasSpecialCharacters;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF181818),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181818),
        title: const Text(
          '닉네임 설정',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 40),
            
            // 제목
            _buildTitle(),
            const SizedBox(height: 40),
            
            // 닉네임 입력
            _buildNicknameInput(),
            const SizedBox(height: 20),
            
            // 랜덤 닉네임 버튼
            _buildRandomNicknameButton(),
            const SizedBox(height: 40),
            
            // 건너뛰기 버튼
            _buildSkipButton(),
            const SizedBox(height: 20),
            
            // 다음 버튼
            _buildNextButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        const Text(
          '닉네임을 설정해주세요',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Pretendard',
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          '다른 사용자들이 볼 수 있는 이름입니다',
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 16,
            fontFamily: 'Pretendard',
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildNicknameInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '닉네임',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Pretendard',
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nicknameController,
          style: const TextStyle(color: Colors.white, fontFamily: 'Pretendard'),
          decoration: InputDecoration(
            hintText: '닉네임을 입력하세요',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontFamily: 'Pretendard'),
            filled: true,
            fillColor: const Color(0xFF1A1A1A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade800),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade800),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF48FF00)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '2-20자, 특수문자 사용 불가',
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 12,
            fontFamily: 'Pretendard',
          ),
        ),
      ],
    );
  }

  Widget _buildRandomNicknameButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _generateRandomNickname,
        icon: const Icon(Icons.shuffle, color: Color(0xFF48FF00)),
        label: const Text(
          '랜덤 닉네임 생성',
          style: TextStyle(
            color: Color(0xFF48FF00),
            fontFamily: 'Pretendard',
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF48FF00)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildSkipButton() {
    return TextButton(
      onPressed: _isLoading ? null : _handleSkip,
      child: Text(
        '건너뛰기',
        style: TextStyle(
          color: Colors.grey.shade400,
          fontSize: 16,
          fontFamily: 'Pretendard',
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isButtonEnabled && !_isLoading ? _handleNext : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF48FF00),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(
                color: Color(0xFFECECEC),
                strokeWidth: 2,
              )
            : const Text(
                '다음',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Pretendard',
                ),
              ),
      ),
    );
  }

  void _generateRandomNickname() {
    final randomNickname = RandomNicknameGenerator.generate();
    _nicknameController.text = randomNickname;
  }

  Future<void> _handleSkip() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final randomNickname = RandomNicknameGenerator.generate();
      await ref.read(authProvider.notifier).updateProfile(nickname: randomNickname);
      await ref.read(onboardingProvider.notifier).setNickname(randomNickname);

      if (mounted) {
        context.goNamed(AppRoutes.onboardingProfileImageName);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('닉네임 설정 중 오류가 발생했습니다: $e'),
            backgroundColor: const Color(0xFF242424),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleNext() async {
    if (!_isButtonEnabled) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final nickname = _nicknameController.text.trim();
      await ref.read(authProvider.notifier).updateProfile(nickname: nickname);
      await ref.read(onboardingProvider.notifier).setNickname(nickname);

      if (mounted) {
        context.goNamed(AppRoutes.onboardingProfileImageName);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('닉네임 설정 중 오류가 발생했습니다: $e'),
            backgroundColor: const Color(0xFF242424),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}