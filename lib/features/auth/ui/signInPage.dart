import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import '../../../core/history/saveResult.dart';
import '../../../core/session/sessionController.dart';
import '../../../core/theme/appColors.dart';
import '../../../core/theme/appTheme.dart';
import 'authWidgets.dart';

enum _EnterMode { choose, email, phone }

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  _EnterMode _mode = _EnterMode.choose;
  bool _googleBusy = false;
  late final TapGestureRecognizer _joinTap;

  @override
  void initState() {
    super.initState();
    _joinTap = TapGestureRecognizer()..onTap = () => context.go('/auth/join');
  }

  @override
  void dispose() {
    _joinTap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthCard(
      child: switch (_mode) {
        _EnterMode.choose => _chooser(),
        _EnterMode.email => _EmailEnter(onBack: () => _set(_EnterMode.choose)),
        _EnterMode.phone => _PhoneEnter(onBack: () => _set(_EnterMode.choose)),
      },
    );
  }

  void _set(_EnterMode mode) => setState(() => _mode = mode);

  Future<void> _google() async {
    setState(() => _googleBusy = true);
    try {
      await context.read<SessionController>().signInWithGoogle();
      if (!mounted) return;
      showAppMessage(context, 'Google 계정으로 로그인했습니다.');
      context.go('/');
    } on GoogleSignInException catch (error) {
      if (!mounted) return;
      if (error.code == GoogleSignInExceptionCode.canceled) {
        showAppMessage(context, '로그인을 취소했습니다.');
      } else {
        showAppMessage(context, error.description ?? 'Google 로그인에 실패했습니다.');
      }
    } on FormatException catch (error) {
      if (mounted) showAppMessage(context, error.message);
    } catch (_) {
      if (mounted) showAppMessage(context, 'Google 로그인에 실패했습니다.');
    } finally {
      if (mounted) setState(() => _googleBusy = false);
    }
  }

  Widget _chooser() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '로그인',
          style: orbitron(20, color: AppColors.navy),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        StackedButton(
          label: 'Google 로그인',
          onPressed: _googleBusy ? null : _google,
        ),
        const SizedBox(height: 10),
        StackedButton(
          label: '이메일 로그인',
          filled: false,
          onPressed: () => _set(_EnterMode.email),
        ),
        const SizedBox(height: 10),
        StackedButton(
          label: '휴대폰번호 로그인',
          filled: false,
          onPressed: () => _set(_EnterMode.phone),
        ),
        const SizedBox(height: 16),
        Text.rich(
          TextSpan(
            style: bodyText(color: AppColors.muted),
            children: [
              const TextSpan(text: '처음이라면 '),
              TextSpan(
                text: '신규 회원',
                style: bodyText(color: AppColors.blue, weight: FontWeight.w700),
                recognizer: _joinTap,
              ),
              const TextSpan(text: ' 가입하여 주세요'),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _EmailEnter extends StatefulWidget {
  const _EmailEnter({required this.onBack});

  final VoidCallback onBack;

  @override
  State<_EmailEnter> createState() => _EmailEnterState();
}

class _EmailEnterState extends State<_EmailEnter> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();
  String? _emailBubble;
  String? _passwordBubble;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _passwordFocus.addListener(_onPasswordFocus);
  }

  @override
  void dispose() {
    _passwordFocus.removeListener(_onPasswordFocus);
    _passwordFocus.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _onPasswordFocus() async {
    if (_passwordFocus.hasFocus) {
      final exists = await context.read<SessionController>().emailExists(
        _email.text,
      );
      if (!mounted || !_passwordFocus.hasFocus) return;
      setState(() => _emailBubble = exists ? null : '없는 이메일 ID입니다');
      return;
    }
    if (_password.text.isEmpty) return;
    final session = context.read<SessionController>();
    final exists = await session.emailExists(_email.text);
    if (!exists) return;
    final accepted = await session.emailPasswordAccepted(
      _email.text,
      _password.text,
    );
    if (!mounted || _passwordFocus.hasFocus) return;
    setState(() {
      _passwordBubble = accepted ? null : '비밀번호가 틀립니다. 다시 확인해 주세요';
    });
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      final session = context.read<SessionController>();
      if (!await session.emailExists(_email.text)) {
        if (!mounted) return;
        setState(() => _emailBubble = '없는 이메일 ID입니다');
        return;
      }
      await session.signInWithEmail(
        email: _email.text,
        password: _password.text,
      );
      if (!mounted) return;
      context.go('/');
    } on FormatException catch (error) {
      if (!mounted) return;
      setState(() => _passwordBubble = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '이메일 로그인',
          style: orbitron(20, color: AppColors.navy),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        FieldBalloon(
          message: _emailBubble,
          child: TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: '이메일 로그인 ID',
              hintText: '*****@*********.com',
            ),
            onChanged: (_) => setState(() => _emailBubble = null),
          ),
        ),
        const SizedBox(height: 12),
        FieldBalloon(
          message: _passwordBubble,
          child: SecretField(
            controller: _password,
            focusNode: _passwordFocus,
            label: '비밀번호',
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() => _passwordBubble = null),
            onEditingComplete: _busy ? null : _submit,
          ),
        ),
        const SizedBox(height: 18),
        StackedButton(label: '로그인', onPressed: _busy ? null : _submit),
        TextButton(onPressed: widget.onBack, child: const Text('뒤로')),
      ],
    );
  }
}

