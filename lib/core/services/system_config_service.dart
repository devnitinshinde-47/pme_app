import 'dart:convert';
import 'package:http/http.dart' as http;
import '../network/api_constants.dart';
import '../models/system_config_model.dart';

class SystemConfigService {
  Future<SystemConfigModel?> fetchSystemConfig() async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/api/system-config');
      final response = await http.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return SystemConfigModel.fromJson(data);
      }
    } catch (_) {}
    return null;
  }
}
