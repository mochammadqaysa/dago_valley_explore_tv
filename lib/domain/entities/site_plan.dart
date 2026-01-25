class SitePlan {
  final int id;
  final String housingId;
  final String name;
  final String imageUrl;
  final String imageTahap2Url;
  final String mapUrl;
  final String fasumUrl;
  final String timelineProgressUrl;
  final String? timelineProgressTahap2Url;
  final String createdAt;
  final String updatedAt;

  SitePlan({
    required this.id,
    required this.housingId,
    required this.name,
    required this.imageUrl,
    required this.imageTahap2Url,
    required this.mapUrl,
    required this.fasumUrl,
    required this.timelineProgressUrl,
    this.timelineProgressTahap2Url,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SitePlan.fromJson(Map<String, dynamic> json) => SitePlan(
    id: json["id"],
    housingId: json["housing_id"],
    name: json['name'],
    imageUrl: json['imageUrl'],
    imageTahap2Url: json['imageTahap2Url'],
    mapUrl: json['mapUrl'],
    fasumUrl: json['fasumUrl'],
    timelineProgressUrl: json['timelineProgressUrl'],
    timelineProgressTahap2Url: json['timelineProgressTahap2Url'],
    createdAt: json['created_at'],
    updatedAt: json['updated_at'],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "housing_id": housingId,
    "name": name,
    "imageUrl": imageUrl,
    "imageTahap2Url": imageTahap2Url,
    "mapUrl": mapUrl,
    "fasumUrl": fasumUrl,
    "timelineProgressUrl": timelineProgressUrl,
    "timelineProgressTahap2Url": timelineProgressTahap2Url,
    "created_at": createdAt,
    "updated_at": updatedAt,
  };
}
