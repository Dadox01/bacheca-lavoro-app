import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/job.dart';
import '../providers/auth_provider.dart';
import '../routes.dart';
import '../services/api_client.dart';
import '../utils/fmt.dart';
import '../widgets/brand_header.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_view.dart';
import '../widgets/job_card.dart';

/// Area riservata dell'azienda: i propri annunci e le candidature ricevute.
class CompanyHomeScreen extends StatefulWidget {
  const CompanyHomeScreen({super.key});

  @override
  State<CompanyHomeScreen> createState() => _CompanyHomeScreenState();
}

class _CompanyHomeScreenState extends State<CompanyHomeScreen> {
  List<Job>? _jobs;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool showSpinner = true}) async {
    if (showSpinner) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final data = await context.read<ApiClient>().get('/api/jobs/mine');
      if (!mounted) return;
      setState(() {
        _jobs = (data as List)
            .map((e) => Job.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Risposta non valida dal server.';
        _loading = false;
      });
    }
  }

  Future<void> _openNewJob() async {
    final created = await Navigator.of(context).pushNamed(Routes.jobForm);
    if (created == true) _load(showSpinner: false);
  }

  Future<void> _openApplications(Job job) async {
    await Navigator.of(context)
        .pushNamed(Routes.jobApplications, arguments: job);
    _load(showSpinner: false);
  }

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Uscire dall\'account?'),
        content: const Text(
          'Per rivedere i tuoi annunci dovrai effettuare di nuovo il login.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Esci'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(Routes.jobs, (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final company = context.watch<AuthProvider>().company;
    final jobs = _jobs ?? const <Job>[];
    final applications = jobs.fold<int>(
      0,
      (sum, j) => sum + j.applicationsCount,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Area aziende'),
        actions: [
          IconButton(
            tooltip: 'Esci',
            onPressed: _confirmLogout,
            icon: const Icon(Icons.logout),
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewJob,
        icon: const Icon(Icons.add),
        label: const Text('Nuovo annuncio'),
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(showSpinner: false),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            BrandHeader(
              title: 'Ciao, ${company?.name ?? ''}',
              subtitle: company?.email ?? '',
              icon: Icons.business_center_outlined,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.campaign_outlined,
                    value: '${jobs.length}',
                    label: Fmt.plural(jobs.length, 'annuncio', 'annunci'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.people_outline,
                    value: '$applications',
                    label: Fmt.plural(
                      applications,
                      'candidatura',
                      'candidature',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Text(
                  'I tuoi annunci',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (_jobs != null)
                  Text(
                    '${_jobs!.length}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ..._content(theme),
          ],
        ),
      ),
    );
  }

  List<Widget> _content(ThemeData theme) {
    if (_loading) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (_error != null) {
      return [ErrorView(message: _error!, onRetry: _load)];
    }
    if ((_jobs ?? []).isEmpty) {
      return [
        EmptyState(
          icon: Icons.post_add_outlined,
          title: 'Nessun annuncio pubblicato',
          message: 'Pubblica il tuo primo annuncio: comparirà subito nella bacheca pubblica.',
          action: FilledButton.icon(
            onPressed: _openNewJob,
            icon: const Icon(Icons.add),
            label: const Text('Crea annuncio'),
          ),
        ),
      ];
    }
    return [
      for (final job in _jobs!) ...[
        JobCard(
          job: job,
          showCompany: false,
          onTap: () => _openApplications(job),
          trailing: _ApplicationBadge(count: job.applicationsCount),
        ),
        const SizedBox(height: 12),
      ],
    ];
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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

class _ApplicationBadge extends StatelessWidget {
  final int count;

  const _ApplicationBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = count > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.people_alt_outlined,
            size: 14,
            color: active
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: active
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
