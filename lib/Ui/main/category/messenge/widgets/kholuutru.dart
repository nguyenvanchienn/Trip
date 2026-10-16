import 'package:flutter/material.dart';
import 'package:tourn/Ui/main/category/messenge/pages/ChatPage.dart';
import 'package:tourn/Ui/main/category/messenge/widgets/FirebaseRecentChats.dart';

class ArchivedChatsPage extends StatefulWidget {
  const ArchivedChatsPage({super.key});

  // Danh sách cuộc trò chuyện đã lưu trữ - static để truy cập từ bên ngoài
  static final List<Map<String, dynamic>> archivedChats = [];

  // notifier increments whenever the archive contents change so other
  // widgets can rebuild immediately
  static final ValueNotifier<int> changeNotifier = ValueNotifier<int>(0);

  // giữ id để tránh trùng lặp và lọc trong danh sách chính
  static final Set<String> _archivedIds = {};

  static bool isArchived(String id) => _archivedIds.contains(id);

  static DateTime? getArchivedAt(String id) {
    final chat = archivedChats.firstWhere(
      (c) => c['id'] == id,
      orElse: () => {},
    );
    if (chat.isEmpty) return null;
    final raw = chat['archivedAt'];
    if (raw is int) {
      return DateTime.fromMillisecondsSinceEpoch(raw);
    }
    if (raw is String) {
      return DateTime.tryParse(raw);
    }
    return null;
  }

  static void addArchivedChat(String id, Map<String, dynamic> chat) {
    // Kiểm tra xem đã lưu trữ chưa
    if (_archivedIds.add(id)) {
      // new items should appear at top of archive list
      archivedChats.insert(0, Map<String, dynamic>.from(chat));
      changeNotifier.value++;
    }
  }

  static void removeArchivedChat(String id) {
    _archivedIds.remove(id);
    archivedChats.removeWhere((chat) => chat['id'] == id);
  }

  @override
  State<ArchivedChatsPage> createState() => _ArchivedChatsPageState();
}

class _ArchivedChatsPageState extends State<ArchivedChatsPage> {
  late final VoidCallback _archiveListener;

  @override
  void initState() {
    super.initState();
    // listener notified whenever the archived list changes. We avoid
    // calling setState synchronously since the notification can occur while
    // the page is still building (e.g. when tapping an archived conversation
    // that immediately unarchives itself). Calling setState during a build
    // results in the FlutterError seen in the screenshot. Instead we defer
    // the rebuild to the next frame using addPostFrameCallback.
    _archiveListener = () {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    };
    ArchivedChatsPage.changeNotifier.addListener(_archiveListener);
  }

  @override
  void dispose() {
    ArchivedChatsPage.changeNotifier.removeListener(_archiveListener);
    super.dispose();
  }

  void _unarchiveChat(Map<String, dynamic> chat) {
    setState(() {
      // remove by matching id if present, otherwise by name
      if (chat['id'] != null) {
        ArchivedChatsPage.removeArchivedChat(chat['id'] as String);
      } else {
        // fallback: remove first entry with same name
        final name = chat['name'] as String;
        ArchivedChatsPage.archivedChats.removeWhere((c) => c['name'] == name);
      }
      // notify listeners
      ArchivedChatsPage.changeNotifier.value++;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã bỏ lưu trữ cuộc trò chuyện với ${chat['name']}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // debug print to help verify contents
    // ignore: avoid_print
    print(
      'ArchivedChatsPage.build: count = ${ArchivedChatsPage.archivedChats.length}',
    );
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
      // debug print to help verify contents moved above return
      // ignore: avoid_print
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
                final isAi = chat['isAi'] == true;
                final avatar = (chat['avatar'] as String?)?.trim() ?? '';
                final hasNetworkAvatar =
                    avatar.isNotEmpty && avatar.startsWith('http');
                final hasAssetAvatar = avatar.isNotEmpty;
                // use a key that's guaranteed unique (id if available, otherwise name + index)
                return Dismissible(
                  key: ValueKey(chat['id'] ?? chat['name']),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    // remove item immediately to avoid Dismissible lingering
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
                            child: isAi
                                ? Image.asset(
                                    'asset/icon/logo.png',
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.contain,
                                  )
                                : (hasNetworkAvatar
                                      ? Image.network(
                                          avatar,
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              Container(
                                                width: 60,
                                                height: 60,
                                                color: Colors.grey[300],
                                                child: Icon(
                                                  Icons.person,
                                                  size: 40,
                                                ),
                                              ),
                                        )
                                      : Image.asset(
                                          hasAssetAvatar
                                              ? avatar
                                              : 'asset/images/OIP.jpg',
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                        )),
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
                        if (chat['isFirebase'] == true) {
                          // open Firestore-backed chat using conversation id
                          Navigator.of(context, rootNavigator: true).push(
                            MaterialPageRoute(
                              builder: (context) {
                                // FirebaseChatPage defined in FirebaseRecentChats.dart
                                return FirebaseChatPage(
                                  conversationId: chat['id'] as String,
                                  displayName: chat['name'] as String,
                                  displayPhoto: chat['avatar'] as String?,
                                );
                              },
                            ),
                          );
                        } else {
                          // fallback to dummy ChatPage for static conversations
                          Navigator.of(context, rootNavigator: true).push(
                            MaterialPageRoute(
                              builder: (context) => ChatPage(
                                user: {
                                  'id': chat['id'],
                                  'name': chat['name'],
                                  'avatar': chat['avatar'],
                                },
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
