import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_colors.dart';

/// Portfolio Page
class PortfolioPage extends StatelessWidget {
  const PortfolioPage({super.key});

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
                  'Portfolio',
                  style: TextStyle(
                    fontSize: isMobile ? 36 : 48,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Stream projects from Firestore
              StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
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
                      child: CircularProgressIndicator(
                        color: AppColors.primaryOrange,
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(60),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderColor),
                      ),
                      child: const Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.folder_open,
                              size: 64,
                              color: AppColors.textMuted,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Chưa có dự án nào',
                              style: TextStyle(
                                fontSize: 18,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final projects = snapshot.data!.docs;

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isMobile ? 1 : 2,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: isMobile ? 0.85 : 1.5,
                    ),
                    itemCount: projects.length,
                    itemBuilder: (context, index) {
                      final data =
                          projects[index].data() as Map<String, dynamic>;
                      final title = data['title'] ?? 'Untitled Project';
                      final description = data['description'] ?? '';
                      final imageUrl = data['imageUrl'] as String?;

                      return _buildProjectCard(
                        context,
                        title,
                        description,
                        imageUrl,
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectCard(
    BuildContext context,
    String title,
    String description,
    String? imageUrl,
  ) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image (if available)
          if (imageUrl != null && imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: Image.network(
                imageUrl,
                height: isMobile ? 230 : 250,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: isMobile ? 160 : 200,
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

          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryOrange,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: isMobile ? 4 : 5,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
