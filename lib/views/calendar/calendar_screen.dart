import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/record_photo.dart';
import '../../data/models/attendance_record.dart';
import '../../viewmodels/calendar_viewmodel.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final DateTime _firstDay;
  late final DateTime _lastDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _firstDay = DateTime(now.year - 1, 1, 1);
    _lastDay = DateTime(now.year + 1, 12, 31);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CalendarViewModel>().loadCalendarWindow(DateTime.now());
    });
  }

  void _openDayDetail(CalendarViewModel viewModel) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _dayDetailSheet(
        viewModel.selectedDay,
        viewModel.recordsForSelectedDay,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CalendarViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.calendarTitle)),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: TableCalendar<AttendanceStatus>(
                firstDay: _firstDay,
                lastDay: _lastDay,
                focusedDay: viewModel.focusedDay,
                rowHeight: 54,
                startingDayOfWeek: StartingDayOfWeek.monday,
                calendarFormat: CalendarFormat.month,
                availableGestures: AvailableGestures.all,
                selectedDayPredicate: (day) =>
                    isSameDay(day, viewModel.selectedDay),
                onDaySelected: (selectedDay, focusedDay) {
                  viewModel.selectDate(selectedDay);
                  viewModel.setFocusedDay(focusedDay);
                  _openDayDetail(viewModel);
                },
                onPageChanged: (focusedDay) {
                  viewModel.setFocusedDay(focusedDay);
                  viewModel.loadCalendarWindow(focusedDay);
                },
                eventLoader: (day) {
                  final status = viewModel.statusFor(day);
                  return status == null ? [] : [status];
                },
                calendarBuilders: CalendarBuilders<AttendanceStatus>(
                  markerBuilder: (context, day, events) =>
                      events.isEmpty ? null : _statusDot(),
                  selectedBuilder: (context, day, focusedDay) => _dayCell(
                    day,
                    background: AppColors.primary,
                    foreground: Colors.white,
                  ),
                  todayBuilder: (context, day, focusedDay) => _dayCell(
                    day,
                    background: AppColors.primary.withValues(alpha: 0.15),
                    foreground: AppColors.primary,
                  ),
                ),
                calendarStyle: const CalendarStyle(
                  markersMaxCount: 1,
                  markersAnchor: 0.95,
                  defaultTextStyle: TextStyle(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                  weekendTextStyle: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                  ),
                  outsideDaysVisible: false,
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                  leftChevronIcon: Icon(
                    Icons.chevron_left,
                    color: AppColors.primary,
                    size: 28,
                  ),
                  rightChevronIcon: Icon(
                    Icons.chevron_right,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
          _legendRow(),
          if (viewModel.errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                viewModel.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.danger, fontSize: 13),
              ),
            ),
          if (viewModel.isLoading) const LinearProgressIndicator(),
        ],
      ),
    );
  }

  Widget _dayCell(
    DateTime day, {
    required Color? background,
    required Color foreground,
  }) {
    return Container(
      margin: const EdgeInsets.all(6),
      alignment: Alignment.center,
      decoration: background == null
          ? null
          : BoxDecoration(color: background, shape: BoxShape.circle),
      child: Text(
        '${day.day}',
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _statusDot() {
    return Center(
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppColors.attendancePresent,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _legendRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            AppStrings.legendTitle,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(width: 16),
          _legendItem(AppColors.attendancePresent, AppStrings.presentLabel),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _dayDetailSheet(DateTime day, List<AttendanceRecord> records) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.dayDetailTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppStrings.fullDate(day),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                _summaryBadge(records),
              ],
            ),
            const SizedBox(height: 12),
            if (records.isEmpty)
              const SizedBox(
                height: 180,
                child: EmptyState(
                  icon: Icons.event_busy,
                  message: AppStrings.noRecordsForDay,
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: records.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _recordTile(records[index]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _summaryBadge(List<AttendanceRecord> records) {
    if (records.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.attendancePresent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        AppStrings.presentLabel,
        style: TextStyle(
          color: AppColors.attendancePresent,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _recordTile(AttendanceRecord record) {
    final time =
        '${record.timestamp.hour.toString().padLeft(2, '0')}:'
        '${record.timestamp.minute.toString().padLeft(2, '0')}:'
        '${record.timestamp.second.toString().padLeft(2, '0')}';
    final isCheckIn = record.eventType == ClockEventType.checkIn;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (isCheckIn ? AppColors.success : AppColors.primary)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isCheckIn ? Icons.login : Icons.logout,
              color: isCheckIn ? AppColors.success : AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      AppStrings.eventTypeLabel(record.eventType),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.place_outlined,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        record.address,
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${record.latitude.toStringAsFixed(5)}, '
                  '${record.longitude.toStringAsFixed(5)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _recordPhoto(record.photoPath),
        ],
      ),
    );
  }

  Widget _recordPhoto(String? path) {
    return RecordPhoto(
      path: path,
      width: 56,
      height: 56,
      borderRadius: BorderRadius.circular(8),
      fallback: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.border.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_outline,
              size: 18,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 2),
            Text(
              AppStrings.noPhotoLabel,
              style: TextStyle(fontSize: 8, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
