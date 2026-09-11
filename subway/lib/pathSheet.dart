import 'package:flutter/material.dart';
import 'package:subway/stations.dart';

class PathSheet extends StatefulWidget {
  final List<List<String>> pathStations;
  const PathSheet({super.key, required this.pathStations});

  @override
  State<PathSheet> createState() => PathSheetState();
}

class PathSheetState extends State<PathSheet> {
  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.of(context).padding.bottom;

    // 기기의 물리적 상단 패딩 값 (픽셀 단위)
    final double physicalTopPadding = View.of(context).viewPadding.top;

    // 기기의 픽셀 밀도 (배율)
    final double devicePixelRatio = View.of(context).devicePixelRatio;

    // 상단 패딩을 뺀 화면의 높이
    double safeAreaHeight =
        MediaQuery.sizeOf(context).height -
        physicalTopPadding / devicePixelRatio;

    String duration = (int.parse(widget.pathStations[0][0]) ~/ 60)
        .toString(); // ~/ 나누고 나머지는 버림
    if (int.parse(widget.pathStations[0][0]) % 60 != 0) {
      duration =
          '${int.parse(widget.pathStations[0][0]) ~/ 60}~${int.parse(widget.pathStations[0][0]) ~/ 60 + 1}';
    }

    Set<String> forStationLineWidget = {};

    final List<List<String>> pathStationsSummary = [];

    for (int i = 1; i < widget.pathStations.length; i++) {
      // 1. 첫 번째 요소이거나, 앞의 요소와 값이 다르면 '연속 구간의 시작'이므로 추가
      if (i == 1 ||
          widget.pathStations[i][1] != widget.pathStations[i - 1][1]) {
        pathStationsSummary.add(widget.pathStations[i]);
      }
      // 2. 마지막 요소이거나, 뒤의 요소와 값이 다르면 '연속 구간의 끝'이므로 추가
      else if (i == widget.pathStations.length - 1 ||
          widget.pathStations[i][1] != widget.pathStations[i + 1][1]) {
        pathStationsSummary.add(widget.pathStations[i]);
      }
      // 3. 앞뒤가 모두 나와 같은 값이면 '연속 구간의 중간'이므로 무시(제거 효과)
    }

