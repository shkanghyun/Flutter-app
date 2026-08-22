import 'package:flutter/material.dart';

class TimeTableSheet extends StatefulWidget {
  const TimeTableSheet({super.key});

  @override
  State<TimeTableSheet> createState() => TimeTableSheetState();
}

class TimeTableSheetState extends State<TimeTableSheet> {
  // 1. 페이지를 제어할 컨트롤러 생성
  final PageController _pageController = PageController();
  int selectedIndex = 0;
  @override
  void dispose() {
    // 2. 위젯이 사라질 때 컨트롤러를 메모리에서 해제 (메모리 누수 방지)
    _pageController.dispose();
    super.dispose();
  }

  List<String> lineList = ['line1', 'line5', 'line7', 'suinbundang'];

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
