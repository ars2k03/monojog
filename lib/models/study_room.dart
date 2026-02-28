import 'dart:math';

/// A study room where friends can study together
class StudyRoom {
  final String id;
  final String name;
  final String hostId;
  final String hostName;
  final String roomCode; // 6-char join code
  final List<RoomMember> members;
  final int maxMembers;
  final bool isActive;
  final DateTime createdAt;
  final String? subject;
  final int targetMinutes;
  final String? communityCode;

  StudyRoom({
    required this.id,
    required this.name,
    required this.hostId,
    required this.hostName,
    required this.roomCode,
    this.members = const [],
    this.maxMembers = 8,
    this.isActive = true,
    required this.createdAt,
    this.subject,
    this.targetMinutes = 60,
    this.communityCode,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'hostId': hostId,
        'hostName': hostName,
        'roomCode': roomCode,
        'maxMembers': maxMembers,
        'isActive': isActive,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'subject': subject,
        'targetMinutes': targetMinutes,
        'communityCode': communityCode,
        'members': members.map((m) => m.toMap()).toList(),
      };

  factory StudyRoom.fromMap(Map<String, dynamic> map) {
    final membersList = map['members'];
    List<RoomMember> parsedMembers = [];
    if (membersList is List) {
      parsedMembers = membersList
          .map((m) => RoomMember.fromMap(Map<String, dynamic>.from(m)))
          .toList();
    }

    return StudyRoom(
      id: map['id'] as String,
      name: map['name'] as String,
      hostId: map['hostId'] as String,
      hostName: map['hostName'] as String,
      roomCode: map['roomCode'] as String,
      members: parsedMembers,
      maxMembers: map['maxMembers'] as int? ?? 8,
      isActive: map['isActive'] as bool? ?? true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      subject: map['subject'] as String?,
      targetMinutes: map['targetMinutes'] as int? ?? 60,
      communityCode: map['communityCode'] as String?,
    );
  }

  StudyRoom copyWith({
    String? id,
    String? name,
    String? hostId,
    String? hostName,
    String? roomCode,
    List<RoomMember>? members,
    int? maxMembers,
    bool? isActive,
    DateTime? createdAt,
    String? subject,
    int? targetMinutes,
    String? communityCode,
  }) {
    return StudyRoom(
      id: id ?? this.id,
      name: name ?? this.name,
      hostId: hostId ?? this.hostId,
      hostName: hostName ?? this.hostName,
      roomCode: roomCode ?? this.roomCode,
      members: members ?? this.members,
      maxMembers: maxMembers ?? this.maxMembers,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      subject: subject ?? this.subject,
      targetMinutes: targetMinutes ?? this.targetMinutes,
      communityCode: communityCode ?? this.communityCode,
    );
  }

  /// Generate a random 6-character room code
  static String generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }
}

/// Persistent study community that can host many rooms.
class StudyCommunity {
  final String id;
  final String name;
  final String code; // 6-char join code
  final String ownerId;
  final String ownerName;
  final DateTime createdAt;
  final List<RoomMember> members;
  final List<String> roomIds;

