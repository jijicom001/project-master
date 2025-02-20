import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ollama PDF 查詢系統',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const QueryPage(),
    );
  }
}

class QueryPage extends StatefulWidget {
  const QueryPage({super.key});

  @override
  _QueryPageState createState() => _QueryPageState();
}

class _QueryPageState extends State<QueryPage> {
  final TextEditingController _controller = TextEditingController();
  final Dio _dio = Dio();
  String _responseText = "";
  bool _isLoading = false;

  Future<void> _sendQuery() async {
    final String query = _controller.text.trim();
    if (query.isEmpty) {
      setState(() {
        _responseText = "請輸入問題。";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _responseText = "回答：\n";
    });

    try {
      print("發送請求到伺服器: $query");

      final response = await _dio.post(
        "http://180.176.211.159:8000/query",
        data: {"query": query},
        options: Options(
          responseType: ResponseType.stream,
          contentType: Headers.jsonContentType,
        ),
      );

      print("伺服器回應: ${response.statusCode}");

      final Stream<List<int>>? stream = response.data?.stream;
      if (stream != null) {
        stream.listen(
          (data) {
            setState(() {
              _responseText += utf8.decode(data, allowMalformed: true);
            });
          },
          onDone: () {
            setState(() {
              _isLoading = false;
            });
          },
          onError: (error) {
            setState(() {
              _isLoading = false;
              _responseText = "發生錯誤：$error";
            });
          },
        );
      }
    } catch (e) {
      print("請求錯誤: $e"); // 紀錄錯誤
      setState(() {
        _isLoading = false;
        _responseText = "無法連接到伺服器。";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("PDF 問答系統")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: "輸入問題...",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isLoading ? null : _sendQuery,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("查詢", style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _responseText,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
