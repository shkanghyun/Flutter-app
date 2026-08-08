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

  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  void _openStationOption(Station station) {
    print('역 옵션 실행');
    //if (_overlayEntry != null) {print('안됨'); return;} // 이미 켜져있으면 중복 생성 방지

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: 150, // 띄울 위젯의 너비
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 50), // 버튼 기준 위젯이 뜰 위치 (X축, Y축)
          child: Material(
            elevation: 4.0,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(12),
              color: Colors.amber,
              child: const Text('특정 위치 위젯!'),
            ),
          ),
        ),
      ),
    );

    // 화면 오버레이에 추가
    Overlay.of(context).insert(_overlayEntry!);
    print(_overlayEntry);
  }

  // 오버레이 닫기 함수
  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _openSearch() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StationSearchSheet(onSelect: _openStationDetailsSheet),
    );
  }

  void _openStationDetailsSheet(Station station) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StationDetailsSheet(station: station),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    _animationController.dispose();
    _hideOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                        onTap: () => _openStationOption(station),
                        transformationController: _mapController,
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

class StationMarker extends StatefulWidget {
  const StationMarker({
    super.key,
    required this.station,
    required this.onTap,
    required this._transformationController,
  });

  final Station station;
  final VoidCallback onTap;
  final TransformationController _transformationController;

  @override
  State<StationMarker> createState() => _StationMarkerState();
}

class _StationMarkerState extends State<StationMarker> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    // 2. 줌인/줌아웃(화면 조작)이 일어날 때마다 오버레이를 다시 그리도록 리스너 등록
    widget._transformationController.addListener(_updateOverlay);
  }

  void _updateOverlay() {
    if (_overlayEntry != null) {
      // 리스너가 동작할 때 상태를 Rebuild 하여 새로운 Scale 값을 적용합니다.
      _overlayEntry!.markNeedsBuild();
    }
  }

  void _openStationOption() {
    if (_overlayEntry != null) {
      print('안됨');
      return;
    } // 이미 켜져있으면 중복 생성 방지
        final double currentScale =
            widget._transformationController.value.row0.x;

        const double originalWidth = 150.0;
        const double originalHeight = 80.0;
    _overlayEntry = SingleOverlayManager.show(context,
      
        // 컨트롤러의 매트릭스에서 현재 X축 확대 배율을 추출


        Positioned(
          width: originalWidth / currentScale,
          height: originalHeight / currentScale,

          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 50), // 버튼 기준 위젯이 뜰 위치 (X축, Y축)
            child: Material(
              elevation: 4.0,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: EdgeInsets.zero,
                color: Colors.amber,
                child: Padding(
                  padding: EdgeInsets.zero,
                  child: Text(
                    '특정 위치 위젯!',
                    style: TextStyle(fontSize: 14.0 / currentScale),
                  ),
                ),
              ),
            ),
          ),
      ),
      
    );

    // 화면 오버레이에 추가
    Overlay.of(context).insert(_overlayEntry!);
    print(_overlayEntry);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _hideOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('BuildContext');
    const markerSize = 38.0;
    return Positioned(
      left: widget.station.x * _mapSize - markerSize / 2,
      top: widget.station.y * _mapSize - markerSize / 2,
      width: markerSize,
      height: markerSize,
      child: Tooltip(
        message: widget.station.name,
        child: Semantics(
          label: '${widget.station.name} 역 정보 보기',
          button: true,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _openStationOption,
              borderRadius: BorderRadius.circular(20),
              child: Center(
                child: CompositedTransformTarget(
                  link: _layerLink,
                  child: Container(
                    width: 25,
                    height: 25,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: widget.station.color, width: 4),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x59000000),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.add,
                      size: 12,
                      color: widget.station.color,
                    ),
                  ),
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

class selectStationOption extends StatelessWidget {
  const selectStationOption({super.key, required this.station});
  final Station station;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: station.x * _mapSize,
      top: station.y * _mapSize,
      child: Column(
        children: [
          SizedBox(width: 10, height: 10),
          SizedBox(width: 10, height: 10),
        ],
      ),
    );
  }
}

class SingleOverlayManager {
  // 현재 화면에 표시 중인 OverlayEntry를 저장하는 변수
  static OverlayEntry? _currentEntry;

  /// 새로운 오버레이를 화면에 하나만 표시합니다.
  static OverlayEntry? show(BuildContext context, Widget child) {
    dismiss();

    // 2. 새로운 OverlayEntry를 생성합니다.
    _currentEntry = OverlayEntry(
      builder: (context) => child,
    );

    // 3. 현재 화면의 Overlay에 삽입합니다.
    return _currentEntry;
  }

  /// 현재 표시 중인 오버레이를 제거합니다.
  static void dismiss() {
    if (_currentEntry != null) {
      _currentEntry!.remove();
      _currentEntry = null;
    }
  }
}