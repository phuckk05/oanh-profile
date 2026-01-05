import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/auth_provider.dart';
import '../utils/app_colors.dart';
import '../APIs/cloudinary_api.dart';

/// Settings Page - Admin panel for managing data
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final CloudinaryApi _cloudinaryApi = CloudinaryApi();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Information form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _majorController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _imageUrl;
  String? _informationDocId;

  // Gallery form controllers
  final TextEditingController _galleryDescController = TextEditingController();
  String? _galleryImageUrl;
  bool _isEditingGallery = false;
  String? _editingGalleryId;

  // Project form controllers
  final TextEditingController _projectTitleController = TextEditingController();
  final TextEditingController _projectDescController = TextEditingController();
  String? _projectImageUrl;
  bool _isEditingProject = false;
  String? _editingProjectId;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInformation();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _majorController.dispose();
    _descriptionController.dispose();
    _galleryDescController.dispose();
    _projectTitleController.dispose();
    _projectDescController.dispose();
    super.dispose();
  }

  // Load existing information from Firestore
  Future<void> _loadInformation() async {
    try {
      final querySnapshot =
          await _firestore.collection('information').limit(1).get();
      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = doc.data();
        setState(() {
          _informationDocId = doc.id;
          _nameController.text = data['name'] ?? '';
          _majorController.text = data['major'] ?? '';
          _descriptionController.text = data['description'] ?? '';
          _imageUrl = data['image'];
        });
      }
    } catch (e) {
      _showSnackBar('Lỗi khi tải thông tin: $e', isError: true);
    }
  }

  // Pick and upload image
  Future<String?> _pickAndUploadImage(String folder) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null) {
        setState(() => _isLoading = true);

        String imageUrl;
        if (kIsWeb) {
          // Web: use bytes
          final bytes = result.files.first.bytes!;
          final fileName = result.files.first.name;
          imageUrl = await _cloudinaryApi.uploadImageFromBytes(
            bytes,
            fileName,
            folder: folder,
          );
        } else {
          // Mobile/Desktop: use file path
          final filePath = result.files.first.path!;
          imageUrl = await _cloudinaryApi.uploadImageFromPath(
            filePath,
            folder: folder,
          );
        }

        setState(() => _isLoading = false);
        return imageUrl;
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Lỗi khi upload ảnh: $e', isError: true);
    }
    return null;
  }

  // Save or update information
  Future<void> _saveInformation() async {
    if (_nameController.text.trim().isEmpty) {
      _showSnackBar('Vui lòng nhập tên', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = {
        'name': _nameController.text.trim(),
        'major': _majorController.text.trim(),
        'description': _descriptionController.text.trim(),
        'image': _imageUrl ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_informationDocId == null) {
        // Create new
        data['createdAt'] = FieldValue.serverTimestamp();
        final docRef = await _firestore.collection('information').add(data);
        setState(() => _informationDocId = docRef.id);
      } else {
        // Update existing
        await _firestore
            .collection('information')
            .doc(_informationDocId)
            .update(data);
      }

      _showSnackBar('Đã lưu thông tin thành công!');
    } catch (e) {
      _showSnackBar('Lỗi khi lưu: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Delete information
  Future<void> _deleteInformation() async {
    if (_informationDocId == null) return;

    final confirm = await _showConfirmDialog('Xóa thông tin cá nhân?');
    if (!confirm) return;

    setState(() => _isLoading = true);

    try {
      await _firestore
          .collection('information')
          .doc(_informationDocId)
          .delete();
      setState(() {
        _informationDocId = null;
        _nameController.clear();
        _majorController.clear();
        _descriptionController.clear();
        _imageUrl = null;
      });
      _showSnackBar('Đã xóa thông tin!');
    } catch (e) {
      _showSnackBar('Lỗi khi xóa: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Add or update gallery item
  Future<void> _saveGalleryItem() async {
    if (_galleryDescController.text.trim().isEmpty ||
        _galleryImageUrl == null) {
      _showSnackBar('Vui lòng chọn ảnh và nhập mô tả', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = {
        'image': _galleryImageUrl,
        'description': _galleryDescController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_isEditingGallery && _editingGalleryId != null) {
        // Update existing
        await _firestore
            .collection('gallery')
            .doc(_editingGalleryId)
            .update(data);
        _showSnackBar('Đã cập nhật gallery!');
      } else {
        // Create new
        data['createdAt'] = FieldValue.serverTimestamp();
        await _firestore.collection('gallery').add(data);
        _showSnackBar('Đã thêm vào gallery!');
      }

      // Reset form
      setState(() {
        _galleryDescController.clear();
        _galleryImageUrl = null;
        _isEditingGallery = false;
        _editingGalleryId = null;
      });
    } catch (e) {
      _showSnackBar('Lỗi khi lưu: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Delete gallery item
  Future<void> _deleteGalleryItem(String docId) async {
    final confirm = await _showConfirmDialog('Xóa ảnh này khỏi gallery?');
    if (!confirm) return;

    try {
      await _firestore.collection('gallery').doc(docId).delete();
      _showSnackBar('Đã xóa ảnh!');
    } catch (e) {
      _showSnackBar('Lỗi khi xóa: $e', isError: true);
    }
  }

  // Edit gallery item
  void _editGalleryItem(String docId, Map<String, dynamic> data) {
    setState(() {
      _isEditingGallery = true;
      _editingGalleryId = docId;
      _galleryImageUrl = data['image'];
      _galleryDescController.text = data['description'] ?? '';
    });
  }

  // Add or update project
  Future<void> _saveProject() async {
    if (_projectTitleController.text.trim().isEmpty ||
        _projectDescController.text.trim().isEmpty) {
      _showSnackBar('Vui lòng nhập đầy đủ thông tin project', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = {
        'title': _projectTitleController.text.trim(),
        'description': _projectDescController.text.trim(),
        'imageUrl': _projectImageUrl ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_isEditingProject && _editingProjectId != null) {
        // Update existing
        await _firestore
            .collection('projects')
            .doc(_editingProjectId)
            .update(data);
        _showSnackBar('Đã cập nhật project!');
      } else {
        // Create new
        data['createdAt'] = FieldValue.serverTimestamp();
        await _firestore.collection('projects').add(data);
        _showSnackBar('Đã thêm project mới!');
      }

      // Reset form
      setState(() {
        _projectTitleController.clear();
        _projectDescController.clear();
        _projectImageUrl = null;
        _isEditingProject = false;
        _editingProjectId = null;
      });
    } catch (e) {
      _showSnackBar('Lỗi khi lưu: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Delete project
  Future<void> _deleteProject(String docId) async {
    final confirm = await _showConfirmDialog('Xóa project này?');
    if (!confirm) return;

    try {
      await _firestore.collection('projects').doc(docId).delete();
      _showSnackBar('Đã xóa project!');
    } catch (e) {
      _showSnackBar('Lỗi khi xóa: $e', isError: true);
    }
  }

  // Edit project
  void _editProject(String docId, Map<String, dynamic> data) {
    setState(() {
      _isEditingProject = true;
      _editingProjectId = docId;
      _projectTitleController.text = data['title'] ?? '';
      _projectDescController.text = data['description'] ?? '';
      _projectImageUrl = data['imageUrl'];
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : AppColors.primaryOrange,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<bool> _showConfirmDialog(String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.borderColor),
            ),
            title: const Text(
              'Xác nhận',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            content: Text(
              message,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Xác nhận'),
              ),
            ],
          ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 800;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 20 : 80,
          vertical: 60,
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              ShaderMask(
                shaderCallback:
                    (bounds) => const LinearGradient(
                      colors: AppColors.orangeGradient,
                    ).createShader(bounds),
                child: Text(
                  'Settings & Management',
                  style: TextStyle(
                    fontSize: isMobile ? 36 : 48,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Loading indicator
              if (_isLoading)
                const LinearProgressIndicator(
                  color: AppColors.primaryOrange,
                  backgroundColor: AppColors.secondaryBg,
                ),

              const SizedBox(height: 20),

              // SECTION 1: Information Management
              _buildSectionTitle('Thông tin cá nhân', Icons.person),
              const SizedBox(height: 20),
              _buildInformationSection(),

              const SizedBox(height: 40),

              // SECTION 2: Gallery Management
              _buildSectionTitle('Quản lý Gallery', Icons.photo_library),
              const SizedBox(height: 20),
              _buildGalleryAddSection(),

              const SizedBox(height: 20),
              _buildGalleryListSection(),

              const SizedBox(height: 40),

              // SECTION 3: Projects Management
              _buildSectionTitle('Quản lý Projects', Icons.work),
              const SizedBox(height: 20),
              _buildProjectAddSection(),

              const SizedBox(height: 20),
              _buildProjectListSection(),

              const SizedBox(height: 40),

              // Logout Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showLogoutDialog(context, ref);
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Đăng xuất'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.1),
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.red.withOpacity(0.3)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryOrange, size: 28),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildInformationSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image picker
          Center(
            child: GestureDetector(
              onTap: () async {
                final url = await _pickAndUploadImage('information');
                if (url != null) {
                  setState(() => _imageUrl = url);
                }
              },
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: AppColors.secondaryBg,
                  borderRadius: BorderRadius.circular(75),
                  border: Border.all(color: AppColors.primaryOrange, width: 3),
                  image:
                      _imageUrl != null
                          ? DecorationImage(
                            image: NetworkImage(_imageUrl!),
                            fit: BoxFit.cover,
                          )
                          : null,
                ),
                child:
                    _imageUrl == null
                        ? const Icon(
                          Icons.add_photo_alternate,
                          size: 48,
                          color: AppColors.textMuted,
                        )
                        : null,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Name field
          _buildTextField(
            controller: _nameController,
            label: 'Tên',
            hint: 'Nhập tên của bạn',
            icon: Icons.person,
          ),

          const SizedBox(height: 16),

          // Major field
          _buildTextField(
            controller: _majorController,
            label: 'Chuyên ngành',
            hint: 'VD: Flutter Developer',
            icon: Icons.work,
          ),

          const SizedBox(height: 16),

          // Description field
          _buildTextField(
            controller: _descriptionController,
            label: 'Mô tả',
            hint: 'Giới thiệu về bản thân...',
            icon: Icons.description,
            maxLines: 4,
          ),

          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveInformation,
                  icon: const Icon(Icons.save),
                  label: Text(
                    _informationDocId == null ? 'Tạo mới' : 'Cập nhật',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              if (_informationDocId != null) ...[
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _deleteInformation,
                  icon: const Icon(Icons.delete),
                  label: const Text('Xóa'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.1),
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 24,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryAddSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isEditingGallery ? 'Chỉnh sửa ảnh' : 'Thêm ảnh mới',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 16),

          // Image picker
          GestureDetector(
            onTap: () async {
              final url = await _pickAndUploadImage('gallery');
              if (url != null) {
                setState(() => _galleryImageUrl = url);
              }
            },
            child: Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.secondaryBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderColor, width: 2),
                image:
                    _galleryImageUrl != null
                        ? DecorationImage(
                          image: NetworkImage(_galleryImageUrl!),
                          fit: BoxFit.cover,
                        )
                        : null,
              ),
              child:
                  _galleryImageUrl == null
                      ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate,
                            size: 48,
                            color: AppColors.textMuted,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Nhấn để chọn ảnh',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        ],
                      )
                      : null,
            ),
          ),

          const SizedBox(height: 16),

          // Description field
          _buildTextField(
            controller: _galleryDescController,
            label: 'Mô tả ảnh',
            hint: 'Nhập mô tả cho ảnh này...',
            icon: Icons.text_fields,
            maxLines: 2,
          ),

          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveGalleryItem,
                  icon: Icon(_isEditingGallery ? Icons.update : Icons.add),
                  label: Text(
                    _isEditingGallery ? 'Cập nhật' : 'Thêm vào Gallery',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              if (_isEditingGallery) ...[
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isEditingGallery = false;
                      _editingGalleryId = null;
                      _galleryImageUrl = null;
                      _galleryDescController.clear();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondaryBg,
                    foregroundColor: AppColors.textSecondary,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 24,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Hủy'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryListSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('gallery').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Lỗi: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryOrange),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: const Center(
              child: Text(
                'Chưa có ảnh nào trong gallery',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
            ),
          );
        }

        final galleryItems = snapshot.data!.docs;
        final size = MediaQuery.of(context).size;
        final isMobile = size.width < 800;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isMobile ? 1 : 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemCount: galleryItems.length,
          itemBuilder: (context, index) {
            final doc = galleryItems[index];
            final data = doc.data() as Map<String, dynamic>;
            final imageUrl = data['image'] as String? ?? '';
            final description = data['description'] as String? ?? '';

            return _buildGalleryCard(doc.id, imageUrl, description, data);
          },
        );
      },
    );
  }

  Widget _buildGalleryCard(
    String docId,
    String imageUrl,
    String description,
    Map<String, dynamic> data,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child:
                  imageUrl.isNotEmpty
                      ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppColors.secondaryBg,
                            child: const Icon(
                              Icons.broken_image,
                              size: 48,
                              color: AppColors.textMuted,
                            ),
                          );
                        },
                      )
                      : Container(
                        color: AppColors.secondaryBg,
                        child: const Icon(
                          Icons.image,
                          size: 48,
                          color: AppColors.textMuted,
                        ),
                      ),
            ),
          ),

          // Description and actions
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _editGalleryItem(docId, data),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Sửa'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryOrange.withOpacity(
                            0.1,
                          ),
                          foregroundColor: AppColors.primaryOrange,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _deleteGalleryItem(docId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.withOpacity(0.1),
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Icon(Icons.delete, size: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primaryOrange),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.secondaryBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppColors.primaryOrange,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.borderColor),
            ),
            title: const Text(
              'Đăng xuất',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            content: const Text(
              'Bạn có chắc chắn muốn đăng xuất?',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Hủy',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  ref.read(authProvider.notifier).logout();
                  Navigator.of(context).pop(); // Close dialog
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Đăng xuất'),
              ),
            ],
          ),
    );
  }

  // Build project add section
  Widget _buildProjectAddSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isEditingProject ? 'Chỉnh sửa Project' : 'Thêm Project mới',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 16),

          // Image picker (optional)
          GestureDetector(
            onTap: () async {
              final url = await _pickAndUploadImage('projects');
              if (url != null) {
                setState(() => _projectImageUrl = url);
              }
            },
            child: Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.secondaryBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderColor, width: 2),
                image:
                    _projectImageUrl != null
                        ? DecorationImage(
                          image: NetworkImage(_projectImageUrl!),
                          fit: BoxFit.cover,
                        )
                        : null,
              ),
              child:
                  _projectImageUrl == null
                      ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate,
                            size: 48,
                            color: AppColors.textMuted,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Nhấn để chọn ảnh (tùy chọn)',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        ],
                      )
                      : null,
            ),
          ),

          const SizedBox(height: 16),

          // Title field
          _buildTextField(
            controller: _projectTitleController,
            label: 'Tên Project',
            hint: 'Nhập tên project...',
            icon: Icons.title,
          ),

          const SizedBox(height: 16),

          // Description field
          _buildTextField(
            controller: _projectDescController,
            label: 'Mô tả Project',
            hint: 'Nhập mô tả chi tiết...',
            icon: Icons.description,
            maxLines: 4,
          ),

          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveProject,
                  icon: Icon(_isEditingProject ? Icons.update : Icons.add),
                  label: Text(_isEditingProject ? 'Cập nhật' : 'Thêm Project'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              if (_isEditingProject) ...[
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isEditingProject = false;
                      _editingProjectId = null;
                      _projectTitleController.clear();
                      _projectDescController.clear();
                      _projectImageUrl = null;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondaryBg,
                    foregroundColor: AppColors.textSecondary,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 24,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Hủy'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // Build project list section
  Widget _buildProjectListSection() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          _firestore
              .collection('projects')
              .orderBy('createdAt', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Lỗi: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryOrange),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: const Center(
              child: Text(
                'Chưa có project nào',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
            ),
          );
        }

        final projects = snapshot.data!.docs;
        final size = MediaQuery.of(context).size;
        final isMobile = size.width < 800;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: projects.length,
          itemBuilder: (context, index) {
            final doc = projects[index];
            final data = doc.data() as Map<String, dynamic>;
            final title = data['title'] as String? ?? '';
            final description = data['description'] as String? ?? '';
            final imageUrl = data['imageUrl'] as String?;

            return _buildProjectCard(
              doc.id,
              title,
              description,
              imageUrl,
              data,
            );
          },
        );
      },
    );
  }

  Widget _buildProjectCard(
    String docId,
    String title,
    String description,
    String? imageUrl,
    Map<String, dynamic> data,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image (if available)
          if (imageUrl != null && imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Image.network(
                imageUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: AppColors.secondaryBg,
                    child: const Icon(
                      Icons.broken_image,
                      size: 48,
                      color: AppColors.textMuted,
                    ),
                  );
                },
              ),
            ),

          // Content and actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryOrange,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _editProject(docId, data),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Sửa'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryOrange.withOpacity(
                            0.1,
                          ),
                          foregroundColor: AppColors.primaryOrange,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _deleteProject(docId),
                      icon: const Icon(Icons.delete, size: 16),
                      label: const Text('Xóa'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.withOpacity(0.1),
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
