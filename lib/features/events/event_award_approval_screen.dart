import 'package:flutter/material.dart';
import '../../core/services/supabase_service.dart';

class EventAwardApprovalScreen extends StatefulWidget {
  final Map<String, dynamic> event;
  const EventAwardApprovalScreen({super.key, required this.event});

  @override
  State<EventAwardApprovalScreen> createState() => _EventAwardApprovalScreenState();
}

class _EventAwardApprovalScreenState extends State<EventAwardApprovalScreen> {
  List<Map<String, dynamic>> _pendingAwards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingAwards();
  }

  Future<void> _loadPendingAwards() async {
    final results = await SupabaseService.fetchPendingAwardsForEvent(widget.event['id'].toString());
    if (mounted) {
      setState(() {
        _pendingAwards = results;
        _isLoading = false;
      });
    }
  }

  Future<void> _processAward(Map<String, dynamic> award, bool approve) async {
    bool success;
    final eventId = award['event_id'].toString();
    final userId = award['user_id'].toString();
    final points = (widget.event['points'] ?? 200).toInt();

    if (approve) {
       success = await SupabaseService.approveAward(eventId, userId, points);
    } else {
       success = await SupabaseService.rejectAward(eventId, userId);
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(approve ? 'Award Approved!' : 'Award Rejected')),
      );
      _loadPendingAwards();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Approve Awards: ${widget.event['title']}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingAwards.isEmpty
              ? const Center(child: Text('No pending awards for this event.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _pendingAwards.length,
                  itemBuilder: (context, index) {
                    final award = _pendingAwards[index];
                    final profile = award['profiles'];
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(profile?['full_name'] ?? 'Unknown User'),
                        subtitle: Text('Joined on: ${(award['joined_at'] ?? award['created_at']) != null ? (award['joined_at'] ?? award['created_at']).toString().split('T')[0] : 'Unknown'}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check_circle, color: Colors.green),
                              onPressed: () => _processAward(award, true),
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              onPressed: () => _processAward(award, false),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
