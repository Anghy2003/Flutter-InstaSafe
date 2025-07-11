class UsuarioLigero {
  final String cedula;
  final String plantillaFacial;

  UsuarioLigero({
    required this.cedula,
    required this.plantillaFacial,
  });

  factory UsuarioLigero.fromJson(Map<String, dynamic> json) {
    return UsuarioLigero(
      cedula: json['cedula'] ?? '',
      plantillaFacial: json['plantillaFacial'] ?? '',
    );
  }
}
