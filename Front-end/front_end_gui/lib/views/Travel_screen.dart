import 'package:flutter/material.dart';
import 'package:front_end_gui/views/widgets/MapaScreen.dart';

class TravelScreen extends StatefulWidget {
  const TravelScreen({super.key});

 

  @override
  _TravelScreenState createState() => _TravelScreenState();
}

class _TravelScreenState extends State<TravelScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 42),
        child: Column(
          children: [
            Text('SECCIÓN DE PUBLICACIÓN DE VIAJES', style: TextStyle(fontSize: 16 )),
            Text('En esta sección voy a desarrollar como crear un viaje, listar viajes, actualizar viajes y borrar viajes.', style: TextStyle(color: const Color.fromARGB(255, 94, 94, 94)),),
            MapaScreen()
          ],
        ),
      ),
    );
  }
}