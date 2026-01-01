import 'package:cloud_firestore/cloud_firestore.dart';

/// Authentication Service - Quản lý login/logout với Firebase
class AuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Kiểm tra login với username và password từ Firestore
  Future<Map<String, dynamic>?> login(String username, String password) async {
    try {
      // Query Firestore collection 'users' để tìm user
      final querySnapshot =
          await _firestore
              .collection('users')
              .where('username', isEqualTo: username)
              .where('password', isEqualTo: password)
              .limit(1)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Tìm thấy user - trả về user data
        final userData = querySnapshot.docs.first.data();
        userData['id'] = querySnapshot.docs.first.id;
        return userData;
      }

      return null; // Không tìm thấy user
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  /// Kiểm tra xem username đã tồn tại chưa
  Future<bool> checkUsernameExists(String username) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('users')
              .where('username', isEqualTo: username)
              .limit(1)
              .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Check username error: $e');
      return false;
    }
  }

  /// Tạo user mới trong Firestore (optional - for admin)
  Future<bool> createUser({
    required String username,
    required String password,
    String? displayName,
    String? email,
  }) async {
    try {
      // Kiểm tra username đã tồn tại chưa
      final exists = await checkUsernameExists(username);
      if (exists) {
        print('Username already exists');
        return false;
      }

      // Tạo user mới
      await _firestore.collection('users').add({
        'username': username,
        'password': password,
        'displayName': displayName ?? username,
        'email': email ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Create user error: $e');
      return false;
    }
  }
}
