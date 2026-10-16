import 'package:flutter/material.dart';
import 'dart:async';

class VoiceCallPage extends StatefulWidget {
  final String name;
  final String? avatar;
  final String? conversationId;
  final Function(int duration, bool answered)? onCallEnded;

  const VoiceCallPage({
    super.key,
    required this.name,
    this.avatar,
    this.conversationId,
    this.onCallEnded,
  });

  @override
  State<VoiceCallPage> createState() => _VoiceCallPageState();
}

class _VoiceCallPageState extends State<VoiceCallPage> {
  bool _isMuted = false;
  bool _isSpeaker = false;
  String _callStatus = 'Đang đổ chuông...';
  int _callDuration = 0;
  Timer? _timer;
  bool _isConnected = false;
  int _ringDuration = 0;
  Timer? _ringTimer;

  @override
  void initState() {
    super.initState();
    // Start ring timer to show how long we've been calling
    _ringTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && !_isConnected) {
        setState(() {
          _ringDuration++;
          // After 30 seconds of ringing, consider it missed
          if (_ringDuration >= 30) {
            _endCall();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ringTimer?.cancel();
    super.dispose();
  }

  void _answerCall() {
    if (_isConnected) return;
    _ringTimer?.cancel();
    setState(() {
      _callStatus = 'Đang gọi';
      _isConnected = true;
    });
    // Start call duration timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _callDuration++;
        });
      }
    });
  }

  void _endCall() {
    _timer?.cancel();
    _ringTimer?.cancel();
    // Call the callback with duration and whether call was answered
    widget.onCallEnded?.call(_callDuration, _isConnected);
    Navigator.pop(context, {
      'duration': _callDuration,
      'answered': _isConnected,
    });
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
                    onPressed: _endCall,
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
                  _callDuration > 0
                      ? _formatDuration(_callDuration)
                      : _callStatus,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
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
                            color: _isSpeaker
                                ? const Color(0xFF113953)
                                : Colors.white,
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
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),

                  // Nút Nghe máy (chỉ hiện khi đang đổ chuông - để test)
                  if (!_isConnected)
                    Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.call,
                              color: Colors.white,
                              size: 28,
                            ),
                            onPressed: _answerCall,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Nghe máy',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),

                  // Nút Tắt tiếng (chỉ hiện khi đã kết nối)
                  if (_isConnected)
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
                              color: _isMuted
                                  ? const Color(0xFF113953)
                                  : Colors.white,
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
                          style: TextStyle(color: Colors.white, fontSize: 12),
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
                          onPressed: _endCall,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Kết thúc',
                        style: TextStyle(color: Colors.white, fontSize: 12),
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
