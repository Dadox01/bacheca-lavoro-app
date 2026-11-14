// Test end-to-end sugli scenari del compito (S1, S2, S3) contro il backend reale.
//
// Avvio (server già in esecuzione su http://127.0.0.1:8080):
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/app_flow_test.dart -d <device-id>
//
// Il selettore di file è sostituito da un finto selettore (non è possibile
// automatizzare il picker nativo); tutto il resto dell'app è quello vero,
// compreso l'upload multipart verso il server.
import 'dart:convert';
import 'dart:typed_data';

import 'package:bacheca_lavoro_app/main.dart';
import 'package:bacheca_lavoro_app/services/api_client.dart';
import 'package:bacheca_lavoro_app/services/cv_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _cvContent =
    '%PDF-1.4\n1 0 obj<</Type/Catalog>>endobj\n'
    'trailer<</Root 1 0 R>>\n%%EOF\n';

class _TestCvPicker implements CvPicker {
  @override
  Future<PickedCv?> pickPdf() async => PickedCv(
    'Curriculum_Mario_Rossi.pdf',
    Uint8List.fromList(utf8.encode(_cvContent)),
  );
}

Future<void> waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 25),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 120));
    if (finder.evaluate().isNotEmpty) {
      await tester.pumpAndSettle(const Duration(milliseconds: 120));
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 120));
  }
  throw TestFailure('Non è comparso: $finder');
}

