import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Async UX Pattern: Loading, Error, Empty States
/// 
/// Bu widget, async işlemlerin 3 durumunu yönetir:
/// 1. Loading: CircularProgressIndicator gösterir
/// 2. Error: Hata mesajı ve retry butonu gösterir
/// 3. Empty: Boş durum mesajı gösterir
/// 4. Success: Child widget'ı gösterir
class AsyncStateBuilder extends StatelessWidget {
  final bool isLoading;
  final String? error;
  final bool isEmpty;
  final Widget child;
  final String? emptyMessage;
  final IconData emptyIcon;
  final VoidCallback? onRetry;
  final VoidCallback? onEmptyAction;
  final String? emptyActionText;

  const AsyncStateBuilder({
    super.key,
    required this.isLoading,
    this.error,
    required this.isEmpty,
    required this.child,
    this.emptyMessage,
    this.emptyIcon = Icons.inbox_outlined,
    this.onRetry,
    this.onEmptyAction,
    this.emptyActionText,
  });

  @override
  Widget build(BuildContext context) {
    // 1. LOADING STATE
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryOrange),
        ),
      );
    }

    // 2. ERROR STATE
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tekrar Dene'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryOrange,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // 3. EMPTY STATE
    if (isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                emptyIcon,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                emptyMessage ?? 'Henüz içerik yok',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              if (onEmptyAction != null) ...[
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: onEmptyAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryOrange,
                    foregroundColor: Colors.black,
                  ),
                  child: Text(emptyActionText ?? 'Başla'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // 4. SUCCESS STATE
    return child;
  }
}
