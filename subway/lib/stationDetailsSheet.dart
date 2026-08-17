import 'package:flutter/material.dart';
import 'package:subway/api_service.dart';
import 'package:subway/stations.dart';

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
      List<String> result = await SeoulApiService.fetchPublicXmlData(
        widget.station.name,
      );

      setState(() {
        _dataList = result; // 받아온 진짜 데이터를 변수에 저장
        _isLoading = false; // 로딩 완료
      });
    } catch (e) {
      _isLoading = false;

      // 에러 처리 (예: 스낵바 띄우기)
      /*ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('데이터를 가져오지 못했습니다: $e')));*/
    }
  }

  @override
  Widget build(BuildContext context) {
    // 기기의 물리적 상단 패딩 값 (픽셀 단위)
    final double physicalTopPadding = View.of(context).viewPadding.top;

    // 기기의 픽셀 밀도 (배율)
    final double devicePixelRatio = View.of(context).devicePixelRatio;

    return SizedBox(
      height:
          MediaQuery.sizeOf(context).height -
          physicalTopPadding / devicePixelRatio,

      child: DraggableScrollableSheet(
        snap: true,

        //shouldCloseOnMinExtent: false,
        initialChildSize: 1.0,
        minChildSize: 0.0,
        //snapSizes: const [0.2, 0.3],
        //maxChildSize: 1.0,
        //expand: false,
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              fixedSize: const Size(50, 20),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 0.0,
                                vertical: 0.0,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: Text('출발'),
                            //icon: const Icon(Icons.close_rounded),
                          ),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              fixedSize: const Size(50, 20),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 0.0,
                                vertical: 0.0,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: Text('도착'),
                            //icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        //tooltip: '닫기',
                        style: ElevatedButton.styleFrom(
                          //fixedSize: const Size(50, 20),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 0.0,
                            vertical: 0.0,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text('경유'),
                        //icon: const Icon(Icons.close_rounded),
                      ),
                    ],
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

const _sectionTitle = TextStyle(
  fontSize: 15,
  fontWeight: FontWeight.w800,
  color: Color(0xFF101B36),
);
