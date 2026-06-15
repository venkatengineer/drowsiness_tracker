import 'package:flutter/material.dart';

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
  String _vehicleType = 'Car';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Setup')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SectionCard(
                    title: 'Personal Information',
                    children: const [
                      GlassTextField(
                        label: 'Full Name',
                        icon: Icons.person_outline,
                      ),
                      SizedBox(height: 14),
                      GlassTextField(
                        label: 'Age',
                        icon: Icons.cake_outlined,
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(height: 14),
                      GlassTextField(
                        label: 'Gender',
                        icon: Icons.badge_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _SectionCard(
                    title: 'Vehicle Information',
                    children: [
                      const GlassTextField(
                        label: 'Vehicle Number',
                        icon: Icons.pin_outlined,
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
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
                    ],
                  ),
                  const SizedBox(height: 18),
                  _SectionCard(
                    title: 'Emergency Information',
                    children: const [
                      GlassTextField(
                        label: 'Emergency Contact Name',
                        icon: Icons.contact_emergency_outlined,
                      ),
                      SizedBox(height: 14),
                      GlassTextField(
                        label: 'Emergency Contact Number',
                        icon: Icons.phone_in_talk_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _SectionCard(
                    title: 'Driving Preferences',
                    children: const [
                      GlassTextField(
                        label: 'Average Daily Driving Hours',
                        icon: Icons.schedule_outlined,
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  GlassButton(
                    label: 'Complete Setup',
                    icon: Icons.check_circle_outline,
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.home,
                      (_) => false,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }
}
