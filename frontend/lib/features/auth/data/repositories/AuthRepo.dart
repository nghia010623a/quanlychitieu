import '../datasources/AuthAPI.dart';

class AuthRepo {
  final AuthAPI api;

  AuthRepo({AuthAPI? api}) : api = api ?? AuthAPI();

  Future<Map<String, dynamic>> login({
    required String nickname,
    required String password,
  }) async {
    return await api.login(
      identifier: nickname,
      password: password,
    );
  }
}