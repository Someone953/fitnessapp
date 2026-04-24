import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DbHelper {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // User Auth Methods
  static Future<String?> register(String email, String password, String username) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      final uid = credential.user?.uid;
      
      if (uid != null) {
        // Create a user document with username
        await _db.collection('users').doc(uid).set({
          'username': username,
          'email': email,
          'created_at': FieldValue.serverTimestamp(),
        });
      }
      return uid;
    } catch (e) {
      rethrow;
    }
  }

  static Future<String?> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return credential.user?.uid;
    } catch (e) {
      return null;
    }
  }

  static Future<void> logout() async {
    await _auth.signOut();
  }

  // Firestore Methods
  static Future<void> insert(String collection, Map<String, dynamic> data) async {
    await _db.collection(collection).add(data);
  }

  static Future<List<Map<String, dynamic>>> query(String collection, {String? userId}) async {
    Query query = _db.collection(collection);
    if (userId != null) {
      query = query.where('user_id', isEqualTo: userId);
    }
    
    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id; 
      return data;
    }).toList();
  }

  static Future<void> update(String collection, Map<String, dynamic> data, String id) async {
    await _db.collection(collection).doc(id).update(data);
  }

  static Future<void> delete(String collection, String id) async {
    await _db.collection(collection).doc(id).delete();
  }
  
  static Future<Map<String, dynamic>?> getUserData(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }
}
