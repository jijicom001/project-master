import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'dart:math' as math;

final Logger logger = Logger();

class MelancholyWidget extends StatefulWidget {
  final String userId;
  const MelancholyWidget({super.key, required this.userId});

  @override
  State<MelancholyWidget> createState() => _MelancholyWidgetState();
}

class _MelancholyWidgetState extends State<MelancholyWidget> {
  final List<String> questions = [
    '我能開懷的笑並看到事物有趣的一面',
    '我能夠以快樂的心情來期待事情',
    '當事情不順利時，我會不必要的責備自己',
    '我會無緣無故感到焦慮和擔心',
    '我會無緣無故感到害怕和驚慌',
    '事情壓得我喘不過氣',
    '我很不開心以致失眠',
    '我感到悲傷和難過',
    '我的不快樂導致我哭泣',
    '我會有傷害自己的想法',
  ];

  final Map<int, List<String>> questionOptions = {
    0: ["同以前一樣", "沒有以前那麼多", "肯定比以前少", "完全不能"],
    1: ["同以前一樣", "沒有以前那麼多", "肯定比以前少", "完全不能"],
    2: ["相當多時候這樣", "有時候這樣", "很少這樣", "沒有這樣"],
    3: ["相當多時候這樣", "有時候這樣", "很少這樣", "沒有這樣"],
    4: ["相當多時候這樣", "有時候這樣", "很少這樣", "沒有這樣"],
    5: ["大多數時候我都不能應付", "有時候我不能像平常時那樣應付得好", "大部分時候我都能像平時那樣應付得好", "我一直都能應付得好"],
    6: ["相當多時候這樣", "有時候這樣", "很少這樣", "沒有這樣"],
    7: ["相當多時候這樣", "有時候這樣", "很少這樣", "沒有這樣"],
    8: ["相當多時候這樣", "有時候這樣", "很少這樣", "沒有這樣"],
    9: ["相當多時候這樣", "有時候這樣", "很少這樣", "沒有這樣"],
  };

  final Map<int, String?> answers = {}; // 存使用者選擇的答案

  bool _isAllQuestionsAnswered() {
    return answers.length == questions.length && !answers.containsValue(null);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final double fontSize = screenWidth * 0.045; // 自適應字體大小

    return Scaffold(
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
        decoration: const BoxDecoration(
          color: Color.fromRGBO(233, 227, 213, 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: screenHeight * 0.02),
            Text(
              '產後憂鬱量表',
              style: TextStyle(
                fontSize: fontSize * 1.2,
                fontWeight: FontWeight.bold,
                color: const Color.fromRGBO(147, 129, 108, 1),
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            Expanded(
              child: ListView.builder(
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  return _buildQuestionRow(index, screenWidth, fontSize);
                },
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Transform.rotate(
                    angle: math.pi,
                    child: Image.asset(
                      'assets/images/back.png',
                      width: screenWidth * 0.12,
                    ),
                  ),
                ),
                if (_isAllQuestionsAnswered())
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.08,
                          vertical: screenHeight * 0.015),
                      backgroundColor: Colors.brown.shade400,
                    ),
                    onPressed: () async {
                      await _saveAnswersToFirebase();
                      if (!context.mounted) return;
                      Navigator.pushNamed(
                        context,
                        '/FinishWidget',
                        arguments: widget.userId,
                      );
                    },
                    child: Text(
                      "下一步",
                      style: TextStyle(
                        fontSize: fontSize,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: screenHeight * 0.02),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionRow(
      int questionIndex, double screenWidth, double fontSize) {
    List<String> options =
        questionOptions[questionIndex] ?? ["可以", "還行", "不行", "沒辦法"];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${questionIndex + 1}. ${questions[questionIndex]}',
          style: TextStyle(
            fontSize: fontSize,
            color: const Color.fromRGBO(147, 129, 108, 1),
          ),
        ),
        SizedBox(height: screenWidth * 0.02),
        Column(
          children: options.map((option) {
            return Row(
              children: [
                Radio<String>(
                  value: option,
                  groupValue: answers[questionIndex],
                  onChanged: (value) {
                    setState(() {
                      answers[questionIndex] = value!;
                    });
                  },
                ),
                Expanded(
                  child: Text(
                    option,
                    style: TextStyle(
                      fontSize: fontSize,
                      color: const Color.fromRGBO(147, 129, 108, 1),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
        Divider(color: Colors.grey, thickness: 1),
      ],
    );
  }

  Future<void> _saveAnswersToFirebase() async {
    try {
      final Map<String, String?> formattedAnswers = answers.map(
        (key, value) => MapEntry(key.toString(), value),
      );

      final CollectionReference userResponses = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection("questions");

      await userResponses.doc('melancholy').set({
        'answers': formattedAnswers,
        'timestamp': FieldValue.serverTimestamp(),
      });

      logger.i("✅ 憂鬱量表問卷已成功儲存！");
    } catch (e) {
      logger.e("❌ 儲存憂鬱量表問卷時發生錯誤：$e");
    }
  }
}
