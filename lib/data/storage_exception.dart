import 'package:drift/drift.dart';
import 'package:drift/isolate.dart' show DriftRemoteException;
import 'package:drift/native.dart' show SqliteException;

/// A database operation that failed, told without the values it carried.
///
/// sqlite3 puts the failing statement and the values bound to it into an
/// error's text, and drift passes that text on from its background isolate.
/// Flutter prints a reported error's text to the device log even in release
/// builds, where a bug report can carry it off the device. The values are
/// the person's memos, scores and precautions, so only what helps to find the
/// cause is kept: the operation, the SQLite result code and SQLite's own
/// message, which names tables, columns and constraints but no values.
class StorageException implements Exception {
  StorageException(this.operation, Object error)
    : resultCode = _sqlite(error)?.extendedResultCode,
      cause = _describe(error);

  /// What was being done: `insert`, `select`, `commit`, ...
  final String operation;

  /// SQLite's extended result code, when SQLite refused the operation.
  final int? resultCode;

  /// The failure, without statements or values.
  final String cause;

  static SqliteException? _sqlite(Object error) => switch (error) {
    DriftRemoteException(:final remoteCause) => _sqlite(remoteCause),
    SqliteException() => error,
    _ => null,
  };

  static String _describe(Object error) => switch (_sqlite(error)) {
    SqliteException(:final extendedResultCode, :final message) =>
      'SqliteException($extendedResultCode): $message',
    // Other errors may quote values in their text too; their type is
    // enough to start from.
    null => '${error.runtimeType}',
  };

  @override
  String toString() => 'StorageException: $operation failed: $cause';
}

/// Turns every failure of the database into a [StorageException], so no
/// error leaving the database holds a value that was written or read.
class RedactingInterceptor extends QueryInterceptor {
  Future<T> _redacted<T>(String operation, Future<T> Function() run) async {
    try {
      return await run();
    } on CancellationException {
      // drift's own signal that it dropped a query no longer needed; it
      // carries no values, and drift recognizes it by its type.
      rethrow;
    } catch (error, stack) {
      Error.throwWithStackTrace(StorageException(operation, error), stack);
    }
  }

  /// The statement's first word, such as `insert` for an insert that
  /// returns rows: drift runs that through [runSelect].
  static String _verbOf(String statement) =>
      statement.trimLeft().split(RegExp(r'\s')).first.toLowerCase();

  @override
  Future<bool> ensureOpen(QueryExecutor executor, QueryExecutorUser user) =>
      _redacted('open', () => executor.ensureOpen(user));

  @override
  Future<void> runBatched(
    QueryExecutor executor,
    BatchedStatements statements,
  ) => _redacted('batch', () => executor.runBatched(statements));

  @override
  Future<void> runCustom(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) => _redacted(_verbOf(statement), () => executor.runCustom(statement, args));

  @override
  Future<int> runInsert(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) => _redacted(_verbOf(statement), () => executor.runInsert(statement, args));

  @override
  Future<int> runUpdate(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) => _redacted(_verbOf(statement), () => executor.runUpdate(statement, args));

  @override
  Future<int> runDelete(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) => _redacted(_verbOf(statement), () => executor.runDelete(statement, args));

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) => _redacted(_verbOf(statement), () => executor.runSelect(statement, args));

  @override
  Future<void> commitTransaction(TransactionExecutor inner) =>
      _redacted('commit', inner.send);

  @override
  Future<void> rollbackTransaction(TransactionExecutor inner) =>
      _redacted('rollback', inner.rollback);
}
