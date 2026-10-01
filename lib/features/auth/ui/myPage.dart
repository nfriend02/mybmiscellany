import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/history/saveResult.dart';
import '../../../core/session/sessionController.dart';
import '../../../core/theme/appColors.dart';
import '../../../core/theme/appTheme.dart';
import '../api/memberRepository.dart';
import '../model/credentialRules.dart';
import '../model/defaultAdmin.dart';
import 'authWidgets.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  final _nickname = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _editingName = false;
  bool _editingPassword = false;
  bool _confirmingWithdraw = false;
  bool _passwordTouched = false;
  bool _confirmTouched = false;
  String? _doneMessage;
  List<MemberSummary> _members = const [];
  String? _selectedMember;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMembers());
  }

  Future<void> _loadMembers() async {
    if (!mounted) return;
    final members = await context.read<SessionController>().memberChoices();
    if (!mounted) return;
    setState(() {
      _members = members;
      _selectedMember ??= members.isEmpty ? null : members.first.loginId;
    });
  }

  @override
  void dispose() {
    _nickname.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _saveNickname() async {
    await context.read<SessionController>().updateNickname(_nickname.text);
    if (!mounted) return;
    setState(() => _editingName = false);
    _nickname.clear();
    showAppMessage(context, '닉네임을 수정했습니다.');
  }

  Future<void> _savePassword() async {
    setState(() {
      _passwordTouched = true;
      _confirmTouched = true;
    });
    if (passwordFormatError(_password.text) != null ||
        passwordConfirmError(_password.text, _confirm.text) != null) {
      return;
    }
    await context.read<SessionController>().updatePassword(_password.text);
    if (!mounted) return;
    _password.clear();
    _confirm.clear();
    setState(() {
      _editingPassword = false;
      _passwordTouched = false;
      _confirmTouched = false;
    });
    showAppMessage(context, '비밀번호를 수정했습니다.');
  }

  Future<void> _appoint() async {
    final loginId = _selectedMember;
    if (loginId == null || loginId.isEmpty) return;
    try {
      await context.read<SessionController>().appointAdmin(loginId);
      if (!mounted) return;
      showAppMessage(context, '관리자로 지정했습니다.');
      await _loadMembers();
    } on FormatException catch (error) {
      if (mounted) showAppMessage(context, error.message);
    }
  }

  Future<void> _withdraw() async {
    try {
      await context.read<SessionController>().withdraw();
    } on FormatException catch (error) {
      if (mounted) showAppMessage(context, error.message);
      return;
    }
    if (!mounted) return;
    setState(() => _doneMessage = '탈퇴가 완료 되었습니다!');
    showAppMessage(context, '탈퇴가 완료 되었습니다!');
    context.go('/auth');
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionController>().user;
    if (!user.signedIn) {
      return AuthCard(
        child: Column(
          children: [
            Text('마이페이지', style: orbitron(20, color: AppColors.navy)),
            const SizedBox(height: 12),
            Text(
              '로그인하면 닉네임과 비밀번호를 관리할 수 있습니다.',
              style: bodyText(color: AppColors.muted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            StackedButton(label: '로그인', onPressed: () => context.go('/auth')),
          ],
        ),
      );
    }
    final passwordError = _passwordTouched
        ? passwordFormatError(_password.text)
        : null;
    final confirmError = _confirmTouched
        ? passwordConfirmError(_password.text, _confirm.text)
        : null;
    return AuthCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '마이페이지',
            style: orbitron(20, color: AppColors.navy),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nickname,
                  enabled: _editingName,
                  decoration: InputDecoration(
                    labelText: '닉네임',
                    hintText: user.displayName,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: _editingName
                    ? _saveNickname
                    : () => setState(() => _editingName = true),
                child: Text(_editingName ? '확인' : '수정'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('ID', style: labelText(color: AppColors.muted)),
          const SizedBox(height: 4),
          Text(user.loginLabel, style: bodyText(size: 16)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('비밀번호', style: labelText(color: AppColors.muted)),
                    const SizedBox(height: 4),
                    Text(maskedPassword, style: bodyText(size: 16)),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => setState(() {
                  _editingPassword = !_editingPassword;
                  _passwordTouched = false;
                  _confirmTouched = false;
                  _password.clear();
                  _confirm.clear();
                }),
                child: const Text('수정'),
              ),
            ],
          ),
          if (_editingPassword) ...[
            const SizedBox(height: 8),
            FieldBalloon(
              message: passwordError,
              child: SecretField(
                controller: _password,
                label: '새로운 비밀번호',
                onChanged: (_) => setState(() => _passwordTouched = true),
              ),
            ),
            const SizedBox(height: 12),
            FieldBalloon(
              message: confirmError,
              child: SecretField(
                controller: _confirm,
                label: '비밀번호 확인',
                onChanged: (_) => setState(() => _confirmTouched = true),
              ),
            ),
            const SizedBox(height: 12),
            StackedButton(label: '수정 확인', onPressed: _savePassword),
          ],
          if (user.admin) ...[
            const SizedBox(height: 28),
            Text('관리자 지정', style: orbitron(16, color: AppColors.navy)),
            const SizedBox(height: 8),
            Text(
              '가입된 회원을 골라 관리자로 추가할 수 있습니다.',
              style: bodyText(size: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            if (_members.isEmpty)
              Text('가입된 회원이 없습니다.', style: bodyText(color: AppColors.muted))
            else
              DropdownButtonFormField<String>(
                initialValue:
                    _members.any((member) => member.loginId == _selectedMember)
                    ? _selectedMember
                    : _members.first.loginId,
                decoration: const InputDecoration(labelText: '가입 회원'),
                items: [
                  for (final member in _members)
                    DropdownMenuItem(
                      value: member.loginId,
                      child: Text(
                        '${member.nickname.isEmpty ? '회원' : member.nickname} · ${member.loginId}${member.admin ? ' · 관리자' : ''}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) => setState(() => _selectedMember = value),
              ),
            const SizedBox(height: 12),
            StackedButton(
              label: '관리자로 지정',
              onPressed: _members.isEmpty ? null : _appoint,
            ),
          ],
          if (normalizeEmail(user.loginLabel) !=
              normalizeEmail(defaultAdminEmail)) ...[
            const SizedBox(height: 28),
            if (_confirmingWithdraw)
              const FieldBalloon(
                message: '탈퇴하시면 모든 기록이 사라집니다! 그래도 탈퇴하시겠습니까?',
                child: SizedBox.shrink(),
              ),
            if (_doneMessage != null)
              Text(
                _doneMessage!,
                style: bodyText(color: AppColors.blue, weight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _confirmingWithdraw
                    ? AppColors.neonOrange
                    : AppColors.navy,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (!_confirmingWithdraw) {
                  setState(() => _confirmingWithdraw = true);
                  return;
                }
                _withdraw();
              },
              child: Text(_confirmingWithdraw ? '탈퇴 확인' : '회원탈퇴'),
            ),
          ],
        ],
      ),
    );
  }
}
