import 'dart:convert';
import 'package:tractian_mobile_challenge/models/company.dart';
import 'package:http/http.dart' as http;

class MenuViewmodel {
  List<Company> _companies = [];

  List<Company> get companies => _companies;

  Future<void> fetchCompanies() async {
    final response = await http.get(Uri.parse('https://fake-api.tractian.com/companies'));

    if (response.statusCode == 200) {
      _companies = (json.decode(response.body) as List).map((json) => Company.fromJson(json)).toList();
    }
  }
}
