import 'dart:io';

void main() {
  print("Stripping Firebase from Windows C++ configuration...");

  // 1. Strip generated_plugins.cmake
  final cmakeFile = File("windows/flutter/generated_plugins.cmake");
  if (cmakeFile.existsSync()) {
    var content = cmakeFile.readAsStringSync();
    final linesToRemove = ["cloud_firestore", "firebase_auth", "firebase_core"];
    for (final plugin in linesToRemove) {
      content = content.replaceAll(RegExp(r'\s*' + plugin + r'\s*\n'), '\n');
    }
    cmakeFile.writeAsStringSync(content);
    print("Successfully stripped windows/flutter/generated_plugins.cmake");
  } else {
    print("Warning: windows/flutter/generated_plugins.cmake not found.");
  }

  // 2. Strip generated_plugin_registrant.cc
  final ccFile = File("windows/flutter/generated_plugin_registrant.cc");
  if (ccFile.existsSync()) {
    var content = ccFile.readAsStringSync();
    final includesToRemove = [
      '#include <cloud_firestore/cloud_firestore_plugin_c_api.h>',
      '#include <firebase_auth/firebase_auth_plugin_c_api.h>',
      '#include <firebase_core/firebase_core_plugin_c_api.h>',
    ];
    for (final inc in includesToRemove) {
      content = content.replaceAll(inc, '');
    }

    content = content.replaceAll(
      RegExp(r'CloudFirestorePluginCApiRegisterWithRegistrar\(\s*registry->GetRegistrarForPlugin\("CloudFirestorePluginCApi"\)\);'),
      '',
    );
    content = content.replaceAll(
      RegExp(r'FirebaseAuthPluginCApiRegisterWithRegistrar\(\s*registry->GetRegistrarForPlugin\("FirebaseAuthPluginCApi"\)\);'),
      '',
    );
    content = content.replaceAll(
      RegExp(r'FirebaseCorePluginCApiRegisterWithRegistrar\(\s*registry->GetRegistrarForPlugin\("FirebaseCorePluginCApi"\)\);'),
      '',
    );

    ccFile.writeAsStringSync(content);
    print("Successfully stripped windows/flutter/generated_plugin_registrant.cc");
  } else {
    print("Warning: windows/flutter/generated_plugin_registrant.cc not found.");
  }
}