class _PhoneEnter extends StatefulWidget {
  const _PhoneEnter({required this.onBack});

  final VoidCallback onBack;

  @override
  State<_PhoneEnter> createState() => _PhoneEnterState();
}

class _PhoneEnterState extends State<_PhoneEnter> {
  final _country = TextEditingController(text: '+ 82 ');
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();
  String? _phoneBubble;
  String? _passwordBubble;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _passwordFocus.addListener(_onPasswordFocus);
  }

  @override
  void dispose() {
    _passwordFocus.removeListener(_onPasswordFocus);
    _passwordFocus.dispose();
    _country.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _onPasswordFocus() async {
    final session = context.read<SessionController>();
    if (_passwordFocus.hasFocus) {
      final exists = await session.phoneExists(_country.text, _phone.text);
      if (!mounted || !_passwordFocus.hasFocus) return;
      setState(() => _phoneBubble = exists ? null : '없는 휴대폰 전화번호 ID입니다');
      return;
    }
    if (_password.text.isEmpty) return;
    final exists = await session.phoneExists(_country.text, _phone.text);
    if (!exists) return;
    final accepted = await session.phonePasswordAccepted(
      _country.text,
      _phone.text,
      _password.text,
    );
    if (!mounted || _passwordFocus.hasFocus) return;
    setState(() {
      _passwordBubble = accepted ? null : '비밀번호가 틀립니다. 다시 확인해 주세요';
    });
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      final session = context.read<SessionController>();
      if (!await session.phoneExists(_country.text, _phone.text)) {
        if (!mounted) return;
        setState(() => _phoneBubble = '없는 휴대폰 전화번호 ID입니다');
        return;
      }
      await session.signInWithPhone(
        country: _country.text,
        number: _phone.text,
        password: _password.text,
      );
      if (!mounted) return;
      context.go('/');
    } on FormatException catch (error) {
      if (!mounted) return;
      setState(() => _passwordBubble = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '휴대폰 번호 로그인',
          style: orbitron(20, color: AppColors.navy),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Text('휴대폰 번호 로그인 ID', style: labelText()),
        const SizedBox(height: 6),
        FieldBalloon(
          message: _phoneBubble,
          child: Row(
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
                  decoration: const InputDecoration(hintText: '10-1234-5678'),
                  onChanged: (_) => setState(() => _phoneBubble = null),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        FieldBalloon(
          message: _passwordBubble,
          child: SecretField(
            controller: _password,
            focusNode: _passwordFocus,
            label: '비밀번호',
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() => _passwordBubble = null),
            onEditingComplete: _busy ? null : _submit,
          ),
        ),
        const SizedBox(height: 18),
        StackedButton(label: '로그인', onPressed: _busy ? null : _submit),
        TextButton(onPressed: widget.onBack, child: const Text('뒤로')),
      ],
    );
  }
}
