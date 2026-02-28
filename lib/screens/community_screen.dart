import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:monojog/models/study_room.dart';
import 'package:monojog/providers/study_room_provider.dart';

class _C {
  static const bg = Color(0xFF0A0E1A);
  static const card = Color(0xFF141828);
  static const cardLight = Color(0xFF1C2137);
  static const surface = Color(0xFF1A1F33);
  static const cyan = Color(0xFF00E5FF);
  static const purple = Color(0xFF7C4DFF);
  static const gold = Color(0xFFFFD700);
  static const green = Color(0xFF66FFCC);
  static const red = Color(0xFFFF6B6B);
  static const white = Colors.white;
  static const textSec = Color(0xFF6B7294);
}

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _chatController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StudyRoomProvider>(
      builder: (ctx, room, _) {
        final community = room.joinedCommunity;
        return Scaffold(
          backgroundColor: _C.bg,
          body: SafeArea(
            child: Column(
              children: [
                _buildAppBar(community, room),
                if (community != null) ...[
                  _buildTabBar(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _ChatView(
                          messages: room.communityMessages,
                          room: room,
                          chatController: _chatController,
                        ),
                        _MembersView(community: community),
                        _DiscoverView(
                          allCommunities: room.allCommunities,
                          currentCommunity: community,
                          room: room,
                        ),
                        _NoticesView(room: room),
                      ],
                    ),
                  ),
                ] else
                  Expanded(child: _buildNoCommunity(room)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar(dynamic community, StudyRoomProvider room) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded, color: _C.white),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  community?.name ?? 'Community',
                  style: const TextStyle(
                    color: _C.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    letterSpacing: -0.5,
                  ),
                ),
                if (community != null)
                  Text(
                    '${community.members.length} members • ${community.code}',
                    style: const TextStyle(
                        color: _C.textSec,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
              ],
            ),
          ),
          if (community != null)
            IconButton(
              onPressed: () => _showCommunityInfo(community),
              icon: const Icon(Icons.info_outline_rounded,
                  color: _C.textSec, size: 22),
            ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: _C.cyan.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: _C.cyan.withValues(alpha: 0.3)),
        ),
        labelColor: _C.cyan,
        unselectedLabelColor: _C.textSec,
        labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        tabs: const [
          Tab(text: 'Chat'),
          Tab(text: 'Members'),
          Tab(text: 'Discover'),
          Tab(text: 'Notices'),
        ],
      ),
    );
  }

  Widget _buildNoCommunity(StudyRoomProvider room) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_C.purple, _C.cyan]),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.groups_rounded, color: _C.white, size: 40),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Community Yet',
            style: TextStyle(
                color: _C.white, fontWeight: FontWeight.w900, fontSize: 22),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create a community or join one with a code\nto start chatting and studying together!',
            textAlign: TextAlign.center,
            style: TextStyle(color: _C.textSec, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => _showCreateDialog(room),
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text('Create'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _C.purple,
                      foregroundColor: _C.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => _showJoinDialog(room),
                    icon: const Icon(Icons.login_rounded, size: 20),
                    label: const Text('Join'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _C.cardLight,
                      foregroundColor: _C.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Show all communities
          if (room.allCommunities.isNotEmpty) ...[
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Available Communities',
                style: TextStyle(
                    color: _C.white, fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: room.allCommunities.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final c = room.allCommunities[i];
                  return _communityTile(c, room);
                },
              ),
            ),
          ] else
            const Spacer(),
        ],
      ),
    );
  }

  Widget _communityTile(dynamic c, StudyRoomProvider room) {
    final isMember = c.members.any((m) => m.id == room.myUserId);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _C.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                c.name.isNotEmpty ? c.name[0].toUpperCase() : 'C',
                style: const TextStyle(
                    color: _C.white, fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.name,
                    style: const TextStyle(
                        color: _C.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14)),
                Text('${c.members.length} members',
                    style: const TextStyle(color: _C.textSec, fontSize: 11)),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              final ok = isMember
                  ? room.openCommunity(c.code)
                  : await room.joinCommunity(c.code);
              if (!mounted) return;
              if (ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          isMember ? 'Opened ${c.name}' : 'Joined ${c.name}'),
                      backgroundColor: _C.green),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: _C.cyan,
              backgroundColor: _C.cyan.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
            ),
            child: Text(isMember ? 'Open' : 'Join',
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  void _showCommunityInfo(dynamic community) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _C.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: _C.textSec.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Text(community.name,
                  style: const TextStyle(
                      color: _C.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 20)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: community.code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Code copied!'),
                        backgroundColor: _C.green),
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: _C.cyan.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _C.cyan.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.copy_rounded, color: _C.cyan, size: 16),
                      const SizedBox(width: 8),
                      Text('Share code: ${community.code}',
                          style: const TextStyle(
                              color: _C.cyan,
                              fontWeight: FontWeight.w800,
                              fontSize: 14)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('${community.members.length} members',
                  style: const TextStyle(color: _C.textSec, fontSize: 13)),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateDialog(StudyRoomProvider room) {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Create Community',
            style: TextStyle(fontWeight: FontWeight.w900, color: _C.white)),
        content: TextField(
          controller: nameCtrl,
          style: const TextStyle(color: _C.white),
          decoration: InputDecoration(
            hintText: 'e.g. CSE Batch 2026',
            hintStyle: TextStyle(color: _C.textSec.withValues(alpha: 0.6)),
            filled: true,
            fillColor: _C.surface,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: _C.textSec))),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final name = nameCtrl.text.trim().isEmpty
                  ? 'My Community'
                  : nameCtrl.text.trim();
              final community = await room.createCommunity(name: name);
              if (!mounted || !ctx.mounted) return;
              Navigator.pop(ctx);
              messenger.showSnackBar(SnackBar(
                  content: Text('Created! Code: ${community.code}'),
                  backgroundColor: _C.green));
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: _C.purple, foregroundColor: _C.white),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showJoinDialog(StudyRoomProvider room) {
    final codeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Join Community',
            style: TextStyle(fontWeight: FontWeight.w900, color: _C.white)),
        content: TextField(
          controller: codeCtrl,
          textCapitalization: TextCapitalization.characters,
          textAlign: TextAlign.center,
          maxLength: 7,
          style: const TextStyle(
              color: _C.cyan,
              fontWeight: FontWeight.w900,
              fontSize: 22,
              letterSpacing: 4),
          decoration: InputDecoration(
            counterText: '',
            hintText: 'CODE',
            hintStyle: TextStyle(color: _C.textSec.withValues(alpha: 0.45)),
            filled: true,
            fillColor: _C.surface,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: _C.textSec))),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final ok =
                  await room.joinCommunity(codeCtrl.text.trim().toUpperCase());
              if (!mounted || !ctx.mounted) return;
              Navigator.pop(ctx);
              messenger.showSnackBar(SnackBar(
                content: Text(ok ? 'Joined successfully!' : 'Code not found.'),
                backgroundColor: ok ? _C.green : _C.red,
              ));
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: _C.cyan, foregroundColor: _C.bg),
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════
//  CHAT VIEW
// ═══════════════════════════════════════
class _ChatView extends StatelessWidget {
  final List<dynamic> messages;
  final StudyRoomProvider room;
  final TextEditingController chatController;

