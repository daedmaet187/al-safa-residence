import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../amenities_provider.dart';

class BookingSheet extends ConsumerStatefulWidget {
  const BookingSheet({
    super.key,
    required this.amenityId,
    required this.amenityName,
  });
  final String amenityId;
  final String amenityName;

  @override
  ConsumerState<BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends ConsumerState<BookingSheet> {
  DateTime? _date;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final _notesController = TextEditingController();
  String? _errorMessage;
  bool _submitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _displayDate(DateTime d) => DateFormat('EEE, MMM d yyyy').format(d);

  String _displayTime(TimeOfDay t) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, t.hour, t.minute);
    return DateFormat('h:mm a').format(dt);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _startTime = picked);
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ??
          (_startTime != null
              ? TimeOfDay(
                  hour: (_startTime!.hour + 1) % 24,
                  minute: _startTime!.minute)
              : TimeOfDay.now()),
    );
    if (picked != null) setState(() => _endTime = picked);
  }

  bool _isEndAfterStart() {
    if (_startTime == null || _endTime == null) return true;
    final start = _startTime!.hour * 60 + _startTime!.minute;
    final end = _endTime!.hour * 60 + _endTime!.minute;
    return end > start;
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);

    if (_date == null) {
      setState(() => _errorMessage = 'Please select a date.');
      return;
    }
    if (_startTime == null) {
      setState(() => _errorMessage = 'Please select a start time.');
      return;
    }
    if (_endTime == null) {
      setState(() => _errorMessage = 'Please select an end time.');
      return;
    }
    if (!_isEndAfterStart()) {
      setState(
          () => _errorMessage = 'End time must be after start time.');
      return;
    }

    setState(() => _submitting = true);

    await ref.read(bookingNotifierProvider.notifier).createBooking(
          amenityId: widget.amenityId,
          date: _formatDate(_date!),
          startTime: _formatTime(_startTime!),
          endTime: _formatTime(_endTime!),
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );

    if (!mounted) return;
    setState(() => _submitting = false);

    final bookingState = ref.read(bookingNotifierProvider);
    if (bookingState is AsyncError) {
      final err = bookingState.error;
      setState(() {
        _errorMessage = err.toString().replaceFirst('Exception: ', '');
      });
    } else {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking submitted!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color:
                          isDark ? AppColors.darkBorder : AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Book ${widget.amenityName}',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 20),
                _PickerRow(
                  label: 'Date',
                  value: _date != null ? _displayDate(_date!) : null,
                  placeholder: 'Select date',
                  icon: Icons.calendar_today_outlined,
                  onTap: _pickDate,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _PickerRow(
                  label: 'Start Time',
                  value: _startTime != null ? _displayTime(_startTime!) : null,
                  placeholder: 'Select start time',
                  icon: Icons.access_time_outlined,
                  onTap: _pickStartTime,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _PickerRow(
                  label: 'End Time',
                  value: _endTime != null ? _displayTime(_endTime!) : null,
                  placeholder: 'Select end time',
                  icon: Icons.access_time_filled_outlined,
                  onTap: _pickEndTime,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Notes (optional)',
                    hintText: 'Any special requirements...',
                    filled: true,
                    fillColor: isDark
                        ? AppColors.darkSurfaceRaised
                        : AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                          color:
                              isDark ? AppColors.darkBorder : AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                          color:
                              isDark ? AppColors.darkBorder : AppColors.border),
                    ),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkDangerLight
                          : AppColors.dangerLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            size: 16,
                            color: isDark
                                ? AppColors.darkDanger
                                : AppColors.danger),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.darkDanger
                                  : AppColors.danger,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppColors.goldGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Text(
                              'Confirm Booking',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.label,
    required this.value,
    required this.placeholder,
    required this.icon,
    required this.onTap,
    required this.isDark,
  });
  final String label;
  final String? value;
  final String placeholder;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceRaised : AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 20,
                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.textMuted,
                    )),
                const SizedBox(height: 2),
                Text(
                  value ?? placeholder,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: value != null
                        ? (isDark ? AppColors.darkText : AppColors.text)
                        : (isDark
                            ? AppColors.darkTextSubtle
                            : AppColors.textSubtle),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded,
                size: 20,
                color:
                    isDark ? AppColors.darkTextSubtle : AppColors.textSubtle),
          ],
        ),
      ),
    );
  }
}
