import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import '../../core/services/parse_service.dart';

class EventAwardApprovalScreen extends StatefulWidget {
  final ParseObject event;
  const EventAwardApprovalScreen({super.key, required this.event});

  @override
  State<EventAwardApprovalScreen> createState() => _EventAwardApprovalScreenState();
}

class _EventAwardApprovalScreenState extends State<EventAwardApprovalScreen> {
  List<ParseObject> _pendingAwards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingAwards();
  }

  Future<void> _loadPendingAwards() async {
    final results = await ParseService.fetchPendingAwardsForEvent(widget.event.objectId!);
    if (mounted) {
      setState(() {
        _pendingAwards = results;
        _isLoading = false;
      });
    }
  }

  Future<void> _processAward(ParseObject userEvent, bool approve) async {
    bool success;
    if (approve) {
       // Default XP for event completion
       success = await ParseService.approveAward(userEvent, 200);
    } else {
       success = await ParseService.rejectAward(userEvent);
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
        title: Text('Approve Awards: ${widget.event.get('title')}'),
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
                    final user = award.get<ParseUser>('user');
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(user?.get<String>('fullName') ?? 'Unknown User'),
                        subtitle: Text('Completed on: ${award.get<DateTime>('completedAt')?.toLocal().toString().split('.')[0]}'),
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
