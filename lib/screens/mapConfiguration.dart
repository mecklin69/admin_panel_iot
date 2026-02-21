import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapConfiguration extends StatefulWidget {
  const MapConfiguration({super.key});

  @override
  State<MapConfiguration> createState() => _MapConfigurationState();
}

class _MapConfigurationState extends State<MapConfiguration> with AutomaticKeepAliveClientMixin {
  final Completer<GoogleMapController> _controller = Completer();

  // State variables
  String? _selectedState;
  Set<Marker> _markers = {};

  // Camera settings
  static const CameraPosition _initialIndia = CameraPosition(
    target: LatLng(20.5937, 78.9629),
    zoom: 4.8,
  );

  final Map<String, LatLng> _indiaStates = {
    "Andhra Pradesh": const LatLng(15.9129, 79.7400),
    "Arunachal Pradesh": const LatLng(28.2180, 94.7278),
    "Assam": const LatLng(26.2006, 92.9376),
    "Bihar": const LatLng(25.0961, 85.3131),
    "Chhattisgarh": const LatLng(21.2787, 81.8661),
    "Goa": const LatLng(15.2993, 74.1240),
    "Gujarat": const LatLng(22.2587, 71.1924),
    "Haryana": const LatLng(29.0588, 76.0856),
    "Himachal Pradesh": const LatLng(31.1048, 77.1734),
    "Jammu & Kashmir": const LatLng(33.2778, 75.3412), // Added
    "Jharkhand": const LatLng(23.6102, 85.2799),
    "Karnataka": const LatLng(15.3173, 75.7139),
    "Kerala": const LatLng(10.8505, 76.2711),
    "Ladakh": const LatLng(34.1526, 77.5770), // Added
    "Madhya Pradesh": const LatLng(22.9734, 78.6569),
    "Maharashtra": const LatLng(19.7515, 75.7139),
    "Manipur": const LatLng(24.6637, 93.9063),
    "Meghalaya": const LatLng(25.4670, 91.3662),
    "Mizoram": const LatLng(23.1645, 92.9376),
    "Nagaland": const LatLng(26.1584, 94.5624),
    "Odisha": const LatLng(20.9517, 85.0985),
    "Punjab": const LatLng(31.1471, 75.3412),
    "Rajasthan": const LatLng(27.0238, 74.2179),
    "Sikkim": const LatLng(27.5330, 88.5122),
    "Tamil Nadu": const LatLng(11.1271, 78.6569),
    "Telangana": const LatLng(18.1124, 79.0193),
    "Tripura": const LatLng(23.9408, 91.9882),
    "Uttar Pradesh": const LatLng(26.8467, 80.9462),
    "Uttarakhand": const LatLng(30.0668, 79.0193),
    "West Bengal": const LatLng(22.9868, 87.8550),
    "Andaman & Nicobar": const LatLng(11.7401, 92.6586),
    "Chandigarh": const LatLng(30.7333, 76.7794),
    "Delhi": const LatLng(28.7041, 77.1025),
    "Puducherry": const LatLng(11.9416, 79.8083),
  };

  void _onStateSelected(String? stateName) async {
    if (stateName == null) return;

    final coords = _indiaStates[stateName]!;
    final GoogleMapController controller = await _controller.future;

    setState(() {
      _selectedState = stateName;
      // Add a marker at the state location
      _markers = {
        Marker(
          markerId: MarkerId(stateName),
          position: coords,
          infoWindow: InfoWindow(title: stateName, snippet: "Major Hub"),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        )
      };
    });

    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: coords, zoom: 6.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: Stack(
        children: [
          // THE MAP
          GoogleMap(
            initialCameraPosition: _initialIndia,
            markers: _markers,
            onMapCreated: (GoogleMapController controller) => _controller.complete(controller),
            zoomControlsEnabled: false, // Cleaner UI
            mapToolbarEnabled: false,
          ),

          // OVERLAY UI
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildDropdown(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedState,
          hint: const Text("Select India State", style: TextStyle(color: Colors.indigo)),
          isExpanded: true,
          icon: const Icon(Icons.map_outlined, color: Colors.indigo),
          items: _indiaStates.keys.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
            );
          }).toList(),
          onChanged: _onStateSelected,
        ),
      ),
    );
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
}