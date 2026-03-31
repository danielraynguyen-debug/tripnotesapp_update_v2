import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Gửi OTP
  Future<void> verifyPhone({
    required String phoneNumber,
    required Function(String) onCodeSent,
    required Function(FirebaseAuthException) onFailed,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: onFailed,
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  // Xác nhận OTP và cập nhật FCM Token sau khi login thành công
  Future<UserCredential> verifyOTP(String verificationId, String smsCode) async {
    AuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    final userCred = await _auth.signInWithCredential(credential);
    if (userCred.user != null) {
      await updateFcmToken(userCred.user!.uid);
    }
    return userCred;
  }

  // Cập nhật FCM Token vào Firestore
  Future<void> updateFcmToken(String uid) async {
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(uid).set({
          'fcmToken': token,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint("Lỗi cập nhật FCM Token: $e");
    }
  }

  // Lưu thông tin người dùng vào Firestore
  Future<void> saveUserToFirestore(UserModel user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(user.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw Exception("Lỗi khi lưu dữ liệu vào Firestore: $e");
    }
  }

  // Lắng nghe dữ liệu người dùng realtime
  Stream<UserModel?> getUserStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    });
  }

  // Tải lên avatar
  Future<void> uploadAvatar(String uid, File imageFile) async {
    try {
      final ref = _storage.ref().child('avatars/$uid.jpg');
      await ref.putFile(imageFile);
      final downloadUrl = await ref.getDownloadURL();
      
      // Cập nhật vào Firestore
      await _firestore.collection('users').doc(uid).update({
        'photoUrl': downloadUrl,
      });

      // Cập nhật Firebase Auth (Tùy chọn)
      await _auth.currentUser?.updatePhotoURL(downloadUrl);
    } catch (e) {
      throw Exception("Lỗi khi tải ảnh đại diện: $e");
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get current user
  User? get currentUser => _auth.currentUser;
}