Future<void> shot(
  IntegrationTestWidgetsFlutterBinding binding,
  String name,
) async {
  try {
    await binding.takeScreenshot(name);
  } catch (e) {
    debugPrint('Screenshot $name non disponibile: $e');
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  final stamp = DateTime.now().millisecondsSinceEpoch.toString();
  final email = 'demo$stamp@example.com';
  final jobTitle = 'Sviluppatore Flutter $stamp';
  final picker = _TestCvPicker();

  testWidgets('S1 - pubblicare un annuncio', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final api = ApiClient();

    await tester.pumpWidget(BachecaLavoroApp(api: api, cvPicker: picker));
    await waitFor(tester, find.text('Trova il tuo prossimo lavoro'));
    await shot(binding, '01_bacheca_pubblica');

    // Registrazione azienda (R1)
    await tester.tap(find.widgetWithText(TextButton, 'Accedi').first);
    await waitFor(tester, find.text('Accedi come azienda'));
    await shot(binding, '02_login_azienda');

    await tester.tap(find.text('Non hai un account? Registra la tua azienda'));
    await waitFor(tester, find.text('Crea l\'account della tua azienda'));
    await tester.enterText(find.byType(TextFormField).at(0), 'Acme Srl');
    await tester.enterText(find.byType(TextFormField).at(1), email);
    await tester.enterText(find.byType(TextFormField).at(2), 'Password1');
    await tester.enterText(find.byType(TextFormField).at(3), 'Password1');
    await shot(binding, '03_registrazione_compilata');
    await tester.tap(find.text('Crea account'));

    // Area riservata (dopo la registrazione l'account è già autenticato)
    await waitFor(tester, find.text('I tuoi annunci'));
    await shot(binding, '04_area_aziende_vuota');

    // Pubblicazione annuncio (R4)
    await tester.tap(find.text('Nuovo annuncio'));
    await waitFor(tester, find.text('Descrivi la posizione'));
    await tester.enterText(find.byType(TextFormField).at(0), jobTitle);
    await tester.enterText(find.byType(TextFormField).at(1), 'Milano (ibrido)');
    await tester.enterText(
      find.byType(TextFormField).at(2),
      '30.000 - 38.000 EUR',
    );
    await tester.enterText(
      find.byType(TextFormField).at(3),
      'Cerchiamo una persona per sviluppare applicazioni mobile in Flutter '
      'con un backend Dart. Si lavora in team agile, due giorni di remoto.',
    );
    await shot(binding, '05_nuovo_annuncio');
    await tester.scrollUntilVisible(
      find.text('Pubblica annuncio'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Pubblica annuncio'));

    await waitFor(tester, find.text('I tuoi annunci'));
    await waitFor(tester, find.text(jobTitle));
    await shot(binding, '06_annuncio_pubblicato');

    // Logout (R3): si torna alla bacheca pubblica
    await tester.tap(find.byTooltip('Esci'));
    await waitFor(tester, find.text('Uscire dall\'account?'));
    await tester.tap(find.widgetWithText(FilledButton, 'Esci'));
    await waitFor(tester, find.text('Trova il tuo prossimo lavoro'));
    await waitFor(tester, find.text(jobTitle));
    await shot(binding, '07_bacheca_con_annuncio');

    // ---------------------------------------------------------------- S2
    // Bacheca e dettaglio (R5)
    await tester.tap(find.text(jobTitle).first);
    await waitFor(tester, find.text('Descrizione'));
    expect(find.text('Acme Srl'), findsWidgets);
    await shot(binding, '08_dettaglio_annuncio');

    // Candidatura (R6)
    await tester.tap(find.text('Candidati a questo annuncio'));
    await waitFor(tester, find.text('Invia candidatura'));
    await tester.enterText(find.byType(TextFormField).at(0), 'Mario');
    await tester.enterText(find.byType(TextFormField).at(1), 'Rossi');
    await tester.enterText(
      find.byType(TextFormField).at(2),
      'mario.rossi@example.com',
    );
    await tester.enterText(
      find.byType(TextFormField).at(3),
      'Sono uno sviluppatore Flutter con tre anni di esperienza. '
      'Allego il curriculum e resto a disposizione per un colloquio.',
    );
    await tester.scrollUntilVisible(
      find.text('Scegli file'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Scegli file'));
    await waitFor(tester, find.text('Curriculum_Mario_Rossi.pdf'));
    await shot(binding, '09_candidatura_compilata');

    await tester.scrollUntilVisible(
      find.text('Invia candidatura'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Invia candidatura'));
    await waitFor(tester, find.text('Candidatura inviata'));
    await shot(binding, '10_conferma_candidatura');
    await tester.tap(find.text('Chiudi'));
    await waitFor(tester, find.text('Candidatura inviata correttamente.'));

    // La candidatura è davvero sul server: si verifica via API.
    final jobs = (await api.get('/api/jobs') as List);
    final jobId =
        (jobs.firstWhere((j) => (j as Map)['title'] == jobTitle) as Map)['id']
            as int;
    final detail = await api.get('/api/jobs/$jobId') as Map;
    expect(
      detail['applicationsCount'],
      isNull,
      reason: 'la bacheca pubblica non espone il numero di candidature',
    );

    // ---------------------------------------------------------------- S3
    // Login azienda (R2) e consultazione candidature (R7)
    await tester.pageBack();
    await waitFor(tester, find.text('Trova il tuo prossimo lavoro'));
    await tester.tap(find.widgetWithText(TextButton, 'Accedi').first);
    await waitFor(tester, find.text('Accedi come azienda'));
    await tester.enterText(find.byType(TextFormField).at(0), email);
    await tester.enterText(find.byType(TextFormField).at(1), 'Password1');
    await tester.tap(find.widgetWithText(FilledButton, 'Accedi'));

    await waitFor(tester, find.text('I tuoi annunci'));
    await waitFor(tester, find.text(jobTitle));
    await shot(binding, '11_area_aziende_con_candidatura');

    await tester.tap(find.text(jobTitle).first);
    await waitFor(tester, find.text('Candidature'));
    await waitFor(tester, find.text('Mario Rossi'));
    await shot(binding, '12_candidature_ricevute');

    await tester.tap(find.text('Mario Rossi'));
    await waitFor(tester, find.text('Lettera di presentazione'));
    expect(find.text('mario.rossi@example.com'), findsOneWidget);
    expect(find.text('Curriculum_Mario_Rossi.pdf'), findsOneWidget);
    await shot(binding, '13_dettaglio_candidato');

    // Il curriculum è scaricabile solo dall'azienda proprietaria.
    final list = await api.get('/api/jobs/$jobId/applications') as Map;
    final application = (list['applications'] as List).first as Map;
    final cv = await http.get(Uri.parse(api.cvUrl(application['id'] as int)));
    expect(cv.statusCode, 200, reason: 'download del curriculum');
    expect(cv.headers['content-type'], 'application/pdf');
    expect(utf8.decode(cv.bodyBytes), contains('%PDF-1.4'));

    // Logout (R3): l'area riservata non è più accessibile
    await tester.pageBack();
    await waitFor(tester, find.text('Candidature'));
    await tester.pageBack();
    await waitFor(tester, find.text('I tuoi annunci'));
    await tester.tap(find.byTooltip('Esci'));
    await waitFor(tester, find.text('Uscire dall\'account?'));
    await tester.tap(find.widgetWithText(FilledButton, 'Esci'));
    await waitFor(tester, find.text('Trova il tuo prossimo lavoro'));
    await tester.tap(find.widgetWithText(TextButton, 'Accedi').first);
    await waitFor(tester, find.text('Accedi come azienda'));
    await shot(binding, '14_dopo_logout_login_richiesto');
  });
}
