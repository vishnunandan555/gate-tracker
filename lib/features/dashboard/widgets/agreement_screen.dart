import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/config/brand_config.dart';
import 'package:gateletics/providers/providers.dart';

class AgreementScreen extends StatefulWidget {
  const AgreementScreen({super.key});

  @override
  State<AgreementScreen> createState() => _AgreementScreenState();
}

class _AgreementScreenState extends State<AgreementScreen> {
  bool _tosAgreed = false;
  bool _privacyAgreed = false;

  final String _tosText = """
TERMS OF SERVICE
Last updated: June 25, 2026

1. Acceptance of Terms
By using ${BrandConfig.appName} ("App"), you agree to be bound by these Terms. If you disagree with any part of the terms, you may not use the App.

2. License to Use
We grant you a personal, non-exclusive, non-transferable, revocable license to use the App for personal, non-commercial educational purposes on devices owned or controlled by you.

3. Intellectual Property
${BrandConfig.openSourceNotice} You may modify and redistribute it under the terms of the GNU AGPLv3 License, but the official Play Store version and brand name "${BrandConfig.appName}" are represented by the developer.

4. Limitation of Liability & "As-Is" Clause
The App is provided on an "AS IS" and "AS AVAILABLE" basis without warranties of any kind. ${BrandConfig.companyName} shall not be liable for any damages arising out of your use of, or inability to use, the App. This includes loss of study data, device issues, or syllabus errors.

5. Changes to Terms
We reserve the right to modify or replace these Terms at any time. Your continued use of the App after changes constitutes acceptance of the new Terms.

6. Contact Us
For questions regarding these Terms, contact: ${BrandConfig.supportEmail}

7. Disclaimer of Affiliation
${BrandConfig.legalDisclaimer}
""";

  final String _privacyText = """
PRIVACY POLICY
Last updated: June 25, 2026

1. Information Collection and Use
No Personal Information Collected: The App is designed as an offline-first tool. We do not collect, store, or transmit any personally identifiable information (PII) or user tracking data.

Local Storage: All study progress, syllabus checklists, subjects, and tracking data are stored locally on your device's secure storage using an embedded database. This data never leaves your device unless you manually choose to export it.

Internet Access: The App requires internet access solely to fetch daily motivational quotes from a public repository. No user-specific identifier, location, or device telemetry is transmitted during this fetch.

2. Third-Party Services
The App does not use any third-party analytics, advertising networks, or tracking SDKs.

3. Children's Privacy
Our App does not collect any information from children or anyone else, making it fully compliant with COPPA and global privacy standards.

4. Contact Us
If you have any questions about this Privacy Policy, please contact us at: ${BrandConfig.supportEmail}
""";

  void _showDocumentDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          title,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Text(
                content,
                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13.5, height: 1.6),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "CLOSE",
              style: GoogleFonts.outfit(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 24),
                        // App Icon / Welcome Header
                        Center(
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: Colors.white.withAlpha(20), width: 1.5),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.asset(
                                'assets/icon.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: Text(
                            BrandConfig.appName.toUpperCase(),
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.0,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            "Please review and accept our policies to continue",
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: Colors.white38,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Welcome Message
                        Text(
                          "Welcome to ${BrandConfig.appName}. Before you begin tracking your syllabus progress, please take a moment to read and accept our legal terms.",
                          style: GoogleFonts.outfit(
                            color: Colors.white70,
                            fontSize: 13.5,
                            height: 1.6,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),

                        // Terms Card Button
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          tileColor: Colors.white.withAlpha(8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: Colors.white10),
                          ),
                          leading: const Icon(Icons.description_rounded, color: Colors.cyanAccent),
                          title: Text(
                            "Terms of Service",
                            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          subtitle: Text(
                            "Usage conditions & disclaimer",
                            style: GoogleFonts.outfit(color: Colors.white30, fontSize: 11),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
                          onTap: () => _showDocumentDialog("Terms of Service", _tosText),
                        ),
                        const SizedBox(height: 12),

                        // Privacy Card Button
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          tileColor: Colors.white.withAlpha(8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: Colors.white10),
                          ),
                          leading: const Icon(Icons.privacy_tip_rounded, color: Colors.cyanAccent),
                          title: Text(
                            "Privacy Policy",
                            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          subtitle: Text(
                            "Data storage & usage details",
                            style: GoogleFonts.outfit(color: Colors.white30, fontSize: 11),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
                          onTap: () => _showDocumentDialog("Privacy Policy", _privacyText),
                        ),
                        
                        const SizedBox(height: 24),

                        // Agreement Toggles in a clean Card style
                        Material(
                          color: Colors.white.withAlpha(5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.white.withAlpha(8)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                            child: Theme(
                              data: ThemeData(unselectedWidgetColor: Colors.white30),
                              child: Column(
                                children: [
                                  CheckboxListTile(
                                    activeColor: Colors.cyanAccent,
                                    checkColor: Colors.black,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                    value: _tosAgreed,
                                    title: Text(
                                      "I read and agree to the Terms of Service",
                                      style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13),
                                    ),
                                    controlAffinity: ListTileControlAffinity.leading,
                                    onChanged: (val) {
                                      setState(() {
                                        _tosAgreed = val ?? false;
                                      });
                                    },
                                  ),
                                  const Divider(color: Colors.white10, height: 1),
                                  CheckboxListTile(
                                    activeColor: Colors.cyanAccent,
                                    checkColor: Colors.black,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                    value: _privacyAgreed,
                                    title: Text(
                                      "I read and agree to the Privacy Policy",
                                      style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13),
                                    ),
                                    controlAffinity: ListTileControlAffinity.leading,
                                    onChanged: (val) {
                                      setState(() {
                                        _privacyAgreed = val ?? false;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  if (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
                                    SystemNavigator.pop();
                                  } else {
                                    SystemNavigator.pop();
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  side: const BorderSide(color: Colors.white24),
                                  foregroundColor: Colors.white70,
                                ),
                                child: Text(
                                  "EXIT APP",
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12.5, letterSpacing: 0.5),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Consumer(
                                builder: (context, ref, _) {
                                  final isEnabled = _tosAgreed && _privacyAgreed;

                                  return FilledButton(
                                    onPressed: isEnabled
                                        ? () async {
                                            await ref.read(agreementProvider.notifier).acceptAgreement();
                                          }
                                        : null,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.cyanAccent,
                                      foregroundColor: Colors.black,
                                      disabledBackgroundColor: Colors.white12,
                                      disabledForegroundColor: Colors.white24,
                                      padding: const EdgeInsets.symmetric(vertical: 15),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: Text(
                                      "AGREE & START",
                                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12.5, letterSpacing: 0.5),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
