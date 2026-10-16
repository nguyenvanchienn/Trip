import 'package:flutter/material.dart';

class SearchMessagesPage extends StatefulWidget {
  final String chatName;

  const SearchMessagesPage({super.key, required this.chatName});

  @override
  State<SearchMessagesPage> createState() => _SearchMessagesPageState();
}

class _SearchMessagesPageState extends State<SearchMessagesPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  // Dữ liệu mẫu tin nhắn
  final List<Map<String, dynamic>> _allMessages = [
    {
      'text': 'Hello chien how are you?',
      'sender': 'Programmer',
      'time': DateTime.now().subtract(Duration(hours: 2)),
    },
    {
      'text': 'I am fine thanks',
      'sender': 'You',
      'time': DateTime.now().subtract(Duration(hours: 1)),
    },
    {
      'text': 'What are you doing?',
      'sender': 'Programmer',
      'time': DateTime.now().subtract(Duration(minutes: 30)),
    },
  ];

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchResults = _allMessages
          .where(
            (msg) => msg['text'].toString().toLowerCase().contains(
              query.toLowerCase(),
            ),
          )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF113953),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Tìm kiếm tin nhắn...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          onChanged: _performSearch,
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear, color: Colors.white),
              onPressed: () {
                _searchController.clear();
                _performSearch('');
              },
            ),
        ],
      ),
      body: _isSearching
          ? _searchResults.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Không tìm thấy kết quả',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final message = _searchResults[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Color(0xFF113953),
                          child: Text(
                            message['sender'][0],
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(message['text']),
                        subtitle: Text(
                          '${message['sender']} - ${_formatTime(message['time'])}',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Nhảy đến tin nhắn')),
                          );
                        },
                      );
                    },
                  )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search, size: 64, color: Colors.grey[300]),
                  SizedBox(height: 16),
                  Text(
                    'Tìm kiếm tin nhắn trong cuộc trò chuyện',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }
}
