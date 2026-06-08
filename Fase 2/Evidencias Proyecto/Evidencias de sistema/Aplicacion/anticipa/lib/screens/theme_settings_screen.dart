import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../theme/app_theme.dart';
import '../services/theme_service.dart';

class ThemeSettingsScreen extends StatefulWidget {
  final ThemeConfig currentConfig;

  const ThemeSettingsScreen({super.key, required this.currentConfig});

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  late ThemeConfig _config;
  bool _isCustomizing = false;

  @override
  void initState() {
    super.initState();
    _config = widget.currentConfig;
  }

  Future<void> _selectPredefinedTheme(PredefinedTheme tema) async {
    setState(() {
      _config = ThemeConfig(temaId: tema.id, colors: tema.colors, usandoTemaPredefinido: true);
      _isCustomizing = false;
    });
    await ThemeService.saveTheme(_config);
  }

  Future<void> _openColorPicker(String elementName, Color currentColor, Function(Color) onColorChanged) async {
    Color pickedColor = currentColor;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Color de $elementName'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: pickedColor,
            onColorChanged: (c) => pickedColor = c,
            enableAlpha: false,
            hexInputBar: true,
            labelTypes: const [],
            pickerAreaHeightPercent: 0.7,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              onColorChanged(pickedColor);
              Navigator.pop(ctx);
            },
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }

  Future<void> _applyCustomColor(String element, Color color) async {
    ThemeColors newColors;
    switch (element) {
      case 'background':
        newColors = _config.colors.copyWith(background: color);
        break;
      case 'appBar':
        newColors = _config.colors.copyWith(appBar: color);
        break;
      case 'card':
        newColors = _config.colors.copyWith(card: color);
        break;
      case 'primary':
        newColors = _config.colors.copyWith(primary: color);
        break;
      case 'textPrimary':
        newColors = _config.colors.copyWith(textPrimary: color);
        break;
      case 'textSecondary':
        newColors = _config.colors.copyWith(textSecondary: color);
        break;
      default:
        return;
    }
    setState(() {
      _config = ThemeConfig(temaId: -1, colors: newColors, usandoTemaPredefinido: false);
    });
    await ThemeService.saveTheme(_config);
  }

  Future<void> _resetToDefault() async {
    await ThemeService.resetTheme();
    setState(() {
      _config = ThemeConfig.defaultTheme();
      _isCustomizing = false;
    });
  }

  Widget _colorOption(String label, Color color, String element) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade400),
        ),
      ),
      title: Text(label),
      subtitle: Text('#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}'),
      trailing: const Icon(Icons.edit, size: 20),
      onTap: () => _openColorPicker(label, color, (c) => _applyCustomColor(element, c)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personalizar colores'),
        backgroundColor: _config.colors.appBar,
      ),
      backgroundColor: _config.colors.background,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Temas predefinidos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.9,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: predefinedThemes.length,
            itemBuilder: (ctx, i) {
              final tema = predefinedThemes[i];
              final isSelected = _config.usandoTemaPredefinido && _config.temaId == tema.id;
              return GestureDetector(
                onTap: () => _selectPredefinedTheme(tema),
                child: Container(
                  decoration: BoxDecoration(
                    color: tema.colors.background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? tema.colors.primary : Colors.grey.shade300,
                      width: isSelected ? 3 : 1,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: tema.colors.primary.withValues(alpha: 0.4), blurRadius: 8, spreadRadius: 1)]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(tema.emoji, style: const TextStyle(fontSize: 28)),
                      const SizedBox(height: 6),
                      Text(tema.name, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: tema.colors.textPrimary)),
                      const SizedBox(height: 4),
                      Container(
                        width: 28,
                        height: 4,
                        decoration: BoxDecoration(color: tema.colors.primary, borderRadius: BorderRadius.circular(2)),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _isCustomizing = !_isCustomizing),
                  icon: Icon(_isCustomizing ? Icons.check : Icons.palette),
                  label: Text(_isCustomizing ? 'Guardar personalización' : 'Personalizar colores'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _config.colors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: _resetToDefault,
                icon: const Icon(Icons.restore),
                tooltip: 'Restablecer tema por defecto',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
          if (_isCustomizing || !_config.usandoTemaPredefinido) ...[
            const SizedBox(height: 24),
            const Text('Colores personalizados', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Toca cada color para cambiarlo', style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 12),
            Card(
              color: _config.colors.card,
              child: Column(children: [
                _colorOption('Fondo de pantalla', _config.colors.background, 'background'),
                const Divider(height: 1),
                _colorOption('Barra superior', _config.colors.appBar, 'appBar'),
                const Divider(height: 1),
                _colorOption('Tarjetas', _config.colors.card, 'card'),
                const Divider(height: 1),
                _colorOption('Botones principales', _config.colors.primary, 'primary'),
                const Divider(height: 1),
                _colorOption('Texto principal', _config.colors.textPrimary, 'textPrimary'),
                const Divider(height: 1),
                _colorOption('Texto secundario', _config.colors.textSecondary, 'textSecondary'),
              ]),
            ),
          ],
          const SizedBox(height: 24),
          const Text('Vista previa', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildPreview(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    return Container(
      decoration: BoxDecoration(
        color: _config.colors.appBar,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(width: 36, height: 36, decoration: BoxDecoration(color: _config.colors.primary, borderRadius: BorderRadius.circular(8))),
            const SizedBox(width: 12),
            Text('Nombre estudiante', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _config.colors.card,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              Container(width: 48, height: 48, decoration: BoxDecoration(color: _config.colors.primary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12))),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Actividad de ejemplo', style: TextStyle(color: _config.colors.textPrimary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('09:00 - 09:05', style: TextStyle(color: _config.colors.textSecondary, fontSize: 13)),
                ],
              )),
              ElevatedButton(
                onPressed: null,
                style: ElevatedButton.styleFrom(backgroundColor: _config.colors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                child: const Text('Completar'),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('⭐ 5 estrellas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ]),
        ],
      ),
    );
  }
}

extension ColorExtension on Color {
  Color copyWith({double? red, double? green, double? blue, double? alpha}) {
    return Color.fromARGB(
      (alpha ?? this.a).round(),
      (red ?? this.r * 255).round(),
      (green ?? this.g * 255).round(),
      (blue ?? this.b * 255).round(),
    );
  }
}

extension ThemeColorsCopyWith on ThemeColors {
  ThemeColors copyWith({
    Color? background,
    Color? appBar,
    Color? card,
    Color? primary,
    Color? textPrimary,
    Color? textSecondary,
  }) {
    return ThemeColors(
      background: background ?? this.background,
      appBar: appBar ?? this.appBar,
      card: card ?? this.card,
      primary: primary ?? this.primary,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
    );
  }
}