import 'dart:math' as math show sin, cos, atan2, sqrt, pow;
import 'package:ml_linalg/matrix.dart';
import 'package:ml_linalg/vector.dart';

/// Extensión para actualizar rangos de valores en un Vector
extension SetVectorValues on Vector {
  Vector setValues(int start, int end, Iterable<double> values) {
    if (values.length > length) throw Exception('Values too large for vector');
    if (end - start != values.length) throw Exception('Range size mismatch');
    if (start < 0 || end > length) throw Exception('Range out of bounds');

    final tempList = toList();
    tempList.replaceRange(start, end, values);
    return Vector.fromList(tempList);
  }
}

/// Extensiones para modificar matrices (actualizar celdas, submatrices, etc.)
extension ChangeMatrixValues on Matrix {
  Matrix setSubMatrix(
    int startRow,
    int endRow,
    int startColumn,
    int endColumn,
    Iterable<Iterable<double>> values,
  ) {
    final numRows = endRow - startRow;
    final numCols = endColumn - startColumn;

    if (values.length != numRows || values.first.length != numCols) {
      throw Exception('Tamaño de submatriz incorrecto');
    }

    final tempList = asFlattenedList.toList();

    for (var i = 0; i < numRows; i++) {
      final rowIndex = startRow + i;
      tempList.replaceRange(
        rowIndex * columnCount + startColumn,
        rowIndex * columnCount + endColumn,
        values.elementAt(i),
      );
    }

    return Matrix.fromFlattenedList(tempList, rowCount, columnCount);
  }

  Matrix setValues(
    int startRow,
    int endRow,
    int startColumn,
    int endColumn,
    Iterable<double> values,
  ) {
    final expectedLength = (endRow - startRow) * (endColumn - startColumn);
    if (values.length != expectedLength) {
      throw Exception('Cantidad de valores no coincide con el rango');
    }

    final tempList = asFlattenedList.toList();
    var index = 0;

    for (var i = startRow; i < endRow; i++) {
      for (var j = startColumn; j < endColumn; j++) {
        tempList[i * columnCount + j] = values.elementAt(index++);
      }
    }

    return Matrix.fromFlattenedList(tempList, rowCount, columnCount);
  }

  Matrix setValue(int row, int column, double value) {
    if (row < 0 || row >= rowCount || column < 0 || column >= columnCount) {
      throw Exception('Índice fuera de rango');
    }

    final tempList = asFlattenedList.toList();
    tempList[row * columnCount + column] = value;

    return Matrix.fromFlattenedList(tempList, rowCount, columnCount);
  }

  Matrix appendRow(List<double> row) {
    if (row.length != columnCount) {
      throw Exception('La fila debe tener la misma cantidad de columnas');
    }

    final extended = asFlattenedList.toList()..addAll(row);
    return Matrix.fromFlattenedList(extended, rowCount + 1, columnCount);
  }
}

/// Extensiones para operaciones matemáticas sobre matrices
extension MatrixCalculations on Matrix {
  double determinant() {
    if (rowCount != columnCount) {
      throw Exception('La matriz debe ser cuadrada');
    }

    if (rowCount == 1) {
      return this[0][0];
    } else if (rowCount == 2) {
      return this[0][0] * this[1][1] - this[0][1] * this[1][0];
    }

    throw Exception('Determinante solo implementado para matrices 1x1 y 2x2');
  }

  /// Descomposición en valores singulares (solo para matrices 2x2)
  Map<String, dynamic> svd() {
    if (rowCount != 2 || columnCount != 2) {
      throw Exception('Solo funciona para matrices 2x2');
    }

    final a = this[0][0];
    final b = this[0][1];
    final c = this[1][0];
    final d = this[1][1];

    final tempCalc = a * a + b * b - c * c - d * d;
    final theta = 0.5 * math.atan2(2 * a * c + 2 * b * d, tempCalc);

    final U = Matrix.fromList([
      [math.cos(theta), math.sin(theta)],
      [math.sin(theta), -math.cos(theta)],
    ]);

    final S1 = a * a + b * b + c * c + d * d;
    final S2 = math.sqrt(math.pow(tempCalc, 2) + 4 * math.pow(a * c + b * d, 2));

    final sigma1 = math.sqrt((S1 + S2) / 2);
    final sigma2 = math.sqrt((S1 - S2) / 2);

    final S = Vector.fromList([sigma1, sigma2]);

    final tempCalc2 = a * a - b * b + c * c - d * d;
    final phi = 0.5 * math.atan2(2 * a * b + 2 * c * d, tempCalc2);

    final s11 = (a * math.cos(theta) + c * math.sin(theta)) * math.cos(phi) +
        (b * math.cos(theta) + d * math.sin(theta)) * math.sin(phi);
    final s22 = (a * math.sin(theta) - c * math.cos(theta)) * math.sin(phi) +
        (-b * math.sin(theta) + d * math.cos(theta)) * math.cos(phi);

    final V = Matrix.fromList([
      [s11.sign * math.cos(phi), s22.sign * math.sin(phi)],
      [s11.sign * math.sin(phi), -s22.sign * math.cos(phi)],
    ]);

    return {'U': U, 'S': S, 'V': V};
  }

  int matrixRank() {
    final svdResult = svd();
    final Vector S = svdResult['S']!;
    return S.toList().where((s) => s > 1e-10).length;
  }
}
