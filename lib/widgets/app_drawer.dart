import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../screens/home_screen.dart';
import '../screens/calendar_screen.dart';
import '../screens/stats_screen.dart';
import '../screens/category_manager_screen.dart';
import '../utils/app_colors.dart';
import '../utils/app_theme.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[900] : AppColors.primaryPurple,
            ),
            accountName: Text(
              'Cyclic Task Planner',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            accountEmail: FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                final version = snapshot.data?.version ?? '1.0.0';
                return Text(
                  'Version $version',
                  style: const TextStyle(color: Colors.white70),
                );
              },
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(
                Icons.task_alt_rounded,
                size: 40,
                color: AppColors.primaryPurple,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  context,
                  icon: Icons.home_rounded,
                  title: 'Home',
                  onTap: () => _navigateTo(context, const HomeScreen()),
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.category_rounded,
                  title: 'Categories',
                  onTap: () => _navigateTo(context, const CategoryManagerScreen()),
                ),
                const Divider(),
                _buildDrawerItem(
                  context,
                  icon: Icons.share_rounded,
                  title: 'Share App',
                  onTap: () => _shareApp(context),
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.star_rounded,
                  title: 'Rate App',
                  onTap: () => _launchURL('https://play.google.com/store/apps/details?id=YOUR_PACKAGE_NAME'),
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.feedback_rounded,
                  title: 'Feedback',
                  onTap: () => _launchURL('mailto:support@example.com?subject=Cyclic Task Planner Feedback'),
                ),
                const Divider(),
                _buildDrawerItem(
                  context,
                  icon: Icons.settings_rounded,
                  title: 'Settings',
                  onTap: () {
                    // TODO: Navigate to settings screen
                    Navigator.pop(context);
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.help_rounded,
                  title: 'Support',
                  onTap: () => _launchURL('https://example.com/support'),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: Theme.of(context).iconTheme.color?.withOpacity(0.8),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      dense: true,
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    // Close the drawer first
    Navigator.pop(context);
    // Then navigate to the new screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  Future<void> _shareApp(BuildContext context) async {
    await Share.share(
      'Check out this awesome task management app: https://play.google.com/store/apps/details?id=YOUR_PACKAGE_NAME',
      subject: 'Cyclic Task Planner',
    );
  }
}
