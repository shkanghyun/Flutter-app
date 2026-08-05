import 'package:flutter/material.dart';
import 'package:subway/api_service.dart';

void main() {
  runApp(const SeoulMetroApp());
}

class SeoulMetroApp extends StatelessWidget {
  const SeoulMetroApp({super.key});

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF101B36);
    return MaterialApp(
      title: '서울 지하철',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2857D9),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FC),
        appBarTheme: const AppBarTheme(
          backgroundColor: ink,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
      ),
      home: const MetroMapPage(),
    );
  }
}

class MetroMapPage extends StatefulWidget {
  const MetroMapPage({super.key});

  @override
  State<MetroMapPage> createState() => _MetroMapPageState();
}

class _MetroMapPageState extends State<MetroMapPage> {
  final TransformationController _mapController = TransformationController();

  void _resetMap() {
    Size viewport = MediaQuery.sizeOf(context);
    double scale = (viewport.width / _mapSize).clamp(0.20, 1.0);
    print('viewport is: $viewport');
    print('scale: $scale');
    print('translate to: ${viewport.height - _mapSize * scale}');
    _mapController.value = Matrix4.identity()
      ..translateByDouble(
        0.0,
        (viewport.height - _mapSize * scale) / 2,
        0.0,
        1.0,
      )
      ..scaleByDouble(scale, scale, 1.0, 1.0);
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _openStation(Station station) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StationDetailsSheet(station: station),
    );
  }

  void _openSearch() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StationSearchSheet(onSelect: _openStation),
    );
  }

  @override
  Widget build(BuildContext context) {
    Size viewport = MediaQuery.sizeOf(context);
    double statusBarHeight = MediaQuery.of(context).padding.top; //상태바 높이
    double scale = (viewport.height / _mapSize).clamp(0.20, 1.0);

    print('viewport:$viewport statusbar:$statusBarHeight scale:$scale');
    _mapController.value = Matrix4.identity()
      ..translateByDouble(
        (viewport.width-_mapSize*scale) / 2,
        (viewport.height - _mapSize * scale) / 2,
        0.0,
        1.0,
      )
      ..scaleByDouble(scale, scale, 1.0, 1.0);

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 244, 244, 244),
      appBar: AppBar(
        titleSpacing: 20,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('서울 지하철', style: TextStyle(fontWeight: FontWeight.w800)),
            Text(
              '역을 탭하여 정보 보기',
              style: TextStyle(fontSize: 12, color: Color(0xFFB8C8FF)),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: '역 검색',
            onPressed: _openSearch,
            icon: const Icon(Icons.search_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              transformationController: _mapController,
              clipBehavior: Clip.none,
              constrained: false,
              minScale: 0.20,
              maxScale: 4.0,
              boundaryMargin: const EdgeInsets.all(100),
              child: SizedBox(
                width: _mapSize,
                height: _mapSize,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        'assets/images/seoul_subway_map-2.png',
                        fit: BoxFit.fill,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                    ...stations.map(
                      (station) => StationMarker(
                        station: station,
                        onTap: () => _openStation(station),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 16,
            top: 16,
            child: Material(
              color: Colors.white,
              elevation: 3,
              shadowColor: const Color(0x25000000),
              borderRadius: BorderRadius.circular(14),
              child: IconButton(
                tooltip: '지도 위치 초기화',
                onPressed: _resetMap,
                icon: const Icon(
                  Icons.my_location_rounded,
                  color: Color(0xFF101B36),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const double _mapSize = 1400;

class StationMarker extends StatelessWidget {
  const StationMarker({super.key, required this.station, required this.onTap});

  final Station station;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    print('BuildContext');
    const markerSize = 38.0;
    return Positioned(
      left: station.x * _mapSize - markerSize / 2,
      top: station.y * _mapSize - markerSize / 2,
      width: markerSize,
      height: markerSize,
      child: Tooltip(
        message: station.name,
        child: Semantics(
          label: '${station.name} 역 정보 보기',
          button: true,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              child: Center(
                child: Container(
                  width: 25,
                  height: 25,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: station.color, width: 4),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x59000000),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(Icons.add, size: 12, color: station.color),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class StationDetailsSheet extends StatefulWidget {
  final Station station;
  const StationDetailsSheet({super.key, required this.station});

  @override
  State<StationDetailsSheet> createState() => StationDetailsSheetState();
}

class StationDetailsSheetState extends State<StationDetailsSheet> {
  List<String> _dataList = [];
  bool _isLoading = false; // 로딩 상태 기억용 변수

  @override
  void initState() {
    super.initState();
    loadData(); // 화면이 열리자마자 데이터를 가져옵니다.
    print('initState 실행');
  }

  Future<void> loadData() async {
    setState(() {
      _isLoading = true; // 로딩 시작
      print('setState 실행');
    });

    try {
      // FutureBuilder 없이 await로 결과를 일반 변수에 바로 대입!
      List<String> result = await ApiService.fetchPublicXmlData(
        widget.station.name,
      );

      setState(() {
        _dataList = result; // 받아온 진짜 데이터를 변수에 저장
        _isLoading = false; // 로딩 완료
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // 에러 처리 (예: 스낵바 띄우기)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('데이터를 가져오지 못했습니다: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.52,
      minChildSize: 0.36,
      maxChildSize: 0.88,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9DFED),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: widget.station.color,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.subway_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.station.name,
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF101B36),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.station.englishName,
                        style: const TextStyle(
                          color: Color(0xFF68748E),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: '닫기',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 22),
            const Text('운행 노선', style: _sectionTitle),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.station.lines
                  .map((line) => LineBadge(line: line))
                  .toList(),
            ),
            const SizedBox(height: 24),
            _InfoCard(
              icon: Icons.swap_horiz_rounded,
              label: '환승 안내',
              value: widget.station.transferNote,
              iconColor: widget.station.color,
            ),
            const SizedBox(height: 10),
            _InfoCard(
              icon: Icons.location_on_outlined,
              label: '주변 주요 장소',
              value: widget.station.nearby,
              iconColor: const Color(0xFF5F6D89),
            ),
            const SizedBox(height: 10),
            _InfoCard(
              icon: Icons.info_outline_rounded,
              label: '역 안내',
              value: widget.station.note,
              iconColor: const Color(0xFF5F6D89),
            ),
            const SizedBox(height: 10),

            _InfoCard(
              icon: Icons.info_outline_rounded,
              label: '도착 정보',
              value: widget.station.note,
              iconColor: const Color(0xFF5F6D89),
            ),
            SizedBox(
              height: 200,
              child: _dataList.isEmpty
                  ? Center(child: Text('데이터가 없습니다.')) // 데이터가 없을 때
                  : ListView.builder(
                      // 데이터가 있을 때 일반 변수(_dataList) 사용!
                      itemCount: _dataList.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: CircleAvatar(child: Text('${index + 1}')),
                          title: Text(_dataList[index]), // 일반 변수의 값 출력
                        );
                      },
                    ),
            ),
            FilledButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${widget.station.name}역을 즐겨찾기에 저장했습니다.'),
                ),
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: const Color(0xFF101B36),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.bookmark_border_rounded),
              label: const Text('즐겨찾기에 저장'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF68748E),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF1D2942),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const _sectionTitle = TextStyle(
  fontSize: 15,
  fontWeight: FontWeight.w800,
  color: Color(0xFF101B36),
);

class LineBadge extends StatelessWidget {
  const LineBadge({super.key, required this.line});

  final MetroLine line;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: line.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: line.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            line.name,
            style: TextStyle(
              color: line.color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class StationSearchSheet extends StatefulWidget {
  const StationSearchSheet({super.key, required this.onSelect});

  final ValueChanged<Station> onSelect;

  @override
  State<StationSearchSheet> createState() => _StationSearchSheetState();
}

class _StationSearchSheetState extends State<StationSearchSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final results = stations
        .where((station) => station.matches(_query))
        .toList();
    return DraggableScrollableSheet(
      initialChildSize: 0.68,
      minChildSize: 0.42,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
        child: Column(
          children: [
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD9DFED),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              autofocus: true,
              onChanged: (value) => setState(() => _query = value.trim()),
              decoration: InputDecoration(
                hintText: '역 이름 검색',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: const Color(0xFFF1F4FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                itemCount: results.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final station = results[index];
                  return Material(
                    color: Colors.transparent,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 5,
                      ),
                      leading: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: station.color,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.subway_rounded,
                          color: Colors.white,
                          size: 19,
                        ),
                      ),
                      title: Text(
                        station.name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        station.lines.map((line) => line.name).join(' · '),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        Navigator.pop(context);
                        widget.onSelect(station);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MetroLine {
  const MetroLine(this.name, this.color);

  final String name;
  final Color color;
}

class Station {
  const Station({
    required this.name,
    required this.englishName,
    required this.x,
    required this.y,
    required this.lines,
    required this.transferNote,
    required this.nearby,
    required this.note,
  });

  final String name;
  final String englishName;
  final double x;
  final double y;
  final List<MetroLine> lines;
  final String transferNote;
  final String nearby;
  final String note;

  Color get color => lines.first.color;

  bool matches(String query) {
    if (query.isEmpty) return true;
    final normalized = query.toLowerCase();
    return name.toLowerCase().contains(normalized) ||
        englishName.toLowerCase().contains(normalized);
  }
}

const line1 = MetroLine('1호선', Color(0xFF1F4B99));
const line2 = MetroLine('2호선', Color(0xFF13A538));
const line3 = MetroLine('3호선', Color(0xFFF27822));
const line4 = MetroLine('4호선', Color(0xFF38A4D5));
const line5 = MetroLine('5호선', Color(0xFF8B4EBB));
const line6 = MetroLine('6호선', Color(0xFF9B4D31));
const line7 = MetroLine('7호선', Color(0xFF67772D));
const line8 = MetroLine('8호선', Color(0xFFE91B74));
const line9 = MetroLine('9호선', Color(0xFF9E9D92));
const airport = MetroLine('공항철도', Color(0xFF5AAFC3));
const gtxA = MetroLine('GTX-A', Color(0xFFAA4398));
const suinBundang = MetroLine('수인분당선', Color(0xFFF4BB38));
const gyeongui = MetroLine('경의중앙선', Color(0xFF73C5B4));

const stations = <Station>[
  Station(
    name: '서울역',
    englishName: 'Seoul Station',
    x: 0.570,
    y: 0.394,
    lines: [line1, line4, airport, gyeongui],
    transferNote: '1·4호선, 공항철도, 경의중앙선 환승 가능',
    nearby: '서울역 KTX, 롯데마트 서울역점, 서울로7017',
    note: '공항철도 직통열차와 일반열차를 이용할 수 있습니다.',
  ),
  Station(
    name: '홍대입구',
    englishName: 'Hongik Univ.',
    x: 0.402,
    y: 0.430,
    lines: [line2, airport, gyeongui],
    transferNote: '2호선, 공항철도, 경의중앙선 환승 가능',
    nearby: '홍익대학교, 연남동, 경의선숲길',
    note: '공항철도와 경의중앙선은 같은 역에서 환승합니다.',
  ),
  Station(
    name: '종로3가',
    englishName: 'Jongno 3(sam)-ga',
    x: 0.476,
    y: 0.334,
    lines: [line1, line3, line5],
    transferNote: '1·3·5호선 환승 가능',
    nearby: '익선동, 종묘, 인사동',
    note: '1호선과 3·5호선의 승강장 위치가 다르니 표지판을 확인하세요.',
  ),
  Station(
    name: '디지털미디어시티',
    englishName: 'Digital Media City',
    x: 0.282,
    y: 0.366,
    lines: [line6, airport, gyeongui],
    transferNote: '6호선, 공항철도, 경의중앙선 환승 가능',
    nearby: '상암 DMC, MBC, 월드컵공원',
    note: '공항철도 이용 시 인천공항 방면으로 이동할 수 있습니다.',
  ),
  Station(
    name: '여의도',
    englishName: 'Yeouido',
    x: 0.420,
    y: 0.581,
    lines: [line5, line9],
    transferNote: '5·9호선 환승 가능',
    nearby: '여의도공원, 더현대 서울, 국회의사당',
    note: '9호선 급행 정차역입니다.',
  ),
  Station(
    name: '고속터미널',
    englishName: 'Express Bus Terminal',
    x: 0.584,
    y: 0.629,
    lines: [line3, line7, line9],
    transferNote: '3·7·9호선 환승 가능',
    nearby: '서울고속버스터미널, 신세계백화점 강남점',
    note: '고속·시외버스 터미널과 연결됩니다.',
  ),
  Station(
    name: '강남',
    englishName: 'Gangnam',
    x: 0.664,
    y: 0.704,
    lines: [line2, suinBundang],
    transferNote: '2호선과 신분당선 환승 가능',
    nearby: '강남대로, 강남역 지하상가, 테헤란로',
    note: '신분당선은 별도 운임이 적용될 수 있습니다.',
  ),
  Station(
    name: '사당',
    englishName: 'Sadang',
    x: 0.508,
    y: 0.718,
    lines: [line2, line4],
    transferNote: '2·4호선 환승 가능',
    nearby: '사당역 버스환승센터, 관악산',
    note: '4호선 남태령·당고개 방면 승강장을 확인하세요.',
  ),
  Station(
    name: '잠실',
    englishName: 'Jamsil',
    x: 0.790,
    y: 0.571,
    lines: [line2, line8],
    transferNote: '2·8호선 환승 가능',
    nearby: '롯데월드, 롯데월드타워, 석촌호수',
    note: '대형 복합시설과 연결되어 주말에는 혼잡할 수 있습니다.',
  ),
  Station(
    name: '청량리',
    englishName: 'Cheongnyangni',
    x: 0.700,
    y: 0.255,
    lines: [line1, gyeongui, suinBundang, gtxA],
    transferNote: '1호선, 경의중앙선, 수인분당선, GTX-A 환승 가능',
    nearby: '청량리역 KTX, 롯데백화점 청량리점',
    note: '광역·일반 철도 이용객이 많은 복합 환승역입니다.',
  ),
];
