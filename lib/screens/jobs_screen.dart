import 'dart:async';

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

/// R5 - Bacheca pubblica: elenco annunci e ricerca. Nessun login richiesto.
class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  final TextEditingController _search = TextEditingController();
  Timer? _debounce;
  List<Job>? _jobs;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({bool showSpinner = true}) async {
    if (showSpinner) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final data = await context.read<ApiClient>().get(
        '/api/jobs',
        query: {'q': _search.text.trim()},
      );
      if (!mounted) return;
      setState(() {
        _jobs = (data as List)
            .map((e) => Job.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        _loading = false;
        _error = null;
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

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) _load(showSpinner: false);
    });
  }

  void _openJob(Job job) {
    Navigator.of(context)
        .pushNamed(Routes.jobDetail, arguments: job)
        .then((_) => _load(showSpinner: false));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bacheca Lavoro'),
        actions: [
          TextButton.icon(
            onPressed: () =>
                Navigator.of(context)
                    .pushNamed(auth.isLoggedIn ? Routes.company : Routes.login),
            icon: const Icon(Icons.business_center_outlined, size: 18),
            label: Text(auth.isLoggedIn ? 'Area aziende' : 'Accedi'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(showSpinner: false),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            BrandHeader(
              title: 'Trova il tuo prossimo lavoro',
              subtitle: _jobs == null
                  ? 'Annunci delle aziende iscritte'
                  : Fmt.plural(
                      _jobs!.length,
                      'annuncio pubblicato',
                      'annunci pubblicati',
                    ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _search,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Cerca per ruolo, azienda o sede',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Cancella',
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _search.clear();
                          _load(showSpinner: false);
                        },
                      ),
              ),
            ),
            const SizedBox(height: 20),
            ..._content(theme),
            if (!auth.isLoggedIn) ...[
              const SizedBox(height: 24),
              _CompanyCta(
                onTap: () => Navigator.of(context).pushNamed(Routes.login),
              ),
            ],
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
    final jobs = _jobs ?? const <Job>[];
    if (jobs.isEmpty) {
      return const [
        EmptyState(
          icon: Icons.search_off,
          title: 'Nessun annuncio trovato',
          message: 'Non ci sono annunci che corrispondono alla ricerca. Prova con un altro termine.',
        ),
      ];
    }
    return [
      for (final job in jobs) ...[
        JobCard(job: job, onTap: () => _openJob(job)),
        const SizedBox(height: 12),
      ],
    ];
  }
}

class _CompanyCta extends StatelessWidget {
  final VoidCallback onTap;

  const _CompanyCta({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.campaign_outlined, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sei un\'azienda?',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Accedi per pubblicare annunci e consultare le candidature.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(onPressed: onTap, child: const Text('Accedi')),
          ],
        ),
      ),
    );
  }
}
