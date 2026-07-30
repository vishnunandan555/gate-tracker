import 'package:flutter/foundation.dart';

/// Centralized brand configuration holding all application metadata,
/// publisher/company details, official URLs, and legal disclaimers.
/// 
/// Updating values in this file updates the brand identity across the entire app.
@immutable
class BrandConfig {
  const BrandConfig._();

  // App Identity
  static const String appName = 'GATEletics';
  static const String appTagline =
      'A syllabus and resource tracker for GATE exam preparation.';
  
  // Publisher & Company Details
  static const String companyName = 'Vishnu Nandan';
  static const String supportEmail = 'support@gateletics.com';

  // Repository & Deployment URLs
  static const String githubOwner = 'vishnunandan555';
  static const String githubRepo = 'gateletics';
  static const String githubRepoUrl =
      'https://github.com/$githubOwner/$githubRepo';
  static const String githubReleasesUrl = '$githubRepoUrl/releases';
  static const String githubLatestReleaseApi =
      'https://api.github.com/repos/$githubOwner/$githubRepo/releases/latest';
  static const String githubIssuesUrl = '$githubRepoUrl/issues';

  // Web & Documentation Links
  static const String docsUrl = 'https://$githubOwner.github.io/$githubRepo/';
  static const String liveWebAppUrl = 'https://gateletics.vercel.app/';
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.vishnunandan.gateletics';
  static const String termsUrl = '${docsUrl}terms.html';
  static const String privacyUrl = '${docsUrl}privacy.html';
  static const String supportHubUrl = '${docsUrl}support.html';

  // Package Identifier (matching Android applicationId & bundle ID)
  static const String androidPackageId = 'com.vishnunandan.gateletics';

  // Legal Copy & Disclaimers
  static const String legalDisclaimer =
      'GATEletics is an independent educational tool developed to assist student preparation. This App is not affiliated with, authorized by, sponsored by, or associated with the Graduate Aptitude Test in Engineering (GATE) or its official organizing institutes (IISc, IITs, or NCB-GATE).';

  static const String openSourceNotice =
      'The App, its original features, and source code are open-source and licensed under the GNU AGPLv3 License.';

  static const String termsOfServiceCopy = '''
By using $appName ("App"), you agree to be bound by these Terms. If you disagree with any part of the terms, you may not use the App.

The App, its original features, and source code are open-source and licensed under the GNU AGPLv3 License. You may modify and redistribute it under the terms of the GNU AGPLv3 License, but the official Play Store version and brand name "$appName" are represented by the developer.

$legalDisclaimer
''';
}
