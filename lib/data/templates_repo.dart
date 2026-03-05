import '../models/models.dart';

class TemplatesRepo {
  static const List<StoryTemplate> templates = [
    // =========================================================
    // DRAMA (5)
    // =========================================================
    StoryTemplate(
      id: 't_drama_01',
      genre: StoryGenre.drama,
      title: '승자와 패자',
      logline: '금수저 vs 노력파, 그리고 권력의 균열',
      skeleton:
          '신용호는 탄탄한 배경으로 승승장구한다. 정수는 이를 악물고 올라서며 가정을 지킨다. '
          '시간이 흐르고, 정수의 아이가 검사로 성장해 신용호의 주변을 파고든다. '
          '성공의 정점에서 균열이 시작된다.',
    ),
    StoryTemplate(
      id: 't_drama_02',
      genre: StoryGenre.drama,
      title: '담장 너머의 계약서',
      logline: '한 장의 문서가 관계를 갈라놓는다',
      skeleton:
          '협력사와의 계약이 갱신되는 날, 조항 하나가 조용히 바뀌어 있다. '
          '그 변경은 한 사람의 책임이 되고, 팀 전체의 신뢰가 흔들린다. '
          '누가 바꿨는지, 왜 지금인지, 답을 찾아야 한다.',
    ),
    StoryTemplate(
      id: 't_drama_03',
      genre: StoryGenre.drama,
      title: '회색 회의실',
      logline: '말보다 표정이 먼저 결론을 낸다',
      skeleton:
          '회의실의 공기가 무겁게 가라앉는다. 안건은 단순하지만, 이해관계는 복잡하다. '
          '짧은 침묵과 시선이 오가며, 한 사람이 고립된다. '
          '결정은 이미 내려진 듯 보이지만, 아직 뒤집을 여지가 남아 있다.',
    ),
    StoryTemplate(
      id: 't_drama_04',
      genre: StoryGenre.drama,
      title: '이름 없는 추천서',
      logline: '누군가의 한 줄이 인생을 바꾼다',
      skeleton:
          '지원서가 통과될 리 없다고 생각한 순간, 익명의 추천서가 도착한다. '
          '도움이었을까, 덫이었을까. '
          '추천서를 쓴 사람을 찾는 과정에서 과거의 빚과 관계가 드러난다.',
    ),
    StoryTemplate(
      id: 't_drama_05',
      genre: StoryGenre.drama,
      title: '유리 천장 아래',
      logline: '성장과 질투가 같은 속도로 커진다',
      skeleton:
          '성과는 분명히 쌓였는데, 평가는 늘 한 발 늦다. '
          '동료의 승진 소식이 들리고, 축하와 불편함이 동시에 밀려온다. '
          '다음 선택은 관계를 지킬지, 목표를 앞당길지로 갈린다.',
    ),

    // =========================================================
    // ROMANCE (5)
    // =========================================================
    StoryTemplate(
      id: 't_romance_01',
      genre: StoryGenre.romance,
      title: '비 오는 날의 계약',
      logline: '서로를 싫어하던 두 사람이 계약으로 엮인다',
      skeleton:
          '급하게 돈이 필요한 날, 완벽하지만 냉정한 사람이 나타난다. '
          '우연히 시작된 계약 관계는 사소한 일상 속에서 조금씩 흔들리기 시작한다. '
          '서로의 약한 부분을 보게 되는 순간, 관계의 정의가 바뀐다.',
    ),
    StoryTemplate(
      id: 't_romance_02',
      genre: StoryGenre.romance,
      title: '같은 시간대의 메시지',
      logline: '밤마다 도착하는 한 줄이 마음을 흔든다',
      skeleton:
          '매일 같은 시간, 알림이 울린다. 짧은 안부와 사소한 농담. '
          '처음엔 우연이라 생각하지만, 반복될수록 의미가 생긴다. '
          '만나야 할지, 계속 멀리서 지켜볼지 선택이 필요해진다.',
    ),
    StoryTemplate(
      id: 't_romance_03',
      genre: StoryGenre.romance,
      title: '서랍 속 영수증',
      logline: '잊고 있던 날짜가 다시 떠오른다',
      skeleton:
          '서랍을 정리하다 오래된 영수증 한 장이 나온다. 날짜와 장소가 선명하다. '
          '그 날의 말투, 표정, 공기가 되살아난다. '
          '연락을 해야 하는지, 그냥 덮어야 하는지 마음이 갈린다.',
    ),
    StoryTemplate(
      id: 't_romance_04',
      genre: StoryGenre.romance,
      title: '낮은 목소리의 약속',
      logline: '작게 한 말이 오래 남는다',
      skeleton:
          '사람이 많은 자리에서 낮게 속삭인 약속 하나가 마음을 붙잡는다. '
          '가벼운 말이었는지 확인하고 싶어지지만, 먼저 다가가기가 어렵다. '
          '거리와 타이밍이 계속 엇갈리며 감정이 깊어진다.',
    ),
    StoryTemplate(
      id: 't_romance_05',
      genre: StoryGenre.romance,
      title: '연습실의 불빛',
      logline: '같은 공간에서 조금씩 가까워진다',
      skeleton:
          '연습실에 남아 불을 끄려던 순간, 누군가가 들어온다. '
          '서로의 습관과 약점을 보게 되며 경계가 풀린다. '
          '호흡이 맞기 시작하면, 마음도 따라 움직인다.',
    ),

    // =========================================================
    // THRILLER (5)
    // =========================================================
    StoryTemplate(
      id: 't_thriller_01',
      genre: StoryGenre.thriller,
      title: '문 앞의 쪽지',
      logline: '사라진 사람, 그리고 혼자만 알아챈 단서',
      skeleton:
          '평범한 하루를 시작하려다 문 앞의 쪽지를 발견한다. '
          '쪽지에는 숨겨 둔 사실을 정확히 찌르는 내용이 적혀 있다. '
          '실종 사건이 일상과 연결되어 있고, 누군가 지켜보고 있다는 감각이 점점 선명해진다.',
    ),
    StoryTemplate(
      id: 't_thriller_02',
      genre: StoryGenre.thriller,
      title: '꺼지지 않는 알림',
      logline: '읽지 않았는데 읽힌다',
      skeleton:
          '메시지를 열지 않았는데 상대는 이미 읽었다고 말한다. '
          '통화기록, 위치기록, 사진의 메타데이터가 어긋나기 시작한다. '
          '단순 오류가 아니라는 확신이 들면서, 주변이 낯설어진다.',
    ),
    StoryTemplate(
      id: 't_thriller_03',
      genre: StoryGenre.thriller,
      title: '빈 좌석',
      logline: '늘 있던 사람이 없다',
      skeleton:
          '늘 같은 자리에 앉던 사람이 어느 날 보이지 않는다. '
          '주변은 아무렇지 않게 굴지만, 공기만 달라져 있다. '
          '작은 단서들을 따라가면, 사라진 이유가 예상보다 가까이에 있다.',
    ),
    StoryTemplate(
      id: 't_thriller_04',
      genre: StoryGenre.thriller,
      title: '검은 우산의 남자',
      logline: '비가 오면 나타난다',
      skeleton:
          '비가 오는 날마다 같은 우산이 시야에 걸린다. '
          '우연이라 넘기려 했지만, 동선이 정확히 겹친다. '
          '확인하려는 순간, 뒤에서 발소리가 멈춘다.',
    ),
    StoryTemplate(
      id: 't_thriller_05',
      genre: StoryGenre.thriller,
      title: '파일명: final_final_3',
      logline: '지워도 다시 생긴다',
      skeleton:
          '컴퓨터에 정체불명의 파일이 반복해서 생성된다. '
          '열어보면 기록은 없고, 대신 익숙한 문장 한 줄이 남아 있다. '
          '지우려 할수록 더 깊은 곳에서 다시 떠오른다.',
    ),

    // =========================================================
    // FANTASY (5)
    // =========================================================
    StoryTemplate(
      id: 't_fantasy_01',
      genre: StoryGenre.fantasy,
      title: '봉인된 규칙',
      logline: '규칙을 알면 살고, 모르면 죽는다',
      skeleton:
          '어느 날 낯선 공간에서 깨어난다. '
          '벽엔 단 하나의 규칙만 적혀 있다: “밤 12시엔 절대 거울을 보지 마라.” '
          '규칙을 어기는 순간, 세계가 처벌한다. '
          '살아남기 위해 규칙의 진짜 의미를 찾아야 한다.',
    ),
    StoryTemplate(
      id: 't_fantasy_02',
      genre: StoryGenre.fantasy,
      title: '균열의 지하철',
      logline: '한 정거장만 지나면 세계가 바뀐다',
      skeleton:
          '평소 타던 노선인데, 어느 날 안내 방송이 다르게 들린다. '
          '창밖 풍경이 한 번 흔들리더니 낯선 도시로 이어진다. '
          '되돌아가려면 ‘진짜 역명’을 찾아야 한다.',
    ),
    StoryTemplate(
      id: 't_fantasy_03',
      genre: StoryGenre.fantasy,
      title: '빛을 먹는 서점',
      logline: '책을 펼치면 현실이 얇아진다',
      skeleton:
          '낡은 서점에 들어서자 조명이 한 단계 어두워진다. '
          '책장을 넘길수록 주변의 소리가 사라지고, 문자들이 공중으로 뜬다. '
          '한 권을 끝까지 읽으면, 되돌릴 수 없는 선택이 열린다.',
    ),
    StoryTemplate(
      id: 't_fantasy_04',
      genre: StoryGenre.fantasy,
      title: '손목의 문양',
      logline: '표식은 능력이 아니라 부름이다',
      skeleton:
          '손목에 없던 문양이 생긴다. 만지면 미세하게 뜨겁다. '
          '같은 문양을 가진 사람들이 하나둘 눈에 띄기 시작한다. '
          '문양이 완성되는 순간, ‘호출’이 시작된다.',
    ),
    StoryTemplate(
      id: 't_fantasy_05',
      genre: StoryGenre.fantasy,
      title: '잠들지 못하는 마을',
      logline: '밤이 오지 않는다',
      skeleton:
          '해가 지지 않는 마을에 들어선다. 시계는 움직이는데 어둠은 오지 않는다. '
          '사람들은 웃지만 눈가가 말라 있다. '
          '밤을 되찾기 위해선 마을의 금기를 건드려야 한다.',
    ),

    // =========================================================
    // SLICE OF LIFE (5)
    // =========================================================
    StoryTemplate(
      id: 't_slice_01',
      genre: StoryGenre.sliceOfLife,
      title: '오늘의 온도',
      logline: '작은 변화가 쌓여 사람을 바꾼다',
      skeleton:
          '반복되는 하루가 이어진다. '
          '출근길, 익숙한 카페, 같은 사람들. '
          '하지만 사소한 사건 하나가 감정을 흔들고, '
          '스스로를 다시 보게 된다.',
    ),
    StoryTemplate(
      id: 't_slice_02',
      genre: StoryGenre.sliceOfLife,
      title: '늦은 점심',
      logline: '말하지 못한 마음이 식지 않는다',
      skeleton:
          '점심 시간이 자꾸 밀린다. 누군가는 늘 먼저 먹고, 누군가는 늘 남는다. '
          '남은 자리에서 흘러나오는 말들이 마음에 걸린다. '
          '사소한 한마디가 하루의 결을 바꾼다.',
    ),
    StoryTemplate(
      id: 't_slice_03',
      genre: StoryGenre.sliceOfLife,
      title: '창가 자리',
      logline: '같은 풍경이 조금 다르게 보인다',
      skeleton:
          '늘 앉던 창가 자리에 앉는다. 같은 음악, 같은 향, 같은 메뉴. '
          '그런데 오늘은 유난히 시선이 오래 머문다. '
          '변한 건 풍경이 아니라 마음쪽일지도 모른다.',
    ),
    StoryTemplate(
      id: 't_slice_04',
      genre: StoryGenre.sliceOfLife,
      title: '정리의 기술',
      logline: '버릴수록 가벼워진다',
      skeleton:
          '방을 정리하다가 오래된 물건들이 나온다. '
          '버리려 들었다가 손이 멈춘다. '
          '정리는 결국, 무엇을 남길지 결정하는 일이 된다.',
    ),
    StoryTemplate(
      id: 't_slice_05',
      genre: StoryGenre.sliceOfLife,
      title: '퇴근길의 노래',
      logline: '한 곡이 하루를 붙잡는다',
      skeleton:
          '퇴근길에 우연히 들은 노래가 하루 종일 맴돈다. '
          '가사 한 줄이 마음을 정확히 건드린다. '
          '집에 도착할 때쯤, 작은 결심이 생긴다.',
    ),
  ];

  static List<StoryTemplate> byGenre(StoryGenre genre) {
    return templates.where((t) => t.genre == genre).toList();
  }
}




