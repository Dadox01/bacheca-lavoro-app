final RegExp _emailRe = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');

class Validators {
  static String? requiredText(
    String? v,
    String label, {
    int min = 1,
    int max = 200,
  }) {
    final s = (v ?? '').trim();
    if (s.length < min) {
      return min <= 1
          ? 'Inserisci $label'
          : '$label troppo corto (minimo $min caratteri)';
    }
    if (s.length > max) {
      return '$label troppo lungo (massimo $max caratteri)';
    }
    return null;
  }

  static String? email(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Inserisci l\'email';
    if (!_emailRe.hasMatch(s)) return 'Email non valida';
    return null;
  }

  static String? password(String? v) {
    final s = v ?? '';
    if (s.isEmpty) return 'Inserisci la password';
    if (s.length < 8) return 'Almeno 8 caratteri';
    if (!RegExp(r'[A-Za-z]').hasMatch(s) || !RegExp(r'\d').hasMatch(s)) {
      return 'Serve almeno una lettera e un numero';
    }
    return null;
  }

  static String? confirmPassword(String? v, String original) {
    if ((v ?? '').isEmpty) return 'Ripeti la password';
    if (v != original) return 'Le password non coincidono';
    return null;
  }
}
