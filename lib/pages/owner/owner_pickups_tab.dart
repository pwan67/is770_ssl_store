import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/appointment.dart';
import '../../services/mock_service.dart';

class OwnerPickupsTab extends StatefulWidget {
  const OwnerPickupsTab({super.key});

  @override
  State<OwnerPickupsTab> createState() => _OwnerPickupsTabState();
}

class _OwnerPickupsTabState extends State<OwnerPickupsTab> {
  final MockService _service = MockService();

  Future<void> _completePickup(Appointment apt) async {
    try {
      await _service.completeAppointment(apt.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Completed pickup for ${apt.assetName}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to complete: $e')));
      }
    }
  }

  void _showCompleteDialog(Appointment apt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark Pickup as Completed?'),
        content: Text(
          'Are you sure you want to mark ${apt.assetName} as picked up by the customer?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              Navigator.pop(context);
              _completePickup(apt);
            },
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Appointment>>(
      stream: _service.getAllScheduledAppointmentsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading pickups: ${snapshot.error}'),
          );
        }

        final appointments = snapshot.data ?? [];

        if (appointments.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No Upcoming Pickups',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'All scheduled pickups have been processed.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // Group by Date for cleaner UI
        final groupedAppointments = <DateTime, List<Appointment>>{};
        for (var apt in appointments) {
          final dateKey = DateTime(apt.date.year, apt.date.month, apt.date.day);
          if (!groupedAppointments.containsKey(dateKey)) {
            groupedAppointments[dateKey] = [];
          }
          groupedAppointments[dateKey]!.add(apt);
        }

        final sortedDates = groupedAppointments.keys.toList()..sort();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedDates.length,
          itemBuilder: (context, index) {
            final dateKey = sortedDates[index];
            final dailyApts = groupedAppointments[dateKey]!;

            // Format section header (e.g., "Today", "Tomorrow", or Date)
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final tomorrow = today.add(const Duration(days: 1));

            String dateLabel;
            if (dateKey == today) {
              dateLabel = 'Today';
            } else if (dateKey == tomorrow) {
              dateLabel = 'Tomorrow';
            } else {
              dateLabel = DateFormat('EEEE, MMM d, yyyy').format(dateKey);
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 12.0),
                  child: Text(
                    dateLabel,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF800000),
                    ),
                  ),
                ),
                ...dailyApts.map((apt) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat('hh:mm a').format(apt.date),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.orange,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  apt.assetName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.person,
                                      size: 14,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Customer ID: ${apt.userId.substring(0, 5)}...',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text('Complete'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () => _showCompleteDialog(apt),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
              ],
            );
          },
        );
      },
    );
  }
}
