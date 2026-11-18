import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design_system/design_system.dart';
import 'friends_provider.dart';

/// What the add / edit friend sheet returns.
sealed class FriendSheetResult {
  const FriendSheetResult();
}

class FriendSheetSave extends FriendSheetResult {
  const FriendSheetSave(this.name, this.steps);
  final String name;
  final int steps;
}

class FriendSheetRemove extends FriendSheetResult {
  const FriendSheetRemove();
}

/// Opens the add-friend sheet, or the edit sheet when [friend] is given.
Future<FriendSheetResult?> showFriendSheet(BuildContext context, {Friend? friend}) {
  final p = context.aero;
  return showModalBottomSheet<FriendSheetResult>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: p.isDark ? AeroColors.espressoCard : Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (_) => _FriendSheet(friend: friend),
  );
}

class _FriendSheet extends StatefulWidget {
  const _FriendSheet({this.friend});
  final Friend? friend;

  @override
  State<_FriendSheet> createState() => _FriendSheetState();
}

class _FriendSheetState extends State<_FriendSheet> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.friend?.name ?? '');
  late final _steps = TextEditingController(text: widget.friend?.weeklySteps.toString() ?? '');
  var _validate = AutovalidateMode.disabled;

  bool get _editing => widget.friend != null;

  @override
  void dispose() {
    _name.dispose();
    _steps.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_form.currentState?.validate() ?? false)) {
      setState(() => _validate = AutovalidateMode.onUserInteraction);
      HapticFeedback.selectionClick();
      return;
    }
    final steps = int.parse(_steps.text.trim().replaceAll(',', ''));
    Navigator.of(context).pop(FriendSheetSave(_name.text.trim(), steps));
  }

  Future<void> _confirmRemove() async {
    final name = widget.friend!.name;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove $name?'),
        content: const Text('Their entry will be deleted from this phone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AeroColors.error, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if ((ok ?? false) && mounted) Navigator.of(context).pop(const FriendSheetRemove());
  }

  InputDecoration _decoration(AeroPalette p, String hint, IconData icon) {
    OutlineInputBorder border(Color c, [double w = 0]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: w == 0 ? BorderSide.none : BorderSide(color: c, width: w),
    );
    return InputDecoration(
      counterText: '',
      hintText: hint,
      hintStyle: AeroText.bodyMd.copyWith(color: p.textMuted),
      prefixIcon: Icon(icon, size: 20, color: p.textMuted),
      filled: true,
      fillColor: p.chip,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: border(Colors.transparent),
      enabledBorder: border(Colors.transparent),
      focusedBorder: border(p.accent, 1.5),
      errorBorder: border(AeroColors.error, 1.5),
      focusedErrorBorder: border(AeroColors.error, 1.5),
      errorStyle: AeroText.caption.copyWith(color: p.isDark ? const Color(0xFFFFB4AB) : AeroColors.error),
    );
  }

  Widget _label(AeroPalette p, String text) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 6),
    child: Text(text.toUpperCase(), style: AeroText.labelCaps.copyWith(color: p.textMuted)),
  );

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: Form(
            key: _form,
            autovalidateMode: _validate,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: p.track, borderRadius: BorderRadius.circular(99)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    AeroIconTile(icon: _editing ? Icons.edit : Icons.person_add),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _editing ? 'Update friend' : 'Add a friend',
                            style: AeroText.titleMd.copyWith(color: p.text),
                          ),
                          Text('Saved only on this phone', style: AeroText.caption.copyWith(color: p.textMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _label(p, 'Name'),
                TextFormField(
                  controller: _name,
                  autofocus: !_editing,
                  maxLength: kFriendNameMaxLength,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  cursorColor: p.accent,
                  style: AeroText.bodyLg.copyWith(color: p.text),
                  decoration: _decoration(p, 'e.g. Ayesha', Icons.person_outline),
                  validator: validateFriendName,
                ),
                const SizedBox(height: 14),
                _label(p, 'Steps this week'),
                TextFormField(
                  controller: _steps,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                  cursorColor: p.accent,
                  style: AeroText.numeric(18, color: p.text),
                  decoration: _decoration(p, 'e.g. 42000', Icons.directions_walk),
                  validator: validateFriendSteps,
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    "Ask your friend for this week's total from their step app.",
                    style: AeroText.caption.copyWith(color: p.textMuted),
                  ),
                ),
                const SizedBox(height: 20),
                AeroPillButton(
                  label: _editing ? 'Save changes' : 'Add friend',
                  icon: _editing ? Icons.check : Icons.person_add,
                  expand: true,
                  onPressed: _submit,
                ),
                if (_editing) ...[
                  const SizedBox(height: 6),
                  Center(
                    child: TextButton.icon(
                      onPressed: _confirmRemove,
                      style: TextButton.styleFrom(
                        foregroundColor: p.isDark ? const Color(0xFFFFB4AB) : AeroColors.error,
                        shape: const StadiumBorder(),
                      ),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: Text('Remove friend', style: AeroText.bodyMd.copyWith(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
