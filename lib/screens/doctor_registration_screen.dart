import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';

class DoctorRegistrationScreen extends StatefulWidget {
  const DoctorRegistrationScreen({super.key});

  @override
  State<DoctorRegistrationScreen> createState() => _DoctorRegistrationScreenState();
}

class _DoctorRegistrationScreenState extends State<DoctorRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _licenseController = TextEditingController();
  final _hospitalController = TextEditingController();
  
  String _selectedSpecialization = 'General Medicine';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;

  final List<String> _specializations = [
    'General Medicine',
    'Internal Medicine',
    'Cardiology',
    'Dermatology',
    'Emergency Medicine',
    'Family Medicine',
    'Gastroenterology',
    'Neurology',
    'Oncology',
    'Orthopedics',
    'Pediatrics',
    'Psychiatry',
    'Radiology',
    'Surgery',
    'Other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _licenseController.dispose();
    _hospitalController.dispose();
    super.dispose();
  }

  Future<void> _registerDoctor() async {
    if (!_formKey.currentState!.validate() || !_acceptedTerms) {
      if (!_acceptedTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please accept the terms and conditions'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    final result = await AuthService.registerDoctor(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
      licenseNumber: _licenseController.text.trim(),
      specialization: _selectedSpecialization,
      hospital: _hospitalController.text.trim().isNotEmpty 
          ? _hospitalController.text.trim() 
          : null,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? Colors.green : Colors.red,
        ),
      );

      if (result.success) {
        // Navigate to verification pending screen or login
        context.go('/doctor-verification');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal[600]!, Colors.teal[400]!, Colors.white],
            stops: const [0.0, 0.3, 0.7],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => context.go('/login'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Doctor Registration',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Form Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    children: [
                      // Professional Header
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.teal[50],
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Icon(
                                Icons.medical_services,
                                size: 40,
                                color: Colors.teal[600],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Join as Healthcare Professional',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Register to provide medical insights and help patients with their health concerns.',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Registration Form
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Personal Information Section
                              _buildSectionHeader('Personal Information', Icons.person),
                              const SizedBox(height: 16),
                              
                              _buildTextField(
                                controller: _nameController,
                                label: 'Full Name',
                                icon: Icons.person_outline,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your full name';
                                  }
                                  return null;
                                },
                              ),
                              
                              const SizedBox(height: 16),
                              
                              _buildTextField(
                                controller: _emailController,
                                label: 'Email Address',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                    return 'Please enter a valid email address';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 24),

                              // Professional Information Section
                              _buildSectionHeader('Professional Information', Icons.work),
                              const SizedBox(height: 16),
                              
                              _buildTextField(
                                controller: _licenseController,
                                label: 'Medical License Number',
                                icon: Icons.badge_outlined,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your medical license number';
                                  }
                                  if (value.trim().length < 5) {
                                    return 'License number must be at least 5 characters';
                                  }
                                  return null;
                                },
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Specialization Dropdown
                              DropdownButtonFormField<String>(
                                initialValue: _selectedSpecialization,
                                decoration: InputDecoration(
                                  labelText: 'Specialization',
                                  prefixIcon: Icon(Icons.local_hospital, color: Colors.teal[600]),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.teal[600]!),
                                  ),
                                ),
                                items: _specializations.map((spec) {
                                  return DropdownMenuItem(
                                    value: spec,
                                    child: Text(spec),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedSpecialization = value!;
                                  });
                                },
                              ),
                              
                              const SizedBox(height: 16),
                              
                              _buildTextField(
                                controller: _hospitalController,
                                label: 'Hospital/Clinic (Optional)',
                                icon: Icons.local_hospital_outlined,
                              ),

                              const SizedBox(height: 24),

                              // Security Section
                              _buildSectionHeader('Security', Icons.security),
                              const SizedBox(height: 16),
                              
                              _buildTextField(
                                controller: _passwordController,
                                label: 'Password',
                                icon: Icons.lock_outline,
                                obscureText: _obscurePassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a password';
                                  }
                                  if (value.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                              
                              const SizedBox(height: 16),
                              
                              _buildTextField(
                                controller: _confirmPasswordController,
                                label: 'Confirm Password',
                                icon: Icons.lock_outline,
                                obscureText: _obscureConfirmPassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword = !_obscureConfirmPassword;
                                    });
                                  },
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please confirm your password';
                                  }
                                  if (value != _passwordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 24),

                              // Terms and Conditions
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Checkbox(
                                    value: _acceptedTerms,
                                    onChanged: (value) {
                                      setState(() {
                                        _acceptedTerms = value ?? false;
                                      });
                                    },
                                    activeColor: Colors.teal[600],
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _acceptedTerms = !_acceptedTerms;
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 12),
                                        child: RichText(
                                          text: TextSpan(
                                            style: TextStyle(
                                              color: Colors.grey[700],
                                              fontSize: 14,
                                            ),
                                            children: [
                                              const TextSpan(
                                                text: 'I agree to the ',
                                              ),
                                              TextSpan(
                                                text: 'Terms of Service',
                                                style: TextStyle(
                                                  color: Colors.teal[600],
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const TextSpan(text: ' and '),
                                              TextSpan(
                                                text: 'Privacy Policy',
                                                style: TextStyle(
                                                  color: Colors.teal[600],
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const TextSpan(
                                                text: ' for healthcare professionals.',
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 32),

                              // Register Button
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _registerDoctor,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal[600],
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Text(
                                          'Register as Doctor',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Login Link
                              Center(
                                child: TextButton(
                                  onPressed: () => context.go('/login'),
                                  child: RichText(
                                    text: TextSpan(
                                      style: TextStyle(color: Colors.grey[600]),
                                      children: [
                                        const TextSpan(text: 'Already have an account? '),
                                        TextSpan(
                                          text: 'Sign In',
                                          style: TextStyle(
                                            color: Colors.teal[600],
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.teal[600]),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.teal[600]),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.teal[600]!),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }
}
