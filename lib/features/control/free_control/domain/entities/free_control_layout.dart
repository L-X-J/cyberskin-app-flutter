// 自由控制页面的布局配置领域模型；由后端 JSON 驱动组件排列。

/// 后端下发的自由控制页面布局配置。
///
/// 每个布局由 [components] 列表定义组件顺序与属性，
/// 客户端按序渲染对应占位或真实组件。
final class FreeControlLayout {
  /// 创建布局配置并冻结组件列表。
  FreeControlLayout({
    required this.deviceName,
    required List<FreeControlComponentConfig> components,
    this.columns = 2,
  }) : components = List.unmodifiable(components);

  /// 当前布局所属的设备展示名称。
  final String deviceName;

  /// 布局网格列数，默认 2。
  final int columns;

  /// 按展示顺序排列的组件配置列表。
  final List<FreeControlComponentConfig> components;

  /// 从后端 DeviceModelDetail 的 `layout` 与 `supportedActions` 解析构造。
  ///
  /// 后台布局编辑器只持久化 `type/variant/row/col/order`，档位数与模式名称归属能力配置；
  /// 因此模块缺失这些字段时，按模块类型从 [supportedActions] 补齐 `gearMax` / `modes`。
  /// 模块自身显式下发的字段优先于能力配置。
  factory FreeControlLayout.fromJson({
    required String deviceName,
    Map<String, dynamic>? layoutJson,
    List<Map<String, dynamic>> supportedActions = const [],
  }) {
    final rawColumns = layoutJson?['columns'];
    final columns = (rawColumns is int && rawColumns > 0) ? rawColumns : 2;
    final rawModules = layoutJson?['modules'];

    final List<FreeControlComponentConfig> components = [];

    if (rawModules is List && rawModules.isNotEmpty) {
      final validModules = rawModules.whereType<Map<String, dynamic>>();
      for (final mod in validModules) {
        final type = FreeControlComponentType.fromString(
          mod['type'] as String?,
        );
        final config = FreeControlComponentConfig.fromJson(
          mod,
          capability: type?.findAction(supportedActions),
        );
        if (config != null) {
          components.add(config);
        }
      }
    }

    // 如果后端未返回布局配置或为空，则基于默认常规配置兜底
    if (components.isEmpty) {
      return FreeControlLayout.defaultPreset(deviceName: deviceName);
    }

    return FreeControlLayout(
      deviceName: deviceName,
      columns: columns,
      components: components,
    );
  }

  /// 兜底默认预设（对应设计图 img_free_control）：
  /// Row 0: Heat(1x1, col:0), Suck(1x1, col:1)
  /// Row 1: Telescopic(3x1, col:0, rows:3), Vibration(3x1, col:1, rows:3)
  /// Row 4: OneClickClimax(2x2, col:0, rows:2, cols:2)
  factory FreeControlLayout.defaultPreset({required String deviceName}) {
    return FreeControlLayout(
      deviceName: deviceName,
      columns: 2,
      components: const [
        FreeControlComponentConfig(
          type: FreeControlComponentType.heat,
          variant: 'heat_toggle_1x1',
          rows: 1,
          cols: 1,
          row: 0,
          col: 0,
          order: 1,
        ),
        FreeControlComponentConfig(
          type: FreeControlComponentType.suck,
          variant: 'suck_toggle_1x1',
          rows: 1,
          cols: 1,
          row: 0,
          col: 1,
          order: 2,
        ),
        FreeControlComponentConfig(
          type: FreeControlComponentType.telescopic,
          variant: 'telescopic_mode_3x1',
          rows: 3,
          cols: 1,
          row: 1,
          col: 0,
          order: 3,
          gearMax: 6,
          gearCurrent: 4,
        ),
        FreeControlComponentConfig(
          type: FreeControlComponentType.vibration,
          variant: 'vibration_mode_3x1',
          rows: 3,
          cols: 1,
          row: 1,
          col: 1,
          order: 4,
          gearMax: 6,
          gearCurrent: 2,
        ),
        FreeControlComponentConfig(
          type: FreeControlComponentType.oneClickClimax,
          variant: 'climax_2x2',
          rows: 2,
          cols: 2,
          row: 4,
          col: 0,
          order: 5,
        ),
      ],
    );
  }
}

/// 自由控制页面可渲染的组件类型。
enum FreeControlComponentType {
  /// 伸缩通道。
  telescopic,

  /// 振动通道。
  vibration,

  /// 吮吸/吸附通道。
  suck,

  /// 加热通道。
  heat,

