import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:subway/stations.dart';
import 'package:subway/stationDetails.dart';

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

class _MetroMapPageState extends State<MetroMapPage>
    with SingleTickerProviderStateMixin {
  final TransformationController _mapController = TransformationController();
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 200), // 제자리 복귀 시간
        )..addListener(() {
          _mapController.value = _animation!.value;
        });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Size viewport = MediaQuery.sizeOf(context);
      final scale = 0.65;
      _mapController.value = Matrix4.identity()
        ..translateByDouble(
          (viewport.width - _mapSize * scale) / 2,
          10, //(viewport.height - _mapSize * scale) / 2,
          0.0,
          1.0,
        )
        ..scaleByDouble(scale, scale, 1.0, 1.0);
    });
  }

  void _onInteractionUpdate(ScaleUpdateDetails details) {
    // 현재 손가락이 가려는 위치 (누적된 이동 거리)

    final translation = _mapController.value.getTranslation();

    double dx = details.focalPointDelta.dx;
    double dy = details.focalPointDelta.dy;

    double resistedDx = dx * 20;
    double resistedBy = dy * 20;

    // 실시간으로 저항값이 계산된 행렬을 강제로 주입합니다.
    _mapController.value = _mapController.value
      ..translateByDouble(resistedDx, resistedBy, 0.0, 1.0);
  }

  void _onInteractionEnd(ScaleEndDetails details) async {
    Size viewport = MediaQuery.sizeOf(context);
    double scale = _mapController.value.storage[0]; // 확대 정도
    double dx = _mapController.value.storage[12]; // X축 이동량
    double dy = _mapController.value.storage[13]; // Y축 이동량
    double velocityX = details.velocity.pixelsPerSecond.dx; // X축 이동속도
    double velocityY = details.velocity.pixelsPerSecond.dy; // Y축 이동속도

    double targetX = dx + (velocityX * 0.01);
    double targetY = dy + (velocityY * 0.01);

    Matrix4 finalMatrix = _mapController.value.clone();

    finalMatrix.setEntry(0, 3, targetX);
    finalMatrix.setEntry(1, 3, targetY);

    _animation = Matrix4Tween(begin: _mapController.value, end: finalMatrix)
        .animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );
    await _animationController.forward(from: 0.0);

    Matrix4 onEdgeMatrix = _mapController.value.clone();

    if (targetX >= 50) {
      onEdgeMatrix.setEntry(0, 3, 50);
      print('OnEdge!!!!!!!!!!!!');
    } else if (dx <= viewport.width - _mapSize * scale - 50) {
      onEdgeMatrix.setEntry(0, 3, viewport.width - _mapSize * scale - 50);
    }
    if (targetY >= 50) {
      onEdgeMatrix.setEntry(1, 3, 50);
    } else if (dy <= viewport.height - _mapSize * scale - 70) {
      onEdgeMatrix.setEntry(1, 3, viewport.height - _mapSize * scale - 70);
    }

    _mapController.value = onEdgeMatrix;
  }

  @override
  void dispose() {
    _mapController.dispose();
    _animationController.dispose();
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
    /*Size viewport = MediaQuery.sizeOf(context);
    double statusBarHeight = MediaQuery.of(context).padding.top; //상태바 높이
    double scale = (viewport.height / _mapSize).clamp(0.20, 1.0);

    print('빌드중 viewport:$viewport statusbar:$statusBarHeight scale:$scale');
    _mapController.value = Matrix4.identity()
      ..translateByDouble(
        10, //(viewport.width - _mapSize * scale) / 2,
        10, //(viewport.height - _mapSize * scale) / 2,
        0.0,
        1.0,
      )
      ..scaleByDouble(0.6, 0.6, 1.0, 1.0);*/

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 244, 244, 244),
      //resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              interactionEndFrictionCoefficient: double.infinity,
              transformationController: _mapController,
              //clipBehavior: Clip.none,
              constrained: false,
              minScale: 1.0,
              maxScale: 4.0,
              boundaryMargin: const EdgeInsets.all(200),
              //onInteractionUpdate: _onInteractionUpdate, // 👈 드래그 중 제어
              onInteractionEnd: _onInteractionEnd, // 👈 드래그 종료 시 제어
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
            bottom: 60,
            width: 60,
            height: 60,
            child: Material(
              color: Colors.white,
              elevation: 3,
              shadowColor: const Color(0x25000000),
              borderRadius: BorderRadius.circular(14),
              child: IconButton(
                tooltip: '역 검색',
                onPressed: _openSearch,
                icon: const Icon(Icons.search_rounded),
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
      left:  station.x * _mapSize - markerSize / 2,
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
