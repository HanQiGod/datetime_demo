import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

const _minuteInterval = 30;

DateTime normalizeToMinuteInterval(
  DateTime value, {
  int minuteInterval = _minuteInterval,
  bool roundUp = false,
}) {
  final totalMinutes = value.hour * 60 + value.minute;
  final remainder = totalMinutes % minuteInterval;
  final normalizedTotalMinutes = switch ((remainder, roundUp)) {
    (0, _) => totalMinutes,
    (_, true) => totalMinutes + (minuteInterval - remainder),
    _ => totalMinutes - remainder,
  };
  final dayOffset = normalizedTotalMinutes ~/ (24 * 60);
  final minutesInDay = normalizedTotalMinutes % (24 * 60);

  return DateTime(
    value.year,
    value.month,
    value.day + dayOffset,
    minutesInDay ~/ 60,
    minutesInDay % 60,
  );
}

DateTime clampDateTime(DateTime value, DateTime minimum, DateTime maximum) {
  if (value.isBefore(minimum)) {
    return minimum;
  }
  if (value.isAfter(maximum)) {
    return maximum;
  }
  return value;
}

Future<DateTime?> showLeaveDateTimePicker({
  required BuildContext context,
  required String title,
  required DateTime initialValue,
  required DateTime minimumDate,
  required DateTime maximumDate,
  String? helperText,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    barrierColor: Colors.black.withValues(alpha: 0.32),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (context) {
      return _LeaveDateTimePickerSheet(
        title: title,
        helperText: helperText,
        initialValue: initialValue,
        minimumDate: minimumDate,
        maximumDate: maximumDate,
      );
    },
  );
}

class _LeaveDateTimePickerSheet extends StatefulWidget {
  const _LeaveDateTimePickerSheet({
    required this.title,
    required this.initialValue,
    required this.minimumDate,
    required this.maximumDate,
    this.helperText,
  });

  final String title;
  final String? helperText;
  final DateTime initialValue;
  final DateTime minimumDate;
  final DateTime maximumDate;

  @override
  State<_LeaveDateTimePickerSheet> createState() =>
      _LeaveDateTimePickerSheetState();
}

class _LeaveDateTimePickerSheetState extends State<_LeaveDateTimePickerSheet> {
  late final List<DateTime> _dateOptions;
  late FixedExtentScrollController _dateController;
  FixedExtentScrollController? _timeController;