  /// 模式选择。
  mode,

  /// 一键高潮。
  oneClickClimax;

  /// 从后台字符串类型安全解析。
  static FreeControlComponentType? fromString(String? typeStr) {
    if (typeStr == null) return null;
    return switch (typeStr.toLowerCase()) {
      'telescopic' => FreeControlComponentType.telescopic,
      'vibration' => FreeControlComponentType.vibration,
      'suck' => FreeControlComponentType.suck,
      'heat' => FreeControlComponentType.heat,
      'mode' => FreeControlComponentType.mode,
      'oneclickclimax' ||
      'one_click_climax' ||
      'climax' => FreeControlComponentType.oneClickClimax,
      _ => null,
    };
  }

  /// 能力配置 `supportedActions[].code` 中对应本模块类型的取值；
  /// 别名与 `ConnectedDeviceRepository` 的能力解析保持一致。
  Set<String> get _actionCodes => switch (this) {
    FreeControlComponentType.telescopic => const {'thrust', 'telescopic'},
    FreeControlComponentType.vibration => const {'vibration', 'vibrate'},
    FreeControlComponentType.suck => const {'suck', 'suction'},
    FreeControlComponentType.heat => const {'heat', 'heating'},
    FreeControlComponentType.mode ||
    FreeControlComponentType.oneClickClimax => const <String>{},
  };

  /// 在后台能力动作列表中查找本模块类型对应的动作；未配置时返回 `null`。
  Map<String, dynamic>? findAction(List<Map<String, dynamic>> actions) {
    final codes = _actionCodes;
    for (final action in actions) {
      final code = action['code']?.toString().toLowerCase();
      if (code != null && codes.contains(code)) return action;
    }
    return null;
  }
}

/// 单个组件在布局中的配置。
final class FreeControlComponentConfig {
  /// 创建组件配置。
  const FreeControlComponentConfig({
    required this.type,
    required this.variant,
    this.rows = 1,
    this.cols = 1,
    this.row = 0,
    this.col = 0,
    this.order = 0,
    this.label,
    this.gearMax,
    this.gearMin = 1,
    this.gearCurrent,
    this.variableSpeedSupported = false,
    this.defaultValue = 1,
    this.modes = const <String>[],
  });

  /// 组件类型。
  final FreeControlComponentType type;

  /// 后端 variant 字段，例如：'telescopic_mode_3x1', 'heat_toggle_1x1', 'climax_2x2' 等。
  final String variant;

  /// 占用的网格行数。
  final int rows;

  /// 占用的网格列数（1 或 2）。
  final int cols;

  /// 布局中的起始行（从 0 开始）。
  final int row;

  /// 布局中的起始列（0 或 1）。
  final int col;

  /// 排序次序。
  final int order;

  /// 显示标签；为空时使用默认标签。
  final String? label;

  /// 离散档位最大值；例如 6。
  final int? gearMax;

  /// 离散档位最小值；默认 1。
  final int gearMin;

  /// 当前档位值；例如 4。
  final int? gearCurrent;

  /// 是否为连续变速。
  final bool variableSpeedSupported;

  /// 默认值。
  final int defaultValue;

  /// 模式名称列表（用于 mode/multi 变体）。
  final List<String> modes;

  /// 分档控件实际使用的最大档位；后台未配置时兜底 6 档，与设计稿一致。
  int get resolvedGearMax => gearMax ?? 6;

  /// 是否跨满整行（即占 2 列）。
  bool get isFullWidth => cols >= 2;

  /// 返回仅替换当前档位的副本，用于把设备上报的实时档位注入分档控件。
  FreeControlComponentConfig withGearCurrent(int? value) =>
      FreeControlComponentConfig(
        type: type,
        variant: variant,
        rows: rows,
        cols: cols,
        row: row,
        col: col,
        order: order,
        label: label,
        gearMax: gearMax,
        gearMin: gearMin,
        gearCurrent: value,
        variableSpeedSupported: variableSpeedSupported,
        defaultValue: defaultValue,
        modes: modes,
      );

  /// 预设尺寸对应的参考高度（单位逻辑像素，基于设计稿比例）。
  /// 单行单列（1x1）：105
  /// 三行单列（3x1）：312
  /// 单行双列（1x2）：135
  /// 双行双列（2x2）：231
  double get estimatedHeight {
    if (variant.contains('3x1')) return 312;
    if (variant.contains('1x2')) return 135;
    if (variant.contains('2x2')) return 231;
    if (variant.contains('1x1')) return 105;
    if (rows >= 3) return 312;
    if (rows == 2) return 231;
    return cols >= 2 ? 135 : 105;
  }

