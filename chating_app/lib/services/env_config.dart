import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static late String baseUrl;

  static Future<void> init() async {
    await dotenv.load(fileName: "assets/.env");
    baseUrl = dotenv.env['BASE_URL'] ?? '';
    print("BASE_URL hiện tại: $baseUrl");
    if (baseUrl.isEmpty) {
      throw Exception("BASE_URL not found in .env file");
    }
  }
}
