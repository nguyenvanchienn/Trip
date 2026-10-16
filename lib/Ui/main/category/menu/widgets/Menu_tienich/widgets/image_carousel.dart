import 'package:flutter/material.dart';
import 'package:tourn/ultils.enums/image_utils.dart';

class ImageCarousel extends StatefulWidget {
  final List<String> images;
  final BoxFit fit;

  const ImageCarousel({
    super.key,
    required this.images,
    this.fit = BoxFit.cover,
  });

  @override
  State<ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  int _currentIndex = 0;

  void _openFullScreen(BuildContext context, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: PageView.builder(
            controller: PageController(initialPage: initialIndex),
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              final imgUrl = widget.images[index];
              return InteractiveViewer(
                child: Center(
                  child:
                      imgUrl.startsWith('http') ||
                          imgUrl.startsWith('data:image')
                      ? Image(
                          image:
                              getImageProvider(imgUrl) ??
                              const AssetImage('asset/images/anhdemo.jpeg')
                                  as ImageProvider,
                          fit: BoxFit.contain,
                        )
                      : Image.asset(imgUrl, fit: BoxFit.contain),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return Container(
        color: Colors.grey[300],
        child: const Center(child: Icon(Icons.image, size: 50)),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          itemCount: widget.images.length,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          itemBuilder: (context, index) {
            final imgUrl = widget.images[index];
            return GestureDetector(
              onTap: () => _openFullScreen(context, index),
              child:
                  imgUrl.startsWith('http') || imgUrl.startsWith('data:image')
                  ? Image(
                      image:
                          getImageProvider(imgUrl) ??
                          const AssetImage('asset/images/anhdemo.jpeg')
                              as ImageProvider,
                      fit: widget.fit,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.image, size: 100),
                    )
                  : Image.asset(
                      imgUrl,
                      fit: widget.fit,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.image, size: 100),
                    ),
            );
          },
        ),
        if (widget.images.isNotEmpty)
          Positioned(
            bottom: 8,
            right: 8,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_currentIndex + 1}/${widget.images.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
