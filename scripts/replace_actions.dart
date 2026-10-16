import 'dart:io';

void main() {
  final files = [
    r'lib\Ui\main\category\menu\widgets\Menu_tienich\Thuephuongtiendichuyen.dart',
    r'lib\Ui\main\category\menu\widgets\Menu_tienich\widgets\amthucvungmien_page.dart',
    r'lib\Ui\main\category\menu\widgets\Menu_tienich\widgets\datvemaybay_page.dart',
    r'lib\Ui\main\category\menu\widgets\Menu_tienich\widgets\datvetauhoa_page.dart',
    r'lib\Ui\main\category\menu\widgets\Menu_tienich\widgets\datvetau_page.dart',
    r'lib\Ui\main\category\menu\widgets\Menu_tienich\widgets\datvexekhach_page.dart',
    r'lib\Ui\main\category\menu\widgets\Menu_tienich\widgets\Thuehuongdanvien_page.dart',
    r'lib\Ui\main\category\menu\widgets\Menu_tienich\widgets\Thuequanaophukien_page.dart',
    r'lib\Ui\main\category\menu\widgets\Menu_tienich\widgets\Thuethochupanh_Page.dart',
    r'lib\Ui\main\category\menu\widgets\Menu_tienich\widgets\Datphongkhachsan\Datphongkhachsan_list.dart'
  ];

  final historyAction = '''
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DonHangCuaBanPage(),
                ),
              );
            },
          ),
        ],
''';

  final importStmt = "import 'package:tourn/Ui/main/category/menu/widgets/Menu_items/widgets/donhangcuaban_page.dart';\n";

  for (var path in files) {
    var file = File(path);
    if (!file.existsSync()) continue;

    var content = file.readAsStringSync();
    bool modified = false;
    
    if (!content.contains('donhangcuaban_page.dart')) {
      content = importStmt + content;
      modified = true;
    }

    if (content.contains('const BusinessAccountAction(),')) {
      content = content.replaceAll(RegExp(r'const BusinessAccountAction\(\),\s*'), '');
      modified = true;
    }

    final regex = RegExp(r'actions:\s*\[[\s\S]*?\],');
    if (regex.hasMatch(content)) {
      content = content.replaceFirst(regex, historyAction.trim());
      modified = true;
    } else {
      if (content.contains('centerTitle: true,')) {
        content = content.replaceFirst('centerTitle: true,', 'centerTitle: true,\n' + historyAction);
        modified = true;
      } else if (content.contains("title: const Text(")) {
        final titleRegex = RegExp(r'title:\s*const Text\([^)]+\),');
        if (titleRegex.hasMatch(content)) {
          content = content.replaceFirstMapped(titleRegex, (match) => match.group(0)! + '\n' + historyAction);
          modified = true;
        }
      } else if (content.contains("title: Text(")) {
        final titleRegex2 = RegExp(r'title:\s*Text\([^)]+\),');
        if (titleRegex2.hasMatch(content)) {
          content = content.replaceFirstMapped(titleRegex2, (match) => match.group(0)! + '\n' + historyAction);
          modified = true;
        }
      } else if (content.contains("title: GestureDetector(")) {
          content = content.replaceFirst('title: GestureDetector(', historyAction + '\ntitle: GestureDetector(');
          modified = true;
      }
    }

    if (modified) {
      file.writeAsStringSync(content);
      print('Updated: \$path');
    }
  }
}
