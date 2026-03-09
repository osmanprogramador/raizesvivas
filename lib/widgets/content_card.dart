import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/content_model.dart';
import '../utils/constants.dart';

class ContentCard extends StatelessWidget {
  final ContentModel content;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onQrCode;
  final bool showActions;

  const ContentCard({
    super.key,
    required this.content,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.onQrCode,
    this.showActions = false,
  });

  Color _getCategoryColor() {
    switch (content.category) {
      case 'INFRAESTRUTURAS':
        return const Color(AppConstants.brownTag);
      case 'PRODUÇÃO':
        return const Color(AppConstants.lightGreen);
      case 'HISTÓRIA':
        return const Color(AppConstants.brownCocoa);
      case 'MEIO AMBIENTE':
        return const Color(AppConstants.primaryGreen);
      case 'CULTURA':
        return const Color(AppConstants.darkGreen);
      default:
        return const Color(AppConstants.textGray);
    }
  }

  IconData _getCategoryIcon() {
    switch (content.category) {
      case 'INFRAESTRUTURAS':
        return Icons.business;
      case 'PRODUÇÃO':
        return Icons.agriculture;
      case 'HISTÓRIA':
        return Icons.history_edu;
      case 'MEIO AMBIENTE':
        return Icons.eco;
      case 'CULTURA':
        return Icons.palette;
      default:
        return Icons.category;
    }
  }

  bool _isRecent() {
    final now = DateTime.now();
    final difference = now.difference(content.createdAt);
    return difference.inDays < 7; // Recent if created in last 7 days
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Hoje';
    } else if (difference.inDays == 1) {
      return 'Ontem';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} dias atrás';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasLocation = content.latitude != null && content.longitude != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(AppConstants.cardDark),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getCategoryColor().withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with category and badges
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Category icon and name
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getCategoryColor().withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _getCategoryColor().withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getCategoryIcon(),
                            size: 14,
                            color: _getCategoryColor(),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            content.category,
                            style: TextStyle(
                              color: _getCategoryColor(),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Recent badge
                    if (_isRecent())
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            AppConstants.primaryGreen,
                          ).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.fiber_new,
                              size: 12,
                              color: const Color(AppConstants.primaryGreen),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'NOVO',
                              style: TextStyle(
                                color: Color(AppConstants.primaryGreen),
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Location badge
                    if (hasLocation) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _getCategoryColor().withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          Icons.location_on,
                          size: 12,
                          color: _getCategoryColor(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                content.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                content.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(AppConstants.textGray),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),

              // Footer with date and QR code ID
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 12,
                    color: const Color(
                      AppConstants.textGray,
                    ).withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(content.createdAt),
                    style: TextStyle(
                      color: const Color(
                        AppConstants.textGray,
                      ).withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(AppConstants.cardMedium),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.qr_code_2,
                          size: 10,
                          color: _getCategoryColor(),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          content.qrCodeId.split('.').last,
                          style: TextStyle(
                            color: _getCategoryColor(),
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Action buttons (for admin)
              if (showActions) ...[
                const SizedBox(height: 16),
                const Divider(color: Color(AppConstants.cardMedium), height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: ElevatedButton.icon(
                          onPressed: onEdit,
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text(
                            'Editar',
                            style: TextStyle(fontSize: 13),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              AppConstants.lightGreen,
                            ),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: ElevatedButton.icon(
                          onPressed: onQrCode,
                          icon: const Icon(Icons.qr_code, size: 16),
                          label: const Text(
                            'QR Code',
                            style: TextStyle(fontSize: 13),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              AppConstants.brownCocoa,
                            ),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 40,
                      width: 40,
                      child: IconButton(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete, size: 18),
                        style: IconButton.styleFrom(
                          foregroundColor: const Color(AppConstants.deleteRed),
                          side: const BorderSide(
                            color: Color(AppConstants.deleteRed),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        tooltip: 'Deletar',
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
