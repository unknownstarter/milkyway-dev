import 'package:flutter/material.dart';

class MemoSection extends StatelessWidget {
  const MemoSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 2,
      itemBuilder: (context, index) {
        return Card(
          child: ListTile(
            title: Text('메모 ${index + 1}'),
            subtitle: Text('2024.02.${15 - index}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
        );
      },
    );
  }
}
