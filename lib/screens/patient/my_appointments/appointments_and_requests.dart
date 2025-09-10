import 'package:flutter/material.dart';
import 'appointments_tab.dart';
import 'service_requests_tab.dart';

class AppointmentsAndRequestsScreen extends StatelessWidget {
  const AppointmentsAndRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Appointments / Requests'),
          bottom: const TabBar(
            indicatorColor: Colors.white, // Underline color
            labelColor: Colors.white, // Selected tab text color
            unselectedLabelColor: Colors.white70, // Unselected tab text color
            tabs: [Tab(text: 'Appointments'), Tab(text: 'Service Requests')],
          ),
        ),
        body: const TabBarView(
          children: [AppointmentsTab(), ServiceRequestsTab()],
        ),
      ),
    );
  }
}
