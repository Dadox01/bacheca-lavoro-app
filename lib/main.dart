import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'routes.dart';
import 'services/api_client.dart';
import 'services/cv_picker.dart';
import 'theme.dart';

void main() {
  runApp(const BachecaLavoroApp());
}

class BachecaLavoroApp extends StatefulWidget {
  /// Iniettabili nei test: client HTTP e selettore del curriculum.
  final ApiClient? api;
  final CvPicker? cvPicker;

  const BachecaLavoroApp({super.key, this.api, this.cvPicker});

  @override
  State<BachecaLavoroApp> createState() => _BachecaLavoroAppState();
}

class _BachecaLavoroAppState extends State<BachecaLavoroApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late final ApiClient _api;
  late final AuthProvider _auth;
  late final CvPicker _cvPicker;

  @override
  void initState() {
    super.initState();
    _api = widget.api ?? ApiClient();
    _cvPicker = widget.cvPicker ?? FilePickerCvPicker();
    _auth = AuthProvider(_api);
    _auth.addListener(_onAuthChanged);
    _auth.restoreSession();
  }

  /// Sessione scaduta (401): logout locale e ritorno al login.
  void _onAuthChanged() {
    if (_auth.sessionExpired) {
      _auth.sessionExpired = false;
      _navigatorKey.currentState
          ?.pushNamedAndRemoveUntil(Routes.login, (r) => false);
    }
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    _auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: _api),
        Provider<CvPicker>.value(value: _cvPicker),
        ChangeNotifierProvider<AuthProvider>.value(value: _auth),
      ],
      child: Selector<AuthProvider, bool>(
        selector: (_, a) => a.initializing,
        builder: (context, initializing, _) {
          if (initializing) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: buildTheme(),
              home: const Scaffold(
                body: Center(
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                ),
              ),
            );
          }
          return MaterialApp(
            title: 'Bacheca Lavoro',
            debugShowCheckedModeBanner: false,
            theme: buildTheme(),
            navigatorKey: _navigatorKey,
            initialRoute: Routes.jobs,
            onGenerateRoute: (s) => Routes.generate(s, _auth),
          );
        },
      ),
    );
  }
}
