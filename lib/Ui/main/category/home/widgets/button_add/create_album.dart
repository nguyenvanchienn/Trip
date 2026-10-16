import 'package:flutter/material.dart';

class CreateAlbum extends StatefulWidget {
  const CreateAlbum({super.key});

  @override
  State<CreateAlbum> createState() => _CreateAlbumState();
}

class _CreateAlbumState extends State<CreateAlbum> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  String? _selectedImage;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo album'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Tiêu đề album'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Vui lòng nhập tiêu đề'
                    : null,
              ),
              const SizedBox(height: 16),

              const Text('Ảnh bìa'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  // TODO: open image picker or selection
                  setState(() {});
                },
                child: Container(
                  height: 100,
                  width: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                    color: Colors.grey.shade100,
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            _selectedImage!,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) =>
                                Container(color: Colors.grey),
                          ),
                        )
                      : const Center(child: Text('Thêm ảnh bìa')),
                ),
              ),

              const Spacer(),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _onSave,
                      child: const Text('Tạo album'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    final image = _selectedImage;

    // return a simple map with album data to the caller
    Navigator.pop(context, {'title': title, 'image': image});
  }
}
