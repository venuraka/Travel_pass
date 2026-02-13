class DriverModel {
  final String uid;
  final String name;
  final String vehiclePlate;
  final String phone;
  final String email;

  DriverModel({
    required this.uid,
    required this.name,
    required this.vehiclePlate,
    required this.phone,
    required this.email,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'vehiclePlate': vehiclePlate,
      'phone': phone,
      'email': email,
      'role': 'driver', // Helpful for role-based login later
    };
  }
}
