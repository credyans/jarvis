class QuoteModel {
  final String text;
  final String author;

  const QuoteModel({
    required this.text,
    required this.author,
  });

  factory QuoteModel.fromJson(Map<String, dynamic> json) {
    return QuoteModel(
      text: json['text'] as String,
      author: json['author'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'author': author,
    };
  }

  QuoteModel copyWith({
    String? text,
    String? author,
  }) {
    return QuoteModel(
      text: text ?? this.text,
      author: author ?? this.author,
    );
  }

  @override
  String toString() {
    return 'QuoteModel(text: $text, author: $author)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! QuoteModel) return false;
    return text == other.text && author == other.author;
  }

  @override
  int get hashCode {
    return Object.hash(text, author);
  }
}
