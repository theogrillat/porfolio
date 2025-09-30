import 'dart:math' as math;
import 'package:vector_math/vector_math.dart';

/// Generates uniformly distributed points on a sphere using geodesic icosahedron subdivision
class GeodesicDistribution {

  /// Generates uniformly distributed points on a unit sphere
  static List<Vector3> generateUniformPoints(int targetCount) {
    // Start with icosahedron vertices
    var points = _createIcosahedronVertices();
    var faces = _createIcosahedronFaces();

    // Subdivide until we have enough points
    while (points.length < targetCount) {
      final newFaces = <List<int>>[];
      final vertexMap = <String, int>{};

      for (final face in faces) {
        _subdivideFace(face, points, newFaces, vertexMap);
      }

      faces = newFaces;
    }

    // If we have too many points, select optimal subset
    if (points.length > targetCount) {
      points = _selectOptimalSubset(points, targetCount);
    }

    return points;
  }

  // ============================================================================
  // PRIVATE HELPER METHODS
  // ============================================================================

  static List<Vector3> _createIcosahedronVertices() {
    final phi = (1.0 + math.sqrt(5.0)) / 2.0; // Golden ratio
    return [
      Vector3(-1, phi, 0).normalized(),
      Vector3(1, phi, 0).normalized(),
      Vector3(-1, -phi, 0).normalized(),
      Vector3(1, -phi, 0).normalized(),
      Vector3(0, -1, phi).normalized(),
      Vector3(0, 1, phi).normalized(),
      Vector3(0, -1, -phi).normalized(),
      Vector3(0, 1, -phi).normalized(),
      Vector3(phi, 0, -1).normalized(),
      Vector3(phi, 0, 1).normalized(),
      Vector3(-phi, 0, -1).normalized(),
      Vector3(-phi, 0, 1).normalized(),
    ];
  }

  static List<List<int>> _createIcosahedronFaces() {
    return [
      [0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11],
      [1, 5, 9], [5, 11, 4], [11, 10, 2], [10, 7, 6], [7, 1, 8],
      [3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9],
      [4, 9, 5], [2, 4, 11], [6, 2, 10], [8, 6, 7], [9, 8, 1],
    ];
  }

  static void _subdivideFace(
    List<int> face,
    List<Vector3> vertices,
    List<List<int>> newFaces,
    Map<String, int> vertexMap,
  ) {
    final a = face[0], b = face[1], c = face[2];

    final ab = _getMidpoint(a, b, vertices, vertexMap);
    final bc = _getMidpoint(b, c, vertices, vertexMap);
    final ca = _getMidpoint(c, a, vertices, vertexMap);

    newFaces.addAll([
      [a, ab, ca],
      [b, bc, ab],
      [c, ca, bc],
      [ab, bc, ca],
    ]);
  }

  static int _getMidpoint(
    int a,
    int b,
    List<Vector3> vertices,
    Map<String, int> vertexMap
  ) {
    final key = a < b ? '$a-$b' : '$b-$a';
    if (vertexMap.containsKey(key)) return vertexMap[key]!;

    final midpoint = ((vertices[a] + vertices[b]) * 0.5).normalized();
    vertices.add(midpoint);
    return vertexMap[key] = vertices.length - 1;
  }

  static List<Vector3> _selectOptimalSubset(List<Vector3> points, int targetCount) {
    final selected = <Vector3>[points[0]];
    final remaining = List<Vector3>.from(points)..removeAt(0);

    while (selected.length < targetCount && remaining.isNotEmpty) {
      Vector3? bestPoint;
      double maxMinDistance = 0;
      int bestIndex = -1;

      for (int i = 0; i < remaining.length; i++) {
        final candidate = remaining[i];
        final minDistance = selected
            .map((p) => _sphericalDistance(candidate, p))
            .reduce(math.min);

        if (minDistance > maxMinDistance) {
          maxMinDistance = minDistance;
          bestPoint = candidate;
          bestIndex = i;
        }
      }

      if (bestPoint != null) {
        selected.add(bestPoint);
        remaining.removeAt(bestIndex);
      }
    }

    return selected;
  }

  static double _sphericalDistance(Vector3 a, Vector3 b) {
    return math.acos((a.dot(b)).clamp(-1.0, 1.0));
  }
}
