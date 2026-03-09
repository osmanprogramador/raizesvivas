import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/content_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/constants.dart';
import '../widgets/content_card.dart';
import 'admin_dashboard_screen.dart';
import 'content_detail_screen.dart';
import 'content_form_screen.dart';
import 'qr_generator_screen.dart';

class ContentListScreen extends StatelessWidget {
  const ContentListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const _ContentListWeb();
    }
    return const AdminDashboardScreen();
  }
}

class _ContentListWeb extends StatefulWidget {
  const _ContentListWeb();

  @override
  State<_ContentListWeb> createState() => _ContentListWebState();
}

class _ContentListWebState extends State<_ContentListWeb> {
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
    // Only access providers inside build to avoid unnecessary rebuilds or context issues
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor:
          Colors.transparent, // Transparent because Layout handles bg
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ContentFormScreen(),
            ),
          );
        },
        backgroundColor: const Color(AppConstants.primaryGreen),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Novo Conteúdo',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
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
                content.title
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ||
                content.description
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase());

            final matchesCategory = _selectedCategoryFilter == null ||
                content.category == _selectedCategoryFilter;

            return matchesSearch && matchesCategory;
          }).toList();

          return Column(
            children: [
              // Search and Filter Section
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: themeProvider.cardColor,
                  border: Border(
                    bottom: BorderSide(
                      color: themeProvider.cardMediumColor,
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Search Bar
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                            style: TextStyle(color: themeProvider.textColor),
                            decoration: InputDecoration(
                              hintText: 'Buscar conteúdos...',
                              hintStyle: TextStyle(
                                color: themeProvider.textSecondaryColor
                                    .withValues(alpha: 0.6),
                              ),
                              prefixIcon: const Icon(
                                Icons.search,
                                color: Color(AppConstants.primaryGreen),
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(
                                        Icons.clear,
                                        color: themeProvider.textSecondaryColor,
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
                              fillColor: themeProvider.cardMediumColor,
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
                        ),
                        const SizedBox(width: 16),
                        // Refresh Button
                        IconButton.filled(
                          onPressed: () {
                            contentProvider.loadContents();
                          },
                          icon: const Icon(Icons.refresh),
                          style: IconButton.styleFrom(
                            backgroundColor: themeProvider.cardMediumColor,
                            foregroundColor: themeProvider.textColor,
                            padding: const EdgeInsets.all(16),
                          ),
                          tooltip: 'Atualizar Lista',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

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
                            backgroundColor: themeProvider.cardMediumColor,
                            selectedColor:
                                const Color(AppConstants.primaryGreen),
                            labelStyle: TextStyle(
                              color: _selectedCategoryFilter == null
                                  ? Colors.white
                                  : themeProvider.textColor,
                              fontWeight: _selectedCategoryFilter == null
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide.none,
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            showCheckmark: false,
                          ),
                          const SizedBox(width: 8),

                          // Dynamic Category Chips
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
                                backgroundColor: themeProvider.cardMediumColor,
                                selectedColor:
                                    const Color(AppConstants.primaryGreen),
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : themeProvider.textColor,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide.none,
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                showCheckmark: false,
                              ),
                            );
                          }),
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
                              Icons.search_off,
                              size: 64,
                              color: themeProvider.textSecondaryColor
                                  .withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Nenhum conteúdo encontrado',
                              style: TextStyle(
                                color: themeProvider.textSecondaryColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_searchQuery.isNotEmpty ||
                                _selectedCategoryFilter != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _searchQuery = '';
                                      _searchController.clear();
                                      _selectedCategoryFilter = null;
                                    });
                                  },
                                  child: const Text(
                                    'Limpar filtros',
                                    style: TextStyle(
                                      color: Color(AppConstants.primaryGreen),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(24),
                        itemCount: filteredContents.length,
                        itemBuilder: (context, index) {
                          final content = filteredContents[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: ContentCard(
                              content: content,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ContentDetailScreen(content: content),
                                  ),
                                );
                              },
                              onEdit: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ContentFormScreen(content: content),
                                  ),
                                );
                              },
                              onDelete: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: themeProvider.cardColor,
                                    title: Text(
                                      'Excluir Conteúdo',
                                      style: TextStyle(
                                          color: themeProvider.textColor),
                                    ),
                                    content: Text(
                                      'Tem certeza que deseja excluir "${content.title}"?',
                                      style: TextStyle(
                                          color:
                                              themeProvider.textSecondaryColor),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        child: const Text('Cancelar'),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          Navigator.of(context).pop();
                                          await context
                                              .read<ContentProvider>()
                                              .deleteContent(content.id);
                                        },
                                        style: TextButton.styleFrom(
                                          foregroundColor: const Color(
                                              AppConstants.deleteRed),
                                        ),
                                        child: const Text('Excluir'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              onQrCode: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        QrGeneratorScreen(content: content),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
