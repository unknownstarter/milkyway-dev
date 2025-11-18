import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';

class AddActionModal extends StatelessWidget {
  const AddActionModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 8,
          ),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF4117EB).withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.menu_book_outlined,
              color: Color(0xFF4117EB),
            ),
          ),
          title: const Text(
            '책 등록하기',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          onTap: () {
            Navigator.pop(context);
            context.goNamed(AppRoutes.bookSearchName);
          },
        ),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 8,
          ),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF4117EB).withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.edit_outlined,
              color: Color(0xFF4117EB),
            ),
          ),
          title: const Text(
            '메모 작성하기',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          onTap: () {
            Navigator.pop(context);
            context.pushNamed(AppRoutes.memoCreateName);
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
} 