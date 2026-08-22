import 'package:flutter/material.dart';

class TimeTableSheet extends StatefulWidget {
  const TimeTableSheet({super.key});

  @override
  State<TimeTableSheet> createState() => TimeTableSheetState();
}

class TimeTableSheetState extends State<TimeTableSheet> {
  // 1. 페이지를 제어할 컨트롤러 생성
  final PageController _pageController = PageController();

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
            tabs: lineList.map((title) => SizedBox(width: 50, child: Tab(text: title))).toList(),
             dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
          ),
        ),
        body: TabBarView(
          children: lineList.map((title) {
            return Center(
              child: Text('🔥 $title 콘텐츠 화면입니다.', style: const TextStyle(fontSize: 20)),
            );
          }).toList(),
        ),
      ),
    );
  }
}
