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
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD9DFED),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 18),
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
            ),
          ],
        );
      },
    );
  }
}
