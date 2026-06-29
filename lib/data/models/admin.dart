class Admin {
  final String id;
  final String name;
  final String phone;
  final String role; // super_admin, admin, viewer
  final DateTime? createdAt;

  Admin({
    required this.id,
    required this.name,
    required this.phone,
    this.role = 'admin',
    this.createdAt,
  });

  factory Admin.fromJson(Map<String, dynamic> json) {
    return Admin(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: json['role'] as String? ?? 'admin',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  bool get isSuperAdmin => role == 'super_admin';
  bool get isViewer => role == 'viewer';

  String get roleLabel {
    switch (role) {
      case 'super_admin':
        return 'مسؤول أعلى';
      case 'admin':
        return 'مسؤول';
      case 'viewer':
        return 'مشاهد';
      default:
        return role;
    }
  }
}
