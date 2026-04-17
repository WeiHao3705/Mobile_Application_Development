import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';
import '../models/app_user.dart';
import 'landing_page.dart';
import 'main_navigation.dart';

class SignUpPages extends StatefulWidget {
  static const routeName = '/signup';

  const SignUpPages({super.key, required this.authController});

  final AuthController authController;

  @override
  State<SignUpPages> createState() => _SignUpState();
}

class _SignUpState extends State<SignUpPages> {
  static const int _lastStepIndex = 5;

  final _formKey = GlobalKey<FormState>();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _targetWeightController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dateOfBirthController = TextEditingController();

  int _stepIndex = 0;
  String? _selectedGender;
  DateTime _selectedDateOfBirth = DateTime.now();
  bool _hasSelectedDateOfBirth = false;

  AuthController get _authController => widget.authController;

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _targetWeightController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _dateOfBirthController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final initialDate = _hasSelectedDateOfBirth
        ? _selectedDateOfBirth
        : DateTime(now.year - 18, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme,
            dialogTheme: DialogThemeData(
              backgroundColor: theme.colorScheme.surface,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _selectedDateOfBirth = picked;
      _hasSelectedDateOfBirth = true;
      _dateOfBirthController.text =
          '${picked.year}-${_twoDigits(picked.month)}-${_twoDigits(picked.day)}';
    });
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  void _goToLanding() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      LandingPage.routeName,
      (route) => false,
    );
  }

  void _quitSignUp() {
    FocusScope.of(context).unfocus();
    _goToLanding();
  }

  void _goBackStep() {
    FocusScope.of(context).unfocus();
    if (_stepIndex == 0) {
      _goToLanding();
      return;
    }

    setState(() {
      _stepIndex -= 1;
    });
  }

  void _goNext() {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _stepIndex += 1;
    });
  }

  Future<void> _handleSignUp() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    final selectedGender = _selectedGender;
    if (selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your gender')),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    final profile = SignUpProfileData(
      gender: selectedGender,
      dateOfBirth: _selectedDateOfBirth,
      height: double.parse(_heightController.text.trim()),
      currentWeight: double.parse(_weightController.text.trim()),
      targetWeight: double.parse(_targetWeightController.text.trim()),
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      email: _emailController.text.trim(),
      fullName: _fullNameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
    );

    final success = await _authController.signUp(profile: profile);

    if (!mounted) {
      return;
    }

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_authController.errorMessage)),
      );
      return;
    }

    Navigator.pushNamedAndRemoveUntil(
      context,
      MainNavigation.routeName,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLastStep = _stepIndex == _lastStepIndex;

    return AnimatedBuilder(
      animation: _authController,
      builder: (context, _) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) {
              return;
            }
            _goBackStep();
          },
          child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _authController.isLoading ? null : _goBackStep,
              ),
              backgroundColor: theme.colorScheme.surface,
              foregroundColor: theme.colorScheme.onSurface,
              title: Text('Sign Up (${_stepIndex + 1}/6)'),
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Card(
                      color: theme.colorScheme.surface,
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              LinearProgressIndicator(
                                value: (_stepIndex + 1) / 6,
                                backgroundColor: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.18),
                                valueColor: AlwaysStoppedAnimation(
                                    theme.colorScheme.primary),
                              ),
                              const SizedBox(height: 20),
                              Expanded(
                                child: SingleChildScrollView(
                                  child: _buildStepFields(theme),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _authController.isLoading ? null : _quitSignUp,
                                      icon: const Icon(Icons.close),
                                      label: const Text('Quit'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _authController.isLoading
                                          ? null
                                          : isLastStep
                                              ? _handleSignUp
                                              : _goNext,
                                      child: _authController.isLoading
                                          ? SizedBox(
                                              height: 18,
                                              width: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: theme.colorScheme.onPrimary,
                                              ),
                                            )
                                          : Text(isLastStep ? 'Finish Sign Up' : 'Next'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepFields(ThemeData theme) {
    switch (_stepIndex) {
      case 0:
        return _buildGenderStep(theme);
      case 1:
        return _buildDateOfBirthStep(theme);
      case 2:
        return _buildHeightStep(theme);
      case 3:
        return _buildWeightStep(theme);
      case 4:
        return _buildTargetWeightStep(theme);
      case 5:
        return _buildAccountStep(theme);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildGenderStep(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What is your gender?', style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _selectedGender,
          decoration: const InputDecoration(
            labelText: 'Gender',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'male', child: Text('Male')),
            DropdownMenuItem(value: 'female', child: Text('Female')),
            DropdownMenuItem(value: 'other', child: Text('Other')),
          ],
          validator: (value) => value == null ? 'Please select your gender' : null,
          onChanged: (value) {
            setState(() {
              _selectedGender = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildDateOfBirthStep(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What is your date of birth?', style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        TextFormField(
          controller: _dateOfBirthController,
          readOnly: true,
          decoration: const InputDecoration(
            labelText: 'Date of Birth',
            border: OutlineInputBorder(),
            suffixIcon: Icon(Icons.calendar_today),
          ),
          onTap: _pickDateOfBirth,
          validator: (value) {
            if (!_hasSelectedDateOfBirth) {
              return 'Please select your date of birth';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildHeightStep(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What is your height (cm)?', style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        TextFormField(
          controller: _heightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Height (cm)',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            final number = double.tryParse(value?.trim() ?? '');
            if (number == null || number <= 0) {
              return 'Please enter a valid height';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildWeightStep(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What is your current weight (kg)?', style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        TextFormField(
          controller: _weightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Current Weight (kg)',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            final number = double.tryParse(value?.trim() ?? '');
            if (number == null || number <= 0) {
              return 'Please enter a valid current weight';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTargetWeightStep(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What is your target weight (kg)?', style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        TextFormField(
          controller: _targetWeightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Target Weight (kg)',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            final number = double.tryParse(value?.trim() ?? '');
            if (number == null || number <= 0) {
              return 'Please enter a valid target weight';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAccountStep(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Create your account', style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        TextFormField(
          controller: _usernameController,
          decoration: const InputDecoration(
            labelText: 'Username',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a username';
            }
            if (value.trim().length < 3) {
              return 'Username must be at least 3 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password',
            border: OutlineInputBorder(),
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
        const SizedBox(height: 12),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            final text = value?.trim() ?? '';
            if (text.isEmpty) {
              return 'Please enter an email';
            }
            if (!text.contains('@')) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _fullNameController,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your full name';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            final text = value?.trim() ?? '';
            if (text.isEmpty) {
              return 'Please enter your phone number';
            }
            if (text.length < 8) {
              return 'Phone number is too short';
            }
            return null;
          },
        ),
      ],
    );
  }
}
