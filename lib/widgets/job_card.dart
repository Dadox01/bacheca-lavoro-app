import 'package:flutter/material.dart';

import '../models/job.dart';
import '../utils/fmt.dart';

/// Piccola etichetta con icona (sede, contratto, retribuzione).
class InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const InfoPill({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class JobCard extends StatelessWidget {
  final Job job;
  final VoidCallback onTap;
  final bool showCompany;
  final Widget? trailing;

  const JobCard({
    super.key,
    required this.job,
    required this.onTap,
    this.showCompany = true,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      job.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  trailing ??
                      Icon(
                        Icons.chevron_right,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                ],
              ),
              if (showCompany) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.business_outlined,
                      size: 15,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        job.companyName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (job.location.isNotEmpty)
                    InfoPill(icon: Icons.place_outlined, label: job.location),
                  if (job.contract.isNotEmpty)
                    InfoPill(
                      icon: Icons.work_history_outlined,
                      label: job.contract,
                    ),
                  if (job.salary != null && job.salary!.isNotEmpty)
                    InfoPill(icon: Icons.payments_outlined, label: job.salary!),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Pubblicato il ${Fmt.date(job.createdAt)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
