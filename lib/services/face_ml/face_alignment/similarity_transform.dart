import 'dart:math' show atan2;

import 'package:instasafe/extensions/ml_linalg_extensions.dart';
import 'package:instasafe/services/face_ml/face_alignment/alignment_result.dart';
import 'package:ml_linalg/linalg.dart';

/// Class to compute the similarity transform between two sets of points.
///
/// The class estimates the parameters of the similarity transformation via the `estimate` function.
class SimilarityTransform {
  Matrix _params = Matrix.fromList([
    [1.0, 0.0, 0.0],
    [0.0, 1.0, 0.0],
    [0, 0, 1],
  ]);
  List<double> _center = <double>[0, 0]; // [x, y]
  double _size = 1; // 1 / scale
  double _rotation = 0; // atan2(simRotation[1][0], simRotation[0][0]);

  final arcface4Landmarks = [
    <double>[38.2946, 51.6963],
    <double>[73.5318, 51.5014],
    <double>[56.0252, 71.7366],
    <double>[56.1396, 92.2848],
  ];
  final arcface5Landmarks = [
    <double>[38.2946, 51.6963],
    <double>[73.5318, 51.5014],
    <double>[56.0252, 71.7366],
    <double>[41.5493, 92.3655],
    <double>[70.7299, 92.2041],
  ];

  get arcfaceNormalized4 => arcface4Landmarks
      .map((list) => list.map((value) => value / 112.0).toList())
      .toList();

  get arcfaceNormalized5 => arcface5Landmarks
      .map((list) => list.map((value) => value / 112.0).toList())
      .toList();

  List<List<double>> get paramsList =>
      _params.map((iterable) => iterable.toList()).toList();

  // singleton pattern
  SimilarityTransform._privateConstructor();
  static final instance = SimilarityTransform._privateConstructor();
  factory SimilarityTransform() => instance;

  void _cleanParams() {
    _params = Matrix.fromList([
      [1.0, 0.0, 0.0],
      [0.0, 1.0, 0.0],
      [0, 0, 1],
    ]);
    _center = <double>[0, 0];
    _size = 1;
    _rotation = 0;
  }

  /// Function to estimate the parameters of the affine transformation. These parameters are stored in the class variable params.
  ///
  /// Returns true if the parameters are estimated successfully, false otherwise.
  ///
  /// Runs efficiently in about 1-3 ms after initial warm-up.
  ///
  /// It takes the source and destination points as input and returns the
  /// parameters of the affine transformation as output. The function
  /// returns false if the parameters cannot be estimated. The function
  /// estimates the parameters by solving a least-squares problem using
  /// the Umeyama algorithm.
  (AlignmentResult, bool) estimate(List<List<double>> src) {
    _cleanParams();
    final (params, center, size, rotation) =
        _umeyama(src, arcfaceNormalized5, true);
    _params = params;
    _center = center;
    _size = size;
    _rotation = rotation;
    final alignmentResult = AlignmentResult(
      affineMatrix: paramsList,
      center: center,
      size: size,
      rotation: rotation,
    );
    // We check for NaN in the transformation matrix params.
    final isNoNanInParam =
        !_params.asFlattenedList.any((element) => element.isNaN);
    return (alignmentResult, isNoNanInParam);
  }

  static (Matrix, List<double>, double, double) _umeyama(
    List<List<double>> src,
    List<List<double>> dst, [
    bool estimateScale = true,
  ]) {
    final srcMat = Matrix.fromList(
      src,
      // .map((list) => list.map((value) => value.toDouble()).toList())
      // .toList(),
    );
    final dstMat = Matrix.fromList(dst);
    final num = srcMat.rowCount;
    final dim = srcMat.columnCount;

    // Compute mean of src and dst.
    final srcMean = srcMat.mean(Axis.columns);
    final dstMean = dstMat.mean(Axis.columns);

    // Subtract mean from src and dst.
    final srcDemean = srcMat.mapRows((vector) => vector - srcMean);
    final dstDemean = dstMat.mapRows((vector) => vector - dstMean);

    // Eq. (38).
    final A = (dstDemean.transpose() * srcDemean) / num;

    // Eq. (39).
    var d = Vector.filled(dim, 1.0);
    if (A.determinant() < 0) {
      d = d.set(dim - 1, -1);
    }

    var T = Matrix.identity(dim + 1);

    final svdResult = A.svd();
    final Matrix U = svdResult['U']!;
    final Vector S = svdResult['S']!;
    final Matrix V = svdResult['V']!;

    // Eq. (40) and (43).
    final rank = A.matrixRank();
    if (rank == 0) {
      return (T * double.nan, <double>[0, 0], 1, 0);
    } else if (rank == dim - 1) {
      if (U.determinant() * V.determinant() > 0) {
        T = T.setSubMatrix(0, dim, 0, dim, U * V);
      } else {
        final s = d[dim - 1];
        d = d.set(dim - 1, -1);
        final replacement = U * Matrix.diagonal(d.toList()) * V;
        T = T.setSubMatrix(0, dim, 0, dim, replacement);
        d = d.set(dim - 1, s);
      }
    } else {
      final replacement = U * Matrix.diagonal(d.toList()) * V;
      T = T.setSubMatrix(0, dim, 0, dim, replacement);
    }
    final Matrix simRotation = U * Matrix.diagonal(d.toList()) * V;

    var scale = 1.0;
    if (estimateScale) {
      // Eq. (41) and (42).
      scale = 1.0 / srcDemean.variance(Axis.columns).sum() * (S * d).sum();
    }

    final subTIndices = Iterable<int>.generate(dim, (index) => index);
    final subT = T.sample(rowIndices: subTIndices, columnIndices: subTIndices);
    final newSubT = dstMean - (subT * srcMean) * scale;
    T = T.setValues(0, dim, dim, dim + 1, newSubT);
    final newNewSubT =
        T.sample(rowIndices: subTIndices, columnIndices: subTIndices) * scale;
    T = T.setSubMatrix(0, dim, 0, dim, newNewSubT);

    // final List<double> translation = [T[0][2], T[1][2]];
    // final simRotation = replacement?;
    final size = 1 / scale;
    final rotation = atan2(simRotation[1][0], simRotation[0][0]);
    final meanTranslation = (dstMean - 0.5) * size;
    final centerMat = srcMean - meanTranslation;
    final List<double> center = [centerMat[0], centerMat[1]];

    return (T, center, size, rotation);
  }
}
