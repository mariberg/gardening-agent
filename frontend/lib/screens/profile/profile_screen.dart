import 'package:flutter/material.dart';

import '../../data/repository_provider.dart';
import '../../models/garden_statistics.dart';
import '../../models/user_profile.dart';
import '../../repositories/user_repository.dart';
import 'profile_utils.dart';
import 'widgets/garden_stats_card.dart';
import 'widgets/profile_header.dart';
import 'widgets/settings_row.dart';
import 'widgets/settings_section.dart';
import 'widgets/sign_out_button.dart';

/// The main Profile screen displayed at tab index 3 in the AppShell.
///
/// Loads user profile and garden statistics from [UserRepository] via
/// [RepositoryProvider], and displays profile information, settings sections,
/// and sign-out functionality.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _userProfile;
  GardenStatistics? _gardenStats;
  bool _isLoading = true;
  bool _hasError = false;
  bool _hasLoadedData = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoadedData) {
      _hasLoadedData = true;
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final userRepo = RepositoryProvider.of<UserRepository>(context);
      final results = await Future.wait([
        userRepo.getUserProfile(),
        userRepo.getGardenStatistics(),
      ]);
      if (!mounted) return;
      setState(() {
        _userProfile = results[0] as UserProfile;
        _gardenStats = results[1] as GardenStatistics;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _handleSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      final userRepo = RepositoryProvider.of<UserRepository>(context);
      await userRepo.signOut();
      // Placeholder: navigate to sign-in screen
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign out failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_hasError) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Something went wrong. Please try again.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final profile = _userProfile!;
    final stats = _gardenStats!;
    final computedDaysActive = daysActive(profile.createdAt, DateTime.now());

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            ProfileHeader(profile: profile),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GardenStatsCard(
                stats: stats,
                daysActive: computedDaysActive,
              ),
            ),
            const SizedBox(height: 16),
            SettingsSection(
              heading: 'Account',
              children: [
                SettingsRow(label: 'Name', value: profile.name, onTap: () {}),
                SettingsRow(
                  label: 'Email',
                  value: profile.email,
                  onTap: () {},
                ),
                SettingsRow(
                  label: 'Location',
                  value: profile.location,
                  onTap: () {},
                ),
                SettingsRow(
                  label: 'Member since',
                  value: formatMemberSince(profile.createdAt),
                  onTap: () {},
                ),
              ],
            ),
            SettingsSection(
              heading: 'Preferences',
              children: [
                SettingsRow(label: 'Notifications', onTap: () {}),
                SettingsRow(label: 'Watering Reminders', onTap: () {}),
                SettingsRow(label: 'Units', value: 'Metric', onTap: () {}),
              ],
            ),
            SettingsSection(
              heading: 'Support',
              children: [
                SettingsRow(label: 'Help Centre', onTap: () {}),
                SettingsRow(label: 'Send Feedback', onTap: () {}),
                SettingsRow(label: 'About', value: '1.0.0', onTap: () {}),
              ],
            ),
            const SizedBox(height: 16),
            SignOutButton(onTap: _handleSignOut),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
