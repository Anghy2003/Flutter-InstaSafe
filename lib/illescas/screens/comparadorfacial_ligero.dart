import 'dart:math';
import 'package:instasafe/illescas/screens/usuarioLigero.dart';
import 'package:instasafe/models/plantillafacial.dart';

class ComparadorFacialLigero {
  /// Compara una plantilla facial contra una lista de usuarios registrados.
  ///
  /// Retorna un `Map` con:
  /// - 'usuario': el usuario más cercano encontrado
  /// - 'distancia': la distancia entre embeddings
  /// - 'esAdvertencia': `true` si está entre umbrales
  ///
  /// Si no se detecta nada dentro del umbral de advertencia, retorna `null`.
  static Map<String, dynamic>? comparar(
  PlantillaFacial plantillaCapturada,
  List<UsuarioLigero> usuarios, {
  double umbral = 0.70,
  double umbralAdvertencia = 0.90,
}) {
  double distanciaMinima = double.infinity;
  UsuarioLigero? usuarioCoincidente;

  for (final usuario in usuarios) {
    if (usuario.plantillaFacial.isEmpty) {
      print('⚠️ Usuario ${usuario.cedula} no tiene plantilla facial');
      continue;
    }

    try {
      final plantillaGuardada =
          PlantillaFacial.fromBase64(usuario.plantillaFacial);

      final distancia = _calcularDistanciaEuclidiana(
        plantillaCapturada.embedding,
        plantillaGuardada.embedding,
      );

      print('📏 Distancia con ${usuario.cedula}: $distancia');

      if (distancia < distanciaMinima) {
        distanciaMinima = distancia;
        usuarioCoincidente = usuario;
      }
    } catch (e) {
      print('❌ Error al comparar con ${usuario.cedula}: $e');
      continue;
    }
  }

  if (usuarioCoincidente == null) {
    print('⚠️ No se encontró ninguna coincidencia');
    return null;
  }

  print('👤 Mejor coincidencia: ${usuarioCoincidente.cedula}, distancia: $distanciaMinima');

  if (distanciaMinima <= umbral) {
    return {
      'usuario': usuarioCoincidente,
      'distancia': distanciaMinima,
      'esAdvertencia': false,
    };
  } else if (distanciaMinima <= umbralAdvertencia) {
    return {
      'usuario': usuarioCoincidente,
      'distancia': distanciaMinima,
      'esAdvertencia': true,
    };
  }

  print('🚫 Distancia $distanciaMinima es mayor que el umbral de advertencia ($umbralAdvertencia)');
  return null;
}

  /// Calcula la distancia euclidiana entre dos vectores
  static double _calcularDistanciaEuclidiana(List<double> a, List<double> b) {
    if (a.length != b.length) {
      throw ArgumentError('Los vectores deben tener la misma longitud');
    }

    double suma = 0.0;
    for (int i = 0; i < a.length; i++) {
      final diff = a[i] - b[i];
      suma += diff * diff;
    }

    return sqrt(suma);
  }
}
