import 'package:flutter/foundation.dart';

/// In-memory session holder for the currently signed-in backend user.
class AuthSession extends ChangeNotifier {
  AuthSession._();

  static final AuthSession instance = AuthSession._();

  int? _userId;
  String? _nickname;
  String? _fullName;

  int? get userId => _userId;
  String? get nickname => _nickname;
  String? get fullName => _fullName;
  bool get isLoggedIn => _userId != null;

  void setFromUserJson(Map<String, dynamic> userJson) {
    final rawId = userJson['userId'];
    _userId = rawId is num ? rawId.toInt() : int.tryParse(rawId?.toString() ?? '');
    _nickname = userJson['nickname'] as String?;
    _fullName = userJson['fullName'] as String?;
    notifyListeners();
  }

  void setUserId(int? userId) {
    _userId = userId;
    notifyListeners();
  }

  void clear() {
    _userId = null;
    _nickname = null;
    _fullName = null;
    notifyListeners();
  }
}
