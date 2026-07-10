import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/providers.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/calendar_entry.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(calendarEntriesProvider);
    final entryAsync = ref.watch(calendarEntryForDateProvider(_selectedDay));

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            _buildCalendar(entriesAsync),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Expanded(
              child: entryAsync.when(
                loading: () => const LoadingIndicator(),
                error: (_, __) => const SizedBox.shrink(),
                data: (entry) => _buildDayDetail(context, entry),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(
        'Calendar',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
    );
  }

  Widget _buildCalendar(AsyncValue<List<CalendarEntry>> entriesAsync) {
    final eventMap = entriesAsync.valueOrNull?.fold<Map<DateTime, List>>(
          {},
          (map, e) {
            final day = DateTime(e.date.year, e.date.month, e.date.day);
            map[day] = [e];
            return map;
          },
        ) ??
        {};

    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      eventLoader: (day) {
        final key = DateTime(day.year, day.month, day.day);
        return eventMap[key] ?? [];
      },
      onDaySelected: (selected, focused) {
        setState(() {
          _selectedDay = selected;
          _focusedDay = focused;
        });
        ref.read(selectedMonthProvider.notifier).state = focused;
      },
      onPageChanged: (focused) {
        setState(() => _focusedDay = focused);
        ref.read(selectedMonthProvider.notifier).state = focused;
      },
      calendarStyle: CalendarStyle(
        defaultTextStyle:
            const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        weekendTextStyle:
            const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        outsideDaysVisible: false,
        todayDecoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        todayTextStyle: const TextStyle(
            color: AppColors.primary, fontWeight: FontWeight.w600),
        selectedDecoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        selectedTextStyle: const TextStyle(
            color: AppColors.background, fontWeight: FontWeight.w600),
        markerDecoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        markerSize: 5,
        markersMaxCount: 1,
      ),
      headerStyle: HeaderStyle(
        titleCentered: true,
        formatButtonVisible: false,
        titleTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        leftChevronIcon: const Icon(
            Icons.chevron_left, color: AppColors.textSecondary),
        rightChevronIcon: const Icon(
            Icons.chevron_right, color: AppColors.textSecondary),
        headerPadding: const EdgeInsets.symmetric(vertical: 8),
      ),
      daysOfWeekStyle: const DaysOfWeekStyle(
        weekdayStyle:
            TextStyle(color: AppColors.textDisabled, fontSize: 12),
        weekendStyle:
            TextStyle(color: AppColors.textDisabled, fontSize: 12),
      ),
    );
  }

  Widget _buildDayDetail(BuildContext context, CalendarEntry? entry) {
    final isToday = isSameDay(_selectedDay, DateTime.now());
    final isPast = _selectedDay.isBefore(DateTime.now()) && !isToday;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _formatSelectedDay(),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (isToday) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Today',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
              const Spacer(),
              if (entry != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: AppColors.error, size: 20),
                  onPressed: () => _removeEntry(context),
                ),
            ],
          ),
          const SizedBox(height: 16),
          entry != null
              ? _buildEntryCard(context, entry)
              : _buildEmptyDay(context, isPast),
        ],
      ).animate().fadeIn(duration: 200.ms),
    );
  }

  Widget _buildEntryCard(BuildContext context, CalendarEntry entry) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.checkroom_outlined,
                color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.outfit?.name ?? 'Outfit',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (entry.outfit?.occasion != null)
                  Text(
                    entry.outfit!.occasion!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                Text(
                  '${entry.outfit?.garments.length ?? 0} items',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.swap_horiz, color: AppColors.textSecondary),
            onPressed: () => _pickOutfit(context),
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildEmptyDay(BuildContext context, bool isPast) {
    return GestureDetector(
      onTap: isPast ? null : () => _pickOutfit(context),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPast ? AppColors.border : AppColors.primary.withOpacity(0.3),
            width: isPast ? 0.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isPast
                  ? Icons.remove_circle_outline
                  : Icons.add_circle_outline,
              color: isPast ? AppColors.textDisabled : AppColors.primary,
            ),
            const SizedBox(width: 12),
            Text(
              isPast ? 'No outfit recorded' : 'Plan an outfit for this day',
              style: TextStyle(
                color: isPast ? AppColors.textDisabled : AppColors.primary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn();
  }

  String _formatSelectedDay() {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[_selectedDay.month - 1]} ${_selectedDay.day}';
  }

  Future<void> _pickOutfit(BuildContext context) async {
    final outfits = await ref.read(outfitRepositoryProvider).getOutfits();
    if (!mounted || outfits.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No outfits saved yet')),
        );
      }
      return;
    }

    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (ctx, scrollCtrl) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Pick an Outfit',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            Expanded(
              child: ListView.separated(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: outfits.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  tileColor: AppColors.card,
                  title: Text(outfits[i].name),
                  subtitle: Text(outfits[i].occasion ?? ''),
                  trailing: Text('${outfits[i].garments.length} items',
                      style: Theme.of(context).textTheme.labelSmall),
                  onTap: () => Navigator.pop(ctx, outfits[i].id),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (selected != null && mounted) {
      await ref.read(calendarRepositoryProvider).setOutfitForDate(
            date: _selectedDay,
            outfitId: selected,
          );
      ref.invalidate(calendarEntriesProvider);
      ref.invalidate(calendarEntryForDateProvider(_selectedDay));
    }
  }

  Future<void> _removeEntry(BuildContext context) async {
    await ref
        .read(calendarRepositoryProvider)
        .removeEntryForDate(_selectedDay);
    ref.invalidate(calendarEntriesProvider);
    ref.invalidate(calendarEntryForDateProvider(_selectedDay));
  }
}
