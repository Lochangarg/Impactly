import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import '../../../../l10n/app_localizations.dart';

class EventDiscoveryCard extends StatelessWidget {
  final ParseObject eventObject;
  final ParseUser? currentUser;
   final bool isJoined;
   final VoidCallback onJoin;
  
   const EventDiscoveryCard({
     super.key,
     required this.eventObject,
     required this.currentUser,
     required this.onJoin,
     this.isJoined = false,
   });

  String _formatDate(DateTime? date, AppLocalizations l10n) {
    if (date == null) return l10n.no_date;
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = eventObject.get<String>('title') ?? l10n.untitled;
    final location = eventObject.get<String>('location') ?? l10n.location;
    final points = eventObject.get<num>('points')?.toInt() ?? 0;
    final date = eventObject.get<DateTime>('date');
    final description = eventObject.get<String>('description') ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF3F4F6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event Image Placeholder
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Container(
              height: 160,
              width: double.infinity,
              color: const Color(0xFFF9FAFB),
              child: Stack(
                children: [
                  const Center(
                    child: Icon(Icons.image_outlined, color: Color(0xFFD1D5DB), size: 48),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.stars, color: Color(0xFFFBBF24), size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '+$points ${l10n.points_unit}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                    letterSpacing: -0.5,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF6B7280)),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(date, l10n),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF6B7280)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        location,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF4B5563),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                (() {
                  final eventOwner = eventObject.get<ParseObject>('createdBy');
                  final isOwner = eventOwner?.objectId == currentUser?.objectId;

                  return SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: (isOwner || isJoined) ? null : onJoin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (isOwner || isJoined) ? Colors.grey.shade300 : const Color(0xFF6366F1),
                        foregroundColor: (isOwner || isJoined) ? Colors.grey.shade600 : Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        isOwner 
                          ? l10n.your_event 
                          : (isJoined ? l10n.joined : l10n.join_event),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  );
                })(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

