import 'package:flutter/material.dart';
import 'package:subway/api_service.dart';
import 'package:subway/stations.dart';

class TimeTableSheet extends StatefulWidget {
  final Station station;
  const TimeTableSheet({super.key, required this.station});

  @override
  State<TimeTableSheet> createState() => TimeTableSheetState();
}

class TimeTableSheetState extends State<TimeTableSheet> {
  bool _isLoading = false; // 로딩 상태 기억용 변수
  List<String> lineList=[];

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
      List<String> result = await StationNameApiService.fetchPublicXmlData(
        stationName: widget.station.name,
      );

      setState(() {
        lineList = result; // 받아온 진짜 데이터를 변수에 저장
        lineList.sort((a, b) {
          // 라인 순서대로 정렬 (Line1->9->이외)
          bool hasTargetA = a.startsWith('Line');
          bool hasTargetB = b.startsWith('Line');

          if (hasTargetA && !hasTargetB) return -1; // a를 맨 앞으로
          if (!hasTargetA && hasTargetB) return 1; // b를 맨 앞으로
          return a.compareTo(b);
        });
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

  int selectedIndex = 0;
  @override
  void dispose() {
    // 2. 위젯이 사라질 때 컨트롤러를 메모리에서 해제 (메모리 누수 방지)
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      key: ValueKey(lineList.length),
      length: lineList.length,
      child: Scaffold(
        appBar: AppBar(
          title: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicator: BoxDecoration(),
            tabs: lineList
                .map((title) => SizedBox(width: 50, child: Tab(text: title)))
                .toList(),
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
          ),
        ),
        body: Column(
          children: [
            Flexible(
              child: Row(
                children: [
                  SizedBox(width: 15),
                  Flexible(child: Text('weekday')),
                  Flexible(
                    child: Checkbox(
                      value: selectedIndex == 0,
                      onChanged: (bool? value) {
                        if (selectedIndex == 0) return;
                        setState(() {
                          selectedIndex = 0;
                        });
                      },
                    ),
                  ),
                  SizedBox(width: 10),
                  Flexible(child: Text('saturday')),
                  Flexible(
                    child: Checkbox(
                      value: selectedIndex == 1,
                      onChanged: (bool? value) {
                        if (selectedIndex == 1) return;
                        setState(() {
                          selectedIndex = 1;
                        });
                      },
                    ),
                  ),
                  SizedBox(width: 10),
                  Flexible(child: Text('holiday')),
                  Flexible(
                    child: Checkbox(
                      value: selectedIndex == 2,
                      onChanged: (bool? value) {
                        if (selectedIndex == 2) return;
                        setState(() {
                          selectedIndex = 2;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: TabBarView(
                children: lineList.map((title) {
                  return ListView(
                    children: [
                      Text(
                        '🔥 $title 콘텐츠 화면입니다.',
                        style: const TextStyle(fontSize: 20),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
