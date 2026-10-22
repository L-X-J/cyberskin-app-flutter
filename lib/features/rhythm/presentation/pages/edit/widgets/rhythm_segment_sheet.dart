// 添加/修改片段弹层：固定标题和玻璃操作列，Continue 保留配置并向左换页。
import 'package:cyberskin_app/core/theme/app_rhythm_style.dart';
import 'package:cyberskin_app/core/theme/app_typography.dart';
import 'package:cyberskin_app/core/widgets/app_liquid_glass_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_liquid_glass_plus/flutter_liquid_glass.dart';
import 'package:get/get.dart';

import '../../../../domain/entities/rhythm_program.dart';
import '../../../widgets/rhythm_surface.dart';
import '../rhythm_edit_controller.dart';
import 'rhythm_channel_editor.dart';
import 'rhythm_duration_wheel.dart';

/// 短生命周期片段配置；继续添加时保留当前参数。
final class RhythmSegmentSheet extends StatefulWidget {
  /// 创建实例；依赖及初始状态由调用方提供。
  const RhythmSegmentSheet({super.key, required this.controller, this.index});

  /// 拥有片段草稿和保存规则的编辑控制器。
  final RhythmEditController controller;

  /// 当前片段索引；编辑弹层为空表示新增。
  final int? index;

  @override
  State<RhythmSegmentSheet> createState() => _RhythmSegmentSheetState();
}

