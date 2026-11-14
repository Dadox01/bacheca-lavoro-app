import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_client.dart';
import '../utils/validators.dart';
import '../widgets/inline_error.dart';

const List<String> kContractTypes = [
  'Tempo indeterminato',
  'Tempo determinato',
  'Apprendistato',
  'Stage',
  'Part-time',
  'Freelance',
];

/// R4 - Pubblicazione di un nuovo annuncio.
class JobFormScreen extends StatefulWidget {
  const JobFormScreen({super.key});

  @override
  State<JobFormScreen> createState() => _JobFormScreenState();
}

class _JobFormScreenState extends State<JobFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _location = TextEditingController();
  final _salary = TextEditingController();

  String _contract = kContractTypes.first;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _location.dispose();
    _salary.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await context.read<ApiClient>().post('/api/jobs', body: {
        'title': _title.text.trim(),
        'description': _description.text.trim(),
        'location': _location.text.trim(),
        'contract': _contract,
        'salary': _salary.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('Annuncio pubblicato nella bacheca.'),
        ));
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _submitting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Pubblicazione non riuscita. Riprova.';
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Nuovo annuncio')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Text(
              'Descrivi la posizione',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'L\'annuncio sarà visibile subito a tutti i candidati.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            if (_error != null) InlineError(message: _error!),
            TextFormField(
              controller: _title,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.sentences,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (v) =>
                  Validators.requiredText(v, 'il titolo', min: 3, max: 100),
              decoration: const InputDecoration(
                labelText: 'Titolo della posizione',
                hintText: 'Es. Sviluppatore Flutter',
                prefixIcon: Icon(Icons.work_outline),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _location,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (v) =>
                  Validators.requiredText(v, 'la sede', min: 2, max: 80),
              decoration: const InputDecoration(
                labelText: 'Sede',
                hintText: 'Es. Milano (ibrido)',
                prefixIcon: Icon(Icons.place_outlined),
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _contract,
              decoration: const InputDecoration(
                labelText: 'Tipo di contratto',
                prefixIcon: Icon(Icons.work_history_outlined),
              ),
              items: [
                for (final c in kContractTypes)
                  DropdownMenuItem(value: c, child: Text(c)),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _contract = v);
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _salary,
              textInputAction: TextInputAction.next,
              validator: (v) {
                final s = (v ?? '').trim();
                if (s.length > 40) return 'Massimo 40 caratteri';
                return null;
              },
              decoration: const InputDecoration(
                labelText: 'Retribuzione (facoltativa)',
                hintText: 'Es. 30.000 - 38.000 EUR',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _description,
              maxLines: 8,
              maxLength: 3000,
              textCapitalization: TextCapitalization.sentences,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (v) => Validators.requiredText(
                  v, 'la descrizione',
                  min: 10, max: 3000),
              decoration: const InputDecoration(
                labelText: 'Descrizione',
                alignLabelWithHint: true,
                hintText:
                    'Mansioni, requisiti, modalità di lavoro, benefit…',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.publish_outlined),
              label: Text(_submitting ? 'Pubblicazione…' : 'Pubblica annuncio'),
            ),
          ],
        ),
      ),
    );
  }
}
