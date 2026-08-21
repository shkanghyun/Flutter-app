import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:subway/api_service.dart';
import 'package:subway/stations.dart';
import 'package:subway/stationDetailsSheet.dart';
import 'package:subway/stationSearchSheet.dart';

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

  void _openSearch() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StationSearchSheet(onSelect: _openStationDetailsSheet),
    );
  }

  void _openStationDetailsSheet(Station station) {
    final topPadding = MediaQuery.of(context).padding.top;
    print('toppadding=$topPadding');
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
    super.dispose();
  }

  // Flag 구현
  static Station? DepartureStation;
  static Station? ArrivalStation;
  static Station? TransferStation;
  bool _isDepartSet = false;
  bool _isArriveSet = false;
  bool _isTransferSet = false;

  void setDepartureStationFlag(Station station) {
    if (DepartureStation == station) {
      setState(() {
        _isDepartSet = false;
      });
    } else {
      setState(() {
        DepartureStation = station;
        _isDepartSet = true;
      });
    }
  }

  void setArrivalStationFlag(Station station) {
    if (ArrivalStation == station) {
      setState(() {
        _isArriveSet = false;
      });
    } else {
      setState(() {
        ArrivalStation = station;
        _isArriveSet = true;
      });
    }
  }

  void setTransferStationFlag(Station station) {
    if (TransferStation == station) {
      setState(() {
        _isTransferSet = false;
      });
    } else {
      setState(() {
        TransferStation = station;
        _isTransferSet = true;
      });
    }
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
                        'assets/images/seoul_subway_map_foreigners.png',
                        fit: BoxFit.fill,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                    ...stations.map(
                      (station) => StationMarker(
                        station: station,
                        onStationInformationSelected: (station) {
                          _openStationDetailsSheet(station);
                        },
                        onDepartureStationSelected: (station) {
                          setDepartureStationFlag(station);
                        },
                        onArrivalStationSelected: (station) {
                          setArrivalStationFlag(station);
                        },
                        onTransferStationSelected: (station) {
                          setTransferStationFlag(station);
                        },
                        transformationController: _mapController,
                      ),
                    ),
                    if (_isDepartSet)
                      DepartFlag(
                        transformationController: _mapController,
                        station: DepartureStation,
                      ),
                    if (_isArriveSet)
                      ArriveFlag(
                        transformationController: _mapController,
                        station: ArrivalStation,
                      ),
                    if (_isTransferSet)
                      TransferFlag(
                        transformationController: _mapController,
                        station: TransferStation,
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
    required this.onStationInformationSelected,
    required this.onDepartureStationSelected,
    required this.onArrivalStationSelected,
    required this.onTransferStationSelected,
    required this._transformationController,
  });

  final Station station;
  final Function(Station) onStationInformationSelected;
  final Function(Station) onDepartureStationSelected;
  final Function(Station) onArrivalStationSelected;
  final Function(Station) onTransferStationSelected;
  final TransformationController _transformationController;

  @override
  State<StationMarker> createState() => _StationMarkerState();
}

