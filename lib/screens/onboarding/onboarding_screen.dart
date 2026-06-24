import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/auth_api.dart';
import '../../routes/app_routes.dart';
import '../../widgets/glass_button.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glass_textfield.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentStep = 0;
  bool _isSaving = false;

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _genderController = TextEditingController();
  final _vehicleNumController = TextEditingController();
  final _emergNameController = TextEditingController();
  final _emergPhoneController = TextEditingController();
  final _hoursController = TextEditingController();
  String _vehicleType = 'Car';

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _genderController.dispose();
    _vehicleNumController.dispose();
    _emergNameController.dispose();
    _emergPhoneController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_validateCurrentStep()) {
      if (_currentStep < 7) {
        setState(() => _currentStep++);
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        _submitOnboarding();
      }
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validateCurrentStep() {
    String error = '';
    switch (_currentStep) {
      case 0:
        if (_nameController.text.trim().isEmpty) {
          error = 'Please enter your name.';
        }
        break;
      case 1:
        final age = int.tryParse(_ageController.text.trim());
        if (age == null || age <= 0) {
          error = 'Please enter a valid age.';
        }
        break;
      case 2:
        if (_genderController.text.trim().isEmpty) {
          error = 'Please enter your gender.';
        }
        break;
      case 3:
        if (_vehicleNumController.text.trim().isEmpty) {
          error = 'Please enter your vehicle number.';
        }
        break;
      case 4:
        if (_vehicleType.isEmpty) {
          error = 'Please select a vehicle type.';
        }
        break;
      case 5:
        if (_emergNameController.text.trim().isEmpty) {
          error = 'Please enter emergency contact name.';
        }
        break;
      case 6:
        if (_emergPhoneController.text.trim().isEmpty) {
          error = 'Please enter emergency contact number.';
        }
        break;
      case 7:
        final hours = int.tryParse(_hoursController.text.trim());
        if (hours == null || hours <= 0) {
          error = 'Please enter valid driving hours.';
        }
        break;
    }

    if (error.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.urgent),
      );
      return false;
    }
    return true;
  }

  Future<void> _submitOnboarding() async {
    setState(() => _isSaving = true);
    try {
      final name = _nameController.text.trim();
      final age = int.parse(_ageController.text.trim());
      final gender = _genderController.text.trim();
      final vehicleNumber = _vehicleNumController.text.trim();
      final emergencyName = _emergNameController.text.trim();
      final emergencyPhone = _emergPhoneController.text.trim();
      final hours = int.parse(_hoursController.text.trim());

      await AuthApi().saveOnboarding(
        fullName: name,
        age: age,
        gender: gender,
        vehicleNumber: vehicleNumber,
        vehicleType: _vehicleType,
        emergencyContactName: emergencyName,
        emergencyContactNumber: emergencyPhone,
        averageDailyDrivingHours: hours,
      );

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.home,
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save details: ${e.toString()}'),
            backgroundColor: AppColors.urgent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Setup'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: GlassCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Step progress header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Step ${_currentStep + 1} of 8',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.darkSecondaryText
                                : AppColors.lightSecondaryText,
                          ),
                        ),
                        Text(
                          '${((_currentStep + 1) / 8 * 100).round()}%',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.info,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (_currentStep + 1) / 8,
                        backgroundColor:
                            (isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder)
                                .withValues(alpha: 0.5),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.info,
                        ),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // PageView container
                    SizedBox(
                      height: 190,
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildStepPage(
                            title: 'What is your full name?',
                            subtitle: 'Enter your legal first and last name.',
                            input: GlassTextField(
                              controller: _nameController,
                              label: 'Full Name',
                              icon: Icons.person_outline,
                              textInputAction: TextInputAction.done,
                            ),
                          ),
                          _buildStepPage(
                            title: 'How old are you?',
                            subtitle:
                                'We use age for driving pattern safety models.',
                            input: GlassTextField(
                              controller: _ageController,
                              label: 'Age',
                              icon: Icons.cake_outlined,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.done,
                            ),
                          ),
                          _buildStepPage(
                            title: 'What is your gender?',
                            subtitle: 'This helps customize your profile.',
                            input: GlassTextField(
                              controller: _genderController,
                              label: 'Gender',
                              icon: Icons.badge_outlined,
                              textInputAction: TextInputAction.done,
                            ),
                          ),
                          _buildStepPage(
                            title: 'What is your vehicle number?',
                            subtitle:
                                'Enter your license plate registration number.',
                            input: GlassTextField(
                              controller: _vehicleNumController,
                              label: 'Vehicle Number',
                              icon: Icons.pin_outlined,
                              textInputAction: TextInputAction.done,
                            ),
                          ),
                          _buildStepPage(
                            title: 'What type of vehicle do you drive?',
                            subtitle: 'Select your vehicle classification.',
                            input: DropdownButtonFormField<String>(
                              initialValue: _vehicleType,
                              decoration: const InputDecoration(
                                labelText: 'Vehicle Type',
                                prefixIcon: Icon(Icons.directions_car_outlined),
                              ),
                              items: const ['Bike', 'Car', 'Truck', 'Bus']
                                  .map(
                                    (type) => DropdownMenuItem(
                                      value: type,
                                      child: Text(type),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) => setState(
                                () => _vehicleType = value ?? _vehicleType,
                              ),
                            ),
                          ),
                          _buildStepPage(
                            title: 'Who is your emergency contact?',
                            subtitle:
                                'We will notify them in case of safety alerts.',
                            input: GlassTextField(
                              controller: _emergNameController,
                              label: 'Emergency Contact Name',
                              icon: Icons.contact_emergency_outlined,
                              textInputAction: TextInputAction.done,
                            ),
                          ),
                          _buildStepPage(
                            title: 'What is their contact number?',
                            subtitle:
                                'Provide their active mobile phone number.',
                            input: GlassTextField(
                              controller: _emergPhoneController,
                              label: 'Emergency Contact Number',
                              icon: Icons.phone_in_talk_outlined,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.done,
                            ),
                          ),
                          _buildStepPage(
                            title: 'How many hours do you drive daily?',
                            subtitle:
                                'Estimate your average time behind the wheel.',
                            input: GlassTextField(
                              controller: _hoursController,
                              label: 'Average Daily Driving Hours',
                              icon: Icons.schedule_outlined,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.done,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Actions Row
                    Row(
                      children: [
                        if (_currentStep > 0) ...[
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isSaving ? null : _prevStep,
                              icon: const Icon(Icons.arrow_back_rounded),
                              label: const Text('Previous'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(22),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                        ],
                        Expanded(
                          flex: 2,
                          child: GlassButton(
                            label: _isSaving
                                ? 'Saving...'
                                : (_currentStep == 7 ? 'Finish Setup' : 'Next'),
                            icon: _currentStep == 7
                                ? Icons.check_circle_outline
                                : Icons.arrow_forward_rounded,
                            onPressed: _isSaving ? () {} : _nextStep,
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
    );
  }

  Widget _buildStepPage({
    required String title,
    required String subtitle,
    required Widget input,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkSecondaryText
                : AppColors.lightSecondaryText,
          ),
        ),
        const SizedBox(height: 28),
        input,
      ],
    );
  }
}
