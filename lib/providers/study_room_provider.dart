import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import 'package:monojog/models/study_room.dart';
import 'package:monojog/providers/focus_provider.dart';
import 'package:monojog/services/history_service.dart';

class StudyRoomProvider with ChangeNotifier {
  StudyRoomProvider();

  static const _uuid = Uuid();
  bool _disposed = false;

  // ── Static "local backend" storage ──
  // Shared across instances — acts as in-memory DB until a real backend is added.

  static final Map<String, StudyCommunity> _communityHubByCode = {};
  static final Map<String, StudyRoom> _roomHubByCode = {};
  static final Map<String, List<RoomMessage>> _roomMessagesByRoomId = {};
  static final Map<String, List<RoomMessage>> _communityMessagesByCode = {};
  static final Map<String, List<CommunityNotice>> _noticesByCommunity = {};

  /// Clear all static state (useful for logout / testing).
  static void resetAll() {
    _communityHubByCode.clear();
    _roomHubByCode.clear();
    _roomMessagesByRoomId.clear();
    _communityMessagesByCode.clear();
    _noticesByCommunity.clear();
  }

  // ── Instance state ──

  StudyCommunity? _joinedCommunity;
  StudyRoom? _currentRoom;
  List<RoomMessage> _messages = [];
  List<RoomMessage> _communityMessages = [];
  Timer? _studyTimer;
  int _myStudySeconds = 0;
  bool _isStudying = false;
  bool _isSoloMode = false;
  String? _cachedGuestId;

  // ── Public getters ──

  StudyCommunity? get joinedCommunity => _joinedCommunity;

  List<StudyCommunity> get allCommunities {
    final list = _communityHubByCode.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(list);
  }

  StudyRoom? get currentRoom => _currentRoom;
  List<RoomMessage> get messages => List.unmodifiable(_messages);
  List<RoomMessage> get communityMessages =>
      List.unmodifiable(_communityMessages);

  int get myStudySeconds => _myStudySeconds;
  bool get isStudying => _isStudying;
  bool get isSoloMode => _isSoloMode;
  bool get isInRoom => _currentRoom != null;
  bool get hasCommunity => _joinedCommunity != null;

  /// Whether the current user is the community owner.
  bool get isCommunityAdmin =>
      _joinedCommunity?.ownerId == myUserId;

  String get inviteCode => _currentRoom?.roomCode ?? '';

