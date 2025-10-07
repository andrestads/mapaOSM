import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../viewmodels/location_viewmodel.dart';

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  LocationViewModel? _locationViewModel;

  void _onLocationChanged() {
    if (_locationViewModel != null && _locationViewModel!.location != null) {
      final newLocation = LatLng(
        _locationViewModel!.location!.latitude,
        _locationViewModel!.location!.longitude,
      );
      _mapController.move(newLocation, _mapController.camera.zoom);
    }
  }
  
  @override
  void initState() {
    super.initState();
    _locationViewModel = Provider.of<LocationViewModel>(context, listen: false);
  }

  @override
  void dispose() {
    _locationViewModel?.removeListener(_onLocationChanged);
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _searchLocation(String query) async {
    FocusScope.of(context).unfocus();
    try {
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        _mapController.move(
          LatLng(locations.first.latitude, locations.first.longitude),
          16,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Localização não encontrada')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao buscar a localização')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocationViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading && viewModel.location == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (viewModel.location == null) {
          return const Center(
            child: Text('Não foi possível obter a localização.'),
          );
        }
        
        final currentLocation = LatLng(viewModel.location!.latitude, viewModel.location!.longitude);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Pesquisar localização',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () => _searchLocation(_searchController.text),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onSubmitted: _searchLocation,
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
              child: Text(viewModel.address,
                  style: Theme.of(context).textTheme.bodySmall),
            ),
            Expanded(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: currentLocation,
                  initialZoom: 16,
                  onMapReady: () {
                    _locationViewModel?.addListener(_onLocationChanged);
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c'],
                    userAgentPackageName: 'br.edu.ifsul.flutter_mapas_osm',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: currentLocation,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_pin,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}