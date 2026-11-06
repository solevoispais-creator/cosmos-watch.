import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const CosmosWatchApp());

const bg = Color(0xFF090B0E);
const panel = Color(0x667E8790);
const silver = Color(0xFFD5D9DD);
const muted = Color(0xFF929AA2);

class CosmosWatchApp extends StatelessWidget {
  const CosmosWatchApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'COSMOS WATCH',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        colorScheme: const ColorScheme.dark(primary: silver, surface: bg),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const Shell(),
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int index = 0;
  final pages = const [HomePage(), RadarPage(), ObjectsPage(), EventsPage(), SettingsPage()];
  final labels = const ['Главная', 'Радар', 'Объекты', 'События', 'Настройки'];
  final icons = const [Icons.public, Icons.radar, Icons.language, Icons.event, Icons.tune];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
            child: Row(children: [
              const Icon(Icons.blur_circular, color: silver, size: 25),
              const SizedBox(width: 10),
              const Text('COSMOS WATCH', style: TextStyle(letterSpacing: 2.2, fontSize: 13, fontWeight: FontWeight.w600)),
              const Spacer(),
              Container(width: 7, height: 7, decoration: const BoxDecoration(color: Color(0xFF9DB9A5), shape: BoxShape.circle)),
              const SizedBox(width: 7),
              const Text('LIVE DATA', style: TextStyle(color: muted, fontSize: 9, letterSpacing: 1.2)),
            ]),
          ),
          Expanded(child: IndexedStack(index: index, children: pages)),
        ]),
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0x99565E66),
          border: Border.all(color: const Color(0x55FFFFFF)),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 24)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(5, (i) => GestureDetector(
            onTap: () => setState(() => index = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: index == i ? const Color(0x557F8992) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(icons[i], size: 19, color: index == i ? Colors.white : const Color(0xFFADB4BA)),
                const SizedBox(height: 3),
                Text(labels[i], style: TextStyle(fontSize: 9, color: index == i ? Colors.white : const Color(0xFFADB4BA))),
              ]),
            ),
          )),
        ),
      ),
    );
  }
}

class Glass extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const Glass({super.key, required this.child, this.padding = const EdgeInsets.all(16)});
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: panel,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0x44FFFFFF)),
      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 8))],
    ),
    child: child,
  );
}

Widget heading(String title, String subtitle) => Padding(
  padding: const EdgeInsets.only(bottom: 14),
  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w300, letterSpacing: .3)),
    const SizedBox(height: 4),
    Text(subtitle, style: const TextStyle(color: muted, fontSize: 11, letterSpacing: 1.1)),
  ]),
);

class IssPosition {
  final double latitude, longitude, altitude, velocity;
  IssPosition(this.latitude, this.longitude, this.altitude, this.velocity);
  factory IssPosition.fromJson(Map<String, dynamic> j) => IssPosition(
    (j['latitude'] as num).toDouble(), (j['longitude'] as num).toDouble(),
    (j['altitude'] as num).toDouble(), (j['velocity'] as num).toDouble());
}

class SpaceApi {
  static Future<IssPosition> iss() async {
    final r = await http.get(Uri.parse('https://api.wheretheiss.at/v1/satellites/25544')).timeout(const Duration(seconds: 12));
    if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
    return IssPosition.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }
}

class IssCard extends StatefulWidget {
  const IssCard({super.key});
  @override
  State<IssCard> createState() => _IssCardState();
}
class _IssCardState extends State<IssCard> {
  IssPosition? data;
  String? error;
  Timer? timer;
  @override
  void initState() { super.initState(); refresh(); timer = Timer.periodic(const Duration(seconds: 15), (_) => refresh()); }
  Future<void> refresh() async {
    try { final value = await SpaceApi.iss(); if (mounted) setState(() { data = value; error = null; }); }
    catch (_) { if (mounted) setState(() => error = 'Нет соединения с источником данных'); }
  }
  @override
  void dispose() { timer?.cancel(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Glass(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: const [Icon(Icons.satellite_alt, color: silver), SizedBox(width: 8), Text('МЕЖДУНАРОДНАЯ КОСМИЧЕСКАЯ СТАНЦИЯ', style: TextStyle(fontSize: 10, letterSpacing: .8)), Spacer(), Icon(Icons.circle, color: Color(0xFF9DB9A5), size: 7)]),
    const SizedBox(height: 16),
    if (data != null) ...[
      Row(children: [
        Expanded(child: metric('ШИРОТА', '${data!.latitude.toStringAsFixed(2)}°')),
        Expanded(child: metric('ДОЛГОТА', '${data!.longitude.toStringAsFixed(2)}°')),
      ]),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: metric('ВЫСОТА', '${data!.altitude.toStringAsFixed(1)} км')),
        Expanded(child: metric('СКОРОСТЬ', '${(data!.velocity / 3600).toStringAsFixed(2)} км/с')),
      ]),
    ] else Text(error ?? 'Получение текущих координат…', style: const TextStyle(color: muted)),
    const SizedBox(height: 8),
    Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: refresh, icon: const Icon(Icons.refresh, size: 15), label: const Text('Обновить'))),
  ]));
}
Widget metric(String label, String value) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
  Text(label, style: const TextStyle(color: muted, fontSize: 9, letterSpacing: 1)),
  const SizedBox(height: 5),
  Text(value, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w300)),
]);

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 24), children: [
    heading('Космос рядом', 'ОБЗОР НАБЛЮДЕНИЙ И МИССИЙ'),
    Container(height: 180, decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF333B43), Color(0xFF111820), Color(0xFF090B0E)]),
      border: Border.all(color: const Color(0x44FFFFFF))),
      child: Stack(children: [
        Positioned(right: 28, top: 24, child: Container(width: 112, height: 112, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [Color(0xFFB7BEC4), Color(0xFF535E68), Color(0xFF1A222B)])))),
        const Positioned(left: 18, bottom: 18, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('EARTH ORBIT', style: TextStyle(color: silver, fontSize: 9, letterSpacing: 2)),
          SizedBox(height: 6), Text('Наблюдай реальную\nорбиту Земли', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w300)),
        ])),
      ]),
    ),
    const SizedBox(height: 16),
    const IssCard(),
    const SizedBox(height: 16),
    const Glass(child: Row(children: [Icon(Icons.auto_awesome, color: silver), SizedBox(width: 12), Expanded(child: Text('Следующий шаг — добавить каталог объектов и расчёт видимых пролётов.', style: TextStyle(color: silver, fontSize: 12)))])),
  ]);
}

