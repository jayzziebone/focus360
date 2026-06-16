import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shiftsync/core/constants/app_colors.dart';
import 'package:shiftsync/features/admin/presentation/providers/admin_provider.dart';
import 'package:shiftsync/features/auth/data/models/user_model.dart';

class OnboardEmployerScreen extends ConsumerStatefulWidget {
  const OnboardEmployerScreen({super.key});

  @override
  ConsumerState<OnboardEmployerScreen> createState() => _OnboardEmployerScreenState();
}

class _OnboardEmployerScreenState extends ConsumerState<OnboardEmployerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _employerIdController = TextEditingController();
  final _latitudeController = TextEditingController(text: '37.7749');
  final _longitudeController = TextEditingController(text: '-122.4194');
  final MapController _mapController = MapController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _employerIdController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Onboard Employer',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.secondary),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Panel
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: AppColors.primary.withOpacity(0.15)),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.05),
                          AppColors.primaryContainer.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.business_center, color: AppColors.primary, size: 32),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Organization Information',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.secondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Onboard a new corporate firm to assign work locations and shifts.',
                                style: TextStyle(fontSize: 12, color: AppColors.outline),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Organization/Company Name',
                    prefixIcon: Icon(Icons.business),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Company name is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    if (!RegExp(r'^[\w-\.\+]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Login Password',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  validator: (v) => v == null || v.length < 6 ? 'Password must be at least 6 characters' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _employerIdController,
                  decoration: const InputDecoration(
                    labelText: 'Custom Employer ID (Optional)',
                    prefixIcon: Icon(Icons.badge),
                    hintText: 'Leave blank to auto-generate',
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Corporate Location coordinates',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.secondary),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latitudeController,
                        decoration: const InputDecoration(
                          labelText: 'Latitude',
                          prefixIcon: Icon(Icons.explore),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (val) {
                          final lat = double.tryParse(_latitudeController.text);
                          final lng = double.tryParse(_longitudeController.text);
                          if (lat != null && lng != null) {
                            _mapController.move(LatLng(lat, lng), _mapController.camera.zoom);
                          }
                          setState(() {});
                        },
                        validator: (v) => v == null || double.tryParse(v) == null ? 'Invalid latitude' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _longitudeController,
                        decoration: const InputDecoration(
                          labelText: 'Longitude',
                          prefixIcon: Icon(Icons.explore),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (val) {
                          final lat = double.tryParse(_latitudeController.text);
                          final lng = double.tryParse(_longitudeController.text);
                          if (lat != null && lng != null) {
                            _mapController.move(LatLng(lat, lng), _mapController.camera.zoom);
                          }
                          setState(() {});
                        },
                        validator: (v) => v == null || double.tryParse(v) == null ? 'Invalid longitude' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tap map to pinpoint employer headquarters location:',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.outline),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withOpacity(0.15)),
                    ),
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: LatLng(
                          double.tryParse(_latitudeController.text) ?? 37.7749,
                          double.tryParse(_longitudeController.text) ?? -122.4194,
                        ),
                        initialZoom: 12.0,
                        maxZoom: 18.0,
                        minZoom: 2.0,
                        onTap: (tapPosition, point) {
                          setState(() {
                            _latitudeController.text = point.latitude.toStringAsFixed(6);
                            _longitudeController.text = point.longitude.toStringAsFixed(6);
                          });
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.focus360.app',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(
                                double.tryParse(_latitudeController.text) ?? 37.7749,
                                double.tryParse(_longitudeController.text) ?? -122.4194,
                              ),
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
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isLoading
                        ? null
                        : () async {
                            if (_formKey.currentState!.validate()) {
                              setState(() => _isLoading = true);
                              try {
                                final adminRepo = ref.read(adminRepositoryProvider);
                                await adminRepo.onboardUser(
                                  email: _emailController.text.trim(),
                                  password: _passwordController.text,
                                  fullName: _nameController.text.trim(),
                                  role: UserRole.employer,
                                  employerId: _employerIdController.text.trim().isEmpty ? null : _employerIdController.text.trim(),
                                  latitude: double.tryParse(_latitudeController.text.trim()),
                                  longitude: double.tryParse(_longitudeController.text.trim()),
                                );
                                if (mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Onboarded employer "${_nameController.text}" successfully!'),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                                );
                              } finally {
                                if (mounted) {
                                  setState(() => _isLoading = false);
                                }
                              }
                            }
                          },
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('ONBOARD EMPLOYER', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
