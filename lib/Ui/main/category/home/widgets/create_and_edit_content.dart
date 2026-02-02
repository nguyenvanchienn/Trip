// đây là file chứa code của trang tạo và chỉnh sửa bài viết trong phần home
import 'package:flutter/material.dart';
import 'package:tourn/Ui/main/category/home/widgets/next_page.dart';

class createandeditcontent extends StatefulWidget {
  const createandeditcontent({super.key});

  @override
  State<createandeditcontent> createState() => _createandeditcontentState();
}

class _createandeditcontentState extends State<createandeditcontent> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final GlobalKey _textFieldKey = GlobalKey();
  final DraggableScrollableController _draggableController =
      DraggableScrollableController();
  bool _sheetAttached = false;

  bool isTyping = false;
  final ValueNotifier<Color> _bgColor = ValueNotifier<Color>(Colors.black);
  final int _minLinesCount = 7;
  static const double _typingPanelHeight = 120.0;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    final hasFocus = _focusNode.hasFocus;
    if (mounted) {
      setState(() {
        isTyping = hasFocus;
      });
    }
    if (hasFocus) {
      // when typing, the sheet is not attached
      _sheetAttached = false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _draggableController.dispose();
    _bgColor.dispose();
    super.dispose();
  }

  void _safeAnimateTo(
    double target, {
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOut,
  }) {
    if (!_sheetAttached) return;
    _draggableController.animateTo(target, duration: duration, curve: curve);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: GestureDetector(
          onTap: () {
            // Close without animating the sheet to avoid UI hangs when
            // popping the route during an ongoing sheet animation.
            FocusScope.of(context).unfocus();
            Navigator.of(context).maybePop();
          },
          child: const Icon(Icons.close, color: Colors.white),
        ),
        centerTitle: true,
        title: GestureDetector(
          onTap: () {
            _safeAnimateTo(0.35);
          },
          child: const Text(
            'Tạo bài viết',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 20,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                _safeAnimateTo(0.35);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const next()),
                );
              },
              child: const Text(
                'Tiếp',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          if (_focusNode.hasFocus) {
            FocusScope.of(context).unfocus();
            setState(() {
              isTyping = false;
            });
            try {
              final double size = _draggableController.size;
              const double initial = 0.35;
              if (size > initial + 0.01) {
                _safeAnimateTo(initial);
              }
            } catch (_) {}
          }
        },
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: Column(children: [Flexible(child: _buildTextField())]),
                ),
              ],
            ),
            if (isTyping)
              Positioned(
                left: 0,
                right: 0,
                bottom: MediaQuery.of(context).viewInsets.bottom,
                height: _typingPanelHeight,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 8),
                      Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white70,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: _typingOptions(),
                      ),
                    ],
                  ),
                ),
              )
            else
              DraggableScrollableSheet(
                controller: _draggableController,
                initialChildSize: 0.35,
                minChildSize: 0.2,
                maxChildSize: 0.9,
                builder: (context, scrollController) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _sheetAttached = true;
                  });

                  return Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 8),
                        Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white70,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: ListView(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            children: const [
                              _OptionTile(
                                Icons.image,
                                Colors.green,
                                'Ảnh/video',
                              ),
                              _OptionTile(
                                Icons.person_add,
                                Colors.blue,
                                'Gắn thẻ người khác',
                              ),
                              _OptionTile(
                                Icons.emoji_emotions,
                                Colors.orange,
                                'Cảm xúc/hoạt động',
                              ),
                              _OptionTile(
                                Icons.location_on,
                                Colors.red,
                                'Check in',
                              ),
                              _OptionTile(
                                Icons.videocam,
                                Colors.pink,
                                'Video trực tiếp',
                              ),
                              _OptionTile(
                                Icons.text_fields,
                                Colors.cyan,
                                'Màu nền',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundImage: AssetImage('asset/images/employee-5.png'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nguyễn Chiến',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _pill('Công khai'),
                    _pill('+ Album'),
                    _pill('Tắt'),
                    _pill('+ Nhãn AI đang tắt'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade800,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        softWrap: true,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  Widget _buildTextField() {
    final double fontSize = 20;
    final double lineHeightPx = fontSize * 1.2;
    final double verticalPadding = 16;
    final double fixedHeight =
        (lineHeightPx * _minLinesCount) + verticalPadding;

    return ValueListenableBuilder<Color>(
      valueListenable: _bgColor,
      builder: (context, bg, _) {
        final textColor = bg.computeLuminance() > 0.5
            ? Colors.black
            : Colors.white;
        return Container(
          key: _textFieldKey,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          color: bg,
          child: SizedBox(
            height: fixedHeight,
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              minLines: _minLinesCount,
              maxLines: _minLinesCount,
              style: TextStyle(fontSize: fontSize, color: textColor),
              decoration: InputDecoration(
                hintText: 'Bạn đang nghĩ gì?',
                hintStyle: TextStyle(color: textColor.withOpacity(0.6)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              keyboardType: TextInputType.multiline,
            ),
          ),
        );
      },
    );
  }

  Widget _typingOptions() {
    final icons = const [
      [Icons.image, Colors.green],
      [Icons.person_add, Colors.blue],
      [Icons.emoji_emotions, Colors.orange],
      [Icons.location_on, Colors.red],
      [Icons.videocam, Colors.pink],
      [Icons.image, Colors.green],
      [Icons.person_add, Colors.blue],
      [Icons.emoji_emotions, Colors.orange],
      [Icons.location_on, Colors.red],
      [Icons.videocam, Colors.pink],
    ];

    return Column(
      children: [
        _buildColorPicker(),
        const SizedBox(height: 2),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemBuilder: (context, index) => _OptionIcon(
              icons[index][0] as IconData,
              icons[index][1] as Color,
            ),
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemCount: icons.length,
          ),
        ),
      ],
    );
  }

  Widget _buildColorPicker() {
    final colors = [
      Colors.white,
      Colors.blue,
      Colors.cyan,
      Colors.purple,
      Colors.red,
      Colors.orange,
      Colors.black,
    ];

    return SizedBox(
      height: 36,
      child: ValueListenableBuilder<Color>(
        valueListenable: _bgColor,
        builder: (context, bg, _) {
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            itemBuilder: (_, i) => Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () {
                  final hadFocus = _focusNode.hasFocus;
                  _bgColor.value = colors[i];
                  if (hadFocus) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted)
                        FocusScope.of(context).requestFocus(_focusNode);
                    });
                  }
                },
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: colors[i],
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: bg == colors[i]
                                ? (colors[i].computeLuminance() > 0.5
                                      ? Colors.black
                                      : Colors.white)
                                : Colors.white24,
                            width: bg == colors[i] ? 2 : 1,
                          ),
                        ),
                      ),
                      if (bg == colors[i])
                        Icon(
                          Icons.check,
                          size: 16,
                          color: colors[i].computeLuminance() > 0.5
                              ? Colors.black
                              : Colors.white,
                        ),
                    ],
                  ),
                ),
              ),
            ),
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemCount: colors.length,
          );
        },
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;

  const _OptionTile(this.icon, this.color, this.title);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      onTap: () {},
    );
  }
}

class _OptionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _OptionIcon(this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Icon(icon, color: color, size: 28);
  }
}