class RadarPage extends StatelessWidget {
  const RadarPage({super.key});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: [
    heading('Радар', 'ОРБИТАЛЬНАЯ ОБСТАНОВКА'),
    const Glass(child: Column(children: [
      SizedBox(height: 220, child: CustomPaint(painter: RadarPainter(), child: Center(child: Icon(Icons.public, size: 72, color: Color(0xFFB8C0C7))))),
      SizedBox(height: 10),
      Text('Схематический радар · данные МКС обновляются на главной', style: TextStyle(color: muted, fontSize: 10)),
    ])),
    const SizedBox(height: 14),
    const IssCard(),
  ]);
}
class RadarPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..color = const Color(0x55D5D9DD)..style = PaintingStyle.stroke..strokeWidth = 1;
    final center = Offset(s.width/2, s.height/2);
    for (final f in [.28,.52,.76,1.0]) c.drawCircle(center, s.shortestSide*.46*f, p);
    c.drawLine(Offset(center.dx, 0), Offset(center.dx, s.height), p);
    c.drawLine(Offset(0, center.dy), Offset(s.width, center.dy), p);
    final orbit = Paint()..color = const Color(0x99D5D9DD)..style = PaintingStyle.stroke..strokeWidth = 1.4;
    c.drawOval(Rect.fromCenter(center: center, width: s.width*.82, height: s.height*.42), orbit);
    c.drawCircle(Offset(center.dx+s.width*.31, center.dy-s.height*.12), 4, Paint()..color = silver);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ObjectsPage extends StatelessWidget {
  const ObjectsPage({super.key});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: [
    heading('Объекты', 'КАТАЛОГ НЕБЕСНЫХ ТЕЛ'),
    objectTile(Icons.public, 'Планеты', 'Солнечная система'),
    objectTile(Icons.blur_on, 'Астероиды и кометы', 'Малые тела Солнечной системы'),
    objectTile(Icons.satellite_alt, 'Спутники', 'Орбитальные аппараты и станции'),
    const SizedBox(height: 14),
    Glass(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('LIVE SPACE', style: TextStyle(letterSpacing: 1.5, fontSize: 11)),
      const SizedBox(height: 8),
      const Text('Официальный видеопоток с МКС', style: TextStyle(color: muted, fontSize: 12)),
      const SizedBox(height: 12),
      FilledButton.tonalIcon(onPressed: () => launchUrl(Uri.parse('https://www.youtube.com/@NASA/live'), mode: LaunchMode.externalApplication),
        icon: const Icon(Icons.play_arrow), label: const Text('Открыть трансляцию NASA')),
    ])),
    const SizedBox(height: 14),
    const Glass(child: Text('Камеры других спутников доступны только если оператор публикует открытый видеопоток. Большинство спутников таких трансляций не передаёт.', style: TextStyle(color: muted, fontSize: 11))),
  ]);
}
Widget objectTile(IconData icon, String title, String sub) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Glass(child: Row(children: [
  Icon(icon, color: silver, size: 24), const SizedBox(width: 14),
  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: const TextStyle(fontSize: 15)), const SizedBox(height: 3),
    Text(sub, style: const TextStyle(color: muted, fontSize: 10)),
  ])),
  const Icon(Icons.chevron_right, color: muted),
])));

class EventsPage extends StatelessWidget {
  const EventsPage({super.key});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: [
    heading('События', 'АСТРОНОМИЧЕСКИЙ КАЛЕНДАРЬ'),
    const Glass(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Календарь наблюдений', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w300)),
      SizedBox(height: 8),
      Text('Затмения · метеорные потоки · сближения · пролёты МКС', style: TextStyle(color: muted, fontSize: 11)),
      SizedBox(height: 14),
      Text('Подключение проверенного календаря событий — следующий этап интеграции.', style: TextStyle(color: silver, fontSize: 11)),
    ])),
  ]);
}
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: [
    heading('Настройки', 'ПЕРСОНАЛИЗАЦИЯ ПРИЛОЖЕНИЯ'),
    const Glass(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Язык интерфейса', style: TextStyle(fontSize: 15)),
      SizedBox(height: 5),
      Text('Русский · дополнительные языки будут загружаться по выбору', style: TextStyle(color: muted, fontSize: 11)),
    ])),
    const SizedBox(height: 12),
    const Glass(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Внешний вид', style: TextStyle(fontSize: 15)),
      SizedBox(height: 5),
      Text('Серебристое прозрачное стекло · единый стиль всех вкладок', style: TextStyle(color: muted, fontSize: 11)),
    ])),
    const SizedBox(height: 12),
    const Glass(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Данные и приватность', style: TextStyle(fontSize: 15)),
      SizedBox(height: 5),
      Text('Координаты МКС загружаются из открытого источника. Геолокация устройства пока не запрашивается.', style: TextStyle(color: muted, fontSize: 11)),
    ])),
  ]);
}