  StudyCommunity({
    required this.id,
    required this.name,
    required this.code,
    required this.ownerId,
    required this.ownerName,
    required this.createdAt,
    this.members = const [],
    this.roomIds = const [],
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'code': code,
        'ownerId': ownerId,
        'ownerName': ownerName,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'members': members.map((m) => m.toMap()).toList(),
        'roomIds': roomIds,
      };

  factory StudyCommunity.fromMap(Map<String, dynamic> map) {
    final membersList = map['members'];
    List<RoomMember> parsedMembers = [];
    if (membersList is List) {
      parsedMembers = membersList
          .map((m) => RoomMember.fromMap(Map<String, dynamic>.from(m)))
          .toList();
    }

    final roomList = map['roomIds'];
    List<String> parsedRoomIds = [];
    if (roomList is List) {
      parsedRoomIds = roomList.map((e) => e.toString()).toList();
    }

    return StudyCommunity(
      id: map['id'] as String,
      name: map['name'] as String,
      code: map['code'] as String,
      ownerId: map['ownerId'] as String,
      ownerName: map['ownerName'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      members: parsedMembers,
      roomIds: parsedRoomIds,
    );
  }

  StudyCommunity copyWith({
    String? id,
    String? name,
    String? code,
    String? ownerId,
    String? ownerName,
    DateTime? createdAt,
    List<RoomMember>? members,
    List<String>? roomIds,
  }) {
    return StudyCommunity(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      createdAt: createdAt ?? this.createdAt,
      members: members ?? this.members,
      roomIds: roomIds ?? this.roomIds,
    );
  }

  static String generateCommunityCode() {
    return StudyRoom.generateRoomCode();
  }
}

/// A member in a study room
class RoomMember {
  final String id;
  final String name;
  final String? avatarType;
  final bool isOnline;
  final bool isStudying;
  final int studyMinutes; // current session minutes
  final DateTime joinedAt;
  final int totalPoints; // total XP/points accumulated
  final int level; // current level
  final int gold; // gold earned
  final int currentStreak; // current daily streak
  final String? title; // rank title (e.g. "Novice", "FIDE Master")

  RoomMember({
    required this.id,
    required this.name,
    this.avatarType,
    this.isOnline = true,
    this.isStudying = false,
    this.studyMinutes = 0,
    required this.joinedAt,
    this.totalPoints = 0,
    this.level = 1,
    this.gold = 0,
    this.currentStreak = 0,
    this.title,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'avatarType': avatarType,
        'isOnline': isOnline,
        'isStudying': isStudying,
        'studyMinutes': studyMinutes,
        'joinedAt': joinedAt.millisecondsSinceEpoch,
        'totalPoints': totalPoints,
        'level': level,
        'gold': gold,
        'currentStreak': currentStreak,
        'title': title,
      };

  factory RoomMember.fromMap(Map<String, dynamic> map) => RoomMember(
        id: map['id'] as String,
        name: map['name'] as String,
        avatarType: map['avatarType'] as String?,
        isOnline: map['isOnline'] as bool? ?? true,
        isStudying: map['isStudying'] as bool? ?? false,
        studyMinutes: map['studyMinutes'] as int? ?? 0,
        joinedAt: DateTime.fromMillisecondsSinceEpoch(map['joinedAt'] as int),
        totalPoints: map['totalPoints'] as int? ?? 0,
        level: map['level'] as int? ?? 1,
        gold: map['gold'] as int? ?? 0,
        currentStreak: map['currentStreak'] as int? ?? 0,
        title: map['title'] as String?,
      );

  RoomMember copyWith({
    String? id,
    String? name,
    String? avatarType,
    bool? isOnline,
    bool? isStudying,
    int? studyMinutes,
    DateTime? joinedAt,
    int? totalPoints,
    int? level,
    int? gold,
    int? currentStreak,
    String? title,
  }) {
    return RoomMember(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarType: avatarType ?? this.avatarType,
      isOnline: isOnline ?? this.isOnline,
      isStudying: isStudying ?? this.isStudying,
      studyMinutes: studyMinutes ?? this.studyMinutes,
      joinedAt: joinedAt ?? this.joinedAt,
      totalPoints: totalPoints ?? this.totalPoints,
      level: level ?? this.level,
      gold: gold ?? this.gold,
      currentStreak: currentStreak ?? this.currentStreak,
      title: title ?? this.title,
    );
  }
}

/// A chat message in a study room
class RoomMessage {
  final String id;
  final String roomId;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final MessageType type;

  RoomMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    this.type = MessageType.text,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'roomId': roomId,
        'senderId': senderId,
        'senderName': senderName,
        'text': text,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'type': type.name,
      };

  factory RoomMessage.fromMap(Map<String, dynamic> map) => RoomMessage(
        id: map['id'] as String,
        roomId: map['roomId'] as String,
        senderId: map['senderId'] as String,
        senderName: map['senderName'] as String,
        text: map['text'] as String,
        timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
        type: MessageType.values.firstWhere(
          (t) => t.name == (map['type'] as String? ?? 'text'),
          orElse: () => MessageType.text,
        ),
      );
}

enum MessageType { text, system, studyStart, studyEnd, achievement }

class CommunityNotice {
  final String id;
  final String communityCode;
  final String authorId;
  final String authorName;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool pinned;

  CommunityNotice({
    required this.id,
    required this.communityCode,
    required this.authorId,
    required this.authorName,
    required this.title,
    required this.body,
    required this.createdAt,
    this.pinned = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'communityCode': communityCode,
      'authorId': authorId,
      'authorName': authorName,
      'title': title,
      'body': body,
      'createdAt': createdAt.toIso8601String(),
      'pinned': pinned,
    };
  }

  factory CommunityNotice.fromMap(Map<String, dynamic> map) {
    return CommunityNotice(
      id: map['id'] ?? '',
      communityCode: map['communityCode'] ?? '',
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      pinned: map['pinned'] ?? false,
    );
  }

  CommunityNotice copyWith({
    String? id,
    String? communityCode,
    String? authorId,
    String? authorName,
    String? title,
    String? body,
    DateTime? createdAt,
    bool? pinned,
  }) {
    return CommunityNotice(
      id: id ?? this.id,
      communityCode: communityCode ?? this.communityCode,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      pinned: pinned ?? this.pinned,
    );
  }
}

class CommunityRoom {
  final String id;
  final String name;
  final String hostName;
  final String roomCode;
  final int memberCount;
  final int maxMembers;
  final bool isActive;
  final String? subject;
  final DateTime createdAt;

  CommunityRoom({
    required this.id,
    required this.name,
    required this.hostName,
    required this.roomCode,
    this.memberCount = 0,
    this.maxMembers = 10,
    this.isActive = true,
    this.subject,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'hostName': hostName,
      'roomCode': roomCode,
      'memberCount': memberCount,
      'maxMembers': maxMembers,
      'isActive': isActive,
      'subject': subject,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CommunityRoom.fromMap(Map<String, dynamic> map) {
    return CommunityRoom(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      hostName: map['hostName'] ?? '',
      roomCode: map['roomCode'] ?? '',
      memberCount: map['memberCount'] ?? 0,
      maxMembers: map['maxMembers'] ?? 10,
      isActive: map['isActive'] ?? true,
      subject: map['subject'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
