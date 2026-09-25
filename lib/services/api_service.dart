import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../models/coin.dart';
import '../models/news_article.dart';
import '../models/education_topic.dart';
import '../models/trade_of_day.dart';
import '../models/chart_analysis.dart';
import '../models/analysis_notification.dart';

class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://0.0.0.0:8000',
  );
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiService {
  final String baseUrl;
  String? _authToken;

  ApiService({String? baseUrl}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  void setAuthToken(String? token) {
    _authToken = token;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  dynamic _decode(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }
    String detail = 'Request failed (${response.statusCode})';
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['detail'] != null) {
        detail = body['detail'].toString();
      }
    } catch (_) {}
    throw ApiException(detail, statusCode: response.statusCode);
  }

  // ---------- Auth ----------

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _headers,
      body: jsonEncode({
        'email': email,
        'password': password,
        'full_name': fullName,
      }),
    );
    return _decode(res) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password}),
    );
    return _decode(res) as Map<String, dynamic>;
  }

  // ---------- Market ----------

  Future<List<Coin>> getCoins({int page = 1, int perPage = 50}) async {
    final res = await http.get(
      Uri.parse('$baseUrl/market/coins?page=$page&per_page=$perPage'),
      headers: _headers,
    );
    final data = _decode(res) as List;
    return data.map((e) => Coin.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<CoinDetail> getCoinDetail(String coinId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/market/coins/$coinId'),
      headers: _headers,
    );
    return CoinDetail.fromJson(_decode(res) as Map<String, dynamic>);
  }

  Future<List<dynamic>> searchCoins(String query) async {
    final res = await http.get(
      Uri.parse('$baseUrl/market/search?query=${Uri.encodeQueryComponent(query)}'),
      headers: _headers,
    );
    return _decode(res) as List<dynamic>;
  }

  /// Total market cap, 24h change, and BTC/ETH dominance. Free CoinGecko
  /// data via the backend - does not call Gemini.
  Future<GlobalMarketData> getGlobalMarketData() async {
    final res = await http.get(Uri.parse('$baseUrl/market/global'), headers: _headers);
    return GlobalMarketData.fromJson(_decode(res) as Map<String, dynamic>);
  }

  // ---------- News ----------

  Future<List<NewsArticle>> getNews({String? category}) async {
    final uri = Uri.parse('$baseUrl/news').replace(
      queryParameters: category != null ? {'category': category} : null,
    );
    final res = await http.get(uri, headers: _headers);
    final data = _decode(res) as List;
    return data
        .map((e) => NewsArticle.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ---------- Education ----------

  Future<List<EducationTopic>> getEducationTopics() async {
    final res = await http.get(Uri.parse('$baseUrl/education'), headers: _headers);
    final data = _decode(res) as List;
    return data
        .map((e) => EducationTopic.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<EducationTopic> getEducationTopic(String slug) async {
    final res =
        await http.get(Uri.parse('$baseUrl/education/$slug'), headers: _headers);
    return EducationTopic.fromJson(_decode(res) as Map<String, dynamic>);
  }

  // ---------- Analyzer ----------

  Future<Map<String, dynamic>> analyzeChart({
    required File imageFile,
    String? coinHint,
    String? note,
  }) async {
    final uri = Uri.parse('$baseUrl/analyzer/chart');
    final request = http.MultipartRequest('POST', uri);
    if (_authToken != null) {
      request.headers['Authorization'] = 'Bearer $_authToken';
    }
    if (coinHint != null && coinHint.isNotEmpty) {
      request.fields['coin_hint'] = coinHint;
    }
    if (note != null && note.isNotEmpty) {
      request.fields['note'] = note;
    }

    // Explicitly determine content type from the file extension rather than
    // relying on automatic MIME detection, which can fail to recognize
    // HEIC/HEIF (Apple's default photo format) and cause the upload to be
    // rejected by the backend as an unrecognized type.
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        contentType: _mediaTypeForPath(imageFile.path),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _decode(response) as Map<String, dynamic>;
  }

  MediaType _mediaTypeForPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return MediaType('image', 'png');
    if (lower.endsWith('.webp')) return MediaType('image', 'webp');
    if (lower.endsWith('.heic')) return MediaType('image', 'heic');
    if (lower.endsWith('.heif')) return MediaType('image', 'heif');
    return MediaType('image', 'jpeg');
  }

  // ---------- Analysis History & Notifications ----------

  Future<List<ChartAnalysis>> getAnalysisHistory({String scope = 'all'}) async {
    final res = await http.get(
      Uri.parse('$baseUrl/analyzer/history?scope=$scope&limit=200'),
      headers: _headers,
    );
    final data = _decode(res) as List;
    return data.map((e) => ChartAnalysis.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ChartAnalysis> getAnalysis(int id) async {
    final res = await http.get(
      Uri.parse('$baseUrl/analyzer/history/$id'),
      headers: _headers,
    );
    return ChartAnalysis.fromJson(_decode(res) as Map<String, dynamic>);
  }

  String analysisPdfUrl(int id) => '$baseUrl/analyzer/history/$id/pdf';

  Future<List<int>> downloadAnalysisPdfBytes(int id) async {
    final res = await http.get(
      Uri.parse(analysisPdfUrl(id)),
      headers: _authToken != null ? {'Authorization': 'Bearer $_authToken'} : {},
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      _decode(res);
    }
    return res.bodyBytes;
  }

  Future<List<AnalysisNotification>> getAnalysisNotifications() async {
    final res = await http.get(Uri.parse('$baseUrl/analyzer/notifications'), headers: _headers);
    final data = _decode(res) as List;
    return data.map((e) => AnalysisNotification.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<int> getUnreadAnalysisNotificationCount() async {
    final res = await http.get(Uri.parse('$baseUrl/analyzer/notifications/unread-count'), headers: _headers);
    return (_decode(res) as Map<String, dynamic>)['count'] as int;
  }

  Future<void> markAnalysisNotificationsRead() async {
    final res = await http.post(Uri.parse('$baseUrl/analyzer/notifications/read'), headers: _headers);
    _decode(res);
  }

  // ---------- Watchlist ----------

  Future<List<dynamic>> getWatchlist() async {
    final res = await http.get(Uri.parse('$baseUrl/watchlist'), headers: _headers);
    return _decode(res) as List<dynamic>;
  }

  Future<void> addToWatchlist(String coinId, String symbol) async {
    final res = await http.post(
      Uri.parse('$baseUrl/watchlist'),
      headers: _headers,
      body: jsonEncode({'coin_id': coinId, 'symbol': symbol}),
    );
    _decode(res);
  }

  Future<void> removeFromWatchlist(String coinId) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/watchlist/$coinId'),
      headers: _headers,
    );
    _decode(res);
  }

  // ---------- Trade of the Day ----------

  String resolveImageUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    return '$baseUrl$path';
  }

  Future<TradeOfDay?> getLatestTradeOfDay() async {
    final res = await http.get(Uri.parse('$baseUrl/trade-of-day/latest'), headers: _headers);
    if (res.statusCode == 404) return null;
    return TradeOfDay.fromJson(_decode(res) as Map<String, dynamic>);
  }

  Future<List<TradeOfDay>> getTradeOfDayHistory({int limit = 20}) async {
    final res = await http.get(
      Uri.parse('$baseUrl/trade-of-day?limit=$limit'),
      headers: _headers,
    );
    final data = _decode(res) as List;
    return data.map((e) => TradeOfDay.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ---------- AI Chat ----------

  /// Sends a message to the crypto AI chat assistant. Pass the sessionId
  /// returned from a previous call to continue the same conversation;
  /// omit it to start a new one.
  Future<Map<String, dynamic>> sendChatMessage({
    required String message,
    String? sessionId,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/chat'),
      headers: _headers,
      body: jsonEncode({
        'message': message,
        if (sessionId != null) 'session_id': sessionId,
      }),
    );
    return _decode(res) as Map<String, dynamic>;
  }
}
