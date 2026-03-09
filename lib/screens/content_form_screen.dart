import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../models/content_model.dart';
import '../providers/content_provider.dart';
import '../providers/theme_provider.dart';
import '../services/firestore_service.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../widgets/custom_button.dart';

class ContentFormScreen extends StatefulWidget {
  final ContentModel? content; // null for create, non-null for edit

  const ContentFormScreen({super.key, this.content});

  @override
  State<ContentFormScreen> createState() => _ContentFormScreenState();
}

class _ContentFormScreenState extends State<ContentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  String? _selectedCategory;
  String? _imagePath;
  Uint8List? _imageBytes; // Para web
  bool _isLoading = false;
  bool _isLoadingLocation = false;
  int _descriptionLength = 0;
  static const int _maxDescriptionLength = 500;

  bool get isEditing => widget.content != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _titleController.text = widget.content!.title;
      _descriptionController.text = widget.content!.description;
      _selectedCategory = widget.content!.category;
      _imagePath = widget.content!.imagePath;
      _descriptionLength = widget.content!.description.length;
      if (widget.content!.latitude != null) {
        _latitudeController.text = widget.content!.latitude.toString();
      }
      if (widget.content!.longitude != null) {
        _longitudeController.text = widget.content!.longitude.toString();
      }
    }

    _descriptionController.addListener(() {
      setState(() {
        _descriptionLength = _descriptionController.text.length;
      });
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (image != null) {
      if (kIsWeb) {
        // No web, carrega os bytes da imagem
        final bytes = await image.readAsBytes();
        setState(() {
          _imagePath = image.path; // Use path (blob URL) for preview
          _imageBytes = bytes;
        });
      } else {
        // No mobile, usa o path
        setState(() {
          _imagePath = image.path;
          _imageBytes = null;
        });
      }
    }
  }

  void _removeImage() {
    setState(() {
      _imagePath = null;
      _imageBytes = null;
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Permissão de localização negada'),
                backgroundColor: Color(AppConstants.deleteRed),
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Permissão de localização negada permanentemente. Ative nas configurações.',
              ),
              backgroundColor: Color(AppConstants.deleteRed),
              duration: Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        _latitudeController.text = position.latitude.toStringAsFixed(6);
        _longitudeController.text = position.longitude.toStringAsFixed(6);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Localização obtida com sucesso!'),
            backgroundColor: Color(AppConstants.primaryGreen),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao obter localização: $e'),
            backgroundColor: const Color(AppConstants.deleteRed),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  String _generateQrCodeId() {
    final uuid = const Uuid();
    final shortId = uuid.v4().substring(0, 8).toUpperCase();

    String categoryCode = 'GEN';
    switch (_selectedCategory) {
      case 'INFRAESTRUTURAS':
        categoryCode = 'INF';
        break;
      case 'PRODUÇÃO':
        categoryCode = 'PRD';
        break;
      case 'HISTÓRIA':
        categoryCode = 'HIS';
        break;
      case 'MEIO AMBIENTE':
        categoryCode = 'AMB';
        break;
      case 'CULTURA':
        categoryCode = 'CUL';
        break;
    }

    return '${AppConstants.qrCodePrefix}.$categoryCode.$shortId';
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final uuid = const Uuid();
      final now = DateTime.now();
      String? finalImagePath = _imagePath;

      // Upload image if it's a new local file (not an existing URL)
      if (_imagePath != null &&
          !_imagePath!.startsWith('http') &&
          !_imagePath!.startsWith('https')) {
        debugPrint(
            'Iniciando upload de imagem. Web: $kIsWeb, Bytes: ${_imageBytes != null}');

        final firestoreService = FirestoreService.instance;

        try {
          if (kIsWeb && _imageBytes != null) {
            finalImagePath = await firestoreService.uploadImageWeb(
              _imageBytes!,
              'content_images',
            );
          } else if (!kIsWeb) {
            finalImagePath = await firestoreService.uploadImage(
              File(_imagePath!),
              'content_images',
            );
          }
          debugPrint('Upload concluído com sucesso: $finalImagePath');
        } catch (uploadError) {
          debugPrint('Erro crítico no upload: $uploadError');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erro ao enviar imagem: $uploadError'),
                backgroundColor: const Color(AppConstants.deleteRed),
              ),
            );
            setState(() {
              _isLoading = false;
            });
          }
          return;
        }
      }

      double? latitude = double.tryParse(_latitudeController.text);
      double? longitude = double.tryParse(_longitudeController.text);

      final content = ContentModel(
        id: isEditing ? widget.content!.id : uuid.v4(),
        qrCodeId: isEditing ? widget.content!.qrCodeId : _generateQrCodeId(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory!,
        imagePath: finalImagePath,
        latitude: latitude,
        longitude: longitude,
        createdAt: isEditing ? widget.content!.createdAt : now,
        updatedAt: now,
      );

      final contentProvider = context.read<ContentProvider>();
      final success = isEditing
          ? await contentProvider.updateContent(content)
          : await contentProvider.createContent(content);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEditing
                    ? 'Conteúdo atualizado com sucesso'
                    : 'Conteúdo criado com sucesso',
              ),
              backgroundColor: const Color(AppConstants.primaryGreen),
            ),
          );
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEditing
                    ? 'Erro ao atualizar conteúdo'
                    : 'Erro ao criar conteúdo',
              ),
              backgroundColor: const Color(AppConstants.deleteRed),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error saving content: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: const Color(AppConstants.deleteRed),
          ),
        );
      }
    }
  }

  Color _getDescriptionCounterColor() {
    if (_descriptionLength > _maxDescriptionLength * 0.9) {
      return const Color(AppConstants.deleteRed);
    } else if (_descriptionLength > _maxDescriptionLength * 0.7) {
      return Colors.orange;
    }
    return const Color(AppConstants.textGray);
  }

  Widget _buildImagePreview(ThemeProvider themeProvider) {
    if (_imagePath == null) return const SizedBox.shrink();

    // Verifica se é uma URL (Firebase Storage)
    final isNetworkImage =
        _imagePath!.startsWith('http') || _imagePath!.startsWith('https');

    if (isNetworkImage) {
      return CachedNetworkImage(
        imageUrl: _imagePath!,
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: double.infinity,
          height: 200,
          color: themeProvider.cardMediumColor,
          child: const Center(
            child: CircularProgressIndicator(
              color: Color(AppConstants.primaryGreen),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: double.infinity,
          height: 200,
          color: themeProvider.cardMediumColor,
          child: Icon(
            Icons.broken_image,
            size: 48,
            color: themeProvider.textSecondaryColor,
          ),
        ),
      );
    }

    // Se estiver na Web e não for URL, usa os bytes (novo upload)
    if (kIsWeb) {
      if (_imageBytes != null) {
        return Image.memory(
          _imageBytes!,
          width: double.infinity,
          height: 200,
          fit: BoxFit.cover,
        );
      } else {
        // Fallback para blob URLs do image_picker na web
        return Image.network(
          _imagePath!,
          width: double.infinity,
          height: 200,
          fit: BoxFit.cover,
        );
      }
    }

    // Mobile/Desktop: arquivo local
    return Image.file(
      File(_imagePath!),
      width: double.infinity,
      height: 200,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: double.infinity,
          height: 200,
          color: themeProvider.cardMediumColor,
          child: Icon(
            Icons.broken_image,
            size: 48,
            color: themeProvider.textSecondaryColor,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Editar Conteúdo' : 'Novo Conteúdo',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(AppConstants.primaryGreen),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Container(
          constraints: kIsWeb ? const BoxConstraints(maxWidth: 900) : null,
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Title field
                TextFormField(
                  controller: _titleController,
                  validator: Validators.validateTitle,
                  decoration: InputDecoration(
                    labelText: 'Título *',
                    labelStyle: TextStyle(
                      color: themeProvider.textSecondaryColor,
                    ),
                    prefixIcon: const Icon(
                      Icons.title,
                      color: Color(AppConstants.primaryGreen),
                    ),
                    filled: true,
                    fillColor: themeProvider.cardColor,
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
                  style: TextStyle(color: themeProvider.textColor),
                ),
                const SizedBox(height: 16),

                // Category dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  validator: Validators.validateCategory,
                  decoration: InputDecoration(
                    labelText: 'Categoria *',
                    labelStyle: TextStyle(
                      color: themeProvider.textSecondaryColor,
                    ),
                    prefixIcon: const Icon(
                      Icons.category,
                      color: Color(AppConstants.primaryGreen),
                    ),
                    filled: true,
                    fillColor: themeProvider.cardColor,
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
                  dropdownColor: themeProvider.cardColor,
                  style: TextStyle(color: themeProvider.textColor),
                  items: AppConstants.categories.map((category) {
                    return DropdownMenuItem(
                        value: category,
                        child: Text(
                          category,
                          style: TextStyle(color: themeProvider.textColor),
                        ));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Description field with counter
                TextFormField(
                  controller: _descriptionController,
                  validator: Validators.validateDescription,
                  maxLines: 6,
                  maxLength: _maxDescriptionLength,
                  decoration: InputDecoration(
                    labelText: 'Descrição *',
                    labelStyle: TextStyle(
                      color: themeProvider.textSecondaryColor,
                    ),
                    alignLabelWithHint: true,
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 100),
                      child: Icon(
                        Icons.description,
                        color: Color(AppConstants.primaryGreen),
                      ),
                    ),
                    filled: true,
                    fillColor: themeProvider.cardColor,
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
                    counterText: '',
                  ),
                  style: TextStyle(color: themeProvider.textColor),
                ),
                // Custom character counter
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.text_fields,
                        size: 14,
                        color: _getDescriptionCounterColor(),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$_descriptionLength/$_maxDescriptionLength caracteres',
                        style: TextStyle(
                          color: _getDescriptionCounterColor(),
                          fontSize: 12,
                          fontWeight:
                              _descriptionLength > _maxDescriptionLength * 0.9
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Image picker with preview
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: themeProvider.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _imagePath != null
                          ? const Color(
                              AppConstants.primaryGreen,
                            ).withValues(alpha: 0.3)
                          : Colors.transparent,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.image,
                            color: Color(AppConstants.primaryGreen),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Imagem (opcional)',
                            style: TextStyle(
                              color: themeProvider.textSecondaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Image preview or placeholder
                      if (_imagePath != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            children: [
                              // Lógica robusta para preview de imagem (Web vs Mobile, URL vs Local)
                              _buildImagePreview(themeProvider),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: IconButton(
                                  onPressed: _removeImage,
                                  icon: const Icon(Icons.close),
                                  style: IconButton.styleFrom(
                                    backgroundColor: const Color(
                                      AppConstants.deleteRed,
                                    ),
                                    foregroundColor: Colors.white,
                                  ),
                                  tooltip: 'Remover imagem',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ] else ...[
                        Container(
                          width: double.infinity,
                          height: 150,
                          decoration: BoxDecoration(
                            color: themeProvider.cardMediumColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: themeProvider.textSecondaryColor
                                  .withValues(alpha: 0.2),
                              style: BorderStyle.solid,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate,
                                size: 48,
                                color: themeProvider.textSecondaryColor
                                    .withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Nenhuma imagem selecionada',
                                style: TextStyle(
                                  color: themeProvider.textSecondaryColor
                                      .withValues(alpha: 0.5),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _pickImage,
                          icon: Icon(
                            _imagePath != null
                                ? Icons.edit
                                : Icons.add_photo_alternate,
                          ),
                          label: Text(
                            _imagePath != null
                                ? 'Alterar Imagem'
                                : 'Selecionar Imagem',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                                const Color(AppConstants.primaryGreen),
                            side: const BorderSide(
                              color: Color(AppConstants.primaryGreen),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Location section with GPS button
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: themeProvider.cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Color(AppConstants.primaryGreen),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Localização (opcional)',
                                style: TextStyle(
                                  color: themeProvider.textSecondaryColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          // GPS Button
                          OutlinedButton.icon(
                            onPressed:
                                _isLoadingLocation ? null : _getCurrentLocation,
                            icon: _isLoadingLocation
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(AppConstants.primaryGreen),
                                    ),
                                  )
                                : const Icon(Icons.my_location, size: 18),
                            label: const Text('GPS'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(
                                AppConstants.primaryGreen,
                              ),
                              side: const BorderSide(
                                color: Color(AppConstants.primaryGreen),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _latitudeController,
                              decoration: InputDecoration(
                                labelText: 'Latitude',
                                labelStyle: TextStyle(
                                  color: themeProvider.textSecondaryColor,
                                ),
                                filled: true,
                                fillColor: themeProvider.cardMediumColor,
                                border: const OutlineInputBorder(
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              style: TextStyle(color: themeProvider.textColor),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                                signed: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _longitudeController,
                              decoration: InputDecoration(
                                labelText: 'Longitude',
                                labelStyle: TextStyle(
                                  color: themeProvider.textSecondaryColor,
                                ),
                                filled: true,
                                fillColor: themeProvider.cardMediumColor,
                                border: const OutlineInputBorder(
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              style: TextStyle(color: themeProvider.textColor),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                                signed: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Save button
                CustomButton(
                  text: isEditing ? 'Salvar Alterações' : 'Criar Conteúdo',
                  onPressed: _handleSave,
                  isLoading: _isLoading,
                  icon: isEditing ? Icons.save : Icons.add,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
