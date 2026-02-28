class Badge {
  final String id;
  final String title;
  final String description;
  final String icon; // emoji
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final String category; // focus, streak, study, special

  Badge({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.isUnlocked = false,
    this.unlockedAt,
    this.category = 'study',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'icon': icon,
        'is_unlocked': isUnlocked ? 1 : 0,
        'unlocked_at': unlockedAt?.millisecondsSinceEpoch,
        'category': category,
      };

  factory Badge.fromMap(Map<String, dynamic> m) => Badge(
        id: m['id'] as String,
        title: m['title'] as String,
        description: m['description'] as String,
        icon: m['icon'] as String,
        isUnlocked: (m['is_unlocked'] as int? ?? 0) == 1,
        unlockedAt: m['unlocked_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(m['unlocked_at'] as int)
            : null,
        category: m['category'] as String? ?? 'study',
      );

  Badge copyWith({bool? isUnlocked, DateTime? unlockedAt}) => Badge(
        id: id,
        title: title,
        description: description,
        icon: icon,
        isUnlocked: isUnlocked ?? this.isUnlocked,
        unlockedAt: unlockedAt ?? this.unlockedAt,
        category: category,
      );

  /// All predefined badges
  static List<Badge> allBadges = [
    Badge(
      id: 'first_focus',
      title: 'First Focus',
      description: 'Complete your first focus session',
      icon: '🎯',
      category: 'focus',
    ),
    Badge(
      id: 'streak_3',
      title: '3-Day Streak',
      description: 'Study 3 consecutive days',
      icon: '🔥',
      category: 'streak',
    ),
    Badge(
      id: 'streak_7',
      title: '7-Day Streak',
      description: 'Study 7 consecutive days',
      icon: '🔥',
      category: 'streak',
    ),
    Badge(
      id: 'streak_14',
      title: '14-Day Streak',
      description: 'Study 14 consecutive days',
      icon: '💪',
      category: 'streak',
    ),
    Badge(
      id: 'streak_30',
      title: '30-Day Streak',
      description: 'Study 30 consecutive days',
      icon: '👑',
      category: 'streak',
    ),
    Badge(
      id: 'deep_focus',
      title: 'Deep Focus',
      description: 'Complete a session without unlocking your phone',
      icon: '🧘',
      category: 'focus',
    ),
    Badge(
      id: 'early_bird',
      title: 'Early Bird',
      description: 'Start studying before 6 AM',
      icon: '🌅',
      category: 'special',
    ),
    Badge(
      id: 'night_owl',
      title: 'Night Owl',
      description: 'Study after midnight',
      icon: '🦉',
      category: 'special',
    ),
    Badge(
      id: 'hour_warrior',
      title: 'Hour Warrior',
      description: 'Study for 1 hour in a single session',
      icon: '⚔️',
      category: 'study',
    ),
    Badge(
      id: 'level_10',
      title: 'Level 10',
      description: 'Reach level 10',
      icon: '⭐',
      category: 'special',
    ),
    Badge(
      id: 'sessions_50',
      title: '50 Sessions',
      description: 'Complete 50 study sessions',
      icon: '🏆',
      category: 'study',
    ),
    Badge(
      id: 'subject_master',
      title: 'Subject Master',
      description: 'Study a single subject for 10 hours',
      icon: '📚',
      category: 'study',
    ),
  ];
}

class RewardItem {
  final String id;
  final String name;
  final String description;
  final String icon; // emoji
  final int cost; // gold cost
  final String type; // theme, powerup, custom
  final bool isPurchased;

  const RewardItem({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.cost,
    this.type = 'custom',
    this.isPurchased = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'icon': icon,
        'cost': cost,
        'type': type,
        'is_purchased': isPurchased ? 1 : 0,
      };

  factory RewardItem.fromMap(Map<String, dynamic> m) => RewardItem(
        id: m['id'] as String,
        name: m['name'] as String,
        description: m['description'] as String,
        icon: m['icon'] as String,
        cost: m['cost'] as int? ?? 0,
        type: m['type'] as String? ?? 'custom',
        isPurchased: (m['is_purchased'] as int? ?? 0) == 1,
      );

  static List<RewardItem> defaultRewards = [
    const RewardItem(
      id: 'sapling_seed',
      name: 'Sapling Seed',
      description: 'Plant a new sapling in your focus forest',
      icon: '🌱',
      cost: 18,
      type: 'forest',
    ),
    const RewardItem(
      id: 'rain_boost',
      name: 'Rain Boost',
      description: 'Water all trees and boost growth for one day',
      icon: '🌧️',
      cost: 28,
      type: 'forest',
    ),
    const RewardItem(
      id: 'pine_tree',
      name: 'Pine Tree',
      description: 'Unlock a tall evergreen for your garden skyline',
      icon: '🌲',
      cost: 36,
      type: 'forest',
    ),
    const RewardItem(
      id: 'flower_patch',
      name: 'Flower Patch',
      description: 'Add a colorful flower zone around your trees',
      icon: '🌸',
      cost: 42,
      type: 'forest',
    ),
    const RewardItem(
      id: 'forest_path',
      name: 'Forest Path',
      description: 'Build a glowing walkway through your focus forest',
      icon: '🪵',
      cost: 55,
      type: 'forest',
    ),
    const RewardItem(
      id: 'ancient_oak',
      name: 'Ancient Oak',
      description: 'A legendary tree awarded for consistent deep work',
      icon: '🌳',
      cost: 90,
      type: 'forest',
    ),
  ];
}

class BrainDump {
  final String id;
  final String text;
  final String? sessionId;
  final String type; // pre_focus, post_focus, general
  final DateTime createdAt;

  BrainDump({
    required this.id,
    required this.text,
    this.sessionId,
    this.type = 'general',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'text': text,
        'session_id': sessionId,
        'type': type,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory BrainDump.fromMap(Map<String, dynamic> m) => BrainDump(
        id: m['id'] as String,
        text: m['text'] as String,
        sessionId: m['session_id'] as String?,
        type: m['type'] as String? ?? 'general',
        createdAt: DateTime.fromMillisecondsSinceEpoch(
            m['created_at'] as int? ?? DateTime.now().millisecondsSinceEpoch),
      );
}
