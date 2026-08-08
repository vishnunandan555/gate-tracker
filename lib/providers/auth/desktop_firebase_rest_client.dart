import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../firebase_options.dart';

class DesktopUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final String idToken;
  final String refreshToken;
  final DateTime expiresAt;

  DesktopUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    required this.idToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'idToken': idToken,
        'refreshToken': refreshToken,
        'expiresAt': expiresAt.toIso8601String(),
      };

  factory DesktopUser.fromJson(Map<String, dynamic> json) => DesktopUser(
        uid: json['uid'] as String,
        email: json['email'] as String?,
        displayName: json['displayName'] as String?,
        photoUrl: json['photoUrl'] as String?,
        idToken: json['idToken'] as String,
        refreshToken: json['refreshToken'] as String,
        expiresAt: DateTime.parse(json['expiresAt'] as String),
      );
}

class DesktopFirebaseRestClient {
  static String get apiKey => DefaultFirebaseOptions.windows.apiKey;
  static String get projectId => DefaultFirebaseOptions.windows.projectId;

  /// Authenticate with Firebase using a Google OAuth ID Token via REST API
  static Future<DesktopUser> signInWithGoogleIdToken(String googleIdToken) async {
    final url = Uri.parse(
      'https://identitytoolkit.googleapis.com/v1/accounts:signInWithIdToken?key=$apiKey',
    );

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'postBody': 'id_token=$googleIdToken&providerId=google.com',
        'requestUri': 'http://localhost',
        'returnIdpCredential': true,
        'returnSecureToken': true,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Firebase REST Auth failed (${response.statusCode}): ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final uid = data['localId'] as String;
    final idToken = data['idToken'] as String;
    final refreshToken = data['refreshToken'] as String;
    final expiresInStr = data['expiresIn'] as String? ?? '3600';
    final expiresInSec = int.tryParse(expiresInStr) ?? 3600;
    final expiresAt = DateTime.now().add(Duration(seconds: expiresInSec - 60));

    final email = data['email'] as String?;
    final displayName = data['displayName'] as String?;
    final photoUrl = data['photoUrl'] as String?;

    return DesktopUser(
      uid: uid,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      idToken: idToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
    );
  }

  /// Refresh Firebase Auth ID token when expired
  static Future<DesktopUser> refreshToken(DesktopUser user) async {
    final url = Uri.parse(
      'https://securetoken.googleapis.com/v1/token?key=$apiKey',
    );

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'refresh_token',
        'refresh_token': user.refreshToken,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Firebase REST Token Refresh failed: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final newIdToken = data['id_token'] as String;
    final newRefreshToken = data['refresh_token'] as String;
    final expiresInStr = data['expires_in'] as String? ?? '3600';
    final expiresInSec = int.tryParse(expiresInStr) ?? 3600;
    final expiresAt = DateTime.now().add(Duration(seconds: expiresInSec - 60));

    return DesktopUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoUrl,
      idToken: newIdToken,
      refreshToken: newRefreshToken,
      expiresAt: expiresAt,
    );
  }

  /// Fetch user document from Firestore via REST API
  static Future<Map<String, dynamic>?> fetchUserDocument(String uid, String idToken) async {
    final url = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/users/$uid',
    );

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $idToken',
      },
    );

    if (response.statusCode == 404) {
      return null;
    }

    if (response.statusCode != 200) {
      throw Exception('Firestore REST fetch failed (${response.statusCode}): ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final fields = json['fields'] as Map<String, dynamic>?;
    if (fields == null) return null;

    final result = <String, dynamic>{};
    fields.forEach((key, val) {
      result[key] = _firestoreValueToDart(val as Map<String, dynamic>);
    });
    return result;
  }

  /// Save user document to Firestore via REST API
  static Future<void> saveUserDocument(String uid, String idToken, Map<String, dynamic> data) async {
    final url = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/users/$uid',
    );

    final firestoreFields = <String, dynamic>{};
    data.forEach((key, val) {
      firestoreFields[key] = _dartToFirestoreValue(val);
    });

    final body = jsonEncode({
      'fields': firestoreFields,
    });

    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('Firestore REST save failed (${response.statusCode}): ${response.body}');
    }
  }

  static dynamic _firestoreValueToDart(Map<String, dynamic> val) {
    if (val.containsKey('stringValue')) return val['stringValue'];
    if (val.containsKey('booleanValue')) return val['booleanValue'];
    if (val.containsKey('integerValue')) return int.parse(val['integerValue'].toString());
    if (val.containsKey('doubleValue')) return (val['doubleValue'] as num).toDouble();
    if (val.containsKey('timestampValue')) return val['timestampValue'];
    if (val.containsKey('mapValue')) {
      final fields = (val['mapValue'] as Map<String, dynamic>)['fields'] as Map<String, dynamic>?;
      if (fields == null) return <String, dynamic>{};
      final res = <String, dynamic>{};
      fields.forEach((k, v) {
        res[k] = _firestoreValueToDart(v as Map<String, dynamic>);
      });
      return res;
    }
    if (val.containsKey('arrayValue')) {
      final values = (val['arrayValue'] as Map<String, dynamic>)['values'] as List<dynamic>?;
      if (values == null) return [];
      return values.map((e) => _firestoreValueToDart(e as Map<String, dynamic>)).toList();
    }
    if (val.containsKey('nullValue')) return null;
    return null;
  }

  static Map<String, dynamic> _dartToFirestoreValue(dynamic val) {
    if (val == null) return {'nullValue': null};
    if (val is bool) return {'booleanValue': val};
    if (val is int) return {'integerValue': val.toString()};
    if (val is double) return {'doubleValue': val};
    if (val is String) return {'stringValue': val};
    if (val is Map) {
      final fields = <String, dynamic>{};
      val.forEach((k, v) {
        fields[k.toString()] = _dartToFirestoreValue(v);
      });
      return {
        'mapValue': {'fields': fields}
      };
    }
    if (val is List) {
      return {
        'arrayValue': {
          'values': val.map((e) => _dartToFirestoreValue(e)).toList(),
        }
      };
    }
    return {'stringValue': val.toString()};
  }
}
