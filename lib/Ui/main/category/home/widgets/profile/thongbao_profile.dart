import 'package:flutter/material.dart';
import 'package:tourn/domain/user_repository/user_repository.dart';
import 'package:tourn/models/user_model.dart';
import 'package:tourn/Ui/main/category/home/widgets/profile/Profile.dart';

/// Simple model used by this screen.  In a real app you'd replace this
/// with your user/domain object and fetch it from a repository.
class _FollowedUser {
  /// primary text shown in the list tile (usually display name)
  final String title;

  /// secondary text shown below (could be uid or username)
  final String subtitle;
  final String avatarUrl;

  /// user-specific notification preferences, same values as in Profile
  /// ('all','best','off').
  final Map<String, String> notifPrefs;

  _FollowedUser({
    required this.title,
    required this.subtitle,
    required this.avatarUrl,
    Map<String, String>? notifPrefs,
  }) : notifPrefs =
           notifPrefs ??
           {'post': 'best', 'story': 'best', 'reels': 'best', 'live': 'best'};
}

class ThongbaoProfile extends StatefulWidget {
  const ThongbaoProfile({super.key});

  @override
  State<ThongbaoProfile> createState() => _ThongbaoProfileState();
}

class _ThongbaoProfileState extends State<ThongbaoProfile> {
  final TextEditingController _searchController = TextEditingController();
  String _sortLabel = 'Mặc định';

  /// currently applied sort type key (null means alphabetical)
  String? _sortType;
  // repository used to load user data
  final UserRepository _userRepo = FirestoreUserRepository();

  // data shown in the list - initially empty then populated from Firebase
  List<_FollowedUser> _users = [];
  String? _errorMessage;
  String? _debugInfo; // info displayed at top for debugging

  // record anchor position of the prefs menu so reopening after a submenu
  // uses the same vertical coordinate instead of jumping to the tap location
  Offset? _prefsMenuAnchor;

  // multi-selection state
  final Set<int> _selectedIndices = {}; // indices of users currently selected

  /// user has tapped "Chọn" and enters selection UI
  bool _isSelecting = false;

  bool get _selectionMode => _isSelecting || _selectedIndices.isNotEmpty;

  // (moved to field declaration; list will be filled from repository)

  @override
  void initState() {
    super.initState();
    _subscribeFollowing();
  }

