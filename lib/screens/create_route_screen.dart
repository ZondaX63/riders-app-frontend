import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class CreateRouteScreen extends StatefulWidget {
  const CreateRouteScreen({super.key});

  @override
  State<CreateRouteScreen> createState() => _CreateRouteScreenState();
}

class _CreateRouteScreenState extends State<CreateRouteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<LatLng> _waypoints = [];
  bool _isPublic = true;
  bool _isSaving = false;

  void _addWaypoint(LatLng point) {
    setState(() {
      _waypoints.add(point);
    });
  }

  void _removeLastWaypoint() {
    if (_waypoints.isNotEmpty) {
      setState(() {
        _waypoints.removeLast();
      });
    }
  }

  Future<void> _saveRoute() async {
    if (!_formKey.currentState!.validate()) return;
    if (_waypoints.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En az 2 nokta eklemelisiniz')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final List<Map<String, dynamic>> waypointsJson = [];
      for (int i = 0; i < _waypoints.length; i++) {
        waypointsJson.add({
          'latitude': _waypoints[i].latitude,
          'longitude': _waypoints[i].longitude,
          'name': i == 0
              ? 'Başlangıç'
              : (i == _waypoints.length - 1 ? 'Bitiş' : 'Nokta ${i + 1}'),
          'order': i,
        });
      }

      await context.read<ApiService>().createRoute(
            name: _nameController.text,
            description: _descriptionController.text,
            waypoints: waypointsJson,
            isPublic: _isPublic,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rota başarıyla oluşturuldu')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Rota Oluştur'),
        actions: [
          if (_waypoints.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.undo),
              onPressed: _removeLastWaypoint,
              tooltip: 'Son noktayı geri al',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Rota Adı',
                      hintText: 'Örn: Pazar Sürüşü',
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Gerekli' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Açıklama (İsteğe bağlı)',
                    ),
                    maxLines: 2,
                  ),
                  Row(
                    children: [
                      const Text('Herkese Açık'),
                      Switch(
                        value: _isPublic,
                        onChanged: (v) => setState(() => _isPublic = v),
                        activeThumbColor: AppTheme.primaryOrange,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Haritaya dokunarak rota noktalarını belirleyin.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    options: MapOptions(
                      initialCenter: const LatLng(41.0082, 28.9784),
                      initialZoom: 13.0,
                      onTap: (tapPosition, point) => _addWaypoint(point),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.riders.app',
                      ),
                      if (_waypoints.length >= 2)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _waypoints,
                              color: AppTheme.primaryOrange,
                              strokeWidth: 4.0,
                            ),
                          ],
                        ),
                      MarkerLayer(
                        markers: _waypoints.asMap().entries.map((entry) {
                          int idx = entry.key;
                          LatLng point = entry.value;
                          bool isStart = idx == 0;
                          bool isEnd = idx == _waypoints.length - 1 &&
                              _waypoints.length > 1;

                          return Marker(
                            point: point,
                            width: 30,
                            height: 30,
                            child: Icon(
                              isStart
                                  ? Icons.play_circle_fill
                                  : (isEnd
                                      ? Icons.stop_circle
                                      : Icons.location_on),
                              color: isStart
                                  ? Colors.green
                                  : (isEnd
                                      ? Colors.red
                                      : AppTheme.primaryOrange),
                              size: 24,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  if (_isSaving)
                    Container(
                      color: Colors.black45,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _saveRoute,
        label: const Text('Kaydet'),
        icon: const Icon(Icons.save),
        backgroundColor: AppTheme.primaryOrange,
      ),
    );
  }
}
