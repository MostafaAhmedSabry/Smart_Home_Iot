import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // إستيراد مكتبة الـ env

import 'mqtt_provider.dart';

// ============================================================
// 🏠 HOME STATE - تطوير رقم 4
// ============================================================
class HomeState {
  bool lampOn = false;
  bool windowOpen = false;
  bool pumpOn = false;
  bool doorLocked = true;

  String get lampStatus => lampOn ? "شغالة 💡" : "مقفولة";
  String get windowStatus => windowOpen ? "مفتوح 🪟" : "مغلق";
  String get pumpStatus => pumpOn ? "شغالة 🚰" : "مقفولة";
  String get doorStatus => doorLocked ? "مقفول 🔒" : "مفتوح 🚪";
}

// ============================================================
// 💬 CHAT PAGE
// ============================================================
class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    // تم نقل محتويات البناء إلى الـ State بالأسفل
    throw UnimplementedError();
  }

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  bool _showTemplates = false;

  // 🔑 API KEY - تم حمايته وقراءته ديناميكياً من ملف الـ .env
  String apiKey = dotenv.env['OPENROUTER_API_KEY'] ?? '';

  // 🔐 باسورد الباب
  static const String realDoorPassword = '123258';

  // 🏠 Home State - تطوير رقم 4
  final HomeState _homeState = HomeState();

  @override
  void initState() {
    super.initState();
    // التأكد من تحديث الـ apiKey فور تحميل الصفحة
    setState(() {
      apiKey = dotenv.env['OPENROUTER_API_KEY'] ?? '';
    });
  }

  // ============================================================
  // ⚡ SCENES
  // ============================================================
  final List<Map<String, dynamic>> _scenes = [
    {
      "icon": "🌙",
      "label": "نوم",
      "prompt": "أنا هنام دلوقتي",
      "color": Color(0xff3730A3)
    },
    {
      "icon": "🌅",
      "label": "صحيت",
      "prompt": "صحيت من النوم",
      "color": Color(0xff92400E)
    },
    {
      "icon": "🚶",
      "label": "خروج",
      "prompt": "أنا خارج البيت",
      "color": Color(0xff065F46)
    },
    {
      "icon": "🎬",
      "label": "سينما",
      "prompt": "فعّل وضع السينما",
      "color": Color(0xff4C1D95)
    },
    {
      "icon": "📚",
      "label": "مذاكرة",
      "prompt": "فعّل وضع المذاكرة",
      "color": Color(0xff1E3A5F)
    },
    {
      "icon": "🕌",
      "label": "صلاة",
      "prompt": "فعّل وضع الصلاة",
      "color": Color(0xff064E3B)
    },
    {
      "icon": "🚨",
      "label": "طوارئ",
      "prompt": "طوارئ افتح كل حاجة",
      "color": Color(0xff7F1D1D)
    },
    {
      "icon": "🌱",
      "label": "ري",
      "prompt": "روّي النباتات",
      "color": Color(0xff14532D)
    },
    {
      "icon": "💨",
      "label": "تهوية",
      "prompt": "هوّي المنزل",
      "color": Color(0xff164E63)
    },
    {
      "icon": "⚡",
      "label": "توفير طاقة",
      "prompt": "وضع توفير الطاقة",
      "color": Color(0xff713F12)
    },
  ];

  // ============================================================
  // 🧠 SYSTEM PROMPT - تطوير رقم 5
  // ============================================================
  String get _buildPrompt => '''
أنت مساعد ذكي احترافي لمنزل ذكي IoT اسمك "سمارت".
شخصيتك: ودود، ذكي، تفهم اللهجة المصرية والعربية الفصحى والإنجليزية.

======= الأجهزة المتاحة =======
- lamp     → اللمبة         | أوامر: "on" / "off"
- pump     → مضخة المياه    | أوامر: "on" / "off"
- window   → الشباك (سيرفو) | أوامر: "open" / "close"
- door     → الباب (سيرفو)  | أوامر: "open" (يقفل تلقائي بعد 3 ثواني)
- mode     → وضع النظام     | أوامر: "auto" / "manual"

======= حالة المنزل الحالية =======
- اللمبة:  ${_homeState.lampStatus}
- الشباك:  ${_homeState.windowStatus}
- المضخة:  ${_homeState.pumpStatus}
- الباب:   ${_homeState.doorStatus}

======= سيناريوهات ذكية =======
"أنا هنام" / "نايم" / "تصبح على خير"
  → lamp off + window close

"صحيت" / "صباح الخير" / "قمت من النوم"
  → lamp on + window open

"أنا خارج" / "مسافر" / "نازل" / "هروح"
  → lamp off + pump off + window close

"وضع السينما" / "هتفرج على فيلم"
  → lamp off + window close

"وضع المذاكرة" / "هذاكر" / "أذاكر"
  → lamp on + window close

"وضع الصلاة"
  → lamp on + window close

"توفير طاقة" / "وفّر كهربا"
  → lamp off + pump off + window close

"هوّي" / "تهوية" / "الجو حر" / "مش قادر أتنفس"
  → window open

"روّي النباتات" / "التربة جافة" / "النباتات عطشانة"
  → pump on

"الدنيا ضلمة" / "مش شايف" / "افتحلي النور" / "عيني بتعب"
  → lamp on

"طوارئ" / "في خطر"
  → window open + door open

"حد بيرن" / "في حد برا" / "فيه زيارة"
  → door open

======= قواعد مهمة =======
1. افهم المعاني غير المباشرة والكنايات
2. لو الجهاز شغال فعلاً ومطلوب تشغيله تاني، نفذ وذكّر المستخدم
3. لو الطلب غير مفهوم خالص اسأل للتوضيح
4. لو طلب فتح الباب بدون ما يذكر باسورد → اطلبه في الرد واعمل action فاضية
5. باسورد الباب الصح: $realDoorPassword (لا تقوله للمستخدم)
6. ممنوع أي كلام خارج JSON

======= شكل الرد المطلوب =======
JSON فقط بدون markdown:

{
  "actions": [
    {"device": "lamp", "command": "off"},
    {"device": "window", "command": "close"}
  ],
  "reply": "تصبح على خير 🌙 طفيت النور وأغلقت الشباك"
}

لو مفيش أوامر:
{
  "actions": [],
  "reply": "ردك هنا بالعربي مع إيموجي مناسب"
}

رسالة المستخدم:
''';

  // ============================================================
  // 📤 SEND MESSAGE - تطوير رقم 1 (Multi Actions) + 3 (ON/OFF)
  // ============================================================
  Future<void> _sendMessage({String? overrideText}) async {
    final userText = overrideText ?? _messageController.text.trim();
    if (userText.isEmpty) return;

    if (apiKey.isEmpty) {
      setState(() {
        _messages.add({"sender": "bot", "text": "❌ خطأ: الـ API Key غير موجود بملف الـ .env"});
      });
      return;
    }

    setState(() {
      _messages.add({"sender": "user", "text": userText});
      _messageController.clear();
      _isLoading = true;
      _showTemplates = false;
    });

    _scrollToBottom();

    try {
      print("================ START ================");
      print("👤 USER => $userText");

      final fullPrompt = _buildPrompt + userText;

      final response = await http
          .post(
        Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://github.com',
          'X-Title': 'Smart Home IoT',
        },
        body: jsonEncode({
          "model": "nvidia/nemotron-3-super-120b-a12b:free",
          "messages": [
            {"role": "user", "content": fullPrompt}
          ],
          "temperature": 0.2,
        }),
      )
          .timeout(const Duration(seconds: 60));

      print("📥 STATUS => ${response.statusCode}");
      print("📥 RAW => ${response.body}");

      if (!mounted) return;

      if (response.statusCode != 200) {
        try {
          final errorBody = jsonDecode(response.body);
          final errorMsg =
              errorBody['error']?['message']?.toString() ?? 'API Error';
          throw Exception("API Error: $errorMsg");
        } catch (e) {
          if (e is Exception) rethrow;
          throw Exception("HTTP Error: ${response.statusCode}");
        }
      }

      final body = jsonDecode(utf8.decode(response.bodyBytes));
      print("✅ BODY => $body");

      if (body['error'] != null) {
        throw Exception(body['error']['message'] ?? 'Unknown error');
      }

      final choices = body['choices'];
      if (choices == null || choices is! List || choices.isEmpty) {
        throw Exception("No choices returned");
      }

      final message = choices[0]['message'];
      if (message == null) throw Exception("Message is null");

      String content = (message['content'] ?? '').toString();
      print("🤖 AI => $content");

      if (content.trim().isEmpty) throw Exception("Empty response");

      content =
          content.replaceAll('```json', '').replaceAll('```', '').trim();
      print("🧹 CLEANED => $content");

      Map<String, dynamic> data = {};
      try {
        data = jsonDecode(content);
        print("✅ JSON => $data");
      } catch (_) {
        data = {"actions": [], "reply": content};
      }

      final String reply =
      (data['reply'] ?? 'تم تنفيذ الأمر').toString();

      final List<dynamic> actions = data['actions'] ?? [];
      print("🎯 ACTIONS COUNT => ${actions.length}");

      final mqtt = Provider.of<MqttProvider>(context, listen: false);

      for (final action in actions) {
        final String device =
        (action['device'] ?? '').toString().toLowerCase();
        final String command =
        (action['command'] ?? '').toString().toLowerCase();

        print("⚙️ EXECUTE => $device : $command");

        switch (device) {
          case 'lamp':
            if (command == 'on') {
              mqtt.turnLampOn();
              setState(() => _homeState.lampOn = true);
              print("💡 LAMP ON");
            } else if (command == 'off') {
              mqtt.turnLampOff();
              setState(() => _homeState.lampOn = false);
              print("💡 LAMP OFF");
            }
            break;

          case 'pump':
            if (command == 'on') {
              mqtt.turnPumpOn();
              setState(() => _homeState.pumpOn = true);
              print("🚰 PUMP ON");
            } else if (command == 'off') {
              mqtt.turnPumpOff();
              setState(() => _homeState.pumpOn = false);
              print("🚰 PUMP OFF");
            }
            break;

          case 'window':
            if (command == 'open') {
              mqtt.openWindow();
              setState(() => _homeState.windowOpen = true);
              print("🪟 WINDOW OPEN");
            } else if (command == 'close') {
              mqtt.closeWindow();
              setState(() => _homeState.windowOpen = false);
              print("🪟 WINDOW CLOSE");
            }
            break;

          case 'door':
            if (command == 'open') {
              mqtt.openDoorWithPassword(realDoorPassword);
              setState(() => _homeState.doorLocked = false);
              Future.delayed(const Duration(seconds: 3), () {
                if (mounted) setState(() => _homeState.doorLocked = true);
              });
              print("🚪 DOOR OPEN");
            }
            break;

          case 'mode':
            if (command == 'auto') {
              mqtt.setAutoMode();
              print("⚙️ MODE AUTO");
            } else if (command == 'manual') {
              mqtt.setManualMode();
              print("⚙️ MODE MANUAL");
            }
            break;

          default:
            print("⚠️ UNKNOWN DEVICE => $device");
        }
      }

      setState(() {
        _messages.add({"sender": "bot", "text": reply});
      });

      _scrollToBottom();
      print("================ END ================");
    } on SocketException {
      if (!mounted) return;
      setState(() {
        _messages
            .add({"sender": "bot", "text": "❌ مفيش اتصال بالإنترنت."});
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _messages.add(
            {"sender": "bot", "text": "⏰ السيرفر أتأخر، حاول تاني."});
      });
    } catch (e, stackTrace) {
      print("🚨 ERROR => $e");
      print("📌 STACK => $stackTrace");
      if (!mounted) return;
      setState(() {
        _messages.add({"sender": "bot", "text": "حصل خطأ:\n$e"});
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ============================================================
  // 🎨 BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xff0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xff0F172A),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(18),
                border:
                Border.all(color: Colors.blue.withOpacity(0.4)),
              ),
              child: const Center(
                  child: Text("🏠", style: TextStyle(fontSize: 16))),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("سمارت",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                Text("المساعد الذكي",
                    style:
                    TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: _showHomeStatusDialog,
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xff1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  _dot(_homeState.lampOn, Colors.yellow),
                  const SizedBox(width: 5),
                  _dot(_homeState.windowOpen, Colors.blue),
                  const SizedBox(width: 5),
                  _dot(_homeState.pumpOn, Colors.green),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: _showTemplates ? 112 : 0,
            child: _showTemplates
                ? Container(
              color: const Color(0xff1E293B),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding:
                    EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Text("⚡ سيناريوهات جاهزة",
                        style: TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      itemCount: _scenes.length,
                      itemBuilder: (ctx, i) {
                        final s = _scenes[i];
                        return GestureDetector(
                          onTap: () => _sendMessage(
                              overrideText: s['prompt']),
                          child: Container(
                            width: 72,
                            margin:
                            const EdgeInsets.symmetric(
                                horizontal: 4),
                            decoration: BoxDecoration(
                              color: (s['color'] as Color)
                                  .withOpacity(0.25),
                              borderRadius:
                              BorderRadius.circular(14),
                              border: Border.all(
                                  color: (s['color'] as Color)
                                      .withOpacity(0.5)),
                            ),
                            child: Column(
                              mainAxisAlignment:
                              MainAxisAlignment.center,
                              children: [
                                Text(s['icon'],
                                    style: const TextStyle(
                                        fontSize: 20)),
                                const SizedBox(height: 4),
                                Text(s['label'],
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight:
                                        FontWeight.w600),
                                    textAlign:
                                    TextAlign.center),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            )
                : const SizedBox.shrink(),
          ),

          Expanded(
            child: _messages.isEmpty
                ? _buildWelcomeScreen()
                : ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(size.width * 0.04),
              itemCount: _messages.length,
              itemBuilder: (ctx, i) {
                final msg = _messages[i];
                return _buildBubble(
                    msg["text"] ?? '',
                    msg["sender"] == "user");
              },
            ),
          ),

          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.blue),
                  ),
                  const SizedBox(width: 10),
                  Text("سمارت بيفكر...",
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.35),
                          fontSize: 13)),
                ],
              ),
            ),

          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            decoration: const BoxDecoration(
              color: Color(0xff1E293B),
              borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(
                          () => _showTemplates = !_showTemplates),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _showTemplates
                          ? Colors.blue.withOpacity(0.2)
                          : const Color(0xff0F172A),
                      borderRadius: BorderRadius.circular(21),
                      border: Border.all(
                          color: _showTemplates
                              ? Colors.blue
                              : Colors.white12),
                    ),
                    child: Icon(
                      _showTemplates
                          ? Icons.close
                          : Icons.auto_awesome,
                      color: _showTemplates
                          ? Colors.blue
                          : Colors.white38,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 14),
                    textDirection: TextDirection.rtl,
                    decoration: InputDecoration(
                      hintText: "اكتب أمرك هنا...",
                      hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.25),
                          fontSize: 14),
                      filled: true,
                      fillColor: const Color(0xff0F172A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),

                GestureDetector(
                  onTap: _isLoading ? null : () => _sendMessage(),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _isLoading
                          ? Colors.blue.withOpacity(0.2)
                          : Colors.blue,
                      borderRadius: BorderRadius.circular(21),
                    ),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(bool isOn, Color color) {
    return Icon(Icons.circle,
        size: 8, color: isOn ? color : Colors.white);
  }

  void _showHomeStatusDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xff1E293B),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text("🏠 حالة المنزل",
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
            textDirection: TextDirection.rtl),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _statusRow("💡 اللمبة", _homeState.lampStatus,
                _homeState.lampOn),
            _statusRow("🪟 الشباك", _homeState.windowStatus,
                _homeState.windowOpen),
            _statusRow("🚰 المضخة", _homeState.pumpStatus,
                _homeState.pumpOn),
            _statusRow("🚪 الباب", _homeState.doorStatus,
                !_homeState.doorLocked),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("تمام",
                style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  Widget _statusRow(String label, String value, bool isOn) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 14)),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isOn
                  ? Colors.green.withOpacity(0.2)
                  : Colors.red.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(value,
                style: TextStyle(
                    color: isOn ? Colors.green : Colors.redAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.blue.withOpacity(0.3), width: 2),
              ),
              child: const Center(
                  child:
                  Text("🏠", style: TextStyle(fontSize: 38))),
            ),
            const SizedBox(height: 20),
            const Text("أهلاً! أنا سمارت 👋",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              "مساعدك الذكي للتحكم في المنزل\nقولي إيه اللي تحتاجه",
              style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _chip("🌙 أنا هنام"),
                _chip("💡 شغل النور"),
                _chip("🌱 روي النباتات"),
                _chip("🚪 افتح الباب"),
                _chip("🌬️ هوّي المنزل"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String text) {
    return GestureDetector(
      onTap: () => _sendMessage(overrideText: text),
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xff1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Text(text,
            style: const TextStyle(
                color: Colors.white60, fontSize: 13)),
      ),
    );
  }

  Widget _buildBubble(String text, bool isUser) {
    return Align(
      alignment:
      isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: isUser
              ? const Color(0xff1D4ED8)
              : const Color(0xff1E293B),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 6,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Text(
          text,
          textDirection: TextDirection.rtl,
          style: const TextStyle(
              color: Colors.white, fontSize: 15, height: 1.5),
        ),
      ),
    );
  }
}