import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/gold_asset.dart';
import '../models/appointment.dart';
import '../services/mock_service.dart';

class AppointmentPage extends StatefulWidget {
  const AppointmentPage({super.key});

  @override
  State<AppointmentPage> createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  final MockService _service = MockService();

  GoldAsset? _passedAsset;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isProcessing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is GoldAsset) {
      _passedAsset = args;
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );
    if (picked != null) {
      // Validate store hours (e.g., 9 AM to 5 PM)
      if (picked.hour < 9 || picked.hour >= 17) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a time within store hours (09:00 - 17:00)')),
          );
        }
        return;
      }
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _confirmAppointment() async {
    if (_passedAsset == null || _selectedDate == null || _selectedTime == null) return;

    setState(() => _isProcessing = true);
    
    try {
      final combinedDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      await _service.createAppointment(
        asset: _passedAsset!,
        appointmentDate: combinedDateTime,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Appointment Scheduled Successfully!')));
        setState(() {
          _passedAsset = null; // Clear booking form
          _selectedDate = null;
          _selectedTime = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: _passedAsset != null ? 0 : 1,
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF800000),
          foregroundColor: Colors.white,
          title: const Text('Store Appointments'),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Color(0xFFFFD700),
            tabs: [
              Tab(text: 'Book Pickup', icon: Icon(Icons.add_shopping_cart)),
              Tab(text: 'My Schedule', icon: Icon(Icons.calendar_month)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildBookingTab(),
            _buildMyScheduleTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingTab() {
    if (_passedAsset == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inventory, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No Asset Selected',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Please go to your Portfolio and select "Pick Up In Store" on an owned asset to schedule a pickup.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Asset to Pick Up', style: TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text(_passedAsset!.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF800000))),
                  Text('Weight: ${_passedAsset!.weight} Baht', style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Select Date & Time', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today),
                  label: Text(_selectedDate == null ? 'Select Date' : DateFormat('dd MMM yyyy').format(_selectedDate!)),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickTime,
                  icon: const Icon(Icons.access_time),
                  label: Text(_selectedTime == null ? 'Select Time\n(09:00-17:00)' : _selectedTime!.format(context), textAlign: TextAlign.center,),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: (_selectedDate != null && _selectedTime != null && !_isProcessing) ? _confirmAppointment : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF800000),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
            ),
            child: _isProcessing 
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Confirm Pickup Appointment', style: TextStyle(fontSize: 16, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildMyScheduleTab() {
    return StreamBuilder<List<Appointment>>(
      stream: _service.getAppointmentsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading appointments: ${snapshot.error}'));
        }

        final appointments = snapshot.data ?? [];

        if (appointments.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.event_available, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No Upcoming Appointments', style: TextStyle(fontSize: 18, color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: appointments.length,
          itemBuilder: (context, index) {
            final apt = appointments[index];
            final isFuture = apt.date.isAfter(DateTime.now());
            final color = apt.status == 'completed' ? Colors.green : (isFuture ? Colors.blue : Colors.grey);
            final icon = apt.status == 'completed' ? Icons.check_circle : (isFuture ? Icons.schedule : Icons.history);

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: color.withOpacity(0.1),
                  child: Icon(icon, color: color),
                ),
                title: Text(apt.assetName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(DateFormat('EEEE, dd MMM yyyy • hh:mm a').format(apt.date)),
                    Text('Status: ${apt.status.toUpperCase()}', style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
