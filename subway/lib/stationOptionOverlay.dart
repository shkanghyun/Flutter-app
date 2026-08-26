import 'package:flutter/material.dart';
import 'package:subway/stations.dart';

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
                    top: MediaQuery.of(context).padding.top,
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
