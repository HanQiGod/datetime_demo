import 'package:flutter/material.dart';

import 'leave_date_time_picker.dart';

enum _LeaveUnit { hours, days }

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
  late LeaveDaySelection _startDaySelection;
  late LeaveDaySelection _endDaySelection;

  _LeaveUnit _selectedLeaveUnit = _LeaveUnit.hours;
  String _selectedLeaveType = _leaveTypes.first;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _startAt = normalizeToMinuteInterval(now, roundUp: true);
    _endAt = _startAt.add(_defaultLeaveSpan);
    _startDaySelection = LeaveDaySelection(
      date: today,
      period: LeaveDayPeriod.morning,
    );
    _endDaySelection = LeaveDaySelection(
      date: today,
      period: LeaveDayPeriod.afternoon,
    );
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  bool get _isHourUnit => _selectedLeaveUnit == _LeaveUnit.hours;

  String get _leaveBalanceHint => switch (_selectedLeaveType) {
    '调休' => '可用调休余额 2 天',
    '病假' => '病假按制度审批，不扣减年假余额',
    _ => '事假不计薪，提交前请确认请假规则',
  };

  List<String> get _approvalNodes => switch (_selectedLeaveType) {
    '病假' => ['直属主管', '人事'],
    '调休' => ['直属主管', '考勤管理员'],
    _ => ['直属主管', '部门负责人'],
  };

  Duration get _leaveSpan => _endAt.difference(_startAt);

  int get _leaveDayHalfUnits {
    final dayDifference = _dateOnly(
      _endDaySelection.date,
    ).difference(_dateOnly(_startDaySelection.date)).inDays;
    final halfUnits =
        dayDifference * 2 +
        _periodOrder(_endDaySelection.period) -
        _periodOrder(_startDaySelection.period) +
        1;
    return halfUnits < 1 ? 1 : halfUnits;
  }

  String get _leaveDurationText => _isHourUnit
      ? _formatDuration(_leaveSpan)
      : _formatDayDuration(_leaveDayHalfUnits);

  String get _leaveRangeText => _isHourUnit
      ? _formatDateRange(_startAt, _endAt)
      : _formatDayRange(_startDaySelection, _endDaySelection);

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

  Future<void> _pickStartDaySelection() async {
    final today = DateTime.now();
    final minimumDate = DateTime(today.year, today.month, today.day);
    final maximumDate = minimumDate.add(_maximumSelectableRange);

    final picked = await showLeaveDayPicker(
      context: context,
      title: '请选择开始时间',
      helperText: '请选择请假开始日期和时段',
      initialValue: _startDaySelection,
      minimumDate: minimumDate,
      maximumDate: maximumDate,
    );

    if (picked == null) {
      return;
    }

    final normalizedEnd = _compareDaySelections(picked, _endDaySelection) <= 0
        ? _endDaySelection
        : picked;

    setState(() {
      _startDaySelection = picked;
      _endDaySelection = normalizedEnd;
    });
  }

  Future<void> _pickEndDaySelection() async {
    final minimumDate = _dateOnly(_startDaySelection.date);
    final maximumDate = minimumDate.add(const Duration(days: 365));

    final picked = await showLeaveDayPicker(
      context: context,
      title: '请选择结束时间',
      helperText: '结束日期不能早于开始日期',
      initialValue: _endDaySelection,
      minimumDate: minimumDate,
      maximumDate: maximumDate,
    );

    if (picked == null) {
      return;
    }

    final normalizedEnd = _compareDaySelections(picked, _startDaySelection) < 0
        ? _startDaySelection
        : picked;

    setState(() {
      _endDaySelection = normalizedEnd;
    });
  }

  void _submitExample() {
    final reason = _reasonController.text.trim();
    final message =
        '$_selectedLeaveType '
        '${_isHourUnit ? '按小时' : '按天'}：'
        '${_isHourUnit ? _leaveRangeText : _formatDaySubmitRange(_startDaySelection, _endDaySelection)}，'
        '共 $_leaveDurationText'
        '${reason.isEmpty ? '' : '，事由：$reason'}';

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('已提交示例：$message')));
  }

  void _switchUnit(_LeaveUnit unit) {
    if (_selectedLeaveUnit == unit) {
      return;
    }

    setState(() {
      _selectedLeaveUnit = unit;
    });
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
                      _BalanceBanner(
                        type: _selectedLeaveType,
                        message: _leaveBalanceHint,
                      ),
                      const SizedBox(height: 14),
                      const _SectionTitle(title: '请假信息'),
                      const SizedBox(height: 6),
                      _ValueRow(
                        label: '请假类型',
                        value: _selectedLeaveType,
                        onTap: _pickLeaveType,
                      ),
                      const Divider(height: 1, color: Color(0xFFF0F2F5)),
                      _LeaveUnitRow(
                        selectedUnit: _selectedLeaveUnit,
                        onChanged: _switchUnit,
                      ),
                      const Divider(height: 1, color: Color(0xFFF0F2F5)),
                      if (_isHourUnit) ...[
                        _HourDateTimeRow(
                          label: '开始时间',
                          value: _startAt,
                          onTap: _pickStartAt,
                        ),
                        const Divider(height: 1, color: Color(0xFFF0F2F5)),
                        _HourDateTimeRow(
                          label: '结束时间',
                          value: _endAt,
                          onTap: _pickEndAt,
                        ),
                      ] else ...[
                        _DaySelectionRow(
                          label: '开始时间',
                          selection: _startDaySelection,
                          onTap: _pickStartDaySelection,
                        ),
                        const Divider(height: 1, color: Color(0xFFF0F2F5)),
                        _DaySelectionRow(
                          label: '结束时间',
                          selection: _endDaySelection,
                          onTap: _pickEndDaySelection,
                        ),
                      ],
                      const Divider(height: 1, color: Color(0xFFF0F2F5)),
                      _ValueRow(
                        label: '请假时长',
                        value: _leaveDurationText,
                        helper: _leaveRangeText,
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
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _reasonController,
                          builder: (context, value, child) {
                            return Text(
                              '${value.text.characters.length}/200',
                              style: const TextStyle(
                                color: Color(0xFF9AA3AF),
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionTitle(title: '审批流程'),
                      const SizedBox(height: 14),
                      _ApprovalTimeline(nodes: _approvalNodes),
                      const Divider(height: 26, color: Color(0xFFF0F2F5)),
                      const _ValueRow(label: '抄送人', value: '无'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionTitle(title: '附件'),
                      SizedBox(height: 12),
                      _AttachmentUploader(),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: Color(0xFF1677FF),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _isHourUnit
                              ? '当前为按小时请假，使用日期 + 时间双列选择器，最小粒度为 30 分钟。审批人会按照组织规则自动匹配。'
                              : '当前为按天请假，使用日期 + 上午/下午双列选择器，时长按 0.5 天计算。审批人会按照组织规则自动匹配。',
                          style: const TextStyle(
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
                          _leaveDurationText,
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

class _BalanceBanner extends StatelessWidget {
  const _BalanceBanner({required this.type, required this.message});

  final String type;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0EBFF)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F2FF),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              type,
              style: const TextStyle(
                color: Color(0xFF1677FF),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF5C6675),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
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

class _ApprovalTimeline extends StatelessWidget {
  const _ApprovalTimeline({required this.nodes});

  final List<String> nodes;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const _AvatarBadge(
              backgroundColor: Color(0xFFE8F2FF),
              foregroundColor: Color(0xFF1677FF),
              label: '发',
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '发起申请',
                    style: TextStyle(
                      color: Color(0xFF171A1F),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '当前审批流：${nodes.join(' · ')}',
                    style: const TextStyle(
                      color: Color(0xFF8B94A1),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.only(left: 17),
          child: Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              height: 28,
              child: VerticalDivider(
                width: 2,
                thickness: 2,
                color: Color(0xFFE4E9F0),
              ),
            ),
          ),
        ),
        Row(
          children: [
            const _AvatarBadge(
              backgroundColor: Color(0xFFFDF2E8),
              foregroundColor: Color(0xFFED8A2F),
              label: '审',
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '审批人',
                    style: TextStyle(
                      color: Color(0xFF171A1F),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: nodes
                        .map((node) => _ApproverChip(name: node))
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.label,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      child: Text(
        label,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ApproverChip extends StatelessWidget {
  const _ApproverChip({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        name,
        style: const TextStyle(
          color: Color(0xFF5C6675),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
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

class _AttachmentUploader extends StatelessWidget {
  const _AttachmentUploader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD7E2F0)),
      ),
      child: const Column(
        children: [
          Icon(Icons.add_photo_alternate_outlined, color: Color(0xFF1677FF)),
          SizedBox(height: 8),
          Text(
            '添加附件',
            style: TextStyle(
              color: Color(0xFF1677FF),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '支持图片、文档等材料',
            style: TextStyle(color: Color(0xFF8B94A1), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _LeaveUnitRow extends StatelessWidget {
  const _LeaveUnitRow({required this.selectedUnit, required this.onChanged});

  final _LeaveUnit selectedUnit;
  final ValueChanged<_LeaveUnit> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const SizedBox(
            width: 72,
            child: Text(
              '请假单位',
              style: TextStyle(
                color: Color(0xFF171A1F),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F7F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _UnitButton(
                      label: '按小时',
                      selected: selectedUnit == _LeaveUnit.hours,
                      onTap: () => onChanged(_LeaveUnit.hours),
                    ),
                    _UnitButton(
                      label: '按天',
                      selected: selectedUnit == _LeaveUnit.days,
                      onTap: () => onChanged(_LeaveUnit.days),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnitButton extends StatelessWidget {
  const _UnitButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFF1677FF) : const Color(0xFF5C6675),
            fontSize: 14,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _HourDateTimeRow extends StatelessWidget {
  const _HourDateTimeRow({
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
            Expanded(child: _HourDateTimeValue(value: value)),
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

class _HourDateTimeValue extends StatelessWidget {
  const _HourDateTimeValue({required this.value});

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
            _SelectionBadge(label: _weekday(value)),
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

class _DaySelectionRow extends StatelessWidget {
  const _DaySelectionRow({
    required this.label,
    required this.selection,
    required this.onTap,
  });

  final String label;
  final LeaveDaySelection selection;
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatSheetDate(selection.date),
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
                      _SelectionBadge(label: _weekday(selection.date)),
                      const SizedBox(width: 8),
                      Text(
                        selection.period.label,
                        style: const TextStyle(
                          color: Color(0xFF1677FF),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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

class _SelectionBadge extends StatelessWidget {
  const _SelectionBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F7FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF1677FF),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

int _periodOrder(LeaveDayPeriod period) {
  return switch (period) {
    LeaveDayPeriod.morning => 0,
    LeaveDayPeriod.afternoon => 1,
  };
}

int _compareDaySelections(LeaveDaySelection left, LeaveDaySelection right) {
  final dayComparison = _dateOnly(left.date).compareTo(_dateOnly(right.date));
  if (dayComparison != 0) {
    return dayComparison;
  }
  return _periodOrder(left.period) - _periodOrder(right.period);
}

DateTime _dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
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

String _formatDayDuration(int halfUnits) {
  if (halfUnits.isEven) {
    return '${halfUnits ~/ 2}天';
  }
  return '${halfUnits / 2}天';
}

String _formatDateRange(DateTime start, DateTime end) {
  return '${_pad(start.month)}/${_pad(start.day)} ${_formatTime(start)}'
      ' - ${_pad(end.month)}/${_pad(end.day)} ${_formatTime(end)}';
}

String _formatDayRange(LeaveDaySelection start, LeaveDaySelection end) {
  return '${_pad(start.date.month)}/${_pad(start.date.day)} ${start.period.label}'
      ' - ${_pad(end.date.month)}/${_pad(end.date.day)} ${end.period.label}';
}

String _formatDaySubmitRange(LeaveDaySelection start, LeaveDaySelection end) {
  return '${_formatSheetDate(start.date)} ${start.period.label}'
      ' 至 ${_formatSheetDate(end.date)} ${end.period.label}';
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
