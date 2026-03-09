import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/content_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/history_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/constants.dart';
import 'content_form_screen.dart';
import 'admin_form_screen.dart';

class AdminDashboardWebScreen extends StatelessWidget {
  const AdminDashboardWebScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final contentProvider = context.watch<ContentProvider>();
    final authProvider = context.watch<AuthProvider>();
    final historyProvider = context.watch<HistoryProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    final totalContents = contentProvider.contents.length;
    final contentsByCategory = <String, int>{};
    for (final content in contentProvider.contents) {
      contentsByCategory[content.category] =
          (contentsByCategory[content.category] ?? 0) + 1;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(AppConstants.primaryGreen),
                  Color(AppConstants.darkGreen),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bem-vindo, ${authProvider.currentUser?.fullName ?? "Admin"}!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Gerencie conteúdos e usuários do Terra Vista',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.eco,
                  size: 64,
                  color: Colors.white24,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Stats Cards
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Total de Conteúdos',
                  value: totalContents.toString(),
                  icon: Icons.article,
                  color: const Color(AppConstants.primaryGreen),
                  trend: '+${contentProvider.contents.where((c) {
                    final weekAgo =
                        DateTime.now().subtract(const Duration(days: 7));
                    return c.createdAt.isAfter(weekAgo);
                  }).length} esta semana',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  title: 'Usuários Ativos',
                  value: authProvider.currentUser != null ? '1+' : '0',
                  icon: Icons.people,
                  color: const Color(AppConstants.brownCocoa),
                  trend: 'Online agora',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  title: 'Scans Recentes',
                  value: historyProvider.history.length.toString(),
                  icon: Icons.qr_code_scanner,
                  color: const Color(AppConstants.lightGreen),
                  trend: 'Últimos 30 dias',
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Quick Actions
          Text(
            'Ações Rápidas',
            style: TextStyle(
              color: themeProvider.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  title: 'Novo Conteúdo',
                  subtitle: 'Criar conteúdo e gerar QR Code',
                  icon: Icons.add_circle,
                  color: const Color(AppConstants.primaryGreen),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ContentFormScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _QuickActionCard(
                  title: 'Novo Usuário',
                  subtitle: 'Pré-aprovar novo administrador',
                  icon: Icons.person_add,
                  color: const Color(AppConstants.brownCocoa),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminFormScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Content by Category
          Text(
            'Conteúdos por Categoria',
            style: TextStyle(
              color: themeProvider.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: themeProvider.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: themeProvider.cardMediumColor,
              ),
            ),
            child: Column(
              children: AppConstants.categories.map((category) {
                final count = contentsByCategory[category] ?? 0;
                final total = totalContents > 0 ? totalContents : 1;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            category,
                            style: TextStyle(
                              color: themeProvider.textColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '$count conteúdo${count != 1 ? 's' : ''}',
                            style: TextStyle(
                              color: themeProvider.textSecondaryColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: count / total,
                          minHeight: 8,
                          backgroundColor: const Color(AppConstants.cardMedium),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getCategoryColor(category),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 24),

          // Recent Activity
          Text(
            'Atividade Recente',
            style: TextStyle(
              color: themeProvider.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          Container(
            decoration: BoxDecoration(
              color: themeProvider.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: themeProvider.cardMediumColor,
              ),
            ),
            child: contentProvider.contents.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.inbox,
                            size: 48,
                            color: const Color(AppConstants.textGray)
                                .withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhum conteúdo criado ainda',
                            style: TextStyle(
                              color: themeProvider.textSecondaryColor
                                  .withValues(alpha: 0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: contentProvider.contents.take(5).length,
                    separatorBuilder: (context, index) => Divider(
                      color: themeProvider.cardMediumColor,
                      height: 1,
                    ),
                    itemBuilder: (context, index) {
                      final content = contentProvider.contents[index];
                      final formattedDate = DateFormat('dd/MM/yyyy • HH:mm')
                          .format(content.updatedAt);

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _getCategoryColor(content.category)
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getCategoryIcon(content.category),
                            color: _getCategoryColor(content.category),
                            size: 20,
                          ),
                        ),
                        title: Text(
                          content.title,
                          style: TextStyle(
                            color: themeProvider.textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${content.category} • $formattedDate',
                          style: TextStyle(
                            color: themeProvider.textSecondaryColor,
                            fontSize: 12,
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(AppConstants.primaryGreen)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            content.qrCodeId.split('.').last,
                            style: const TextStyle(
                              color: Color(AppConstants.primaryGreen),
                              fontSize: 11,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
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

  IconData _getCategoryIcon(String category) {
    switch (category) {
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
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String trend;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: themeProvider.cardMediumColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              color: themeProvider.textColor,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: themeProvider.textSecondaryColor,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              trend,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: themeProvider.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: themeProvider.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: themeProvider.textSecondaryColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: color,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
