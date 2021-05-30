import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:flutter_chat/views/auth_screen.dart';
import 'package:flutter_chat/views/chat_screen.dart';

/// Create a [AndroidNotificationChannel] for heads up notifications
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', // id
  'High Importance Notifications', // title
  'This channel is used for important notifications.', // description
  importance: Importance.high,
);

/// Initialize the [FlutterLocalNotificationsPlugin] package.
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// To verify things are working, check out the native platform logs.
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();
  print('Handling a background message ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  runApp(App());
}

/// We are using a StatefulWidget such that we only create the [Future] once,
/// no matter how many times our widget rebuild.
/// If we used a [StatelessWidget], in the event where [App] is rebuilt, that
/// would re-initialize FlutterFire and make our application re-enter loading state,
/// which is undesired.
class App extends StatefulWidget {
  // Create the initialization Future outside of `build`:
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  /// The future is part of the state of our widget. We should not call `initializeApp`
  /// directly inside [build].
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();

  void showNotification() {
    setState(() {
      flutterLocalNotificationsPlugin.show(
        0,
        "Flutter Chat",
        "Your new message is here",
        NotificationDetails(
            android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channel.description,
          importance: Importance.high,
          color: Colors.blue,
          playSound: true,
          icon: '@mipmap/ic_launcher',
        )),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        backgroundColor: Colors.blue,
        accentColor: Colors.red,
      ),
      home: FutureBuilder(
        future: _initialization,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Container(
                child: Text("Algo deu errado!"),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.done) {
            return StreamBuilder(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, userSnapshot) {
                if (userSnapshot.hasData) {
                  @override
                  void initState() {
                    super.initState();
                    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
                      RemoteNotification notification = message.notification;
                      AndroidNotification android =
                          message.notification?.android;
                      if (notification != null && android != null) {
                        flutterLocalNotificationsPlugin.show(
                            notification.hashCode,
                            notification.title,
                            notification.body,
                            NotificationDetails(
                              android: AndroidNotificationDetails(
                                channel.id,
                                channel.name,
                                channel.description,
                                color: Colors.blue,
                                playSound: true,
                                icon: '@mipmap/ic_launcher',
                              ),
                            ));
                      }
                    });

                    FirebaseMessaging.onMessageOpenedApp
                        .listen((RemoteMessage message) {
                      print('A new onMessageOpenedApp event was published!');
                      RemoteNotification notification = message.notification;
                      AndroidNotification android =
                          message.notification?.android;
                      if (notification != null && android != null) {
                        showDialog(
                            context: context,
                            builder: (_) {
                              return AlertDialog(
                                title: Text(notification.title),
                                content: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(notification.body),
                                    ],
                                  ),
                                ),
                              );
                            });
                      }
                    });
                  }

                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        ChatScreen(),
                        FloatingActionButton(
                          onPressed: showNotification,
                          tooltip: 'increment',
                          child: Icon(Icons.add),
                        ),
                      ],
                    ),
                  );
                } else {
                  return AuthScreen();
                }
              },
            );
          }
          return Center(
            child: Container(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }
}
