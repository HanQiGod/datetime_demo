import 'package:flutter/material.dart';

import 'leave_date_time_picker.dart';

class LeaveRequestExamplePage extends StatefulWidget {
  const LeaveRequestExamplePage({super.key});

  @override
  State<LeaveRequestExamplePage> createState() =>
      _LeaveRequestExamplePageState();
}

class _LeaveRequestExamplePageState extends State<LeaveRequestExamplePage> {
  static const List<String> _leaveTypes = ['事假', '病假', '调休'];
  static const Duration _minimumLeaveSpan = Duration(minutes: 30);
  static const Duration _defaultLeaveSpan = Duration(hours: 8);
  static const Duration _maximumSelectableRange = Duration(days: 365);

  final TextEditingController _reasonController = TextEditingController();

  late DateTime _startAt;
  late DateTime _endAt;
  String _selectedLeaveType = _leaveTypes.first;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startAt = normalizeToMinuteInterval(now, roundUp: true);
    _endAt = _startAt.add(_defaultLeaveSpan);
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Duration get _leaveSpan => _endAt.difference(_startAt);

  Future<void> _pickLeaveType() async {
    final selectedType = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD6DBE3),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 18, 16, 8),
                child: Text(
                  '请选择请假类型',
                  style: TextStyle(
                    color: Color(0xFF171A1F),
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ..._leaveTypes.map((leaveType) {
                final selected = leaveType == _selectedLeaveType;
                return ListTile(
                  title: Text(
                    leaveType,
                    style: const TextStyle(
                      color: Color(0xFF171A1F),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: selected
                      ? const Icon(
                          Icons.check_rounded,
                          color: Color(0xFF1677FF),
                        )
                      : null,
                  onTap: () => Navigator.of(context).pop(leaveType),
                );
              }),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );

    if (selectedType == null) {
      return;
    }

    setState(() {
      _selectedLeaveType = selectedType;
    });
  }

  Future<void> _pickStartAt() async {
    final minimumDate = normalizeToMinuteInterval(
      DateTime.now(),
      roundUp: true,
    );
    final maximumDate = normalizeToMinuteInterval(
      minimumDate.add(_maximumSelectableRange),
    );

    final picked = await showLeaveDateTimePicker(
      context: context,
      title: '请选择开始时间',
      helperText: '请选择请假开始时间',
      initialValue: clampDateTime(_startAt, minimumDate, maximumDate),
      minimumDate: minimumDate,
      maximumDate: maximumDate,
    );

    if (picked == null) {
      return;
    }

    final normalizedEnd = _endAt.isAfter(picked.add(_minimumLeaveSpan))
        ? _endAt
        : picked.add(_defaultLeaveSpan);

    setState(() {
      _startAt = picked;
      _endAt = normalizedEnd;
    });
  }

  Future<void> _pickEndAt() async {
    final minimumDate = _startAt.add(_minimumLeaveSpan);
    final maximumDate = normalizeToMinuteInterval(
      _startAt.add(const Duration(days: 30)),
    );

    final picked = await showLeaveDateTimePicker(
      context: context,
      title: '请选择结束时间',
      helperText: '结束时间不能早于开始时间',
      initialValue: clampDateTime(_endAt, minimumDate, maximumDate),
      minimumDate: minimumDate,
      maximumDate: maximumDate,
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _endAt = picked;
    });
  }

  void _submitExample() {
    final reason = _reasonController.text.trim();
    final message =
        '$_selectedLeaveType：'
        '${_formatSheetDate(_startAt)} ${_formatTime(_startAt)} 至 '
        '${_formatSheetDate(_endAt)} ${_formatTime(_endAt)}，'
        '共 ${_formatDuration(_leaveSpan)}'
        '${reason.isEmpty ? '' : '，事由：$reason'}';

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('已提交示例：$message')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          '请假',
          style: TextStyle(
            color: Color(0xFF171A1F),
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              children: [
                _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionTitle(title: '请假信息'),
                      const SizedBox(height: 6),
                      _ValueRow(
                        label: '请假类型',
                        value: _selectedLeaveType,
                        onTap: _pickLeaveType,
                        accent: true,
                      ),
                      const Divider(height: 1, color: Color(0xFFF0F2F5)),
                      const _ValueRow(label: '请假单位', value: '小时'),
                      const Divider(height: 1, color: Color(0xFFF0F2F5)),
                      _DateTimeRow(
                        label: '开始时间',
                        value: _startAt,
                        onTap: _pickStartAt,
                      ),
                      const Divider(height: 1, color: Color(0xFFF0F2F5)),
                      _DateTimeRow(
                        label: '结束时间',
                        value: _endAt,
                        onTap: _pickEndAt,
                      ),
                      const Divider(height: 1, color: Color(0xFFF0F2F5)),
                      _ValueRow(
                        label: '请假时长',
                        value: _formatDuration(_leaveSpan),
                        helper: _formatDateRange(_startAt, _endAt),
                        accent: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionTitle(title: '请假事由'),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _reasonController,
                        minLines: 4,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: '请输入请假事由',
                          hintStyle: const TextStyle(
                            color: Color(0xFF9AA3AF),
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF7F8FA),
                          contentPadding: const EdgeInsets.all(14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const _SectionCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: Color(0xFF1677FF),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '时间选择器已改成更接近钉钉的日期列 + 时间列样式，最小粒度为 30 分钟。',
                          style: TextStyle(
                            color: Color(0xFF5C6675),
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '请假时长',
                          style: TextStyle(
                            color: Color(0xFF8B94A1),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDuration(_leaveSpan),
                          style: const TextStyle(
                            color: Color(0xFF1677FF),
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 144,
                    height: 46,
                    child: FilledButton(
                      onPressed: _submitExample,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1677FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('提交'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        child: child,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF171A1F),
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({
    required this.label,
    required this.value,
    this.onTap,
    this.helper,
    this.accent = false,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;
  final String? helper;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF171A1F),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: accent
                        ? const Color(0xFF1677FF)
                        : const Color(0xFF171A1F),
                    fontSize: accent ? 18 : 15,
                    fontWeight: accent ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                if (helper case final helperText?)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      helperText,
                      style: const TextStyle(
                        color: Color(0xFF8B94A1),
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFC4CAD4),
              size: 18,
            ),
          ],
        ],
      ),
    );

    if (onTap == null) {
      return content;
    }

    return InkWell(onTap: onTap, child: content);
  }
}

class _DateTimeRow extends StatelessWidget {
  const _DateTimeRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            SizedBox(
              width: 72,
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF171A1F),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(child: _DateTimeValue(value: value)),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFC4CAD4),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _DateTimeValue extends StatelessWidget {
  const _DateTimeValue({required this.value});

  final DateTime value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          _formatSheetDate(value),
          style: const TextStyle(
            color: Color(0xFF171A1F),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F7FF),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                _weekday(value),
                style: const TextStyle(
                  color: Color(0xFF1677FF),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatTime(value),
              style: const TextStyle(
                color: Color(0xFF1677FF),
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

String _formatDuration(Duration value) {
  final totalMinutes = value.inMinutes;
  final days = totalMinutes ~/ (24 * 60);
  final hours = (totalMinutes % (24 * 60)) ~/ 60;
  final minutes = totalMinutes % 60;
  final parts = <String>[];

  if (days > 0) {
    parts.add('$days天');
  }
  if (hours > 0) {
    parts.add('$hours小时');
  }
  if (minutes > 0) {
    parts.add('$minutes分钟');
  }

  return parts.isEmpty ? '0分钟' : parts.join(' ');
}

String _formatDateRange(DateTime start, DateTime end) {
  return '${_pad(start.month)}/${_pad(start.day)} ${_formatTime(start)}'
      ' - ${_pad(end.month)}/${_pad(end.day)} ${_formatTime(end)}';
}

String _formatSheetDate(DateTime value) {
  return '${value.year}-${_pad(value.month)}-${_pad(value.day)}';
}

String _formatTime(DateTime value) {
  return '${_pad(value.hour)}:${_pad(value.minute)}';
}

String _weekday(DateTime value) {
  const weekDays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  return weekDays[value.weekday - 1];
}

String _pad(int value) => value.toString().padLeft(2, '0');
