import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/update_model.dart';

class UpdateDialog extends StatelessWidget {
  final UpdateModel update;
  const UpdateDialog({super.key, required this.update});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !update.forceUpdate,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        title: Row(
          children: [
            const Icon(Icons.system_update_rounded, color: Color(0xFF6366F1)),
            const SizedBox(width: 12),
            const Text('Update Available', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A new version (${update.latestVersion}) is ready.',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Text(
              update.message,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
        actions: [
          if (!update.forceUpdate)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Later', style: TextStyle(color: Colors.grey[600])),
            ),
          ElevatedButton(
            onPressed: () async {
              final url = Uri.parse(update.updateUrl);
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Update Now'),
          ),
        ],
      ),
    );
  }
}