  String get formattedTimer {
    final h = _myStudySeconds ~/ 3600;
    final m = (_myStudySeconds % 3600) ~/ 60;
    final s = _myStudySeconds % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:$mm:$ss';
    }
    return '$mm:$ss';
  }

  // ── User identity ──

  String get myUserId {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) return user.uid;
    _cachedGuestId ??= 'guest_${_uuid.v4().substring(0, 8)}';
    return _cachedGuestId!;
  }

  String get _myDisplayName {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName?.trim();
    return (name != null && name.isNotEmpty) ? name : 'Guest';
  }

  // ─��� Notices ──

  /// Notices for current community (pinned first, then by date).
  List<CommunityNotice> get notices {
    if (_joinedCommunity == null) return const [];
    final list = List<CommunityNotice>.from(
        _noticesByCommunity[_joinedCommunity!.code] ?? []);
    list.sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      return b.createdAt.compareTo(a.createdAt);
    });
    return list;
  }

  void addNotice({required String title, required String body}) {
    if (_joinedCommunity == null) return;
    final code = _joinedCommunity!.code;
    final notice = CommunityNotice(
      id: _uuid.v4(),
      communityCode: code,
      authorId: myUserId,
      authorName: _myDisplayName,
      title: title,
      body: body,
      createdAt: DateTime.now(),
    );
    _noticesByCommunity.putIfAbsent(code, () => []);
    _noticesByCommunity[code]!.add(notice);
    _addCommunitySystemMessage(code, '📢 New notice: $title');
    _notify();
  }

  void deleteNotice(String noticeId) {
    if (_joinedCommunity == null) return;
    final code = _joinedCommunity!.code;
    _noticesByCommunity[code]?.removeWhere((n) => n.id == noticeId);
    _notify();
  }

  void togglePinNotice(String noticeId) {
    if (_joinedCommunity == null) return;
    final code = _joinedCommunity!.code;
    final list = _noticesByCommunity[code];
    if (list == null) return;
    final idx = list.indexWhere((n) => n.id == noticeId);
    if (idx < 0) return;
    list[idx] = list[idx].copyWith(pinned: !list[idx].pinned);
    _notify();
  }

  // ── Community rooms ──

  /// Active rooms for a given community.
  List<StudyRoom> getCommunityRooms(String communityCode) {
    final community = _communityHubByCode[communityCode];
    if (community == null) return const [];

    return community.roomIds
        .map((roomId) => _roomHubByCode.values
        .cast<StudyRoom?>()
        .firstWhere((r) => r?.id == roomId, orElse: () => null))
        .whereType<StudyRoom>()
        .where((r) => r.isActive)
        .toList();
  }

  /// All active rooms (for discovery).
  List<StudyRoom> get allActiveRooms =>
      _roomHubByCode.values.where((r) => r.isActive).toList();

  // ── Invite helpers ──

  String buildInviteLink() {
    if (_currentRoom == null) return '';
    return 'https://monojog.app/invite?code=${_currentRoom!.roomCode}';
  }

  /// Extract a 6-char room code from user input (raw code or URL).
  String? extractInviteCode(String input) {
    final value = input.trim();
    if (value.isEmpty) return null;

    // Matches the character set used by generateRoomCode
    final codePattern = RegExp(r'^[A-HJ-NP-Z2-9]{6}$');

    if (value.length == 6 && codePattern.hasMatch(value.toUpperCase())) {
      return value.toUpperCase();
    }

    final uri = Uri.tryParse(value);
    if (uri == null) return null;

    final fromQuery = uri.queryParameters['code']?.toUpperCase();
    if (fromQuery != null && codePattern.hasMatch(fromQuery)) {
      return fromQuery;
    }

    if (uri.pathSegments.isNotEmpty) {
      final candidate = uri.pathSegments.last.toUpperCase();
      if (codePattern.hasMatch(candidate)) return candidate;
    }

    return null;
  }

  // ── Community CRUD ──

  Future<StudyCommunity> createCommunity({
    required String name,
  }) async {
    final now = DateTime.now();
    final code = _generateUniqueCommunityCode();

    final me = RoomMember(
      id: myUserId,
      name: _myDisplayName,
      isOnline: true,
      joinedAt: now,
    );

    final community = StudyCommunity(
      id: _uuid.v4(),
      name: name,
      code: code,
      ownerId: myUserId,
      ownerName: _myDisplayName,
      createdAt: now,
      members: [me],
    );

    _communityHubByCode[code] = community;
    _communityMessagesByCode.putIfAbsent(code, () => []);
    _joinedCommunity = community;
    _communityMessages = _communityMessagesByCode[code] ?? [];
    _addCommunitySystemMessage(
        code, 'Community "$name" created by $_myDisplayName');
    _notify();
    return community;
  }

  Future<bool> joinCommunity(String code) async {
    final community = _communityHubByCode[code.toUpperCase()];
    if (community == null) return false;

    final alreadyMember =
    community.members.any((m) => m.id == myUserId);
    final updatedMembers = [...community.members];
    if (!alreadyMember) {
      updatedMembers.add(RoomMember(
        id: myUserId,
        name: _myDisplayName,
        isOnline: true,
        joinedAt: DateTime.now(),
      ));
    }

    final updated = community.copyWith(members: updatedMembers);
    _communityHubByCode[community.code] = updated;
    _joinedCommunity = updated;
    _communityMessagesByCode.putIfAbsent(community.code, () => []);
    _communityMessages =
        _communityMessagesByCode[community.code] ?? [];

    if (!alreadyMember) {
      _addCommunitySystemMessage(
          community.code, '$_myDisplayName joined the community 👋');
    }
    _notify();
    return true;
  }

  bool openCommunity(String code) {
    final community = _communityHubByCode[code.toUpperCase()];
    if (community == null) return false;
    _joinedCommunity = community;
    _communityMessagesByCode.putIfAbsent(community.code, () => []);
    _communityMessages =
        _communityMessagesByCode[community.code] ?? [];
    _notify();
    return true;
  }

  void leaveCommunity() {
    if (_joinedCommunity == null) return;
    final code = _joinedCommunity!.code;
    final community = _communityHubByCode[code];
    if (community != null) {
      final updatedMembers =
      community.members.where((m) => m.id != myUserId).toList();
      _communityHubByCode[code] =
          community.copyWith(members: updatedMembers);
      _addCommunitySystemMessage(
          code, '$_myDisplayName left the community');
    }
    _joinedCommunity = null;
    _communityMessages = [];
    _notify();
  }

  void sendCommunityMessage(String text) {
    final community = _joinedCommunity;
    if (community == null || text.trim().isEmpty) return;

    final msg = RoomMessage(
      id: _uuid.v4(),
      roomId: community.code,
      senderId: myUserId,
      senderName: _myDisplayName,
      text: text.trim(),
      timestamp: DateTime.now(),
    );

    final list = _communityMessagesByCode[community.code] ?? [];
    list.add(msg);
    _communityMessagesByCode[community.code] = list;
    _communityMessages = list;
    _notify();
  }

  // ── Room CRUD ──

  Future<StudyRoom> createRoom({
    required String name,
    String? subject,
    int targetMinutes = 60,
    String? communityCode,
  }) async {
    final roomCode = _generateUniqueRoomCode();
    final now = DateTime.now();

    final me = RoomMember(
      id: myUserId,
      name: _myDisplayName,
      isOnline: true,
      joinedAt: now,
    );

    final effectiveCommunityCode =
        communityCode ?? _joinedCommunity?.code;

    final room = StudyRoom(
      id: _uuid.v4(),
      name: name,
      hostId: myUserId,
      hostName: _myDisplayName,
      roomCode: roomCode,
      members: [me],
      createdAt: now,
      subject: subject,
      targetMinutes: targetMinutes,
      communityCode: effectiveCommunityCode,
    );

    _roomHubByCode[roomCode] = room;
    _roomMessagesByRoomId[room.id] = [];

    // Link to community if applicable
    if (effectiveCommunityCode != null) {
      final community =
      _communityHubByCode[effectiveCommunityCode];
      if (community != null) {
        final updatedCommunity = community.copyWith(
          roomIds: [...community.roomIds, room.id],
        );
        _communityHubByCode[community.code] = updatedCommunity;
        if (_joinedCommunity?.code == community.code) {
          _joinedCommunity = updatedCommunity;
        }
        _addCommunitySystemMessage(
            community.code,
            '$_myDisplayName created room "$name" 🎉');
      }
    }

    _isSoloMode = false;
    _currentRoom = room;
    _messages = _roomMessagesByRoomId[room.id] ?? [];
    _addSystemMessage('Room created by $_myDisplayName 🎉');
    _addSystemMessage(
        'Room Code: $roomCode — share to invite members');
    _notify();
    return room;
  }

  Future<StudyRoom> createSoloRoom({
    String? subject,
    int targetMinutes = 60,
  }) async {
    final room = await createRoom(
      name: '$_myDisplayName\'s Solo Room',
      subject: subject,
      targetMinutes: targetMinutes,
    );
    _isSoloMode = true;
    _notify();
    return room;
  }

  Future<bool> joinRoom(String roomCode) async {
    final normalized = roomCode.toUpperCase();
    final room = _roomHubByCode[normalized];
    if (room == null) return false;

    // Auto-join linked community if needed
    if (room.communityCode != null) {
      final community =
      _communityHubByCode[room.communityCode!];
      if (community == null) return false;
      final isMember =
      community.members.any((m) => m.id == myUserId);
      if (!isMember) {
        final joined = await joinCommunity(community.code);
        if (!joined) return false;
      }
    }

    final alreadyMember =
    room.members.any((m) => m.id == myUserId);
    final updatedMembers = [...room.members];
    if (!alreadyMember) {
      updatedMembers.add(RoomMember(
        id: myUserId,
        name: _myDisplayName,
        isOnline: true,
        joinedAt: DateTime.now(),
      ));
    }

    final updatedRoom =
    room.copyWith(members: updatedMembers, isActive: true);
    _roomHubByCode[normalized] = updatedRoom;
    _currentRoom = updatedRoom;
    _messages = _roomMessagesByRoomId[updatedRoom.id] ?? [];
    _addSystemMessage('$_myDisplayName joined the room 👋');
    _notify();
    return true;
  }

  void leaveRoom() {
    if (_currentRoom == null) return;
    stopStudyTimer();
    final room = _currentRoom!;

    final remaining =
    room.members.where((m) => m.id != myUserId).toList();
    final newHost = remaining.isNotEmpty ? remaining.first : null;

    final updatedRoom = room.copyWith(
      members: remaining,
      isActive: remaining.isNotEmpty,
      hostId: newHost?.id ?? room.hostId,
      hostName: newHost?.name ?? room.hostName,
    );

    _roomHubByCode[room.roomCode] = updatedRoom;
    _addSystemMessage('$_myDisplayName left the room');

    _currentRoom = null;
    _messages = [];
    _isSoloMode = false;
    _notify();
  }

  void sendMessage(String text) {
    if (_currentRoom == null || text.trim().isEmpty) return;

    final msg = RoomMessage(
      id: _uuid.v4(),
      roomId: _currentRoom!.id,
      senderId: myUserId,
      senderName: _myDisplayName,
      text: text.trim(),
      timestamp: DateTime.now(),
    );

    final list = _roomMessagesByRoomId[_currentRoom!.id] ?? [];
    list.add(msg);
    _roomMessagesByRoomId[_currentRoom!.id] = list;
    _messages = list;
    _notify();
  }

  void pokeMember(String memberId) {
    if (_currentRoom == null) return;
    final member = _currentRoom!.members
        .cast<RoomMember?>()
        .firstWhere((m) => m?.id == memberId, orElse: () => null);
    if (member == null || member.id == myUserId) return;
    _addSystemMessage(
        '$_myDisplayName poked ${member.name} to study now! 🔔');
    _notify();
  }

  // ── Study timer ──

  void startStudyTimer() {
    if (_isStudying || _currentRoom == null) return;

    if (FocusProvider.isAnySessionActive) {
      debugPrint(
          '[StudyRoom] Cannot start — '
              '${FocusProvider.globalActiveSession} session active.');
      return;
    }
    FocusProvider.claimSession('study_room');

    _isStudying = true;
    _myStudySeconds = 0;

    _studyTimer = Timer.periodic(
      const Duration(seconds: 1),
          (_) {
        _myStudySeconds++;
        _notify();
      },
    );

    _addSystemMessage(
      '$_myDisplayName started studying 📖',
      type: MessageType.studyStart,
    );
    _updateMyMemberStatus(isStudying: true);
    _notify();
  }

  void stopStudyTimer() {
    if (!_isStudying) return;

    _studyTimer?.cancel();
    _studyTimer = null;
    _isStudying = false;

    final minutes = _myStudySeconds ~/ 60;
    if (minutes > 0) {
      _addSystemMessage(
        '$_myDisplayName studied for $minutes minutes ✅',
        type: MessageType.studyEnd,
      );
      _logStudySession(minutes);
    }

    _updateMyMemberStatus(
      isStudying: false,
      studyMinutes: minutes,
    );

    FocusProvider.releaseSession('study_room');
    _myStudySeconds = 0;
    _notify();
  }

  // ── Private helpers ──

  void _updateMyMemberStatus({
    bool? isStudying,
    int? studyMinutes,
  }) {
    if (_currentRoom == null) return;
    final room = _currentRoom!;
    final updatedMembers = room.members.map((m) {
      if (m.id != myUserId) return m;
      return m.copyWith(
        isStudying: isStudying ?? m.isStudying,
        studyMinutes: studyMinutes ?? m.studyMinutes,
        isOnline: true,
      );
    }).toList();

    final updatedRoom = room.copyWith(members: updatedMembers);
    _roomHubByCode[room.roomCode] = updatedRoom;
    _currentRoom = updatedRoom;
  }

  void _addSystemMessage(
      String text, {
        MessageType type = MessageType.system,
      }) {
    final roomId = _currentRoom?.id;
    if (roomId == null) return;

    final list = _roomMessagesByRoomId[roomId] ?? [];
    list.add(RoomMessage(
      id: _uuid.v4(),
      roomId: roomId,
      senderId: 'system',
      senderName: 'System',
      text: text,
      timestamp: DateTime.now(),
      type: type,
    ));
    _roomMessagesByRoomId[roomId] = list;
    _messages = list;
  }

  void _addCommunitySystemMessage(
      String communityCode, String text) {
    final list = _communityMessagesByCode[communityCode] ?? [];
    list.add(RoomMessage(
      id: _uuid.v4(),
      roomId: communityCode,
      senderId: 'system',
      senderName: 'System',
      text: text,
      timestamp: DateTime.now(),
      type: MessageType.system,
    ));
    _communityMessagesByCode[communityCode] = list;
    if (_joinedCommunity?.code == communityCode) {
      _communityMessages = list;
    }
  }

  void _logStudySession(int minutes) {
    try {
      HistoryService.instance.logEvent(
        'study_room',
        'Study room session',
        '${minutes}min in ${_currentRoom?.name ?? "room"}',
        duration: minutes,
        xp: 5 + minutes ~/ 5,
        gold: 1 + minutes ~/ 15,
      );
    } catch (e) {
      debugPrint('[StudyRoom] Failed to log session: $e');
    }
  }

  String _generateUniqueRoomCode() {
    var code = StudyRoom.generateRoomCode();
    while (_roomHubByCode.containsKey(code)) {
      code = StudyRoom.generateRoomCode();
    }
    return code;
  }

  String _generateUniqueCommunityCode() {
    var code = StudyCommunity.generateCommunityCode();
    while (_communityHubByCode.containsKey(code)) {
      code = StudyCommunity.generateCommunityCode();
    }
    return code;
  }

  /// Safe notifyListeners — guards against post-dispose calls.
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _studyTimer?.cancel();
    _studyTimer = null;
    super.dispose();
  }
}