import 'package:flutter/material.dart';
import 'package:scentview/services/api_service.dart';

class SubscribersScreen extends StatefulWidget {
  const SubscribersScreen({Key? key}) : super(key: key);

  @override
  State<SubscribersScreen> createState() => _SubscribersScreenState();
}

class _SubscribersScreenState extends State<SubscribersScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _subscribersFuture;

  @override
  void initState() {
    super.initState();
    _loadSubscribers();
  }

  void _loadSubscribers() {
    setState(() {
      _subscribersFuture = _apiService.fetchSubscribers();
    });
  }

  Future<void> _deleteSubscriber(dynamic id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subscriber'),
        content: const Text('Are you sure you want to remove this email from the newsletter?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _apiService.deleteSubscriber(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Subscriber deleted successfully')),
          );
          _loadSubscribers();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: const Text('Newsletter Subscribers', style: TextStyle(color: Color(0xFF1A1D2E), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1D2E)),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _subscribersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B9D)));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final subscribers = snapshot.data ?? [];
          if (subscribers.isEmpty) {
            return const Center(child: Text('No subscribers found.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: subscribers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final sub = subscribers[index];
              final email = sub['email'] ?? 'No Email';
              final id = sub['id'];

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFF3E5F5),
                    child: Icon(Icons.email_outlined, color: Colors.purple.shade400, size: 20),
                  ),
                  title: Text(email, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text('Subscribed on: ${sub['created_at']?.split('T')[0] ?? 'N/A'}', style: const TextStyle(fontSize: 12)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => _deleteSubscriber(id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
