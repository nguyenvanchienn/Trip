import 'package:flutter/material.dart';
import 'dart:async';

class VoiceCallPage extends StatefulWidget {
  final String name;
  final String? avatar;

  const VoiceCallPage({super.key, required this.name, this.avatar});

  @override
  State<VoiceCallPage> createState() => _VoiceCallPageState();
}

class _VoiceCallPageState extends State<VoiceCallPage> {
  bool _isMuted = false;
  bool _isSpeaker = false;
  String _callStatus = 'Đang gọi...';
  int _callDuration = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Mô phỏng kết nối sau 3 giây
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _callStatus = 'Đang gọi';
        });
        // Bắt đầu đếm thời gian
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) {
            setState(() {
              _callDuration++;
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF113953),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.minimize, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Avatar và tên
            Column(
              children: [
                CircleAvatar(
                  radius: 70,
                  backgroundColor: Colors.white24,
                  backgroundImage: widget.avatar != null
                      ? NetworkImage(widget.avatar!)
                      : null,
                  child: widget.avatar == null
                      ? const Icon(Icons.person, size: 70, color: Colors.white)
                      : null,
                ),
                const SizedBox(height: 30),
                Text(
                  widget.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _callDuration > 0 ? _formatDuration(_callDuration) : _callStatus,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),

            const Spacer(),

            // Nút điều khiển
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 50),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Nút Loa
                  Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: _isSpeaker ? Colors.white : Colors.white24,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            _isSpeaker ? Icons.volume_up : Icons.volume_off,
                            color: _isSpeaker ? const Color(0xFF113953) : Colors.white,
                            size: 28,
                          ),
                          onPressed: () {
                            setState(() {
                              _isSpeaker = !_isSpeaker;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Loa',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),

                  // Nút Tắt tiếng
                  Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: _isMuted ? Colors.white : Colors.white24,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            _isMuted ? Icons.mic_off : Icons.mic,
                            color: _isMuted ? const Color(0xFF113953) : Colors.white,
                            size: 28,
                          ),
                          onPressed: () {
                            setState(() {
                              _isMuted = !_isMuted;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tắt tiếng',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),

                  // Nút Kết thúc
                  Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.call_end,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Kết thúc',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
