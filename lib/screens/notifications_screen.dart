import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: ListView.builder(
        itemCount: 10, // Placeholder count
        itemBuilder: (context, index) {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey[800],
              child: const Icon(Icons.person, color: Colors.white70),
            ),
            title: Text(
              'User ${index + 1}',
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              index % 2 == 0
                  ? 'liked your post'
                  : 'started following you',
              style: TextStyle(color: Colors.grey[400]),
            ),
            trailing: Text(
              '${index + 1}m ago',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
            ),
            onTap: () {
              // TODO: Handle notification tap
            },
          );
        },
      ),
    );
  }
} 