import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
                  category,
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
                    '+$points pts',
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
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF6B7280)),
              const SizedBox(width: 6),
              Text(
                date,
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF6B7280)),
              const SizedBox(width: 6),
              Text(
                location,
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (isLoading || isOwner || isJoined) ? null : onJoin,
              style: ElevatedButton.styleFrom(
                backgroundColor: (isOwner || isJoined) ? Colors.grey.shade300 : const Color(0xFF6366F1),
                foregroundColor: (isOwner || isJoined) ? Colors.grey.shade600 : Colors.white,
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
                      ? AppConstants.ownerLabel 
                      : (isJoined ? AppConstants.joinedLabel : AppConstants.joinEventLabel), 
                    style: const TextStyle(fontWeight: FontWeight.bold)
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
