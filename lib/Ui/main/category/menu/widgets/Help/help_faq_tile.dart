import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class HelpFaqTile extends StatelessWidget {
  final String qKey;
  final String aKey;

  const HelpFaqTile({super.key, required this.qKey, required this.aKey});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(tr(qKey)),
        children: [
          Padding(padding: const EdgeInsets.all(16.0), child: Text(tr(aKey))),
        ],
      ),
    );
  }
}
