import '../models/models.dart';

class FakeRepo {
  static final List<StoryProject> projects = [
    StoryProject(
      id: 'p1',
      title: '승자와 패자',
      logline: '금수저 vs 노력파, 그리고 권력의 균열',
      protagonistName: '정수',
      baseScenario:
          '신용호는 금수저로 탄탄한 배경을 바탕으로 승승장구한다. 정수는 더 치열하게 노력해 더 좋은 대학을 가고, 그의 자식이 검사가 되어 신용호의 불법 요소를 파고든다.',
      episodes: [
        Episode(
          number: 1,
          title: '1화: 첫 균열',
          content:
              '파일럿 1화(샘플)입니다.\n\n정수는 오늘도 도서관에서 밤을 새웠다. 반면 신용호는 부회장실에서 커피를 한 모금 마시며 웃었다...\n\n(이 내용은 나중에 AI로 교체됩니다.)',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          userRequest: '기본 생성',
          scenarioInput: '기본 뼈대 기반으로 1화 시작',
          tone: Tone.normal,
        ),
      ],
    ),
  ];
}
