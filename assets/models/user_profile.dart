class UserProfile {
  final String uid;
  final String? email;
  final String? name;
  final String? phone;
  final String? profilePicture;
  final String? gender;
  final int? age;
  final String? role;
  final DateTime? createdAt;

  UserProfile({
    required this.uid,
    this.email,
    this.name,
    this.phone,
    this.profilePicture,
    this.gender,
    this.age,
    this.role,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'phone': phone,
      'profilePicture': profilePicture,
      'gender': gender,
      'age': age,
      'role': role,
      'createdAt': createdAt?.millisecondsSinceEpoch,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map, String uid) {
    return UserProfile(
      uid: uid,
      email: map['email'],
      name: map['name'],
      phone: map['phone'],
      profilePicture: map['profilePicture'],
      gender: map['gender'],
      age: map['age'],
      role: map['role'],
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : null,
    );
  }
}