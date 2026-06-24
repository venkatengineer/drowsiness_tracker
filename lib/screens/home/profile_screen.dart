import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/auth_api.dart';
import '../../routes/app_routes.dart';
import '../../widgets/glass_button.dart';
import '../../widgets/glass_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authApi = AuthApi();
  Future<Map<String, dynamic>>? _userDetailsFuture;

  @override
  void initState() {
    super.initState();
    _userDetailsFuture = _authApi.getUserDetails();
  }

  void _logout() {
    _authApi.logout();
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _userDetailsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.urgent,
                        size: 54,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load profile details.',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        snapshot.error.toString(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AppColors.darkSecondaryText
                              : AppColors.lightSecondaryText,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _userDetailsFuture = _authApi.getUserDetails();
                          });
                        },
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final user = snapshot.data ?? {};
            final username = user['username'] ?? 'User';
            final email = user['email'] ?? 'Not provided';
            final phone = user['phone_number'] ?? 'Not provided';
            final createdAt = user['created_at'] != null
                ? user['created_at'].toString().split(' ')[0]
                : 'Unknown';

            final fullName = user['full_name'] ?? 'Not completed setup';
            final age = user['age'] != null
                ? user['age'].toString()
                : 'Not completed setup';
            final gender = user['gender'] ?? 'Not completed setup';
            final vehicleNumber =
                user['vehicle_number'] ?? 'Not completed setup';
            final vehicleType = user['vehicle_type'] ?? 'Not completed setup';
            final emergencyContactName =
                user['emergency_contact_name'] ?? 'Not completed setup';
            final emergencyContactNumber =
                user['emergency_contact_number'] ?? 'Not completed setup';
            final averageDrivingHours =
                user['average_daily_driving_hours'] != null
                ? '${user['average_daily_driving_hours']} hours/day'
                : 'Not completed setup';

            final avatarInitial =
                fullName != 'Not completed setup' && fullName.isNotEmpty
                ? fullName[0].toUpperCase()
                : (username.isNotEmpty ? username[0].toUpperCase() : 'U');

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 540),
                  child: Column(
                    children: [
                      // Avatar
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [AppColors.info, AppColors.safe],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.info.withValues(alpha: 0.28),
                              blurRadius: 24,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            avatarInitial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 38,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        fullName != 'Not completed setup' ? fullName : username,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 28),

                      // User Details Card
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Profile Information',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const Divider(height: 24, thickness: 1),
                            _buildInfoRow(
                              context,
                              icon: Icons.badge_outlined,
                              label: 'Full Name',
                              value: fullName,
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRow(
                              context,
                              icon: Icons.person_outline_rounded,
                              label: 'Username',
                              value: username,
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRow(
                              context,
                              icon: Icons.cake_outlined,
                              label: 'Age',
                              value: age,
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRow(
                              context,
                              icon: Icons.wc_outlined,
                              label: 'Gender',
                              value: gender,
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRow(
                              context,
                              icon: Icons.email_outlined,
                              label: 'Email',
                              value: email,
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRow(
                              context,
                              icon: Icons.phone_outlined,
                              label: 'Mobile Number',
                              value: phone,
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRow(
                              context,
                              icon: Icons.calendar_today_outlined,
                              label: 'Member Since',
                              value: createdAt,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Vehicle Details Card
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Vehicle Information',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const Divider(height: 24, thickness: 1),
                            _buildInfoRow(
                              context,
                              icon: Icons.directions_car_outlined,
                              label: 'Vehicle Type',
                              value: vehicleType,
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRow(
                              context,
                              icon: Icons.pin_outlined,
                              label: 'Vehicle Registration Number',
                              value: vehicleNumber,
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRow(
                              context,
                              icon: Icons.schedule_outlined,
                              label: 'Average Daily Driving',
                              value: averageDrivingHours,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Emergency Information Card
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Emergency Contacts',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const Divider(height: 24, thickness: 1),
                            _buildInfoRow(
                              context,
                              icon: Icons.contact_emergency_outlined,
                              label: 'Emergency Contact Name',
                              value: emergencyContactName,
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRow(
                              context,
                              icon: Icons.phone_in_talk_outlined,
                              label: 'Emergency Contact Number',
                              value: emergencyContactNumber,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Logout button
                      GlassButton(
                        label: 'Logout',
                        icon: Icons.logout_rounded,
                        color: AppColors.urgent,
                        onPressed: _logout,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor = isDark
        ? AppColors.darkSecondaryText
        : AppColors.lightSecondaryText;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: secondaryColor),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: secondaryColor),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
