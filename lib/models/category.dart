class Category {
  final String id;
  final String name;
  final String? slug;
  final String? imageUrl; // Changed to nullable
  final String? description;

  Category({
    required this.id,
    required this.name,
    this.slug,
    this.imageUrl, // Changed to optional
    this.description,
  });

  factory Category.fromMap(Map<String, dynamic> data, String documentId) {
    return Category(
      id: documentId,
      name: data['name'] ?? '',
      slug: data['slug'],
      imageUrl: data['imageUrl'], // Can be null
      description: data['description'],
    );
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      slug: json['slug'],
      imageUrl: json['image_url'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'slug': slug,
      'imageUrl': imageUrl,
      'description': description
    };
  }

  Map<String, dynamic> toDbMap() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'image_url': imageUrl,
    };
  }
}
