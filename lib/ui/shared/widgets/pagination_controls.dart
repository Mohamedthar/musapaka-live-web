import 'package:flutter/material.dart';

class PaginationControls extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;
  final ValueChanged<int> onPageChanged;
  final List<int>? pageSizeOptions;
  final ValueChanged<int>? onPageSizeChanged;

  const PaginationControls({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
    required this.onPageChanged,
    this.pageSizeOptions,
    this.onPageSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1 && (pageSizeOptions == null || totalItems <= pageSizeOptions!.first)) {
      return const SizedBox.shrink();
    }

    final startItem = ((currentPage - 1) * itemsPerPage) + 1;
    final endItem = (currentPage * itemsPerPage).clamp(0, totalItems);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$startItem-$endItem من $totalItems',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF717171),
                  ),
                ),
              ],
            ),
          ),
          if (pageSizeOptions != null && onPageSizeChanged != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'عدد العناصر: ',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF717171),
                    ),
                  ),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: itemsPerPage,
                      items: pageSizeOptions!
                          .map((s) => DropdownMenuItem<int>(
                                value: s,
                                child: Text(
                                  '$s',
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ))
                          .toList(),
                      onChanged: (v) => onPageSizeChanged!(v!),
                      isDense: true,
                      icon: const Icon(Icons.expand_more_rounded, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
          ],
          _pageButton(
            Icons.first_page_rounded,
            onTap: currentPage > 1 ? () => onPageChanged(1) : null,
          ),
          _pageButton(
            Icons.chevron_right_rounded,
            onTap: currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
          ),
          const SizedBox(width: 8),
          ..._pageNumbers(),
          const SizedBox(width: 8),
          _pageButton(
            Icons.chevron_left_rounded,
            onTap: currentPage < totalPages ? () => onPageChanged(currentPage + 1) : null,
          ),
          _pageButton(
            Icons.last_page_rounded,
            onTap: currentPage < totalPages ? () => onPageChanged(totalPages) : null,
          ),
        ],
      ),
    );
  }

  List<Widget> _pageNumbers() {
    final pages = <int>[];
    if (totalPages <= 7) {
      for (var i = 1; i <= totalPages; i++) {
        pages.add(i);
      }
    } else {
      pages.add(1);
      if (currentPage > 3) pages.add(-1);
      for (var i = (currentPage - 1).clamp(2, totalPages - 1);
          i <= (currentPage + 1).clamp(2, totalPages - 1);
          i++) {
        pages.add(i);
      }
      if (currentPage < totalPages - 2) pages.add(-1);
      pages.add(totalPages);
    }

    return pages.map((p) {
      if (p == -1) {
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text('...', style: TextStyle(fontFamily: 'Cairo', fontSize: 14, color: Color(0xFF717171))),
        );
      }
      final isActive = p == currentPage;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: isActive ? const Color(0xFF03121C) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: isActive ? null : () => onPageChanged(p),
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              child: Text(
                '$p',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
                  color: isActive ? Colors.white : const Color(0xFF03121C),
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _pageButton(IconData icon, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: IconButton(
        icon: Icon(icon, size: 20),
        onPressed: onTap,
        splashRadius: 18,
        color: onTap != null ? const Color(0xFF03121C) : Colors.grey.shade300,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      ),
    );
  }
}
