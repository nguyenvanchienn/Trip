// File này chứa phiên bản tích hợp Firebase cho RecentChats
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:tourn/domain/message_repository/message_repository.dart';
import 'package:tourn/models/conversation_model.dart';
import 'package:tourn/models/message_model.dart';
import 'package:tourn/models/user_model.dart';
import 'package:tourn/Ui/main/category/messenge/widgets/kholuutru.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tourn/domain/user_repository/user_repository.dart';
// pages for restriction/limiting users
import 'package:tourn/Ui/main/category/menu/widgets/Settings/quyenriengtuvaantoan/hanche.dart';
import 'package:tourn/data/firebase/firebase_user_service.dart';
import 'package:tourn/data/firebase/firebase_account_service.dart';
import 'package:tourn/data/firebase/firebase_business_service.dart';
import 'package:tourn/Ui/main/category/home/widgets/profile/Profile.dart';
import 'dart:io';
import 'package:record/record.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tourn/ultils.enums/image_utils.dart';
import 'package:tourn/Ui/main/category/messenge/widgets/MessageBubble.dart';
import 'package:tourn/Ui/main/category/messenge/widgets/VoiceCallPage.dart';
import 'package:tourn/Ui/main/category/messenge/widgets/VideoCallPage.dart';
import 'package:tourn/Ui/main/category/home/widgets/story/story_avatar.dart';
import 'package:tourn/Ui/main/category/messenge/widgets/AIbottonchat.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:tourn/Ui/main/category/business/business_profile_page.dart';

class FirebaseRecentChats extends StatefulWidget {
  const FirebaseRecentChats({super.key});

  @override
  State<FirebaseRecentChats> createState() => _FirebaseRecentChatsState();
}

