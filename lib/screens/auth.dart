import 'package:flutter/material.dart';
import '../data/api.dart';
import '../data/app_update.dart';
import '../data/mock.dart';
import '../theme.dart';
import '../widgets/blue_button.dart';
import '../widgets/season_preview.dart';
import '../widgets/update_dialog.dart';
import 'admin/admin_shell.dart';
import 'client/home.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool admin = false;
  bool hide = true;
  bool busy = false;
  String? error;
  String? info;

  final _studentUser = TextEditingController();
  final _studentPass = TextEditingController();

  final _adminUser = TextEditingController();
  final _adminPass = TextEditingController();

  String? _challenge;
  String _emailHint = '';
  final _code = TextEditingController();

  AppUpdateInfo? _update;
  String _version = '';
  String _installed = '';

  @override
  void initState() {
    super.initState();
    AppUpdater.current().then((info) {
      if (mounted) setState(() => _installed = info.version);
    }).catchError((_) {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkUpdate());
  }

  Widget _versionLabel(bool onBlue) => IgnorePointer(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Text('Version $_installed',
                style: TextStyle(
                    fontSize: 12, color: onBlue ? Colors.white70 : C.muted)),
          ),
        ),
      );

  Future<void> _checkUpdate() async {
    final update = await AppUpdater.check();
    if (!mounted || update == null) return;
    final current = await AppUpdater.current();
    if (!mounted) return;
    setState(() {
      _update = update;
      _version = current.version;
    });
    await _openUpdate();
  }

  Future<void> _openUpdate() async {
    final update = _update;
    if (update == null) return;
    await showUpdateDialog(context, update, _version);
  }

  TextEditingController get _user => admin ? _adminUser : _studentUser;
  TextEditingController get _pass => admin ? _adminPass : _studentPass;

  @override
  void dispose() {
    _studentUser.dispose();
    _studentPass.dispose();
    _adminUser.dispose();
    _adminPass.dispose();
    _code.dispose();
    super.dispose();
  }

  void _enter() {
    state.isAdmin = admin;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => admin ? const AdminShell() : const ClientHome(),
    ));
  }

  Future<void> _submit() async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
      info = null;
    });
    try {
      await Api.syncClock();
      await Api.login(admin: admin, user: _user.text, pass: _pass.text);
      if (!mounted) return;
      _enter();
    } on TwoFactorRequired catch (t) {
      if (!mounted) return;
      setState(() {
        busy = false;
        _challenge = t.challenge;
        _emailHint = t.emailHint;
        _code.clear();
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          busy = false;
          error = e.message;
        });
      }
    }
  }

  Future<void> _verify() async {
    final challenge = _challenge;
    if (busy || challenge == null) return;
    if (_code.text.trim().length != 6) {
      setState(() => error = 'Enter the 6-digit code.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
      info = null;
    });
    try {
      await Api.verifyAdmin(challenge, _code.text);
      if (!mounted) return;
      _enter();
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          busy = false;
          error = e.message;
        });
      }
    }
  }

  Future<void> _resend() async {
    final challenge = _challenge;
    if (busy || challenge == null) return;
    setState(() {
      busy = true;
      error = null;
      info = null;
    });
    try {
      await Api.resendAdminCode(challenge);
      if (mounted) {
        setState(() {
          busy = false;
          info = 'A new code was sent to $_emailHint.';
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          busy = false;
          error = e.message;
        });
      }
    }
  }

  void _backToPassword() => setState(() {
        _challenge = null;
        _code.clear();
        error = null;
        info = null;
      });

  Widget _brand({bool large = false}) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            'assets/logo.jpg',
            height: large ? 90 : 64,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 18),
          Container(width: 44, height: 5, color: C.yellow),
          const SizedBox(height: 18),
          Text('STI Legazpi eVoter',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: large ? 56 : 36,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('Vote anywhere. Be faster, no waiting in line.',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: large ? 18 : 15,
                  height: 1.4)),
        ],
      );

  Widget _codeForm() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.mark_email_read_outlined, size: 44, color: C.blue),
          const SizedBox(height: 14),
          const Text('Check your email',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(
              'We sent a 6-digit code to $_emailHint. It expires in 10 minutes.',
              textAlign: TextAlign.center,
              style: TextStyle(color: C.muted)),
          const SizedBox(height: 20),
          TextField(
            controller: _code,
            autofocus: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 8),
            onSubmitted: (_) => _verify(),
            decoration:
                const InputDecoration(counterText: '', hintText: '000000'),
          ),
          if (error != null) ...[
            const SizedBox(height: 14),
            Text(error!,
                textAlign: TextAlign.center, style: TextStyle(color: C.danger)),
          ],
          if (info != null) ...[
            const SizedBox(height: 14),
            Text(info!,
                textAlign: TextAlign.center, style: TextStyle(color: C.ok)),
          ],
          const SizedBox(height: 20),
          BlueButton(
            label: busy ? 'Checking...' : 'Verify and sign in',
            onPressed: busy ? null : _verify,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                  onPressed: busy ? null : _resend,
                  child: const Text('Send a new code')),
              TextButton(
                  onPressed: busy ? null : _backToPassword,
                  child: const Text('Back')),
            ],
          ),
        ],
      );

  Widget _form() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: false,
                label: Text('Student'),
                icon: Icon(Icons.school),
              ),
              ButtonSegment(
                value: true,
                label: Text('Admin'),
                icon: Icon(Icons.admin_panel_settings),
              ),
            ],
            selected: {admin},
            onSelectionChanged: busy
                ? null
                : (s) {
                    setState(() {
                      admin = s.first;
                      error = null;
                      hide = true;
                    });
                  },
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _user,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: admin ? 'Username' : 'Student number',
              prefixIcon: Icon(
                admin ? Icons.admin_panel_settings : Icons.school,
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _pass,
            obscureText: hide,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  hide ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () => setState(() => hide = !hide),
              ),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 14),
            Text(error!,
                textAlign: TextAlign.center, style: TextStyle(color: C.danger)),
          ],
          const SizedBox(height: 22),
          BlueButton(
            label: busy ? 'Signing in...' : 'Sign in',
            onPressed: busy ? null : _submit,
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final form = _challenge == null ? _form() : _codeForm();
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
              child: _update == null
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Material(
                        color: C.yellow,
                        borderRadius: BorderRadius.circular(24),
                        elevation: 2,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: _openUpdate,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.system_update_alt,
                                    size: 18, color: C.onYellow),
                                const SizedBox(width: 6),
                                Text('Update to ${_update!.version}',
                                    style: const TextStyle(
                                        color: C.onYellow,
                                        fontWeight: FontWeight.w800)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
            Material(
              color: C.surface,
              shape: const CircleBorder(),
              elevation: 2,
              child: ThemeToggleButton(color: C.blue),
            ),
          ],
        ),
      ),
      body: LayoutBuilder(
        builder: (context, c) => Stack(
          children: [
            Positioned.fill(child: _layout(c, form)),
            if (_installed.isNotEmpty)
              Positioned(
                  left: 0, bottom: 0, child: _versionLabel(c.maxWidth >= 720)),
          ],
        ),
      ),
    );
  }

  Widget _layout(BoxConstraints c, Widget form) {
    if (c.maxWidth >= 720) {
      return Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [C.blue, C.dark ? C.navy : C.blueDeep],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              alignment: Alignment.centerLeft,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(48, 48, 48, 56),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _brand(large: c.maxWidth >= 1000),
                    const SizedBox(height: 36),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: const SeasonPreview(onBlue: true),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: cardBox(),
                    child: form,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [C.blue, C.dark ? C.navy : C.blueDeep],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 72, 24, 36),
          child: _brand(),
        ),
        Padding(padding: const EdgeInsets.fromLTRB(24, 24, 24, 8), child: form),
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 16, 24, 44),
          child: SeasonPreview(onBlue: false),
        ),
      ],
    );
  }
}
