import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tourn/data/firebase/firebase_menu_service.dart';
import 'package:tourn/models/menu_models.dart';

class GhiChuPage extends StatefulWidget {
  const GhiChuPage({super.key});

  @override
  State<GhiChuPage> createState() => _GhiChuPageState();
}

class _GhiChuPageState extends State<GhiChuPage> {
  final FirebaseMenuService _menuService = FirebaseMenuService();
  List<NoteModel> _notes = [];
  List<NoteModel> _filtered = [];
  bool _loading = true;
  StreamSubscription<List<NoteModel>>? _subscription;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _loadNotes() {
    setState(() => _loading = true);
    _subscription = _menuService.getNotesStream().listen((notes) {
      _notes = notes;
      _applyFilter(_lastQuery);
      if (mounted) setState(() => _loading = false);
    });
  }

  Future<void> _addOrEditNote({NoteModel? note}) async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => NoteEditorPage(note: note)),
    );

    if (result != null) {
      if (note == null) {
        // add new note
        await _menuService.addNote(
          title: result['title'] ?? '',
          content: result['content'] ?? '',
        );
      } else {
        // update existing note
        final updatedNote = note.copyWith(
          title: result['title'] ?? '',
          content: result['content'] ?? '',
        );
        await _menuService.updateNote(updatedNote);
      }
    }
  }

  Future<void> _deleteNote(NoteModel note) async {
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
      await _menuService.deleteNote(note.id);
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
      _filtered = List.from(_notes);
    } else {
      final low = q.toLowerCase();
      _filtered = _notes.where((n) {
        return n.title.toLowerCase().contains(low) ||
            n.content.toLowerCase().contains(low);
      }).toList();
    }
    if (mounted) setState(() {});
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
                  key: ValueKey(item.id),
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
                      title: Text(
                        item.title.isEmpty ? 'Không tiêu đề' : item.title,
                      ),
                      subtitle: Text(
                        item.content.split('\n').first,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(_formatTime(item.updatedAt)),
                      onTap: () => _addOrEditNote(note: item),
                      onLongPress: () => _deleteNote(item),
                    ),
                  ),
                );
              },
            ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final d = dateTime.toLocal();
    return '${d.year}-${_two(d.month)}-${_two(d.day)} ${_two(d.hour)}:${_two(d.minute)}';
  }

  String _two(int v) => v.toString().padLeft(2, '0');
}

class NoteEditorPage extends StatefulWidget {
  final NoteModel? note;
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
    _title = TextEditingController(text: widget.note?.title ?? '');
    _content = TextEditingController(text: widget.note?.content ?? '');
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  void _save() {
    final note = {
      'title': _title.text.trim().isEmpty
          ? 'Không tiêu đề'
          : _title.text.trim(),
      'content': _content.text,
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
  final List<NoteModel> notes;
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
    final results = notes
        .where(
          (n) =>
              n.title.toLowerCase().contains(q) ||
              n.content.toLowerCase().contains(q),
        )
        .toList();
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (c, i) => ListTile(
        title: Text(results[i].title),
        subtitle: Text(results[i].content.split('\n').first),
        onTap: () => close(context, query),
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final q = query.trim().toLowerCase();
    final suggestions = q.isEmpty
        ? <NoteModel>[]
        : notes
              .where(
                (n) =>
                    n.title.toLowerCase().contains(q) ||
                    n.content.toLowerCase().contains(q),
              )
              .toList();
    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (c, i) => ListTile(
        title: Text(suggestions[i].title),
        subtitle: Text(suggestions[i].content.split('\n').first),
        onTap: () {
          query = suggestions[i].title;
          showResults(context);
        },
      ),
    );
  }
}