class _FirebaseRecentChatsState extends State<FirebaseRecentChats>
    with TickerProviderStateMixin {
  static const String _aiUserId = 'trip_ai';
  late final VoidCallback _archiveListener;
  // whether the row of attachment buttons is expanded (not used in this state)
  //bool _showAttachments = false;
  // (no messenger key needed here; HomePage provides the Scaffold for
  // showing SnackBars)
  // keep track of pinned conversations (IDs). newest pins at front, max 3
  final List<String> _pinnedIds = [];
  // user ids that current user has restricted; conversations with these
  // people should be hidden from the recent list (they can still send us
  // messages but we intentionally drop them from the UI).
  final Set<String> _restrictedIds = {};
  // locally deleted conversation ids (optimistic UI).  We add an id here
  // when the user deletes a chat and then remove it again if they undo or
  // when the backend snapshot finally excludes it.
  final Set<String> _locallyDeleted = {};
  StreamSubscription<List<UserModel>>? _restrictedSub;

  bool _isSelectionMode = false;
  final Set<String> _selectedConversationIds = {};

  bool _isBusinessAccount = false;
  TabController? _tabController;
  StreamSubscription<UserModel?>? _userSub;

  // local override of mute state to give immediate feedback while
  // the backend snapshot catches up.  value = true means muted, false
  // means unmuted.  If a conversation ID is absent we fall back to the
  // server-provided flag.
  final Map<String, bool> _muteOverrides = {};
  // keep track of conversations where we've already handled an expired
  // mute timestamp so we don't repeatedly send unmute requests every time
  // the UI rebuilds.
  final Set<String> _handledExpiry = {};
  // name lookups for conversations which initially returned "Me".  We
  // fetch the real display name from the user repository and cache it.
  final Map<String, String> _nameOverrides = {};
  // whether the other party has restricted us; keyed by conversation id.
  // this is used when rendering the list to hide online indicators.
  final Map<String, bool> _restrictedByMap = {};
  // whether the other user has blocked us, keyed by conversation id.  this
  // mirrors _restrictedByMap and is used when rendering online indicators in
  // the recent list so that someone who has blocked us can't detect our
  // presence.
  final Map<String, bool> _blockedByMap = {};

  // cache of last-message sender ids for conversations where the
  // `lastMessageSenderId` field may be absent (legacy docs).  maps
  // conversationId → senderId.
  final Map<String, String> _lastMsgSenderCache = {};
  // photo lookups for conversations where the participantPhotos field
  // was empty at creation time.  maps conversationId → photoUrl.
  final Map<String, String?> _photoOverrides = {};
  // track which conversations we've already attempted to fetch a photo for
  final Set<String> _photoFetchAttempted = {};

  String? _aiSummaryText;
  DateTime? _aiSummaryTime;
  int _aiSummaryConversationCount = 0;
  bool _aiSummaryLoaded = false;

  bool _ensureSignedIn() {
    if (FirebaseAuth.instance.currentUser != null) return true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cần đăng nhập để thực hiện thao tác này')),
    );
    return false;
  }

  // friend IDs (users with mutual following) - used to filter message requests
  Set<String> _friendIds = {};
  StreamSubscription<UserModel?>? _friendsSub;

  @override
  void initState() {
    super.initState();
    // do not subscribe here; wait until we know currentUserId (might be null at
    // startup).  We will set up the listener in didChangeDependencies.

    _tabController = TabController(length: 3, vsync: this);
    int lastIndex = _tabController!.index;
    _tabController!.addListener(() {
      if (mounted && _tabController!.index != lastIndex) {
        lastIndex = _tabController!.index;
        setState(() {});
      }
    });

    _loadAiSummary();

    _archiveListener = () {
      // schedule the rebuild after the current frame to avoid triggering
      // setState while the widget tree is mid-build.  This mirrors the
      // approach used in `ArchivedChatsPage` itself and prevents the
      // "setState() or markNeedsBuild() called during build" exception that
      // can occur when a conversation is unarchived as part of pushing a new
      // route (for example, when the user taps a chat in the archive list).
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    };
    ArchivedChatsPage.changeNotifier.addListener(_archiveListener);
  }

  Future<void> _loadAiSummary() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('ai_conversations');
      if (data == null || data.isEmpty) {
        if (!mounted) return;
        setState(() {
          _aiSummaryLoaded = true;
          _aiSummaryConversationCount = 0;
          _aiSummaryText = null;
          _aiSummaryTime = null;
        });
        return;
      }

      final List<dynamic> jsonList = jsonDecode(data);
      int conversationCount = 0;
      DateTime? latestTime;
      String? latestText;

      for (final raw in jsonList) {
        if (raw is! Map) continue;
        conversationCount += 1;
        final messages = raw['messages'] as List?;
        if (messages == null) continue;
        for (final msgRaw in messages) {
          if (msgRaw is! Map) continue;
          final isDeletedForMe = msgRaw['isDeletedForMe'] == true;
          final isDeletedForAll = msgRaw['isDeletedForAll'] == true;
          if (isDeletedForMe || isDeletedForAll) continue;
          final text = (msgRaw['text'] ?? '').toString();
          if (text.trim().isEmpty) continue;
          if (text.trim().startsWith('Xin chào! Tôi là Trip AI')) {
            continue;
          }
          final timeStr = (msgRaw['time'] ?? '').toString();
          final msgTime = DateTime.tryParse(timeStr);
          if (msgTime == null) continue;
          if (latestTime == null || msgTime.isAfter(latestTime)) {
            latestTime = msgTime;
            latestText = text;
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _aiSummaryLoaded = true;
        _aiSummaryConversationCount = conversationCount;
        _aiSummaryTime = latestTime;
        _aiSummaryText = latestText;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _aiSummaryLoaded = true;
        _aiSummaryConversationCount = 0;
        _aiSummaryText = null;
        _aiSummaryTime = null;
      });
    }
  }

  String _buildAiPreviewText() {
    final base = _aiSummaryText?.trim();
    final preview = (base == null || base.isEmpty)
        ? 'Bắt đầu trò chuyện'
        : base.replaceAll('\n', ' ');
    return preview;
  }

  @override
  void dispose() {
    ArchivedChatsPage.changeNotifier.removeListener(_archiveListener);
    _restrictedSub?.cancel();
    _friendsSub?.cancel();
    _userSub?.cancel();
    _tabController?.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final messageRepository = context.read<MessageRepository>();
    final uid = messageRepository.currentUserId;
    if (uid != null && _restrictedSub == null) {
      _restrictedSub = FirebaseUserService().getRestrictedUsers().listen((
        list,
      ) {
        if (!mounted) return;
        setState(() {
          _restrictedIds
            ..clear()
            ..addAll(list.map((u) => u.uid));
        });
      });
    }
    // Subscribe to current user's friends (mutual following)
    if (uid != null && _friendsSub == null) {
      _friendsSub = context.read<UserRepository>().streamUser(uid).listen((
        user,
      ) {
        if (!mounted || user == null) return;
        final followers = user.followers.toSet();
        final following = user.following.toSet();
        setState(() {
          _friendIds = followers.intersection(following);
        });
      });
    }
    if (uid != null && _userSub == null) {
      _userSub = context.read<UserRepository>().streamUser(uid).listen((user) {
        if (!mounted || user == null) return;
        final isBiz = user.isBusinessAccount;
        if (isBiz != _isBusinessAccount || _tabController == null) {
          setState(() {
            _isBusinessAccount = isBiz;
            _tabController?.dispose();
            _tabController = TabController(length: isBiz ? 2 : 3, vsync: this);
            int lastIndex = _tabController!.index;
            _tabController!.addListener(() {
              if (mounted && _tabController!.index != lastIndex) {
                lastIndex = _tabController!.index;
                setState(() {});
              }
            });
          });
        }
      });
    }
  }

  Widget _buildRecentChats(
    BuildContext context,
    MessageRepository messageRepository,
    String currentUserId,
  ) {
    final body = StreamBuilder<List<ConversationModel>>(
      initialData: const <ConversationModel>[],
      stream: messageRepository.getConversations(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          String msg;
          final err = snapshot.error;
          if (err is FirebaseException && err.code == 'failed-precondition') {
            msg =
                'Cần tạo chỉ mục Firestore để thực hiện truy vấn này. Mở liên kết bên dưới để tạo:\n${err.message}';
          } else {
            msg = 'Lỗi: $err';
          }
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SelectableText(
                msg,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        final isWaiting = snapshot.connectionState == ConnectionState.waiting;
        final raw = snapshot.data ?? [];
        final seen = <Set<String>>{};
        final conversations = <ConversationModel>[];
        for (final c in raw) {
          if (_locallyDeleted.remove(c.id)) {
            // removed from local delete cache
          }
          if (_locallyDeleted.contains(c.id)) continue;
          if (c.deletedFor.contains(currentUserId)) continue;
          if (seen.add(c.participants.toSet())) {
            final isAiConversation =
                c.type == ConversationType.private &&
                c.participants.contains(_aiUserId);
            if (ArchivedChatsPage.isArchived(c.id)) {
              final archivedAt = ArchivedChatsPage.getArchivedAt(c.id);
              final lastAt = c.lastMessageAt;
              final unread = isAiConversation
                  ? 0
                  : (c.unreadCount[currentUserId] ?? 0);
              final hasNew =
                  unread > 0 ||
                  (archivedAt != null &&
                      lastAt != null &&
                      lastAt.isAfter(archivedAt));
              if (hasNew) {
                ArchivedChatsPage.removeArchivedChat(c.id);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ArchivedChatsPage.changeNotifier.value++;
                });
              } else {
                continue;
              }
            }
            final otherId = c.participants.firstWhere(
              (id) => id != currentUserId,
              orElse: () => '',
            );
            if (otherId.isNotEmpty && _restrictedIds.contains(otherId)) {
              continue;
            }
            if (otherId.isNotEmpty && !_restrictedByMap.containsKey(c.id)) {
              FirebaseUserService().isRestrictedBy(otherId).then((value) {
                if (mounted) {
                  setState(() {
                    _restrictedByMap[c.id] = value;
                  });
                }
              });
            }
            if (c.type == ConversationType.private &&
                c.createdBy != currentUserId &&
                !c.isBusinessChat &&
                !c.hasAccepted(currentUserId) &&
                otherId.isNotEmpty &&
                !_friendIds.contains(otherId)) {
              continue;
            }
            conversations.add(c);
          }
        }

        final currentId = messageRepository.currentUserId;
        if (currentId != null) {
          bool changed = false;
          for (final c in conversations) {
            if (_muteOverrides.containsKey(c.id)) {
              final backend = c.mutedUsers[currentId] ?? false;
              if (_muteOverrides[c.id] == backend) {
                _muteOverrides.remove(c.id);
                changed = true;
              }
            }
          }
          if (changed && mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() {});
            });
          }
        }

        conversations.sort((a, b) {
          final aPinned = _pinnedIds.contains(a.id);
          final bPinned = _pinnedIds.contains(b.id);
          if (aPinned && !bPinned) return -1;
          if (!aPinned && bPinned) return 1;
          if (aPinned && bPinned) {
            return _pinnedIds.indexOf(a.id).compareTo(_pinnedIds.indexOf(b.id));
          }
          return 0;
        });

        final filteredConversations = <ConversationModel>[];
        final tabIndex = _tabController?.index ?? 0;

        if (_isBusinessAccount) {
          for (final c in conversations) {
            if (c.type == ConversationType.group) {
              if (tabIndex == 0) filteredConversations.add(c);
              continue;
            }
            final otherId = c.participants.firstWhere(
              (id) => id != currentUserId,
              orElse: () => '',
            );
            if (otherId == _aiUserId) {
              filteredConversations.add(c);
              continue;
            }
            final isSelfChat = otherId.isEmpty || otherId == currentUserId;
            bool showInPersonal = false;
            bool showInBusiness = false;

            if (!c.isBusinessChat) {
              showInPersonal = true;
            } else {
              if (isSelfChat) {
                showInPersonal = true;
                showInBusiness = true;
              } else {
                if (c.createdBy == currentUserId) {
                  showInPersonal = true;
                } else {
                  showInBusiness = true;
                }
              }
            }

            if (tabIndex == 0 && showInPersonal) {
              filteredConversations.add(c);
            } else if (tabIndex == 1 && showInBusiness) {
              filteredConversations.add(c);
            }
          }
        } else {
          for (final c in conversations) {
            if (tabIndex == 0) {
              filteredConversations.add(c);
            } else if (tabIndex == 1) {
              final unread = c.unreadCount[currentUserId] ?? 0;
              if (unread > 0) filteredConversations.add(c);
            } else if (tabIndex == 2) {
              if (c.type == ConversationType.group) {
                filteredConversations.add(c);
              }
            }
          }
        }

        return SlidableAutoCloseBehavior(
          closeWhenOpened: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                child: Text(
                  'Tin nhắn gần đây',
                  style: TextStyle(
                    color: Color(0xFF113953),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  children: [
                    Expanded(
                      child: _isSelectionMode
                          ? Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.mark_email_unread_outlined,
                                    color: Color(0xFF113953),
                                  ),
                                  tooltip: 'Đánh dấu chưa đọc',
                                  onPressed: () {
                                    final repo = context
                                        .read<MessageRepository>();
                                    for (final id in _selectedConversationIds) {
                                      repo.markAsUnread(id);
                                    }
                                    setState(() {
                                      _isSelectionMode = false;
                                      _selectedConversationIds.clear();
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.archive_outlined,
                                    color: Color(0xFF113953),
                                  ),
                                  tooltip: 'Lưu trữ',
                                  onPressed: () {
                                    for (final c in filteredConversations) {
                                      if (_selectedConversationIds.contains(
                                        c.id,
                                      )) {
                                        final isAi =
                                            c.type ==
                                                ConversationType.private &&
                                            c.participants.contains(_aiUserId);
                                        final chat = {
                                          'id': c.id,
                                          'name': c.getDisplayName(
                                            currentUserId,
                                          ),
                                          'avatar':
                                              c.getDisplayPhoto(
                                                currentUserId,
                                              ) ??
                                              'asset/images/OIP.jpg',
                                          'lastMessage': c.lastMessage ?? '',
                                          'time': _formatTime(c.lastMessageAt),
                                          'isOnline':
                                              c.type ==
                                              ConversationType.private,
                                          'isFirebase': true,
                                          'isAi': isAi,
                                          'archivedAt': DateTime.now()
                                              .millisecondsSinceEpoch,
                                        };
                                        ArchivedChatsPage.addArchivedChat(
                                          c.id,
                                          chat,
                                        );
                                      }
                                    }
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Đã lưu trữ ${_selectedConversationIds.length} cuộc trò chuyện',
                                        ),
                                      ),
                                    );
                                    setState(() {
                                      _isSelectionMode = false;
                                      _selectedConversationIds.clear();
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  tooltip: 'Xóa',
                                  onPressed: () {
                                    final repo = context
                                        .read<MessageRepository>();
                                    for (final id in _selectedConversationIds) {
                                      setState(() {
                                        _locallyDeleted.add(id);
                                      });
                                      repo.deleteConversation(id);
                                    }
                                    setState(() {
                                      _isSelectionMode = false;
                                      _selectedConversationIds.clear();
                                    });
                                  },
                                ),
                                const Spacer(),
                                Text(
                                  'Đã chọn ${_selectedConversationIds.length}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF113953),
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            )
                          : TabBar(
                              controller: _tabController,
                              isScrollable: true,
                              indicatorColor: Colors.transparent,
                              labelColor: const Color(0xFF113953),
                              unselectedLabelColor: Colors.grey.shade500,
                              labelStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              unselectedLabelStyle: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 15,
                              ),
                              dividerColor: Colors.transparent,
                              tabAlignment: TabAlignment.start,
                              padding: EdgeInsets.zero,
                              labelPadding: const EdgeInsets.only(right: 24),
                              tabs: _isBusinessAccount
                                  ? const [
                                      Tab(text: 'Cá nhân'),
                                      Tab(text: 'Kinh doanh'),
                                    ]
                                  : const [
                                      Tab(text: 'Tất cả'),
                                      Tab(text: 'Chưa đọc'),
                                      Tab(text: 'Nhóm'),
                                    ],
                            ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        _isSelectionMode ? Icons.close : Icons.checklist,
                        color: const Color(0xFF113953),
                      ),
                      onPressed: () {
                        setState(() {
                          _isSelectionMode = !_isSelectionMode;
                          if (!_isSelectionMode) {
                            _selectedConversationIds.clear();
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              if (filteredConversations.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isWaiting) ...[
                          const SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(height: 16),
                        ] else ...[
                          const Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                        ],
                        Text(
                          isWaiting
                              ? 'Đang tải cuộc trò chuyện...'
                              : 'Chưa có cuộc trò chuyện nào',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredConversations.length,
                  itemBuilder: (context, index) {
                    return _buildConversationTile(
                      context,
                      filteredConversations[index],
                      currentUserId,
                      tabIndex,
                    );
                  },
                ),
            ],
          ),
        );
      },
    );

    return Column(mainAxisSize: MainAxisSize.min, children: [body]);
  }

  @override
  Widget build(BuildContext context) {
    final messageRepository = context.read<MessageRepository>();
    final currentUserId = messageRepository.currentUserId;
    if (currentUserId == null) {
      return StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          final user = snapshot.data;
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return _buildRecentChats(context, messageRepository, user.uid);
        },
      );
    }
    return _buildRecentChats(context, messageRepository, currentUserId);
  }

  Widget _buildConversationTile(
    BuildContext context,
    ConversationModel conversation,
    String currentUserId,
    int tabIndex,
  ) {
    // key used to compute the position of the tile when showing the
    // "more" menu.
    final tileKey = GlobalKey();
    final isAiConversation =
        conversation.type == ConversationType.private &&
        conversation.participants.contains(_aiUserId);
    if (isAiConversation && !_aiSummaryLoaded) {
      _loadAiSummary();
    }
    final rawName = conversation.getDisplayName(currentUserId);
    // if the returned name is just "Me" or somehow matches our own
    // display name, attempt to pick the other participant's stored name.
    var displayName = rawName;
    if (isAiConversation) {
      displayName = 'Trip AI';
    }
    final authName = FirebaseAuth.instance.currentUser?.displayName;
    if (displayName.toLowerCase() == 'me' ||
        (authName != null && displayName == authName)) {
      final otherId = conversation.participants.firstWhere(
        (id) => id != currentUserId,
        orElse: () => '',
      );
      final alt = conversation.participantNames[otherId];
      if (alt != null && alt.isNotEmpty && alt.toLowerCase() != 'me') {
        displayName = alt;
      } else {
        // if we already fetched an override name earlier, use it,
        // otherwise kick off an async lookup to populate the cache.
        final isSelfChat =
            conversation.participants.length == 2 &&
            conversation.participants[0] == conversation.participants[1];
        if (isSelfChat && tabIndex == 1) {
          final authName = FirebaseAuth.instance.currentUser?.displayName;
          if (authName != null && authName.isNotEmpty) {
            displayName = authName;
          }
        } else {
          if (_nameOverrides.containsKey(conversation.id)) {
            displayName = _nameOverrides[conversation.id]!;
          } else {
            _fetchNameForConversation(conversation, currentUserId);
          }
        }
      }
    }
    var displayPhoto = conversation.getDisplayPhoto(currentUserId);
    if (isAiConversation) {
      displayPhoto = null;
    }

    final isSelfChatPhoto =
        conversation.participants.length == 2 &&
        conversation.participants[0] == conversation.participants[1];
    if (isSelfChatPhoto && tabIndex == 1) {
      final authPhoto = FirebaseAuth.instance.currentUser?.photoURL;
      if (authPhoto != null && authPhoto.isNotEmpty) {
        displayPhoto = authPhoto;
      }
    } else {
      // if participantPhotos was empty at creation, try our cached override
      if ((displayPhoto == null || displayPhoto.isEmpty) &&
          _photoOverrides.containsKey(conversation.id)) {
        displayPhoto = _photoOverrides[conversation.id];
      }
      // kick off an async fetch if we haven't tried yet
      if ((displayPhoto == null || displayPhoto.isEmpty) &&
          !_photoFetchAttempted.contains(conversation.id)) {
        _fetchPhotoForConversation(conversation, currentUserId);
      }
    }
    final unreadCount = isAiConversation
        ? 0
        : (conversation.unreadCount[currentUserId] ?? 0);
    final hasUnread = unreadCount > 0;
    final isPinned = _pinnedIds.contains(conversation.id);
    final backendMuted = conversation.mutedUsers[currentUserId] ?? false;
    // determine effective mute, taking expiry into account
    bool effectiveBackendMuted = backendMuted;
    if (backendMuted) {
      final expiryTs = conversation.muteExpiry[currentUserId];
      if (expiryTs != null && expiryTs.toDate().isBefore(DateTime.now())) {
        // expiry passed; unmute in backend if we haven't already
        effectiveBackendMuted = false;
        if (!_handledExpiry.contains(conversation.id)) {
          _handledExpiry.add(conversation.id);
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await context.read<MessageRepository>().setMute(
              conversation.id,
              currentUserId,
              false,
            );
            setState(() {
              _muteOverrides.remove(conversation.id);
            });
          });
        }
      }
    }
    final isMuted = _muteOverrides.containsKey(conversation.id)
        ? _muteOverrides[conversation.id]!
        : effectiveBackendMuted;

    void archive() {
      final isAi = isAiConversation;
      // create simple map used by archive page
      final chat = {
        'id': conversation.id,
        'name': displayName,
        'avatar': displayPhoto ?? 'asset/images/OIP.jpg',
        'lastMessage': conversation.lastMessage ?? '',
        'time': _formatTime(conversation.lastMessageAt),
        'isOnline': conversation.type == ConversationType.private,
        'isFirebase': true, // mark source so we know how to open later
        'isAi': isAi,
        'archivedAt': DateTime.now().millisecondsSinceEpoch,
      };
      ArchivedChatsPage.addArchivedChat(conversation.id, chat);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã lưu trữ cuộc trò chuyện với $displayName')),
      );
      // close the slide
      Slidable.of(context)?.close();
      // trigger rebuild so filter is applied instantly
      setState(() {});
    }

    // make tile slidable to reveal archive/pin/etc actions
    // user prefers swiping left, so use endActionPane instead of start
    return Slidable(
      key: ValueKey(conversation.id),
      endActionPane: ActionPane(
        // lướt
        motion: const ScrollMotion(),
        // don't auto-dismiss on long or fast swipes, user must tap action
        children: [
          SlidableAction(
            onPressed: (_) => _showMoreMenu(context, tileKey, conversation),
            backgroundColor: Colors.grey.shade200,
            foregroundColor: Colors.black,
            icon: Icons.more_horiz,
            label: 'Khác',
          ),
          SlidableAction(
            onPressed: (_) => _togglePin(conversation, context),
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            icon: _pinnedIds.contains(conversation.id)
                ? Icons.push_pin
                : Icons.push_pin_outlined,
            label: _pinnedIds.contains(conversation.id) ? 'Bỏ ghim' : 'Ghim',
          ),
          SlidableAction(
            onPressed: (_) => archive(),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.archive,
            label: 'Lưu trữ',
          ),
        ],
      ),
      child: InkWell(
        key: tileKey,
        onTap: () {
          if (_isSelectionMode) {
            setState(() {
              if (_selectedConversationIds.contains(conversation.id)) {
                _selectedConversationIds.remove(conversation.id);
              } else {
                _selectedConversationIds.add(conversation.id);
              }
            });
            return;
          }
          if (isAiConversation) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AIChatBottomSheet(
                  fullScreen: true,
                  combineHistory: true,
                ),
              ),
            ).then((_) {
              _loadAiSummary();
            });
            return;
          }
          final otherId = conversation.participants.firstWhere(
            (id) => id != currentUserId,
            orElse: () => currentUserId ?? '',
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FirebaseChatPage(
                conversationId: conversation.id,
                displayName: displayName,
                displayPhoto: displayPhoto,
                isGroup: conversation.type == ConversationType.group,
                isBusinessChat: conversation.isBusinessChat,
                otherUserId: otherId,
              ),
            ),
          );
        },
        onLongPress: () {
          if (!_isSelectionMode) {
            setState(() {
              _isSelectionMode = true;
              _selectedConversationIds.add(conversation.id);
            });
          }
        },
        child: Container(
          color: isPinned
              ? Colors.grey.shade50
              : (_selectedConversationIds.contains(conversation.id)
                    ? Colors.blue.shade50
                    : null),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Row(
            children: [
              if (_isSelectionMode) ...[
                Icon(
                  _selectedConversationIds.contains(conversation.id)
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: _selectedConversationIds.contains(conversation.id)
                      ? const Color(0xFF113953)
                      : Colors.grey,
                ),
                const SizedBox(width: 12),
              ],
              // Avatar with story ring
              Stack(
                children: [
                  if (isAiConversation)
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[200],
                      ),
                      padding: const EdgeInsets.all(6),
                      child: ClipOval(
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: Image.asset('asset/icon/logo.png'),
                        ),
                      ),
                    )
                  else
                    StoryAvatar(
                      userId: conversation.type == ConversationType.private
                          ? conversation.participants.firstWhere(
                              (id) => id != currentUserId,
                              orElse: () => '',
                            )
                          : null, // Don't show story ring for groups
                      photoUrl: displayPhoto,
                      userName: displayName,
                      radius: 28,
                      showStoryRing:
                          conversation.type == ConversationType.private,
                    ),
                  if (isAiConversation)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  // Online indicator (if group, skip).  also hide if the
                  // other user has restricted us; a restricted user shouldn't
                  // be able to detect our presence.
                  if (conversation.type == ConversationType.private &&
                      !isAiConversation &&
                      !(_restrictedByMap[conversation.id] ?? false))
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: _OnlineIndicator(
                        userId: conversation.participants.firstWhere(
                          (id) => id != currentUserId,
                          orElse: () => '',
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              displayName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: hasUnread
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: const Color(0xFF113953),
                              ),
                            ),
                            if (isPinned) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.push_pin,
                                size: 16,
                                color: Colors.orange,
                              ),
                            ],
                            if (isMuted) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.notifications_off,
                                size: 16,
                                color: Colors.grey,
                              ),
                            ],
                          ],
                        ),
                        Text(
                          _formatTime(
                            isAiConversation
                                ? (_aiSummaryTime ?? conversation.lastMessageAt)
                                : conversation.lastMessageAt,
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: hasUnread ? Colors.blue : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Builder(
                            builder: (context) {
                              // preview text for last message; prefix "Bạn: " when the
                              // last message was sent by the current user.  this
                              // makes it clear which side we wrote.
                              String preview =
                                  conversation.lastMessage ??
                                  'Bắt đầu trò chuyện';
                              // determine whether the last message came from us
                              bool sentByMe =
                                  conversation.lastMessageSenderId ==
                                  currentUserId;
                              if (!sentByMe) {
                                // try cache fallback if field missing or other
                                final cached =
                                    _lastMsgSenderCache[conversation.id];
                                if (cached != null) {
                                  sentByMe = cached == currentUserId;
                                }
                                // kick off async lookup if still unknown
                                if (cached == null) {
                                  _fetchLastSender(
                                    conversation.id,
                                    currentUserId,
                                  );
                                }
                              }
                              if (sentByMe) {
                                if (!preview.startsWith('Bạn:')) {
                                  preview = 'Bạn: $preview';
                                }
                              }
                              return Text(
                                isAiConversation
                                    ? _buildAiPreviewText()
                                    : (hasUnread
                                          ? '$unreadCount tin nhắn mới'
                                          : preview),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: hasUnread
                                      ? Colors.black87
                                      : Colors.grey,
                                  fontWeight: hasUnread
                                      ? FontWeight.w500
                                      : FontWeight.normal,
                                ),
                              );
                            },
                          ),
                        ),
                        // when there are unread messages we already show a
                        // "X tin nhắn mới" subtitle so the count bubble isn't
                        // necessary; we simply add a tiny dot after the time
                        if (hasUnread)
                          Container(
                            margin: const EdgeInsets.only(left: 4),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          )
                        // Show seen/sent indicator when I sent the last message
                        else
                          Builder(
                            builder: (context) {
                              // Check if I sent the last message
                              bool sentByMe =
                                  conversation.lastMessageSenderId ==
                                  currentUserId;
                              if (!sentByMe) {
                                final cached =
                                    _lastMsgSenderCache[conversation.id];
                                if (cached != null) {
                                  sentByMe = cached == currentUserId;
                                }
                              }

                              if (!sentByMe) {
                                return const SizedBox.shrink();
                              }

                              // Get other user ID
                              final otherId = conversation.participants
                                  .firstWhere(
                                    (id) => id != currentUserId,
                                    orElse: () => '',
                                  );
                              if (otherId.isEmpty) {
                                return const SizedBox.shrink();
                              }

                              // Check if other has read (their unread count is 0)
                              final otherUnreadCount =
                                  conversation.unreadCount[otherId] ?? 0;

                              if (otherUnreadCount == 0) {
                                // Other has read - show their small avatar
                                return Container(
                                  margin: const EdgeInsets.only(left: 4),
                                  child: CircleAvatar(
                                    radius: 8,
                                    backgroundImage: displayPhoto != null
                                        ? getImageProvider(displayPhoto)
                                        : const AssetImage(
                                                'asset/images/OIP.jpg',
                                              )
                                              as ImageProvider,
                                  ),
                                );
                              } else {
                                // Other hasn't read - show sent indicator
                                return Container(
                                  margin: const EdgeInsets.only(left: 4),
                                  child: const Icon(
                                    Icons.check,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                );
                              }
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTripAiTile(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          buildBottomSheet(context);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFF113953),
                child: Icon(Icons.travel_explore, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trip AI',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Tro ly du lich',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showMoreMenu(
    BuildContext context,
    GlobalKey tileKey,
    ConversationModel conversation,
  ) async {
    // use the state's own context for any async operations that outlive the
    // tapped tile (dialogs, snackbars, navigation).  the `context` parameter
    // refers to the tile widget and will be deactivated once the tile is
    // removed from the list, which previously triggered the FlutterError.
    final BuildContext rootContext = this.context;

    // compute the position of the tile so the menu can be anchored correctly
    final RenderBox? box =
        tileKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final Offset topLeft = box.localToGlobal(Offset.zero);
    final Size screenSize = MediaQuery.of(context).size;

    // determine unread/mute state for current user (used for toggle)
    final currentUserId = context.read<MessageRepository>().currentUserId;
    if (currentUserId == null) {
      // if we somehow called this before auth is ready just bail out
      return;
    }
    final messageRepository = context.read<MessageRepository>();
    final unreadCount = conversation.unreadCount[currentUserId] ?? 0;
    final unreadLabel = unreadCount > 0
        ? 'Đánh dấu là đã đọc'
        : 'Đánh dấu là chưa đọc';
    final isAiConversation =
        conversation.type == ConversationType.private &&
        conversation.participants.contains(_aiUserId);
    final backendMuted = conversation.mutedUsers[currentUserId] ?? false;
    bool effectiveBackendMuted = backendMuted;
    if (backendMuted) {
      final expiryTs = conversation.muteExpiry[currentUserId];
      if (expiryTs != null && expiryTs.toDate().isBefore(DateTime.now())) {
        effectiveBackendMuted = false;
        if (!_handledExpiry.contains(conversation.id)) {
          _handledExpiry.add(conversation.id);
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await messageRepository.setMute(
              conversation.id,
              currentUserId,
              false,
            );
            setState(() {
              _muteOverrides.remove(conversation.id);
            });
          });
        }
      }
    }
    final isMuted = _muteOverrides.containsKey(conversation.id)
        ? _muteOverrides[conversation.id]!
        : effectiveBackendMuted;
    final muteLabel = isMuted ? 'Bật thông báo' : 'Tắt thông báo';

    // figure out other participant to possibly act on
    final otherId = conversation.participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
    bool isRestrictedMenu = false;
    if (otherId.isNotEmpty) {
      isRestrictedMenu = await FirebaseUserService().isRestricted(otherId);
    }

    // compute displayName for snackbar (same adjustments as above)
    var displayName =
        _nameOverrides[conversation.id] ??
        conversation.getDisplayName(currentUserId);
    final authName2 = FirebaseAuth.instance.currentUser?.displayName;
    if (displayName.toLowerCase() == 'me' ||
        (authName2 != null && displayName == authName2)) {
      final alt = conversation.participantNames[otherId];
      if (alt != null && alt.isNotEmpty && alt.toLowerCase() != 'me') {
        displayName = alt;
      } else {
        // still no good name, try async fetch
        _fetchNameForConversation(conversation, currentUserId);
      }
    }

    // estimate height of menu based on item count; keep synced with the list
    const int itemCount = 6; // number of menu entries below
    const double itemHeight = kMinInteractiveDimension; // 48.0
    final double menuHeight = itemCount * itemHeight;

    // decide whether we have room to open below the tile; if not, place above.
    final bool preferBelow =
        topLeft.dy + box.size.height + menuHeight <= screenSize.height;

    final RelativeRect position = RelativeRect.fromLTRB(
      topLeft.dx,
      preferBelow ? topLeft.dy + box.size.height : topLeft.dy - menuHeight,
      screenSize.width - topLeft.dx - box.size.width,
      preferBelow
          ? screenSize.height - (topLeft.dy + box.size.height) - menuHeight
          : screenSize.height - topLeft.dy + menuHeight,
    );

    final selected = await showMenu<String>(
      context: context, // positioning still uses tile context
      position: position,
      items: [
        PopupMenuItem(value: 'unread', child: Text(unreadLabel)),
        PopupMenuItem(value: 'mute', child: Text(muteLabel)),
        PopupMenuItem(
          value: 'restrict',
          child: Text(isRestrictedMenu ? 'Bỏ hạn chế' : 'Hạn chế'),
        ),
        const PopupMenuItem(value: 'delete', child: Text('Xóa')),
        const PopupMenuItem(value: 'block', child: Text('Chặn')),
      ],
    );
    if (!mounted) return;
    // reuse messageRepository variable declared earlier in this method
    switch (selected) {
      case 'unread':
        if (unreadCount > 0) {
          await messageRepository.markAsRead(conversation.id);
          ScaffoldMessenger.of(rootContext).showSnackBar(
            const SnackBar(content: Text('Đã đánh dấu là đã đọc')),
          );
        } else {
          await messageRepository.markAsUnread(conversation.id);
          ScaffoldMessenger.of(rootContext).showSnackBar(
            const SnackBar(content: Text('Đã đánh dấu là chưa đọc')),
          );
        }
        final slidableCtx = tileKey.currentContext;
        if (slidableCtx != null) {
          Slidable.of(
            slidableCtx,
          )?.close(); // tile context still fine for closing
        }
        break;
      case 'mute':
        // user tapped the mute/unmute entry.  if the conversation is
        // already considered muted we simply clear it; otherwise show the
        // duration sheet so the user can pick how long to silence it.
        if (isMuted) {
          // unmute immediately
          setState(() {
            _muteOverrides[conversation.id] = false;
          });
          await messageRepository.setMute(
            conversation.id,
            currentUserId,
            false,
          );
          ScaffoldMessenger.of(rootContext).showSnackBar(
            SnackBar(content: Text('Đã bật thông báo cho $displayName')),
          );
        } else {
          final choice = await showModalBottomSheet<int>(
            context: context,
            builder: (_) {
              return SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: const Text('Trong 15 phút'),
                      onTap: () => Navigator.pop(context, 15),
                    ),
                    ListTile(
                      title: const Text('Trong 1 giờ'),
                      onTap: () => Navigator.pop(context, 60),
                    ),
                    ListTile(
                      title: const Text('Trong 8 giờ'),
                      onTap: () => Navigator.pop(context, 8 * 60),
                    ),
                    ListTile(
                      title: const Text('Trong 24 giờ'),
                      onTap: () => Navigator.pop(context, 24 * 60),
                    ),
                    ListTile(
                      title: const Text('Đến khi tôi thay đổi'),
                      onTap: () => Navigator.pop(context, -1),
                    ),
                    ListTile(
                      title: const Text(
                        'Hủy',
                        style: TextStyle(color: Colors.red),
                      ),
                      onTap: () => Navigator.pop(context, null),
                    ),
                  ],
                ),
              );
            },
          );
          if (choice != null) {
            DateTime? until;
            if (choice > 0) {
              until = DateTime.now().add(Duration(minutes: choice));
            }
            // mute locally immediately
            setState(() {
              _muteOverrides[conversation.id] = true;
            });

            await messageRepository.setMute(
              conversation.id,
              currentUserId,
              true,
              until: until,
            );
            ScaffoldMessenger.of(rootContext).showSnackBar(
              SnackBar(content: Text('Đã tắt thông báo cho $displayName')),
            );
          }
        }
        final slidableCtx = tileKey.currentContext;
        if (slidableCtx != null) Slidable.of(slidableCtx)?.close();
        break;
      case 'restrict':
        if (otherId.isNotEmpty) {
          final confirmed = await showDialog<bool>(
            context: rootContext,
            builder: (_) => AlertDialog(
              title: Text(
                '${isRestrictedMenu ? 'Bỏ hạn chế' : 'Hạn chế'} $displayName?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Hủy'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(isRestrictedMenu ? 'Bỏ hạn chế' : 'Hạn chế'),
                ),
              ],
            ),
          );
          if (confirmed == true) {
            if (isRestrictedMenu) {
              await FirebaseUserService().unrestrictUser(otherId);
              ScaffoldMessenger.of(rootContext).showSnackBar(
                SnackBar(content: Text('Đã bỏ hạn chế $displayName')),
              );
              setState(() {
                _restrictedIds.remove(otherId);
              });
            } else {
              await FirebaseUserService().restrictUser(otherId);
              ScaffoldMessenger.of(rootContext).showSnackBar(
                SnackBar(content: Text('Đã hạn chế $displayName')),
              );
              setState(() {
                _restrictedIds.add(otherId);
              });
            }
            // navigate to restricted list page
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HanChePage()),
            );
          }
        }
        final slidableCtx = tileKey.currentContext;
        if (slidableCtx != null) Slidable.of(slidableCtx)?.close();
        break;
      case 'delete':
        // 2. Hiện hộp thoại xác nhận (Confirm Dialog)
        final confirm = await showDialog<bool>(
          context: rootContext,
          builder: (BuildContext dialogContext) => AlertDialog(
            title: const Text('Xóa cuộc trò chuyện'),
            content: const Text(
              'Bạn có chắc chắn muốn xóa vĩnh viễn cuộc trò chuyện này? Tất cả tin nhắn sẽ bị xóa.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Xóa', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );

        // 3. Nếu người dùng chọn 'Xóa' (confirm == true)
        if (confirm == true) {
          if (isAiConversation) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('ai_conversations');
            _loadAiSummary();
          }
          // Lưu lại dữ liệu phòng trường hợp người dùng nhấn 'Khôi phục'
          final convoSnapshot = await messageRepository.getConversationById(
            conversation.id,
          );
          final messagesSnapshot = await messageRepository.getAllMessages(
            conversation.id,
          );

          if (convoSnapshot != null) {
            // close the slidable menu _before_ removing the tile.  if we
            // remove the widget while its Slidable is still open, the
            // Slidable may try to look up an ancestor during disposal and
            // trigger the "deactivated widget" error we were seeing.
            final slidableCtx = tileKey.currentContext;
            if (slidableCtx != null) Slidable.of(slidableCtx)?.close();

            // Optimistically remove the item from the UI so the list looks
            // responsive.  the server stream will eventually drop the doc too.
            setState(() {
              _locallyDeleted.add(conversation.id);
              // also clear any auxiliary state we keep for this convo so
              // it won't linger in caches while the item is gone.
              _pinnedIds.remove(conversation.id);
              _muteOverrides.remove(conversation.id);
              _restrictedByMap.remove(conversation.id);
              _blockedByMap.remove(conversation.id);
              _lastMsgSenderCache.remove(conversation.id);
            });

            // Thực hiện xoá trên server/database
            await messageRepository.deleteConversation(conversation.id);

            // 4. Xử lý hiển thị SnackBar (thông báo có nút Khôi phục)
            if (mounted) {
              final messenger = ScaffoldMessenger.of(rootContext);
              messenger.hideCurrentSnackBar(); // Dọn dẹp các thông báo cũ

              final controller = messenger.showSnackBar(
                SnackBar(
                  duration: const Duration(seconds: 5),
                  behavior: SnackBarBehavior.floating,
                  content: Text('Đã xóa cuộc trò chuyện với $displayName'),
                  action: SnackBarAction(
                    label: 'Khôi phục',
                    onPressed: () async {
                      // hide the snackbar immediately when user chooses undo
                      messenger.hideCurrentSnackBar();
                      await messageRepository.restoreConversation(
                        convoSnapshot,
                        messagesSnapshot,
                      );
                      // undo our optimistic removal so the tile returns
                      if (mounted) {
                        setState(() {
                          _locallyDeleted.remove(conversation.id);
                        });
                      }
                    },
                  ),
                ),
              );

              // Safety net: force-close the snackbar after 5s in case
              // the built-in timer fails (nested Scaffolds can interfere).
              Future.delayed(const Duration(seconds: 5), () {
                try {
                  controller.close();
                } catch (_) {
                  // controller may already be disposed – ignore
                }
              });

              // Cập nhật lại giao diện danh sách tin nhắn
              setState(() {});
            }
          }
        }

        // Đóng thanh Slidable (thanh trượt của item)
        if (mounted) {
          final slidableCtx = tileKey.currentContext;
          if (slidableCtx != null) Slidable.of(slidableCtx)?.close();
        }
        break;
      case 'block':
        // confirm block action
        if (otherId.isNotEmpty) {
          final sure = await showDialog<bool>(
            context: rootContext,
            builder: (_) => AlertDialog(
              title: const Text('Xác nhận chặn'),
              content: const Text(
                'Bạn có chắc chắn muốn chặn người này? Họ sẽ không thể gửi tin nhắn cho bạn.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(rootContext, false),
                  child: const Text('Không'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(rootContext, true),
                  child: const Text('Có'),
                ),
              ],
            ),
          );
          if (sure == true) {
            await FirebaseUserService().blockUser(otherId);
            ScaffoldMessenger.of(
              rootContext,
            ).showSnackBar(SnackBar(content: Text('Đã chặn $displayName')));
            // optional: remove the conversation from recent list immediately
            setState(() {
              _locallyDeleted.add(conversation.id);
            });
            // open chat page so the user sees the block banner
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FirebaseChatPage(
                  conversationId: conversation.id,
                  displayName: displayName,
                  displayPhoto: conversation.getDisplayPhoto(currentUserId),
                  isGroup: conversation.type == ConversationType.group,
                  isBusinessChat: conversation.isBusinessChat,
                  otherUserId: otherId,
                ),
              ),
            );
          }
        }
        final slidableCtx = tileKey.currentContext;
        if (slidableCtx != null) Slidable.of(slidableCtx)?.close();
        break;
    }
  }

  /// attempt to resolve a better display name when the conversation
  /// data contains only "Me" placeholders.  this is triggered lazily so
  /// we don't perform extra lookups unless necessary.
  void _fetchPhotoForConversation(
    ConversationModel convo,
    String currentUserId,
  ) async {
    if (_photoFetchAttempted.contains(convo.id)) return;
    _photoFetchAttempted.add(convo.id);
    final otherId = convo.participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
    if (otherId.isEmpty) return;

    try {
      bool shouldFetchBusinessProfile = false;
      if (convo.isBusinessChat) {
        final isSelfChat =
            convo.participants.length == 2 &&
            convo.participants[0] == convo.participants[1];
        if (isSelfChat) {
          shouldFetchBusinessProfile = true;
        } else {
          if (convo.createdBy == currentUserId) {
            shouldFetchBusinessProfile = true;
          }
        }
      }

      if (shouldFetchBusinessProfile) {
        final accountService = FirebaseAccountService();
        final extProfile = await accountService.getUserExtendedProfile(otherId);
        if (extProfile != null) {
          final bp =
              extProfile['businessProfile'] as Map<String, dynamic>? ?? {};
          final media = bp['media'] as Map<String, dynamic>? ?? {};
          if (media['avatarPath'] != null &&
              media['avatarPath'].toString().isNotEmpty) {
            if (mounted) {
              setState(() {
                _photoOverrides[convo.id] = media['avatarPath'].toString();
              });
            }
            return;
          }
        }
      }

      final userRepo = context.read<UserRepository>();
      final user = await userRepo.getUserById(otherId);
      if (user != null && user.photoUrl != null && user.photoUrl!.isNotEmpty) {
        if (mounted) {
          setState(() {
            _photoOverrides[convo.id] = user.photoUrl;
          });
        }
      }
    } catch (_) {
      // ignore failures
    }
  }

  void _fetchNameForConversation(
    ConversationModel convo,
    String currentUserId,
  ) async {
    if (_nameOverrides.containsKey(convo.id)) return;
    // determine the other participant id
    final otherId = convo.participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
    if (otherId.isEmpty) return;

    try {
      if (convo.isBusinessChat) {
        final accountService = FirebaseAccountService();
        final extProfile = await accountService.getUserExtendedProfile(otherId);
        if (extProfile != null) {
          final bp =
              extProfile['businessProfile'] as Map<String, dynamic>? ?? {};
          if (bp['name'] != null && bp['name'].toString().isNotEmpty) {
            setState(() {
              _nameOverrides[convo.id] = bp['name'].toString();
            });
            return;
          }
        }
      }

      final userRepo = context.read<UserRepository>();
      final user = await userRepo.getUserById(otherId);
      if (user != null && user.displayName.isNotEmpty) {
        setState(() {
          _nameOverrides[convo.id] = user.displayName;
        });
      }
    } catch (_) {
      // ignore failures; we'll just keep showing "Me" until data is
      // corrected on the server.
    }
  }

  /// retrieve most recent message from backend and remember its
  /// sender id.  this is only used for legacy conversations that do not
  /// populate `lastMessageSenderId`.
  void _fetchLastSender(String conversationId, String currentUserId) {
    context
        .read<MessageRepository>()
        .getMessages(conversationId, limit: 1)
        .first
        .then((list) {
          if (list.isNotEmpty) {
            final sender = list.first.senderId;
            _lastMsgSenderCache[conversationId] = sender;
            if (mounted) setState(() {});
          }
        })
        .catchError((_) {
          // ignore failures
        });
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} phút';
    } else if (difference.inDays < 1) {
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      final days = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
      return days[dateTime.weekday % 7];
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  void _togglePin(ConversationModel convo, BuildContext context) {
    final id = convo.id;
    final currentUserId = context.read<MessageRepository>().currentUserId;
    if (currentUserId == null) return;
    final displayName = convo.getDisplayName(currentUserId);
    setState(() {
      if (_pinnedIds.contains(id)) {
        _pinnedIds.remove(id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã bỏ ghim cuộc trò chuyện với $displayName'),
          ),
        );
      } else {
        _pinnedIds.insert(0, id);
        String? evicted;
        if (_pinnedIds.length > 3) {
          evicted = _pinnedIds.removeLast();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã ghim cuộc trò chuyện với $displayName${evicted != null ? ' (bỏ ghim trò chuyện cũ)' : ''}',
            ),
          ),
        );
      }
    });
  }
}

