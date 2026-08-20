import '../../../../core/errors/errors.dart';

final class AboutAppNoteDto {
  const AboutAppNoteDto({
    required this.id,
    required this.title,
    required this.description,
  });

  factory AboutAppNoteDto.fromJson(Map<String, Object?> json) {
    final id = json['id'];
    final title = json['title'];
    final description = json['description'];

    if (id is! String || title is! String || description is! String) {
      throw const ValidationException(
        'Invalid about app note payload.',
        code: 'invalid_about_app_note_payload',
      );
    }

    return AboutAppNoteDto(id: id, title: title, description: description);
  }

  final String id;
  final String title;
  final String description;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'title': title,
      'description': description,
    };
  }
}
