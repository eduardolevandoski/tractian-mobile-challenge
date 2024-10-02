class Asset {
  final String id;
  final String name;
  String? parentId;
  String? sensorId;
  String? sensorType;
  String? status;
  String? gatewayId;
  String? locationId;

  Asset({
    required this.id,
    required this.name,
    this.parentId,
    this.sensorId,
    this.sensorType,
    this.status,
    this.gatewayId,
    this.locationId,
  });
}
