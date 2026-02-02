import 'package:tourn/Ui/main/category/mail/widgets/ActivateChats.dart';
import 'package:tourn/Ui/main/category/mail/widgets/RecentChats.dart';
import 'package:flutter/material.dart';
import 'package:tourn/Ui/main/category/mail/widgets/AIbottonchat.dart';
import 'package:tourn/Ui/main/category/mail/widgets/MenuPage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Tin nhắn",
          style: TextStyle(
            color: Color(0xFF113953),
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.menu, color: Color(0xFF113953)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MenuPage()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    // ignore: deprecated_member_use
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: 300,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 15),
                      child: TextFormField(
                        decoration: InputDecoration(
                          hintText: "Search",
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  Icon(Icons.search, color: Color(0xFF113953)),
                ],
              ),
            ),
          ),
          ActivateChats(),
          RecentChats(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          buildBottomSheet(context);
        },
        backgroundColor: Color(0xFF113953),
        shape: CircleBorder(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(35),
          child: Padding(
            padding: const EdgeInsets.only(
              left: 7,
              right: 9,
              top: 8,
              bottom: 8,
            ),
            child: Image.asset("asset/icon/logo.png", fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
