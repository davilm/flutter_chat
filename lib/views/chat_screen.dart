import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('chat').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
            // return MyAwesomeApp();
          }

          final docs = snapshot.data.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) => Container(
              padding: EdgeInsets.all(10),
              child: Text(docs[index]['text']),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          FirebaseFirestore.instance.collection('chat').add({
            'text': 'Adicionado manualmente!',
          });
        },
      ),
    );
  }
}
