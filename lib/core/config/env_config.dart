import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String get supabaseUrl {
    if (!dotenv.isInitialized) {
      return '';
    }
    return dotenv.env['SUPABASE_URL'] ?? '';
  }

  static String get supabaseAnonKey {
    if (!dotenv.isInitialized) {
      return '';
    }
    return dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  }
}
