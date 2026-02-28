class UserProfile {
  final int totalPoints;
  final int health; // 0-50
  final int maxHealth;
  final int experience;
  final int experienceToNext;
  final int level;
  final int gold;
  final int gems;
  final int currentStreak;
  final int longestStreak;
  final String avatarType; // warrior, mage, healer, rogue
  final int totalStudyMinutes;
  final int totalFocusMinutes;
  final int sessionsCompleted;
  final int phoneUnlocks;
  final String username;
  final String? profileImagePath;

  UserProfile({
    this.totalPoints = 0,
    this.health = 50,
    this.maxHealth = 50,
    this.experience = 0,
    this.experienceToNext = 25,
    this.level = 1,
    this.gold = 0,
    this.gems = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.avatarType = 'warrior',
    this.totalStudyMinutes = 0,
    this.totalFocusMinutes = 0,
    this.sessionsCompleted = 0,
    this.phoneUnlocks = 0,
    this.username = 'Friend',
    this.profileImagePath,
  });

  UserProfile copyWith({
    int? totalPoints,
    int? health,
    int? maxHealth,
    int? experience,
    int? experienceToNext,
    int? level,
    int? gold,
    int? gems,
    int? currentStreak,
    int? longestStreak,
    String? avatarType,
    int? totalStudyMinutes,
    int? totalFocusMinutes,
    int? sessionsCompleted,
    int? phoneUnlocks,
    String? username,
    String? profileImagePath,
  }) {
    return UserProfile(
      totalPoints: totalPoints ?? this.totalPoints,
      health: health ?? this.health,
      maxHealth: maxHealth ?? this.maxHealth,
      experience: experience ?? this.experience,
      experienceToNext: experienceToNext ?? this.experienceToNext,
      level: level ?? this.level,
      gold: gold ?? this.gold,
      gems: gems ?? this.gems,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      avatarType: avatarType ?? this.avatarType,
      totalStudyMinutes: totalStudyMinutes ?? this.totalStudyMinutes,
      totalFocusMinutes: totalFocusMinutes ?? this.totalFocusMinutes,
      sessionsCompleted: sessionsCompleted ?? this.sessionsCompleted,
      phoneUnlocks: phoneUnlocks ?? this.phoneUnlocks,
      username: username ?? this.username,
      profileImagePath: profileImagePath ?? this.profileImagePath,
    );
  }

  Map<String, dynamic> toMap() => {
        'total_points': totalPoints,
        'health': health,
        'max_health': maxHealth,
        'experience': experience,
        'experience_to_next': experienceToNext,
        'level': level,
        'gold': gold,
        'gems': gems,
        'current_streak': currentStreak,
        'longest_streak': longestStreak,
        'avatar_type': avatarType,
        'total_study_minutes': totalStudyMinutes,
        'total_focus_minutes': totalFocusMinutes,
        'sessions_completed': sessionsCompleted,
        'phone_unlocks': phoneUnlocks,
        'username': username,
        'profile_image_path': profileImagePath,
      };

  factory UserProfile.fromMap(Map<String, dynamic> m) => UserProfile(
        totalPoints: m['total_points'] as int? ?? 0,
        health: m['health'] as int? ?? 50,
        maxHealth: m['max_health'] as int? ?? 50,
        experience: m['experience'] as int? ?? 0,
        experienceToNext: m['experience_to_next'] as int? ?? 25,
        level: m['level'] as int? ?? 1,
        gold: m['gold'] as int? ?? 0,
        gems: m['gems'] as int? ?? 0,
        currentStreak: m['current_streak'] as int? ?? 0,
        longestStreak: m['longest_streak'] as int? ?? 0,
        avatarType: m['avatar_type'] as String? ?? 'warrior',
        totalStudyMinutes: m['total_study_minutes'] as int? ?? 0,
        totalFocusMinutes: m['total_focus_minutes'] as int? ?? 0,
        sessionsCompleted: m['sessions_completed'] as int? ?? 0,
        phoneUnlocks: m['phone_unlocks'] as int? ?? 0,
        username: m['username'] as String? ?? 'Friend',
        profileImagePath: m['profile_image_path'] as String?,
      );

  // XP needed for each level = level * 25
  static int xpForLevel(int level) => level * 25;

  String get levelTitle {
    if (level < 5) return 'Novice';
    if (level < 10) return 'Candidate Master';
    if (level < 15) return 'FIDE Master';
    if (level < 20) return 'International Master';
    if (level < 30) return 'Grandmaster';
    if (level < 50) return 'Super Grandmaster';
    return 'World Champion';
  }

  String get levelTitleBengali {
    if (level < 5) return 'Novice';
    if (level < 10) return 'Candidate Master';
    if (level < 15) return 'FIDE Master';
    if (level < 20) return 'International Master';
    if (level < 30) return 'Grandmaster';
    if (level < 50) return 'Super Grandmaster';
    return 'World Champion';
  }
}
