import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  runApp(const MaterialApp(
    home: MapConfiguration(),
    debugShowCheckedModeBanner: false,
  ));
}

class SensorNode {
  final String id;
  final LatLng position;
  final double temperature;
  final int humidity;
  final double turbidity;

  SensorNode({
    required this.id,
    required this.position,
    required this.temperature,
    required this.humidity,
    required this.turbidity,
  });
}

class MapConfiguration extends StatefulWidget {
  const MapConfiguration({super.key});

  @override
  State<MapConfiguration> createState() => _MapConfigurationState();
}

class _MapConfigurationState extends State<MapConfiguration> {
  final Completer<GoogleMapController> _controller = Completer();
  String? _selectedState;
  bool _isPanelOpen = false;
  final List<SensorNode> _activeSensors = [];
  final Set<Marker> _markers = {};

  final Map<String, LatLng> _indiaStates = {
    "Andhra Pradesh": const LatLng(15.9129, 79.7400),
    "Bihar": const LatLng(25.0961, 85.3131),
    "Gujarat": const LatLng(22.2587, 71.1924),
    "Maharashtra": const LatLng(19.7515, 75.7139),
    "Rajasthan": const LatLng(27.0238, 74.2179),
    "Uttar Pradesh": const LatLng(26.8467, 80.9462),
    "Uttarakhand": const LatLng(30.0668, 79.0193),
    "West Bengal": const LatLng(22.9868, 87.8550),
  };

  @override
  void initState() {
    super.initState();
    _generateMockSensors();
  }

  void _generateMockSensors() {
    final Random random = Random();
    final List<LatLng> uttarakhandPoints = [
      const LatLng(30.3165, 78.0322), const LatLng(29.9457, 78.1642),
      const LatLng(29.3919, 79.4542), const LatLng(30.0869, 78.2676),
      const LatLng(30.5208, 78.8471), const LatLng(29.8543, 77.8880),
    ];

    for (int i = 0; i < uttarakhandPoints.length; i++) {
      final node = SensorNode(
        id: "UK-${100 + i}",
        position: uttarakhandPoints[i],
        temperature: 18.0 + random.nextDouble() * 10,
        humidity: 50 + random.nextInt(30),
        turbidity: random.nextDouble() * 3.0,
      );
      _activeSensors.add(node);
      _markers.add(
        Marker(
          markerId: MarkerId(node.id),
          position: node.position,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          onTap: () => _handleMarkerTap(node),
        ),
      );
    }
  }

  void _handleMarkerTap(SensorNode node) {
    setState(() {
      _selectedState = "Uttarakhand";
      _isPanelOpen = true;
    });
    _animateCamera(node.position, 12.0);
  }

  void _onStateSelected(String? stateName) {
    if (stateName == null) return;
    setState(() {
      _selectedState = stateName;
      _isPanelOpen = true; // Fix #3: Ensure panel opens on state selection
    });
    _animateCamera(_indiaStates[stateName]!, stateName == "Uttarakhand" ? 8.5 : 6.5);
  }

  Future<void> _animateCamera(LatLng position, double zoom) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: position, zoom: zoom),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Map
          GoogleMap(
            initialCameraPosition: const CameraPosition(target: LatLng(22.0, 78.0), zoom: 4.5),
            markers: _markers,
            onMapCreated: (c) => _controller.complete(c),
            zoomControlsEnabled: false,
            onTap: (_) => setState(() => _isPanelOpen = false),
          ),

          // 2. Dropdown Header
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                // Fix #1: Use finite width calculation instead of double.infinity
                width: _isPanelOpen ? screenWidth - 380 : screenWidth - 32,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedState,
                    hint: const Text("Select State"),
                    isExpanded: true,
                    items: _indiaStates.keys.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: _onStateSelected,
                  ),
                ),
              ),
            ),
          ),

          // 3. Side Panel
          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            right: _isPanelOpen ? 0 : -350,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: () {}, // This prevents taps from reaching the map
              behavior: HitTestBehavior.opaque, // This ensures the entire area catches the tap
              child: _buildSidePanel(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidePanel() {
    return Container(
      width: 350,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), bottomLeft: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15, spreadRadius: 5)],
      ),
      child: Column(
        children: [
          const SizedBox(height: 60),
          _buildPanelHeader(),
          const Divider(height: 1),
          Expanded(child: _buildSensorList()),
        ],
      ),
    );
  }

  Widget _buildPanelHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const CircleAvatar(backgroundColor: Colors.indigo, child: Icon(Icons.map, color: Colors.white)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_selectedState ?? "Select State", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const Text("Regional Analytics", style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _isPanelOpen = false),
            icon: const Icon(Icons.close_fullscreen_rounded),
          )
        ],
      ),
    );
  }

  Widget _buildSensorList() {
    bool hasSensors = _selectedState == "Uttarakhand";

    if (!hasSensors) {
      return const Center(child: Text("No data for this region", style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _activeSensors.length,
      itemBuilder: (context, index) {
        final sensor = _activeSensors[index];
        return GestureDetector(
          onTap: (){},
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(15),
            ),
            child: ExpansionTile(
              key: PageStorageKey(sensor.id),
              shape: const Border(), // Removes default tile borders
              leading: const Icon(Icons.sensors, color: Colors.orange),
              title: Text("Node ${sensor.id}"),
              subtitle: Text("Health: 100%", style: TextStyle(color: Colors.green.shade700, fontSize: 11)),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 15, left: 15, right: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _tileStat("Temp", "${sensor.temperature.toStringAsFixed(1)}°C"),
                      _tileStat("Hum", "${sensor.humidity}%"),
                      _tileStat("Turb", "${sensor.turbidity.toStringAsFixed(2)}"),
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _tileStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}