  const _ChatView(
      {required this.messages,
      required this.room,
      required this.chatController});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: messages.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded,
                          color: _C.textSec, size: 48),
                      SizedBox(height: 12),
                      Text('No messages yet',
                          style: TextStyle(
                              color: _C.textSec,
                              fontSize: 15,
                              fontWeight: FontWeight.w600)),
                      SizedBox(height: 4),
                      Text('Say hi to your study buddies! 👋',
                          style: TextStyle(color: _C.textSec, fontSize: 13)),
                    ],
                  ),
                )
              : ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  itemCount: messages.length,
                  itemBuilder: (_, index) {
                    final msg = messages[messages.length - 1 - index];
                    final isSystem = msg.senderId == 'system';
                    final isMe = msg.senderId == room.myUserId;

                    if (isSystem) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 5),
                            decoration: BoxDecoration(
                                color: _C.cardLight,
                                borderRadius: BorderRadius.circular(12)),
                            child: Text(msg.text,
                                style: const TextStyle(
                                    color: _C.textSec,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        mainAxisAlignment: isMe
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (!isMe) ...[
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: _C.purple.withValues(alpha: 0.2),
                              child: Text(
                                msg.senderName.isNotEmpty
                                    ? msg.senderName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    color: _C.purple,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? _C.cyan.withValues(alpha: 0.15)
                                    : _C.card,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(18),
                                  topRight: const Radius.circular(18),
                                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                                  bottomRight: Radius.circular(isMe ? 4 : 18),
                                ),
                                border: isMe
                                    ? Border.all(
                                        color: _C.cyan.withValues(alpha: 0.2))
                                    : null,
                              ),
                              child: Column(
                                crossAxisAlignment: isMe
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  if (!isMe)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text(msg.senderName,
                                          style: const TextStyle(
                                              color: _C.cyan,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800)),
                                    ),
                                  Text(msg.text,
                                      style: const TextStyle(
                                          color: _C.white, fontSize: 14)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        _buildInput(context),
      ],
    );
  }

  Widget _buildInput(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
      decoration: BoxDecoration(
        color: _C.card,
        border:
            Border(top: BorderSide(color: _C.cardLight.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: chatController,
              style: const TextStyle(color: _C.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: const TextStyle(color: _C.textSec),
                filled: true,
                fillColor: _C.surface,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _C.cyan,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: _C.cyan.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
            ),
            child: IconButton(
              onPressed: _send,
              icon: const Icon(Icons.send_rounded, color: _C.bg, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  void _send() {
    final text = chatController.text.trim();
    if (text.isEmpty) return;
    room.sendCommunityMessage(text);
    chatController.clear();
  }
}

// ═══════════════════════════════════════
//  MEMBERS VIEW
// ═══════════════════════════════════════
class _MembersView extends StatelessWidget {
  final dynamic community;

  const _MembersView({required this.community});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: community.members.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (_, index) {
        final m = community.members[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _C.card,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: _C.purple.withValues(alpha: 0.2),
                    child: Text(
                      m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                          color: _C.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (m.isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _C.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: _C.card, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.name,
                        style: const TextStyle(
                            color: _C.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(
                      m.isOnline ? 'Studying now' : 'Offline',
                      style: TextStyle(
                          color: m.isOnline ? _C.green : _C.textSec,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Text(
                '${m.studyMinutes}m',
                style: const TextStyle(
                    color: _C.gold, fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════
//  DISCOVER VIEW
// ═══════════════════════════════════════
class _DiscoverView extends StatelessWidget {
  final List<dynamic> allCommunities;
  final dynamic currentCommunity;
  final StudyRoomProvider room;

  const _DiscoverView(
      {required this.allCommunities,
      required this.currentCommunity,
      required this.room});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => _showCreate(context),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Create'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _C.purple,
                      foregroundColor: _C.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => _showJoin(context),
                    icon: const Icon(Icons.login_rounded, size: 18),
                    label: const Text('Join'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _C.cardLight,
                      foregroundColor: _C.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: allCommunities.isEmpty
                ? const Center(
                    child: Text(
                        'No communities yet.\nCreate one to get started!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _C.textSec, fontSize: 14)),
                  )
                : ListView.separated(
                    itemCount: allCommunities.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final c = allCommunities[i];
                      final isActive = currentCommunity?.code == c.code;
                      final isMember =
                          c.members.any((m) => m.id == room.myUserId);
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _C.card,
                          borderRadius: BorderRadius.circular(16),
                          border: isActive
                              ? Border.all(
                                  color: _C.cyan.withValues(alpha: 0.3))
                              : null,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                  color: _C.surface,
                                  borderRadius: BorderRadius.circular(12)),
                              child: Center(
                                child: Text(
                                  c.name.isNotEmpty
                                      ? c.name[0].toUpperCase()
                                      : 'C',
                                  style: const TextStyle(
                                      color: _C.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c.name,
                                      style: const TextStyle(
                                          color: _C.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14)),
                                  Text('${c.members.length} members',
                                      style: const TextStyle(
                                          color: _C.textSec, fontSize: 11)),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                final ok = isMember
                                    ? room.openCommunity(c.code)
                                    : await room.joinCommunity(c.code);
                                if (!context.mounted) return;
                                if (ok) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(isMember
                                            ? 'Opened ${c.name}'
                                            : 'Joined ${c.name}'),
                                        backgroundColor: _C.green),
                                  );
                                }
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: isActive ? _C.green : _C.cyan,
                                backgroundColor: (isActive ? _C.green : _C.cyan)
                                    .withValues(alpha: 0.1),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                minimumSize: Size.zero,
                              ),
                              child: Text(
                                isActive
                                    ? 'Active'
                                    : (isMember ? 'Open' : 'Join'),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showCreate(BuildContext context) {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Create Community',
            style: TextStyle(fontWeight: FontWeight.w900, color: _C.white)),
        content: TextField(
          controller: nameCtrl,
          style: const TextStyle(color: _C.white),
          decoration: InputDecoration(
            hintText: 'e.g. CSE Batch 2026',
            hintStyle: TextStyle(color: _C.textSec.withValues(alpha: 0.6)),
            filled: true,
            fillColor: _C.surface,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: _C.textSec))),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final name = nameCtrl.text.trim().isEmpty
                  ? 'My Community'
                  : nameCtrl.text.trim();
              final community = await room.createCommunity(name: name);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              messenger.showSnackBar(SnackBar(
                  content: Text('Created! Code: ${community.code}'),
                  backgroundColor: _C.green));
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: _C.purple, foregroundColor: _C.white),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showJoin(BuildContext context) {
    final codeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Join Community',
            style: TextStyle(fontWeight: FontWeight.w900, color: _C.white)),
        content: TextField(
          controller: codeCtrl,
          textCapitalization: TextCapitalization.characters,
          textAlign: TextAlign.center,
          maxLength: 7,
          style: const TextStyle(
              color: _C.cyan,
              fontWeight: FontWeight.w900,
              fontSize: 22,
              letterSpacing: 4),
          decoration: InputDecoration(
            counterText: '',
            hintText: 'CODE',
            hintStyle: TextStyle(color: _C.textSec.withValues(alpha: 0.45)),
            filled: true,
            fillColor: _C.surface,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: _C.textSec))),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final ok =
                  await room.joinCommunity(codeCtrl.text.trim().toUpperCase());
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              messenger.showSnackBar(SnackBar(
                content: Text(ok ? 'Joined successfully!' : 'Code not found.'),
                backgroundColor: ok ? _C.green : _C.red,
              ));
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: _C.cyan, foregroundColor: _C.bg),
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Notices View
// ---------------------------------------------------------------------------
class _NoticesView extends StatelessWidget {
  final StudyRoomProvider room;
  const _NoticesView({required this.room});

  @override
  Widget build(BuildContext context) {
    final notices = room.notices;
    final isAdmin = room.isCommunityAdmin;

    if (notices.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.campaign_outlined,
                color: _C.textSec.withValues(alpha: 0.4), size: 56),
            const SizedBox(height: 16),
            const Text(
              'No notices yet',
              style: TextStyle(
                  color: _C.textSec, fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              isAdmin
                  ? 'Tap + to post the first notice'
                  : 'Notices from admins will appear here',
              style: TextStyle(
                  color: _C.textSec.withValues(alpha: 0.6), fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
          itemCount: notices.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (ctx, i) {
            final notice = notices[i];
            return _NoticeCard(
              notice: notice,
              isAdmin: isAdmin,
              onTogglePin: () => room.togglePinNotice(notice.id),
              onDelete: () => room.deleteNotice(notice.id),
            );
          },
        ),
        if (isAdmin)
          Positioned(
            right: 20,
            bottom: 20,
            child: FloatingActionButton(
              backgroundColor: _C.cyan,
              foregroundColor: _C.bg,
              onPressed: () => _showAddNoticeDialog(context),
              child: const Icon(Icons.add_rounded),
            ),
          ),
      ],
    );
  }

  void _showAddNoticeDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('New Notice',
            style: TextStyle(fontWeight: FontWeight.w900, color: _C.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              style: const TextStyle(color: _C.white),
              decoration: InputDecoration(
                hintText: 'Title',
                hintStyle: TextStyle(color: _C.textSec.withValues(alpha: 0.5)),
                filled: true,
                fillColor: _C.surface,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bodyCtrl,
              style: const TextStyle(color: _C.white),
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Body',
                hintStyle: TextStyle(color: _C.textSec.withValues(alpha: 0.5)),
                filled: true,
                fillColor: _C.surface,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: _C.textSec))),
          ElevatedButton(
            onPressed: () {
              final title = titleCtrl.text.trim();
              final body = bodyCtrl.text.trim();
              if (title.isEmpty) return;
              room.addNotice(title: title, body: body);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: _C.cyan, foregroundColor: _C.bg),
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  final CommunityNotice notice;
  final bool isAdmin;
  final VoidCallback onTogglePin;
  final VoidCallback onDelete;

  const _NoticeCard({
    required this.notice,
    required this.isAdmin,
    required this.onTogglePin,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: isAdmin ? () => _showAdminMenu(context) : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notice.pinned ? _C.cardLight : _C.card,
          borderRadius: BorderRadius.circular(16),
          border: notice.pinned
              ? Border.all(color: _C.gold.withValues(alpha: 0.35))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (notice.pinned) ...[
                  const Icon(Icons.push_pin_rounded, color: _C.gold, size: 15),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    notice.title,
                    style: const TextStyle(
                      color: _C.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            if (notice.body.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                notice.body,
                style: const TextStyle(
                    color: _C.white, fontSize: 13.5, height: 1.45),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  notice.authorName,
                  style: const TextStyle(
                      color: _C.cyan,
                      fontWeight: FontWeight.w700,
                      fontSize: 12),
                ),
                const Spacer(),
                Text(
                  _formatDate(notice.createdAt),
                  style: const TextStyle(color: _C.textSec, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAdminMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _C.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: _C.textSec.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: Icon(
                notice.pinned
                    ? Icons.push_pin_outlined
                    : Icons.push_pin_rounded,
                color: _C.gold,
              ),
              title: Text(
                notice.pinned ? 'Unpin Notice' : 'Pin Notice',
                style: const TextStyle(color: _C.white),
              ),
              onTap: () {
                Navigator.pop(ctx);
                onTogglePin();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: _C.red),
              title:
                  const Text('Delete Notice', style: TextStyle(color: _C.red)),
              onTap: () {
                Navigator.pop(ctx);
                onDelete();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
