import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../widgets/custom_button.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('As senhas não conferem'),
          backgroundColor: Color(AppConstants.deleteRed),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authProvider = context.read<AuthProvider>();
    final error = await authProvider.signUp(
      _emailController.text.trim(),
      _passwordController.text,
      _fullNameController.text.trim(),
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (error == null) {
        // Success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conta criada com sucesso!'),
            backgroundColor: Color(AppConstants.primaryGreen),
          ),
        );
        Navigator.pop(
            context); // Return to Login (which will swap to AdminDashboard)
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar conta: $error'),
            backgroundColor: const Color(AppConstants.deleteRed),
          ),
        );
      }
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Cadastro de Usuário',
          style: TextStyle(color: themeProvider.textColor),
        ),
        backgroundColor: themeProvider.cardColor,
        iconTheme: IconThemeData(color: themeProvider.textColor),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Crie sua conta',
                  style: TextStyle(
                    color: themeProvider.textColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Utilize o email cadastrado pelo administrador para ativar seu acesso.',
                  style: TextStyle(
                    color: themeProvider.textSecondaryColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 32),

                // Full Name
                TextFormField(
                  controller: _fullNameController,
                  validator: Validators.validateFullName,
                  decoration: _buildInputDecoration(
                    'Nome Completo',
                    Icons.person,
                    themeProvider,
                  ),
                  style: TextStyle(color: themeProvider.textColor),
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailController,
                  validator: Validators.validateEmail,
                  decoration: _buildInputDecoration(
                    'Email',
                    Icons.email,
                    themeProvider,
                  ),
                  style: TextStyle(color: themeProvider.textColor),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passwordController,
                  validator: Validators.validatePassword,
                  obscureText: _obscurePassword,
                  decoration: _buildInputDecoration(
                    'Senha',
                    Icons.lock,
                    themeProvider,
                  ).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: themeProvider.textSecondaryColor,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  style: TextStyle(color: themeProvider.textColor),
                ),
                const SizedBox(height: 16),

                // Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Confirme sua senha';
                    }
                    if (value != _passwordController.text) {
                      return 'As senhas não conferem';
                    }
                    return null;
                  },
                  obscureText: _obscurePassword,
                  decoration: _buildInputDecoration(
                    'Confirmar Senha',
                    Icons.lock_outline,
                    themeProvider,
                  ),
                  style: TextStyle(color: themeProvider.textColor),
                ),
                const SizedBox(height: 32),

                // Sign Up Button
                CustomButton(
                  text: 'Criar Conta',
                  onPressed: _handleSignUp,
                  isLoading: _isLoading,
                ),
              ],
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(AppConstants.deleteRed),
          width: 1,
        ),
      ),
    );
  }
}
