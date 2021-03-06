// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart core library.

patch class Null {

  factory Null._uninstantiable() {
    throw new UnsupportedError("class Null cannot be instantiated");
  }

  static const _HASH_CODE = 2011; // The year Dart was announced and a prime.
  int get _identityHashCode => _HASH_CODE;
  int get hashCode => _HASH_CODE;

  String toString() {
    return 'null';
  }
}
