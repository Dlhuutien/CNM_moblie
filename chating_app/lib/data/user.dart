extension ObjectUserExtension on ObjectUser {
  ObjectUser copyWithField(String field, String value) {
    switch (field) {
      case 'name': return copyWith(hoTen: value);
      case 'phone': return copyWith(soDienThoai: value);
      case 'gender': return copyWith(gender: value);
      case 'birthday': return copyWith(birthday: value);
      case 'email': return copyWith(email: value);
      case 'work': return copyWith(work: value);
      case 'location': return copyWith(location: value);
      case 'image': return copyWith(image: value);
      case 'password': return copyWith(password: value);
      default: return this;
    }
  }

  ObjectUser copyWith({
    String? userID,
    String? soDienThoai,
    String? matKhau,
    String? hoTen,
    String? gender,
    String? birthday,
    String? email,
    String? work,
    String? image,
    String? location,
    String? password,
  }) {
    return ObjectUser(
      userID: userID ?? this.userID,
      soDienThoai: soDienThoai ?? this.soDienThoai,
      hoTen: hoTen ?? this.hoTen,
      gender: gender ?? this.gender,
      birthday: birthday ?? this.birthday,
      email: email ?? this.email,
      work: work ?? this.work,
      image: image ?? this.image,
      location: location ?? this.location,
      password: password ?? this.password,
    );
  }
}

class ObjectUser {
  final String userID;
  final String soDienThoai;
  final String hoTen;
  final String gender;
  final String birthday;
  final String email;
  final String work;
  final String image;
  final String location;
  final String password;

  ObjectUser({
    required this.userID,
    required this.soDienThoai,
    required this.hoTen,
    required this.gender,
    required this.birthday,
    required this.email,
    required this.work,
    required this.image,
    required this.location,
    required this.password,
  });

  factory ObjectUser.empty() {
    return ObjectUser(
      userID: '',
      soDienThoai: '',
      hoTen: '',
      gender: '',
      birthday: '',
      email: '',
      work: '',
      image: '',
      location: '',
      password: '',
    );
  }
}
