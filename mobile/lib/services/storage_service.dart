import "package:shared_preferences/shared_preferences.dart";

import "../utils/constants.dart";

class StorageService {
  Future<void> saveApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.apiKeyStorageKey, apiKey);
  }

  Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.apiKeyStorageKey);
  }

  Future<void> clearApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.apiKeyStorageKey);
  }
}
