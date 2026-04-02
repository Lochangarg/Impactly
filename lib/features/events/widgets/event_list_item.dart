import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

class EventListItem extends StatelessWidget {
  final String title;
  final String date;
  final String location;
  final int points;
  final String category;
  final bool isOwner;
  final VoidCallback? onJoin;
  final bool isJoined;
  final bool isLoading;

  const EventListItem({
    super.key,
    required this.title,
    required this.date,
    required this.location,
    required this.points,
    required this.category,
    this.isOwner = false,
    this.isJoined = false,
    this.onJoin,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  () {
                    switch (category) {
                      case 'Cleaning': return l10n.cleaning;
                      case 'Workshops': return l10n.workshops;
                      case 'Volunteering': return l10n.volunteering;
                      case 'Music': return l10n.music;
                      case 'Social': return l10n.social;
                      case 'All': return l10n.all;
                      default: return category;
                    }
                  }(),
                  style: const TextStyle(
                    color: Color(0xFF6366F1),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.stars, color: Color(0xFFF59E0B), size: 16),
                  const SizedBox(width: 4),
                  Text(
                    l10n.points_count(points),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
              const SizedBox(width: 6),
              Text(
                date,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
              const SizedBox(width: 6),
              Text(
                location,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (isLoading || isOwner || isJoined) ? null : onJoin,
              style: ElevatedButton.styleFrom(
                backgroundColor: (isOwner || isJoined) ? Theme.of(context).dividerColor : const Color(0xFF6366F1),
                foregroundColor: (isOwner || isJoined) ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(
                    isOwner 
                      ? l10n.created_by_you 
                      : (isJoined ? l10n.joined : l10n.join_event), 
                    style: const TextStyle(fontWeight: FontWeight.bold)
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
