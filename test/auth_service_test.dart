import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vibetune/config/api_config.dart';
import 'package:vibetune/models/user_model.dart';
import 'package:vibetune/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Disable Flutter test mock HTTP overrides to permit real HTTP calls to the backend
    HttpOverrides.global = null;
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    // Point directly to local server running on port 5000
    ApiConfig.setCustomBaseUrl('http://127.0.0.1:5000');
  });

  group('UserModel tests', () {
    test('parses from JSON with id and _id', () {
      final user1 = UserModel.fromJson({
        'id': 'usr_123',
        'name': 'Swathi Test',
        'email': 'swathi@vibetune.com',
      });
      expect(user1.id, 'usr_123');
      expect(user1.name, 'Swathi Test');
      expect(user1.email, 'swathi@vibetune.com');

      final user2 = UserModel.fromJson({
        '_id': 'mongo_456',
        'name': 'Mongo User',
        'email': 'mongo@vibetune.com',
      });
      expect(user2.id, 'mongo_456');
    });

    test('serializes to JSON accurately', () {
      const user = UserModel(
        id: 'usr_789',
        name: 'Vibe Musician',
        email: 'vibe@vibetune.com',
        preferredLanguages: ['Hindi', 'Kannada'],
      );
      final json = user.toJson();
      expect(json['id'], 'usr_789');
      expect(json['name'], 'Vibe Musician');
      expect(json['email'], 'vibe@vibetune.com');
      expect(json['role'], 'user');
      expect(json['preferredLanguages'], ['Hindi', 'Kannada']);
    });

    test('parses role and evaluates isAdmin correctly', () {
      final regularUser = UserModel.fromJson({
        'id': 'usr_user',
        'name': 'Regular Singer',
        'email': 'singer@vibetune.com',
        'role': 'user',
      });
      expect(regularUser.role, 'user');
      expect(regularUser.isAdmin, isFalse);

      final adminUser = UserModel.fromJson({
        'id': 'usr_admin',
        'name': 'Admin Lead',
        'email': 'admin@vibetune.com',
        'role': 'admin',
      });
      expect(adminUser.role, 'admin');
      expect(adminUser.isAdmin, isTrue);
    });
  });

  group('Live Backend AuthService Integration Tests', () {
    final uniqueTimestamp = DateTime.now().millisecondsSinceEpoch;
    final testEmail = 'flutter_client_$uniqueTimestamp@vibetune.com';
    const testPassword = 'FlutterSecurePassword123!';
    const testName = 'Flutter Integration User';
    bool isDbAvailable = false;

    setUpAll(() async {
      HttpOverrides.global = null;
      try {
        final client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 5);
        final request = await client.getUrl(Uri.parse('http://127.0.0.1:5000/api/health'));
        final response = await request.close().timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          isDbAvailable = true;
        }
      } catch (_) {
        isDbAvailable = false;
      }
    });

    test('Full authentication lifecycle: SignUp -> Duplicate SignUp -> Login Failure -> Login Success -> SignOut', () async {
      final authService = AuthService();

      // 1. Initial State
      expect(authService.isAuthenticated, isFalse);
      expect(authService.currentUser, isNull);

      if (!isDbAvailable) {
        // Log clear explanation as required by Module 12
        // ignore: avoid_print
        print('NOTE: MongoDB Atlas is currently offline or current IP requires whitelisting. Skipping live DB write assertions.');
        return;
      }

      // 2. SignUp with backend
      final signUpResult = await authService.signUp(
        name: testName,
        email: testEmail,
        password: testPassword,
        preferredLanguages: ['Hindi', 'Kannada', 'Telugu'],
      );

      expect(signUpResult.isSuccess, isTrue, reason: signUpResult.errorMessage);
      expect(authService.isAuthenticated, isTrue);
      expect(authService.currentUser?.email, testEmail.toLowerCase());
      expect(authService.currentUser?.name, testName);
      expect(authService.token, isNotNull);
      expect(authService.token!.length, greaterThan(20));

      // 3. Duplicate SignUp with same email must fail
      final dupSignUpResult = await authService.signUp(
        name: 'Another User',
        email: testEmail,
        password: testPassword,
        preferredLanguages: ['Tamil'],
      );
      expect(dupSignUpResult.isSuccess, isFalse);
      expect(dupSignUpResult.errorMessage, contains('already registered'));

      // 4. SignOut
      await authService.signOut();
      expect(authService.isAuthenticated, isFalse);
      expect(authService.currentUser, isNull);
      expect(authService.token, isNull);

      // 5. Login with invalid password must fail
      final badLoginResult = await authService.signIn(testEmail, 'IncorrectPassword999!');
      expect(badLoginResult.isSuccess, isFalse);
      expect(badLoginResult.errorMessage, 'Invalid email or password.');
      expect(authService.isAuthenticated, isFalse);

      // 6. Login with valid credentials must succeed
      final goodLoginResult = await authService.signIn(testEmail, testPassword);
      expect(goodLoginResult.isSuccess, isTrue);
      expect(authService.isAuthenticated, isTrue);
      expect(authService.currentUser?.email, testEmail.toLowerCase());
      expect(authService.currentUser?.name, testName);
      expect(authService.token, isNotNull);

      // 7. Test Authenticated Profile Retrieval via GET /api/auth/me
      final profileFetched = await authService.refreshUserProfile();
      expect(profileFetched, isTrue);
      expect(authService.currentUser?.email, testEmail.toLowerCase());

      // 8. Clean up sign out
      await authService.signOut();
      expect(authService.isAuthenticated, isFalse);
    });

    test('Registration rejects invalid email format and short passwords', () async {
      final authService = AuthService();

      // Missing or invalid email
      final badEmailResult = await authService.signUp(
        name: 'Invalid Email User',
        email: 'not-an-email',
        password: 'Password123!',
        preferredLanguages: ['Hindi'],
      );
      expect(badEmailResult.isSuccess, isFalse);
      expect(badEmailResult.errorMessage, contains('valid email'));

      // Short password (< 6 chars)
      final shortPassResult = await authService.signUp(
        name: 'Short Password User',
        email: 'valid_test_format@vibetune.com',
        password: '123',
        preferredLanguages: ['Hindi'],
      );
      expect(shortPassResult.isSuccess, isFalse);
      expect(shortPassResult.errorMessage, contains('at least 6 characters'));
    });

    test('Token verification rejects invalid or malformed tokens', () async {
      final authService = AuthService();
      final isTokenValid = await authService.verifyToken('malformed.fake.jwt_token');
      expect(isTokenValid, isFalse);
      expect(authService.isAuthenticated, isFalse);
    });

    test('Guest mode continues without network call', () {
      final authService = AuthService();
      authService.continueAsGuest();
      expect(authService.isAuthenticated, isTrue);
      expect(authService.currentUser?.name, 'Guest Explorer');
      expect(authService.currentUser?.email, 'guest@vibetune.com');
    });
  });
}