    forStationLineWidget.add(pathStationsSummary[0][1]);
    return DraggableScrollableSheet(
      expand: false,
      snap: true,
      initialChildSize: 0.9,
      minChildSize: 0.3,
      maxChildSize: safeAreaHeight / MediaQuery.sizeOf(context).height,
      snapSizes: const [0.9],
      builder: (BuildContext context, ScrollController scrollController) {
        return Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: CustomScrollView(
                controller: scrollController,
                slivers: [
                  const SliverPadding(padding: EdgeInsets.only(bottom: 10.0)),
                  SliverToBoxAdapter(
                    child: Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD9DFED),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SliverPadding(padding: EdgeInsets.only(bottom: 20.0)),
                  SliverToBoxAdapter(
                    child: Row(
                      //mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(width: 16.0),
                        Icon(Icons.access_time),
                        Text(' $duration minutes     '),
                        ImageIcon(
                          AssetImage('assets/icons/money_icon.png'),
                          size: 30, // 아이콘 크기 조절
                        ),
                        Text(' ${widget.pathStations[0][2]} won'),
                      ],
                    ),
                  ),
                  const SliverPadding(padding: EdgeInsets.only(bottom: 10.0)),
                  SliverToBoxAdapter(
                    child: IntrinsicHeight(child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Column(
                            //mainAxisSize: MainAxisSize.min,
                            children: [
                              _InfoCard(
                                stationName: pathStationsSummary[0][0],
                                lineName: pathStationsSummary[0][1],
                              ),

                              for (List<String> i in pathStationsSummary.skip(
                                1,
                              )) // 첫번째 역은 바로 표시 및 build에서 forStationLineWidget에 추가
                                if (forStationLineWidget.add(i[1])) ...[
                                  // 같은 라인이 들어가면 false가 반환
                                  Container(
                                    height: 40,
                                    alignment: Alignment.centerLeft,
                                    padding: const EdgeInsets.fromLTRB(
                                      9,
                                      0,
                                      14,
                                      0,
                                    ),
                                    margin: const EdgeInsets.fromLTRB(
                                      10,
                                      0,
                                      14,
                                      0,
                                    ),
                                    child: Text(
                                      'Transfer to ${i[1]}. (takes ${int.parse(i[2]) % 60 == 0 ? int.parse(i[2]) ~/ 60 : '${int.parse(i[2]) ~/ 60}~${int.parse(i[2]) ~/ 60 + 1}'} minutes)',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color.fromARGB(255, 75, 75, 75),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),

                                  _InfoCard(stationName: i[0], lineName: i[1]),
                                ] else if (forStationLineWidget.remove(i[1]))
                                  _InfoCard(stationName: i[0], lineName: i[1]),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 50,
                          child: CustomPaint(
                            painter: StraightArrowPainter(
                              color: Color.fromARGB(255, 81, 90, 110), // 원하는 색상 지정
                              thickness: 4.0, // 원하는 두께 지정
                            ),
                          ),
                        ),
                      ],
                    ),) 
                  ),

                  const SliverPadding(padding: EdgeInsets.only(bottom: 10.0)),
                  SliverToBoxAdapter(
                    child: _InfoCard(
                      stationName: pathStationsSummary[0][0],
                      lineName: pathStationsSummary[0][1],
                    ),
                  ),

                  for (List<String> i in pathStationsSummary.skip(
                    1,
                  )) // 첫번째 역은 바로 표시 및 build에서 forStationLineWidget에 추가
                    if (forStationLineWidget.add(i[1])) ...[
                      // 같은 라인이 들어가면 false가 반환
                      SliverToBoxAdapter(
                        child: Container(
                          height: 40,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.fromLTRB(9, 0, 14, 0),
                          margin: const EdgeInsets.fromLTRB(10, 0, 14, 0),
                          child: Text(
                            'Transfer to ${i[1]}. (takes ${int.parse(i[2]) % 60 == 0 ? int.parse(i[2]) ~/ 60 : '${int.parse(i[2]) ~/ 60}~${int.parse(i[2]) ~/ 60 + 1}'} minutes)',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color.fromARGB(255, 75, 75, 75),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: _InfoCard(stationName: i[0], lineName: i[1]),
                      ),
                    ] else if (forStationLineWidget.remove(i[1]))
                      SliverToBoxAdapter(
                        child: _InfoCard(stationName: i[0], lineName: i[1]),
                      ),

                  SliverToBoxAdapter(
                    child: Text(widget.pathStations.toString()),
                  ),
                ],
              ),
            ),

            /*const SizedBox(height: 18),
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
                children: [Text(widget.pathStations.toString())],
              ),
            ),*/
          ],
        );
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.stationName, required this.lineName});

  final String stationName;
  final String lineName;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFDFDFD),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      margin: const EdgeInsets.fromLTRB(10, 5, 0, 5),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stationName,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color.fromARGB(255, 81, 90, 110),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lineName,
                    style: TextStyle(
                      fontSize: 15,
                      color: lineById[lineName]!.color,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StraightArrowPainter extends CustomPainter {
  final Color color;
  final double thickness;

  StraightArrowPainter({
    this.color = Colors.blue, // 화살표 기본 색상
    this.thickness = 3.0, // 화살표 기본 두께
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final arrowPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
final padding = 10.0;
    // 💡 SizedBox의 크기(size)를 기반으로 좌표를 잡습니다.
    // 시작점: 가로 중앙의 맨 위
    final start = Offset(size.width / 2, padding);
    // 도착점: 가로 중앙의 맨 아래 (화살표 촉 크기만큼 약간 위에서 멈춤)
    final arrowSize = 12.0;
    final end = Offset(size.width / 2, size.height - arrowSize - padding);
    
    // 1. 세로 직선 그리기
    canvas.drawLine(start, end, linePaint);

    // 2. 아래를 향하는 삼각형 화살표 촉 그리기
    final path = Path();
    path.moveTo(end.dx, size.height - padding); // 진짜 맨 아래 꼭지점
    path.lineTo(end.dx - arrowSize / 1.5, size.height - padding- arrowSize); // 왼쪽 날개
    path.lineTo(end.dx + arrowSize / 1.5, size.height - padding- arrowSize); // 오른쪽 날개
    path.close();

    canvas.drawPath(path, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
