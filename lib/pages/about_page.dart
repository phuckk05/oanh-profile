import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../utils/app_colors.dart';

/// About Page
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

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
          constraints: const BoxConstraints(maxWidth: 1000),
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
                  'About Me',
                  style: TextStyle(
                    fontSize: isMobile ? 36 : 48,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Social Media Icons
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _buildSocialIcon(
                    icon: FontAwesomeIcons.facebook,
                    label: 'Facebook',
                    onTap: () {
                      // Add your Facebook link here
                    },
                  ),
                  const SizedBox(width: 16),
                  _buildSocialIcon(
                    icon: FontAwesomeIcons.tiktok,
                    label: 'TikTok',
                    onTap: () {
                      // Add your TikTok link here
                    },
                  ),
                  const SizedBox(width: 16),
                  _buildSocialIcon(
                    icon: FontAwesomeIcons.instagram,
                    label: 'Instagram',
                    onTap: () {
                      // Add your Instagram link here
                    },
                  ),
                  const SizedBox(width: 16),
                  _buildSocialIcon(
                    icon: FontAwesomeIcons.phone,
                    label: 'Zalo',
                    onTap: () {
                      // Add your Zalo link here
                    },
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Content - Description from Firestore
              StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('information')
                        .limit(1)
                        .snapshots(),
                builder: (context, snapshot) {
                  String description =
                      'Xin chào! Tôi là một Flutter Developer với đam mê tạo ra những ứng dụng đẹp mắt và hiệu quả. Tôi có kinh nghiệm phát triển cả mobile và web apps với Flutter, Firebase và các công nghệ hiện đại khác.';

                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                    final data =
                        snapshot.data!.docs.first.data()
                            as Map<String, dynamic>;
                    description = data['description'] ?? description;
                  }

                  return Text(
                    description,
                    style: TextStyle(
                      fontSize: isMobile ? 16 : 18,
                      color: AppColors.textSecondary,
                      height: 1.8,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialIcon({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderColor),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryOrange.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 28, color: AppColors.primaryOrange),
      ),
    );
  }
}
