import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static final ApiService instance = ApiService._internal();
  factory ApiService() => instance;

  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const _tokenKey = 'silah_auth_token';
  static const _refreshTokenKey = 'silah_refresh_token';
  static const _userKey = 'silah_current_user';

  String? authToken;
  Map<String, dynamic>? currentUser;

  bool get isMasjidAdmin {
    final adminRoles = currentUser?['adminRoles'] as List<dynamic>?;
    return adminRoles != null && adminRoles.isNotEmpty;
  }

  bool get isSuperAdmin {
    return currentUser?['isSuperAdmin'] == true;
  }

  ApiService._internal() {
    // Vercel Live Production Backend
    const baseUrl = 'https://backend-finytive.vercel.app/v1';

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (authToken != null) {
            options.headers['Authorization'] = 'Bearer $authToken';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          return handler.next(error);
        },
      ),
    );
  }

  Future<Map<String, dynamic>> checkUser(String phone) async {
    final res = await _dio.post('/auth/check-user', data: {'phone': phone});
    return res.data;
  }

  Future<void> _saveSession(Map<String, dynamic> data) async {
    authToken = data['tokens']?['accessToken'];
    final refreshToken = data['tokens']?['refreshToken'];
    currentUser = data['user'];

    if (authToken != null) {
      await _storage.write(key: _tokenKey, value: authToken);
    }
    if (refreshToken != null) {
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    }
    if (currentUser != null) {
      await _storage.write(key: _userKey, value: jsonEncode(currentUser));
    }
  }

  Future<bool> initSession() async {
    try {
      final savedToken = await _storage.read(key: _tokenKey);
      final savedUserJson = await _storage.read(key: _userKey);

      if (savedToken != null && savedToken.isNotEmpty) {
        authToken = savedToken;
        if (savedUserJson != null && savedUserJson.isNotEmpty) {
          currentUser = jsonDecode(savedUserJson) as Map<String, dynamic>;
        }
        // Try refreshing profile in background
        try {
          final profile = await getProfile();
          if (profile != null) {
            currentUser = {
              ...?currentUser,
              ...profile,
              'isOnboarded': profile['isOnboarded'] ?? currentUser?['isOnboarded'] ?? true,
            };
            await _storage.write(key: _userKey, value: jsonEncode(currentUser));
          }
        } catch (_) {}
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<void> clearSession() async {
    authToken = null;
    currentUser = null;
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userKey);
  }

  Future<Map<String, dynamic>> loginDirect(String phone) async {
    final res = await _dio.post('/auth/login-direct', data: {'phone': phone});
    if (res.data['success'] == true && res.data['data'] != null) {
      await _saveSession(res.data['data']);
    }
    return res.data;
  }

  Future<Map<String, dynamic>> register({
    required String phone,
    required String name,
    required int age,
    String? address,
  }) async {
    final res = await _dio.post('/auth/register', data: {
      'phone': phone,
      'name': name,
      'age': age,
      if (address != null && address.isNotEmpty) 'address': address,
    });
    if (res.data['success'] == true && res.data['data'] != null) {
      await _saveSession(res.data['data']);
    }
    return res.data;
  }

  Future<void> updateDeviceToken(String fcmToken, {String platform = 'ANDROID'}) async {
    try {
      await _dio.post('/auth/device-token', data: {
        'fcmToken': fcmToken,
        'platform': platform,
      });
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> joinMasjid(String masjidId, {bool isPrimary = true}) async {
    try {
      final res = await _dio.post('/masjids/$masjidId/join', data: {'isPrimary': isPrimary});
      if (res.data['success'] == true) {
        return res.data['data'] as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> getMasjidByQr(String qrToken) async {
    try {
      final res = await _dio.get('/masjids/qr/$qrToken');
      if (res.data['success'] == true) {
        return res.data['data'] as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>> sendOtp(String phone) async {
    final res = await _dio.post('/auth/otp/send', data: {'phone': phone});
    return res.data;
  }

  Future<Map<String, dynamic>> verifyOtp(String phone, String otp) async {
    final res = await _dio.post('/auth/otp/verify', data: {'phone': phone, 'otp': otp});
    if (res.data['success'] == true && res.data['data'] != null) {
      await _saveSession(res.data['data']);
    }
    return res.data;
  }

  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final res = await _dio.get('/auth/me');
      if (res.data['success'] == true && res.data['data'] != null) {
        currentUser = res.data['data'] as Map<String, dynamic>;
        return currentUser;
      }
    } catch (_) {}
    return null;
  }

  Future<List<dynamic>> getMasjids() async {
    try {
      final res = await _dio.get('/masjids');
      if (res.data['success'] == true) {
        return res.data['data'] as List<dynamic>;
      }
    } catch (e) {
      // Fallback
    }
    return [];
  }

  Future<Map<String, dynamic>?> getTodayPrayerTimes(String masjidId) async {
    try {
      final res = await _dio.get('/masjids/$masjidId/prayer-times/today');
      if (res.data['success'] == true) {
        return res.data['data'] as Map<String, dynamic>;
      }
    } catch (e) {
      // Return null on network error
    }
    return null;
  }

  Future<List<dynamic>> getAnnouncements(String masjidId) async {
    try {
      final res = await _dio.get('/masjids/$masjidId/announcements');
      if (res.data['success'] == true) {
        return res.data['data'] as List<dynamic>;
      }
    } catch (_) {}
    return [];
  }

  Future<void> ensureSuperAdminAuth() async {
    if (authToken == null) {
      try {
        await verifyOtp('1234567890', '123456');
      } catch (_) {}
    }
  }

  Future<Map<String, dynamic>> createMasjid({
    required String name,
    required String city,
    required String address,
    String? nameTa,
    double? latitude,
    double? longitude,
  }) async {
    final res = await _dio.post('/masjids', data: {
      'name': name,
      'city': city,
      'address': address,
      if (nameTa != null && nameTa.isNotEmpty) 'nameTa': nameTa,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    });
    return res.data;
  }

  Future<List<dynamic>> getPendingMasjidRequests() async {
    try {
      await ensureSuperAdminAuth();
      final res = await _dio.get('/masjids/requests/pending');
      if (res.data['success'] == true && res.data['data'] != null) {
        return res.data['data'] as List<dynamic>;
      }
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>> approveMasjidRequest(String masjidId) async {
    await ensureSuperAdminAuth();
    final res = await _dio.post('/masjids/requests/$masjidId/approve');
    return res.data;
  }

  Future<Map<String, dynamic>> rejectMasjidRequest(String masjidId, [String? reason]) async {
    await ensureSuperAdminAuth();
    final res = await _dio.post('/masjids/requests/$masjidId/reject', data: {
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    });
    return res.data;
  }

  Future<Map<String, dynamic>?> getSuperAdminStats() async {
    try {
      await ensureSuperAdminAuth();
      final res = await _dio.get('/dashboard/super-admin');
      if (res.data['success'] == true) {
        return res.data['data'] as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> getMasjidAdminOverview(String masjidId) async {
    try {
      final res = await _dio.get('/dashboard/masjid/$masjidId');
      if (res.data['success'] == true && res.data['data'] != null) {
        return res.data['data'] as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>> updatePrayerTimes(String masjidId, Map<String, dynamic> dto) async {
    final res = await _dio.put('/masjids/$masjidId/prayer-times', data: dto);
    return res.data;
  }

  Future<Map<String, dynamic>> createAnnouncement(String masjidId, Map<String, dynamic> dto) async {
    final res = await _dio.post('/masjids/$masjidId/announcements', data: dto);
    return res.data;
  }

  Future<Map<String, dynamic>> assignRole(String masjidId, {required String phone, required String name, required String role}) async {
    final res = await _dio.post('/masjids/$masjidId/roles', data: {
      'phone': phone,
      'name': name,
      'role': role,
    });
    return res.data;
  }

  Future<List<dynamic>> getUserSandhaStatus(String masjidId) async {
    try {
      final res = await _dio.get('/masjids/$masjidId/sandha/my-status');
      if (res.data['success'] == true && res.data['data'] != null) {
        return res.data['data'] as List<dynamic>;
      }
    } catch (_) {}
    return [];
  }

  Future<List<dynamic>> getMasjidSandhaPlans(String masjidId) async {
    try {
      final res = await _dio.get('/masjids/$masjidId/sandha/plans');
      if (res.data['success'] == true && res.data['data'] != null) {
        return res.data['data'] as List<dynamic>;
      }
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>> updateMasjid(String masjidId, Map<String, dynamic> dto) async {
    final res = await _dio.put('/masjids/$masjidId', data: dto);
    return res.data;
  }

  Future<Map<String, dynamic>?> getMasjidMembers(String masjidId) async {
    try {
      final res = await _dio.get('/masjids/$masjidId/members');
      if (res.data['success'] == true && res.data['data'] != null) {
        return res.data['data'] as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>> addMasjidMember(String masjidId, {required String phone, String? name}) async {
    final res = await _dio.post('/masjids/$masjidId/members', data: {
      'phone': phone,
      if (name != null && name.isNotEmpty) 'name': name,
    });
    return res.data;
  }

  Future<Map<String, dynamic>> updatePrayerTimeRange(String masjidId, Map<String, dynamic> dto) async {
    final res = await _dio.post('/masjids/$masjidId/prayer-times/range', data: dto);
    return res.data;
  }

  Future<List<dynamic>> getSpecialSchedules(String masjidId) async {
    try {
      final res = await _dio.get('/masjids/$masjidId/special-schedules');
      if (res.data['success'] == true && res.data['data'] != null) {
        return res.data['data'] as List<dynamic>;
      }
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>> createSpecialSchedule(String masjidId, Map<String, dynamic> dto) async {
    final res = await _dio.post('/masjids/$masjidId/special-schedules', data: dto);
    return res.data;
  }

  Future<Map<String, dynamic>> deleteSpecialSchedule(String masjidId, String scheduleId) async {
    final res = await _dio.delete('/masjids/$masjidId/special-schedules/$scheduleId');
    return res.data;
  }

  Future<Map<String, dynamic>> deleteAnnouncement(String masjidId, String announcementId) async {
    final res = await _dio.delete('/masjids/$masjidId/announcements/$announcementId');
    return res.data;
  }

  Future<Map<String, dynamic>> createUser(Map<String, dynamic> dto) async {
    await ensureSuperAdminAuth();
    final res = await _dio.post('/users', data: dto);
    return res.data;
  }

  Future<Map<String, dynamic>?> getUsers({String? search, int page = 1, int limit = 20}) async {
    try {
      await ensureSuperAdminAuth();
      final res = await _dio.get('/users', queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        'page': page,
        'limit': limit,
      });
      if (res.data['success'] == true && res.data['data'] != null) {
        return res.data['data'] as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }
}