  /// 组件类型对应的展示标签（优先显示后台配置的 label，为空则回退本地默认名）。
  String get displayLabel {
    if (label != null && label!.trim().isNotEmpty) {
      return label!.trim();
    }
    return switch (type) {
      FreeControlComponentType.telescopic => 'Telescopic',
      FreeControlComponentType.vibration => 'Vibration',
      FreeControlComponentType.suck => 'Suck',
      FreeControlComponentType.heat => 'Heat',
      FreeControlComponentType.mode => 'Mode',
      FreeControlComponentType.oneClickClimax => 'One click climax',
    };
  }

  /// 从后台 json 解析；[capability] 为同类型的能力动作，用于补齐模块未下发的
  /// `gearMax` / `modes`。
  static FreeControlComponentConfig? fromJson(
    Map<String, dynamic> json, {
    Map<String, dynamic>? capability,
  }) {
    final typeStr = json['type'] as String?;
    final type = FreeControlComponentType.fromString(typeStr);
    if (type == null) return null;

    final variant = json['variant'] as String? ?? '';
    final row = _intOf(json['row']) ?? 0;
    final col = _intOf(json['col']) ?? 0;
    final order = _intOf(json['order']) ?? 0;

    // 解析 rows 和 cols（优先使用后端显式返回的 rows/cols，其次从 variant 解析，如 "xxx_3x1" -> rows=3, cols=1）
    var rows = _intOf(json['rows']) ?? 1;
    var cols = _intOf(json['cols']) ?? 1;
    if (json['rows'] == null || json['cols'] == null) {
      final sizeMatch = RegExp(r'(\d+)x(\d+)$').firstMatch(variant);
      if (sizeMatch != null) {
        rows = int.tryParse(sizeMatch.group(1)!) ?? rows;
        cols = int.tryParse(sizeMatch.group(2)!) ?? cols;
      } else {
        // 兼容历史 span
        final span = json['span'] as int?;
        if (span != null && span >= 2) {
          cols = 2;
        }
      }
    }

    final isVariable = variant.contains('variable');
    // 能力配置中 gearMax <= 0 表示不适用（如加热），不能作为档位数使用。
    final capabilityGearMax = _intOf(capability?['gearMax']);
    final gearMax =
        _intOf(json['gearMax']) ??
        (capabilityGearMax != null && capabilityGearMax > 0
            ? capabilityGearMax
            : null) ??
        (variant.contains('mode') ? 6 : null);
    final gearMin = _intOf(json['gearMin']) ?? 1;
    // 不从能力配置补 defaultValue：能力侧是 0–100 逻辑值，模块侧是档位序号，语义不同。
    final defaultValue =
        _intOf(json['defaultValue']) ?? (gearMin > 0 ? gearMin : 1);
    final gearCurrent = _intOf(json['gearCurrent']) ?? defaultValue;
    final moduleModes = _modeNames(json['modes']);

    return FreeControlComponentConfig(
      type: type,
      variant: variant,
      rows: rows,
      cols: cols,
      row: row,
      col: col,
      order: order,
      label: json['label'] as String?,
      gearMax: gearMax,
      gearMin: gearMin,
      gearCurrent: gearCurrent,
      variableSpeedSupported:
          isVariable || (json['variableSpeedSupported'] as bool? ?? false),
      defaultValue: defaultValue,
      // 模式顺序即协议模式号（下标 + 1），因此只整体替换，不与能力列表混合。
      modes: moduleModes.isNotEmpty
          ? moduleModes
          : _modeNames(capability?['modes']),
    );
  }

  /// 兼容 int / double / 数字字符串的整数解析；无法解析时返回 `null`。
  static int? _intOf(Object? value) => switch (value) {
    final num number => number.toInt(),
    final String text => int.tryParse(text.trim()),
    _ => null,
  };

  /// 解析模式名称列表：模块下发字符串数组，能力配置下发 `{id, name}` 对象数组。
  static List<String> _modeNames(Object? raw) {
    if (raw is! List) return const [];
    final names = <String>[];
    for (var i = 0; i < raw.length; i++) {
      final item = raw[i];
      final name = item is Map ? item['name']?.toString() : item?.toString();
      // 缺名模式仍占用模式号位置，用序号兜底以保持下标与协议模式号对齐。
      names.add(name == null || name.trim().isEmpty ? 'Mode ${i + 1}' : name);
    }
    return List.unmodifiable(names);
  }
}
