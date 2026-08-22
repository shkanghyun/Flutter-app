import 'package:flutter/material.dart';

class timeTableSheet extends StatefulWidget {
  const timeTableSheet({super.key});

  @override
  State<timeTableSheet> createState() => _timeTableSheetState();
}

class _timeTableSheetState extends State<timeTableSheet> {
  // 1. 페이지를 제어할 컨트롤러 생성
  final PageController _pageController = PageController();

  @override
  void dispose() {
    // 2. 위젯이 사라질 때 컨트롤러를 메모리에서 해제 (메모리 누수 방지)
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicator: BoxDecoration(),
            tabs: [
              SizedBox(width: 50, child: Tab(text: '추천')),
              SizedBox(width: 50, child: Tab(text: '구독')),
            ],
             dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
          ),
        ),
        body: Stack(
          children: [
            // 배경에 깔리는 PageView
            PageView(
              controller: _pageController, // 컨트롤러 연결
              children: [
                Container(
                  color: Colors.amber,
                  child: const Center(child: Text('첫 번째 페이지')),
                ),
                Container(
                  color: Colors.lightBlue,
                  child: const Center(child: Text('두 번째 페이지')),
                ),
                Container(
                  color: Colors.green,
                  child: const Center(child: Text('세 번째 페이지')),
                ),
              ],
            ),

            // 화면 하단에 버튼 배치
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 이전 버튼
                  ElevatedButton(
                    onPressed: () {
                      // 3. 이전 페이지로 부드럽게 이동
                      _pageController.previousPage(
                        duration: const Duration(
                          milliseconds: 300,
                        ), // 넘어가는 시간 (0.3초)
                        curve: Curves.easeInOut, // 애니메이션 효과
                      );
                    },
                    child: const Text('이전'),
                  ),

                  // 다음 버튼
                  ElevatedButton(
                    onPressed: () {
                      // 4. 다음 페이지로 부드럽게 이동
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: const Text('다음'),
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
