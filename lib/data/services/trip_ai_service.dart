import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Centralized Trip AI Service using Gemini API
class TripAiService {
  static const String _geminiApiKey = 'AIzaSyBOsbV2denSv5Z9tBvo3JIdn7ua4KeMSQw';

  static const List<String> _endpoints = [
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent',
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent',
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite:generateContent',
  ];

  /// Generate AI response for a given prompt with optional system context
  static Future<String> generateResponse({
    required String prompt,
    String? systemContext,
    double temperature = 0.7,
    int maxOutputTokens = 1024,
  }) async {
    const maxRetries = 2;
    const retryDelays = [Duration(seconds: 1), Duration(seconds: 3)];

    final List<Map<String, dynamic>> contents = [];

    // Add system context if provided
    if (systemContext != null) {
      contents.add({
        'role': 'user',
        'parts': [
          {'text': systemContext},
        ],
      });
      contents.add({
        'role': 'model',
        'parts': [
          {'text': 'Tôi hiểu rồi. Tôi sẽ hỗ trợ theo yêu cầu.'},
        ],
      });
    }

    // Add user prompt
    contents.add({
      'role': 'user',
      'parts': [
        {'text': prompt},
      ],
    });

    for (int retry = 0; retry <= maxRetries; retry++) {
      if (retry > 0) {
        await Future.delayed(retryDelays[retry - 1]);
      }

      for (final endpoint in _endpoints) {
        try {
          final response = await http
              .post(
                Uri.parse('$endpoint?key=$_geminiApiKey'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  'contents': contents,
                  'generationConfig': {
                    'temperature': temperature,
                    'topK': 40,
                    'topP': 0.95,
                    'maxOutputTokens': maxOutputTokens,
                  },
                  'safetySettings': [
                    {
                      'category': 'HARM_CATEGORY_HARASSMENT',
                      'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
                    },
                    {
                      'category': 'HARM_CATEGORY_HATE_SPEECH',
                      'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
                    },
                    {
                      'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
                      'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
                    },
                    {
                      'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
                      'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
                    },
                  ],
                }),
              )
              .timeout(const Duration(seconds: 30));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final candidates = data['candidates'] as List?;
            if (candidates != null && candidates.isNotEmpty) {
              final content = candidates[0]['content'];
              final parts = content['parts'] as List?;
              if (parts != null && parts.isNotEmpty) {
                return parts[0]['text'] ?? 'Không có phản hồi từ AI.';
              }
            }
            return 'Không có phản hồi từ AI.';
          } else if (response.statusCode == 404 || response.statusCode == 429) {
            debugPrint('Gemini $response.statusCode at $endpoint');
            continue;
          } else {
            debugPrint('Gemini error ${response.statusCode}: ${response.body}');
            continue;
          }
        } catch (e) {
          debugPrint('Gemini exception at $endpoint: $e');
          continue;
        }
      }
    }

    return 'Không thể kết nối với AI. Vui lòng thử lại sau.';
  }

  /// Get AI budget suggestion for travel planning
  static Future<String> getBudgetSuggestion({
    required double totalBudget,
    required int days,
    required int people,
    required String tripType,
    String? departure,
    String? destination,
  }) async {
    final budgetFormatted = _formatCurrency(totalBudget);
    final perPersonPerDay = _formatCurrency(totalBudget / people / days);

    final prompt =
        '''
Tôi đang lên kế hoạch du lịch với thông tin sau:
- Tổng ngân sách: $budgetFormatted VNĐ
- Số ngày: $days ngày
- Số người: $people người
- Loại hình: $tripType
- Ngân sách mỗi người/ngày: $perPersonPerDay VNĐ
${departure != null ? '- Điểm đi: $departure' : ''}
${destination != null ? '- Điểm đến: $destination' : ''}

Hãy gợi ý CHI TIẾT cho chuyến đi này. Trả lời có emoji, dễ đọc, THỰC TẾ với giá cả cụ thể:

📊 **PHÂN BỔ NGÂN SÁCH:**
- Chỗ ở: X VNĐ (XX%)
- Ăn uống: X VNĐ (XX%)  
- Di chuyển: X VNĐ (XX%)
- Tham quan/vé: X VNĐ (XX%)
- Chi phí khác: X VNĐ (XX%)

🏨 **CHỖ Ở GỢI Ý:** (phù hợp loại hình $tripType)
- Tên khu vực/loại hình cụ thể
- Mức giá mỗi đêm
- Gợi ý 2-3 tên khách sạn/homestay cụ thể nếu có

🍜 **ĂN UỐNG GỢI Ý:**
- Món đặc sản địa phương nên thử
- Quán ăn/nhà hàng gợi ý với mức giá
- Budget mỗi bữa hợp lý

🚗 **DI CHUYỂN GỢI Ý:**
${departure != null && destination != null ? '- Phương tiện từ $departure đến $destination với giá cả\n- Xe máy/ô tô thuê tại địa phương' : '- Phương tiện di chuyển phù hợp với ngân sách'}
- Di chuyển nội thành

🎯 **ĐIỂM THAM QUAN:**
- Top 3-5 địa điểm nên đến
- Vé/chi phí mỗi điểm

💡 **MẸO TIẾT KIỆM:**
- 3 mẹo cụ thể phù hợp loại hình $tripType
''';

    const systemContext = '''
Bạn là chuyên gia tư vấn du lịch Việt Nam với kiến thức sâu về giá cả năm 2025-2026.

QUY TẮC:
1. LUÔN đưa ra GIÁ CỤ THỂ bằng VNĐ
2. GỢI Ý TÊN cụ thể (khách sạn, quán ăn, địa điểm)
3. Phù hợp với loại hình chuyến đi:
   - Tiết kiệm: homestay 200-400k, quán ăn vỉa hè 30-60k/bữa, xe buýt/grab share
   - Tiêu chuẩn: khách sạn 2-3 sao 500-900k, quán ăn 80-150k/bữa, grab/taxi
   - Cao cấp: resort 4-5 sao 1.5-3 triệu, nhà hàng 200-500k/bữa, xe riêng/máy bay
4. Trả lời bằng tiếng Việt, thực tế, hữu ích
5. Format đẹp, dễ đọc với emoji
''';

    return generateResponse(
      prompt: prompt,
      systemContext: systemContext,
      temperature: 0.8,
      maxOutputTokens: 1200,
    );
  }

  /// Get AI trip itinerary suggestion
  static Future<String> getItinerarySuggestion({
    required String destination,
    required int days,
    required double budget,
    List<String>? interests,
  }) async {
    final budgetFormatted = _formatCurrency(budget);
    final interestsText = interests?.join(', ') ?? 'đa dạng';

    final prompt =
        '''
Gợi ý lịch trình du lịch:
- Điểm đến: $destination
- Số ngày: $days
- Ngân sách: $budgetFormatted VNĐ
- Sở thích: $interestsText

Hãy tạo lịch trình chi tiết theo từng ngày với:
1. 🌅 Hoạt động buổi sáng
2. ☀️ Hoạt động buổi trưa
3. 🌙 Hoạt động buổi tối
4. 🍜 Gợi ý ăn uống
5. 💰 Chi phí ước tính mỗi ngày
''';

    return generateResponse(
      prompt: prompt,
      temperature: 0.8,
      maxOutputTokens: 1000,
    );
  }

  /// Get structured budget calculation from AI (returns budget + suggestion text)
  static Future<Map<String, dynamic>> getBudgetCalculation({
    required double totalBudget,
    required int days,
    required int people,
    required String tripType,
    String? departure,
    String? destination,
  }) async {
    final budgetFormatted = _formatCurrency(totalBudget);

    // Calculate budget breakdown based on trip type (fixed percentages)
    Map<String, double> pct;
    if (tripType == 'Tiết kiệm') {
      pct = {
        'Chỗ ở': 0.35,
        'Ăn uống': 0.30,
        'Di chuyển': 0.20,
        'Chi phí khác': 0.15,
      };
    } else if (tripType == 'Cao cấp') {
      pct = {
        'Chỗ ở': 0.45,
        'Ăn uống': 0.30,
        'Di chuyển': 0.15,
        'Chi phí khác': 0.10,
      };
    } else {
      pct = {
        'Chỗ ở': 0.40,
        'Ăn uống': 0.30,
        'Di chuyển': 0.20,
        'Chi phí khác': 0.10,
      };
    }

    final Map<String, double> budget = {};
    pct.forEach((k, v) {
      budget[k] = double.parse((totalBudget * v).toStringAsFixed(0));
    });

    // Get AI suggestion for travel tips (no JSON required)
    final prompt =
        '''
Tôi đang lên kế hoạch du lịch ${destination ?? 'Việt Nam'} với thông tin:
- Ngân sách: $budgetFormatted VNĐ
- Số ngày: $days ngày  
- Số người: $people người
- Loại hình: $tripType
${departure != null && departure.isNotEmpty ? '- Điểm đi: $departure' : ''}

Gợi ý CHI TIẾT bằng tiếng Việt với emoji:

🏨 **CHỖ Ở GỢI Ý:**
- Khu vực nên ở
- 2-3 tên khách sạn/homestay cụ thể với giá

🍜 **ĂN UỐNG:**  
- Món đặc sản nên thử
- 2-3 quán ăn gợi ý với giá

🚗 **DI CHUYỂN:**
- Phương tiện phù hợp với giá cụ thể

🎯 **ĐIỂM THAM QUAN:**
- Top 3-5 địa điểm nên đến

💡 **MẸO TIẾT KIỆM:**
- 2-3 mẹo cụ thể
''';

    const systemContext = '''
Bạn là chuyên gia du lịch Việt Nam 2025-2026.
QUY TẮC:
1. LUÔN đưa giá CỤ THỂ bằng VNĐ
2. Gợi ý TÊN cụ thể (khách sạn, quán ăn)
3. Phù hợp loại hình: Tiết kiệm (200-400k/đêm), Tiêu chuẩn (500-900k), Cao cấp (1.5-3tr)
4. Trả lời ngắn gọn, thực tế, dễ đọc
5. KHÔNG trả về JSON hay code block, chỉ text thuần với emoji
''';

    final suggestion = await generateResponse(
      prompt: prompt,
      systemContext: systemContext,
      temperature: 0.8,
      maxOutputTokens: 1000,
    );

    return {
      'budget': budget,
      'suggestion': suggestion,
      'total': totalBudget,
      'days': days,
      'people': people,
      'perPersonPerDay': double.parse(
        (totalBudget / people / days).toStringAsFixed(0),
      ),
    };
  }

  static String _formatCurrency(double value) {
    return value
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.');
  }
}
