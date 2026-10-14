import 'package:flutter/material.dart';
import 'package:klutter/data/models/bookdto.dart';

class ReadProgressBar extends StatelessWidget {
  const ReadProgressBar({
    Key? key,
    required this.book,
  }) : super(key: key);

  final BookDto book;

  @override
  Widget build(BuildContext context) {
    final progress = book.readProgress;
    if (progress == null || book.media.pagesCount <= 0) {
      return const SizedBox.shrink();
    }
    final double fraction = progress.completed
        ? 1.0
        : (progress.page / book.media.pagesCount).clamp(0.0, 1.0);

    return Container(
      height: 3,
      width: double.infinity,
      color: const Color(0xFF333333),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: fraction,
        child: Container(
          color: const Color(0xFFE5A614),
        ),
      ),
    );
  }
}