// Chat Page tích hợp Firebase
class FirebaseChatPage extends StatefulWidget {
  final String conversationId;
  final String displayName;
  final String? displayPhoto;
  final bool isGroup;
  final bool isBusinessChat;
  final String? otherUserId;

  const FirebaseChatPage({
    super.key,
    required this.conversationId,
    required this.displayName,
    this.displayPhoto,
    this.isGroup = false,
    this.isBusinessChat = false,
    this.otherUserId,
  });

  @override
  State<FirebaseChatPage> createState() => _FirebaseChatPageState();
}

class _FirebaseChatPageState extends State<FirebaseChatPage> {
  // key for scaffold messenger so we can show snackbars/dialogs without
  // relying on a potentially deactivated BuildContext.  This mirrors the
  // same pattern used in _FirebaseRecentChatsState.
  final GlobalKey<ScaffoldMessengerState> _messengerKey = GlobalKey();

  String get _myDisplayName {
    final curUser = FirebaseAuth.instance.currentUser;
    if (_conversation != null && curUser != null) {
      final name = _conversation!.participantNames[curUser.uid];
      if (name != null && name.isNotEmpty) return name;
    }
    return curUser?.displayName ?? '';
  }

  final TextEditingController _messageController = TextEditingController();
  final FocusNode _inputFocus = FocusNode();
  final ScrollController _scrollController = ScrollController();
  // whether attachment buttons are visible; tapping the input field hides
  // them and shows a back arrow instead.
  bool _attachmentsVisible = true;
  late MessageRepository _messageRepository;
  bool _hasText = false;
  // helper for picking images
  final ImagePicker _picker = ImagePicker();

