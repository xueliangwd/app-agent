import 'package:flutter/foundation.dart';

import '../../../core/models/ai_provider.dart';
import '../../../core/models/provider_settings.dart';
import '../../../services/app_settings_repository.dart';

class SettingsController extends ChangeNotifier {
  SettingsController({AppSettingsRepository? repository})
      : _repository = repository ?? const AppSettingsRepository();

  final AppSettingsRepository _repository;
  Map<AiPlatform, ProviderSettings> _providerSettings = {};
  AiModelOption? _selectedModel;

  Map<AiPlatform, ProviderSettings> get providerSettings => _providerSettings;
  AiModelOption? get selectedModel => _selectedModel;

  List<AiModelOption> get availableModels {
    return _providerSettings.values
        .expand(
          (settings) => settings.models.map(
            (id) => AiModelOption(
              platform: settings.platform,
              id: id,
              label: id,
              isConfigured:
                  settings.platform == AiPlatform.system ? true : settings.isConfigured,
            ),
          ),
        )
        .toList(growable: false);
  }

  Future<void> bootstrap() async {
    _providerSettings = await _repository.loadProviderSettings();
    final (platform, modelId) = await _repository.loadSelectedModel();
    _selectedModel = availableModels.firstWhereOrNull(
          (item) => item.platform == platform && item.id == modelId,
        ) ??
        availableModels.firstWhereOrNull((item) => item.isConfigured) ??
        availableModels.firstOrNull;
    notifyListeners();
  }

  ProviderSettings settingsFor(AiPlatform platform) => _providerSettings[platform]!;

  Future<void> updateProviderSettings(ProviderSettings settings) async {
    _providerSettings = {
      ..._providerSettings,
      settings.platform: settings,
    };
    await _repository.saveProviderSettings(settings);
    final updatedModels = availableModels;
    if (_selectedModel != null &&
        !updatedModels.any(
          (item) => item.platform == _selectedModel!.platform && item.id == _selectedModel!.id,
        )) {
      _selectedModel = updatedModels.firstWhereOrNull((item) => item.isConfigured) ??
          updatedModels.firstOrNull;
      await _repository.saveSelectedModel(_selectedModel);
    }
    notifyListeners();
  }

  Future<void> selectModel(AiModelOption model) async {
    _selectedModel = model;
    await _repository.saveSelectedModel(model);
    notifyListeners();
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;

  T? firstWhereOrNull(bool Function(T element) test) {
    for (final element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }
}
