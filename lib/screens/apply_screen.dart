import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/job.dart';
import '../services/api_client.dart';
import '../services/cv_picker.dart';
import '../utils/fmt.dart';
import '../utils/validators.dart';
import '../widgets/inline_error.dart';

/// R6 - Candidatura: dati del candidato + curriculum PDF.
class ApplyScreen extends StatefulWidget {
  final Job job;

  const ApplyScreen({super.key, required this.job});

  @override
  State<ApplyScreen> createState() => _ApplyScreenState();
}

class _ApplyScreenState extends State<ApplyScreen> {
  static const int _maxCvBytes = 5 * 1024 * 1024;

  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _message = TextEditingController();

  PickedCv? _cv;
  bool _submitting = false;
  String? _error;
  String? _cvError;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _pickCv() async {
    try {
      final picked = await context.read<CvPicker>().pickPdf();
      if (picked == null) return;
      if (picked.size > _maxCvBytes) {
        setState(() => _cvError = 'Il file supera il limite di 5 MB.');
        return;
      }
      setState(() {
        _cv = picked;
        _cvError = null;
      });
    } catch (_) {
      setState(() => _cvError = 'Impossibile leggere il file selezionato.');
    }
  }

  Future<void> _submit() async {
    final formOk = _formKey.currentState!.validate();
    if (_cv == null) {
      setState(() => _cvError = 'Allega il curriculum in PDF.');
    }
    if (!formOk || _cv == null) return;

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await context.read<ApiClient>().applyToJob(
        widget.job.id,
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        email: _email.text.trim(),
        message: _message.text.trim(),
        cv: _cv!,
      );
      if (!mounted) return;
      // Il pulsante torna normale: da qui in poi parla il dialog di conferma.
      setState(() => _submitting = false);
      await _showConfirmation();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _submitting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Invio non riuscito. Riprova.';
        _submitting = false;
      });
    }
  }

  Future<void> _showConfirmation() async {
    final theme = Theme.of(context);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          Icons.check_circle_outline,
          color: theme.colorScheme.primary,
          size: 44,
        ),
        title: const Text('Candidatura inviata'),
        content: Text(
          'La tua candidatura per "${widget.job.title}" è stata registrata. '
          'L\'azienda potrà consultare i tuoi dati e il curriculum.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Candidatura')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Text(
              widget.job.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.job.companyName} · ${widget.job.location}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            if (_error != null) InlineError(message: _error!),
            TextFormField(
              controller: _firstName,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (v) =>
                  Validators.requiredText(v, 'il nome', min: 2, max: 40),
              decoration: const InputDecoration(
                labelText: 'Nome',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _lastName,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (v) =>
                  Validators.requiredText(v, 'il cognome', min: 2, max: 40),
              decoration: const InputDecoration(
                labelText: 'Cognome',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: Validators.email,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.alternate_email),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _message,
              maxLines: 4,
              maxLength: 1000,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Presentazione (facoltativa)',
                alignLabelWithHint: true,
                hintText: 'Due righe su di te e sulle tue esperienze',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Curriculum',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            _CvPickerCard(
              cv: _cv,
              error: _cvError,
              onPick: _submitting ? null : _pickCv,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_outlined),
              label: Text(
                _submitting ? 'Invio in corso…' : 'Invia candidatura',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Il curriculum deve essere un PDF di massimo 5 MB.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CvPickerCard extends StatelessWidget {
  final PickedCv? cv;
  final String? error;
  final VoidCallback? onPick;

  const _CvPickerCard({required this.cv, required this.error, this.onPick});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasFile = cv != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: hasFile
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.45)
                : theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.4,
                  ),
            border: Border.all(
              color: error != null
                  ? theme.colorScheme.error
                  : theme.colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Icon(
                hasFile ? Icons.picture_as_pdf : Icons.upload_file_outlined,
                color: hasFile
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasFile ? cv!.fileName : 'Nessun file selezionato',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasFile
                          ? Fmt.fileSize(cv!.size)
                          : 'Formato PDF, max 5 MB',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onPick,
                child: Text(hasFile ? 'Cambia' : 'Scegli file'),
              ),
            ],
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }
}
