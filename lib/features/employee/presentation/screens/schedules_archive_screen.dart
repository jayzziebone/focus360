import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shiftsync/core/constants/app_colors.dart';
import 'package:shiftsync/features/employee/presentation/providers/employee_provider.dart';
import 'package:shiftsync/features/employee/data/models/shift_model.dart';
import 'package:shiftsync/features/employee/data/models/attendance_record_model.dart';
import 'package:shiftsync/features/admin/data/models/location_model.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class SchedulesArchiveScreen extends ConsumerStatefulWidget {
  const SchedulesArchiveScreen({super.key});

  @override
  ConsumerState<SchedulesArchiveScreen> createState() => _SchedulesArchiveScreenState();
}

class _SchedulesArchiveScreenState extends ConsumerState<SchedulesArchiveScreen> {
  @override
  Widget build(BuildContext context) {
    final shiftsStream = ref.watch(employeeShiftsProvider);
    final attendanceHistoryAsync = ref.watch(employeeAttendanceHistoryProvider);
    final locationsAsync = ref.watch(employeeLocationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Schedule Archive',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.secondary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.secondary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Past shifts history',
                style: TextStyle(color: AppColors.outline),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: shiftsStream.when(
                  data: (list) {
                    final attendanceList = attendanceHistoryAsync.value ?? [];

                    // Filter for completed or missed shifts
                    final archivedList = list.where((shift) {
                      final matchingRecord = attendanceList.firstWhere(
                        (r) => r.shiftId == shift.id,
                        orElse: () => AttendanceRecordModel(
                          id: '',
                          employeeId: '',
                          employeeName: '',
                          employerId: '',
                          shiftId: '',
                          punchInTime: DateTime.fromMillisecondsSinceEpoch(0),
                          punchInLatitude: 0,
                          punchInLongitude: 0,
                          punchInVerified: false,
                          approvedStatus: 'pending',
                        ),
                      );

                      if (matchingRecord.id.isNotEmpty) {
                        if (matchingRecord.punchInTime != null && matchingRecord.punchOutTime != null) {
                          return true; // completed shift
                        }
                        return false; // in progress
                      } else {
                        if (shift.endTime.isBefore(DateTime.now())) {
                          return true; // missed shift
                        }
                        return false; // scheduled
                      }
                    }).toList();

                    if (archivedList.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history, size: 64, color: AppColors.outline.withOpacity(0.5)),
                            const SizedBox(height: 16),
                            const Text('No archived shifts.', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            const Text(
                              'Completed or missed shifts will appear here.',
                              style: TextStyle(fontSize: 12, color: AppColors.outline),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    // Sort shifts from recent to past (descending chronological order)
                    final sortedList = List<ShiftModel>.from(archivedList)
                      ..sort((a, b) => b.startTime.compareTo(a.startTime));

                    return ListView.builder(
                      itemCount: sortedList.length,
                      itemBuilder: (context, index) {
                        final shift = sortedList[index];
                        final formattedDate = DateFormat('EEEE, MMM d, y').format(shift.startTime);
                        final formattedTime =
                            '${DateFormat('hh:mm a').format(shift.startTime)} - ${DateFormat('hh:mm a').format(shift.endTime)}';

                        final matchingRecord = attendanceList.firstWhere(
                          (r) => r.shiftId == shift.id,
                          orElse: () => AttendanceRecordModel(
                            id: '',
                            employeeId: '',
                            employeeName: '',
                            employerId: '',
                            shiftId: '',
                            punchInTime: DateTime.fromMillisecondsSinceEpoch(0),
                            punchInLatitude: 0,
                            punchInLongitude: 0,
                            punchInVerified: false,
                            approvedStatus: 'pending',
                          ),
                        );

                        // Compute dynamic operational status
                        String displayStatus = 'MISSED';
                        Color statusColor = AppColors.error;
                        Color statusBgColor = AppColors.error.withOpacity(0.15);

                        if (matchingRecord.id.isNotEmpty) {
                          if (matchingRecord.punchInTime != null && matchingRecord.punchOutTime != null) {
                            displayStatus = 'COMPLETED';
                            statusColor = AppColors.success;
                            statusBgColor = AppColors.success.withOpacity(0.15);
                          }
                        }

                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: AppColors.secondary.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          margin: const EdgeInsets.only(bottom: 12),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () async {
                              LocationModel? location;
                              final localLocations = locationsAsync.value ?? [];
                              final matched = localLocations.where((l) => l.id == shift.locationId).toList();

                              if (matched.isNotEmpty) {
                                location = matched.first;
                              } else {
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                                try {
                                  final repo = ref.read(employeeRepositoryProvider);
                                  location = await repo.getLocationById(shift.locationId);
                                } catch (e) {
                                  print('=== [DEBUG] Error fetching location details: $e ===');
                                }
                                if (mounted) {
                                  Navigator.pop(context); // Dismiss loading indicator
                                }
                              }

                              // Fallback to dummy model if still not found
                              location ??= LocationModel(
                                id: shift.locationId,
                                name: shift.locationName,
                                address: 'Address not loaded',
                                latitude: 0.0,
                                longitude: 0.0,
                                radiusMeters: 100,
                                employerId: '',
                              );

                              if (mounted) {
                                _showLocationDialog(context, shift, location);
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              title: Text(
                                formattedDate,
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(formattedTime, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.pin_drop, size: 14, color: AppColors.outline),
                                      const SizedBox(width: 4),
                                      Expanded(child: Text(shift.locationName, style: const TextStyle(fontSize: 12))),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusBgColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  displayStatus,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  error: (err, _) => Center(
                    child: Text(
                      'Error loading schedules: $err',
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showLocationDialog(BuildContext context, ShiftModel shift, LocationModel location) {
    showDialog(
      context: context,
      builder: (context) {
        final formattedDate = DateFormat('EEEE, MMM d, y').format(shift.startTime);
        final formattedTime =
            '${DateFormat('hh:mm a').format(shift.startTime)} - ${DateFormat('hh:mm a').format(shift.endTime)}';

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: AppColors.background,
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryContainer],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.pin_drop_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      location.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'SHIFT LOCATION METRICS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withOpacity(0.8),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                formattedDate,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.secondary,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                formattedTime,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.home_work_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Workplace Address',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.secondary,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                location.address,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.outline,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        const Icon(Icons.radar_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'GPS Geofencing Metrics',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.secondary,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Coordinates: ${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                  color: AppColors.outline,
                                ),
                              ),
                              Text(
                                'Allowed punch radius: ${location.radiusMeters} meters',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primary.withOpacity(0.15)),
                        ),
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: LatLng(location.latitude, location.longitude),
                            initialZoom: 15.0,
                            maxZoom: 18.0,
                            minZoom: 10.0,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.focus360.app',
                            ),
                            CircleLayer(
                              circles: [
                                CircleMarker(
                                  point: LatLng(location.latitude, location.longitude),
                                  color: AppColors.primary.withOpacity(0.2),
                                  borderStrokeWidth: 2,
                                  borderColor: AppColors.primary,
                                  useRadiusInMeter: true,
                                  radius: location.radiusMeters.toDouble(),
                                ),
                              ],
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(location.latitude, location.longitude),
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
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () async {
                              await Clipboard.setData(ClipboardData(
                                text: '${location.latitude}, ${location.longitude}',
                              ));
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Coordinates copied to clipboard!'),
                                    backgroundColor: AppColors.success,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                                Navigator.pop(context);
                              }
                            },
                            icon: const Icon(Icons.copy_rounded, size: 18),
                            label: const Text('COPY GPS'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () async {
                              final Uri googleMapsUri = Uri.parse(
                                'https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}',
                              );
                              final Uri appleMapsUri = Uri.parse(
                                'https://maps.apple.com/?q=${location.latitude},${location.longitude}',
                              );

                              if (await canLaunchUrl(googleMapsUri)) {
                                await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
                              } else if (await canLaunchUrl(appleMapsUri)) {
                                await launchUrl(appleMapsUri, mode: LaunchMode.externalApplication);
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Could not open map applications.')),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.map_rounded, size: 18),
                            label: const Text('MAP DIRECTIONS'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
