import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UploadPage extends StatefulWidget {
  final VoidCallback? onVisitanteAdded;
  const UploadPage({super.key, this.onVisitanteAdded});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController motivoController = TextEditingController();
  DateTime fechaHora = DateTime.now();
  PlatformFile? selectedImage;

  Future<void> selectImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        selectedImage = result.files.first;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imagen seleccionada correctamente')),
      );
    }
  }

  Future<void> selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: fechaHora,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(fechaHora),
      );

      if (time != null) {
        setState(() {
          fechaHora = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> registrarVisitante(BuildContext context) async {
    final supabase = Supabase.instance.client;

    // Validaciones simples
    if (nombreController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa el nombre del visitante')),
      );
      return;
    }

    if (motivoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa el motivo de la visita')),
      );
      return;
    }

    if (selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona una foto del visitante')),
      );
      return;
    }

    // Mostrar diálogo de progreso
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Registrando visitante...'),
            ],
          ),
        );
      },
    );

    try {
      String? imageUrl;
      
      // Subir imagen si fue seleccionada
      if (selectedImage != null && selectedImage!.bytes != null) {
        final fileBytes = selectedImage!.bytes!;
        final fileName = selectedImage!.name;
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final uniqueFileName = 'visitante_${timestamp}_$fileName';

        await supabase.storage.from('fotos').uploadBinary(uniqueFileName, fileBytes);
        imageUrl = supabase.storage.from('fotos').getPublicUrl(uniqueFileName);
      }

      // Obtener el usuario actual
      final user = supabase.auth.currentUser;
      if (user == null) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Usuario no autenticado'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Guardar datos del visitante
      await supabase.from('imagenes').insert({
        'nombre': nombreController.text.trim(),
        'motivo': motivoController.text.trim(),
        'imagen': imageUrl,
        'fecha_hora': fechaHora.toIso8601String(),
        'user_id': user.id,
      });

      // Cerrar diálogo de progreso
      Navigator.of(context).pop();

      // Mostrar resultado exitoso
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Visitante registrado exitosamente!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // Limpiar los campos
      nombreController.clear();
      motivoController.clear();
      setState(() {
        selectedImage = null;
        fechaHora = DateTime.now();
      });

      // Notificar que se agregó un visitante
      if (widget.onVisitanteAdded != null) {
        widget.onVisitanteAdded!();
      }
      
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al registrar visitante: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'El siguiente formulario te permitirá registrar un nuevo visitante.',
                          style: TextStyle(
                            color: const Color.fromARGB(255, 0, 0, 0),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Campo Nombre del Visitante
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Visitante',
                  border: OutlineInputBorder(),

                ),
              ),
              const SizedBox(height: 16),
              
              // Campo Motivo de Visita
              TextField(
                controller: motivoController,
                decoration: const InputDecoration(
                  labelText: 'Motivo de la Visita',
                  border: OutlineInputBorder(),
                  
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              
              // Seleccionar Fecha y Hora
              Card(
                child: ListTile(
                  title: const Text('Fecha y Hora de la Visita'),
                  subtitle: Text(
                    '${fechaHora.day}/${fechaHora.month}/${fechaHora.year} - ${fechaHora.hour.toString().padLeft(2, '0')}:${fechaHora.minute.toString().padLeft(2, '0')}',
                  ),
                  trailing: const Icon(Icons.edit),
                  onTap: selectDateTime,
                ),
              ),
              const SizedBox(height: 16),
              
              // Seleccionar Foto
              Card(
                child: ListTile(
                  title: const Text('Foto del Visitante'),
                  subtitle: Text(
                    selectedImage != null 
                        ? 'Imagen seleccionada: ${selectedImage!.name}'
                        : 'Toca para seleccionar una foto',
                  ),
                  onTap: selectImage,
                ),
              ),
              const SizedBox(height: 24),
              
              // Botón Registrar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => registrarVisitante(context),
                  icon: const Icon(Icons.save),
                  label: const Text('Registrar Visitante'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}