import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/doodle_icons.dart';
import '../../core/data/models.dart';
import '../../core/providers/transit_provider.dart';
import '../../core/widgets/shared_widgets.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(transitProvider).alerts;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Alerts'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () {
              for (final alert in alerts) {
                ref.read(transitProvider.notifier).markAlertRead(alert.id);
              }
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: alerts.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DoodleIcons.alert(size: 64, color: AppColors.textTertiary),
                  const SizedBox(height: 16),
                  const Text(
                    'No alerts',
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: alerts.length,
              itemBuilder: (context, index) {
                final alert = alerts[index];
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 300 + index * 80),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 16 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _AlertCard(
                      alert: alert,
                      onTap: () => ref
                          .read(transitProvider.notifier)
                          .markAlertRead(alert.id),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final TransitAlert alert;
  final VoidCallback onTap;

  const _AlertCard({required this.alert, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Color typeColor;
    Widget typeIcon;

    switch (alert.type) {
      case AlertType.delay:
        typeColor = AppColors.warning;
        typeIcon = DoodleIcons.clock(size: 20, color: typeColor);
      case AlertType.routeChange:
        typeColor = AppColors.accent;
        typeIcon = DoodleIcons.route(size: 20, color: typeColor);
      case AlertType.serviceUpdate:
        typeColor = AppColors.info;
        typeIcon = DoodleIcons.bus(size: 20, color: typeColor);
      case AlertType.emergency:
        typeColor = AppColors.error;
        typeIcon = DoodleIcons.alert(size: 20, color: typeColor);
    }

    final timeAgo = DateTime.now().difference(alert.timestamp);
    String timeStr;
    if (timeAgo.inMinutes < 60) {
      timeStr = '${timeAgo.inMinutes}m ago';
    } else {
      timeStr = '${timeAgo.inHours}h ago';
    }

    return GestureDetector(
      onTap: onTap,
      child: VtCard(
        borderColor: alert.isRead ? null : typeColor.withValues(alpha: 0.3),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: typeIcon),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          alert.title,
                          style: TextStyle(
                            color: alert.isRead
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (!alert.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: typeColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alert.message,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    timeStr,
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