final class _RhythmSegmentSheetState extends State<RhythmSegmentSheet>
    with TickerProviderStateMixin {
  late final AnimationController _entrance;
  Animation<double>? _routeAnimation;
  bool _entranceStarted = false;

  late final AnimationController _transition =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 360),
      )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _outgoingForm = null);
        }
      });
  Widget? _outgoingForm;
  int _formGeneration = 0;
  int duration = 3;
  late List<RhythmChannelSetting> settings;
  String? error;

  bool get _transitioning => _outgoingForm != null;

  @override
  void initState() {
    super.initState();
    final step = widget.index == null
        ? null
        : RhythmStep.decode(widget.controller.segments[widget.index!]);
    duration = step?.durationSec ?? 3;
    settings = widget.controller.capabilities.map((c) {
      final existing = step?.channels.where((s) => s.channel == c.channel);
      if (existing != null && existing.isNotEmpty) return existing.first;
      return RhythmChannelSetting(
        channel: c.channel,
        on: step == null,
        value:
            c.channel == RhythmChannel.suck || c.channel == RhythmChannel.heat
            ? null
            : c.defaultValue > 0
            ? c.defaultValue.clamp(0, 100)
            : c.variableSpeed
            ? 50
            : (c.gearMax ?? 0) > 0
            ? (100 / c.gearMax!).round()
            : null,
      );
    }).toList();
    _entrance = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 360 + settings.length * 70),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final routeAnimation = ModalRoute.of(context)?.animation;
    if (_routeAnimation != routeAnimation) {
      _routeAnimation?.removeStatusListener(_onRouteStatus);
      _routeAnimation = routeAnimation;
      _routeAnimation?.addStatusListener(_onRouteStatus);
    }
    if (MediaQuery.disableAnimationsOf(context)) {
      _entranceStarted = true;
      _entrance.value = 1;
    } else if (routeAnimation == null || routeAnimation.isCompleted) {
      _startEntrance();
    }
    // 系统在途中开启减少动态效果时立即结束位移并恢复交互。
    if (MediaQuery.disableAnimationsOf(context) && _transitioning) {
      _transition.stop();
      _outgoingForm = null;
    }
  }

  void _onRouteStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _startEntrance();
  }

  void _startEntrance() {
    if (_entranceStarted || !mounted) return;
    _entranceStarted = true;
    _entrance.forward();
  }

  @override
  void dispose() {
    _routeAnimation?.removeStatusListener(_onRouteStatus);
    _entrance.dispose();
    _transition.dispose();
    super.dispose();
  }

  /// 只为成功的新增 Continue 切换表单；锁同时保护同步连击和退出中的控件。
  void _save(bool close) {
    if (_transitioning) return;
    final step = RhythmStep(durationSec: duration, channels: settings);
    final ok = widget.controller.putSegment(step, at: widget.index);
    if (!ok) {
      setState(() => error = widget.controller.error.value);
      return;
    }
    if (close || widget.index != null) {
      Get.back<void>();
      return;
    }
    setState(() {
      error = null;
      if (!MediaQuery.disableAnimationsOf(context)) {
        _outgoingForm = _form(_formGeneration);
      }
      _formGeneration++;
    });
    if (_transitioning) _transition.forward(from: 0);
  }

  Widget _form(int generation) => Column(
    key: ValueKey('segment-form-$generation'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _itemEntrance(
        0,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Duration', style: AppTypography.bodyMedium),
            const SizedBox(height: 12),
            RhythmDurationWheel(
              value: duration,
              onChanged: (value) {
                if (!_transitioning) setState(() => duration = value);
              },
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      for (var i = 0; i < settings.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _itemEntrance(
            i + 1,
            RhythmChannelEditor(
              capability: widget.controller.capabilities[i],
              setting: settings[i],
              onChanged: (value) {
                if (!_transitioning) {
                  setState(() {
                    // CM-> 的数字全是模式号；选择模式与数字速度必须切换整段语义。
                    if (value.mode != null) {
                      settings = settings
                          .map((setting) => setting.copyWith(clearValue: true))
                          .toList();
                      value = value.copyWith(clearValue: true);
                    } else if (value.value != null) {
                      settings = settings
                          .map((setting) => setting.copyWith(clearMode: true))
                          .toList();
                    }
                    settings[i] = value;
                  });
                }
              },
            ),
          ),
        ),
      if (settings.any((setting) => setting.on && setting.mode != null))
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            'Mode control selected. Adjusting speed switches this segment to speed control.',
            style: TextStyle(fontSize: 12),
          ),
        ),
      RhythmError(error),
    ],
  );

  /// 弹层完全展开后，配置区内的每个组件按顺序淡入并从底部浮入。
  Widget _itemEntrance(int index, Widget child) => AnimatedBuilder(
    animation: _entrance,
    child: child,
    builder: (context, child) {
      final elapsed = _entrance.value * _entrance.duration!.inMilliseconds;
      final progress = Curves.easeOutCubic.transform(
        ((elapsed - index * 70) / 360).clamp(0.0, 1.0),
      );
      return Opacity(
        key: ValueKey('segment-item-opacity-$index'),
        opacity: progress,
        child: Transform.translate(
          key: ValueKey('segment-item-entrance-$index'),
          offset: Offset(0, 24 * (1 - progress)),
          child: child,
        ),
      );
    },
  );

  Widget _scrollingForm(Widget form, double footerHeight) =>
      SingleChildScrollView(
        key: ValueKey('segment-scroll-${form.key}'),
        padding: EdgeInsets.fromLTRB(22, 0, 22, footerHeight),
        child: form,
      );

  @override
  Widget build(BuildContext context) => LiquidGlassLayer(
    child: SizedBox(
      width: AppRhythmStyle.maxWidth,
      height: MediaQuery.sizeOf(context).height * 0.7,
      child: RhythmSurface(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
              child: Row(
                children: [
                  const SizedBox(width: 40),
                  Expanded(
                    child: Text(
                      widget.index == null
                          ? 'Add device rhythm'
                          : 'Edit segment',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Get.back<void>(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final stacked =
                      constraints.maxWidth - 44 < 340 &&
                      MediaQuery.textScalerOf(context).scale(20) > 24;
                  final buttonHeight = stacked ? 72.0 : 58.0;
                  final bottom = 20 + MediaQuery.paddingOf(context).bottom;
                  final actionHeight = stacked && widget.index == null
                      ? buttonHeight * 2 + 12
                      : buttonHeight;
                  // 同一局部约束同时决定固定列尺寸和滚动预留，避免测量后的跳动。
                  final footerHeight = 4 + actionHeight + bottom;
                  final actions = [
                    if (widget.index == null)
                      AppLiquidGlassButton(
                        label: 'Continue',
                        width: double.infinity,
                        fillColorOverride: Colors.transparent,
                        height: buttonHeight,
                        onPressed: _transitioning ? null : () => _save(false),
                      ),
                    AppLiquidGlassButton(
                      label: 'Confirm',
                      width: double.infinity,
                      height: buttonHeight,
                      onPressed: _transitioning ? null : () => _save(true),
                    ),
                  ];
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRect(
                        key: const ValueKey('segment-body'),
                        child: ExcludeFocus(
                          excluding: _transitioning,
                          child: IgnorePointer(
                            ignoring: _transitioning,
                            child: AnimatedBuilder(
                              animation: _transition,
                              builder: (context, _) {
                                final current = _scrollingForm(
                                  _form(_formGeneration),
                                  footerHeight,
                                );
                                if (!_transitioning) return current;
                                final progress = Curves.easeInOutCubic
                                    .transform(_transition.value);
                                return Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    ExcludeSemantics(
                                      child: Transform.translate(
                                        key: const ValueKey('segment-outgoing'),
                                        offset: Offset(
                                          -constraints.maxWidth * progress,
                                          0,
                                        ),
                                        child: _scrollingForm(
                                          _outgoingForm!,
                                          footerHeight,
                                        ),
                                      ),
                                    ),
                                    Transform.translate(
                                      key: const ValueKey('segment-incoming'),
                                      offset: Offset(
                                        constraints.maxWidth * (1 - progress),
                                        0,
                                      ),
                                      child: current,
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),

                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: footerHeight,
                        child: Container(
                          padding: EdgeInsets.fromLTRB(22, 4, 22, bottom),
                          child: stacked
                              ? Column(
                                  children: [
                                    for (
                                      var i = 0;
                                      i < actions.length;
                                      i++
                                    ) ...[
                                      if (i > 0) const SizedBox(height: 12),
                                      actions[i],
                                    ],
                                  ],
                                )
                              : Row(
                                  children: [
                                    for (
                                      var i = 0;
                                      i < actions.length;
                                      i++
                                    ) ...[
                                      if (i > 0) const SizedBox(width: 18),
                                      Expanded(child: actions[i]),
                                    ],
                                  ],
                                ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