  // Track if we've done initial scroll to bottom
  bool _hasScrolledToBottom = false;
  // Track message count to scroll on new messages
  int _lastMessageCount = 0;

  // audio recorder
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  Duration _recordDuration = Duration.zero;
  Timer? _recordTimer;

  bool _ensureSignedIn() {
    if (FirebaseAuth.instance.currentUser != null) return true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cần đăng nhập để thực hiện thao tác này')),
    );
    return false;
  }

  // attachment helpers

  void _onAttachPressed() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.location_on), // vị trí thời gian thực
                title: Text('Chia sẻ thời gian thực'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromGallery();
                },
              ),

              ListTile(
                leading: Icon(Icons.account_balance_wallet), // ngân sách / tiền
                title: Text('Gợi ý ngân sách thông minh'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromCamera();
                },
              ),

              ListTile(
                leading: Icon(Icons.receipt_long), // hóa đơn
                title: Text('Thanh toán và chia sẻ hóa đơn'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: gửi tệp hoặc hiển thị trong chat
                },
              ),

              ListTile(
                leading: Icon(Icons.note_alt), // ghi chú
                title: Text('Ghi chú'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: xử lý ghi chú
                },
              ),

              ListTile(
                leading: Icon(Icons.place), // vị trí
                title: Text('Vị trí'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: xử lý chia sẻ vị trí
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickFromGallery() async {
    try {
      // Let user pick image or video
      final XFile? file = await _picker.pickMedia();
      if (file != null) {
        final imageFile = File(file.path);
        final mimeType = file.mimeType ?? '';
        final isVideo =
            mimeType.startsWith('video') ||
            file.path.endsWith('.mp4') ||
            file.path.endsWith('.mov') ||
            file.path.endsWith('.avi');
        final msgType = isVideo ? MessageType.video : MessageType.image;
        await _messageRepository.sendMessage(
          conversationId: widget.conversationId,
          content: file.name,
          senderName: _myDisplayName,
          type: msgType,
          mediaFile: imageFile,
        );
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi khi mở thư viện: $e')));
      }
    }
  }

  Future<void> _pickFromCamera() async {
    try {
      final XFile? file = await _picker.pickImage(source: ImageSource.camera);
      if (file != null) {
        final imageFile = File(file.path);
        await _messageRepository.sendMessage(
          conversationId: widget.conversationId,
          content: file.name,
          senderName: _myDisplayName,
          type: MessageType.image,
          mediaFile: imageFile,
        );
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi khi mở camera: $e')));
      }
    }
  }

  void _onMicPressed() async {
    if (_isRecording) {
      final path = await _recorder.stop();
      _recordTimer?.cancel();
      setState(() {
        _isRecording = false;
        _recordDuration = Duration.zero;
      });
      if (path != null) {
        final file = File(path);
        if (await file.exists()) {
          try {
            await _messageRepository.sendMessage(
              conversationId: widget.conversationId,
              content: '[audio]',
              senderName: _myDisplayName,
              type: MessageType.audio,
              mediaFile: file,
            );
            _scrollToBottom();
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Lỗi gửi âm thanh: $e')));
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Không tìm thấy file ghi âm')),
            );
          }
        }
      }
    } else {
      bool hasPermission = await _recorder.hasPermission();
      if (hasPermission) {
        // use app's temporary directory for better compatibility
        final tempDir = Directory.systemTemp;
        final path =
            '${tempDir.path}/record_${DateTime.now().millisecondsSinceEpoch}.m4a';
        try {
          await _recorder.start(const RecordConfig(), path: path);
          setState(() {
            _isRecording = true;
            _recordDuration = Duration.zero;
          });
          _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
            setState(() {
              _recordDuration += const Duration(seconds: 1);
            });
          });
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Lỗi ghi âm: $e')));
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cần quyền sử dụng micro')),
        );
      }
    }
  }

  // IDs and flags used for restriction logic.  `_otherId` is the
  // participant opposite the current user in this chat.
  String? _otherId;
  Future<List<Map<String, dynamic>>>? _businessServicesFuture;
  // cached user object for the other participant; used when conversation has
  // no messages yet so we can render a profile‑style placeholder.
  UserModel? _otherUser;
  StreamSubscription<UserModel?>? _otherUserSub;

  // mutual friends / followers tracking
  int? _mutualCount;
  final List<String> _myFollowerIds = [];
  final List<String> _otherFollowerIds = [];
  StreamSubscription<List<UserModel>>? _myFollowersSub;
  StreamSubscription<List<UserModel>>? _otherFollowersSub;

  // whether the two accounts follow each other (i.e. are "friends").
  bool _areFriends = false;
  bool _followsOther = false; // current user follows the other person
  bool _followedByOther = false; // other person follows current user

  // true when *we* have restricted the other user (we will show the yellow
  // banner and disable our input).  this is what _isRestricted used to
  // represent.
  bool _hasRestrictedOther = false;
  // true when *the other user* has restricted us; in that case we should
  // hide any online status indicators so they can't detect our presence.
  bool _restrictedByOther = false;
  // true when *we* have blocked the other user.  when blocked we show a
  // special footer with "Bạn đã chặn" and offer unblock/report buttons.
  bool _hasBlockedOther = false;
  // true when *the other user* has blocked us.  used to suppress online
  // indicators (they can't see us when blocked).
  bool _blockedByOther = false;

  // Group chat related state
  ConversationModel? _conversation;
  String? _groupName;

  // ensure we only load once
  bool _checkedRestriction = false;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() {
      setState(() {
        _hasText = _messageController.text.trim().isNotEmpty;
      });
    });
    // listen to focus so we can swap button set
    _inputFocus.addListener(() {
      if (_inputFocus.hasFocus) {
        setState(() {
          _attachmentsVisible = false;
        });
      } else {
        if (!_attachmentsVisible) {
          setState(() {
            _attachmentsVisible = true;
          });
        } else {
          if (mounted) setState(() {});
        }
      }
    });
    // initialize business services early if we have the other user's ID
    if (widget.isBusinessChat &&
        widget.otherUserId != null &&
        widget.otherUserId!.isNotEmpty) {
      _otherId = widget.otherUserId;
      _businessServicesFuture = FirebaseBusinessService().getFeaturedServices(
        widget.otherUserId!,
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _messageRepository = context.read<MessageRepository>();
    // Mark as read when opening conversation; skip if we've
    // restricted the other user (so they don't know we've read their
    // messages).
    if (!_hasRestrictedOther) {
      _messageRepository.markAsRead(widget.conversationId);
    }

    // Jump to bottom when chat opens (avoid visible scroll)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _jumpToBottom();
    });

    // if this conversation was archived locally, unarchive it immediately
    // so that the recent list shows it.  we still also unarchive when the
    // user sends a message (see _sendMessage) but doing it here avoids a
    // momentary lag where the chat still appears archived while the page is
    // visible.
    if (ArchivedChatsPage.isArchived(widget.conversationId)) {
      ArchivedChatsPage.removeArchivedChat(widget.conversationId);
      // schedule the notification after the current frame so that any
      // listeners (eg. the archive page) don't try to rebuild while they're
      // already in the middle of a build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ArchivedChatsPage.changeNotifier.value++;
      });
    }

    // check restriction once we know repository and user id
    if (!_checkedRestriction) {
      _checkedRestriction = true;
      _initRestrictionState();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _inputFocus.dispose();
    _scrollController.dispose();
    _otherUserSub?.cancel();
    _myFollowersSub?.cancel();
    _otherFollowersSub?.cancel();
    super.dispose();
  }

  Future<void> _initRestrictionState() async {
    final conv = await _messageRepository.getConversationById(
      widget.conversationId,
    );
    if (!mounted) return;
    if (conv != null) {
      setState(() {
        _conversation = conv;
        _groupName = conv.name;
      });

      // For group chats, skip the restriction/block logic
      if (widget.isGroup || conv.type == ConversationType.group) {
        return;
      }

      final current = _messageRepository.currentUserId ?? '';
      final other = conv.participants.firstWhere(
        (id) => id != current,
        orElse: () => current,
      );
      _otherId = widget.otherUserId ?? other;
      if (widget.isBusinessChat &&
          _otherId != null &&
          _otherId!.isNotEmpty &&
          _businessServicesFuture == null) {
        setState(() {
          _businessServicesFuture = FirebaseBusinessService()
              .getFeaturedServices(_otherId!);
        });
      }
      if (other.isNotEmpty) {
        // begin listening for profile updates on the other user
        _otherUserSub?.cancel();
        if (!mounted) return;
        _otherUserSub = context.read<UserRepository>().streamUser(other).listen(
          (user) {
            if (!mounted) return;
            setState(() {
              _otherUser = user;
            });
          },
        );

        // also start followers streams so we can compute mutual count and
        // determine whether the two accounts follow each other
        final curId = _messageRepository.currentUserId;
        if (curId != null) {
          _myFollowersSub?.cancel();
          if (!mounted) return;
          _myFollowersSub = context
              .read<UserRepository>()
              .getFollowers(curId)
              .listen((list) {
                if (!mounted) return;
                setState(() {
                  _myFollowerIds
                    ..clear()
                    ..addAll(list.map((u) => u.uid));
                  _computeMutual();
                });
              });
        }
        _otherFollowersSub?.cancel();
        if (!mounted) return;
        _otherFollowersSub = context
            .read<UserRepository>()
            .getFollowers(other)
            .listen((list) {
              if (!mounted) return;
              setState(() {
                _otherFollowerIds
                  ..clear()
                  ..addAll(list.map((u) => u.uid));
                _computeMutual();
              });
            });

        // check both directions: did I restrict them? did they restrict me?
        final hasRestricted = await FirebaseUserService().isRestricted(other);
        final restrictedBy = await FirebaseUserService().isRestrictedBy(other);
        // also query block state both ways
        final hasBlocked = await FirebaseUserService().isBlocked(other);
        final blockedBy = await FirebaseUserService().isBlockedBy(other);
        if (!mounted) return;
        setState(() {
          _hasRestrictedOther = hasRestricted;
          _restrictedByOther = restrictedBy;
          _hasBlockedOther = hasBlocked;
          _blockedByOther = blockedBy;
        });
      }
    }
  }

  Widget _buildRestrictedFooter() {
    // bottomNavigationBar widgets cannot expand vertically, so avoid using
    // Expanded here.  Instead constrain the column to its minimum size and
    // let the text wrap naturally.  This prevents the footer from overflowing
    // up into the rest of the UI.
    return Container(
      color: Colors.yellow[100],
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: OutlinedButton(
              onPressed: _unrestrictOther,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.orange),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
              ),
              child: const Text(
                'Bỏ hạn chế',
                style: TextStyle(color: Colors.orange),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bạn đã hạn chế ${widget.displayName}. Họ sẽ không biết khi nào bạn online hoặc đọc tin nhắn của họ.',
            style: const TextStyle(color: Colors.black87),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildBlockedFooter() {
    return Container(
      color: Colors.white,

      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(height: 1, color: Colors.grey),
          Text(
            'Bạn đã chặn ${widget.displayName}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            "Các bạn sẽ không thể gửi tin nhắn cho nhau, nhưng bạn có thể bỏ chặn hoặc báo cáo người này nếu họ có hành vi không phù hợp.",
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: _unblockOther,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Bỏ chặn'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  _showReportSheet();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Báo cáo'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _unrestrictOther() async {
    if (_otherId != null && _hasRestrictedOther) {
      await FirebaseUserService().unrestrictUser(_otherId!);
      setState(() {
        _hasRestrictedOther = false;
        // the parent widget's subscription will update its own restricted
        // list; we don't need to manage that here.
      });
    }
  }

  Future<void> _unblockOther() async {
    if (_otherId != null && _hasBlockedOther) {
      await FirebaseUserService().unblockUser(_otherId!);
      setState(() {
        _hasBlockedOther = false;
      });
    }
  }

  void _showReportSheet() {
    String feedback = '';
    final suggestions = [
      'Nội dung không phù hợp',
      'Spam / quảng cáo',
      'Làm phiền tôi',
      'Ngôn ngữ xúc phạm',
      'Lý do khác',
    ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        // use stateful builder to enable button enable/disable
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Báo cáo người dùng',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Vui lòng mô tả lý do bạn muốn báo cáo:'),
                    const SizedBox(height: 8),
                    TextField(
                      maxLines: 4,
                      onChanged: (v) {
                        feedback = v;
                        setState(() {});
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Nhập lý do tại đây...',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: suggestions.map((s) {
                        return ActionChip(
                          label: Text(s),
                          onPressed: () {
                            feedback = s;
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Đã báo cáo: $s')),
                            );
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('Huỷ'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: feedback.isNotEmpty
                              ? () {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Đã gửi báo cáo: $feedback',
                                      ),
                                    ),
                                  );
                                }
                              : null,
                          child: const Text('Gửi'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// recompute mutual friend count and friendship status
  void _computeMutual() {
    if (_myFollowerIds.isNotEmpty && _otherFollowerIds.isNotEmpty) {
      final mySet = _myFollowerIds.toSet();
      final mutual = mySet.intersection(_otherFollowerIds.toSet()).length;
      _mutualCount = mutual;
      // two users are "friends" when they follow each other
      final cur = _messageRepository.currentUserId;
      _areFriends =
          cur != null &&
          _otherId != null &&
          _myFollowerIds.contains(_otherId) &&
          _otherFollowerIds.contains(cur);
      if (cur != null && _otherId != null) {
        _followsOther = _otherFollowerIds.contains(cur);
        _followedByOther = _myFollowerIds.contains(_otherId);
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    // if this convo was archived locally, move it back out
    if (ArchivedChatsPage.isArchived(widget.conversationId)) {
      ArchivedChatsPage.removeArchivedChat(widget.conversationId);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ArchivedChatsPage.changeNotifier.value++;
      });
    }

    final bool isFirstMessage =
        _conversation == null ||
        _conversation!.lastMessage == null ||
        _conversation!.lastMessage!.isEmpty;

    await _messageRepository.sendMessage(
      conversationId: widget.conversationId,
      content: text,
      senderName: _myDisplayName, // Use resolved current user name
    );

    final bool isSuggestionChip =
        text == 'Tôi cần tư vấn thêm' ||
        text == 'Cho tôi xem bảng giá' ||
        text == 'Shop ở đâu vậy?' ||
        text == 'Dịch vụ này thế nào?' ||
        text.startsWith('Tôi muốn tìm hiểu thêm về');

    // Auto-reply logic for business chats
    if ((isFirstMessage || isSuggestionChip) &&
        widget.isBusinessChat &&
        _otherId != null) {
      // Ensure we're not inside the trip_ai chat
      if (_otherId != 'trip_ai') {
        try {
          final accountService = FirebaseAccountService();
          final extendedProfile = await accountService.getUserExtendedProfile(
            _otherId!,
          );
          if (extendedProfile != null) {
            final businessProfile =
                extendedProfile['businessProfile'] as Map<String, dynamic>? ??
                {};
            final autoReply =
                businessProfile['autoReply'] as Map<String, dynamic>? ?? {};
            if (autoReply['enabled'] == true) {
              final replyText = (autoReply['message'] ?? '').toString();
              if (replyText.isNotEmpty) {
                // Determine the business name and photo to use as the sender
                final businessName =
                    (businessProfile['name'] ?? widget.displayName).toString();
                final media =
                    businessProfile['media'] as Map<String, dynamic>? ?? {};
                final avatarPath = media['avatarPath'] as String?;

                await _messageRepository.sendMessage(
                  conversationId: widget.conversationId,
                  content: replyText,
                  senderName: businessName.isNotEmpty
                      ? businessName
                      : widget.displayName,
                  senderPhotoUrl: avatarPath ?? widget.displayPhoto,
                  senderIdOverride: _otherId,
                );
              }
            }
          }
        } catch (e) {
          debugPrint('Error sending auto reply: $e');
        }
      }
    }

    // Scroll to bottom after sending
    _scrollToBottom();
  }

  void _scrollToBottom() {
    void doJump() {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    }

    void doAnimate() {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      doJump();
      Future.delayed(const Duration(milliseconds: 100), doJump);
      Future.delayed(const Duration(milliseconds: 220), doAnimate);
    });
  }

  void _jumpToBottom() {
    void doJump() {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      doJump();
      Future.delayed(const Duration(milliseconds: 80), doJump);
      Future.delayed(const Duration(milliseconds: 160), doJump);
    });
  }

  /// Show forward dialog to select conversation for forwarding message
  void _showForwardDialog(MessageModel message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Chuyển tiếp tin nhắn',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<List<ConversationModel>>(
                      stream: _messageRepository.getConversations(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final conversations = snapshot.data!
                            .where((c) => c.id != widget.conversationId)
                            .toList();
                        if (conversations.isEmpty) {
                          return const Center(
                            child: Text('Không có cuộc trò chuyện nào'),
                          );
                        }
                        return ListView.builder(
                          controller: scrollController,
                          itemCount: conversations.length,
                          itemBuilder: (context, index) {
                            final conv = conversations[index];
                            final isGroup = conv.type == ConversationType.group;
                            final displayName = isGroup
                                ? conv.name
                                : conv.participantNames.values
                                          .where((n) => n != widget.displayName)
                                          .firstOrNull ??
                                      conv.name;
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: conv.photoUrl != null
                                    ? getImageProvider(conv.photoUrl!)
                                    : const AssetImage('asset/images/OIP.jpg')
                                          as ImageProvider,
                              ),
                              title: Text(displayName ?? 'Cuộc trò chuyện'),
                              onTap: () async {
                                Navigator.pop(context);
                                // Forward the message
                                await _messageRepository.sendMessage(
                                  conversationId: conv.id,
                                  content: message.content,
                                  senderName: _myDisplayName,
                                  type: message.type,
                                );
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Đã chuyển tiếp tin nhắn'),
                                    ),
                                  );
                                }
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatCurrency(dynamic value) {
    if (value == null) return 'Liên hệ';
    final number = value is num
        ? value.toInt()
        : int.tryParse(value.toString());
    if (number == null) return 'Liên hệ';
    final s = number.toString();
    final reg = RegExp(r'\B(?=(\d{3})+(?!\d))');
    return '${s.replaceAll(reg, '.')} đ';
  }

  Widget _buildBusinessWelcomeMessage() {
    return Container(
      color: const Color(0xFFF5F5F3),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          const Icon(Icons.storefront, color: Color(0xFF113953), size: 36),
          const SizedBox(height: 12),
          Text(
            "Chào mừng bạn đến với ${widget.displayName}! Dưới đây là một số dịch vụ nổi bật của chúng tôi.",
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _businessServicesFuture ?? Future.value([]),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return Text(
                  'Hiện chưa có dịch vụ nổi bật nào. (ID: ${_otherId ?? "null"})',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                );
              }
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: items.map((item) {
                    final name = (item['name'] ?? 'Không có tên').toString();
                    final price = _formatCurrency(item['price']);
                    final categoryLabel = (item['categoryLabel'] ?? '')
                        .toString();

                    IconData icon = Icons.local_offer;
                    if (categoryLabel == 'Thuê xe')
                      icon = Icons.directions_car;
                    else if (categoryLabel == 'Vé máy bay')
                      icon = Icons.flight;
                    else if (categoryLabel == 'Vé tàu/phà')
                      icon = Icons.directions_boat;
                    else if (categoryLabel == 'Vé tàu hỏa')
                      icon = Icons.train;
                    else if (categoryLabel == 'Vé xe khách')
                      icon = Icons.directions_bus;
                    else if (categoryLabel == 'Khách sạn')
                      icon = Icons.hotel;
                    else if (categoryLabel == 'Hướng dẫn viên')
                      icon = Icons.record_voice_over;
                    else if (categoryLabel == 'Chụp ảnh')
                      icon = Icons.camera_alt;
                    else if (categoryLabel == 'Thuê đồ')
                      icon = Icons.checkroom;
                    else if (categoryLabel == 'Ẩm thực')
                      icon = Icons.restaurant;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: _buildProductCard(name, price, icon),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(String title, String price, IconData icon) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF113953), size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            price,
            style: const TextStyle(color: Colors.deepOrange, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 28,
            child: ElevatedButton(
              onPressed: () {
                _messageController.text = "Tôi muốn tìm hiểu thêm về $title";
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF113953),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Hỏi ngay',
                style: TextStyle(fontSize: 11, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build the placeholder shown when a conversation has no messages yet.
  ///
  /// Shows information about the other user if available, otherwise
  /// falls back to a generic stub.  The button navigates to the profile
  /// page and synchronises avatar and location automatically via
  /// [_otherUser] subscription.
  Widget _buildNewConversationPlaceholder() {
    // Check if this is a group chat
    final isGroupChat =
        widget.isGroup || (_conversation?.type == ConversationType.group);

    if (isGroupChat) {
      return _buildGroupPlaceholder();
    }

    final user = _otherUser;
    if (user == null) {
      // still loading user data
      return const Center(child: CircularProgressIndicator());
    }
    final isBiz = widget.isBusinessChat;
    if (isBiz) return const SizedBox.shrink();
    final avatarUrl = user.photoUrl;
    final displayName = isBiz ? widget.displayName : user.displayName;
    final living = isBiz ? null : user.address;
    final bio = isBiz ? null : user.bio;
    final mutual = isBiz ? null : _mutualCount;

    // current friendship state
    final notFriend = !_areFriends;
    final followLabel = notFriend
        ? (_followsOther
              ? 'Đang theo dõi'
              : (_followedByOther ? 'Theo dõi lại' : 'Theo dõi'))
        : 'Bạn bè';

    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 45,
            backgroundImage:
                getImageProvider(avatarUrl) ??
                const AssetImage('asset/images/OIP.jpg') as ImageProvider,
          ),
          const SizedBox(height: 15),
          if (displayName.isNotEmpty)
            Text(
              displayName,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          const SizedBox(height: 5),
          if (notFriend && !isBiz)
            const Text(
              'Các bạn không phải là bạn bè trên Trip',
              style: TextStyle(color: Colors.grey),
            )
          else if (!isBiz)
            Text(
              'Bạn và $displayName là bạn bè trên Trip',
              style: const TextStyle(color: Colors.grey),
            ),
          if (living != null && living.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              'Sống tại $living',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
          if (bio != null && bio.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              'Điểm đến: $bio',
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
          if (mutual != null && mutual > 0) ...[
            const SizedBox(height: 5),
            Text(
              'Bạn chung $mutual người',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isBiz &&
                  notFriend &&
                  !_hasBlockedOther &&
                  !_blockedByOther) ...[
                ElevatedButton.icon(
                  onPressed: () async {
                    final repo = context.read<UserRepository>();
                    final cur = repo.currentUserId;
                    if (cur == null || user.uid.isEmpty) return;
                    if (_followsOther) {
                      if (!_ensureSignedIn()) return;
                      await repo.unfollowUser(user.uid);
                    } else {
                      if (!_ensureSignedIn()) return;
                      await repo.followUser(user.uid);
                    }
                    if (!mounted) return;
                    setState(() {});
                  },
                  icon: Icon(
                    _followsOther ? Icons.check : Icons.person_add,
                    color: _followsOther ? Colors.black : Colors.white,
                    size: 18,
                  ),
                  label: Text(
                    followLabel,
                    style: TextStyle(
                      color: _followsOther ? Colors.black : Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _followsOther
                        ? Colors.grey[300]
                        : const Color(0xFFFFB620),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              if (!isBiz)
                ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Profile(
                          userId: user.uid,
                          name: user.displayName,
                          avatar: user.photoUrl,
                          isOnline: user.isOnline,
                          showBottomNav: true,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.person, size: 18, color: Colors.white),
                  label: const Text(
                    "Xem trang cá nhân",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB620),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build the placeholder for group chats
  Widget _buildGroupPlaceholder() {
    final conv = _conversation;
    final groupName = _groupName ?? widget.displayName;
    final participantCount = conv?.participants.length ?? 0;

    // Build participant names string
    String participantNames = '';
    if (conv != null && conv.participantNames.isNotEmpty) {
      final names = conv.participantNames.values.take(5).toList();
      if (conv.participantNames.length > 5) {
        names.add('+${conv.participantNames.length - 5}');
      }
      participantNames = names.join(', ');
    }

    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Group avatar
          CircleAvatar(
            radius: 45,
            backgroundColor: const Color(0xFF113953),
            child: const Icon(Icons.group, size: 45, color: Colors.white),
          ),
          const SizedBox(height: 15),
          // Group name
          Text(
            groupName,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),
          // Member count
          Text(
            '$participantCount thành viên',
            style: const TextStyle(color: Colors.grey),
          ),
          if (participantNames.isNotEmpty) ...[
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                participantNames,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          const SizedBox(height: 15),
          // Edit group name button
          ElevatedButton.icon(
            onPressed: _showEditGroupNameDialog,
            icon: const Icon(Icons.edit, size: 18, color: Colors.white),
            label: const Text(
              "Sửa tên nhóm",
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFB620),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            ),
          ),
        ],
      ),
    );
  }

  /// Show dialog to edit group name
  Future<void> _showEditGroupNameDialog() async {
    final controller = TextEditingController(
      text: _groupName ?? widget.displayName,
    );

    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sửa tên nhóm'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Nhập tên nhóm mới',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Huỷ'),
            ),
            ElevatedButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isNotEmpty) {
                  Navigator.pop(context, text);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB620),
              ),
              child: const Text('Lưu', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (newName != null && newName.isNotEmpty && mounted) {
      try {
        await _messageRepository.updateGroupName(
          widget.conversationId,
          newName,
        );
        setState(() {
          _groupName = newName;
        });
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Đã cập nhật tên nhóm')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
        }
      }
    }
  }

  Widget _buildChatScaffold(BuildContext context, String currentUserId) {
    // determine friendship flag early so AppBar / banners can use it
    final bool notFriendProp = !_areFriends;

    // wrap scaffold in a ScaffoldMessenger so we control its context
    return ScaffoldMessenger(
      key: _messengerKey,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F3),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF5F5F3),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF113953)),
            onPressed: () => Navigator.pop(context),
          ),
          title: InkWell(
            onTap: () {
              if (widget.isBusinessChat &&
                  _otherId != null &&
                  _otherId!.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        BusinessProfilePage(ownerId: _otherId!),
                  ),
                );
              }
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    // Show group icon for groups, avatar for private chats
                    if (widget.isGroup ||
                        (_conversation?.type == ConversationType.group))
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFF113953),
                        child: const Icon(
                          Icons.group,
                          color: Colors.white,
                          size: 22,
                        ),
                      )
                    else
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: widget.displayPhoto != null
                            ? getImageProvider(widget.displayPhoto!)
                            : const AssetImage('asset/images/OIP.jpg')
                                  as ImageProvider,
                      ),
                    // Online indicator dot (chỉ hiện khi là bạn bè và không phải group, hoặc là doanh nghiệp)
                    if (!widget.isGroup &&
                        _conversation?.type != ConversationType.group &&
                        (widget.isBusinessChat ||
                            ((_areFriends &&
                                    !_restrictedByOther &&
                                    !_blockedByOther &&
                                    !_hasBlockedOther) &&
                                isUserOnline(
                                  _otherUser?.isOnline ?? false,
                                  _otherUser?.lastSeen,
                                ))))
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        (widget.isGroup ||
                                _conversation?.type == ConversationType.group)
                            ? (_groupName ?? widget.displayName)
                            : widget.displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF113953),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Show member count for groups, lastSeen for private chats
                      if (widget.isGroup ||
                          _conversation?.type == ConversationType.group)
                        Text(
                          '${_conversation?.participants.length ?? 0} thành viên',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        )
                      else if (widget.isBusinessChat)
                        const Text(
                          'Đang hoạt động',
                          style: TextStyle(fontSize: 12, color: Colors.green),
                        )
                      else if (_areFriends &&
                          !_restrictedByOther &&
                          !_blockedByOther &&
                          !_hasBlockedOther)
                        Text(
                          formatLastSeen(
                            _otherUser?.lastSeen,
                            _otherUser?.isOnline ?? false,
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                isUserOnline(
                                  _otherUser?.isOnline ?? false,
                                  _otherUser?.lastSeen,
                                )
                                ? Colors.green
                                : Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            if (widget.isBusinessChat)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Color(0xFF113953)),
                onSelected: (value) async {
                  if (value == 'report') {
                    _showReportSheet();
                  } else if (value == 'block') {
                    showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text('Chặn doanh nghiệp'),
                        content: const Text(
                          'Bạn có chắc muốn chặn doanh nghiệp này không? Bạn sẽ không nhận được tin nhắn từ họ nữa.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(c, false),
                            child: const Text('Hủy'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(c, true),
                            child: const Text(
                              'Chặn',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ).then((confirm) async {
                      if (confirm == true && _otherId != null) {
                        await FirebaseUserService().blockUser(_otherId!);
                        if (mounted) {
                          setState(() {
                            _hasBlockedOther = true;
                          });
                        }
                      }
                    });
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'report', child: Text('Báo cáo')),
                  const PopupMenuItem(value: 'block', child: Text('Chặn')),
                ],
              ),
            if (!widget.isBusinessChat) ...[
              IconButton(
                icon: const Icon(Icons.phone, color: Color(0xFF113953)),
                onPressed: () async {
                  final result = await Navigator.push<Map<String, dynamic>>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VoiceCallPage(
                        name: widget.displayName,
                        avatar: widget.displayPhoto,
                        conversationId: widget.conversationId,
                      ),
                    ),
                  );
                  // Send call message
                  if (result != null && mounted) {
                    final duration = result['duration'] as int? ?? 0;
                    final answered = result['answered'] as bool? ?? false;
                    String callContent;
                    if (!answered) {
                      callContent = 'Cuộc gọi nhỡ';
                    } else if (duration == 0) {
                      callContent = 'Cuộc gọi thoại';
                    } else {
                      final mins = duration ~/ 60;
                      final secs = duration % 60;
                      final durationStr = mins > 0
                          ? '$mins phút ${secs.toString().padLeft(2, '0')} giây'
                          : '$secs giây';
                      callContent = 'Cuộc gọi thoại - $durationStr';
                    }
                    await _messageRepository.sendMessage(
                      conversationId: widget.conversationId,
                      content: callContent,
                      senderName:
                          FirebaseAuth.instance.currentUser?.displayName ?? '',
                      senderPhotoUrl:
                          FirebaseAuth.instance.currentUser?.photoURL,
                      type: MessageType.voiceCall,
                      metadata: {'duration': duration, 'answered': answered},
                    );
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.videocam, color: Color(0xFF113953)),
                onPressed: () async {
                  final result = await Navigator.push<Map<String, dynamic>>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VideoCallPage(
                        name: widget.displayName,
                        avatar: widget.displayPhoto,
                        conversationId: widget.conversationId,
                      ),
                    ),
                  );
                  // Send call message
                  if (result != null && mounted) {
                    final duration = result['duration'] as int? ?? 0;
                    final answered = result['answered'] as bool? ?? false;
                    String callContent;
                    if (!answered) {
                      callContent = 'Cuộc gọi video nhỡ';
                    } else if (duration == 0) {
                      callContent = 'Cuộc gọi video';
                    } else {
                      final mins = duration ~/ 60;
                      final secs = duration % 60;
                      final durationStr = mins > 0
                          ? '$mins phút ${secs.toString().padLeft(2, '0')} giây'
                          : '$secs giây';
                      callContent = 'Cuộc gọi video - $durationStr';
                    }
                    await _messageRepository.sendMessage(
                      conversationId: widget.conversationId,
                      content: callContent,
                      senderName:
                          FirebaseAuth.instance.currentUser?.displayName ?? '',
                      senderPhotoUrl:
                          FirebaseAuth.instance.currentUser?.photoURL,
                      type: MessageType.videoCall,
                      metadata: {'duration': duration, 'answered': answered},
                    );
                  }
                },
              ),
            ],
          ],
          // banner moved to body; AppBar no longer includes it
          bottom: null,
        ),
        bottomNavigationBar: _hasBlockedOther
            ? _buildBlockedFooter()
            : (_hasRestrictedOther ? _buildRestrictedFooter() : null),
        body: Column(
          children: [
            // if we've been blocked by the other user, show a notice above the
            // message list so it's immediately obvious.  we still allow typing
            // since messages technically still go through, but the user should
            // understand they won't be received.
            if (_blockedByOther)
              Container(
                color: Colors.yellow[100],
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: const Text(
                  'Bạn đã bị người này chặn. Tin nhắn mới sẽ không tới và họ sẽ không biết khi bạn online.',
                  style: TextStyle(color: Colors.black87),
                ),
              ),
            Expanded(
              child: StreamBuilder(
                stream: _messageRepository.getMessages(widget.conversationId),
                builder: (context, snapshot) {
                  // Don't block the UI with a spinner; render empty state
                  // until messages arrive so it feels instant.

                  final raw = snapshot.data ?? [];
                  // Stream returns newest-first (descending).  With
                  // reverse: true on the ListView, index 0 is at the
                  // bottom of the viewport, so we keep newest-first
                  // order directly.
                  final messages = raw;
                  // true when this conversation has no messages yet
                  final isNewConversation = messages.isEmpty;
                  // we already computed notFriendProp earlier; reuse it

                  // Auto scroll to bottom on first data load or when new messages arrive
                  if (messages.isNotEmpty) {
                    if (!_hasScrolledToBottom ||
                        messages.length > _lastMessageCount) {
                      final isInitial = !_hasScrolledToBottom;
                      _hasScrolledToBottom = true;
                      _lastMessageCount = messages.length;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (isInitial) {
                          _jumpToBottom();
                        } else {
                          _scrollToBottom();
                        }
                      });
                    }
                  }

                  return Column(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                          // Messenger-style: profile at top, messages below
                          // Profile stays at top until messages push it up
                          child: ListView.builder(
                            controller: _scrollController,
                            // NOT reversed - profile at index 0, messages follow
                            reverse: false,
                            physics: null,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 10,
                            ),
                            // First item is profile header, then messages
                            itemCount: messages.length + 1,
                            itemBuilder: (context, index) {
                              // Index 0 is the profile header at TOP
                              if (index == 0) {
                                // profile section plus any banners
                                return Column(
                                  children: [
                                    _buildNewConversationPlaceholder(),
                                    if (widget.isBusinessChat &&
                                        isNewConversation)
                                      _buildBusinessWelcomeMessage()
                                    else if (notFriendProp &&
                                        !widget.isGroup &&
                                        !widget.isBusinessChat)
                                      Container(
                                        color: const Color(0xFFF5F5F3),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          "Yêu cầu trò chuyện đã được gửi tới ${widget.displayName}. Vui lòng đợi ${widget.displayName} chấp nhận.",
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    if (!notFriendProp &&
                                        isNewConversation &&
                                        !widget.isBusinessChat)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                          horizontal: 16,
                                        ),
                                        child: RichText(
                                          textAlign: TextAlign.center,
                                          text: TextSpan(
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                            children: [
                                              const TextSpan(
                                                text:
                                                    'Tin nhắn và cuộc gọi được mã hóa đầu cuối ',
                                              ),
                                              WidgetSpan(
                                                alignment:
                                                    PlaceholderAlignment.middle,
                                                child: Icon(
                                                  Icons.lock_outline,
                                                  size: 14,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              }

                              // Messages start from index 1
                              // Reverse the order: oldest first (index 1 = oldest message)
                              final messageIndex = messages.length - index;
                              final message = messages[messageIndex];
                              final isMe = message.senderId == currentUserId;

                              // Get previous message for timestamp comparison
                              MessageModel? prevMessage;
                              if (messageIndex < messages.length - 1) {
                                prevMessage = messages[messageIndex + 1];
                              }

                              // Determine if we should show timestamp separator
                              final showTimestamp = shouldShowTimestamp(
                                prevMessage,
                                message,
                              );

                              // Determine if this is the last message in a series from same sender
                              // (show avatar only for the LAST message in a consecutive series - bottom)
                              // In display order (oldest to newest), we check if next message is from different sender
                              bool showAvatar = true;
                              final nextMessageIndex = messageIndex - 1;
                              if (nextMessageIndex >= 0) {
                                final nextMessage = messages[nextMessageIndex];
                                // If next message is from same sender, don't show avatar yet
                                if (nextMessage.senderId == message.senderId) {
                                  showAvatar = false;
                                }
                              }

                              // Check if this is the newest message (last in display order)
                              final isNewestMessage = messageIndex == 0;
                              // Check if other user has seen this message
                              final otherUserId = _otherUser?.uid;
                              final hasBeenSeen =
                                  isMe &&
                                  isNewestMessage &&
                                  otherUserId != null &&
                                  message.readBy.contains(otherUserId);

                              return Column(
                                children: [
                                  // Show timestamp separator if messages are 20+ minutes apart
                                  if (showTimestamp)
                                    TimestampSeparator(
                                      timestamp: message.createdAt,
                                    ),

                                  // Message bubble
                                  MessageBubble(
                                    message: message,
                                    isMe: isMe,
                                    senderPhotoUrl: widget.displayPhoto,
                                    currentUserId: currentUserId,
                                    showAvatar: showAvatar,
                                    onRecall: () async {
                                      await _messageRepository.recallMessage(
                                        widget.conversationId,
                                        message.id,
                                      );
                                    },
                                    onDeleteForMe: () async {
                                      await _messageRepository
                                          .deleteMessageForMe(
                                            widget.conversationId,
                                            message.id,
                                          );
                                    },
                                    onForward: (msg) {
                                      _showForwardDialog(msg);
                                    },
                                  ),

                                  // Seen indicator - show small avatar when other user has read the message
                                  if (hasBeenSeen)
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          right: 4,
                                          top: 4,
                                        ),
                                        child: CircleAvatar(
                                          radius: 8,
                                          backgroundImage:
                                              widget.displayPhoto != null
                                              ? getImageProvider(
                                                  widget.displayPhoto!,
                                                )
                                              : const AssetImage(
                                                      'asset/images/OIP.jpg',
                                                    )
                                                    as ImageProvider,
                                        ),
                                      ),
                                    )
                                  // Sent indicator - show checkmark when message sent but not yet read
                                  else if (isMe &&
                                      isNewestMessage &&
                                      !hasBeenSeen)
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          right: 4,
                                          top: 4,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: const [
                                            Icon(
                                              Icons.check,
                                              size: 12,
                                              color: Colors.grey,
                                            ),
                                            Text(
                                              ' Đã gửi',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),

                      // quick reply chips (only when conversation is new)
                      if (!_hasRestrictedOther && isNewConversation) ...[
                        Container(
                          height: 50,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          color: const Color(0xFFF5F5F3),
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children:
                                (widget.isBusinessChat
                                        ? [
                                            'Tôi cần tư vấn thêm',
                                            'Cho tôi xem bảng giá',
                                            'Shop ở đâu vậy?',
                                            'Dịch vụ này thế nào?',
                                          ]
                                        : [
                                            'Bạn ăn cơm chưa:))',
                                            'Chào!',
                                            'Xin chào!',
                                            '👍',
                                            'Hello',
                                            'Cảm ơn',
                                            "Hi",
                                          ])
                                    .map((text) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        child: ActionChip(
                                          label: Text(text),
                                          onPressed: () {
                                            _messageController.text = text;
                                            _sendMessage();
                                          },
                                        ),
                                      );
                                    })
                                    .toList(),
                          ),
                        ),
                      ],
                      // Input area (hide when we've blocked the other user)
                      if (!_hasBlockedOther)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: const Color.fromRGBO(0, 0, 0, 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, -2),
                              ),
                            ],
                          ),
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () {
                              // tapping anywhere in the bar should focus the
                              // text field; the field itself may be narrow at
                              // times so this improves hit testing.
                              _inputFocus.requestFocus();
                            },
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_isRecording)
                                  Container(
                                    color: Colors.red[300],
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.mic,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '${_recordDuration.inMinutes.toString().padLeft(2, "0")}:${(_recordDuration.inSeconds % 60).toString().padLeft(2, "0")}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.stop,
                                            color: Colors.white,
                                          ),
                                          onPressed: _onMicPressed,
                                        ),
                                      ],
                                    ),
                                  ),
                                Row(
                                  children: [
                                    // attachments are visible when not typing; once the
                                    // user taps the field we switch into typing mode
                                    // and show a back arrow instead.  tapping the arrow
                                    // exits typing mode and restores the icons.
                                    if (_attachmentsVisible) ...[
                                      if (!widget.isBusinessChat)
                                        IconButton(
                                          icon: const Icon(
                                            Icons.add,
                                            color: Color(0xFF113953),
                                          ),
                                          onPressed: _onAttachPressed,
                                        ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.camera_alt,
                                          color: Color(0xFF113953),
                                        ),
                                        onPressed: _pickFromCamera,
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.image,
                                          color: Color(0xFF113953),
                                        ),
                                        onPressed: _pickFromGallery,
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.mic,
                                          color: Color(0xFF113953),
                                        ),
                                        onPressed: _onMicPressed,
                                      ),
                                    ] else ...[
                                      IconButton(
                                        icon: const Icon(
                                          Icons.arrow_back_ios,
                                          color: Color(0xFF113953),
                                        ),
                                        onPressed: () {
                                          _inputFocus.unfocus();
                                          setState(() {
                                            _attachmentsVisible = true;
                                          });
                                        },
                                      ),
                                    ],
                                    Expanded(
                                      child: TextField(
                                        focusNode: _inputFocus,
                                        controller: _messageController,
                                        readOnly: _attachmentsVisible,
                                        onTap: () {
                                          if (_attachmentsVisible) {
                                            setState(() {
                                              _attachmentsVisible = false;
                                            });
                                            FocusScope.of(
                                              context,
                                            ).requestFocus(_inputFocus);
                                          }
                                        },
                                        decoration: InputDecoration(
                                          hintText: 'Aa',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              25,
                                            ),
                                            borderSide: BorderSide.none,
                                          ),
                                          filled: true,
                                          fillColor: const Color(0xFFF5F5F3),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 10,
                                              ),
                                          suffixIcon: IconButton(
                                            icon: const Icon(
                                              Icons.emoji_emotions,
                                              color: Color(0xFF113953),
                                            ),
                                            onPressed: () {
                                              // TODO: open emoji picker
                                            },
                                          ),
                                        ),
                                        onSubmitted: (_) => _sendMessage(),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        _hasText ? Icons.send : Icons.thumb_up,
                                        color: const Color(0xFF113953),
                                      ),
                                      onPressed: _hasText
                                          ? _sendMessage
                                          : () {
                                              _messageRepository.sendMessage(
                                                conversationId:
                                                    widget.conversationId,
                                                content: '👍',
                                                senderName: _myDisplayName,
                                              );
                                              _scrollToBottom();
                                            },
                                    ),
                                  ], // end Row children
                                ), // end Row
                              ], // end Column children inside GestureDetector
                            ), // end Column
                          ), // end GestureDetector
                        ), // end Container
                    ], // end Column children (outer)
                  ); // end Column (inner)
                }, // end StreamBuilder.builder
              ), // end StreamBuilder
            ), // end Expanded
          ], // end Column children
        ), // end Column
      ), // end Scaffold
    ); // end ScaffoldMessenger
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _messageRepository.currentUserId;
    if (currentUserId == null) {
      return StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          final user = snapshot.data;
          if (user == null) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return _buildChatScaffold(context, user.uid);
        },
      );
    }
    return _buildChatScaffold(context, currentUserId);
  }
}

/// Widget to display online indicator by streaming user status
/// Only shows when both users are friends (mutual following)
class _OnlineIndicator extends StatelessWidget {
  final String userId;

  const _OnlineIndicator({required this.userId});

  @override
  Widget build(BuildContext context) {
    if (userId.isEmpty) return const SizedBox.shrink();

    final currentUserId = context.read<MessageRepository>().currentUserId;
    if (currentUserId == null) return const SizedBox.shrink();

    return StreamBuilder<UserModel?>(
      stream: context.read<UserRepository>().streamUser(userId),
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null) return const SizedBox.shrink();

        // Check if they are friends (mutual following)
        final currentUserFollowsOther = user.followers.contains(currentUserId);
        final otherFollowsCurrentUser = user.following.contains(currentUserId);
        final areFriends = currentUserFollowsOther && otherFollowsCurrentUser;

        // Only show online indicator if they are friends
        if (!areFriends) return const SizedBox.shrink();

        // Use isUserOnline helper to check true online status
        final isOnline = isUserOnline(user.isOnline, user.lastSeen);
        if (!isOnline) return const SizedBox.shrink();

        return Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        );
      },
    );
  }
}
