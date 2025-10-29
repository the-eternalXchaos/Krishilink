import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:krishi_link/src/core/components/bottom_sheet/app_bottom_sheet.dart';
import 'package:krishi_link/src/features/product/data/models/review_model.dart';

class ReviewCard extends StatelessWidget {
  final ReviewModel review;
  final String? currentUserId;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onReport;
  final bool showMenu;

  const ReviewCard({
    super.key,
    required this.review,
    this.currentUserId,
    this.onEdit,
    this.onDelete,
    this.onReport,
    this.showMenu = true,
  });

  DateTime _asDateTime(DateTime timestamp) {
    return timestamp;
  }

  bool get _isOwnReview {
    return currentUserId != null &&
        currentUserId!.isNotEmpty &&
        review.userId == currentUserId;
  }

  void _showReviewOptions(BuildContext context) {
    AppBottomSheet.show(
      initialChildSize: 0.35,
      minChildSize: 0.3,
      maxChildSize: 0.5,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              'Review Options',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Own Review Options
            if (_isOwnReview) ...[
              // Edit Option
              if (onEdit != null)
                ListTile(
                  leading: Icon(Icons.edit, color: Colors.blue[700]),
                  title: const Text(
                    'Edit Review',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onEdit!();
                  },
                ),

              // Delete Option
              if (onDelete != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'Delete Review',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onDelete!();
                  },
                ),
            ],

            // Other User's Review Options
            if (!_isOwnReview) ...[
              // Report Option
              if (onReport != null)
                ListTile(
                  leading: Icon(Icons.report, color: Colors.orange[700]),
                  title: const Text(
                    'Report Review',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onReport!();
                  },
                ),
            ],

            // Cancel
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.close, color: Colors.grey),
              title: const Text(
                'Cancel',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Inner Row: Avatar + Name & Date grouped together
                Row(
                  children: [
                    CircleAvatar(
                      child: Text(
                        (review.username.isNotEmpty ? review.username[0] : '?')
                            .toUpperCase(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review.username,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          DateFormat(
                            'MMM dd, yyyy',
                          ).format(_asDateTime(review.timestamp)),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Spacer to push triple dot to the end
                const Spacer(),

                // Triple dot button at the end
                if (showMenu &&
                    (onEdit != null || onDelete != null || onReport != null))
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showReviewOptions(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),

            const SizedBox(height: 8),
            Text(review.review),
          ],
        ),
      ),
    );
  }
}
