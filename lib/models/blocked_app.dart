class BlockedApp {
  final String id;
  final String packageName;
  final String appName;
  final bool isBlocked;

  BlockedApp({
    required this.id,
    required this.packageName,
    required this.appName,
    this.isBlocked = true,
  });

  factory BlockedApp.fromMap(Map<String, dynamic> map) {
    return BlockedApp(
      id: map['id'] as String,
      packageName: map['package_name'] as String,
      appName: map['app_name'] as String,
      isBlocked: (map['is_blocked'] as int? ?? 1) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'package_name': packageName,
      'app_name': appName,
      'is_blocked': isBlocked ? 1 : 0,
    };
  }

  BlockedApp copyWith({
    String? id,
    String? packageName,
    String? appName,
    bool? isBlocked,
  }) {
    return BlockedApp(
      id: id ?? this.id,
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      isBlocked: isBlocked ?? this.isBlocked,
    );
  }
}

class InstalledApp {
  final String packageName;
  final String appName;
  final bool isSystemApp;

  InstalledApp({
    required this.packageName,
    required this.appName,
    this.isSystemApp = false,
  });

  factory InstalledApp.fromMap(Map<String, dynamic> map) {
    return InstalledApp(
      packageName: map['packageName'] as String,
      appName: map['appName'] as String,
      isSystemApp: map['isSystemApp'] as bool? ?? false,
    );
  }
}
