import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GhiChuPage extends StatefulWidget {
  const GhiChuPage({super.key});

  @override
  State<GhiChuPage> createState() => _GhiChuPageState();
}

class _GhiChuPageState extends State<GhiChuPage> {
  final String _prefsKey = 'notes_v1';
  List<Map<String, dynamic>> _notes = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        final data = jsonDecode(raw) as List<dynamic>;
        _notes = data.cast<Map<String, dynamic>>();
      } catch (_) {
        _notes = [];
      }
    } else {
      _notes = [];
    }
    _filtered = List.from(_notes.reversed);
    setState(() => _loading = false);
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(_notes));
  }

  Future<void> _addOrEditNote({Map<String, dynamic>? note}) async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => NoteEditorPage(note: note)),
    );

    if (result != null) {
      if (note == null) {
        // add
        _notes.add(result);
      } else {
        // replace by id
        final idx = _notes.indexWhere((n) => n['id'] == note['id']);
        if (idx >= 0) _notes[idx] = result;
      }
      await _saveNotes();
      _applyFilter(_lastQuery);
      setState(() {});
    }
  }

  Future<void> _deleteNote(Map<String, dynamic> note) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Xóa ghi chú'),
        content: const Text('Bạn có chắc chắn muốn xóa ghi chú này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (ok == true) {
      _notes.removeWhere((n) => n['id'] == note['id']);
      await _saveNotes();
      _applyFilter(_lastQuery);
      setState(() {});
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã xóa ghi chú')));
    }
  }

  String _lastQuery = '';
  void _applyFilter(String q) {
    _lastQuery = q;
    if (q.trim().isEmpty) {
      _filtered = List.from(_notes.reversed);
    } else {
      final low = q.toLowerCase();
      _filtered = _notes.reversed.where((n) {
        return (n['title'] as String).toLowerCase().contains(low) ||
            (n['content'] as String).toLowerCase().contains(low);
      }).toList();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ghi chú'),
        actions: [
          IconButton(
            tooltip: 'Tìm kiếm',
            icon: const Icon(Icons.search),
            onPressed: () async {
              final q = await showSearch<String>(
                context: context,
                delegate: _NoteSearchDelegate(_notes),
              );
              if (q != null) _applyFilter(q);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditNote(),
        tooltip: 'Thêm ghi chú',
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _filtered.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Không có ghi chú'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _addOrEditNote(),
                    child: const Text('Tạo ghi chú mới'),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final item = _filtered[i];
                return Dismissible(
                  key: ValueKey(item['id']),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  direction: DismissDirection.startToEnd,
                  onDismissed: (_) => _deleteNote(item),
                  child: Card(
                    child: ListTile(
                      title: Text(item['title'] ?? 'Không tiêu đề'),
                      subtitle: Text(
                        (item['content'] as String).split('\n').first,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(
                        _formatTime(item['updatedAt'] ?? item['createdAt']),
                      ),
                      onTap: () => _addOrEditNote(note: item),
                      onLongPress: () => _deleteNote(item),
                    ),
                  ),
                );
              },
            ),
    );
  }

  String _formatTime(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      return '${d.year}-${_two(d.month)}-${_two(d.day)} ${_two(d.hour)}:${_two(d.minute)}';
    } catch (_) {
      return '';
    }
  }

  String _two(int v) => v.toString().padLeft(2, '0');
}

class NoteEditorPage extends StatefulWidget {
  final Map<String, dynamic>? note;
  const NoteEditorPage({super.key, this.note});

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  late TextEditingController _title;
  late TextEditingController _content;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.note?['title'] ?? '');
    _content = TextEditingController(text: widget.note?['content'] ?? '');
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  void _save() {
    final now = DateTime.now().toUtc();
    final id = widget.note?['id'] ?? now.microsecondsSinceEpoch.toString();
    final note = {
      'id': id,
      'title': _title.text.trim().isEmpty
          ? 'Không tiêu đề'
          : _title.text.trim(),
      'content': _content.text,
      'createdAt': widget.note?['createdAt'] ?? now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    };
    Navigator.of(context).pop(note);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? 'Tạo ghi chú' : 'Sửa ghi chú'),
        actions: [IconButton(onPressed: _save, icon: const Icon(Icons.save))],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(
              controller: _title,
              decoration: const InputDecoration(hintText: 'Tiêu đề'),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TextField(
                controller: _content,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(hintText: 'Nội dung'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteSearchDelegate extends SearchDelegate<String> {
  final List<Map<String, dynamic>> notes;
  _NoteSearchDelegate(this.notes);

  @override
  List<Widget>? buildActions(BuildContext context) => [
    IconButton(onPressed: () => query = '', icon: const Icon(Icons.clear)),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    onPressed: () => close(context, ''),
    icon: const Icon(Icons.arrow_back),
  );

  @override
  Widget buildResults(BuildContext context) {
    final q = query.trim().toLowerCase();
    final results = notes.reversed
        .where(
          (n) =>
              (n['title'] as String).toLowerCase().contains(q) ||
              (n['content'] as String).toLowerCase().contains(q),
        )
        .toList();
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (c, i) => ListTile(
        title: Text(results[i]['title']),
        subtitle: Text((results[i]['content'] as String).split('\n').first),
        onTap: () => close(context, query),
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final q = query.trim().toLowerCase();
    final suggestions = q.isEmpty
        ? []
        : notes.reversed
              .where(
                (n) =>
                    (n['title'] as String).toLowerCase().contains(q) ||
                    (n['content'] as String).toLowerCase().contains(q),
              )
              .toList();
    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (c, i) => ListTile(
        title: Text(suggestions[i]['title']),
        subtitle: Text((suggestions[i]['content'] as String).split('\n').first),
        onTap: () {
          query = suggestions[i]['title'];
          showResults(context);
        },
      ),
    );
  }
}
