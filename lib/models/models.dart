import 'dart:convert';

/// One business plan record — mirrors `business_plan` table in the old SQLite DB.
class BusinessPlan {
  final int planId;
  final String? planToken;
  final String planName;
  final String resourceName;
  final String priceRange;
  final String city;
  final String? youtubeUrl;
  final String pdfFileName;
  final String coverPhotoName;
  final String planType; // FREE | PREMIUM
  final int downloadCount;

  const BusinessPlan({
    required this.planId,
    this.planToken,
    required this.planName,
    required this.resourceName,
    required this.priceRange,
    required this.city,
    this.youtubeUrl,
    required this.pdfFileName,
    required this.coverPhotoName,
    required this.planType,
    this.downloadCount = 0,
  });

  bool get isPremium => planType.toUpperCase() == 'PREMIUM';

  String get pdfAssetPath => 'assets/pdfs/$pdfFileName';

  /// Local cover assets were renamed during the port; map by plan name.
  String get coverAssetPath {
    final name = planName.toLowerCase();
    if (name.contains('kirinda')) return 'assets/images/cover_kirinda.png';
    if (name.contains('fresha')) return 'assets/images/cover_fresha.png';
    if (name.contains('terra')) return 'assets/images/cover_terra.png';
    if (name.contains('cascara')) return 'assets/images/cover_cascara.png';
    if (name.contains('second flush')) {
      return 'assets/images/cover_second_flush.png';
    }
    if (name.contains('fibra')) return 'assets/images/cover_fibra.png';
    if (name.contains('bwiza')) return 'assets/images/cover_bwiza.jpg';
    return 'assets/images/resource_umwenya.jpg';
  }

  factory BusinessPlan.fromJson(Map<String, dynamic> json) => BusinessPlan(
        planId: json['plan_id'] as int,
        planToken: json['plan_token'] as String?,
        planName: json['plan_name'] as String? ?? 'Untitled plan',
        resourceName: json['resource_name'] as String? ?? '',
        priceRange: json['price_range'] as String? ?? '',
        city: json['city'] as String? ?? '',
        youtubeUrl: json['youtube_url'] as String?,
        pdfFileName: json['pdf_file_name'] as String? ?? '',
        coverPhotoName: json['cover_photo_name'] as String? ?? '',
        planType: json['plan_type'] as String? ?? 'FREE',
        downloadCount: json['download_count'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'plan_id': planId,
        'plan_token': planToken,
        'plan_name': planName,
        'resource_name': resourceName,
        'price_range': priceRange,
        'city': city,
        'youtube_url': youtubeUrl,
        'pdf_file_name': pdfFileName,
        'cover_photo_name': coverPhotoName,
        'plan_type': planType,
        'download_count': downloadCount,
      };
}

/// Natural resource category — mirrors `resources` table.
class ResourceCategory {
  final int resourceId;
  final String resourceName;
  final String? description;
  final bool active;

  const ResourceCategory({
    required this.resourceId,
    required this.resourceName,
    this.description,
    this.active = true,
  });

  factory ResourceCategory.fromJson(Map<String, dynamic> json) =>
      ResourceCategory(
        resourceId: json['resource_id'] as int,
        resourceName: json['resource_name'] as String,
        description: json['description'] as String?,
        active: (json['active'] as int? ?? 1) == 1,
      );
}

/// Comment on a business plan — mirrors `comments` table.
class PlanComment {
  final int id;
  final int planId;
  final String username;
  final String text;
  final DateTime createdAt;

  /// True when the comment is only stored on this device because the server
  /// write failed. Pending comments are retried on the next load and the UI
  /// says so instead of claiming the comment was shared.
  final bool pending;

  const PlanComment({
    required this.id,
    required this.planId,
    required this.username,
    required this.text,
    required this.createdAt,
    this.pending = false,
  });

  factory PlanComment.fromJson(Map<String, dynamic> json) => PlanComment(
        id: json['id'] as int,
        planId: json['plan_id'] as int,
        username: json['username'] as String,
        text: json['comment_text'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        pending: json['pending'] as bool? ?? false,
      );

  PlanComment copyWith({int? id, bool? pending}) => PlanComment(
        id: id ?? this.id,
        planId: planId,
        username: username,
        text: text,
        createdAt: createdAt,
        pending: pending ?? this.pending,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'plan_id': planId,
        'username': username,
        'comment_text': text,
        'created_at': createdAt.toIso8601String(),
        if (pending) 'pending': true,
      };
}

List<BusinessPlan> parsePlans(String jsonString) {
  final map = jsonDecode(jsonString) as Map<String, dynamic>;
  return (map['business_plans'] as List)
      .map((e) => BusinessPlan.fromJson(e as Map<String, dynamic>))
      .toList();
}

List<ResourceCategory> parseResources(String jsonString) {
  final map = jsonDecode(jsonString) as Map<String, dynamic>;
  return (map['resources'] as List)
      .map((e) => ResourceCategory.fromJson(e as Map<String, dynamic>))
      .toList();
}
