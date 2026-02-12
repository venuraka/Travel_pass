class MyUserModel {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;

  MyUserModel({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
  });

  // Factory constructor to create our model from a Firebase User object
  factory MyUserModel.fromFirebaseUser(dynamic user) {
    return MyUserModel(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
    );
  }
}