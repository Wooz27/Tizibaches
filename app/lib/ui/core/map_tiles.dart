import 'package:flutter_map/flutter_map.dart';

const _userAgent = 'mx.tizimin.baches';

List<TileLayer> appTileLayers() => [
  TileLayer(
    urlTemplate:
        'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{z}/{y}/{x}',
    userAgentPackageName: _userAgent,
    maxNativeZoom: 16,
    maxZoom: 19,
  ),
  TileLayer(
    urlTemplate:
        'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Reference/MapServer/tile/{z}/{y}/{x}',
    userAgentPackageName: _userAgent,
    maxNativeZoom: 16,
    maxZoom: 19,
  ),
];

const mapAttribution = 'Esri, HERE, Garmin, © OpenStreetMap contributors';
