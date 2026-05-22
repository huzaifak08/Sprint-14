class UserBusinessPermissions {
  final String role; // 'owner', 'admin', 'salesman', or 'none'

  UserBusinessPermissions({required this.role});

  // Simple, expressive booleans for your UI switches
  bool get isOwner => role == 'owner';
  bool get isAdmin => role == 'admin';
  bool get isSalesman => role == 'salesman';

  // High-level privilege check
  bool get hasAdminPrivileges => role == 'owner' || role == 'admin';
}
