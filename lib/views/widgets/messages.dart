import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat/views/widgets/message_bubble.dart';

class Messages extends StatelessWidget {
  const Messages({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('chat')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
            // return MyAwesomeApp();
          }

          final docs = snapshot.data.docs;
          return ListView.builder(
            reverse: true,
            itemCount: docs.length,
            itemBuilder: (context, index) => MessageBubble(
              docs[index]['text'],
            ),
          );
        },
      ),
    );
  }
}
