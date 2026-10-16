import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tourn/models/story_model.dart';
import 'package:tourn/data/firebase/firebase_story_service.dart';
import 'package:tourn/ultils.enums/image_utils.dart';
import 'story_viewer.dart';

/// Avatar widget that shows story ring when user has active stories
/// Tap on avatar opens story viewer if user has stories, otherwise calls onTap
class StoryAvatar extends StatelessWidget {
  final String? userId;
  final String? photoUrl;
  final String? userName;
  final double radius;
  final VoidCallback? onTap;
  final bool showStoryRing;

  const StoryAvatar({
    super.key,
    this.userId,
    this.photoUrl,
    this.userName,
    this.radius = 22,
    this.onTap,
    this.showStoryRing = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!showStoryRing || userId == null || userId!.isEmpty) {
      return _buildSimpleAvatar(context, hasStory: false, stories: []);
    }

    return StreamBuilder<List<StoryModel>>(
      stream: _getUserActiveStories(userId!),
      builder: (context, snapshot) {
        final stories = snapshot.data ?? [];
        final hasStory = stories.isNotEmpty;

        return _buildAvatarWithStoryRing(
          context,
          hasStory: hasStory,
          stories: stories,
        );
      },
    );
  }

  Stream<List<StoryModel>> _getUserActiveStories(String userId) {
    final now = DateTime.now();
    return FirebaseFirestore.instance
        .collection('stories')
        .where('authorId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => StoryModel.fromFirestore(doc))
              .where((story) => !story.isExpired)
              .toList();
        });
  }

  Widget _buildAvatarWithStoryRing(
    BuildContext context, {
    required bool hasStory,
    required List<StoryModel> stories,
  }) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    // Check if user has viewed all stories
    final hasUnviewedStory =
        hasStory &&
        stories.any(
          (story) => currentUid != null && !story.viewers.contains(currentUid),
        );

    return GestureDetector(
      onTap: () {
        if (hasStory && stories.isNotEmpty) {
          _showStoryViewer(context, stories);
        } else {
          onTap?.call();
        }
      },
      child: Container(
        width: (radius + 4) * 2,
        height: (radius + 4) * 2,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: hasStory
              ? (hasUnviewedStory
                    ? const LinearGradient(
                        colors: [Color(0xFF113953), Color(0xFF2196F3)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [Colors.grey[400]!, Colors.grey[300]!],
                      ))
              : null,
          border: hasStory
              ? null
              : Border.all(color: Colors.grey.shade200, width: 1),
        ),
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          padding: hasStory ? const EdgeInsets.all(2) : EdgeInsets.zero,
          child: _buildAvatarImage(),
        ),
      ),
    );
  }

  Widget _buildSimpleAvatar(
    BuildContext context, {
    required bool hasStory,
    required List<StoryModel> stories,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade200, width: 1),
        ),
        child: _buildAvatarImage(),
      ),
    );
  }

  Widget _buildAvatarImage() {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[200],
      backgroundImage: photoUrl != null && photoUrl!.isNotEmpty
          ? getImageProvider(photoUrl!)
          : const AssetImage('asset/images/OIP.jpg') as ImageProvider,
    );
  }

  void _showStoryViewer(BuildContext context, List<StoryModel> stories) {
    final storyService = FirebaseStoryService();
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          return StoryViewerFirebase(
            stories: stories,
            initialIndex: 0,
            storyService: storyService,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
}