  Future<void> _subscribeFollowing() async {
    // listen to changes in the current user's document so we always have the
    // most up-to-date list of accounts they follow.  Instead of querying other
    // users' followers arrays (which may be out-of-sync), we simply read the
    // `following` field from the current user and fetch those profiles.
    _userRepo.streamCurrentUser().listen((current) async {
      // clear previous messages each update
      setState(() {
        _debugInfo = 'stream event';
        _errorMessage = null;
      });
      debugPrint('streamCurrentUser update: $current');
      if (!mounted || current == null) return;
      final ids = current.following;
      debugPrint('following ids: $ids');
      setState(() {
        _debugInfo = 'ids: $ids';
      });
      if (ids.isEmpty) {
        setState(() {
          _users = [];
        });
        return;
      }
      // fetch each user by id; we could optimize with a whereIn query but
      // that has limits, so we'll just do individual requests for now.
      final futures = ids.map((id) => _userRepo.getUserById(id)).toList();
      final results = await Future.wait(futures);
      debugPrint('fetched profiles: ${results.length}');
      if (!mounted) return;
      setState(() {
        _users = results
            .whereType<UserModel>()
            .map(
              (u) => _FollowedUser(
                // primary text = displayName or email prefix
                title: u.displayName.isNotEmpty
                    ? u.displayName
                    : u.email.split('@').first,
                // secondary text = uid for debugging/identification
                subtitle: u.uid,
                avatarUrl: u.photoUrl ?? '',
              ),
            )
            .toList();
      });
      // reapply current sort order to new list
      _applySort();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // not used any more; preferences are edited via popup

  /// apply given preference (all/best/off) to every content type of all
  /// currently selected users, then exit selection mode.
  void _applyBulk(String pref) {
    setState(() {
      for (final idx in _selectedIndices) {
        final user = _users[idx];
        user.notifPrefs.updateAll((key, value) => pref);
      }
      _selectedIndices.clear();
      _isSelecting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle:
            true, // giữa tiêu đề để cân đối với nút "Hủy" khi ở chế độ chọn
        title: _selectionMode
            ? Text(
                'Chọn (${_selectedIndices.length})',
                style: const TextStyle(fontSize: 18),
              )
            : const Text(
                'Từ tài khoản bạn theo dõi',
                style: TextStyle(fontSize: 18),
              ),
        leading: _selectionMode
            ? TextButton(
                onPressed: () => setState(() {
                  _isSelecting = false;
                  _selectedIndices.clear();
                }),
                child: const Text('Hủy', style: TextStyle(color: Colors.blue)),
              )
            : BackButton(onPressed: () => Navigator.pop(context)),
        actions: _selectionMode
            ? null
            : [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isSelecting = true;
                    });
                  },
                  child: const Text('Chọn'),
                ),
              ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                const Text('Sắp xếp theo '),
                Text(
                  _sortLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                GestureDetector(
                  onTapDown: (details) {
                    _showSortMenu(context, details.globalPosition);
                  },
                  child: const Icon(Icons.sort),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _errorMessage != null
                ? Center(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                : ListView.builder(
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      if (_searchController.text.isNotEmpty &&
                          !user.title.toLowerCase().contains(
                            _searchController.text.toLowerCase(),
                          )) {
                        return const SizedBox.shrink();
                      }
                      return ListTile(
                        // left inset 12px, right inset handled by trailing padding so icon
                        // ends up exactly 12px from screen edge
                        contentPadding: const EdgeInsets.only(
                          left: 12,
                          right: 0,
                        ),
                        onTap: () {
                          if (_selectionMode) {
                            setState(() {
                              if (_selectedIndices.contains(index)) {
                                _selectedIndices.remove(index);
                              } else {
                                _selectedIndices.add(index);
                              }
                            });
                          } else {
                            // normal tap does nothing when not selecting; bell icon handles prefs
                          }
                        },
                        leading: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            // push profile for this user
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => Profile(userId: user.subtitle),
                              ),
                            );
                          },
                          child: CircleAvatar(
                            backgroundImage: user.avatarUrl.isNotEmpty
                                ? NetworkImage(user.avatarUrl)
                                : null,
                            child: user.avatarUrl.isEmpty
                                ? const Icon(Icons.person)
                                : null,
                          ),
                        ),
                        title: Text(user.title),
                        subtitle: Text(user.subtitle),
                        trailing: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: _selectionMode
                              ? Icon(
                                  _selectedIndices.contains(index)
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                )
                              : GestureDetector(
                                  onTapDown: (details) {
                                    _openPrefsMenu(
                                      context,
                                      details.globalPosition,
                                      index,
                                    );
                                  },
                                  child: Icon(
                                    // show enabled/disabled bell based on post preference
                                    user.notifPrefs['post'] == 'off'
                                        ? Icons.notifications_none
                                        : Icons.notifications,
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _selectionMode
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // disable if nothing selected
                        Builder(
                          builder: (ctx) {
                            final hasSel = _selectedIndices.isNotEmpty;
                            return Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: TextButton(
                                    onPressed: hasSel
                                        ? () => _applyBulk('all')
                                        : null,
                                    style: TextButton.styleFrom(
                                      backgroundColor: hasSel
                                          ? Colors.grey.shade300
                                          : Colors.grey.shade200,
                                      foregroundColor: hasSel
                                          ? Colors.black
                                          : Colors.black38,
                                    ),
                                    child: const Text('Tất cả'),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                SizedBox(
                                  width: double.infinity,
                                  child: TextButton(
                                    onPressed: hasSel
                                        ? () => _applyBulk('best')
                                        : null,
                                    style: TextButton.styleFrom(
                                      backgroundColor: hasSel
                                          ? Colors.blue
                                          : Colors.blue[100],
                                      foregroundColor: hasSel
                                          ? Colors.white
                                          : Colors.white38,
                                    ),
                                    child: const Text('Phù hợp nhất'),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                SizedBox(
                                  width: double.infinity,
                                  child: TextButton(
                                    onPressed: hasSel
                                        ? () => _applyBulk('off')
                                        : null,
                                    style: TextButton.styleFrom(
                                      backgroundColor: hasSel
                                          ? Colors.black54
                                          : Colors.black26,
                                      foregroundColor: hasSel
                                          ? Colors.white
                                          : Colors.white38,
                                    ),
                                    child: const Text('Tắt'),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Các thay đổi đã chọn áp dụng cho mọi loại nội dung.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            )
          : null,
    );
  }

  Future<void> _openPrefsMenu(
    BuildContext context,
    Offset position,
    int userIndex,
  ) async {
    // remember anchor so reopen uses same dy rather than the point where
    // the user tapped in the submenu (which is typically lower)
    _prefsMenuAnchor = position;

    final user = _users[userIndex];
    final screenW = MediaQuery.of(context).size.width;
    final centerX = screenW / 2;
    // fixed width for every menu
    final menuWidth = screenW * 0.51;

    Widget fixedText(String text, {TextStyle? style}) {
      return SizedBox(
        width: menuWidth,
        child: Text(
          text,
          style: style,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      );
    }

    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        centerX,
        // use stored anchor when available
        (_prefsMenuAnchor ?? position).dy,
        centerX,
        (_prefsMenuAnchor ?? position).dy,
      ),
      items: <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          enabled: false,
          height: 40,
          child: fixedText(
            'Thông báo từ ${user.title}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
        const PopupMenuDivider(),
        // each main item is wrapped in GestureDetector so that tapping it
        // opens a second-level menu rather than immediately selecting
        // the value.
        PopupMenuItem<String>(
          value: 'post',
          height: 40,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) {
              // close main menu then show submenu
              Navigator.pop(context);
              Future.microtask(
                () => _showPrefOptions(
                  context,
                  details.globalPosition,
                  userIndex,
                  'post',
                ),
              );
            },
            child: _prefTile('Bài viết', user.notifPrefs['post'] ?? 'best'),
          ),
        ),
        PopupMenuItem<String>(
          value: 'story',
          height: 40,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) {
              Navigator.pop(context);
              Future.microtask(
                () => _showPrefOptions(
                  context,
                  details.globalPosition,
                  userIndex,
                  'story',
                ),
              );
            },
            child: _prefTile('Tin', user.notifPrefs['story'] ?? 'best'),
          ),
        ),
        PopupMenuItem<String>(
          value: 'reels',
          height: 40,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) {
              Navigator.pop(context);
              Future.microtask(
                () => _showPrefOptions(
                  context,
                  details.globalPosition,
                  userIndex,
                  'reels',
                ),
              );
            },
            child: _prefTile('Reels', user.notifPrefs['reels'] ?? 'best'),
          ),
        ),
        PopupMenuItem<String>(
          value: 'live',
          height: 40,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) {
              Navigator.pop(context);
              Future.microtask(
                () => _showPrefOptions(
                  context,
                  details.globalPosition,
                  userIndex,
                  'live',
                ),
              );
            },
            child: _prefTile(
              'Video trực tiếp',
              user.notifPrefs['live'] ?? 'best',
            ),
          ),
        ),
      ],
    );

    if (selected != null) {
      setState(() {
        // toggle between 'best' and 'off' for demonstration
        final current = user.notifPrefs[selected] ?? 'best';
        user.notifPrefs[selected] = current == 'off' ? 'best' : 'off';
      });
    }
  }

  /// secondary menu shown after tapping a main item
  Future<void> _showPrefOptions(
    BuildContext context,
    Offset position,
    int userIndex,
    String type,
  ) async {
    final user = _users[userIndex];
    final screenW = MediaQuery.of(context).size.width;
    final centerX = screenW / 2;
    final menuWidth = screenW * 0.75;

    Widget fixedText(String text, {TextStyle? style}) {
      return SizedBox(
        width: menuWidth,
        child: Text(
          text,
          style: style,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      );
    }

    final chosen = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        centerX,
        position.dy,
        centerX,
        position.dy,
      ),
      items: <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          enabled: false,
          child: fixedText(
            type == 'post'
                ? 'Bài viết'
                : type == 'story'
                ? 'Tin'
                : type == 'reels'
                ? 'Reels'
                : 'Video trực tiếp',
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'all',
          height: 40,
          child: fixedText('Tất cả'),
        ),
        PopupMenuItem<String>(
          value: 'best',
          height: 40,
          child: fixedText('Phù hợp nhất'),
        ),
        PopupMenuItem<String>(
          value: 'off',
          height: 40,
          child: fixedText('Tắt'),
        ),
      ],
    );

