// 登录页面壳：持有唯一背景，在同一路由内编排首页、邮箱和验证码前景切换。
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_lottie_background.dart';
import 'email_address_step.dart';
import 'email_verification_step.dart';
import 'login_controller.dart';
import 'login_home_step.dart';

/// 三个短期前景步骤只属于当前页面，不新增路由或全局状态。
enum _LoginStep { home, email, verification }

/// 固定背景上的三步登录页面，业务事件交由 LoginController。
final class LoginPage extends StatefulWidget {
  /// 创建登录页面。
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

final class _LoginPageState extends State<LoginPage>
    with WidgetsBindingObserver {
  late final LoginController _controller = Get.find<LoginController>();
  _LoginStep _step = _LoginStep.home;
  int _stepRevision = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _controller.updateResendCountdown();
  }

  /// 切换仅改变前景并收起旧输入焦点，背景不参与切换。
  void _changeStep(_LoginStep value) {
    FocusManager.instance.primaryFocus?.unfocus();
    _controller.failure.value = null;
    setState(() {
      _stepRevision++;
      _step = value;
    });
  }

  /// 每次重新进入邮箱流程保留邮箱，丢弃旧验证码和过期请求结果。
  void _openEmail() {
    _controller.resetEmailVerification();
    _changeStep(_LoginStep.email);
  }

  /// 发码成功才前进；返回或离开页面后到达的结果不得重新打开验证码步骤。
  Future<void> _sendCode() async {
    final revision = _stepRevision;
    final sent = await _controller.sendCode();
    if (!mounted ||
        !sent ||
        revision != _stepRevision ||
        _step != _LoginStep.email) {
      return;
    }
    _changeStep(_LoginStep.verification);
  }

  /// 验证码返回邮箱，邮箱返回首页；正在提交登录时不改变流程。
  void _goBack() {
    if (_controller.signingIn.value) return;
    _controller.resetEmailVerification();
    _changeStep(
      _step == _LoginStep.verification ? _LoginStep.email : _LoginStep.home,
    );
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _step == _LoginStep.home,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop && _step != _LoginStep.home) _goBack();
    },
    child: Scaffold(
      backgroundColor: AppColors.scaffold,
      // 键盘只压缩前景可用空间，避免改变背景的裁切或播放位置。
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AppLottieBackground(playbackSpeed: 1.5),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 402),
                  child: SizedBox.expand(
                    child: ClipRect(
                      child: AnimatedSwitcher(
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 320),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        // 退出的前景不再接收触控、焦点或无障碍事件，防止动画期间重复提交。
                        layoutBuilder: (current, previous) => Stack(
                          alignment: Alignment.center,
                          children: [
                            for (final outgoing in previous)
                              ExcludeSemantics(
                                child: ExcludeFocus(
                                  child: IgnorePointer(child: outgoing),
                                ),
                              ),
                            ?current,
                          ],
                        ),
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.05, 0),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        ),
                        child: switch (_step) {
                          _LoginStep.home => LoginHomeStep(
                            key: ValueKey(_step),
                            controller: _controller,
                            onEmail: _openEmail,
                          ),
                          _LoginStep.email => EmailAddressStep(
                            key: ValueKey(_step),
                            controller: _controller,
                            onBack: _goBack,
                            onNext: _sendCode,
                          ),
                          _LoginStep.verification => EmailVerificationStep(
                            key: ValueKey(_step),
                            controller: _controller,
                            onBack: _goBack,
                          ),
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
