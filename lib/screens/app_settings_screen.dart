// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import 'notifications_screen.dart';
import 'edit_profile_screen.dart';
import 'blocked_users_screen.dart';
import 'password_security_screen.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  bool privateAccount = false;
  bool locationVisible = true;

  @override
  Widget build(BuildContext context) {
    final dividerColor = adjustOpacity(Colors.white, 0.06);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          // Account Management
          const _SectionHeader(text: 'Hesap Yönetimi'),
          _SettingsCard(children: [
            _SettingsRow(
              icon: Icons.person,
              title: 'Profil Bilgileri',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                );
              },
            ),
            _InnerDivider(color: dividerColor),
            _SettingsRow(
              icon: Icons.security,
              title: 'Şifre ve Güvenlik',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PasswordSecurityScreen()),
                );
              },
            ),
          ]),

          // Privacy & Safety
          const SizedBox(height: 24),
          const _SectionHeader(text: 'Gizlilik ve Güvenlik'),
          _SettingsCard(children: [
            _SettingsRow(
              icon: Icons.lock,
              title: 'Özel Hesap',
              subtitle: 'Sadece takipçiler gönderilerinizi görebilir',
              trailing: _SwitchBadge(
                value: privateAccount,
                onChanged: (v) => setState(() => privateAccount = v),
              ),
            ),
            _InnerDivider(color: dividerColor),
            _SettingsRow(
              icon: Icons.block,
              title: 'Engellenen Kullanıcılar',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BlockedUsersScreen()),
                );
              },
            ),
          ]),

          // Location Settings
          const SizedBox(height: 24),
          const _SectionHeader(text: 'Konum Ayarları'),
          _SettingsCard(children: [
            _SettingsRow(
              icon: Icons.map,
              title: 'Haritada Görün',
              subtitle: locationVisible 
                  ? 'Konumunuz diğer motorcular tarafından görülebilir' 
                  : 'Konumunuz gizli',
              trailing: _SwitchBadge(
                value: locationVisible,
                onChanged: (v) => setState(() => locationVisible = v),
              ),
            ),
            _InnerDivider(color: dividerColor),
            _SettingsRow(
              icon: Icons.info_outline,
              title: 'Konum Bilgisi',
              subtitle: 'Haritada görünürlük ayarlarınızı yönetin',
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Konum Gizliliği'),
                    content: const Text(
                      'Haritada görünür olduğunuzda, yakınlarınızdaki diğer motorcular sizi haritada görebilir. '
                      'Gizli modda iken konumunuz kimseyle paylaşılmaz.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Tamam'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ]),

          // Notifications
          const SizedBox(height: 24),
          const _SectionHeader(text: 'Bildirimler'),
          _SettingsCard(children: [
            _SettingsRow(
              icon: Icons.notifications,
              title: 'Push Bildirimler',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                );
              },
            ),
          ]),

          // App Settings
          const SizedBox(height: 24),
          const _SectionHeader(text: 'Uygulama Ayarları'),
          _SettingsCard(children: [
            _SettingsRow(
              icon: Icons.dark_mode,
              title: 'Görünüm',
              onTap: () => _showAppearanceSheet(context),
            ),
            _InnerDivider(color: dividerColor),
            _SettingsRow(
              icon: Icons.language,
              title: 'Dil',
              onTap: () => _chooseLanguage(context),
            ),
          ]),

          // Logout
          const SizedBox(height: 24),
          _LogoutRow(onTap: () async {
            try {
              await Provider.of<AuthProvider>(context, listen: false).logout();
            } catch (_) {}
            if (!mounted) return;
            if (!context.mounted) return;
            Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
          }),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          letterSpacing: 0.6,
          fontWeight: FontWeight.w600,
          color: adjustOpacity(Colors.white, 0.6),
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.lightGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: adjustOpacity(Colors.white, 0.06)),
      ),
      child: Column(children: children),
    );
  }
}

class _InnerDivider extends StatelessWidget {
  final Color color;
  const _InnerDivider({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 1,
      color: color,
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _SettingsRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon badge
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: adjustOpacity(AppTheme.primaryOrange, 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.primaryOrange),
            ),
            const SizedBox(width: 12),
            // Texts
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ]
                ],
              ),
            ),
            // Trailing
            trailing ?? const Icon(Icons.chevron_right, color: Colors.white60),
          ],
        ),
      ),
    );
  }
}

class _SwitchBadge extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchBadge({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeThumbColor: Colors.white,
      activeTrackColor: AppTheme.primaryOrange,
    );
  }
}

Future<void> _chooseLanguage(BuildContext context) async {
  if (!context.mounted) return;
  final prefs = await SharedPreferences.getInstance();
  final current = prefs.getString('app_language') ?? 'tr';
  String selected = current;

  if (!context.mounted) return;
  await showDialog(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('Dil Seçimi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              value: 'tr',
              groupValue: selected,
              onChanged: (v) {
                selected = v ?? 'tr';
                Navigator.of(ctx).pop();
              },
              title: const Text('Türkçe'),
            ),
            RadioListTile<String>(
              value: 'en',
              groupValue: selected,
              onChanged: (v) {
                selected = v ?? 'en';
                Navigator.of(ctx).pop();
              },
              title: const Text('English'),
            ),
          ],
        ),
      );
    },
  );

  await prefs.setString('app_language', selected);
  if (context.mounted) {
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Dil güncellendi: ${selected.toUpperCase()}')),
    );
  }
}

void _showAppearanceSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppTheme.lightGrey,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) {
      return const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Görünüm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 12),
              ListTile(
                leading: Icon(Icons.dark_mode),
                title: Text('Koyu (varsayılan)'),
                subtitle: Text('Şimdilik koyu tema etkin'),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _LogoutRow extends StatelessWidget {
  final VoidCallback onTap;
  const _LogoutRow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.lightGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: adjustOpacity(Colors.white, 0.06)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: adjustOpacity(Colors.redAccent, 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout, color: Colors.redAccent),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Çıkış Yap',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.redAccent,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.redAccent),
            ],
          ),
        ),
      ),
    );
  }
}

// Reverting the `adjustOpacity` method to use `withOpacity`
Color adjustOpacity(Color color, double opacity) {
  return color.withValues(alpha: opacity);
}