  late List<DateTime> _timeOptions;
  late int _selectedDateIndex;
  late int _selectedTimeIndex;
  late DateTime _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = clampDateTime(
      widget.initialValue,
      widget.minimumDate,
      widget.maximumDate,
    );
    _dateOptions = _buildDateOptions(widget.minimumDate, widget.maximumDate);
    _selectedDateIndex = _findDateIndex(_selectedValue);
    _timeOptions = _buildTimeOptionsForDate(
      _dateOptions[_selectedDateIndex],
      widget.minimumDate,
      widget.maximumDate,
    );
    _selectedTimeIndex = _findClosestTimeIndex(_timeOptions, _selectedValue);
    _selectedValue = _timeOptions[_selectedTimeIndex];
    _dateController = FixedExtentScrollController(
      initialItem: _selectedDateIndex,
    );
    _timeController = FixedExtentScrollController(
      initialItem: _selectedTimeIndex,
    );
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController?.dispose();
    super.dispose();
  }

  void _onDateChanged(int index) {
    final selectedDate = _dateOptions[index];
    final nextTimeOptions = _buildTimeOptionsForDate(
      selectedDate,
      widget.minimumDate,
      widget.maximumDate,
    );
    final nextTimeIndex = _findClosestTimeIndex(
      nextTimeOptions,
      _selectedValue,
    );
    final previousTimeController = _timeController;
    final nextTimeController = FixedExtentScrollController(
      initialItem: nextTimeIndex,
    );

    setState(() {
      _selectedDateIndex = index;
      _timeOptions = nextTimeOptions;
      _selectedTimeIndex = nextTimeIndex;
      _timeController = nextTimeController;
      _selectedValue = _timeOptions[_selectedTimeIndex];
    });

    previousTimeController?.dispose();
  }

  void _onTimeChanged(int index) {
    setState(() {
      _selectedTimeIndex = index;
      _selectedValue = _timeOptions[index];
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SizedBox(
          height: 418,
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD6DBE3),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 10, 8, 2),
                child: Row(
                  children: [
                    _ActionButton(
                      label: '取消',
                      onTap: () => Navigator.of(context).pop(),
                      textColor: const Color(0xFF5C6675),
                    ),
                    Expanded(
                      child: Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF171A1F),
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _ActionButton(
                      label: '确定',
                      onTap: () => Navigator.of(context).pop(_selectedValue),
                      textColor: const Color(0xFF1677FF),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6FAFF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFDCE9FF)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.helperText ?? '已选时间',
                        style: const TextStyle(
                          color: Color(0xFF7B8794),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatSelectedValue(_selectedValue),
                        style: const TextStyle(
                          color: Color(0xFF1677FF),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 16, 24, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '日期',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF8B94A1),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '时间',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF8B94A1),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(color: const Color(0xFFF7F8FA)),
                        Positioned(
                          left: 10,
                          right: 10,
                          child: IgnorePointer(
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0x141677FF),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0x331677FF),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: CupertinoPicker(
                                itemExtent: 44,
                                selectionOverlay: const SizedBox.shrink(),
                                scrollController: _dateController,
                                onSelectedItemChanged: _onDateChanged,
                                children: _dateOptions.map((date) {
                                  return Center(
                                    child: Text(
                                      _formatDateOption(date),
                                      style: const TextStyle(
                                        color: Color(0xFF171A1F),
                                        fontSize: 17,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            Container(
                              width: 1,
                              margin: const EdgeInsets.symmetric(vertical: 24),
                              color: const Color(0xFFE7EBF0),
                            ),
                            Expanded(
                              child: CupertinoPicker(
                                itemExtent: 44,
                                selectionOverlay: const SizedBox.shrink(),
                                scrollController: _timeController,
                                onSelectedItemChanged: _onTimeChanged,
                                children: _timeOptions.map((time) {
                                  return Center(
                                    child: Text(
                                      _formatTimeOption(time),
                                      style: const TextStyle(
                                        color: Color(0xFF171A1F),
                                        fontSize: 17,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _findDateIndex(DateTime value) {
    final index = _dateOptions.indexWhere((date) => _isSameDay(date, value));
    return index == -1 ? 0 : index;
  }

  int _findClosestTimeIndex(List<DateTime> timeOptions, DateTime target) {
    if (timeOptions.isEmpty) {
      return 0;
    }

    var bestIndex = 0;
    var bestDifference = timeOptions.first.difference(target).inMinutes.abs();

    for (var i = 1; i < timeOptions.length; i++) {
      final difference = timeOptions[i].difference(target).inMinutes.abs();
      if (difference < bestDifference) {
        bestIndex = i;
        bestDifference = difference;
      }
    }

    return bestIndex;
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onTap,
    required this.textColor,
  });

  final String label;
  final VoidCallback onTap;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: textColor,
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      child: Text(label),
    );
  }
}

List<DateTime> _buildDateOptions(DateTime minimumDate, DateTime maximumDate) {
  final firstDay = _dateOnly(minimumDate);
  final lastDay = _dateOnly(maximumDate);
  final dayCount = lastDay.difference(firstDay).inDays;

  return List.generate(dayCount + 1, (index) {
    return firstDay.add(Duration(days: index));
  });
}

List<DateTime> _buildTimeOptionsForDate(
  DateTime date,
  DateTime minimumDate,
  DateTime maximumDate,
) {
  final dayStart = _dateOnly(date);
  var effectiveStart = dayStart;
  var effectiveEnd = DateTime(date.year, date.month, date.day, 23, 59);

  if (_isSameDay(date, minimumDate)) {
    effectiveStart = minimumDate;
  }
  if (_isSameDay(date, maximumDate)) {
    effectiveEnd = maximumDate;
  }

  effectiveStart = normalizeToMinuteInterval(
    effectiveStart,
    minuteInterval: _minuteInterval,
    roundUp: true,
  );
  effectiveEnd = normalizeToMinuteInterval(
    effectiveEnd,
    minuteInterval: _minuteInterval,
  );

  final options = <DateTime>[];
  var current = effectiveStart;
  while (!current.isAfter(effectiveEnd)) {
    options.add(current);
    current = current.add(const Duration(minutes: _minuteInterval));
  }

  return options.isEmpty ? [effectiveStart] : options;
}

DateTime _dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String _formatSelectedValue(DateTime value) {
  return '${value.year}-${_pad(value.month)}-${_pad(value.day)} '
      '${_weekday(value)} ${_pad(value.hour)}:${_pad(value.minute)}';
}

String _formatDateOption(DateTime value) {
  final today = _dateOnly(DateTime.now());
  final tomorrow = today.add(const Duration(days: 1));
  final prefix = switch (value) {
    final date when _isSameDay(date, today) => '今天',
    final date when _isSameDay(date, tomorrow) => '明天',
    _ => _weekday(value),
  };

  return '$prefix ${_pad(value.month)}-${_pad(value.day)}';
}

String _formatTimeOption(DateTime value) {
  return '${_pad(value.hour)}:${_pad(value.minute)}';
}

String _weekday(DateTime value) {
  const weekDays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  return weekDays[value.weekday - 1];
}

String _pad(int value) => value.toString().padLeft(2, '0');
