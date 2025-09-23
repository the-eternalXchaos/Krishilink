// import 'package:krishi_link/src/core/networking/api_service.dart';
// class AiApiService extends ApiService {



  
//   // --- AI CHAT LOGIC ---
//   Future<String> chatWithAI(String message) async {
//     try {
//       final response = await _dio.post(
//         ApiConstants.chatWithAiEndpoint,
//         data: jsonEncode(message),
//         options: Options(headers: {'Content-Type': 'application/json'}),
//       );
//       return response.data.toString();
//     } on DioException catch (e) {
//       throw _parseDioError(e);
//     }
//   }

//   Future<List<dynamic>> getAiChats() async {
//     try {
//       final res = await _dio.get(ApiConstants.getAiChatsEndpoint);
//       final data = res.data;
//       if (data is List) return data;
//       if (data is Map && data['data'] is List)
//         return List<dynamic>.from(data['data']);
//       return const [];
//     } on DioException catch (e) {
//       throw _parseDioError(e);
//     }
//   }

//   Future<List<dynamic>> getAiChatMessages(String aiChatId) async {






//     try {
//       final res = await _dio.get(
//         '${ApiConstants.getAiChatMessagesEndpoint}/$aiChatId',
//       );
//       final data = res.data;
//       if (data is List) return data;
//       if (data is Map && data['data'] is List)
//         return List<dynamic>.from(data['data']);
//       return const [];
//     } on DioException catch (e) {
//       throw _parseDioError(e);
//     }
//   }

//   Future<bool> deleteAiChat(String aiChatId) async {
//     try {
//       final res = await _dio.delete(
//         '${ApiConstants.deleteAiChatEndpoint}/$aiChatId',
//       );
//       return res.statusCode == 200;
//     } on DioException catch (e) {
//       throw _parseDioError(e);
//     }
//   }
// }
