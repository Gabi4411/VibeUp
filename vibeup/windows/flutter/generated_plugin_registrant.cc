//
//  Generated file. Do not edit.
//

// clang-format off

// Forward-declare PluginRegistry to avoid requiring "flutter/plugin_registry.h"
// in this translation unit (prevents includePath errors while keeping the
// RegisterPlugins implementation).
namespace flutter {
class PluginRegistry;
}

#if __has_include(<cloud_firestore/cloud_firestore_plugin_c_api.h>)
#include <cloud_firestore/cloud_firestore_plugin_c_api.h>
#endif

#if __has_include(<firebase_auth/firebase_auth_plugin_c_api.h>)
#include <firebase_auth/firebase_auth_plugin_c_api.h>
#endif

#if __has_include(<firebase_core/firebase_core_plugin_c_api.h>)
#include <firebase_core/firebase_core_plugin_c_api.h>
#endif

#if __has_include(<firebase_storage/firebase_storage_plugin_c_api.h>)
#include <firebase_storage/firebase_storage_plugin_c_api.h>
#endif

void RegisterPlugins(flutter::PluginRegistry* registry) {
#if __has_include(<cloud_firestore/cloud_firestore_plugin_c_api.h>)
  CloudFirestorePluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("CloudFirestorePluginCApi"));
#endif

#if __has_include(<firebase_auth/firebase_auth_plugin_c_api.h>)
  FirebaseAuthPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FirebaseAuthPluginCApi"));
#endif

#if __has_include(<firebase_core/firebase_core_plugin_c_api.h>)
  FirebaseCorePluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FirebaseCorePluginCApi"));
#endif

#if __has_include(<firebase_storage/firebase_storage_plugin_c_api.h>)
  FirebaseStoragePluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FirebaseStoragePluginCApi"));
#endif
}