class _StationMarkerState extends State<StationMarker> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _optionOverlayEntry;

  @override
  void initState() {
    super.initState();
    // 2. 줌인/줌아웃(화면 조작)이 일어날 때마다 오버레이를 다시 그리도록 리스너 등록
    widget._transformationController.addListener(() {
      _updateOverlay;
    });
  }

  void _updateOverlay() {
    if (_optionOverlayEntry != null) {
      // 리스너가 동작할 때 상태를 Rebuild 하여 새로운 Scale 값을 적용합니다.
      _optionOverlayEntry!.markNeedsBuild();
      _optionOverlayEntry = null;
      //print('Optionoverlay 업데이트');
    }
  }

  void _openStationOption(Station station) {
    final double currentScale = widget
        ._transformationController
        .value
        .row0
        .x; // 컨트롤러의 매트릭스에서 현재 X축 확대 배율을 추출

    _optionOverlayEntry = StationOptionOverlay(
      station: station,
      onStationInformationSelected: widget.onStationInformationSelected,
      onDepartureSelected: widget.onDepartureStationSelected,
      onArrivalSelected: widget.onArrivalStationSelected,
      onTransferSelected: widget.onTransferStationSelected,
    ).show(context, widget._transformationController, _layerLink);

    // 화면 오버레이에 추가
    Overlay.of(context).insert(_optionOverlayEntry!);
    print(_optionOverlayEntry);
  }

  void _hideOverlay() {
    _optionOverlayEntry?.remove();
    _optionOverlayEntry = null;
  }

  @override
  void dispose() {
    _hideOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              onTap: () => _openStationOption(widget.station),
              borderRadius: BorderRadius.circular(20),
              child: Center(
                child: CompositedTransformTarget(
                  link: _layerLink,
                  child: Container(
                    //width: 25,
                    //height: 25,
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

class StationOptionOverlay {
  Station station;
  final Function(Station) onStationInformationSelected;
  final Function(Station) onDepartureSelected;
  final Function(Station) onArrivalSelected;
  final Function(Station) onTransferSelected;
  StationOptionOverlay({
    required this.station,
    required this.onStationInformationSelected,
    required this.onDepartureSelected,
    required this.onArrivalSelected,
    required this.onTransferSelected,
  });

  // 현재 화면에 표시 중인 OverlayEntry를 저장하는 변수
  static OverlayEntry? _currentEntry;

  OverlayEntry? show(
    BuildContext context,
    TransformationController _transformationController,
    LayerLink _layerLink,
  ) {
    dismiss();

    // 2. 새로운 OverlayEntry를 생성합니다.
    _currentEntry = OverlayEntry(
      builder: (context) {
        final double currentScale = _transformationController
            .value
            .row0
            .x; // 컨트롤러의 매트릭스에서 현재 X축 확대 배율을 추출
        const double originalWidth = 150.0;
        const double originalHeight = 40.0;
        return Stack(
          children: [
            Positioned(
              width: originalWidth / currentScale,
              height: originalHeight / currentScale * 2,
              child: CompositedTransformFollower(
                targetAnchor: Alignment.bottomCenter,
                followerAnchor: Alignment.topCenter,
                link: _layerLink,
                showWhenUnlinked: false,
                offset: const Offset(0, 0), // 버튼 기준 위젯이 뜰 위치 (X축, Y축)
                child: TapRegion(
                  onTapOutside: (event) {
                    _currentEntry?.remove();
                    _currentEntry = null;
                    //behavior: HitTestBehavior.opaque,
                  },

                  child: Material(
                    color: Colors.transparent,
                    child: Column(
                      children: [
                        Flexible(
                          child: Row(
                            children: [
                              Flexible(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    fixedSize: Size(
                                      originalWidth / currentScale,
                                      originalHeight / currentScale,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 0.0,
                                      vertical: 0.0,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        15 / currentScale,
                                      ),
                                    ),
                                    side: BorderSide(width: 1.0 / currentScale),
                                    backgroundColor: Colors.white,
                                    textStyle: TextStyle(
                                      fontSize: 20 / currentScale,
                                    ),
                                  ),
                                  onPressed: () {
                                    onDepartureSelected(station);
                                    PathFinder(
                                      station: station,
                                    ).setDepartureStation();
                                    dismiss();
                                  },
                                  child: Text('From'),
                                  //icon: const Icon(Icons.close_rounded),
                                ),
                              ),
                              Flexible(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    fixedSize: Size(
                                      originalWidth / currentScale,
                                      originalHeight / currentScale,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 0.0,
                                      vertical: 0.0,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        15 / currentScale,
                                      ),
                                    ),
                                    side: BorderSide(width: 1.0 / currentScale),
                                    backgroundColor: Colors.white,
                                    textStyle: TextStyle(
                                      fontSize: 20 / currentScale,
                                    ),
                                  ),
                                  onPressed: () {
                                    onArrivalSelected(station);
                                    PathFinder(
                                      station: station,
                                    ).setArrivalStation();
                                    dismiss();
                                  },
                                  child: Text('To'),
                                  //icon: const Icon(Icons.close_rounded),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Flexible(
                          child: Row(
                            children: [
                              Flexible(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    fixedSize: Size(
                                      originalWidth / currentScale,
                                      originalHeight / currentScale,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 0.0,
                                      vertical: 0.0,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        15 / currentScale,
                                      ),
                                    ),
                                    side: BorderSide(width: 1.0 / currentScale),
                                    backgroundColor: Colors.white,
                                    textStyle: TextStyle(
                                      fontSize: 20 / currentScale,
                                    ),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  onPressed: () {
                                    onTransferSelected(station);
                                    PathFinder(
                                      station: station,
                                    ).setTransferStation();
                                    dismiss();
                                  },
                                  child: Text('Via'),
                                  //icon: const Icon(Icons.close_rounded),
                                ),
                              ),
                              Flexible(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    fixedSize: Size(
                                      originalWidth / currentScale,
                                      originalHeight / currentScale,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 0.0,
                                      vertical: 0.0,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        15 / currentScale,
                                      ),
                                    ),
                                    side: BorderSide(width: 1.0 / currentScale),
                                    backgroundColor: Colors.white,
                                    textStyle: TextStyle(
                                      fontSize: 20 / currentScale,
                                    ),
                                  ),
                                  onPressed: () {
                                    dismiss();
                                    onStationInformationSelected(station);
                                  },
                                  child: Text('Info'),
                                  //icon: const Icon(Icons.close_rounded),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  height: 120,
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top ,
                    left: 16,
                    right: 16,
                  ),
                  color: Colors.white,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: station.color,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.subway_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              station.englishName,
                              style: const TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF101B36),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              station.name,
                              style: const TextStyle(
                                color: Color(0xFF68748E),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
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

class DepartFlag extends StatefulWidget {
  const DepartFlag({
    super.key,
    required this._transformationController,
    required this.station,
  });
  final TransformationController _transformationController;
  final Station? station;
  @override
  State<DepartFlag> createState() => _DepartFlagState();
}

class _DepartFlagState extends State<DepartFlag> {
  @override
  void initState() {
    super.initState();
    currentScale = widget._transformationController.value.row0.x;
    widget._transformationController.addListener(_onTransformationChanged);
  }

  void _onTransformationChanged() {
    // 컨트롤러의 매트릭스에서 현재 X축 확대 배율을 추출
    setState(() {
      currentScale = widget._transformationController.value.row0.x;
    });
  }

  double currentScale = 1.0;
  double originalWidth = 40.0;
  double originalHeight = 40.0;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.station!.x * _mapSize - originalWidth / currentScale / 2,
      top: widget.station!.y * _mapSize - originalHeight / currentScale,
      width: originalWidth / currentScale,
      height: originalHeight / currentScale,
      child: IgnorePointer(
        ignoring: true,
        child: Transform.translate(
          offset: Offset(0.0, 3.5 / currentScale),
          child: Icon(Icons.location_on, size: originalHeight / currentScale),
        ),
      ),
    );
  }

  @override
  void dispose() {
    widget._transformationController.removeListener(_onTransformationChanged);
    super.dispose();
  }
}

class ArriveFlag extends StatefulWidget {
  const ArriveFlag({
    super.key,
    required this._transformationController,
    required this.station,
  });
  final TransformationController _transformationController;
  final Station? station;
  @override
  State<ArriveFlag> createState() => _ArriveFlagState();
}

class _ArriveFlagState extends State<ArriveFlag> {
  @override
  void initState() {
    super.initState();
    currentScale = widget._transformationController.value.row0.x;
    widget._transformationController.addListener(_onTransformationChanged);
  }

  void _onTransformationChanged() {
    // 컨트롤러의 매트릭스에서 현재 X축 확대 배율을 추출

    setState(() {
      currentScale = widget._transformationController.value.row0.x;
    });
  }

  double currentScale = 1.0;
  double originalWidth = 40.0;
  double originalHeight = 40.0;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.station!.x * _mapSize - originalWidth / currentScale / 2,
      top: widget.station!.y * _mapSize - originalHeight / currentScale,
      width: originalWidth / currentScale,
      height: originalHeight / currentScale,
      child: IgnorePointer(
        ignoring: true,
        child: Transform.translate(
          offset: Offset(0.0, 3.5 / currentScale),
          child: Icon(Icons.location_off, size: originalHeight / currentScale),
        ),
      ),
    );
  }

  @override
  void dispose() {
    widget._transformationController.removeListener(_onTransformationChanged);
    super.dispose();
  }
}

class TransferFlag extends StatefulWidget {
  const TransferFlag({
    super.key,
    required this._transformationController,
    required this.station,
  });
  final TransformationController _transformationController;
  final Station? station;
  @override
  State<TransferFlag> createState() => _TransferFlagState();
}

class _TransferFlagState extends State<TransferFlag> {
  @override
  void initState() {
    super.initState();
    currentScale = widget._transformationController.value.row0.x;
    print(currentScale);
    widget._transformationController.addListener(_onTransformationChanged);
  }

  void _onTransformationChanged() {
    // 컨트롤러의 매트릭스에서 현재 X축 확대 배율을 추출

    setState(() {
      currentScale = widget._transformationController.value.row0.x;
    });
  }

  double currentScale = 1.0;
  double originalWidth = 40.0;
  double originalHeight = 40.0;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.station!.x * _mapSize - originalWidth / currentScale / 2,
      top: widget.station!.y * _mapSize - originalHeight / currentScale,
      width: originalWidth / currentScale,
      height: originalHeight / currentScale,
      child: IgnorePointer(
        ignoring: true,
        child: Transform.translate(
          offset: Offset(0.0, 3.5 / currentScale),
          child: Icon(
            Icons.add_location_rounded,
            size: originalHeight / currentScale,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    widget._transformationController.removeListener(_onTransformationChanged);
    super.dispose();
  }
}

class PathFinder {
  PathFinder({required this.station});

  Station station;

  // 현재 화면에 표시 중인 OverlayEntry를 저장하는 변수
  static OverlayEntry? _currentEntry;
  static String? departureStation;
  static String? arrivalStation;
  static String transferStation = '';
  List<String> _dataList = [];
  bool _isLoading = false; // 로딩 상태 기억용 변수

  void setDepartureStation() {
    if (departureStation == station.name) {
      departureStation = null;
    } else {
      departureStation = station.name;
      if (departureStation != null && arrivalStation != null) {
        loadData();
      }
    }
  }

  void setArrivalStation() {
    if (arrivalStation == station.name) {
      arrivalStation = null;
    } else {
      arrivalStation = station.name;
      if (departureStation != null && arrivalStation != null) {
        loadData();
      }
    }
  }

  void setTransferStation() {
    if (transferStation == station.name) {
      transferStation = '';
      if (departureStation != null && arrivalStation != null) {
        loadData();
      }
    } else {
      transferStation = station.name;
      if (departureStation != null && arrivalStation != null) {
        loadData();
      }
    }
  }

  Future<void> loadData() async {
    _isLoading = true; // 로딩 시작

    try {
      // FutureBuilder 없이 await로 결과를 일반 변수에 바로 대입!
      List<String> result = await SeoulApiService.fetchPublicXmlData(
        DepartureStation: departureStation,
        ArrivalStation: arrivalStation,
        TransferStation: transferStation,
      );

      _dataList = result; // 받아온 진짜 데이터를 변수에 저장
      _isLoading = false; // 로딩 완료
    } catch (e) {
      _isLoading = false;

      // 에러 처리 (예: 스낵바 띄우기)
      /*ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('데이터를 가져오지 못했습니다: $e')));*/
    }
  }

  OverlayEntry? show(
    BuildContext context,

    TransformationController _transformationController,
    LayerLink _layerLink,
  ) {
    dismiss();

    // 2. 새로운 OverlayEntry를 생성합니다.
    _currentEntry = OverlayEntry(
      builder: (context) {
        final double currentScale = _transformationController
            .value
            .row0
            .x; // 컨트롤러의 매트릭스에서 현재 X축 확대 배율을 추출
        const double originalWidth = 40.0;
        const double originalHeight = 40.0;
        return Positioned(
          width: originalWidth / currentScale,
          height: originalHeight / currentScale,
          child: IgnorePointer(
            ignoring: true,
            child: CompositedTransformFollower(
              targetAnchor: Alignment.bottomCenter,
              followerAnchor: Alignment.bottomCenter,
              link: _layerLink,
              showWhenUnlinked: false,
              offset: const Offset(0, -10), // 버튼 기준 위젯이 뜰 위치 (X축, Y축)
              child: Icon(Icons.add_location_rounded, size: 30 / currentScale),
            ),
          ),
        );
      },
    );

    // 3. 현재 화면의 Overlay에 삽입합니다.
    return _currentEntry;
  }

  /// 현재 표시 중인 오버레이를 제거합니다.
  static void dismiss() {
    if (_currentEntry != null) {
      _currentEntry!.remove();
      _currentEntry = null;
      print('OverlayEntry Remove함');
    }
  }
}
