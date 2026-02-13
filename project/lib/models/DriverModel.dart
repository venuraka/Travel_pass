class DriverModel {
  final String uid;
  final String name;
  final String vehiclePlate;
  final String phone;
  final String email;
  final String? vehicleModel;
  final int? seatCount;
  final String? vehicleType;

  DriverModel({
    required this.uid,
    required this.name,
    required this.vehiclePlate,
    required this.phone,
    required this.email,
    this.vehicleModel,
    this.seatCount,
    this.vehicleType,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'vehiclePlate': vehiclePlate,
      'phone': phone,
      'email': email,
      'vehicleModel': vehicleModel,
      'seatCount': seatCount,
      'vehicleType': vehicleType,
      'role': 'driver', // Helpful for role-based login later
    };
  }
}
