import 'package:flutter/material.dart';

import 'models/application.dart';
import 'models/job.dart';
import 'providers/auth_provider.dart';
import 'screens/application_detail_screen.dart';
import 'screens/apply_screen.dart';
import 'screens/company_home_screen.dart';
import 'screens/job_applications_screen.dart';
import 'screens/job_detail_screen.dart';
import 'screens/job_form_screen.dart';
import 'screens/jobs_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';

class Routes {
  static const jobs = '/';
  static const jobDetail = '/job';
  static const apply = '/apply';
  static const login = '/login';
  static const register = '/register';
  static const company = '/company';
  static const jobForm = '/company/new-job';
  static const jobApplications = '/company/applications';
  static const applicationDetail = '/company/application';

  /// Rotte riservate all'azienda autenticata (guard solo lato UI:
  /// il server verifica comunque token e proprietà delle risorse).
  static const Set<String> companyOnly = {
    company,
    jobForm,
    jobApplications,
    applicationDetail,
  };

  static MaterialPageRoute<dynamic> _page(RouteSettings s, Widget w) =>
      MaterialPageRoute<dynamic>(settings: s, builder: (_) => w);

  static Route<dynamic> generate(RouteSettings settings, AuthProvider auth) {
    final name = settings.name ?? jobs;

    // Non autenticato su una rotta riservata -> login con rotta di ritorno.
    if (companyOnly.contains(name) && !auth.isLoggedIn) {
      return _page(
        RouteSettings(name: login, arguments: name),
        LoginScreen(returnTo: name),
      );
    }

    switch (name) {
      case jobDetail:
        final job = settings.arguments;
        if (job is Job) return _page(settings, JobDetailScreen(job: job));
        return _page(const RouteSettings(name: jobs), const JobsScreen());
      case apply:
        final job = settings.arguments;
        if (job is Job) return _page(settings, ApplyScreen(job: job));
        return _page(const RouteSettings(name: jobs), const JobsScreen());
      case login:
        return _page(
          settings,
          LoginScreen(returnTo: settings.arguments as String?),
        );
      case register:
        return _page(
          settings,
          RegisterScreen(returnTo: settings.arguments as String?),
        );
      case company:
        return _page(settings, const CompanyHomeScreen());
      case jobForm:
        return _page(settings, const JobFormScreen());
      case jobApplications:
        final job = settings.arguments;
        if (job is Job) {
          return _page(settings, JobApplicationsScreen(job: job));
        }
        return _page(
          const RouteSettings(name: company),
          const CompanyHomeScreen(),
        );
      case applicationDetail:
        final application = settings.arguments;
        if (application is Application) {
          return _page(
            settings,
            ApplicationDetailScreen(application: application),
          );
        }
        return _page(
          const RouteSettings(name: company),
          const CompanyHomeScreen(),
        );
      case jobs:
      default:
        return _page(const RouteSettings(name: jobs), const JobsScreen());
    }
  }

  /// Dopo login/registrazione: area aziende, mantenendo la bacheca come radice.
  static void afterLogin(BuildContext context, String? returnTo) {
    final dest = returnTo != null && companyOnly.contains(returnTo)
        ? returnTo
        : company;
    Navigator.of(context).pushNamedAndRemoveUntil(dest, (r) => r.isFirst);
  }
}
