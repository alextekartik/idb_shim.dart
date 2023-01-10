import 'dart:typed_data';

import 'package:idb_shim/idb.dart';
import 'package:idb_shim/src/utils/env_utils.dart';
import 'package:idb_shim/src/utils/value_utils.dart';

/// See [KeyRange] for information
class IdbKeyRange implements KeyRange {
  /// Should not be used.
  @Deprecated('Use other constructors')
  IdbKeyRange();

  /// Creates a new key range containing a single value.
  IdbKeyRange.only(/*Key*/ value) : this.bound(value, value);

  /// Creates a new key range with only a lower bound.
  IdbKeyRange.lowerBound(Object? lowerBound, [bool open = false]) {
    _lowerBound = lowerBound;
    _lowerBoundOpen = open;
    _checkLowerBoundDef();
  }

  void _checkLowerBoundDef() =>
      _checkBound('lower', _lowerBound, _lowerBoundOpen);
  void _checkUpperBoundDef() =>
      _checkBound('upper', _upperBound, _upperBoundOpen);

  void _checkBound(String tag, bound, open) {
    if (_boundHasNull(bound)) {
      // DataError: Failed to execute 'lowerBound' on 'IDBKeyRange': The parameter is not a valid key.
      throw DatabaseError(
          'DataError: The $tag key has nulls and the bounds is not open ($this)');
    }
  }

  bool _boundHasNull(Object? bound) {
    if (bound is Iterable) {
      if (bound is! Uint8List) {
        return bound.where((element) => element == null).isNotEmpty;
      }
    }
    return bound == null;
  }

  /// Creates a new upper-bound key range.
  IdbKeyRange.upperBound(Object? upperBound, [bool open = false]) {
    _upperBound = upperBound;
    _upperBoundOpen = open;
    _checkUpperBoundDef();
  }

  /// Creates a new key range with upper and lower bounds.
  IdbKeyRange.bound(this._lowerBound, this._upperBound,
      [bool lowerOpen = false, bool upperOpen = false]) {
    _lowerBoundOpen = lowerOpen;
    _upperBoundOpen = upperOpen;
    if (isDebug) {
      // Extra compare value not keys as it might not be bounded
      if (compareValue(_lowerBound, _upperBound) == 0) {
        if (lowerOpen || upperOpen) {
          throw StateError(
              'DataError: The lower key and upper key are equal and one of the bounds is open ($this)');
        }
      }
    }
  }

  dynamic _lowerBound;
  bool _lowerBoundOpen = true;
  dynamic _upperBound;
  bool _upperBoundOpen = true;

  /// Lower bound of the key range.
  @override
  Object? get lower => _lowerBound;

  /// Returns false if the lower-bound value is included in the key range.
  @override
  bool get lowerOpen => _lowerBoundOpen;

  /// Upper bound of the key range.
  @override
  Object? get upper => _upperBound;

  /// Returns false if the upper-bound value is included in the key range.
  @override
  bool get upperOpen => _upperBoundOpen;

  num _compareValue(value1, value2) {
    if (value1 is num) {
      return value1 - (value2 as num);
    } else if (value1 is String) {
      return value1.compareTo(value2 as String);
    } else if (value1 is List) {
      final list = value1;
      for (var i = 0; i < list.length; i++) {
        var diff = _compareValue(list[i], (value2 as List)[i]);
        if (diff != 0) {
          return diff;
        }
      }
      return 0;
    } else {
      throw UnsupportedError(
          "key '$value1' of type ${value1.runtimeType} not supported");
    }
  }

  ///
  /// Added method for memory implementation
  ///
  bool _checkLowerBound(key) {
    if (_lowerBound != null) {
      final exclude = _lowerBoundOpen;
      final cmp = _compareValue(key, _lowerBound);
      if (cmp == 0 && exclude) {
        return false;
      } else {
        return cmp >= 0;
      }
    }
    return true;
  }

  bool _checkUpperBound(key) {
    if (_upperBound != null) {
      final exclude = _upperBoundOpen;
      final cmp = _compareValue(key, _upperBound);
      if (cmp == 0 && exclude) {
        return false;
      } else {
        return cmp <= 0;
      }
    }
    return true;
  }

  /// Return true if a key range contains a given key
  @override
  bool contains(key) {
    if (!_checkLowerBound(key)) {
      return false;
    } else {
      return _checkUpperBound(key);
    }
  }

  @override
  String toString() {
    final sb = StringBuffer('kr');
    if (lower == null) {
      sb.write('...');
    } else {
      if (lowerOpen) {
        sb.write(']');
      } else {
        sb.write('[');
      }
      sb.write(lower);
    }
    sb.write('-');
    if (upper == null) {
      sb.write('...');
    } else {
      sb.write(upper);
      if (upperOpen) {
        sb.write('[');
      } else {
        sb.write(']');
      }
    }
    return sb.toString();
  }
}
