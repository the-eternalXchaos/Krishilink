// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:krishi_link/models/user_model.dart';

// class AuthService {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   // Stream to listen for auth state changes
//   Stream<User?> get authStateChanges => _auth.authStateChanges();

//   // Register new user
//   Future<UserModel?> registerUser({
//     required String fullName,
//     required String email,
//     required String password,
//     required String role, // 'farmer' or 'customer'
//     String? address,
//     String? gender,
//   }) async {
//     try {
//       // 1. Register user with Firebase Auth
//       UserCredential credential = await _auth.createUserWithEmailAndPassword(
//         email: email,
//         password: password,
//       );

//       // 2. Create user document in Firestore
//       UserModel newUser = UserModel(
//         uid: credential.user!.uid,
//         fullName: fullName,
//         email: email,
//         role: role,
//         address: address,
//         gender: gender,
//         phoneNumber: '',
//         profileImageUrl: null,
//         createdAt: DateTime.now(),
//         updatedAt: DateTime.now(),
//       );

//       await _firestore
//           .collection('users')
//           .doc(credential.user!.uid)
//           .set(newUser.toJson());

//       return newUser;
//     } on FirebaseAuthException catch (e) {
//       throw FirebaseAuthException(code: e.code, message: e.message);
//     } catch (e) {
//       throw Exception('Registration failed: ${e.toString()}');
//     }
//   }


//   // Get current user data from Firestore
//   Future<UserModel?> getCurrentUser() async {
//     try {
//       if (_auth.currentUser != null) {
//         DocumentSnapshot doc =
//             await _firestore
//                 .collection('users')
//                 .doc(_auth.currentUser!.uid)
//                 .get();

//         if (doc.exists) {
//           return UserModel.fromJson(doc.data() as Map<String, dynamic>);
//         }
//       }
//       return null;
//     } catch (e) {
//       throw Exception('Error getting user data: ${e.toString()}');
//     }
//   }

//   // Logout user
//   Future<void> logout() async {
//     try {
//       await _auth.signOut();
//     } catch (e) {
//       throw Exception('Logout failed: ${e.toString()}');
//     }
//   }
// }
