import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseNotification{
  final _firebaseMessaging=FirebaseMessaging.instance;
  Future<void>initNotifications()async{
    await _firebaseMessaging.requestPermission();
    String? token=await _firebaseMessaging.getToken();
    print("Token: $token");
  }


}
