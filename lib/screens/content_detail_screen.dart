import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/content_model.dart';
import '../providers/content_provider.dart';
import '../utils/constants.dart';
import 'content_form_screen.dart';

class ContentDetailScreen extends StatefulWidget {
  final ContentModel content;

  const ContentDetailScreen({super.key, required this.content});

  @override
  State<ContentDetailScreen> createState() => _ContentDetailScreenState();
}

class _ContentDetailScreenState extends State<ContentDetailScreen> {
  bool _showQrCode = false;

  bool get _hasImage {
    final path = widget.content.imagePath;
    return path != null && path.isNotEmpty;
  }

  Color _getCategoryColor() {
    switch (widget.content.category) {
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
    switch (widget.content.category) {
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

  String _formatDate(DateTime date) {
    try {
      return DateFormat('dd/MM/yyyy • HH:mm', 'pt_BR').format(date);
    } catch (e) {
      // Fallback se o locale não estiver disponível
      return DateFormat('dd/MM/yyyy • HH:mm').format(date);
    }
  }

  void _shareContent() {
    final hasLocation =
        widget.content.latitude != null && widget.content.longitude != null;
    final locationText = hasLocation
        ? '\n\n📍 Localização: ${widget.content.latitude!.toStringAsFixed(6)}, ${widget.content.longitude!.toStringAsFixed(6)}'
        : '';

    final text = '''
🌿 ${widget.content.title}

📂 Categoria: ${widget.content.category}

${widget.content.description}$locationText

🔖 QR Code: ${widget.content.qrCodeId}

---
Terra Vista - Assentamento Sustentável
''';

    // ignore: deprecated_member_use
    Share.share(text, subject: widget.content.title);
  }

  Widget _buildImageWidget() {
    if (!_hasImage) {
      return const SizedBox(height: 100); // Placeholder for no image
    }

    final imagePath = widget.content.imagePath!;

    // Allow blob URLs (Web) or HTTP URLs
    if (imagePath.startsWith('http') || imagePath.startsWith('blob:')) {
      return SizedBox(
        height: 300,
        width: double.infinity,
        child: CachedNetworkImage(
          imageUrl: imagePath,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: const Color(AppConstants.cardDark),
            child: const Center(
              child: CircularProgressIndicator(
                color: Color(AppConstants.primaryGreen),
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: const Color(AppConstants.cardDark),
            child: const Center(
              child: Icon(
                Icons.broken_image,
                size: 64,
                color: Color(AppConstants.textGray),
              ),
            ),
          ),
        ),
      );
    }

    // Web fallback for non-http/blob paths
    if (kIsWeb) {
      return Container(
        height: 300,
        width: double.infinity,
        color: const Color(AppConstants.cardDark),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_not_supported,
                size: 64,
                color: Color(AppConstants.textGray),
              ),
              SizedBox(height: 8),
              Text(
                'Imagem local não disponível na web',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(AppConstants.textGray),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Mobile: usa Image.file ou Image.asset
    final isFilePath = imagePath.contains('/') &&
        (imagePath.startsWith('/') || imagePath.contains(':\\'));

    if (isFilePath) {
      final file = File(imagePath);
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: const Color(AppConstants.cardDark),
            child: const Center(
              child: Icon(
                Icons.broken_image,
                size: 64,
                color: Color(AppConstants.textGray),
              ),
            ),
          );
        },
      );
    } else {
      return Image.asset(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: const Color(AppConstants.cardDark),
            child: const Center(
              child: Icon(
                Icons.broken_image,
                size: 64,
                color: Color(AppConstants.textGray),
              ),
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasLocation =
        widget.content.latitude != null && widget.content.longitude != null;

    // Check if user is admin (hardcoded for now as per previous logic)
    // In a real app, use context.read<AuthProvider>().isAdmin
    // ignore: unused_local_variable
    const canEdit = true;

    return Scaffold(
      backgroundColor: const Color(AppConstants.backgroundBlack),
      body: Builder(
        builder: (context) {
          try {
            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: _hasImage ? 280 : kToolbarHeight,
                  collapsedHeight: kToolbarHeight,
                  pinned: true,
                  backgroundColor: const Color(AppConstants.backgroundBlack),
                  title: !_hasImage
                      ? Text(
                          widget.content.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  flexibleSpace: _hasImage
                      ? FlexibleSpaceBar(
                          background: Stack(
                            fit: StackFit.expand,
                            children: [
                              _buildImageWidget(),
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      const Color(
                                        AppConstants.backgroundBlack,
                                      ).withValues(alpha: 0.7),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : null,
                  actions: [
                    IconButton(
                        icon: const Icon(Icons.qr_code, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            _showQrCode = !_showQrCode;
                          });
                        }),
                    IconButton(
                      icon: const Icon(Icons.share, color: Colors.white),
                      onPressed: _shareContent,
                    ),
                    if (canEdit) ...[
                      IconButton(
                        tooltip: 'Editar',
                        icon: const Icon(Icons.edit, color: Colors.white),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ContentFormScreen(content: widget.content),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        tooltip: 'Deletar',
                        icon: const Icon(Icons.delete,
                            color: Color(AppConstants.deleteRed)),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor:
                                  const Color(AppConstants.cardDark),
                              title: const Text('Deletar Conteúdo',
                                  style: TextStyle(color: Colors.white)),
                              content: const Text(
                                  'Tem certeza que deseja deletar este conteúdo? Esta ação não pode ser desfeita.',
                                  style: TextStyle(
                                      color: Color(AppConstants.textGray))),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    // Close dialog first
                                    Navigator.pop(context);

                                    // Delete content
                                    final success = await context
                                        .read<ContentProvider>()
                                        .deleteContent(widget.content.id);

                                    if (success && mounted) {
                                      Navigator.pop(context); // Return to list
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Conteúdo deletado com sucesso'),
                                          backgroundColor:
                                              Color(AppConstants.primaryGreen),
                                        ),
                                      );
                                    } else if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content:
                                              Text('Erro ao deletar conteúdo'),
                                          backgroundColor:
                                              Color(AppConstants.deleteRed),
                                        ),
                                      );
                                    }
                                  },
                                  style: TextButton.styleFrom(
                                      foregroundColor:
                                          const Color(AppConstants.deleteRed)),
                                  child: const Text('Deletar'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _getCategoryColor().withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _getCategoryColor().withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getCategoryIcon(),
                                size: 16,
                                color: _getCategoryColor(),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.content.category,
                                style: TextStyle(
                                  color: _getCategoryColor(),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_hasImage) ...[
                          Text(
                            widget.content.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: const Color(
                                AppConstants.textGray,
                              ).withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Criado em ${_formatDate(widget.content.createdAt)}',
                              style: TextStyle(
                                color: const Color(
                                  AppConstants.textGray,
                                ).withValues(alpha: 0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        if (widget.content.updatedAt !=
                            widget.content.createdAt) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.update,
                                size: 14,
                                color: const Color(
                                  AppConstants.textGray,
                                ).withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Atualizado em ${_formatDate(widget.content.updatedAt)}',
                                style: TextStyle(
                                  color: const Color(
                                    AppConstants.textGray,
                                  ).withValues(alpha: 0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 24),
                        const Divider(
                          color: Color(AppConstants.cardDark),
                          thickness: 1,
                        ),
                        const SizedBox(height: 24),
                        if (_showQrCode) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: _getCategoryColor()
                                      .withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'QR CODE',
                                  style: TextStyle(
                                    color: _getCategoryColor(),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                QrImageView(
                                  data: widget.content.qrCodeId,
                                  version: QrVersions.auto,
                                  size: 200,
                                  backgroundColor: Colors.white,
                                  eyeStyle: QrEyeStyle(
                                    eyeShape: QrEyeShape.square,
                                    color: _getCategoryColor(),
                                  ),
                                  dataModuleStyle: QrDataModuleStyle(
                                    dataModuleShape: QrDataModuleShape.square,
                                    color: _getCategoryColor(),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(AppConstants.cardDark),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    widget.content.qrCodeId,
                                    style: const TextStyle(
                                      color: Color(AppConstants.textGray),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                        Row(
                          children: [
                            Icon(
                              Icons.description,
                              size: 18,
                              color: _getCategoryColor(),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Descrição',
                              style: TextStyle(
                                color: _getCategoryColor(),
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(AppConstants.cardDark),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getCategoryColor().withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            widget.content.description,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              height: 1.6,
                            ),
                          ),
                        ),
                        if (hasLocation) ...[
                          const SizedBox(height: 32),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 18,
                                color: _getCategoryColor(),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Localização',
                                style: TextStyle(
                                  color: _getCategoryColor(),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            height: 250,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(AppConstants.cardDark),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    _getCategoryColor().withValues(alpha: 0.3),
                              ),
                            ),
                            child: Stack(
                              children: [
                                CustomPaint(
                                  size: const Size(double.infinity, 250),
                                  painter: _MapGridPainter(
                                    color: _getCategoryColor(),
                                  ),
                                ),
                                Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        size: 64,
                                        color: _getCategoryColor(),
                                        shadows: const [
                                          Shadow(
                                            blurRadius: 10,
                                            color: Colors.black45,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                              AppConstants.cardMedium),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color:
                                                _getCategoryColor().withValues(
                                              alpha: 0.4,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.gps_fixed,
                                              size: 14,
                                              color:
                                                  Color(AppConstants.textGray),
                                            ),
                                            const SizedBox(width: 8),
                                            Flexible(
                                              child: Text(
                                                '${widget.content.latitude!.toStringAsFixed(6)}, ${widget.content.longitude!.toStringAsFixed(6)}',
                                                style: const TextStyle(
                                                  color: Color(
                                                      AppConstants.textGray),
                                                  fontSize: 12,
                                                  fontFamily: 'monospace',
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 40),
                        Center(
                          child: Text(
                            '🌿 Terra Vista',
                            style: TextStyle(
                              color: const Color(
                                AppConstants.textGray,
                              ).withValues(alpha: 0.5),
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            );
          } catch (e) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Color(AppConstants.deleteRed),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Erro ao carregar conteúdo: $e',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  final Color color;
  _MapGridPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final paint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (double i = 0; i < size.width; i += 30) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 30) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
