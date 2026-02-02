import 'package:flutter/material.dart';
import 'dart:async';

class VideoCallPage extends StatefulWidget {
  final String name;
  final String? avatar;

  const VideoCallPage({super.key, required this.name, this.avatar});

  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  bool _isMuted = false;
  bool _isCameraOff = false;
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
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Video người nhận (toàn màn hình)
            Container(
              width: double.infinity,
              height: double.infinity,
              color: const Color(0xFF113953),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
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
              ),
            ),

            // Video của bạn (góc trên bên phải)
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                width: 120,
                height: 160,
                decoration: BoxDecoration(
                  color: _isCameraOff ? const Color(0xFF113953) : Colors.grey[800],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24, width: 2),
                ),
                child: _isCameraOff
                    ? const Center(
                        child: Icon(
                          Icons.videocam_off,
                          color: Colors.white,
                          size: 40,
                        ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 50,
                        ),
                      ),
              ),
            ),

            // Nút minimize
            Positioned(
              top: 20,
              left: 20,
              child: IconButton(
                icon: const Icon(Icons.minimize, color: Colors.white),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),

            // Nút điều khiển (bottom)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 40),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Nút Camera
                    Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: _isCameraOff ? Colors.white : Colors.white24,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(
                              _isCameraOff ? Icons.videocam_off : Icons.videocam,
                              color: _isCameraOff ? const Color(0xFF113953) : Colors.white,
                              size: 28,
                            ),
                            onPressed: () {
                              setState(() {
                                _isCameraOff = !_isCameraOff;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Camera',
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

                    // Nút Đảo camera
                    Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: const BoxDecoration(
                            color: Colors.white24,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.flip_camera_ios,
                              color: Colors.white,
                              size: 28,
                            ),
                            onPressed: () {
                              // Đảo camera
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Đảo',
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
            ),
          ],
        ),
      ),
    );
  }
}
