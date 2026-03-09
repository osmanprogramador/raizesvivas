import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../widgets/custom_button.dart';

class AdminFormScreen extends StatefulWidget {
  final UserModel? user; // Null for create, non-null for edit

  const AdminFormScreen({super.key, this.user});

  @override
  State<AdminFormScreen> createState() => _AdminFormScreenState();
}

class _AdminFormScreenState extends State<AdminFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();

  UserRole _selectedRole = UserRole.viewer;
  bool _isLoading = false;

  bool get isEditing => widget.user != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _usernameController.text = widget.user!.username;
      _fullNameController.text = widget.user!.fullName;
      _emailController.text = widget.user!.email;
      _selectedRole = widget.user!.role;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();
      final currentUser = context.read<AuthProvider>().currentUser;

      // For new users created by admin, we use the email as the temporary ID
      // so it can be found when the user actually signs up.
      // For existing users (edits), we keep the original ID (which is the UID).
      final docId = isEditing ? widget.user!.id : _emailController.text.trim();

      final user = UserModel(
        id: docId,
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        fullName: _fullNameController.text.trim(),
        phone: isEditing ? widget.user!.phone : null,
        role: _selectedRole,
        isActive: isEditing ? widget.user!.isActive : true,
        mustChangePassword: false, // Handled by Firebase Auth reset if needed
        createdAt: isEditing ? widget.user!.createdAt : now,
        createdBy: isEditing ? widget.user!.createdBy : currentUser?.username,
        updatedAt: now,
        updatedBy: currentUser?.username,
        lastLoginAt: isEditing ? widget.user!.lastLoginAt : null,
      );

      final provider = context.read<AuthProvider>();
      final success = isEditing
          ? await provider.updateUser(user)
          : await provider.createUser(user);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEditing
                    ? 'Usuário atualizado com sucesso'
                    : 'Usuário pré-aprovado com sucesso',
              ),
              backgroundColor: const Color(AppConstants.primaryGreen),
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Erro ao salvar usuário. Verifique se o ID/Email já existe.',
              ),
              backgroundColor: Color(AppConstants.deleteRed),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro inesperado: $e'),
            backgroundColor: const Color(AppConstants.deleteRed),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Editar Usuário' : 'Novo Usuário',
          style: TextStyle(color: themeProvider.textColor),
        ),
        backgroundColor: themeProvider.cardColor,
        iconTheme: IconThemeData(color: themeProvider.textColor),
      ),
      body: Center(
        child: Container(
          constraints: kIsWeb ? const BoxConstraints(maxWidth: 800) : null,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Personal Info Section
                  Text(
                    'Informações Pessoais',
                    style: TextStyle(
                      color: const Color(AppConstants.primaryGreen),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Full Name
                  TextFormField(
                    controller: _fullNameController,
                    validator: Validators.validateFullName,
                    decoration: _buildInputDecoration(
                      'Nome Completo *',
                      Icons.person,
                      themeProvider,
                    ),
                    style: TextStyle(color: themeProvider.textColor),
                  ),
                  const SizedBox(height: 16),

                  // Account Info Section
                  Text(
                    'Informações da Conta',
                    style: TextStyle(
                      color: const Color(AppConstants.primaryGreen),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Username
                  TextFormField(
                    controller: _usernameController,
                    validator: Validators.validateUsername,
                    decoration: _buildInputDecoration(
                      'Nome de Usuário *',
                      Icons.alternate_email,
                      themeProvider,
                    ),
                    style: TextStyle(color: themeProvider.textColor),
                    //enabled: !isEditing, // Allow fix if needed
                  ),
                  const SizedBox(height: 16),

                  // Email
                  TextFormField(
                    controller: _emailController,
                    validator: Validators.validateEmail,
                    decoration: _buildInputDecoration(
                      'Email *',
                      Icons.email,
                      themeProvider,
                    ),
                    style: TextStyle(color: themeProvider.textColor),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),

                  // Phone
                  Text(
                    'Telefone (opcional)', // TODO: Add field
                    style: TextStyle(
                      color: themeProvider.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Role Selection
                  Text(
                    'Nível de Acesso',
                    style: TextStyle(
                      color: const Color(AppConstants.primaryGreen),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: themeProvider.cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<UserRole>(
                        value: _selectedRole,
                        dropdownColor: themeProvider.cardMediumColor,
                        style: TextStyle(color: themeProvider.textColor),
                        icon: const Icon(Icons.arrow_drop_down,
                            color: Color(AppConstants.primaryGreen)),
                        items: UserRole.values.map((role) {
                          String label = 'Visualizador';
                          if (role == UserRole.admin) label = 'Administrador';
                          if (role == UserRole.superAdmin) {
                            label = 'Super Admin';
                          }
                          if (role == UserRole.editor) label = 'Editor';

                          return DropdownMenuItem(
                            value: role,
                            child: Text(label),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedRole = value;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Save Button
                  CustomButton(
                    text: isEditing ? 'Salvar Alterações' : 'Criar Usuário',
                    onPressed: _handleSave,
                    isLoading: _isLoading,
                    icon: isEditing ? Icons.save : Icons.person_add,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(
      String label, IconData icon, ThemeProvider themeProvider) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: themeProvider.textSecondaryColor,
      ),
      prefixIcon: Icon(
        icon,
        color: themeProvider.textSecondaryColor,
      ),
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
    );
  }
}
