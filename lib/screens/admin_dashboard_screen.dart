import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/content_provider.dart';
import '../utils/constants.dart';
import '../widgets/content_card.dart';
import 'content_form_screen.dart';
import 'qr_generator_screen.dart';
import 'content_detail_screen.dart';
import 'admin_list_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategoryFilter;

  @override
  void initState() {
    super.initState();
    // Load contents when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContentProvider>().loadContents();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final canManageUsers = authProvider.isSuperAdmin;

    return Scaffold(
      backgroundColor: const Color(AppConstants.backgroundBlack),
      appBar: AppBar(
        title: const Text('Área Administrativa'),
        backgroundColor: const Color(AppConstants.primaryGreen),
        automaticallyImplyLeading: false,
        actions: [
          if (canManageUsers)
            IconButton(
              tooltip: 'Gerenciar Usuários',
              icon: const Icon(Icons.manage_accounts),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminListScreen(),
                  ),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(AppConstants.cardDark),
                  title: const Text(
                    'Sair',
                    style: TextStyle(color: Colors.white),
                  ),
                  content: const Text(
                    'Deseja realmente sair da área administrativa?',
                    style: TextStyle(color: Color(AppConstants.textGray)),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () {
                        context.read<AuthProvider>().logout();
                        Navigator.of(context).pop();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(AppConstants.deleteRed),
                      ),
                      child: const Text('Sair'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<ContentProvider>(
        builder: (context, contentProvider, _) {
          if (contentProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(AppConstants.primaryGreen),
              ),
            );
          }

          // Filter contents based on search and category
          final filteredContents = contentProvider.contents.where((content) {
            final matchesSearch = _searchQuery.isEmpty ||
                content.title.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                content.description.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    );

            final matchesCategory = _selectedCategoryFilter == null ||
                content.category == _selectedCategoryFilter;

            return matchesSearch && matchesCategory;
          }).toList();

          return Column(
            children: [
              // Search and Filter Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(AppConstants.cardDark),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Search Bar
                    TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Buscar conteúdos...',
                        hintStyle: TextStyle(
                          color: const Color(
                            AppConstants.textGray,
                          ).withValues(alpha: 0.6),
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(AppConstants.primaryGreen),
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  color: Color(AppConstants.textGray),
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: const Color(AppConstants.cardMedium),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(AppConstants.primaryGreen),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Category Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // All filter
                          FilterChip(
                            label: const Text('Todos'),
                            selected: _selectedCategoryFilter == null,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategoryFilter = null;
                              });
                            },
                            selectedColor: const Color(
                              AppConstants.primaryGreen,
                            ).withValues(alpha: 0.3),
                            checkmarkColor: const Color(
                              AppConstants.primaryGreen,
                            ),
                            labelStyle: TextStyle(
                              color: _selectedCategoryFilter == null
                                  ? const Color(AppConstants.primaryGreen)
                                  : const Color(AppConstants.textGray),
                              fontWeight: _selectedCategoryFilter == null
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                            backgroundColor: const Color(
                              AppConstants.cardMedium,
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Category filters
                          ...AppConstants.categories.map((category) {
                            final isSelected =
                                _selectedCategoryFilter == category;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(category),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedCategoryFilter =
                                        selected ? category : null;
                                  });
                                },
                                selectedColor: _getCategoryColor(
                                  category,
                                ).withValues(alpha: 0.3),
                                checkmarkColor: _getCategoryColor(category),
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? _getCategoryColor(category)
                                      : const Color(AppConstants.textGray),
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  fontSize: 12,
                                ),
                                backgroundColor: const Color(
                                  AppConstants.cardMedium,
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                    // Results count
                    if (_searchQuery.isNotEmpty ||
                        _selectedCategoryFilter != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Row(
                          children: [
                            Icon(
                              Icons.filter_list,
                              size: 16,
                              color: const Color(
                                AppConstants.textGray,
                              ).withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${filteredContents.length} resultado(s) encontrado(s)',
                              style: TextStyle(
                                color: const Color(
                                  AppConstants.textGray,
                                ).withValues(alpha: 0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Content List
              Expanded(
                child: filteredContents.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _searchQuery.isNotEmpty ||
                                      _selectedCategoryFilter != null
                                  ? Icons.search_off
                                  : Icons.inventory_2_outlined,
                              size: 80,
                              color: const Color(
                                AppConstants.textGray,
                              ).withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty ||
                                      _selectedCategoryFilter != null
                                  ? 'Nenhum conteúdo encontrado'
                                  : 'Nenhum conteúdo cadastrado',
                              style: const TextStyle(
                                color: Color(AppConstants.textGray),
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _searchQuery.isNotEmpty ||
                                      _selectedCategoryFilter != null
                                  ? 'Tente ajustar os filtros'
                                  : 'Clique no + para adicionar',
                              style: const TextStyle(
                                color: Color(AppConstants.textDarkGray),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => contentProvider.loadContents(),
                        color: const Color(AppConstants.primaryGreen),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredContents.length,
                          itemBuilder: (context, index) {
                            final content = filteredContents[index];

                            return ContentCard(
                              content: content,
                              showActions: true,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ContentDetailScreen(content: content),
                                  ),
                                );
                              },
                              onEdit: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ContentFormScreen(content: content),
                                  ),
                                );
                              },
                              onQrCode: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        QrGeneratorScreen(content: content),
                                  ),
                                );
                              },
                              onDelete: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: const Color(
                                      AppConstants.cardDark,
                                    ),
                                    title: const Text(
                                      'Deletar Conteúdo',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    content: Text(
                                      'Deseja realmente deletar "${content.title}"?',
                                      style: const TextStyle(
                                        color: Color(AppConstants.textGray),
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: const Text('Cancelar'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                        style: TextButton.styleFrom(
                                          foregroundColor: const Color(
                                            AppConstants.deleteRed,
                                          ),
                                        ),
                                        child: const Text('Deletar'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirmed == true && context.mounted) {
                                  final success = await contentProvider
                                      .deleteContent(content.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          success
                                              ? 'Conteúdo deletado com sucesso'
                                              : 'Erro ao deletar conteúdo',
                                        ),
                                        backgroundColor: success
                                            ? const Color(
                                                AppConstants.primaryGreen,
                                              )
                                            : const Color(
                                                AppConstants.deleteRed,
                                              ),
                                      ),
                                    );
                                  }
                                }
                              },
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const ContentFormScreen()),
          );
        },
        backgroundColor: const Color(AppConstants.primaryGreen),
        child: const Icon(Icons.add, size: 32),
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
}
