class Invitation {
  final String code;
  final String link;

  const Invitation({
    required this.code,
    required this.link,
  });

  factory Invitation.fromJson(Map<String, dynamic> json) {
    return Invitation(
      code: json['code'] as String? ?? '',
      link: json['link'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'link': link,
    };
  }
}
