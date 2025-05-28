import 'package:flutter/material.dart';

class PersonalprofileScreen extends StatefulWidget {
  const PersonalprofileScreen({super.key});


  @override
  _PersonalprofileScreenState createState() => _PersonalprofileScreenState();
}

class _PersonalprofileScreenState extends State<PersonalprofileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32 , vertical: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Nombre del usuario')
          ],
        ),
      )
    );
  }
}