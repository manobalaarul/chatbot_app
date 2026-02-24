import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_config.dart';
import '../models/models.dart';

class SessionService {
  static SessionService? _instance;
  static SessionService get instance => _instance ??= SessionService._();
  SessionService._();

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  String?    get token     => _prefs.getString(AppConfig.kToken);
  AdminInfo? get adminInfo {
    final raw = _prefs.getString(AppConfig.kAdmin);
    if (raw == null) return null;
    try { return AdminInfo.fromJson(jsonDecode(raw)); } catch (_) { return null; }
  }
  String?    get appKey    => _prefs.getString(AppConfig.kAppKey);
  bool       get hasSession => token != null && adminInfo != null;

  Future<void> save(String token, AdminInfo admin, String appKey) async {
    await _prefs.setString(AppConfig.kToken,  token);
    await _prefs.setString(AppConfig.kAdmin,  jsonEncode(admin.toJson()));
    await _prefs.setString(AppConfig.kAppKey, appKey);
  }

  Future<void> clear() async {
    await _prefs.remove(AppConfig.kToken);
    await _prefs.remove(AppConfig.kAdmin);
    await _prefs.remove(AppConfig.kAppKey);
  }
}