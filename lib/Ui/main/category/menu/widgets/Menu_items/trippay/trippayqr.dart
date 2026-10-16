import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'qrcuatoi.dart';

class Trippayqr extends StatefulWidget {
  const Trippayqr({super.key});

  @override
  State<Trippayqr> createState() => _TrippayqrState();
}

class _TrippayqrState extends State<Trippayqr> {
  String? result;
  final MobileScannerController _cameraController = MobileScannerController();
  bool _torchOn = false;

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // use a transparent appbar to place icons over camera
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Quét mã QR', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(
              _torchOn ? Icons.flash_off : Icons.flash_on,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _torchOn = !_torchOn;
              });
              _cameraController.toggleTorch();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // camera preview
          MobileScanner(
            controller: _cameraController,
            onDetect: (capture) {
              if (capture.barcodes.isEmpty) return;
              final barcode = capture.barcodes.first;
              final code = barcode.rawValue;
              if (code != null && code != result) {
                setState(() => result = code);
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Đã quét được mã'),
                    content: Text(code),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        child: const Text('Thanh toán'),
                      ),
                    ],
                  ),
                );
              }
            },
          ),

          // gold scanning frame
          Center(
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.orange, width: 4),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          // top instruction overlay
          Positioned(
            top: kToolbarHeight + 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Di chuyển camera vào mã QR',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),

          // bottom panel with accepted codes and actions
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black54,
              padding: const EdgeInsets.only(top: 12, bottom: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _actionButton(
                        Icons.qr_code,
                        'QR của tôi',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const Qrcuatoi()),
                          );
                        },
                      ),
                      _actionButton(
                        Icons.image,
                        'Tải ảnh lên',
                        onTap: () {
                          // TODO: handle upload image
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            backgroundColor: Colors.orange,
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
