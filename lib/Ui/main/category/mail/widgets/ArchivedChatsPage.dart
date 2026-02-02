import 'package:flutter/material.dart';
import 'package:tourn/Ui/main/category/mail/pages/ChatPage.dart';

class ArchivedChatsPage extends StatefulWidget {
  const ArchivedChatsPage({super.key});

  // Danh sách cuộc trò chuyện đã lưu trữ - static để truy cập từ bên ngoài
  static final List<Map<String, dynamic>> archivedChats = [];

  static void addArchivedChat(Map<String, dynamic> chat) {
    // Kiểm tra xem đã lưu trữ chưa
    if (!archivedChats.any((c) => c['name'] == chat['name'])) {
      archivedChats.add(Map<String, dynamic>.from(chat));
    }
  }

  static void removeArchivedChat(String name) {
    archivedChats.removeWhere((chat) => chat['name'] == name);
  }

  @override
  State<ArchivedChatsPage> createState() => _ArchivedChatsPageState();
}

class _ArchivedChatsPageState extends State<ArchivedChatsPage> {
  void _unarchiveChat(Map<String, dynamic> chat) {
    setState(() {
      ArchivedChatsPage.archivedChats.remove(chat);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã bỏ lưu trữ cuộc trò chuyện với ${chat['name']}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Color(0xFF113953),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Cuộc trò chuyện đã lưu trữ',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ArchivedChatsPage.archivedChats.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.archive_outlined,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Chưa có cuộc trò chuyện nào được lưu trữ',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Vuốt sang trái và chọn "Lưu trữ"\nđể lưu cuộc trò chuyện',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: ArchivedChatsPage.archivedChats.length,
              itemBuilder: (context, index) {
                final chat = ArchivedChatsPage.archivedChats[index];
                return Dismissible(
                  key: Key('archived_${chat['name']}'),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    _unarchiveChat(chat);
                  },
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.only(right: 20),
                    color: Colors.green,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.unarchive, color: Colors.white, size: 32),
                        SizedBox(height: 4),
                        Text(
                          'Bỏ lưu trữ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  child: Container(
                    color: Colors.white,
                    margin: EdgeInsets.only(bottom: 1),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 10,
                      ),
                      leading: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(35),
                            child: Image.asset(
                              chat['avatar'],
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          ),
                          if (chat['isOnline'] == true)
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
                      title: Text(
                        chat['name'],
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF113953),
                        ),
                      ),
                      subtitle: Text(
                        chat['lastMessage'],
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            chat['time'],
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          SizedBox(height: 5),
                          Icon(
                            Icons.archive,
                            color: Colors.grey.shade400,
                            size: 18,
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.of(context, rootNavigator: true).push(
                          MaterialPageRoute(
                            builder: (context) => const ChatPage(),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
