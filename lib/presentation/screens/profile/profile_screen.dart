import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/providers.dart';
import '../../../core/theme/app_colors.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildAvatar(context, user).animate().fadeIn(),
            const SizedBox(height: 32),
            _buildSection(
              context,
              title: 'Account',
              children: [
                _tile(context,
                    icon: Icons.person_outline,
                    label: 'Edit Profile',
                    onTap: () {}),
                _tile(context,
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    onTap: () {}),
              ],
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 20),
            _buildSection(
              context,
              title: 'Preferences',
              children: [
                _tile(context,
                    icon: Icons.palette_outlined,
                    label: 'Style Profile',
                    onTap: () {}),
                _tile(context,
                    icon: Icons.cloud_upload_outlined,
                    label: 'Backup & Sync',
                    onTap: () {}),
              ],
            ).animate().fadeIn(delay: 150.ms),
            const SizedBox(height: 20),
            _buildSection(
              context,
              title: 'About',
              children: [
                _tile(context,
                    icon: Icons.privacy_tip_outlined,
                    label: 'Privacy Policy',
                    onTap: () {}),
                _tile(context,
                    icon: Icons.help_outline,
                    label: 'Help & Support',
                    onTap: () {}),
                _tile(context,
                    icon: Icons.info_outline,
                    label: 'App Version',
                    trailing: const Text('1.0.0',
                        style: TextStyle(
                            color: AppColors.textDisabled, fontSize: 13)),
                    onTap: () {}),
              ],
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              icon: const Icon(Icons.logout, color: AppColors.error),
              label: const Text('Sign Out',
                  style: TextStyle(color: AppColors.error)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
              ),
              onPressed: () => _confirmSignOut(context, ref),
            ).animate().fadeIn(delay: 250.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, user) {
    final name = user?.userMetadata?['full_name'] as String? ?? 'User';
    final email = user?.email ?? '';
    final initials = name.trim().split(' ').take(2).map((w) => w[0]).join();

    return Row(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Center(
            child: Text(
              initials.toUpperCase(),
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 26,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 2),
              Text(email, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection(BuildContext context,
      {required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(title, style: Theme.of(context).textTheme.labelLarge),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _tile(BuildContext context,
      {required IconData icon,
      required String label,
      Widget? trailing,
      required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: 20),
      title: Text(label, style: Theme.of(context).textTheme.bodyLarge),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: AppColors.textDisabled, size: 18),
      onTap: onTap,
      minLeadingWidth: 20,
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              context.pop();
              await ref.read(supabaseProvider).auth.signOut();
              if (context.mounted) context.go('/login');
            },
            child: const Text('Sign Out',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
