import 'package:flutter/material.dart';

import '../models/job.dart';
import '../routes.dart';
import '../utils/fmt.dart';
import '../widgets/job_card.dart';

/// R5 - Dettaglio di un annuncio, con accesso alla candidatura.
class JobDetailScreen extends StatelessWidget {
  final Job job;

  const JobDetailScreen({super.key, required this.job});

  Future<void> _apply(BuildContext context) async {
    final sent = await Navigator.of(context).pushNamed(Routes.apply, arguments: job);
    if (sent == true && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('Candidatura inviata correttamente.'),
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Dettaglio annuncio')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text(
            job.title,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700, height: 1.25),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.business_outlined,
                  size: 18, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  job.companyName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (job.location.isNotEmpty)
                InfoPill(icon: Icons.place_outlined, label: job.location),
              if (job.contract.isNotEmpty)
                InfoPill(icon: Icons.work_history_outlined, label: job.contract),
              if (job.salary != null && job.salary!.isNotEmpty)
                InfoPill(icon: Icons.payments_outlined, label: job.salary!),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Pubblicato il ${Fmt.dateTime(job.createdAt)}',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const Divider(height: 32),
          Text(
            'Descrizione',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            job.description.isEmpty ? 'Nessuna descrizione disponibile.' : job.description,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.55),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.lock_open_outlined,
                    size: 18, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Per candidarti non serve un account: bastano i tuoi dati e il curriculum in PDF.',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: FilledButton.icon(
          onPressed: () => _apply(context),
          icon: const Icon(Icons.send_outlined),
          label: const Text('Candidati a questo annuncio'),
        ),
      ),
    );
  }
}
