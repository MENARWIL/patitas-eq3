import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/pet.dart';
import '../services/cloudinary_service.dart';

class PetListScreen extends StatelessWidget {
  const PetListScreen({super.key});

  CollectionReference<Map<String, dynamic>> get _pets =>
      FirebaseFirestore.instance.collection('pets');

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.pets, color: Color(0xFF287A68)),
            SizedBox(width: 10),
            Text('Patitas'),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Text(
                user.email ?? 'Sesión iniciada',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _pets.where('ownerUid', isEqualTo: user.uid).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _MessageState(
                  icon: Icons.cloud_off_outlined,
                  title: 'No se pudieron cargar tus mascotas',
                  detail: '${snapshot.error}',
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final pets =
                  (snapshot.data?.docs ?? []).map(Pet.fromFirestore).toList()
                    ..sort(
                      (first, second) => first.name.toLowerCase().compareTo(
                        second.name.toLowerCase(),
                      ),
                    );
              if (pets.isEmpty) {
                return const _MessageState(
                  icon: Icons.pets_outlined,
                  title: 'Todavía no tienes mascotas registradas',
                  detail: 'Agrega la primera para empezar tu catálogo.',
                );
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                children: [
                  Text(
                    'Mis mascotas',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${pets.length} ${pets.length == 1 ? 'mascota' : 'mascotas'} en tu catálogo',
                  ),
                  const SizedBox(height: 16),
                  ...pets.map(
                    (pet) => _PetCard(
                      pet: pet,
                      onEdit: () => _openEditor(context, pet: pet),
                      onDelete: () => _deletePet(context, pet),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context),
        icon: const Icon(Icons.add),
        label: const Text('Agregar mascota'),
      ),
    );
  }

  Future<void> _openEditor(BuildContext context, {Pet? pet}) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => _PetEditorDialog(pet: pet, pets: _pets),
    );
    if (saved != true || !context.mounted) return;

    final message = pet == null
        ? '¡Mascota registrada con éxito!'
        : '¡Cambios guardados con éxito!';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }

  Future<void> _deletePet(BuildContext context, Pet pet) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar mascota'),
        content: Text(
          '¿Quieres eliminar a ${pet.name}? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await _pets.doc(pet.id).delete();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${pet.name} fue eliminada.')));
      }
    } on FirebaseException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No se pudo eliminar: ${error.message ?? error.code}',
            ),
          ),
        );
      }
    }
  }
}

class _PetCard extends StatelessWidget {
  const _PetCard({
    required this.pet,
    required this.onEdit,
    required this.onDelete,
  });

