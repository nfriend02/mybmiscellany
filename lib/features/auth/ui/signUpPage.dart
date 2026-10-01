import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/history/saveResult.dart';
import '../../../core/session/sessionController.dart';
import '../../../core/theme/appColors.dart';
import '../../../core/theme/appTheme.dart';
import '../model/credentialRules.dart';
import 'authWidgets.dart';

enum _JoinMode { choose, email, phone }

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  _JoinMode _mode = _JoinMode.choose;

  @override
  Widget build(BuildContext context) {
    return AuthCard(
      child: switch (_mode) {
        _JoinMode.choose => _chooser(),
        _JoinMode.email => _EmailJoin(onBack: () => _set(_JoinMode.choose)),
        _JoinMode.phone => _PhoneJoin(onBack: () => _set(_JoinMode.choose)),
      },
    );
  }

  void _set(_JoinMode mode) => setState(() => _mode = mode);

  Widget _chooser() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '신규 회원 가입',
          style: orbitron(20, color: AppColors.navy),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          '이메일 또는 휴대폰 번호로 가입할 수 있습니다.',
          style: bodyText(color: AppColors.muted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        StackedButton(label: '이메일 가입', onPressed: () => _set(_JoinMode.email)),
        const SizedBox(height: 10),
        StackedButton(
          label: '휴대폰 번호 가입',
          filled: false,
          onPressed: () => _set(_JoinMode.phone),
        ),
      ],
    );
  }
}

class _EmailJoin extends StatefulWidget {
  const _EmailJoin({required this.onBack});

  final VoidCallback onBack;

  @override
  State<_EmailJoin> createState() => _EmailJoinState();
}

class _EmailJoinState extends State<_EmailJoin> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _emailTouched = false;
  bool _passwordTouched = false;
  bool _confirmTouched = false;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _emailTouched = true;
      _passwordTouched = true;
      _confirmTouched = true;
    });
    if (emailFormatError(_email.text) != null ||
        passwordFormatError(_password.text) != null ||
        passwordConfirmError(_password.text, _confirm.text) != null) {
      return;
    }
    setState(() => _busy = true);
    try {
      await context.read<SessionController>().registerWithEmail(
        email: _email.text,
        password: _password.text,
      );
      if (!mounted) return;
      showAppMessage(context, '회원 등록이 완료되었습니다.');
      context.go('/');
    } on FormatException catch (error) {
      if (mounted) showAppMessage(context, error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final emailError = _emailTouched ? emailFormatError(_email.text) : null;
    final passwordError = _passwordTouched
        ? passwordFormatError(_password.text)
        : null;
    final confirmError = _confirmTouched
        ? passwordConfirmError(_password.text, _confirm.text)
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '이메일 가입',
          style: orbitron(20, color: AppColors.navy),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        FieldBalloon(
          message: emailError,
          child: TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: '이메일',
              hintText: '*****@*********.com',
            ),
            onChanged: (_) => setState(() => _emailTouched = true),
          ),
        ),
        const SizedBox(height: 12),
        FieldBalloon(
          message: passwordError,
          child: SecretField(
            controller: _password,
            label: '비밀번호',
            onChanged: (_) => setState(() => _passwordTouched = true),
          ),
        ),
        const SizedBox(height: 12),
        FieldBalloon(
          message: confirmError,
          child: SecretField(
            controller: _confirm,
            label: '비밀번호 확인',
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() => _confirmTouched = true),
            onEditingComplete: _busy ? null : _submit,
          ),
        ),
        const SizedBox(height: 18),
        StackedButton(label: '회원 등록', onPressed: _busy ? null : _submit),
        TextButton(onPressed: widget.onBack, child: const Text('뒤로')),
      ],
    );
  }
}

class _PhoneJoin extends StatefulWidget {
  const _PhoneJoin({required this.onBack});

  final VoidCallback onBack;

  @override
  State<_PhoneJoin> createState() => _PhoneJoinState();
}

class _PhoneJoinState extends State<_PhoneJoin> {
  final _country = TextEditingController(text: '+ 82 ');
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _phoneTouched = false;
  bool _passwordTouched = false;
  bool _confirmTouched = false;
  bool _busy = false;

  @override
  void dispose() {
    _country.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _phoneTouched = true;
      _passwordTouched = true;
      _confirmTouched = true;
    });
    if (phoneFormatError(_phone.text) != null ||
        passwordFormatError(_password.text) != null ||
        passwordConfirmError(_password.text, _confirm.text) != null) {
      return;
    }
    setState(() => _busy = true);
    try {
      await context.read<SessionController>().registerWithPhone(
        country: _country.text,
        number: _phone.text,
        password: _password.text,
      );
      if (!mounted) return;
      showAppMessage(context, '회원 등록이 완료되었습니다.');
      context.go('/');
    } on FormatException catch (error) {
      if (mounted) showAppMessage(context, error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final phoneError = _phoneTouched ? phoneFormatError(_phone.text) : null;
    final passwordError = _passwordTouched
        ? passwordFormatError(_password.text)
        : null;
    final confirmError = _confirmTouched
        ? passwordConfirmError(_password.text, _confirm.text)
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '휴대폰 번호 가입',
          style: orbitron(20, color: AppColors.navy),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        FieldBalloon(
          message: phoneError,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 96,
                child: TextField(
                  controller: _country,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
                    LengthLimitingTextInputFormatter(8),
                  ],
                  decoration: const InputDecoration(labelText: '국가'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9-]')),
                    LengthLimitingTextInputFormatter(13),
                  ],
                  decoration: const InputDecoration(
                    labelText: '휴대폰 번호',
                    hintText: '10-1234-5678',
                  ),
                  onChanged: (_) => setState(() => _phoneTouched = true),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        FieldBalloon(
          message: passwordError,
          child: SecretField(
            controller: _password,
            label: '비밀번호',
            onChanged: (_) => setState(() => _passwordTouched = true),
          ),
        ),
        const SizedBox(height: 12),
        FieldBalloon(
          message: confirmError,
          child: SecretField(
            controller: _confirm,
            label: '비밀번호 확인',
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() => _confirmTouched = true),
            onEditingComplete: _busy ? null : _submit,
          ),
        ),
        const SizedBox(height: 18),
        StackedButton(label: '회원 등록', onPressed: _busy ? null : _submit),
        TextButton(onPressed: widget.onBack, child: const Text('뒤로')),
      ],
    );
  }
}
