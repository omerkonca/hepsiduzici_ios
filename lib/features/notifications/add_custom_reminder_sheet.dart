import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';

Future<bool> showAddCustomReminderSheet(BuildContext context) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _AddCustomReminderSheet(),
  );
  return result == true;
}

class _AddCustomReminderSheet extends ConsumerStatefulWidget {
  const _AddCustomReminderSheet();

  @override
  ConsumerState<_AddCustomReminderSheet> createState() =>
      _AddCustomReminderSheetState();
}

class _AddCustomReminderSheetState
    extends ConsumerState<_AddCustomReminderSheet> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  DateTime _selected = DateTime.now().add(const Duration(hours: 2));
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selected,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('tr', 'TR'),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selected),
    );
    if (time == null || !mounted) return;

    setState(() {
      _selected = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Başlık girin.')),
      );
      return;
    }
    if (_selected.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gelecekte bir tarih seçin.')),
      );
      return;
    }

    setState(() => _saving = true);
    await ref.read(reminderSchedulerServiceProvider).addCustomReminder(
          title: title,
          body: _bodyController.text.trim(),
          scheduledAt: _selected,
        );
    ref.invalidate(customRemindersProvider);
    ref.invalidate(appNotificationsProvider);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final formatted = DateFormat('d MMMM yyyy, HH:mm', 'tr_TR').format(_selected);

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Özel hatırlatıcı',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Başlık',
                hintText: 'Örn. Eczane, toplantı, randevu',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bodyController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Not (isteğe bağlı)',
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule_rounded, color: AppColors.primary),
              title: const Text('Tarih ve saat'),
              subtitle: Text(formatted),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: _pickDateTime,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Hatırlatıcı oluştur'),
            ),
          ],
        ),
      ),
    );
  }
}
