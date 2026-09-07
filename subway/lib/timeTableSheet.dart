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
  List<List<String>> lineStationIdList = [];
  final Map<String, (List<List<String>>, List<List<String>>)> _pageCache = {};

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
      print('API 요청');
      List<List<String>> result =
          await StationNameApiService.fetchPublicXmlData(
            stationName: widget.station.name,
          );
      print('API 요청완료');
      setState(() {
        lineStationIdList = result; // 받아온 진짜 데이터를 변수에 저장
        lineStationIdList.sort((a, b) {
          // 라인 순서대로 정렬 (Line1->9->이외)
          bool hasTargetA = a[0].startsWith('Line');
          bool hasTargetB = b[0].startsWith('Line');

          if (hasTargetA && !hasTargetB) return -1; // a를 맨 앞으로
          if (!hasTargetA && hasTargetB) return 1; // b를 맨 앞으로
          return a[0].compareTo(b[0]);
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

  String selectedIndex = '01';
  @override
  void dispose() {
    // 2. 위젯이 사라질 때 컨트롤러를 메모리에서 해제 (메모리 누수 방지)
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      key: ValueKey(lineStationIdList.length),
      length: lineStationIdList.length,
      child: Scaffold(
        appBar: AppBar(
          title: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicator: BoxDecoration(),
            tabs: lineStationIdList
                .map((title) => SizedBox(child: Tab(text: title[0])))
                .toList(),
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
          ),
        ),
        body: Column(
          children: [
            Row(
              children: [
                SizedBox(width: 15),
                Flexible(child: Text('weekday')),
                Flexible(
                  child: Checkbox(
                    value: selectedIndex == '01',
                    onChanged: (bool? value) {
                      if (selectedIndex == '01') return;
                      setState(() {
                        selectedIndex = '01';
                      });
                    },
                  ),
                ),
                SizedBox(width: 10),
                Flexible(child: Text('saturday')),
                Flexible(
                  child: Checkbox(
                    value: selectedIndex == '02',
                    onChanged: (bool? value) {
                      if (selectedIndex == '02') return;
                      setState(() {
                        selectedIndex = '02';
                      });
                    },
                  ),
                ),
                SizedBox(width: 10),
                Flexible(child: Text('holiday')),
                Flexible(
                  child: Checkbox(
                    value: selectedIndex == '03',
                    onChanged: (bool? value) {
                      if (selectedIndex == '03') return;
                      setState(() {
                        selectedIndex = '03';
                      });
                    },
                  ),
                ),
              ],
            ),

            Expanded(
              child: TabBarView(
                children: lineStationIdList.map((lineStationId) {
                  return StationScheduleTab(
                    stationId: lineStationId[1],
                    dailyTypeCode: selectedIndex,
                    enLine: lineStationId[0],
                    stationName: lineStationId[2],
                    pageCache: _pageCache,
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

class StationScheduleTab extends StatefulWidget {
  final String stationId;
  final String dailyTypeCode;
  final String enLine;
  final String stationName;
  final Map<String, (List<List<String>>, List<List<String>>)> pageCache;

  const StationScheduleTab({
    super.key,
    required this.stationId,
    required this.dailyTypeCode,
    required this.enLine,
    required this.stationName,
    required this.pageCache,
  });

  @override
  StationScheduleTabState createState() => StationScheduleTabState();
}

class StationScheduleTabState extends State<StationScheduleTab> {
  late Future<(List<List<String>>, List<List<String>>)> _scheduleFuture;

  @override
  void initState() {
    super.initState();
    // initState에서 최초 1회만 API를 호출하여 상태를 보존합니다.
    _fetchCombinedData();
  }

  // 💡 부모 위젯이 변경되어 dailyTypeCode(selectedIndex)가 바뀔 때 실행됨
  @override
  void didUpdateWidget(covariant StationScheduleTab oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 이전 값과 새로운 값이 다를 때만 데이터를 다시 요청합니다.
    if (oldWidget.dailyTypeCode != widget.dailyTypeCode) {
      setState(() {
        _fetchCombinedData(); // 데이터 새로고침
      });
    }
  }

  void _fetchCombinedData() {
    // 💡 1. 고유한 캐시 키를 생성 (예: "STATION123_WEEKDAY")
    final cacheKey = '${widget.stationId}_${widget.dailyTypeCode}';

    // 💡 2. 이미 캐시에 데이터가 존재하는지 확인
    if (widget.pageCache.containsKey(cacheKey)) {
      // 이미 불러온 적이 있다면, 서버 요청 없이 기존 데이터를 Future.value로 즉시 반환
      _scheduleFuture = Future.value(widget.pageCache[cacheKey]);
      return;
    }
    // Future.wait를 사용해 두 서버에 동시에 병렬(Parallel) 요청을 보냄
    // Dart 3.0 이상부터는 아래처럼 Record 패턴을 사용하면 타입이 정확히 매칭되어 편리함
    _scheduleFuture =
        Future.wait([
          StationScheduleApiService.fetchPublicXmlData(
            stationId: widget.stationId,
            dailyTypeCode: widget.dailyTypeCode,
            upDownTypeCode: 'U',
            enLine: widget.enLine,
            stationName: widget.stationName,
          ),
          StationScheduleApiService.fetchPublicXmlData(
            stationId: widget.stationId,
            dailyTypeCode: widget.dailyTypeCode,
            upDownTypeCode: 'D',
            enLine: widget.enLine,
            stationName: widget.stationName,
          ),
        ]).then((results) {
          widget.pageCache[cacheKey] = (results[0], results[1]);

          // 첫 번째 결과와 두 번째 결과를 각각 알맞은 타입으로 묶어서 반환
          return (results[0], results[1]);
        });
  }

  Widget? buildTimetablePage(
    List<List<String>> serverUpData,
    List<List<String>> serverDownData,
    int i,
  ) {
    List<List<String>> result1 = serverUpData
        .where(
          (innerList) =>
              innerList[0].substring(0, 2) == i.toString().padLeft(2, '0'),
        )
        .toList();
    List<List<String>> result2 = serverDownData
        .where(
          (innerList) =>
              innerList[0].substring(0, 2) == i.toString().padLeft(2, '0'),
        )
        .toList();

    if (result1.isNotEmpty || result2.isNotEmpty) {
      return IntrinsicHeight(
        child: Row(
          children: [
            // 텍스트가 아무리 길어져도 화면 밖으로 터지지 않고 줄바꿈이 되도록 보호!
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var item in result1)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        '${item[0].substring(2)} ${item[1]}',
                        //maxLines: 1, // 한 줄로만 제한하고 싶을 때 (선택)
                        overflow: TextOverflow.ellipsis, // 말줄임표(...) 표시 (선택)
                      ),
                    ),
                ],
              ),
            ),
            Container(
              width: 40,
              color: Colors.blue.withAlpha(50),
              child: Center(child: Text(i.toString().padLeft(2, '0'))),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var item in result2)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        '${item[0].substring(2)} ${item[1]}',
                        //maxLines: 1, // 한 줄로만 제한하고 싶을 때 (선택)
                        overflow: TextOverflow.ellipsis, // 말줄임표(...) 표시 (선택)
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> lineUpdown = ['', ''];
    if (widget.enLine == 'Line 1' ||
        widget.enLine == 'Line 4' ||
        widget.enLine == 'Line 8' ||
        widget.enLine == 'Incheon Line 1' ||
        widget.enLine == 'Incheon Line 2' ||
        widget.enLine == 'Shillim Line' ||
        widget.enLine == 'Seohae Line') {
      lineUpdown = ['Upward', 'Downward'];
    }
    if (widget.enLine == 'Line 2') lineUpdown = ['Clockwise', 'CounterCW'];
    if (widget.enLine == 'Line 3' ||
        widget.enLine == 'Line 5' ||
        widget.enLine == 'Line 6') {
      lineUpdown = ['Leftward', 'Rightward'];
    }
    if (widget.enLine == 'Line 7') lineUpdown = ['RightUpward', 'LeftDownward'];
    if (widget.enLine == 'Line 9' || widget.enLine == 'Gyeongui·Jungang Line') {
      lineUpdown = ['Rightward', 'Leftward'];
    }
    if (widget.enLine == 'Suin·Bundang Line' ||
        widget.enLine == 'ShinBundang Line' ||
        widget.enLine == 'Airport Railroad' ||
        widget.enLine == 'Uijeongbu Lrt' ||
        widget.enLine == 'Ui Sinseol Line' ||
        widget.enLine == 'Gimpo Goldline' ||
        widget.enLine == 'Yongin EverLine' ||
        widget.enLine == 'Gyeongchun Line' ||
        widget.enLine == 'Gyeonggang Line' ||
        widget.enLine == 'GTX-A') {
      lineUpdown = ['Inbound', 'Outbound'];
    }

    return FutureBuilder<(List<List<String>>, List<List<String>>)>(
      future: _scheduleFuture, // 보존된 Future 사용
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('에러 발생: ${snapshot.error}'));
        }
        if (snapshot.hasData) {
          // 💡 구조 분해(Destructuring) 문법으로 깔끔하게 각 변수에 나눠 담습니다.
          final (serverUpData, serverDownData) = snapshot.data!;
          return ListView(
            children: [
              Row(
                children: [
                  // 텍스트가 아무리 길어져도 화면 밖으로 터지지 않고 줄바꿈이 되도록 보호!
                  Expanded(
                    child: Container(
                      //color: Colors.blue.withAlpha(50),
                      child: Center(child: Text(lineUpdown[0])),
                    ),
                  ),
                  Container(
                    width: 40,
                    color: Colors.blue.withAlpha(50),
                    child: Center(child: Text('Hr')),
                  ),
                  Expanded(
                    child: Container(
                      //color: Colors.blue.withAlpha(50),
                      child: Center(child: Text(lineUpdown[1])),
                    ),
                  ),
                ],
              ),
              Divider(
                thickness: 1.5, // 선의 두께
                height: 1.0, // 선이 차지하는 전체 위아래 영역 (0이나 1로 주면 여백이 최소화됩니다)
                color: Colors.grey[600], // 선의 색상
              ),
              for (int i = 2; i <= 24; i++)
                if (buildTimetablePage(serverUpData, serverDownData, i)
                    case Widget widget) ...[
                  widget,
                  const Divider(
                    thickness: 1.0, // 선의 두께
                    height: 1.0, // 선이 차지하는 전체 위아래 영역 (0이나 1로 주면 여백이 최소화됩니다)
                    color: Colors.grey, // 선의 색상
                  ),
                ],
              if (buildTimetablePage(serverUpData, serverDownData, 1)
                  case Widget widget) ...[
                widget,
                const Divider(
                  thickness: 1.0, // 선의 두께
                  height: 1.0, // 선이 차지하는 전체 위아래 영역 (0이나 1로 주면 여백이 최소화됩니다)
                  color: Colors.grey, // 선의 색상
                ),
              ],
            ],
          );
        }
        return const Center(child: Text('조회된 데이터가 없습니다.'));
      },
    );
  }
}
