// ignore_for_file: public_member_api_docs

import 'package:idb_shim/idb.dart';
import 'package:idb_shim/idb_client_sembast.dart';
import 'package:idb_shim/src/common/common_factory.dart';
import 'package:idb_shim/src/sembast/sembast_database.dart';
import 'package:idb_shim/src/utils/core_imports.dart';
import 'package:path/path.dart';
import 'package:sembast/sembast.dart' as sdb;
import 'package:sembast/sembast_memory.dart';

bool sembastDebug = false; // devWarning(true);

/// Special factory in memory but supporting writing on a virtual file system (in memory too)
IdbFactory? _idbFactorySembastMemoryFsImpl;
IdbFactory get idbFactorySembastMemoryFsImpl =>
    _idbFactorySembastMemoryFsImpl ??=
        IdbFactorySembast(databaseFactoryMemoryFs);

IdbFactory? _idbSembastMemoryFactoryImpl;

/// Sembast memory based factory
IdbFactory get idbFactorySembastMemoryImpl =>
    _idbSembastMemoryFactoryImpl ??= IdbFactorySembast(databaseFactoryMemory);

/// New Sembast memory based factory
IdbFactory newIdbFactorySembastMemoryImpl() =>
    IdbFactorySembast(newDatabaseFactoryMemory());

class IdbFactorySembastImpl extends IdbFactoryBase
    implements IdbFactorySembast {
  final sdb.DatabaseFactory _databaseFactory;
  final String? _path;

  @override
  String getDbPath(String dbName) =>
      _path == null ? dbName : join(_path, dbName);

  @override
  sdb.DatabaseFactory get sdbFactory => _databaseFactory;

  @override
  bool get persistent => _databaseFactory.hasStorage;

  IdbFactorySembastImpl(this._databaseFactory, [this._path]);

  @override
  String get name => idbFactoryNameSembast;

  // get the underlying sembast database for a given database
  @override
  sdb.Database? getSdbDatabase(Database db) => (db as DatabaseSembast).db;

  @override
  Future<Database> openFromSdbDatabase(sdb.Database sdbDb) =>
      DatabaseSembast.fromDatabase(this, sdbDb);

  @override
  Future<Database> open(String dbName,
      {int? version,
      OnUpgradeNeededFunction? onUpgradeNeeded,
      OnBlockedFunction? onBlocked}) async {
    checkOpenArguments(version: version, onUpgradeNeeded: onUpgradeNeeded);

    // 2020-10-31 try no setting the version here
    // version ??= 1;

    // name null ok for in memory
    // if (dbName == null) {
    //  return new Future.error(new ArgumentError('name cannot be null'));
    // }

    final db = DatabaseSembast(this, dbName);

    if (sembastDebug) {
      print(
          'open1 onUpgradeNeeded ${onUpgradeNeeded != null ? 'NOT NULL' : 'NULL'}');
    }
    await db.open(version, onUpgradeNeeded);
    return db;
  }

  @override
  Future<IdbFactory> deleteDatabase(String dbName,
      {OnBlockedFunction? onBlocked}) async {
    await _databaseFactory.deleteDatabase(getDbPath(dbName));
    return this;
  }

  @override
  bool get supportsDatabaseNames {
    return false;
  }

  @override
  Future<List<String>> getDatabaseNames() {
    throw DatabaseException('getDatabaseNames not supported');
  }

  @override
  bool get supportsDoubleKey => true;

  @override
  String toString() => 'IdbFactorySembast($_databaseFactory)';
}
