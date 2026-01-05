import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../utils/app_colors.dart';
import '../utils/open_external_url.dart';

/// About Page
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Future<void> openUrl(String url, BuildContext context) async {
    try {
      final trimmed = url.trim();
      final uri = Uri.parse(trimmed);
      final normalizedUrl = uri.scheme.isEmpty ? 'https://$trimmed' : trimmed;

      final launched = await openExternalUrl(normalizedUrl);
      if (!launched) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Không thể mở link: $url'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                      openUrl('https://www.facebook.com/kmnhhz', context);
                    },
                  ),
                  const SizedBox(width: 16),
                  _buildSocialIcon(
                    icon: FontAwesomeIcons.linkedin,
                    label: 'LinkedIn',
                    onTap: () {
                      openUrl('https://www.linkedin.com/in/kmnhhz', context);
                    },
                  ),
                  const SizedBox(width: 16),
                  _buildSocialIcon(
                    icon: FontAwesomeIcons.mapLocation,
                    label: 'Address',
                    onTap: () {
                      openUrl(
                        "https://www.google.com/maps/place/Tp.+H%C3%A0+T%C4%A9nh,+H%C3%A0+T%C4%A9nh,+Vi%E1%BB%87t+Nam/@18.3543214,105.8606304,12591m/data=!3m2!1e3!4b1!4m6!3m5!1s0x31384e25a01235b9:0xbcd7270a51316e31!8m2!3d18.3420419!4d105.8923492!16zL20vMDdtMV95!5m1!1e1?entry=ttu&g_ep=EgoyMDI1MTIwOS4wIKXMDSoKLDEwMDc5MjA3MUgBUAM%3D",
                        context,
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  _buildSocialIcon(
                    icon: FontAwesomeIcons.phone,
                    label: 'Zalo',
                    onTap: () {
                      openUrl('https://zalo.me/0328566452', context);
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
