import 'package:flutter/material.dart';

class ChatBottomSheet extends StatelessWidget {
  const ChatBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 65,
      decoration: BoxDecoration(
        color: Colors.white,
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
      child: Row(
        children: [
          Padding(
            padding: EdgeInsets.only(left: 8),
            child: Icon(Icons.add, color: Color(0xFF113953), size: 30),
          ),
          Padding(
            padding: EdgeInsets.only(left: 5),
            child: Icon(
              Icons.emoji_emotions_outlined,
              color: Color(0xFF113953),
              size: 30,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: 10),
            child: Container(
              alignment: Alignment.center,
              width: 270,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Type something',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Spacer(),
          Padding(
            padding: EdgeInsets.only(right: 10),
            child: Icon(Icons.send, color: Color(0xFF113953)),
          ),
        ],
      ),
    );
  }
}
