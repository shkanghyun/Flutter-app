import 'package:flutter/material.dart';

class MetroLine {
  const MetroLine(this.name, this.color);

  final String name;
  final Color color;
}

class Station {
  const Station({
    required this.name,
    required this.englishName,
    required this.x,
    required this.y,
    required this.lines,
    required this.transferNote,
    required this.nearby,
    required this.note,
  });

  final String name;
  final String englishName;
  final double x;
  final double y;
  final List<MetroLine> lines;
  final String transferNote;
  final String nearby;
  final String note;

  Color get color => lines.first.color;

  bool matches(String query) {
    if (query.isEmpty) return true;
    final normalized = query.toLowerCase();
    return name.toLowerCase().contains(normalized) ||
        englishName.toLowerCase().contains(normalized);
  }
}

const line1 = MetroLine('1호선', Color(0xFF1F4B99));
const line2 = MetroLine('2호선', Color(0xFF13A538));
const line3 = MetroLine('3호선', Color(0xFFF27822));
const line4 = MetroLine('4호선', Color(0xFF38A4D5));
const line5 = MetroLine('5호선', Color(0xFF8B4EBB));
const line6 = MetroLine('6호선', Color(0xFF9B4D31));
const line7 = MetroLine('7호선', Color(0xFF67772D));
const line8 = MetroLine('8호선', Color(0xFFE91B74));
const line9 = MetroLine('9호선', Color(0xFF9E9D92));
const airport = MetroLine('공항철도', Color(0xFF5AAFC3));
const gtxA = MetroLine('GTX-A', Color(0xFFAA4398));
const suinBundang = MetroLine('수인분당선', Color(0xFFF4BB38));
const gyeongui = MetroLine('경의중앙선', Color(0xFF73C5B4));

const stations = <Station>[
  Station(
    name: '서울역',
    englishName: 'Seoul Station',
    x: 0.570,
    y: 0.394,
    lines: [line1, line4, airport, gyeongui],
    transferNote: '1·4호선, 공항철도, 경의중앙선 환승 가능',
    nearby: '서울역 KTX, 롯데마트 서울역점, 서울로7017',
    note: '공항철도 직통열차와 일반열차를 이용할 수 있습니다.',
  ),
  Station(
    name: '홍대입구',
    englishName: 'Hongik Univ.',
    x: 0.402,
    y: 0.430,
    lines: [line2, airport, gyeongui],
    transferNote: '2호선, 공항철도, 경의중앙선 환승 가능',
    nearby: '홍익대학교, 연남동, 경의선숲길',
    note: '공항철도와 경의중앙선은 같은 역에서 환승합니다.',
  ),
  Station(
    name: '종로3가',
    englishName: 'Jongno 3(sam)-ga',
    x: 0.476,
    y: 0.334,
    lines: [line1, line3, line5],
    transferNote: '1·3·5호선 환승 가능',
    nearby: '익선동, 종묘, 인사동',
    note: '1호선과 3·5호선의 승강장 위치가 다르니 표지판을 확인하세요.',
  ),
  Station(
    name: '디지털미디어시티',
    englishName: 'Digital Media City',
    x: 0.282,
    y: 0.366,
    lines: [line6, airport, gyeongui],
    transferNote: '6호선, 공항철도, 경의중앙선 환승 가능',
    nearby: '상암 DMC, MBC, 월드컵공원',
    note: '공항철도 이용 시 인천공항 방면으로 이동할 수 있습니다.',
  ),
  Station(
    name: '여의도',
    englishName: 'Yeouido',
    x: 0.420,
    y: 0.581,
    lines: [line5, line9],
    transferNote: '5·9호선 환승 가능',
    nearby: '여의도공원, 더현대 서울, 국회의사당',
    note: '9호선 급행 정차역입니다.',
  ),
  Station(
    name: '고속터미널',
    englishName: 'Express Bus Terminal',
    x: 0.584,
    y: 0.629,
    lines: [line3, line7, line9],
    transferNote: '3·7·9호선 환승 가능',
    nearby: '서울고속버스터미널, 신세계백화점 강남점',
    note: '고속·시외버스 터미널과 연결됩니다.',
  ),
  Station(
    name: '강남',
    englishName: 'Gangnam',
    x: 0.664,
    y: 0.704,
    lines: [line2, suinBundang],
    transferNote: '2호선과 신분당선 환승 가능',
    nearby: '강남대로, 강남역 지하상가, 테헤란로',
    note: '신분당선은 별도 운임이 적용될 수 있습니다.',
  ),
  Station(
    name: '사당',
    englishName: 'Sadang',
    x: 0.508,
    y: 0.718,
    lines: [line2, line4],
    transferNote: '2·4호선 환승 가능',
    nearby: '사당역 버스환승센터, 관악산',
    note: '4호선 남태령·당고개 방면 승강장을 확인하세요.',
  ),
  Station(
    name: '잠실',
    englishName: 'Jamsil',
    x: 0.790,
    y: 0.571,
    lines: [line2, line8],
    transferNote: '2·8호선 환승 가능',
    nearby: '롯데월드, 롯데월드타워, 석촌호수',
    note: '대형 복합시설과 연결되어 주말에는 혼잡할 수 있습니다.',
  ),
  Station(
    name: '청량리',
    englishName: 'Cheongnyangni',
    x: 0.700,
    y: 0.255,
    lines: [line1, gyeongui, suinBundang, gtxA],
    transferNote: '1호선, 경의중앙선, 수인분당선, GTX-A 환승 가능',
    nearby: '청량리역 KTX, 롯데백화점 청량리점',
    note: '광역·일반 철도 이용객이 많은 복합 환승역입니다.',
  ),
];
