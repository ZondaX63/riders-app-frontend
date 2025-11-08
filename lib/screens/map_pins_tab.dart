import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/map_pin_provider.dart';

class MapPinsTab extends StatefulWidget {
  const MapPinsTab({super.key});

  @override
  State<MapPinsTab> createState() => _MapPinsTabState();
}

class _MapPinsTabState extends State<MapPinsTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  static const LatLng _defaultCenter = LatLng(41.0082, 28.9784);
  static const double _defaultZoom = 12.5;
  static const int _defaultRadius = 5000;
  static const Map<String, String> _typeLabels = {
    'meetup': 'Meetup',
    'hazard': 'Hazard',
    'checkpoint': 'Checkpoint',
    'fuel': 'Fuel',
    'food': 'Food',
    'custom': 'Custom',
  };

  final MapController _mapController = MapController();
  late final StreamSubscription<MapEvent> _mapSubscription;
  LatLng _currentCenter = _defaultCenter;
  bool _mapReady = false;
  bool _locating = false;
  String? _locationError;
  final Set<String> _selectedTypes = {};

  @override
  void initState() {
    super.initState();
    _mapSubscription = _mapController.mapEventStream.listen((event) {
      _currentCenter = event.camera.center;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<MapPinProvider>();
      provider.loadNearbyPins(
        latitude: _currentCenter.latitude,
        longitude: _currentCenter.longitude,
        radius: _defaultRadius,
      );
      provider.loadMyPins();
    });
  }

  @override
  void dispose() {
    _mapSubscription.cancel();
    super.dispose();
  }

  Future<void> _refreshPins() async {
    final provider = context.read<MapPinProvider>();
    final center = _mapReady ? _mapController.camera.center : _currentCenter;
    await provider.loadNearbyPins(
      latitude: center.latitude,
      longitude: center.longitude,
      radius: _defaultRadius,
      types: _selectedTypes.isEmpty ? null : _selectedTypes.toList(),
    );
  }

  Future<void> _showAddPinDialog() async {
    final center = _mapReady ? _mapController.camera.center : _currentCenter;
    
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddPinForm(
        latitude: center.latitude,
        longitude: center.longitude,
        onPinAdded: () {
          _refreshPins();
          context.read<MapPinProvider>().loadMyPins();
        },
      ),
    );
  }

  Future<void> _locateUser() async {
    setState(() {
      _locating = true;
      _locationError = null;
    });

    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        throw Exception('Location services are disabled');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }

      final position = await Geolocator.getCurrentPosition();
      final target = LatLng(position.latitude, position.longitude);

      if (mounted) {
        _mapController.move(target, _defaultZoom);
        setState(() {
          _currentCenter = target;
        });
        await _refreshPins();
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _locationError = error.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _locating = false;
        });
      }
    }
  }

  void _toggleType(String type) {
    setState(() {
      if (_selectedTypes.contains(type)) {
        _selectedTypes.remove(type);
      } else {
        _selectedTypes.add(type);
      }
    });
    _refreshPins();
  }

  Color _pinColor(String type) {
    switch (type) {
      case 'hazard':
        return Colors.redAccent;
      case 'checkpoint':
        return Colors.blueAccent;
      case 'fuel':
        return Colors.greenAccent;
      case 'food':
        return Colors.orangeAccent;
      case 'meetup':
        return Colors.purpleAccent;
      default:
        return Colors.amberAccent;
    }
  }

  IconData _pinIcon(String type) {
    switch (type) {
      case 'hazard':
        return Icons.warning_amber_rounded;
      case 'checkpoint':
        return Icons.flag;
      case 'fuel':
        return Icons.local_gas_station;
      case 'food':
        return Icons.restaurant;
      case 'meetup':
        return Icons.groups;
      default:
        return Icons.place;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Consumer<MapPinProvider>(
      builder: (context, provider, _) {
        final nearbyPins = provider.nearbyPins;
        final loading = provider.isLoadingNearby;
        final error = provider.nearbyError;

        return Column(
          children: [
            SizedBox(
              height: 56,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                scrollDirection: Axis.horizontal,
                children: _typeLabels.entries.map((entry) {
                  final selected = _selectedTypes.contains(entry.key);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(entry.value),
                      selected: selected,
                      onSelected: (_) => _toggleType(entry.key),
                      selectedColor: _pinColor(entry.key).withOpacity(0.2),
                      checkmarkColor: Colors.white,
                    ),
                  );
                }).toList()
                  ..insert(
                    0,
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('All'),
                        selected: _selectedTypes.isEmpty,
                        onSelected: (_) {
                          setState(() {
                            _selectedTypes.clear();
                          });
                          _refreshPins();
                        },
                      ),
                    ),
                  ),
              ),
            ),
            if (_locationError != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _locationError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _defaultCenter,
                      initialZoom: _defaultZoom,
                      maxZoom: 18,
                      minZoom: 3,
                      onMapReady: () {
                        setState(() => _mapReady = true);
                        _currentCenter = _mapController.camera.center;
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.riders.social',
                      ),
                      MarkerLayer(
                        markers: nearbyPins
                            .map(
                              (pin) => Marker(
                                point: LatLng(pin.latitude, pin.longitude),
                                width: 48,
                                height: 48,
                                child: Tooltip(
                                  message: pin.title,
                                  child: Icon(
                                    Icons.location_on,
                                    color: _pinColor(pin.type),
                                    size: 36,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                  Positioned(
                    right: 16,
                    top: 16,
                    child: Column(
                      children: [
                        FloatingActionButton.small(
                          heroTag: 'add-pin',
                          onPressed: () => _showAddPinDialog(),
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: const Icon(Icons.add_location_alt),
                        ),
                        const SizedBox(height: 8),
                        FloatingActionButton.small(
                          heroTag: 'locate-pins',
                          onPressed: _locating ? null : _locateUser,
                          child: _locating
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.my_location),
                        ),
                      ],
                    ),
                  ),
                  if (loading)
                    const Positioned.fill(
                      child: IgnorePointer(
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                  if (error != null && !loading)
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Card(
                        color: Colors.redAccent.withOpacity(0.2),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(error, style: const TextStyle(color: Colors.white)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(
              height: 140,
              child: nearbyPins.isEmpty
                  ? Center(
                      child: Text(
                        loading ? 'Loading pins...' : 'No pins nearby',
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) {
                        final pin = nearbyPins[index];
                        return Container(
                          width: 220,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _pinColor(pin.type).withOpacity(0.4)),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(_pinIcon(pin.type), color: _pinColor(pin.type), size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      pin.title,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (pin.description != null && pin.description!.isNotEmpty)
                                Text(
                                  pin.description!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                            ],
                          ),
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemCount: nearbyPins.length,
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _AddPinForm extends StatefulWidget {
  final double latitude;
  final double longitude;
  final VoidCallback onPinAdded;

  const _AddPinForm({
    required this.latitude,
    required this.longitude,
    required this.onPinAdded,
  });

  @override
  State<_AddPinForm> createState() => _AddPinFormState();
}

class _AddPinFormState extends State<_AddPinForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedType = 'custom';
  bool _isPublic = true;
  bool _isSubmitting = false;
  
  static const Map<String, String> _typeLabels = {
    'meetup': 'Meetup Point',
    'hazard': 'Hazard Warning',
    'checkpoint': 'Checkpoint',
    'fuel': 'Fuel Station',
    'food': 'Food/Restaurant',
    'custom': 'Custom',
  };

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitPin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final provider = context.read<MapPinProvider>();
      await provider.createPin(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        latitude: widget.latitude,
        longitude: widget.longitude,
        type: _selectedType,
        isPublic: _isPublic,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onPinAdded();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pin başarıyla eklendi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Yeni Pin Ekle',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Pin Type
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Pin Tipi',
                  border: OutlineInputBorder(),
                ),
                items: _typeLabels.entries
                    .map((e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedType = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              
              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Başlık *',
                  border: OutlineInputBorder(),
                  hintText: 'Pin başlığı',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Başlık gerekli';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                  border: OutlineInputBorder(),
                  hintText: 'Detaylı açıklama (opsiyonel)',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              
              // Location Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Konum',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Lat: ${widget.latitude.toStringAsFixed(6)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      'Lng: ${widget.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Public Toggle
              SwitchListTile(
                title: const Text('Herkese Açık'),
                subtitle: const Text('Diğer kullanıcılar bu pin\'i görebilir'),
                value: _isPublic,
                onChanged: (value) => setState(() => _isPublic = value),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 24),
              
              // Submit Button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitPin,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Pin Ekle'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
