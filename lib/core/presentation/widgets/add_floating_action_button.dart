import 'package:flutter/material.dart';
import '../../../features/home/presentation/widgets/add_action_modal.dart';

/// 공통 플로팅 액션 버튼
/// 
/// Home, Books, Memos 스크린에서 공통으로 사용하는 플로팅 버튼
class AddFloatingActionButton extends StatelessWidget {
  const AddFloatingActionButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.3,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (context) => const AddActionModal(),
      ),
      backgroundColor: const Color(0xFFECECEC),
      shape: const CircleBorder(),
      child: const Icon(Icons.add, color: Colors.black),
    );
  }
}

