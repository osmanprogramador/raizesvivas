import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import 'admin_form_screen.dart';
import 'admin_list_screen.dart';

class UserListScreen extends StatelessWidget {
  const UserListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const _UserListWeb();
    }
    return const AdminListScreen();
  }
}

class _UserListWeb extends StatefulWidget {
  const _UserListWeb();

  @override
  State<_UserListWeb> createState() => _UserListWebState();
}

class _UserListWebState extends State<_UserListWeb> {
  late Future<List<UserModel>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() {
    setState(() {
      _usersFuture = context.read<AuthProvider>().getAllUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent, // Background handled by Layout
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (context) => const AdminFormScreen()),
          );

          if (created == true && mounted) {
            _loadUsers();
          }
        },
        backgroundColor: const Color(AppConstants.primaryGreen),
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text(
          'Novo Usuário',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Header / Filter area could go here
          Expanded(
            child: FutureBuilder<List<UserModel>>(
              future: _usersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(AppConstants.primaryGreen),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 60,
                          color: themeProvider.isDarkMode
                              ? const Color(AppConstants.deleteRed)
                              : Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Erro ao carregar usuários: ${snapshot.error}',
                          style: TextStyle(
                              color: themeProvider.textSecondaryColor),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadUsers,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(AppConstants.primaryGreen),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Tentar Novamente'),
                        ),
                      ],
                    ),
                  );
                }

                final users = snapshot.data ?? [];

                if (users.isEmpty) {
                  return Center(
                    child: Text(
                      'Nenhum usuário encontrado',
                      style: TextStyle(color: themeProvider.textSecondaryColor),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    _loadUsers();
                  },
                  color: const Color(AppConstants.primaryGreen),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: users.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final isSelf = user.id ==
                          context.read<AuthProvider>().currentUser?.id;

                      return Card(
                        color: themeProvider.cardColor,
                        elevation: 2,
                        margin: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: themeProvider.cardMediumColor,
                            width: 1,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor:
                                const Color(AppConstants.primaryGreen),
                            child: Text(
                              user.fullName.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            user.fullName,
                            style: TextStyle(
                              color: themeProvider.textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                user.email,
                                style: TextStyle(
                                  color: themeProvider.textSecondaryColor,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                    color:
                                        const Color(AppConstants.primaryGreen)
                                            .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                        color: const Color(
                                                AppConstants.primaryGreen)
                                            .withValues(alpha: 0.3))),
                                child: Text(
                                  user.roleDisplayName,
                                  style: const TextStyle(
                                    color: Color(AppConstants.primaryGreen),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          trailing: isSelf
                              ? Chip(
                                  label: const Text(
                                    'Você',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                    ),
                                  ),
                                  backgroundColor:
                                      themeProvider.textSecondaryColor,
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                  side: BorderSide.none,
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.edit,
                                        color: themeProvider.textSecondaryColor,
                                      ),
                                      tooltip: 'Editar',
                                      onPressed: () async {
                                        final updated =
                                            await Navigator.push<bool>(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                AdminFormScreen(user: user),
                                          ),
                                        );

                                        if (updated == true && mounted) {
                                          _loadUsers();
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Color(AppConstants.deleteRed),
                                      ),
                                      tooltip: 'Excluir',
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            backgroundColor:
                                                themeProvider.cardColor,
                                            title: Text(
                                              'Excluir Usuário',
                                              style: TextStyle(
                                                  color:
                                                      themeProvider.textColor),
                                            ),
                                            content: Text(
                                              'Tem certeza que deseja excluir ${user.fullName}?',
                                              style: TextStyle(
                                                color: themeProvider
                                                    .textSecondaryColor,
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                    context, false),
                                                child: const Text('Cancelar'),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                    context, true),
                                                style: TextButton.styleFrom(
                                                  foregroundColor: const Color(
                                                    AppConstants.deleteRed,
                                                  ),
                                                ),
                                                child: const Text('Excluir'),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirm == true) {
                                          if (!context.mounted) return;
                                          final authProvider =
                                              context.read<AuthProvider>();
                                          final success =
                                              await authProvider.deleteUser(
                                            user.id,
                                          );

                                          if (!context.mounted) return;
                                          if (success) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Usuário excluído com sucesso',
                                                ),
                                                backgroundColor: Color(
                                                  AppConstants.primaryGreen,
                                                ),
                                              ),
                                            );
                                            _loadUsers();
                                          }
                                        }
                                      },
                                    ),
                                  ],
                                ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
