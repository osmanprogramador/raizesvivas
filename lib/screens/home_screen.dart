import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../providers/content_provider.dart';
import '../utils/constants.dart';
import 'qr_scanner_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _openScanner(BuildContext context) async {
    // Request camera permission
    final status = await Permission.camera.request();

    if (status.isGranted && context.mounted) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => const QrScannerScreen()));
    } else if (status.isDenied && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Permissão de câmera necessária para escanear QR Codes',
          ),
          backgroundColor: Color(AppConstants.deleteRed),
        ),
      );
    } else if (status.isPermanentlyDenied && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Permissão de câmera negada. Ative nas configurações.',
          ),
          backgroundColor: const Color(AppConstants.deleteRed),
          action: SnackBarAction(
            label: 'Configurações',
            textColor: Colors.white,
            onPressed: () => openAppSettings(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppConstants.backgroundBlack),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo or app name
                const Text(
                  'Terra Vista',
                  style: TextStyle(
                    color: Color(AppConstants.primaryGreen),
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Assentamento Terra Vista',
                  style: TextStyle(
                    color: Color(AppConstants.textGray),
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),
                _buildSyncStatus(context),
                const SizedBox(height: 32),

                // Main card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(48.0),
                  decoration: BoxDecoration(
                    color: const Color(AppConstants.cardDark),
                    borderRadius: BorderRadius.circular(24.0),
                    border: Border.all(
                      color: const Color(
                        AppConstants.primaryGreen,
                      ).withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // QR Code Icon in Circle
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(AppConstants.primaryGreen),
                            width: 3.0,
                          ),
                        ),
                        child: const Icon(
                          Icons.qr_code_scanner,
                          size: 80,
                          color: Color(AppConstants.primaryGreen),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Title
                      const Text(
                        'Escanear QR Code',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Subtitle
                      const Text(
                        'Descubra histórias, saberes e informações sobre\neste local do assentamento',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(AppConstants.textGray),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Scan button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: () => _openScanner(context),
                          icon: const Icon(Icons.qr_code_scanner, size: 24),
                          label: const Text(
                            'Iniciar Escaneamento',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              AppConstants.primaryGreen,
                            ),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSyncStatus(BuildContext context) {
    return Consumer<ContentProvider>(
      builder: (context, provider, _) {
        Color color;
        String text;
        IconData icon;
        bool isSpinning = false;

        switch (provider.syncStatus) {
          case SyncStatus.syncing:
            color = const Color(AppConstants.textGray);
            text = 'Sincronizando dados...';
            icon = Icons.refresh;
            isSpinning = true;
            break;
          case SyncStatus.synced:
            color = const Color(AppConstants.primaryGreen);
            text = 'Base de dados atualizada';
            icon = Icons.check_circle_outline;
            break;
          case SyncStatus.error:
            color = const Color(AppConstants.deleteRed);
            text = 'Modo offline';
            icon = Icons.wifi_off;
            break;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              isSpinning
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    )
                  : Icon(icon, size: 14, color: color),
              const SizedBox(width: 8),
              Text(
                text,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
