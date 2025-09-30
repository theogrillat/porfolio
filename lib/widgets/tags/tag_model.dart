import 'package:vector_math/vector_math.dart';

class Tag {
  Tag({
    required this.id,
    required this.text,
    required this.x,
    required this.y,
    required this.size,
    required this.originalPosition,
    this.isClickable = false,
    this.clickID,
  }) : super();

  String id;
  String text;
  double x;
  double y;
  double size;
  Vector3 originalPosition;
  bool isClickable;
  int? clickID;
}