  final Pet pet;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 14),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 68,
            height: 68,
            child: pet.imageUrl.isEmpty
                ? const ColoredBox(
                    color: Color(0xFFE8F1EE),
                    child: Icon(Icons.pets, color: Color(0xFF287A68)),
                  )
                : Image.network(
                    pet.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const ColoredBox(
                          color: Color(0xFFE8F1EE),
                          child: Icon(Icons.broken_image_outlined),
                        ),
                  ),
          ),
        ),
        title: Text(
          pet.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${pet.species} · ${pet.age} ${pet.age == 1 ? 'año' : 'años'}',
        ),
        trailing: PopupMenuButton<String>(
          tooltip: 'Acciones',
          onSelected: (action) {
            if (action == 'edit') onEdit();
            if (action == 'delete') onDelete();
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit_outlined),
                title: Text('Editar'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete_outline),
                title: Text('Eliminar'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PetEditorDialog extends StatefulWidget {
  const _PetEditorDialog({required this.pets, this.pet});

  final CollectionReference<Map<String, dynamic>> pets;
  final Pet? pet;

  @override
  State<_PetEditorDialog> createState() => _PetEditorDialogState();
}

class _PetEditorDialogState extends State<_PetEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _speciesController = TextEditingController();
  final _ageController = TextEditingController();
  final _picker = ImagePicker();
  final _cloudinary = CloudinaryService();
  XFile? _selectedImage;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.pet?.name ?? '';
    _speciesController.text = widget.pet?.species ?? '';
    _ageController.text = widget.pet?.age.toString() ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _speciesController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _chooseImage() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (image != null && mounted) {
        setState(() {
          _selectedImage = image;
          _errorMessage = null;
        });
      }
    } on PlatformException catch (error) {
      if (mounted) {
        setState(
          () => _errorMessage =
              'No se pudo elegir la imagen: ${error.message ?? error.code}',
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImage == null && (widget.pet?.imageUrl.isEmpty ?? true)) {
      setState(() => _errorMessage = 'Selecciona una foto para la mascota.');
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(
        () => _errorMessage = 'La sesión expiró. Inicia sesión otra vez.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      final imageUrl = _selectedImage == null
          ? widget.pet!.imageUrl
          : await _cloudinary.uploadImage(_selectedImage!);
      final values = Pet(
        id: widget.pet?.id ?? '',
        ownerUid: user.uid,
        name: _nameController.text.trim(),
        species: _speciesController.text.trim(),
        age: int.parse(_ageController.text),
        imageUrl: imageUrl,
      ).toFirestore();
      if (widget.pet == null) {
        values['createdAt'] = FieldValue.serverTimestamp();
        await widget.pets.add(values);
      } else {
        await widget.pets.doc(widget.pet!.id).update(values);
      }

      if (mounted) Navigator.pop(context, true);
    } on FirebaseException catch (error) {
      if (mounted) {
        setState(
          () => _errorMessage =
              'No se pudo guardar: ${error.message ?? error.code}',
        );
      }
    } on StateError catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } on CloudinaryUploadException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } on Exception catch (error) {
      if (mounted) setState(() => _errorMessage = 'No se pudo guardar: $error');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.pet != null;
    return AlertDialog(
      title: Text(isEditing ? 'Editar mascota' : 'Nueva mascota'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ImageChooser(
                  selectedImage: _selectedImage,
                  currentImageUrl: widget.pet?.imageUrl,
                  onChoose: _isSaving ? null : _chooseImage,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (value) => (value?.trim().isEmpty ?? true)
                      ? 'El nombre es obligatorio.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _speciesController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Especie (perro, gato...)',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  validator: (value) => (value?.trim().isEmpty ?? true)
                      ? 'La especie es obligatoria.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Edad en años',
                    prefixIcon: Icon(Icons.cake_outlined),
                  ),
                  validator: (value) {
                    final age = int.tryParse(value ?? '');
                    if (age == null || age < 0 || age > 99) {
                      return 'Ingresa una edad entre 0 y 99.';
                    }
                    return null;
                  },
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEditing ? 'Guardar cambios' : 'Guardar mascota'),
        ),
      ],
    );
  }
}

class _ImageChooser extends StatelessWidget {
  const _ImageChooser({
    required this.selectedImage,
    required this.currentImageUrl,
    required this.onChoose,
  });

  final XFile? selectedImage;
  final String? currentImageUrl;
  final VoidCallback? onChoose;

  @override
  Widget build(BuildContext context) {
    Widget preview;
    if (selectedImage != null) {
      preview = FutureBuilder(
        future: selectedImage!.readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Icon(Icons.broken_image_outlined, size: 40);
          }
          if (!snapshot.hasData) {
            return const CircularProgressIndicator();
          }
          return Image.memory(snapshot.data!, fit: BoxFit.cover);
        },
      );
    } else if (currentImageUrl?.isNotEmpty ?? false) {
      preview = Image.network(
        currentImageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image_outlined, size: 40),
      );
    } else {
      preview = const Icon(Icons.add_a_photo_outlined, size: 36);
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 128,
            height: 100,
            color: const Color(0xFFE8F1EE),
            alignment: Alignment.center,
            child: preview,
          ),
        ),
        TextButton.icon(
          onPressed: onChoose,
          icon: const Icon(Icons.photo_library_outlined),
          label: Text(selectedImage == null ? 'Elegir foto' : 'Cambiar foto'),
        ),
        if (!CloudinaryService.isConfigured)
          Text(
            'Configura Cloudinary para subir imágenes.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 54, color: const Color(0xFF287A68)),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(detail, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
