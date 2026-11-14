// Test dell'interfaccia: un client HTTP finto (MockClient) simula il backend,
// così si verificano i flussi reali dell'app senza rete.
import 'dart:convert';
import 'dart:typed_data';

import 'package:bacheca_lavoro_app/main.dart';
import 'package:bacheca_lavoro_app/services/api_client.dart';
import 'package:bacheca_lavoro_app/services/cv_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _jobJson = {
  'id': 1,
  'companyId': 1,
  'companyName': 'Acme Srl',
  'title': 'Sviluppatore Flutter',
  'description':
      'Cerchiamo una persona per sviluppare app mobile con Flutter e Dart.',
  'location': 'Milano',
  'contract': 'Tempo indeterminato',
  'salary': '30.000 - 38.000 EUR',
  'createdAt': '2026-11-14T10:00:00Z',
  'applicationsCount': 0,
};

class _FakeCvPicker implements CvPicker {
  @override
  Future<PickedCv?> pickPdf() async => PickedCv(
        'curriculum_mario.pdf',
        Uint8List.fromList(utf8.encode('%PDF-1.4\n% test\n')),
      );
}

class _NoCvPicker implements CvPicker {
  @override
  Future<PickedCv?> pickPdf() async => null;
}

Widget _app(MockClient client, {CvPicker? picker}) => BachecaLavoroApp(
      api: ApiClient(client: client),
      cvPicker: picker ?? _NoCvPicker(),
    );

http.Response _json(Object body, {int status = 200}) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('la bacheca pubblica mostra gli annunci del server', (tester) async {
    final client = MockClient((request) async {
      if (request.url.path == '/api/jobs') return _json([_jobJson]);
      return _json({'error': 'rotta non prevista'}, status: 404);
    });

    await tester.pumpWidget(_app(client));
    await tester.pumpAndSettle();

    expect(find.text('Bacheca Lavoro'), findsOneWidget);
    expect(find.text('Sviluppatore Flutter'), findsOneWidget);
    expect(find.text('Acme Srl'), findsOneWidget);
    expect(find.text('Milano'), findsOneWidget);
  });

  testWidgets('server irraggiungibile: messaggio di errore e Riprova',
      (tester) async {
    final client = MockClient((request) async => _json(
          {'error': 'Impossibile contattare il server.'},
          status: 500,
        ));

    await tester.pumpWidget(_app(client));
    await tester.pumpAndSettle();

    expect(find.text('Impossibile contattare il server.'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Riprova'), findsOneWidget);
  });

  testWidgets('login azienda con credenziali errate mostra il messaggio',
      (tester) async {
    final client = MockClient((request) async {
      if (request.url.path == '/api/jobs') return _json([_jobJson]);
      if (request.url.path == '/api/auth/login') {
        return _json({'error': 'Email o password non corretti'}, status: 401);
      }
      return _json({'error': 'rotta non prevista'}, status: 404);
    });

    await tester.pumpWidget(_app(client));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Accedi').first);
    await tester.pumpAndSettle();
    expect(find.text('Accedi come azienda'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'azienda@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'Password1');
    await tester.tap(find.widgetWithText(FilledButton, 'Accedi'));
    await tester.pumpAndSettle();

    expect(find.text('Email o password non corretti'), findsOneWidget);
  });

  testWidgets('candidatura: richiede il curriculum e poi conferma l\'invio',
      (tester) async {
    var uploaded = false;
    final client = MockClient((request) async {
      if (request.url.path == '/api/jobs') return _json([_jobJson]);
      if (request.method == 'POST' &&
          request.url.path == '/api/jobs/1/applications') {
        uploaded = true;
        expect(request.headers['content-type'], contains('multipart/form-data'));
        final body = utf8.decode(request.bodyBytes, allowMalformed: true);
        expect(body, contains('Mario'));
        expect(body, contains('curriculum_mario.pdf'));
        return _json({'id': 1, 'firstName': 'Mario'}, status: 201);
      }
      return _json({'error': 'rotta non prevista'}, status: 404);
    });

    await tester.pumpWidget(_app(client, picker: _FakeCvPicker()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sviluppatore Flutter'));
    await tester.pumpAndSettle();
    expect(find.text('Descrizione'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Candidati a questo annuncio'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Mario');
    await tester.enterText(find.byType(TextFormField).at(1), 'Rossi');
    await tester.enterText(find.byType(TextFormField).at(2), 'mario.rossi@example.com');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    // Il pulsante di invio è in fondo al form: si scorre fino a vederlo.
    await tester.scrollUntilVisible(
      find.text('Invia candidatura'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    // Senza curriculum l'invio non parte.
    await tester.tap(find.text('Invia candidatura'));
    await tester.pumpAndSettle();
    expect(find.text('Allega il curriculum in PDF.'), findsOneWidget);
    expect(uploaded, isFalse);

    await tester.tap(find.widgetWithText(TextButton, 'Scegli file'));
    await tester.pumpAndSettle();
    expect(find.text('curriculum_mario.pdf'), findsOneWidget);

    await tester.tap(find.text('Invia candidatura'));
    await tester.pumpAndSettle();

    expect(uploaded, isTrue);
    expect(find.text('Candidatura inviata'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Chiudi'));
    await tester.pumpAndSettle();
    expect(find.text('Candidatura inviata correttamente.'), findsOneWidget);
  });
}
