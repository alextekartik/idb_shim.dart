library idb_shim.test_runner_client_sembast_fs_test;

import 'package:idb_shim/idb_client.dart';
import 'package:idb_shim/src/sembast/sembast_factory.dart';

import 'idb_test_common.dart';

void main() {
  var idbFactory = idbMemoryFsFactory;
  test('bug', () async {
    // Turn on dev logs
    sembastDebug = true;
    var dbName = "bug.db";
    try {
      try {
        await idbFactory.deleteDatabase(dbName);
      } catch (_) {}

      void _initializeDatabase(VersionChangeEvent e) {
        Database db = e.database;
        db.createObjectStore(testStoreName);
      }

      print(" init ${_initializeDatabase} ${_initializeDatabase != null
          ? "NOT NULL"
          : "NULL"}");

      var db = await idbFactory.open(dbName,
          version: 1, onUpgradeNeeded: _initializeDatabase);
      List<String> storeNames = new List.from(db.objectStoreNames);
      expect(storeNames.length, 1);
      expect(storeNames[0], testStoreName);

      db.close();
    } finally {
      sembastDebug = false;
    }
  });
}
