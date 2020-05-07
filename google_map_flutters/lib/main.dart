
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:fluster/fluster.dart';
import 'map_marker.dart';
import 'map_helper.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
void main() => runApp(MaterialApp(home: HomePage()));

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Completer<GoogleMapController> _mapController = Completer();
  final Set<Marker> _markers = Set();
  final int _minClusterZoom = 0;
  final int _maxClusterZoom = 19;
  Fluster<MapMarker> _clusterManager;
  double _currentZoom = 15;
  bool _isMapLoading = true;
  bool _areMarkersLoading = true;
  final String _markerImageUrl = 'https://img.icons8.com/color/80/000000/marker.png';
  final Color _clusterColor = Colors.blue;
  final Color _clusterTextColor = Colors.white;

  final List<LatLng> _markerLocations = [
    LatLng(23.0215,  72.5714),
    LatLng(23.0225,  72.5725),
    LatLng(23.0230,  72.5739),
    LatLng(23.0241,  72.5740),
    LatLng(23.0255,  72.5751),
    LatLng(23.0264,  72.5760),
    LatLng(23.0276,  72.5774),
    LatLng(23.0280,  72.5780),
    LatLng(23.0294,  72.5794),
    LatLng(23.0205,  72.5704),
  ];


  void _onMapCreated(GoogleMapController controller) {
    _mapController.complete(controller);

    setState(() {
      _isMapLoading = false;
    });

    _initMarkers();
  }

   void _initMarkers() async {
    final List<MapMarker> markers = [];

    for (LatLng markerLocation in _markerLocations) {
      final BitmapDescriptor markerImage =
      await MapHelper.getMarkerImageFromUrl(_markerImageUrl);

      markers.add(
        MapMarker(

          id: _markerLocations.indexOf(markerLocation).toString(),
          position: markerLocation,
          icon: markerImage,
        ),
      );
    }

    _clusterManager = await MapHelper.initClusterManager(
      markers,
      _minClusterZoom,
      _maxClusterZoom,
    );

    await _updateMarkers();
  }


  Future<void> _updateMarkers([double updatedZoom]) async {
    if (_clusterManager == null || updatedZoom == _currentZoom) return;

    if (updatedZoom != null) {
      _currentZoom = updatedZoom;
    }

    setState(() {
      _areMarkersLoading = true;
    });

    final updatedMarkers = await MapHelper.getClusterMarkers(
      _clusterManager,
      _currentZoom,
      _clusterColor,
      _clusterTextColor,
      80,
    );

    _markers
      ..clear()
      ..addAll(updatedMarkers);

    setState(() {
      _areMarkersLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Google map Clusters '),
      ),
      body: Stack(
        children: <Widget>[
          // Google Map widget
          Opacity(
            opacity: _isMapLoading ? 0 : 1,
            child: GoogleMap(
              mapToolbarEnabled: false,
              initialCameraPosition: CameraPosition(
                target: LatLng(23.0225,  72.5714),
                zoom: _currentZoom,
              ),
              markers: _markers,
              onMapCreated: (controller) => _onMapCreated(controller),
              onCameraMove: (position) => _updateMarkers(position.zoom),
            ),
          ),

          // Map loading indicator
          Opacity(
            opacity: _isMapLoading ? 1 : 0,
            child: Center(child: CircularProgressIndicator()),
          ),

          // Map markers loading indicator
          _areMarkersLoading ?
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Align(
              alignment: Alignment.topCenter,
              child: Card(
                elevation: 2,
                color: Colors.grey.withOpacity(0.9),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    'Loading',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ): Container()
        ],
      ),
    );
  }
}




