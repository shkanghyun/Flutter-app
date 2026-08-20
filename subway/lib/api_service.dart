import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml; // XML 패키지 임포트
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:subway/translate.dart';

class SubwayApiService {
  static Future<List<List<String>>> fetchPublicXmlData(
    String stationName,
  ) async {
    final String serviceKey = '6b4f495a6773686b3639514c624a65';
    String url =
          'http://swopenAPI.seoul.go.kr/api/subway/$serviceKey/xml/realtimeStationArrival/0/30/$stationName';
    //  XML 전용 API 주소를 입력하세요.
    if (stationName == '서울역') {
      url =
          'http://swopenAPI.seoul.go.kr/api/subway/$serviceKey/xml/realtimeStationArrival/0/30/서울';
    }

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        print('response.statusCode : 200');
        print(url);
        // 1. 깨짐 방지를 위해 UTF-8로 변환한 XML 문자열 확보
        final String decodedBody = utf8.decode(response.bodyBytes);

        // 2. 문자열을 XML 문서 객체로 파싱(해석)
        final document = xml.XmlDocument.parse(decodedBody);

        final items = document.findAllElements(
          'row',
        ); // document.findAllElements('태그명')을 쓰면 깊이에 상관없이 해당 이름을 가진 모든 태그를 찾습니다.

        List<List<String>> results = [];
        for (var item in items) {
          // element.findElements('태그명')은 현재 요소의 바로 다음 단계 자식 노드에서만 검색합니다.
          final lineList = item.findElements('subwayList').first.innerText;
          final lineId = item.findElements('subwayId').first.innerText;
          final headingTo = item.findElements('trainLineNm').first.innerText;
          final trainType = item.findElements('btrainSttus').first.innerText;
          final finalStation = item.findElements('bstatnNm').first.innerText;
          final arvlMsg = item.findElements('arvlMsg2').first.innerText;
          final trainAt = item.findElements('arvlMsg3').first.innerText;
          final trainOn = item.findElements('arvlCd').first.innerText;

          String line = switch (lineId) {
            '1001' => 'Line 1',
            '1002' => 'Line 2',
            '1003' => 'Line 3',
            '1004' => 'Line 4',
            '1005' => 'Line 5',
            '1006' => 'Line 6',
            '1007' => 'Line 7',
            '1008' => 'Line 8',
            '1009' => 'Line 9',
            '1061' => 'Jungang Line',
            '1063' => 'Gyeongui·Jungang Line',
            '1065' => 'Airport Railroad',
            '1067' => 'Gyuongchun Line',
            '1075' => 'Suin·Bundang Line',
            '1077' => 'Shinbundang Line',
            '1092' => 'Ui Sinseol Line',
            '1093' => 'Seohae Line',
            '1094' => 'Sillim Line',
            '1081' => 'Gyeonggang Line',
            '1032' => 'GTX-A',
            _ => '?', // 지정된 값이 이외의 값이 들어오면 반환하는 값
          };

          List<String> heading = headingTo.split(' - ');
          String nextStation = heading[1];                                       // '..방면' 추출

          String enFinalStation = translateStationName(finalStation);            

          String enNextStation = '';
          if (nextStation.length >= 2) {
            String nextStationChopped = nextStation.split('방면').first;
            enNextStation = translateStationName(nextStationChopped);
          }

          String enArvlMsg = translateArrivalInfo(arvlMsg);

          results.add([
            line,
            'toward $enNextStation',
            'bound for $enFinalStation',
            enArvlMsg,
            trainAt,
            trainType,
            lineList,
          ]);
        }
        print('API.dart result: $results');
        return results; // 추출한 데이터 리스트 반환
      } else {
        throw Exception('데이터 로드 실패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('네트워크 또는 XML 파싱 오류: $e');
    }
  }
}

class SeoulApiService {
  static Future<List<String>> fetchPublicXmlData({
    required String? DepartureStation,
    required String? ArrivalStation,
    String? TransferStation,
  }) async {
    final String serviceKey = '4f6d59565373686b39335a4e696348';
    String formattedDate = DateFormat(
      'yyyy-MM-dd HH:mm:ss',
    ).format(DateTime.now());

    //  XML 전용 API 주소
    final String url =
        'http://openapi.seoul.go.kr:8088/$serviceKey/xml/getShtrmPath/1/5/$DepartureStation/$ArrivalStation/$formattedDate///$TransferStation';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        print('response.statusCode : 200');
        print(url);
        // 1. 깨짐 방지를 위해 UTF-8로 변환한 XML 문자열 확보
        final String decodedBody = utf8.decode(response.bodyBytes);

        // 2. 문자열을 XML 문서 객체로 파싱(해석)
        final document = xml.XmlDocument.parse(decodedBody);

        // 3. 원하는 태그 찾기 (예: <item> 태그 내의 <stationName> 태그 데이터를 가져오고 싶을 때)
        // 💡 활용하시는 API 명세서상의 태그 이름으로 바꾸셔야 합니다!
        final items = document.findAllElements(
          'arvlStn',
        ); // document.findAllElements('태그명')을 쓰면 깊이에 상관없이 해당 이름을 가진 모든 태그를 찾습니다.

        List<String> results = [];
        for (var item in items) {
          // item 태그 내부에서 'stationName'이라는 태그의 텍스트 추출
          final stationName = item
              .findElements('stnNm')
              .first
              .innerText; // element.findElements('태그명')은 현재 요소의 바로 다음 단계 자식 노드에서만 검색합니다.
          results.add(stationName);
        }

        print('API.dart result: $results');
        return results; // 추출한 데이터 리스트 반환
      } else {
        throw Exception('데이터 로드 실패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('네트워크 또는 XML 파싱 오류: $e');
    }
  }
}
