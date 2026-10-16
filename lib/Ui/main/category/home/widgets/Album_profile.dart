// Album grid for profile page
import 'package:flutter/material.dart';
import 'package:tourn/Ui/main/category/home/widgets/button_add/create_album.dart';
import 'package:tourn/Ui/main/category/home/widgets/detail_album.dart';

class AlbumProfile extends StatelessWidget {
  const AlbumProfile({super.key});

  static final List<_AlbumItem> _albums = [
    _AlbumItem(title: 'Đà Nẵng Travel', image: 'asset/images/Group 151.png'),
    _AlbumItem(title: 'Ninh Bình Travel', image: 'asset/images/anh-mo-ta.jpg'),
    _AlbumItem(title: 'Hà Nội Travel', image: 'asset/images/OIP.jpg'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top actions row
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            ],
          ),

          const SizedBox(height: 8),

          // Grid of albums
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.0,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              // album tiles
              ..._albums.map((a) => _AlbumTile(album: a)),

              // add album tile
              _AddAlbumTile(),
            ],
          ),
        ],
      ),
    );
  }
}

class _AlbumItem {
  final String title;
  final String image;
  const _AlbumItem({required this.title, required this.image});
}

class _AlbumTile extends StatelessWidget {
  final _AlbumItem album;
  const _AlbumTile({required this.album});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  album.image,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Icon(Icons.image, size: 40, color: Colors.black26),
                    ),
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const DetailAlbum()),
                      );
                    },
                    splashColor: Colors.black26,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          album.title,
          style: const TextStyle(fontSize: 13),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _AddAlbumTile extends StatelessWidget {
  const _AddAlbumTile();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateAlbum()),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
                color: Colors.white,
              ),
              child: const Center(
                child: Icon(Icons.add, size: 36, color: Colors.black26),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Album',
          style: TextStyle(fontSize: 13),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
