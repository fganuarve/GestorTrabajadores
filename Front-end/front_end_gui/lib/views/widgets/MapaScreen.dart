import 'package:flutter/material.dart';
import 'package:front_end_gui/services/GoogleMapServices.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:developer';

class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});


  @override
  _MapaScreenState createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {

  GoogleMapController? _mapController;
  final Set<Polyline> _polylines = {};
  final GoogleMapServices _mapsService = GoogleMapServices();

  // Coordenadas de ejemplo
  final LatLng _origen = LatLng(40.416775, -3.703790);  // Madrid
  final LatLng _destino = LatLng(40.4378698, -3.8196208); // Hospital en Madrid

  @override
  void initState() {
   
    super.initState();
    
  }

  void _cargarRuta() async {

    try {
       List<LatLng> puntosRuta = await _mapsService.getRouteCoordinates(_origen, _destino);

      if(puntosRuta.isNotEmpty){
        setState(() {
              _polylines.add( Polyline(
                polylineId: PolylineId("ruta"),
                color: Colors.blue,
                width: 5,
                points: puntosRuta
                ));
            });
      } else {
        log('Error en la devolución de Lista puntosRuta - MapaScreen');
      }
    } catch (e) {
      log("Error en la devolución de Lista puntosRuta - MapaScreen");
    }
    
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height, // Limita el tamaño
      width: MediaQuery.of(context).size.width,
      child: GoogleMap(
        initialCameraPosition: CameraPosition(target: _origen, zoom: 12),
        onMapCreated: (GoogleMapController controller) {
         if(_mapController == null){
           _mapController = controller;
           _cargarRuta();
         }
        },
        markers: {
          Marker(markerId: MarkerId("origen"), position: _origen),
          Marker(markerId: MarkerId("destino"), position: _destino),
        },
        polylines: _polylines,
      ),
    );

    
  }
}