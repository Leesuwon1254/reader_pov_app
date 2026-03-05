import 'package:flutter/material.dart';

enum Genre {
  romance,
  romanceFantasy,
  modernFantasy,
  thriller,
  mystery,
  school,
  office,
  sf,
}

extension GenreLabel on Genre {
  String get label {
    switch (this) {
      case Genre.romance:
        return '로맨스';
      case Genre.romanceFantasy:
        return '로맨스판타지';
      case Genre.modernFantasy:
        return '현대판타지';
      case Genre.thriller:
        return '스릴러';
      case Genre.mystery:
        return '추리';
      case Genre.school:
        return '학원물';
      case Genre.office:
        return '오피스';
      case Genre.sf:
        return 'SF';
    }
  }

  String get subtitle {
    switch (this) {
      case Genre.romance:
        return '감정선 중심, 설렘과 갈등';
      case Genre.romanceFantasy:
        return '세계관 + 로맨스, 운명/각성';
      case Genre.modernFantasy:
        return '현대 배경에 이능/비밀';
      case Genre.thriller:
        return '긴장감, 추격, 위험';
      case Genre.mystery:
        return '단서, 추리, 반전';
      case Genre.school:
        return '교실/동아리/비밀';
      case Genre.office:
        return '회사, 권력, 인간관계';
      case Genre.sf:
        return '기술, 미래, 디스토피아';
    }
  }

  IconData get icon {
    switch (this) {
      case Genre.romance:
        return Icons.favorite;
      case Genre.romanceFantasy:
        return Icons.auto_awesome;
      case Genre.modernFantasy:
        return Icons.flash_on;
      case Genre.thriller:
        return Icons.warning_amber;
      case Genre.mystery:
        return Icons.search;
      case Genre.school:
        return Icons.school;
      case Genre.office:
        return Icons.business_center;
      case Genre.sf:
        return Icons.public;
    }
  }
}
