import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/auth_controller.dart';
import '../models/app_user.dart';
import 'landing_page.dart';
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
  final _dateOfBirthController = TextEditingController();

  int _stepIndex = 0;
  String? _selectedGender;
  DateTime _selectedDateOfBirth = DateTime.now();
  bool _hasSelectedDateOfBirth = false;
  bool _isPasswordVisible = false;

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

  String _friendlySignUpError(String rawMessage) {
    final raw = rawMessage.toLowerCase();

    if (raw.contains('rate limit')) {
      return 'Too many sign-up attempts. Please wait a moment and try again.';
    }
    if (raw.contains('already') ||
        raw.contains('duplicate') ||
        raw.contains('unique') ||
        raw.contains('key-pair') ||
        raw.contains('violates')) {
      return 'This username or email is already in use. Please choose another one.';
    }
    if (raw.contains('network') || raw.contains('socket') || raw.contains('timeout')) {
      return 'Network issue detected. Please check your connection and try again.';
    }
    if (raw.contains('permission') || raw.contains('row-level security')) {
      return 'Unable to create account right now. Please try again later.';
    }

    return 'Unable to sign up right now. Please try again.';
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
    );

    final success = await _authController.signUp(profile: profile);

    if (!mounted) {
      return;
    }

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlySignUpError(_authController.errorMessage))),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('New account created successfully. Please login to continue.'),
        duration: Duration(seconds: 2),
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) {
      return;
    }

    Navigator.pushNamedAndRemoveUntil(
      context,
      LandingPage.routeName,
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
                                          : Text(isLastStep ? 'Sign Up' : 'Next'),
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
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedGender = 'male';
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _selectedGender == 'male'
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                      width: _selectedGender == 'male' ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: _selectedGender == 'male'
                        ? theme.colorScheme.primary.withValues(alpha: 0.1)
                        : Colors.transparent,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(
                        'lib/Image/Bot-Gender-Male.png',
                        width: 80,
                        height: 80,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Male',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _selectedGender == 'male'
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedGender = 'female';
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _selectedGender == 'female'
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                      width: _selectedGender == 'female' ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: _selectedGender == 'female'
                        ? theme.colorScheme.primary.withValues(alpha: 0.1)
                        : Colors.transparent,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(
                        'lib/Image/Bot-Gender-Female.png',
                        width: 80,
                        height: 80,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Female',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _selectedGender == 'female'
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
          decoration: InputDecoration(
            labelText: 'Height (cm)',
            helperText: 'Max 3 digits (e.g., 180)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.colorScheme.error, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
            ),
            errorStyle: TextStyle(color: theme.colorScheme.error),
          ),
          inputFormatters: [
            LengthLimitingTextInputFormatter(3),
          ],
          validator: (value) {
            final number = double.tryParse(value?.trim() ?? '');
            if (number == null || number <= 0) {
              return 'Please enter a valid height';
            }
            if (number > 999) {
              return 'Height cannot exceed 999 cm';
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
          decoration: InputDecoration(
            labelText: 'Current Weight (kg)',
            helperText: 'Max 3 digits (e.g., 75)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.colorScheme.error, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
            ),
            errorStyle: TextStyle(color: theme.colorScheme.error),
          ),
          inputFormatters: [
            LengthLimitingTextInputFormatter(3),
          ],
          validator: (value) {
            final number = double.tryParse(value?.trim() ?? '');
            if (number == null || number <= 0) {
              return 'Please enter a valid current weight';
            }
            if (number > 999) {
              return 'Weight cannot exceed 999 kg';
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
          decoration: InputDecoration(
            labelText: 'Target Weight (kg)',
            helperText: 'Max 3 digits (e.g., 70)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.colorScheme.error, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
            ),
            errorStyle: TextStyle(color: theme.colorScheme.error),
          ),
          inputFormatters: [
            LengthLimitingTextInputFormatter(3),
          ],
          validator: (value) {
            final number = double.tryParse(value?.trim() ?? '');
            if (number == null || number <= 0) {
              return 'Please enter a valid target weight';
            }
            if (number > 999) {
              return 'Weight cannot exceed 999 kg';
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
          decoration: InputDecoration(
            labelText: 'Username',
            helperText: '3-25 characters',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.colorScheme.error, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
            ),
            errorStyle: TextStyle(color: theme.colorScheme.error),
          ),
          inputFormatters: [
            LengthLimitingTextInputFormatter(25),
          ],
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a username';
            }
            if (value.trim().length < 3) {
              return 'Username must be at least 3 characters';
            }
            if (value.trim().length > 25) {
              return 'Username cannot exceed 25 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          decoration: InputDecoration(
            labelText: 'Password',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
              icon: Icon(
                _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
              ),
            ),
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
      ],
    );
  }
}

