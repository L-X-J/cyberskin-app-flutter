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

  /// 从后端 DeviceModelDetail 返回的 Map 结构以及设备名称进行解析构造。
  factory FreeControlLayout.fromJson({
    required String deviceName,
    Map<String, dynamic>? layoutJson,
    Map<String, dynamic>? capabilityJson,
  }) {
    final rawColumns = layoutJson?['columns'];
    final columns = (rawColumns is int && rawColumns > 0) ? rawColumns : 2;
    final rawModules = layoutJson?['modules'];

    final List<FreeControlComponentConfig> components = [];

    if (rawModules is List && rawModules.isNotEmpty) {
      // 按 order 或 row/col 排序
      final sortedModules = List<Map<String, dynamic>>.from(
        rawModules.whereType<Map<String, dynamic>>(),
      )..sort((a, b) {
          final orderA = a['order'] as int? ?? 0;
          final orderB = b['order'] as int? ?? 0;
          if (orderA != orderB) return orderA.compareTo(orderB);
          final rowA = a['row'] as int? ?? 0;
          final rowB = b['row'] as int? ?? 0;
          if (rowA != rowB) return rowA.compareTo(rowB);
          final colA = a['col'] as int? ?? 0;
          final colB = b['col'] as int? ?? 0;
          return colA.compareTo(colB);
        });

      for (final mod in sortedModules) {
        final config = FreeControlComponentConfig.fromJson(mod);
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
  /// Heat(1x1), Suck(1x1), Telescopic(垂直 3x1), Vibration(垂直 3x1), OneClickClimax(2x2)
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
      'oneclickclimax' || 'one_click_climax' || 'climax' =>
        FreeControlComponentType.oneClickClimax,
      _ => null,
    };
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
    this.gearCurrent,
    this.variableSpeedSupported = false,
    this.defaultValue = 0,
    List<String> modes = const <String>[],
  }) : modes = modes;

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

  /// 当前档位值；例如 4。
  final int? gearCurrent;

  /// 是否为连续变速。
  final bool variableSpeedSupported;

  /// 默认值 0–100。
  final int defaultValue;

  /// 模式名称列表（用于 mode/multi 变体）。
  final List<String> modes;

  /// 是否跨满整行（即占 2 列）。
  bool get isFullWidth => cols >= 2;

  /// 组件类型对应的默认展示标签。
  String get displayLabel => label ?? switch (type) {
    FreeControlComponentType.telescopic => 'Telescopic',
    FreeControlComponentType.vibration => 'Vibration',
    FreeControlComponentType.suck => 'Suck',
    FreeControlComponentType.heat => 'Heat',
    FreeControlComponentType.mode => 'Mode',
    FreeControlComponentType.oneClickClimax => 'One click climax',
  };

  /// 从后台 json 解析。
  static FreeControlComponentConfig? fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String?;
    final type = FreeControlComponentType.fromString(typeStr);
    if (type == null) return null;

    final variant = json['variant'] as String? ?? '';
    final row = json['row'] as int? ?? 0;
    final col = json['col'] as int? ?? 0;
    final order = json['order'] as int? ?? 0;

    // 解析 rows 和 cols（从 variant 解析，如 "xxx_3x1" -> rows=3, cols=1）
    var rows = 1;
    var cols = 1;
    final sizeMatch = RegExp(r'(\d+)x(\d+)$').firstMatch(variant);
    if (sizeMatch != null) {
      rows = int.tryParse(sizeMatch.group(1)!) ?? 1;
      cols = int.tryParse(sizeMatch.group(2)!) ?? 1;
    } else {
      // 兼容历史 span
      final span = json['span'] as int?;
      if (span != null && span >= 2) {
        cols = 2;
      }
    }

    final isVariable = variant.contains('variable');
    final gearMax = json['gearMax'] as int? ?? (variant.contains('mode') ? 6 : null);

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
      variableSpeedSupported: isVariable || (json['variableSpeedSupported'] as bool? ?? false),
      defaultValue: json['defaultValue'] as int? ?? 0,
      modes: (json['modes'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }
}
