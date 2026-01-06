import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class UserStatusDialog extends StatefulWidget {
  final String? currentStatus;
  final String? currentCustomText;

  const UserStatusDialog({
    super.key,
    this.currentStatus,
    this.currentCustomText,
  });

  @override
  State<UserStatusDialog> createState() => _UserStatusDialogState();
}

class _UserStatusDialogState extends State<UserStatusDialog> {
  final List<Map<String, dynamic>> _statuses = [
    {
      'message': '',
      'label': 'Durum Yok',
      'icon': Icons.cancel_outlined,
      'color': Colors.grey,
    },
    {
      'message': 'Sürüşe Hazırım',
      'label': 'Sürüşe Hazırım',
      'icon': Icons.two_wheeler,
      'color': Colors.green,
    },
    {
      'message': 'Mola Verdim',
      'label': 'Mola Verdim',
      'icon': Icons.local_cafe,
      'color': Colors.orange,
    },
    {
      'message': 'Kahve Arıyorum',
      'label': 'Kahve Arıyorum',
      'icon': Icons.coffee,
      'color': Colors.brown,
    },
    {
      'message': 'Yardıma İhtiyacım Var',
      'label': 'Yardıma İhtiyacım Var',
      'icon': Icons.warning_amber_rounded,
      'color': Colors.red,
    },
  ];

  String _selectedMessage = '';
  final TextEditingController _customTextController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedMessage = widget.currentStatus ?? '';
    _customTextController.text = widget.currentCustomText ?? '';
  }

  @override
  void dispose() {
    _customTextController.dispose();
    super.dispose();
  }

  Future<void> _updateStatus() async {
    setState(() => _isLoading = true);

    try {
      final apiService = ApiService();
      await apiService.updateUserStatus(
        message: _selectedMessage,
        customText: _customTextController.text.trim().isEmpty
            ? null
            : _customTextController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Durum güncellendi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppTheme.primaryOrange,
                  size: 28,
                ),
                SizedBox(width: 12),
                Text(
                  'Durumunu Seç',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Diğer motorcular senin durumunu görebilir',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),

            // Status options
            ...List.generate(_statuses.length, (index) {
              final status = _statuses[index];
              final isSelected = _selectedMessage == status['message'];

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedMessage = status['message'] as String;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryOrange.withValues(alpha: 0.1)
                          : AppTheme.lightGrey,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryOrange
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (status['color'] as Color).withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            status['icon'] as IconData,
                            color: status['color'] as Color,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            status['label'] as String,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? AppTheme.primaryOrange
                                  : Colors.white,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle,
                            color: AppTheme.primaryOrange,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 16),

            // Custom text field
            TextField(
              controller: _customTextController,
              maxLength: 100,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Özel Not (İsteğe Bağlı)',
                hintText: 'Örn: "Boğaz köprüsünden geçiyorum"',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppTheme.lightGrey,
              ),
            ),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed:
                      _isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('İptal'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isLoading ? null : _updateStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryOrange,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        )
                      : const Text(
                          'Kaydet',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
