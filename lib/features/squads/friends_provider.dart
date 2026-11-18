import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/app_settings.dart';
import '../../design_system/design_system.dart';

/// Max characters in a friend's display name.
const kFriendNameMaxLength = 30;

/// Max weekly steps a friend entry can hold.
const kFriendMaxSteps = 999999;

/// Cap on list size so the standings stay readable.
const kMaxFriends = 50;

/// Avatar gradients for friends (white initials stay readable on each).
const _friendAvatarPalettes = <List<Color>>[
  [AeroColors.tangerineDeep, AeroColors.tangerine],
  [AeroColors.cyanDeep, AeroColors.telemetryCyan],
  [Color(0xFF934B13), Color(0xFFE48B4F)],
  [Color(0xFF4A3F9E), Color(0xFF8576E8)],
  [Color(0xFF1E6B4C), Color(0xFF3FB27F)],
  [Color(0xFF9C2A5A), Color(0xFFE0608F)],
  [Color(0xFF37474F), Color(0xFF78909C)],
  [Color(0xFF7A5A00), Color(0xFFD9A21B)],
];

/// Deterministic avatar colours for [name] (stable across app runs).
List<Color> avatarColorsFor(String name) {
  // FNV-1a 32-bit over the normalised name.
  var h = 0x811C9DC5;
  for (final c in name.trim().toLowerCase().codeUnits) {
    h ^= c;
    h = (h * 0x01000193) & 0xFFFFFFFF;
  }
  return _friendAvatarPalettes[h % _friendAvatarPalettes.length];
}

/// A friend the user tracks manually. Stored on this device only.
@immutable
class Friend {
  const Friend({required this.id, required this.name, required this.weeklySteps, required this.updatedAt});

  final String id;
  final String name;

  /// Steps this week, as entered by the user.
  final int weeklySteps;

  /// When the steps were last entered (UTC).
  final DateTime updatedAt;

  List<Color> get avatarColors => avatarColorsFor(name);

  Friend copyWith({String? name, int? weeklySteps, DateTime? updatedAt}) => Friend(
    id: id,
    name: name ?? this.name,
    weeklySteps: weeklySteps ?? this.weeklySteps,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, Object> toJson() => {
    'id': id,
    'name': name,
    'steps': weeklySteps,
    'updatedAt': updatedAt.toUtc().millisecondsSinceEpoch,
  };

  static Friend? tryParse(String raw) {
    try {
      final m = jsonDecode(raw);
      if (m is! Map) return null;
      final id = m['id'];
      final name = m['name'];
      final steps = m['steps'];
      if (id is! String || name is! String || steps is! int) return null;
      final ms = m['updatedAt'];
      return Friend(
        id: id,
        name: name,
        weeklySteps: steps.clamp(0, kFriendMaxSteps),
        updatedAt: ms is int
            ? DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true)
            : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );
    } catch (_) {
      return null;
    }
  }
}

/// Returns an error message, or null when [raw] is a valid friend name.
String? validateFriendName(String? raw) {
  final v = (raw ?? '').trim();
  if (v.isEmpty) return 'Enter a name';
  if (v.length > kFriendNameMaxLength) return 'Keep it under $kFriendNameMaxLength characters';
  return null;
}

/// Returns an error message, or null when [raw] is a valid weekly step count.
String? validateFriendSteps(String? raw) {
  final v = (raw ?? '').trim().replaceAll(',', '');
  if (v.isEmpty) return 'Enter their steps this week';
  final n = int.tryParse(v);
  if (n == null || n < 0) return 'Use whole numbers only';
  if (n > kFriendMaxSteps) return 'Max 999,999 steps';
  return null;
}

/// On-device friends list (SharedPreferences, JSON string list).
class FriendsNotifier extends Notifier<List<Friend>> {
  static const _key = 'squad_friends';

  @override
  List<Friend> build() {
    final raw = ref.watch(sharedPrefsProvider).getStringList(_key) ?? const [];
    return List.unmodifiable(raw.map(Friend.tryParse).whereType<Friend>());
  }

  void _save(List<Friend> next) {
    state = List.unmodifiable(next);
    ref.read(sharedPrefsProvider).setStringList(_key, [for (final f in next) jsonEncode(f.toJson())]);
  }

  /// Adds a friend. Returns false if the input is invalid or the list is full.
  bool add(String name, int weeklySteps) {
    final n = name.trim();
    if (validateFriendName(n) != null || weeklySteps < 0 || weeklySteps > kFriendMaxSteps) return false;
    if (state.length >= kMaxFriends) return false;
    final now = DateTime.now().toUtc();
    _save([...state, Friend(id: _newId(now), name: n, weeklySteps: weeklySteps, updatedAt: now)]);
    return true;
  }

  /// Unique id even when several friends are added within the same microsecond.
  String _newId(DateTime now) {
    final taken = {for (final f in state) f.id};
    final base = 'f${now.microsecondsSinceEpoch}';
    var id = base;
    for (var i = 1; taken.contains(id); i++) {
      id = '$base-$i';
    }
    return id;
  }

  /// Updates a friend's name and/or steps.
  void edit(String id, {String? name, int? weeklySteps}) {
    final n = name?.trim();
    if (n != null && validateFriendName(n) != null) return;
    if (weeklySteps != null && (weeklySteps < 0 || weeklySteps > kFriendMaxSteps)) return;
    _save([
      for (final f in state)
        if (f.id == id)
          f.copyWith(
            name: n,
            weeklySteps: weeklySteps,
            updatedAt: weeklySteps != null && weeklySteps != f.weeklySteps ? DateTime.now().toUtc() : null,
          )
        else
          f,
    ]);
  }

  void remove(String id) => _save([
    for (final f in state)
      if (f.id != id) f,
  ]);
}

final friendsProvider = NotifierProvider<FriendsNotifier, List<Friend>>(FriendsNotifier.new);
