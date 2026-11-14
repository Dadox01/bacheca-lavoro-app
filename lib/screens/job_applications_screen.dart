import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/application.dart';
import '../models/job.dart';
import '../routes.dart';
import '../services/api_client.dart';
import '../utils/fmt.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_view.dart';
import '../widgets/job_card.dart';

/// R7 - Candidature ricevute per un annuncio dell'azienda autenticata.
class JobApplicationsScreen extends StatefulWidget {
  final Job job;

  const JobApplicationsScreen({super.key, required this.job});

  @override
  State<JobApplicationsScreen> createState() => _JobApplicationsScreenState();
}

class _JobApplicationsScreenState extends State<JobApplicationsScreen> {
  List<Application>? _applications;
  Job? _job;
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
      final data = await context
          .read<ApiClient>()
          .get('/api/jobs/${widget.job.id}/applications');
      final map = Map<String, dynamic>.from(data as Map);
      if (!mounted) return;
      setState(() {
        _job = Job.fromJson(Map<String, dynamic>.from(map['job'] as Map));
        _applications = (map['applications'] as List)
            .map((e) => Application.fromJson(Map<String, dynamic>.from(e as Map)))
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

  void _openApplication(Application application) {
    Navigator.of(context)
        .pushNamed(Routes.applicationDetail, arguments: application);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final job = _job ?? widget.job;
    final applications = _applications ?? const <Application>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Candidature')),
      body: RefreshIndicator(
        onRefresh: () => _load(showSpinner: false),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(
              job.title,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (job.location.isNotEmpty)
                  InfoPill(icon: Icons.place_outlined, label: job.location),
                InfoPill(
                  icon: Icons.people_alt_outlined,
                  label: Fmt.plural(
                      applications.length, 'candidatura', 'candidature'),
                ),
              ],
            ),
            const Divider(height: 32),
            ..._content(theme, applications),
          ],
        ),
      ),
    );
  }

  List<Widget> _content(ThemeData theme, List<Application> applications) {
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
    if (applications.isEmpty) {
      return const [
        EmptyState(
          icon: Icons.inbox_outlined,
          title: 'Nessuna candidatura',
          message:
              'Quando qualcuno si candiderà a questo annuncio lo troverai qui, con il curriculum allegato.',
        ),
      ];
    }
    return [
      for (final application in applications) ...[
        _CandidateCard(
          application: application,
          onTap: () => _openApplication(application),
        ),
        const SizedBox(height: 12),
      ],
    ];
  }
}

class _CandidateCard extends StatelessWidget {
  final Application application;
  final VoidCallback onTap;

  const _CandidateCard({required this.application, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  application.initials,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      application.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      application.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.picture_as_pdf_outlined,
                            size: 14, color: theme.colorScheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          application.cvName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: theme.colorScheme.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Fmt.date(application.createdAt),
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  Icon(Icons.chevron_right,
                      color: theme.colorScheme.onSurfaceVariant),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
