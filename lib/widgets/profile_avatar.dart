import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

/// Reusable Profile Avatar Widget
/// 
/// Kullanıcı profil fotoğrafını gösterir.
/// NetworkImage cache yönetimi ile performans.
class ProfileAvatar extends StatelessWidget {
  final String? profilePicture;
  final double radius;
  final bool showBorder;
  final Color borderColor;
  final VoidCallback? onTap;

  const ProfileAvatar({
    super.key,
    this.profilePicture,
    this.radius = 20,
    this.showBorder = false,
    this.borderColor = AppTheme.primaryOrange,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();
    final avatarUrl = profilePicture != null && profilePicture!.isNotEmpty
        ? apiService.buildStaticUrl(profilePicture!)
        : null;

    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: AppTheme.lightGrey,
      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
      child: avatarUrl == null
          ? Icon(Icons.person, size: radius * 0.8, color: Colors.grey)
          : null,
    );

    if (showBorder) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: borderColor,
              width: 3,
            ),
          ),
          child: avatar,
        ),
      );
    }

    return onTap != null
        ? GestureDetector(onTap: onTap, child: avatar)
        : avatar;
  }
}

/// Avatar with status badge
class ProfileAvatarWithBadge extends StatelessWidget {
  final String? profilePicture;
  final double radius;
  final String? status;
  final bool isOnline;

  const ProfileAvatarWithBadge({
    super.key,
    this.profilePicture,
    this.radius = 20,
    this.status,
    this.isOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ProfileAvatar(
          profilePicture: profilePicture,
          radius: radius,
        ),
        if (isOnline)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: radius * 0.3,
              height: radius * 0.3,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 2),
              ),
            ),
          ),
        if (status != null)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppTheme.primaryOrange,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getStatusIcon(status!),
                size: radius * 0.4,
                color: Colors.black,
              ),
            ),
          ),
      ],
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Sürüşe Hazırım':
        return Icons.two_wheeler;
      case 'Mola Verdim':
        return Icons.local_cafe;
      case 'Kahve Arıyorum':
        return Icons.coffee;
      case 'Yardıma İhtiyacım Var':
        return Icons.warning_amber_rounded;
      default:
        return Icons.info;
    }
  }
}
