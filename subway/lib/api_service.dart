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
          String nextStation = heading[1]; // '..방면' 추출

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

class StationNameApiService {
  static Future<List<List<String>>> fetchPublicXmlData({
    required String stationName,
  }) async {
    final String serviceKey =
        'kA3Tj4EZj6vNZpawfuh1yc1CTp%2B9Rnkfx%2BeHgtj2SmKJnf1SYW00SL%2FIhZPtwuBMuoK%2FOXkCcfCmIQoUWTaCPA%3D%3D';

    //  XML 전용 API 주소
    final String url =
        'https://apis.data.go.kr/1613000/SubwayInfo/GetKwrdFndSubwaySttnList?serviceKey=$serviceKey&pageNo=1&numOfRows=20&_type=xml&subwayStationName=$stationName';

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
          'item',
        ); // document.findAllElements('태그명')을 쓰면 깊이에 상관없이 해당 이름을 가진 모든 태그를 찾습니다.

        List<List<String>> results = [];
        for (var item in items) {
          // item 태그 내부에서 'subwayRouteName'이라는 태그의 텍스트 추출
          final stationLine = item
              .findElements('subwayRouteName')
              .first
              .innerText; // element.findElements('태그명')은 현재 요소의 바로 다음 단계 자식 노드에서만 검색합니다.
          final stationId = item
              .findElements('subwayStationId')
              .first
              .innerText;
          final stationNm = item
              .findElements('subwayStationName')
              .first
              .innerText;

          String enStationLine = switch (stationLine) {
            '1호선' => 'Line 1',
            '2호선' => 'Line 2',
            '3호선' => 'Line 3',
            '4호선' => 'Line 4',
            '5호선' => 'Line 5',
            '6호선' => 'Line 6',
            '7호선' => 'Line 7',
            '8호선' => 'Line 8',
            '9호선' => 'Line 9',
            '경의중앙' => 'Gyeongui·Jungang Line',
            '공항' => 'Airport Railroad',
            '경춘' => 'Gyuongchun Line',
            '수인분당' => 'Suin·Bundang Line',
            '신분당' => 'Shinbundang Line',
            '우이신설' => 'Ui Sinseol Line',
            '서해선' => 'Seohae Line',
            '신림선' => 'Sillim Line',
            '경강' => 'Gyeonggang Line',
            'GTX-A' => 'GTX-A',
            '에버라인' => 'Yongin Everline',
            '김포골드라인' => 'Gimpo Goldline',
            '인천1호선' => 'Incheon Line 1',
            '인천2호선' => 'Incheon Line 2',
            '의정부' => 'Uijeongbu Lrt',
            '자기부상' => 'Maglev Line',
            _ => '?', // 지정된 값이 이외의 값이 들어오면 반환하는 값
          };
          if (stationName == stationNm ||
              stationName == stationNm.split('(').first) {
            results.add([enStationLine, stationId, stationName]);
          }
        }

        print('station line list API result: $results');
        return results; // 추출한 데이터 리스트 반환
      } else {
        throw Exception('데이터 로드 실패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('네트워크 또는 XML 파싱 오류: $e');
    }
  }
}

