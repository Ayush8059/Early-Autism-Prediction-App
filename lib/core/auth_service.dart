import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService(this._client);

  static const passwordResetRedirectUrl =
      'com.example.autisense://auth-callback';

  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    String? captchaToken,
  }) async {
    return _client.auth.signUp(
      email: email.trim(),
      password: password,
      emailRedirectTo: passwordResetRedirectUrl,
      data: {'full_name': fullName.trim()},
      captchaToken: captchaToken,
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
    String? captchaToken,
  }) {
    return _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
      captchaToken: captchaToken,
    );
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<void> resetPassword(String email, {String? captchaToken}) {
    return _client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: passwordResetRedirectUrl,
      captchaToken: captchaToken,
    );
  }

  Future<void> resendSignupConfirmation({
    required String email,
    String? captchaToken,
  }) {
    return _client.auth.resend(
      type: OtpType.signup,
      email: email.trim(),
      emailRedirectTo: passwordResetRedirectUrl,
      captchaToken: captchaToken,
    );
  }

  Future<UserResponse> updatePassword(String password) {
    return _client.auth.updateUser(UserAttributes(password: password));
  }

  Future<void> deleteAccount() async {
    await _client.functions.invoke('delete-account');
    await _client.auth.signOut();
  }
}
