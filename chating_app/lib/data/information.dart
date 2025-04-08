import 'user.dart';

class LoginData {
  static List<ObjectUser> users = [
    ObjectUser(
      soDienThoai: '0386474751',
      matKhau: 'huutien123',
      hoTen: 'Đặng Lê Hữu Tiến',
      gender: 'Male',
      birthday: '29/08/2003',
      email: 'tien@gmail.com',
      work: 'Mobile Developer',
    ),
    ObjectUser(
      soDienThoai: '0911223344',
      matKhau: 'abc123',
      hoTen: 'Nguyễn Văn A',
      gender: 'Male',
      birthday: '01/01/2000',
      email: 'vana@gmail.com',
      work: 'Backend Developer',
    ),
    ObjectUser(
      soDienThoai: '0987654321',
      matKhau: 'hello123',
      hoTen: 'Trần Thị B',
      gender: 'Female',
      birthday: '20/05/1998',
      email: 'thiB@gmail.com',
      work: 'UI/UX Designer',
    ),
  ];

  // Hàm kiểm tra đăng nhập
  static ObjectUser? login(String phone, String pass) {
    try {
      return users.firstWhere(
            (user) => user.soDienThoai == phone && user.matKhau == pass,
      );
    } catch (e) {
      return null;
    }
  }
}
