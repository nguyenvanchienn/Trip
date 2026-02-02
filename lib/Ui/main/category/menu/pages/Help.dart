import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Help/help_quick_action.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Help/help_topic_card.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Help/help_faq_tile.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Help/help_topic_page.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Help/help_faq_page.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Help/help_community_page.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Help/help_contact_page.dart';

class Help extends StatefulWidget {
  const Help({super.key});

  @override
  State<Help> createState() => _HelpState();
}

class _HelpState extends State<Help> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  final List<Map<String, String>> _faq = [
    {'q': 'help_q1', 'a': 'help_a1'},
    {'q': 'help_q2', 'a': 'help_a2'},
    {'q': 'help_q3', 'a': 'help_a3'},
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, String>> get _filteredFAQs {
    if (_query.trim().isEmpty) return _faq;
    final q = _query.toLowerCase();
    return _faq
        .where(
          (e) =>
              tr(e['q']!).toLowerCase().contains(q) ||
              tr(e['a']!).toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('help_title'.tr()), elevation: 0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search field
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'help_search_hint'.tr(),
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),

              const SizedBox(height: 12),

              // Quick actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: HelpQuickAction(
                      icon: Icons.question_answer_outlined,
                      label: 'help_faq'.tr(),
                      onTap: () => _openFaq(),
                    ),
                  ),
                  Expanded(
                    child: HelpQuickAction(
                      icon: Icons.group_outlined,
                      label: 'help_community'.tr(),
                      onTap: () => _openCommunity(),
                    ),
                  ),
                  Expanded(
                    child: HelpQuickAction(
                      icon: Icons.support_agent_outlined,
                      label: 'help_contact_support'.tr(),
                      onTap: () => _openContact(),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Trending topics header
              Text(
                'help_trending_topics'.tr(),
                style: Theme.of(context).textTheme.titleMedium,
              ),

              const SizedBox(height: 8),

              // Trending topics horizontal list
              SizedBox(
                height: 110,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 6,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, idx) => HelpTopicCard(
                    topic: '#Topic${idx + 1}',
                    onTap: () => _openTopic('#Topic${idx + 1}'),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // FAQs
              Expanded(
                child: _filteredFAQs.isEmpty
                    ? Center(child: Text('help_no_results'.tr()))
                    : ListView.builder(
                        itemCount: _filteredFAQs.length,
                        itemBuilder: (context, index) {
                          final item = _filteredFAQs[index];
                          return HelpFaqTile(
                            qKey: item['q']!,
                            aKey: item['a']!,
                          );
                        },
                      ),
              ),

              // Contact support action
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _openContact,
                  icon: const Icon(Icons.support_agent),
                  label: Text('help_get_support'.tr()),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openContact() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const HelpContactPage()));
  }

  void _openCommunity() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const HelpCommunityPage()));
  }

  void _openFaq() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => HelpFaqPage(faqs: _faq)));
  }

  void _openTopic(String topic) {
    final key = topic.replaceAll('#', '').toLowerCase();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => HelpTopicPage(displayTitle: topic, topicKey: key),
      ),
    );
  }
}
