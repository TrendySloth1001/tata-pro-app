class User {
  final String id;
  final String name;
  final String email;
  final String unitNumber;
  final String buildingId;
  final UserRole role;
  final double monthlyAllocation;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.unitNumber,
    required this.buildingId,
    required this.role,
    this.monthlyAllocation = 150.0,
  });
}

enum UserRole { resident, buildingAdmin, gridAdmin }
