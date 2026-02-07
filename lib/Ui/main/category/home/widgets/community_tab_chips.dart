import 'package:flutter/material.dart';

class CommunityTabChips extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const CommunityTabChips({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          final isSelected = selectedIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => onSelected(index),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF113953) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF113953)
                        : Colors.grey.shade300,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF113953).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    if (index == 0)
                      Icon(
                        Icons.local_fire_department,
                        size: 16,
                        color: isSelected ? Colors.orange : Colors.orange,
                      ),
                    if (index == 1)
                      Icon(
                        Icons.restaurant,
                        size: 16,
                        color: isSelected ? Colors.white : Colors.grey[600],
                      ),
                    if (index == 2)
                      Icon(
                        Icons.beach_access,
                        size: 16,
                        color: isSelected ? Colors.white : Colors.grey[600],
                      ),
                    if (index == 3)
                      Icon(
                        Icons.terrain,
                        size: 16,
                        color: isSelected ? Colors.white : Colors.grey[600],
                      ),
                    if (index == 4)
                      Icon(
                        Icons.account_balance,
                        size: 16,
                        color: isSelected ? Colors.white : Colors.grey[600],
                      ),
                    const SizedBox(width: 6),
                    Text(
                      tabs[index],
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[700],
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