class StationScheduleApiService {
  static Future<List<List<String>>> fetchPublicXmlData({
    required String? stationId,
    required String? dailyTypeCode,
    required String? upDownTypeCode,
    required String? stationName,
    required String enLine,
  }) async {
    final String serviceKey =
        'kA3Tj4EZj6vNZpawfuh1yc1CTp%2B9Rnkfx%2BeHgtj2SmKJnf1SYW00SL%2FIhZPtwuBMuoK%2FOXkCcfCmIQoUWTaCPA%3D%3D';

    //  XML 전용 API 주소
    final String url =
        'https://apis.data.go.kr/1613000/SubwayInfo/GetSubwaySttnAcctoSchdulList?serviceKey=$serviceKey&pageNo=1&numOfRows=10&_type=json&subwayStationId=$stationId&dailyTypeCode=$dailyTypeCode&upDownTypeCode=$upDownTypeCode';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        print('response.statusCode : 200');
        print(url);
        // 응답받은 문자열(Body)을 UTF-8 디코딩 후 JSON 객체로 파싱
        final Map<String, dynamic> jsonMap = jsonDecode(
          utf8.decode(response.bodyBytes),
        );

        // 3. 중첩된 계층 구조를 따라가며 'item' 리스트까지 접근
        final Map<String, dynamic> responseData = jsonMap['response'];
        final Map<String, dynamic> bodyData = responseData['body'];
        final Map<String, dynamic> itemsData = bodyData['items'];

        // 'item' 키 안에 든 리스트를 가져옴
        final List<dynamic> itemList = itemsData['item'];

        List<List<String>> results = [];
        if (itemList.isNotEmpty) {
          for (var item in itemList) {
            String endStationName = '';

            String departureTime = item['depTime'];
            if (departureTime == '0') {
              departureTime = item['arrTime'];
            }
            if (item['endSubwayStationNm'] != null) {
              endStationName = item['endSubwayStationNm'];
            }
            String departureTimeFormatted = departureTime.substring(0, 4);
            if (departureTimeFormatted.startsWith("00")) {
              departureTimeFormatted =
                  "24${departureTimeFormatted.substring(2)}";
            }
            results.add([departureTimeFormatted, endStationName]);
          }

          print('schedule API result: $results');

          return results; // 추출한 데이터 리스트 반환
        } else if (enLine.contains(RegExp(r'^Line\s\d$'))) {
          //국토교통부 API에 시간표 데이터 없을 경우 서울교통공사 API에서 시간표 받아오기
          List<dynamic> rawData = [];
          String stationCode = '';

          final String response = await rootBundle.loadString(
            'assets/data/seoul_stationname_code.json',
          );
          rawData = jsonDecode(response)['DATA'];

          var targetStation = rawData.firstWhere(
            (item) => item['station_nm'] == stationName,
            orElse: () => null,
          );
          if (targetStation != null) {
            stationCode = targetStation['station_cd'];
          }

          String weekTag = dailyTypeCode!.split('').last;
          String inoutTag = switch (upDownTypeCode) {
            'U' => '1',
            'D' => '2',
            _ => '?',
          };

          final String serviceKey = '4f6d59565373686b39335a4e696348';
          final String url =
              'http://openapi.seoul.go.kr:8088/$serviceKey/json/SearchSTNTimeTableByIDService/1/5/$stationCode/$weekTag/$inoutTag/';

          try {
            final response = await http.get(Uri.parse(url));
            print(url);

            if (response.statusCode == 200) {
              // 1. 깨짐 방지를 위해 UTF-8로 변환한 XML 문자열 확보
              final Map<String, dynamic> jsonMap = jsonDecode(
                utf8.decode(response.bodyBytes),
              );

              final Map<String, dynamic> responseData =
                  jsonMap['SearchSTNTimeTableByIDService'];
              final List<dynamic> itemList = responseData['row'];

              List<List<String>> results = [];
              if (itemList.isNotEmpty) {
                for (var item in itemList) {
                  String endStationName = '';

                  String departureTime = item['LEFTTIME'];
                  if (departureTime == '0') {
                    departureTime = item['ARRIVETIME'];
                  }
                  if (item['SUBWAYENAME'] != null) {
                    endStationName = item['SUBWAYENAME'];
                  }
                  String departureTimeFormatted = departureTime
                      .replaceAll(':', '')
                      .substring(0, 4);
                  if (departureTimeFormatted.startsWith("00")) {
                    departureTimeFormatted =
                        "24${departureTimeFormatted.substring(2)}";
                  }

                  results.add([departureTimeFormatted, endStationName]);
                }
              }

              print('station line list API result: $results');
              return results; // 추출한 데이터 리스트 반환
            } else {
              throw Exception('데이터 로드 실패: ${response.statusCode}');
            }
          } catch (e) {
            throw Exception('네트워크 또는 XML 파싱 오류: $e');
          }
        } else {
          Map<String, dynamic> rawData = {};

          final String response = await rootBundle.loadString(
            'assets/data/timetable_data.json',
          );
          rawData = jsonDecode(response)['stations'];

          final Map<String, dynamic> stationDataByName = rawData[stationName];
          final Map<String, dynamic> stationDataByLine =
              stationDataByName[enLine];
          final Map<String, dynamic> stationDataByUpDown =
              stationDataByLine[upDownTypeCode];
          final Map<String, dynamic> stationDataByWeekCode =
              stationDataByUpDown[dailyTypeCode];
          final List<dynamic> stationTimeTableData =
              stationDataByWeekCode['timetable'];

          for (var item in stationTimeTableData) {
            String endStationName = '';

            String departureTime = item['depTime'];
            if (departureTime == '0') {
              departureTime = item['arrTime'];
            }
            if (item['endSubwayStationNm'] != null) {
              endStationName = item['endSubwayStationNm'];
            }
            String departureTimeFormatted = departureTime
                .replaceAll(':', '')
                .substring(0, 4);
            if (departureTimeFormatted.startsWith("00")) {
              departureTimeFormatted =
                  "24${departureTimeFormatted.substring(2)}";
            }
            results.add([departureTimeFormatted, endStationName]);
          }

          //if (stationData != null) {}
          return results;
        }
      } else {
        throw Exception('데이터 로드 실패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('네트워크 또는 XML 파싱 오류: $e');
    }
  }
}
