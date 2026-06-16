import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shiftsync/core/constants/app_colors.dart';
import 'package:shiftsync/features/admin/presentation/providers/admin_provider.dart';
import 'package:shiftsync/features/auth/data/models/user_model.dart';

class OnboardEmployeeScreen extends ConsumerStatefulWidget {
  final List<UserModel> employers;

  const OnboardEmployeeScreen({super.key, required this.employers});

  @override
  ConsumerState<OnboardEmployeeScreen> createState() => _OnboardEmployeeScreenState();
}

class _OnboardEmployeeScreenState extends ConsumerState<OnboardEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _employeeIdController = TextEditingController();
  String? _selectedEmployerId;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _employeeIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Onboard Staff Employee',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.secondary),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: AppColors.tertiary.withOpacity(0.15)),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          AppColors.tertiary.withOpacity(0.05),
                          AppColors.tertiary.withOpacity(0.02),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person_add, color: AppColors.tertiary, size: 32),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Employee Registration',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.secondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Register a new employee. A welcome email containing their temporary password will be sent automatically.',
                                style: TextStyle(fontSize: 11, color: AppColors.outline),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Employee Full Name',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    if (!RegExp(r'^[\w-\.\+]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Temporary Password',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  validator: (v) => v == null || v.length < 6 ? 'Password must be at least 6 characters' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String?>(
                  value: _selectedEmployerId,
                  decoration: const InputDecoration(
                    labelText: 'Assign to Employer Org',
                    prefixIcon: Icon(Icons.business),
                  ),
                  hint: const Text('None (No Assignment)'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('None (No Assignment)'),
                    ),
                    ...widget.employers.map((emp) {
                      return DropdownMenuItem<String?>(
                        value: emp.employerId,
                        child: Text(emp.fullName),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedEmployerId = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _employeeIdController,
                  decoration: const InputDecoration(
                    labelText: 'Custom Employee ID (Optional)',
                    prefixIcon: Icon(Icons.badge),
                    hintText: 'Leave blank to auto-generate',
                  ),
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.tertiary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isLoading
                        ? null
                        : () async {
                            if (_formKey.currentState!.validate()) {
                              setState(() => _isLoading = true);
                              try {
                                final adminRepo = ref.read(adminRepositoryProvider);
                                await adminRepo.onboardUser(
                                  email: _emailController.text.trim(),
                                  password: _passwordController.text,
                                  fullName: _nameController.text.trim(),
                                  role: UserRole.employee,
                                  employerId: _selectedEmployerId,
                                  employeeId: _employeeIdController.text.trim().isEmpty ? null : _employeeIdController.text.trim(),
                                );
                                if (mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Onboarded staff "${_nameController.text}" successfully!'),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                                );
                              } finally {
                                if (mounted) {
                                  setState(() => _isLoading = false);
                                }
                              }
                            }
                          },
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('ONBOARD STAFF', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
