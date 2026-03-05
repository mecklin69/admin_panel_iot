import 'dart:async';
import 'dart:math'; // For random simulation
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapConfiguration extends StatefulWidget {
  const MapConfiguration({super.key});

  @override
  State<MapConfiguration> createState() => _MapConfigurationState();
}

class _MapConfigurationState extends State<MapConfiguration> with AutomaticKeepAliveClientMixin {
  final Completer<GoogleMapController> _controller = Completer();
  String? _selectedState;
  Set<Marker> _markers = {};

  @override
  bool get wantKeepAlive => true;

  // Camera settings
  static const CameraPosition _initialIndia = CameraPosition(
    target: LatLng(22.0000, 78.9629),
    zoom: 4.5,
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


  @override
  void initState() {
    super.initState();
    _loadUttarakhandSensors(); // Initialize with sensor pins
  }

  void _loadUttarakhandSensors() {
    final Random random = Random();

    // 16 key approximate coordinates within Uttarakhand
    final List<LatLng> uttarakhandPoints = [
      const LatLng(30.3165, 78.0322), // Dehradun
      const LatLng(29.9457, 78.1642), // Haridwar
      const LatLng(29.3919, 79.4542), // Nainital
      const LatLng(30.0869, 78.2676), // Rishikesh
      const LatLng(29.5892, 79.6467), // Almora
      const LatLng(30.4000, 79.3333), // Chamoli
      const LatLng(30.7343, 79.0669), // Kedarnath Area
      const LatLng(30.5208, 78.8471), // Rudraprayag
      const LatLng(30.1467, 78.7889), // Pauri
      const LatLng(30.3753, 78.4444), // Tehri
      const LatLng(30.7291, 78.4359), // Uttarkashi
      const LatLng(29.7381, 80.2182), // Pithoragarh
      const LatLng(28.9800, 79.4500), // Rudrapur
      const LatLng(29.8377, 79.7694), // Bageshwar
      const LatLng(29.2104, 79.5126), // Haldwani
      const LatLng(29.8543, 77.8880), // Roorkee
    ];

    Set<Marker> sensorMarkers = {};

    for (int i = 0; i < uttarakhandPoints.length; i++) {
      // Simulating real-time data
      double temp = 15 + random.nextDouble() * 15; // 15°C to 30°C
      int humidity = 40 + random.nextInt(40); // 40% to 80%
      double turbidity = random.nextDouble() * 5.0; // 0-5 NTU

      sensorMarkers.add(
        Marker(
          markerId: MarkerId('sensor_$i'),
          position: uttarakhandPoints[i],
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: InfoWindow(
            title: "Sensor Node UK-${100 + i}",
            snippet: "Temp: ${temp.toStringAsFixed(1)}°C | Hum: $humidity% | Turb: ${turbidity.toStringAsFixed(2)} NTU",
          ),
        ),
      );
    }

    setState(() {
      _markers.addAll(sensorMarkers);
    });
  }

  void _onStateSelected(String? stateName) async {
    if (stateName == null) return;
    final coords = _indiaStates[stateName]!;
    final GoogleMapController controller = await _controller.future;

    setState(() {
      _selectedState = stateName;
      // We keep the sensor markers and just move the camera
    });

    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: coords, zoom: stateName == "Uttarakhand" ? 8.5 : 6.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialIndia,
            markers: _markers,
            onMapCreated: (GoogleMapController controller) => _controller.complete(controller),
            zoomControlsEnabled: false,
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildDropdown(),
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
          items: _indiaStates.keys.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: _onStateSelected,
        ),
      ),
    );
  }
}