import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';
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
                  groupId: 'my_group',
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
              child: TapRegion(
                groupId: 'my_group',
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    height: 130,
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top,
                      left: 16,
                      right: 16,
                    ),
                    color: Colors.white,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                station.englishName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
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
                        const SizedBox(width: 16),
                        ConstrainedBox(
                          //width: 100,
                          //height: 80,
                          constraints: const BoxConstraints(
                            minHeight: 80,
                            minWidth: 80,
                          ),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 80),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (var line in station.lines)
                                  Text(
                                    line.name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: line.color,
                                    ),
                                    maxLines: 1,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
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

class AutoMarqueeText extends StatelessWidget {
  final String text;
  final TextStyle style;

  const AutoMarqueeText({super.key, required this.text, required this.style});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 1. 텍스트가 차지할 실제 가로 길이를 계산합니다.
        final textPainter = TextPainter(
          text: TextSpan(text: text, style: style),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: double.infinity);

        // 2. 텍스트 길이가 부모 박스의 최대 가로 폭(constraints.maxWidth)보다 긴지 확인
        final isOverflowing = textPainter.size.width > constraints.maxWidth;

        // 3. 길면 Marquee를, 짧으면 일반 Text 위젯을 반환합니다.
        if (isOverflowing) {
          return SizedBox(
            height: textPainter.size.height + 10, // 텍스트 높이에 맞게 조절
            child: Marquee(
              text: text,
              style: style,
              blankSpace: 20.0, // 반복 공백
              velocity: 30.0, // 속도
            ),
          );
        } else {
          return Text(text, style: style, maxLines: 1);
        }
      },
    );
  }
}
