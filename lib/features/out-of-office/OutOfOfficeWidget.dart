import 'package:flutter/material.dart';

import '../../core/format/formatTimestamp.dart';
import '../../core/history/saveResult.dart';
import '../../core/registry/featureModule.dart';
import '../../core/theme/appColors.dart';
import '../../core/theme/appTheme.dart';
import '../../shared/widgets/FeatureFrame.dart';
import '../../shared/widgets/InputBox.dart';
import 'outOfOfficeService.dart';

class OutOfOfficeWidget extends StatefulWidget {
  const OutOfOfficeWidget({super.key, required this.module});

  final FeatureModule module;

  @override
  State<OutOfOfficeWidget> createState() => _OutOfOfficeWidgetState();
}

class _OutOfOfficeWidgetState extends State<OutOfOfficeWidget> {
  final _name = TextEditingController();
  final _role = TextEditingController();
  final _reason = TextEditingController();
  final _contact = TextEditingController();
  late DateTime _start;
  late DateTime _returnAt;
  OutOfOfficeMessage? _message;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _start = DateTime(now.year, now.month, now.day, now.hour, now.minute);
    _returnAt = _start.add(const Duration(days: 1));
  }

  @override
  void dispose() {
    _name.dispose();
    _role.dispose();
    _reason.dispose();
    _contact.dispose();
    super.dispose();
  }

  Future<void> _pick(bool returning) async {
    final current = returning ? _returnAt : _start;
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null || !mounted) return;
    setState(() {
      final value = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      if (returning) {
        _returnAt = value;
      } else {
        _start = value;
      }
    });
  }

  void _buildMessage() {
    try {
      setState(() {
        _message = buildOutOfOffice(
          name: _name.text,
          role: _role.text,
          start: _start,
          returnAt: _returnAt,
          reason: _reason.text,
          contact: _contact.text,
        );
        _error = null;
      });
    } on FormatException catch (error) {
      setState(() => _error = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final message = _message;
    return FeatureFrame(
      module: widget.module,
      children: [
        InputBox(label: '이름', hint: '홍길동', controller: _name, maxLines: 1),
        const SizedBox(height: 12),
        InputBox(label: '역할', hint: '선택 사항', controller: _role, maxLines: 1),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            OutlinedButton(
              onPressed: () => _pick(false),
              child: Text('시작 ${formatTimestamp(_start)}'),
            ),
            OutlinedButton(
              onPressed: () => _pick(true),
              child: Text('복귀 ${formatTimestamp(_returnAt)}'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        InputBox(
          label: '사유',
          hint: '워크숍 참석',
          controller: _reason,
          enableVoice: true,
          maxLines: 3,
        ),
        const SizedBox(height: 12),
        InputBox(
          label: '긴급 연락처',
          hint: '팀 채널 또는 이메일',
          controller: _contact,
          maxLines: 1,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton(
              onPressed: _buildMessage,
              child: const Text('안내 문구 만들기'),
            ),
            if (message != null)
              OutlinedButton(
                onPressed: () => saveResult(
                  context,
                  featureType: widget.module.featureType,
                  title: '${_name.text.trim()} 부재 안내',
                  preview: message.text,
                  input: {
                    'name': _name.text.trim(),
                    'role': _role.text.trim(),
                    'start': _start.toIso8601String(),
                    'returnAt': _returnAt.toIso8601String(),
                    'reason': _reason.text.trim(),
                    'contact': _contact.text.trim(),
                  },
                  output: {'text': message.text},
                ),
                child: const Text('기록에 저장'),
              ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!, style: bodyText(color: AppColors.neonOrange)),
        ],
        if (message != null) ...[
          const SizedBox(height: 16),
          _GradientNotice(text: message.text),
        ],
      ],
    );
  }
}

class _GradientNotice extends StatefulWidget {
  const _GradientNotice({required this.text});

  final String text;

  @override
  State<_GradientNotice> createState() => _GradientNoticeState();
}

class _GradientNoticeState extends State<_GradientNotice>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment(-1 + t * 2, -1),
              end: Alignment(1, 1 - t),
              colors: const [
                AppColors.blue,
                AppColors.neonPurple,
                AppColors.neonOrange,
                AppColors.blueBright,
              ],
            ),
          ),
          child: child,
        );
      },
      child: SelectableText(
        widget.text,
        style: bodyText(color: Colors.white, size: 16),
      ),
    );
  }
}
