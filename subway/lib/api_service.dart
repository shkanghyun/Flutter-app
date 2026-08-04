import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml; // XML 패키지 임포트

class ApiService {
  // XML 데이터를 파싱하여 결과 문자열 리스트로 반환하는 함수
  static Future<List<String>> fetchPublicXmlData() async {
    final String serviceKey = '6b4f495a6773686b3639514c624a65';
    //  XML 전용 API 주소를 입력하세요.
    final String url = 'http://swopenAPI.seoul.go.kr/api/subway/$serviceKey/xml/realtimeStationArrival/0/5/서울';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // 1. 깨짐 방지를 위해 UTF-8로 변환한 XML 문자열 확보
        final xmlString = http.Response.bytes(response.bodyBytes, 200).body;

        // 2. 문자열을 XML 문서 객체로 파싱(해석)
        final document = xml.XmlDocument.parse(xmlString);

        // 3. 원하는 태그 찾기 (예: <item> 태그 내의 <stationName> 태그 데이터를 가져오고 싶을 때)
        // 💡 활용하시는 API 명세서상의 태그 이름으로 바꾸셔야 합니다!
        final items = document.findAllElements('item');
        
        List<String> results = [];
        for (var item in items) {
          // item 태그 내부에서 'stationName'이라는 태그의 텍스트 추출
          final stationName = item.findElements('stationName').first.innerText;
          results.add(stationName);
        }

        return results; // 추출한 데이터 리스트 반환
      } else {
        throw Exception('데이터 로드 실패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('네트워크 또는 XML 파싱 오류: $e');
    }
  }
}