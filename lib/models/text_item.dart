class TextItem {
  final String content;
  final String device;
  final int createTime;

  TextItem({
    required this.content,
    required this.device,
    required this.createTime,
  });

  factory TextItem.fromJson(Map<String, dynamic> json) {
    return TextItem(
      content: json['content'] as String,
      device: json['device'] as String,
      createTime: json['createTime'] as int,
    );
  }
} 