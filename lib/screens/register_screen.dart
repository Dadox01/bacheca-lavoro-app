import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../routes.dart';
import '../services/api_client.dart';
import '../utils/validators.dart';
import '../widgets/inline_error.dart';

/// R1 - Registrazione azienda.
class RegisterScreen extends StatefulWidget {
  final String? returnTo;

  const RegisterScreen({super.key, this.returnTo});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await auth.register(_name.text.trim(), _email.text.trim(), _password.text);
      if (!mounted) return;
      Routes.afterLogin(context, widget.returnTo ?? Routes.company);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _submitting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Risposta non valida dal server.';
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Registrazione azienda')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Crea l\'account della tua azienda',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Con un account puoi pubblicare annunci e vedere chi si candida.',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),
                  if (_error != null) InlineError(message: _error!),
                  TextFormField(
                    controller: _name,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (v) => Validators.requiredText(
                        v, 'il nome dell\'azienda',
                        min: 2, max: 80),
                    decoration: const InputDecoration(
                      labelText: 'Nome azienda',
                      prefixIcon: Icon(Icons.apartment_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    textInputAction: TextInputAction.next,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: Validators.email,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.alternate_email),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.next,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: Validators.password,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      helperText: 'Almeno 8 caratteri, con lettere e numeri',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        tooltip: _obscure ? 'Mostra' : 'Nascondi',
                        icon: Icon(_obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _confirm,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submitting ? null : _submit(),
                    validator: (v) =>
                        Validators.confirmPassword(v, _password.text),
                    decoration: const InputDecoration(
                      labelText: 'Conferma password',
                      prefixIcon: Icon(Icons.lock_reset),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Crea account'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _submitting
                        ? null
                        : () => Navigator.of(context).pushReplacementNamed(
                            Routes.login,
                            arguments: widget.returnTo),
                    child: const Text('Hai già un account? Accedi'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
