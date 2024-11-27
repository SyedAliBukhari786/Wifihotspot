import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class WifiSearchApp extends StatefulWidget {
  @override
  _WifiSearchAppState createState() => _WifiSearchAppState();
}

class _WifiSearchAppState extends State<WifiSearchApp> {
  final MapController _mapController = MapController();
  List<List<dynamic>> csvData = [];
  List<List<dynamic>> filteredData = [];
  List<Marker> markers = [];
  bool _isSearching = false;

  String selectedCity = '';
  String selectedProvider = '';

  LatLng userLocation = LatLng(40.73061, -73.935242); // Default NYC location
  List<String> cities = [];
  List<String> providers = [];

  @override
  void initState() {
    super.initState();
    _loadCsvData();
  }

  Future<void> _loadCsvData() async {
    try {
      final rawData = await rootBundle.loadString('assets/locations.csv');
      List<List<dynamic>> data = const CsvToListConverter().convert(rawData);

      // Extract unique cities and providers
      List<String> cityList =
      data.skip(1).map((row) => row[12].toString()).toSet().toList();
      List<String> providerList =
      data.skip(1).map((row) => row[3].toString()).toSet().toList();

      setState(() {
        csvData = data;
        cities = cityList..sort();
        providers = providerList..sort();
      });
    } catch (e) {
      print('Error loading CSV data: $e');
    }
  }

  void _filterData() {
    setState(() {
      filteredData = csvData.skip(1).where((row) {
        final cityMatch = selectedCity.isEmpty || row[12] == selectedCity;
        final providerMatch =
            selectedProvider.isEmpty || row[3] == selectedProvider;
        return cityMatch && providerMatch;
      }).toList();

      _updateMarkers();
      _isSearching = true;
    });
  }

  void _updateMarkers() {
    setState(() {
      markers = filteredData.map((row) {
        double latitude = double.tryParse(row[6].toString()) ?? 0.0;
        double longitude = double.tryParse(row[7].toString()) ?? 0.0;

        return Marker(
          width: 80,
          height: 80,
          point: LatLng(latitude, longitude),
          child: GestureDetector(
            onTap: () => _showDetailsDialog(row),
            child: Icon(
              Icons.location_on,
              color: Colors.red,
              size: 40,
            ),
          ),
        );
      }).toList();

      // Add user location marker
      markers.add(
        Marker(
          width: 80,
          height: 80,
          point: userLocation,
          child: Icon(
            Icons.person_pin_circle,
            color: Colors.blue,
            size: 40,
          ),
        ),
      );
    });
  }

  void _showDetailsDialog(List<dynamic> details) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(details[4]?.toString() ?? 'No Name'), // Ensure it's a String
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Location: ${details[5]?.toString() ?? 'N/A'}'),
              Text('City: ${details[12]?.toString() ?? 'N/A'}'),
              Text('Provider: ${details[3]?.toString() ?? 'N/A'}'),
              Text('Remarks: ${details[11]?.toString() ?? 'N/A'}'),
              Text('SSID: ${details[13]?.toString() ?? 'N/A'}'),
              Text('SourceID: ${details[14]?.toString() ?? 'N/A'}'),
              Text('Activated: ${details[15]?.toString() ?? 'N/A'}'),
              Text('BoroCode: ${details[16]?.toString() ?? 'N/A'}'),
              Text('BoroName: ${details[17]?.toString() ?? 'N/A'}'),
              Text('NTACode: ${details[18]?.toString() ?? 'N/A'}'),
              Text('NTAName: ${details[19]?.toString() ?? 'N/A'}'),
              Text('CounDist: ${details[20]?.toString() ?? 'N/A'}'),
              Text('Postcode: ${details[21]?.toString() ?? 'N/A'}'),
              Text('BoroCD: ${details[22]?.toString() ?? 'N/A'}'),
              Text('CT2010: ${details[23]?.toString() ?? 'N/A'}'),
              Text('BCTCB2010: ${details[24]?.toString() ?? 'N/A'}'),
              Text('BIN: ${details[25]?.toString() ?? 'N/A'}'),
              Text('BBL: ${details[26]?.toString() ?? 'N/A'}'),
              Text('DOITT_ID: ${details[27]?.toString() ?? 'N/A'}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }


  void _cancelSearch() {
    setState(() {
      markers = [
        Marker(
          width: 80,
          height: 80,
          point: userLocation,
          child: Icon(
            Icons.person_pin_circle,
            color: Colors.blue,
            size: 40,
          ),
        ),
      ];
      _isSearching = false;
      filteredData = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('WiFi Hotspots'),
        centerTitle: true,
        backgroundColor: Colors.orange,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.orange,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButton<String>(
                      value: selectedCity.isNotEmpty && cities.contains(selectedCity) ? selectedCity : null,
                      isExpanded: true,
                      hint: Text('Select City'),
                      onChanged: (value) {
                        setState(() {
                          selectedCity = value ?? '';
                          _filterData();
                        });
                      },
                      items: cities.map((city) {
                        return DropdownMenuItem(
                          value: city,
                          child: Text(city),
                        );
                      }).toList(),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: DropdownButton<String>(
                      value: selectedProvider.isNotEmpty && providers.contains(selectedProvider) ? selectedProvider : null,
                      isExpanded: true,
                      hint: Text('Select Provider'),
                      onChanged: (value) {
                        setState(() {
                          selectedProvider = value ?? '';
                          _filterData();
                        });
                      },
                      items: providers.map((provider) {
                        return DropdownMenuItem(
                          value: provider,
                          child: Text(provider),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: userLocation,
                    initialZoom: 12,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                      "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                      subdomains: ['a', 'b', 'c'],
                    ),
                    MarkerLayer(
                      markers: markers,
                    ),
                  ],
                ),
                if (_isSearching) ...[
                  Positioned(
                    bottom: 80,
                    right: 10,
                    child: FloatingActionButton(
                      onPressed: _cancelSearch,
                      child: Icon(Icons.cancel),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