    if (chosen != null) {
      setState(() {
        user.notifPrefs[type] = chosen;
      });
      // reopen the main menu so user can choose another thing or close
      await _openPrefsMenu(context, _prefsMenuAnchor ?? position, userIndex);
    }
  }

  /// Displays the drop‑down used by the sort icon.
  Future<void> _showSortMenu(BuildContext context, Offset position) async {
    final screenW = MediaQuery.of(context).size.width;
    final centerX = screenW / 2;
    final chosen = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        centerX,
        position.dy,
        centerX,
        position.dy,
      ),
      items: <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          enabled: false,
          height: 32,
          child: Text('Sắp xếp theo', style: TextStyle(fontSize: 14)),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem<String>(
          value: 'Mặc định',
          height: 32,
          child: const Text('Mặc định', style: TextStyle(fontSize: 14)),
        ),
        PopupMenuItem<String>(
          value: 'Nhiều bài viết nhất',
          height: 32,
          child: const Text('Bài viết', style: TextStyle(fontSize: 14)),
        ),
        PopupMenuItem<String>(
          value: 'Nhiều tin nhất',
          height: 32,
          child: const Text('Tin', style: TextStyle(fontSize: 14)),
        ),
        PopupMenuItem<String>(
          value: 'Nhiều thươc phim nhất',
          height: 32,
          child: const Text('Thước phim', style: TextStyle(fontSize: 14)),
        ),
        PopupMenuItem<String>(
          value: 'Nhiều video trực tiếp nhất',
          height: 32,
          child: const Text('Video trực tiếp', style: TextStyle(fontSize: 14)),
        ),
      ],
    );
    if (chosen != null) {
      setState(() {
        _sortLabel = chosen;
      });
      _applySort();
    }
  }

  /// Sorts the local _users list according to the current _sortLabel.
  void _applySort() {
    // determine sort key based on label
    switch (_sortLabel) {
      case 'Mặc định':
        _sortType = null;
        break;
      case 'Bài viết':
        _sortType = 'post';
        break;
      case 'Tin':
        _sortType = 'story';
        break;
      case 'Thước phim':
        _sortType = 'reels';
        break;
      case 'Video trực tiếp':
        _sortType = 'live';
        break;
      default:
        _sortType = null;
    }
    if (_sortType == null) {
      _users.sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );
    } else {
      final order = {'all': 0, 'best': 1, 'off': 2};
      _users.sort((a, b) {
        final va = order[a.notifPrefs[_sortType!] ?? 'best']!;
        final vb = order[b.notifPrefs[_sortType!] ?? 'best']!;
        return va.compareTo(vb);
      });
    }
    // refresh UI
    setState(() {});
  }

  Widget _prefTile(String label, String pref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          pref == 'all'
              ? 'Tất cả'
              : pref == 'best'
              ? 'Phù hợp nhất'
              : 'Tắt',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}
