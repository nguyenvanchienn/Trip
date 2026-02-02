import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class HelpFaqPage extends StatefulWidget {
  final List<Map<String, String>>? faqs;

  const HelpFaqPage({super.key, this.faqs});

  @override
  State<HelpFaqPage> createState() => _HelpFaqPageState();
}

class _HelpFaqPageState extends State<HelpFaqPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(
      () => setState(() => _query = _searchController.text),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultFaqs = [
      {'q': 'help_q1', 'a': 'help_a1'},
      {'q': 'help_q2', 'a': 'help_a2'},
      {'q': 'help_q3', 'a': 'help_a3'},
    ];
    final list = widget.faqs ?? defaultFaqs;
    final filtered = _query.trim().isEmpty
        ? list
        : list
              .where(
                (e) =>
                    tr(e['q']!).toLowerCase().contains(_query.toLowerCase()) ||
                    tr(e['a']!).toLowerCase().contains(_query.toLowerCase()),
              )
              .toList();

    return Scaffold(
      appBar: AppBar(title: Text('help_faq'.tr()), elevation: 0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm câu hỏi...',
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: filtered.isEmpty
                    ? Center(child: Text('help_no_results'.tr()))
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ExpansionTile(
                              title: Text(tr(item['q']!)),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(tr(item['a']!)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
