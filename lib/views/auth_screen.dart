import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat/models/auth_data.dart';
import 'package:flutter_chat/views/widgets/auth_form.dart';

class AuthScreen extends StatefulWidget {
  AuthScreen({Key key}) : super(key: key);

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _auth = FirebaseAuth.instance;

  bool _isLoading = false;

  Future<void> _handleSubmit(AuthData authData) async {
    setState(() {
      _isLoading = true;
    });

    UserCredential userCredential;

    try {
      if (authData.isLogin) {
        userCredential = await _auth.signInWithEmailAndPassword(
            email: authData.email, password: authData.password);
      } else {
        userCredential = await _auth.createUserWithEmailAndPassword(
            email: authData.email, password: authData.password);

        final ref = FirebaseStorage.instance
            .ref()
            .child('user_images')
            .child(userCredential.user.uid + '.jpg');

        await ref.putFile(authData.image);
        final url = await ref.getDownloadURL();

        final userData = {
          'name': authData.name,
          'email': authData.email,
          'imageUrl': url,
        };

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user.uid)
            .set(userData);
      }
    } catch (error) {
      String errorMessage =
          error.message ?? 'Ocorreu um erro! Verifique suas credenciais!';

      switch (error.code) {
        case "email-already-in-use":
          errorMessage = "Seu endereço de Email já está em uso.";
          break;
        case "operation-not-allowed":
          errorMessage = "Habilite email/senha no Console do Firebase.";
          break;
        case "weak-password":
          errorMessage = "Sua senha não é forte o suficiente.";
          break;
        case "invalid-email":
          errorMessage = "Seu endereço de Email está mal formatado.";
          break;
        case "user-disabled":
          errorMessage = "Usuário com este Email foi desabilitado.";
          break;
        case "user-not-found":
          errorMessage = "Não existe usuário com este Email.";
          break;
        case "wrong-password":
          errorMessage = "Sua senha está incorreta.";
          break;
        default:
          errorMessage = "Um erro inesperado ocorreu.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          duration: Duration(seconds: 5),
          backgroundColor: Theme.of(context).errorColor,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  AuthForm(_handleSubmit),
                  if (_isLoading)
                    Positioned.fill(
                      child: Container(
                        margin: EdgeInsets.all(20),
                        decoration:
                            BoxDecoration(color: Color.fromRGBO(0, 0, 0, 0.5)),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
