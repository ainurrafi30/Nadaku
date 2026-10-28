import 'package:flutter/material.dart';

/// Daftar item yang digulir ke samping (misalnya artis atau album populer).
class Shelf extends StatelessWidget {
  const Shelf({
    super.key,
    required this.height,
    required this.itemCount,
    required this.itemBuilder,
  });

  final double height;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: itemCount,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: itemBuilder,
      ),
    );
  }
}
