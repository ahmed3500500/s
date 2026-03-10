import '../local_storage_service.dart';
import '../models.dart';

class SettingsRepository {
  final LocalStorageService _storage;

  SettingsRepository(this._storage);

  UserSettingsModel load() => _storage.loadSettings();

  Future<void> save(UserSettingsModel settings) => _storage.saveSettings(settings);
}

