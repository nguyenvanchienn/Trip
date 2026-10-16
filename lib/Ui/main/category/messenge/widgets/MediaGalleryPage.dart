import 'package:flutter/material.dart';

class MediaGalleryPage extends StatefulWidget {
  final String chatName;

  const MediaGalleryPage({super.key, required this.chatName});

  @override
  State<MediaGalleryPage> createState() => _MediaGalleryPageState();
}

class _MediaGalleryPageState extends State<MediaGalleryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Dữ liệu mẫu
  final List<String> _photos = [
    'asset/images/OIP.jpg',
    'asset/images/OIP.jpg',
    'asset/images/OIP.jpg',
    'asset/images/OIP.jpg',
    'asset/images/OIP.jpg',
    'asset/images/OIP.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF113953),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Ảnh & Video', style: TextStyle(color: Colors.white)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'Ảnh'),
            Tab(text: 'Video'),
            Tab(text: 'File'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab Ảnh
          _photos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_library, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Chưa có ảnh nào',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: EdgeInsets.all(4),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: _photos.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        _openFullScreenGallery(context, index);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          image: DecorationImage(
                            image: AssetImage(_photos[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),

          // Tab Video
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.video_library, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Chưa có video nào',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ),

          // Tab File
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.insert_drive_file, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Chưa có file nào',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openFullScreenGallery(BuildContext context, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            FullScreenGallery(photos: _photos, initialIndex: initialIndex),
      ),
    );
  }
}

class FullScreenGallery extends StatefulWidget {
  final List<String> photos;
  final int initialIndex;

  const FullScreenGallery({
    super.key,
    required this.photos,
    this.initialIndex = 0,
  });

  @override
  State<FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<FullScreenGallery> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.photos.length,
              itemBuilder: (context, index) {
                return Center(
                  child: InteractiveViewer(
                    panEnabled: true,
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.asset(
                      widget.photos[index],
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                );
              },
            ),

            // Close button
            Positioned(
              top: 12,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            // Page indicator
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
