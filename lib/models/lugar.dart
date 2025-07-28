class Lugar {
  final int id;
  final String nombre;

  Lugar({required this.id, required this.nombre});

  factory Lugar.fromJson(Map<String, dynamic> json) {
    return Lugar(
      id: json['id'],
      nombre: json['nombre'],
    );
  }
}
