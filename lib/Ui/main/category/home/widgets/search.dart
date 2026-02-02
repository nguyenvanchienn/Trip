import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _editHistory = false;

  final List<String> _searchHistory = [
    'Nguyễn Hữu Hiển',
    'Nguyễn Văn Chiến',
    'Đào Mạnh Vương',
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      focusNode: _focusNode,
                      decoration: const InputDecoration(
                        hintText: 'Tìm kiếm',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  if (_ctrl.text.isNotEmpty)
                    GestureDetector(
                      onTap: () => setState(() => _ctrl.clear()),
                      child: const Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditButton() {
    return Padding(
      padding: const EdgeInsets.only(right: 12, bottom: 4),
      child: Align(
        alignment: Alignment.centerRight,
        child: Row(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Mới đây",
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
            ),
            const Spacer(), // Đẩy nút về bên phải
            TextButton(
              onPressed: () {
                setState(() => _editHistory = !_editHistory);
              },
              child: Text(
                _editHistory ? 'Xong' : 'Chỉnh sửa',
                style: const TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistory() {
    return ListView.separated(
      itemCount: _searchHistory.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final text = _searchHistory[i];
        return ListTile(
          leading: const Icon(Icons.history, color: Colors.grey),
          title: Text(text),
          trailing: _editHistory
              ? IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    setState(() => _searchHistory.removeAt(i));
                  },
                )
              : null,
          onTap: () {
            _ctrl.text = text;
            _ctrl.selection = TextSelection.fromPosition(
              TextPosition(offset: text.length),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(), // Thanh tìm kiếm
            _buildEditButton(), // Nút chỉnh sửa lịch sử
            const Divider(height: 1),
            Expanded(child: _buildHistory()),
          ],
        ),
      ),
    );
  }
}
