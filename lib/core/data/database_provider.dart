import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'aero_database.dart';

final databaseProvider = Provider<AeroDatabase>((ref) {
  final db = AeroDatabase();
  ref.onDispose(db.close);
  return db;
});
