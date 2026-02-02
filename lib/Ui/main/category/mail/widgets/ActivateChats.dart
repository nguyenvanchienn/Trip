// ignore: unused_import
import 'package:flutter/material.dart';
import 'package:tourn/Ui/main/category/mail/pages/ChatPage.dart';

class ActivateChats extends StatelessWidget {
  const ActivateChats({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isOnline = true;
    return Padding(
      padding: EdgeInsets.only(top: 25, left: 5),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: InkWell(
          onTap: () => Navigator.of(
            context,
            rootNavigator: true,
          ).push(MaterialPageRoute(builder: (context) => const ChatPage())),
          child: Row(
            children: [
              for (int i = 0; i < 10; i++)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Container(
                    width: 65,
                    height: 65,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(35),
                      boxShadow: [
                        BoxShadow(
                          // ignore: deprecated_member_use
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(35),
                          child: Image.asset(
                            "asset/images/employee-5.png",
                            width: 65,
                            height: 65,
                            fit: BoxFit.cover,
                          ),
                        ),
                        if (isOnline)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
