import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final List<BottomNavigationBarItem> items;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
      height: 70,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 25,
            offset: const Offset(8, 20),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isSelected = selectedIndex == index;
          return GestureDetector(
            onTap: () => onItemTapped(index),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 36,
                  height: 36,
                  child: isSelected
                      ? Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            item.activeIcon,
                          ],
                        )
                      : item.icon,
                ),
                if (item.label != null)
                  Text(
                    item.label!,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
