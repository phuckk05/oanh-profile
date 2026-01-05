import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// Header Navigation Bar - Giống trong ảnh
class CosmicHeader extends StatelessWidget {
  final String currentPage;
  final Function(int)? onPageChanged;
  final bool isLoggedIn;
  final VoidCallback? onLoginPressed;

  const CosmicHeader({
    super.key,
    this.currentPage = 'Home',
    this.onPageChanged,
    this.isLoggedIn = false,
    this.onLoginPressed,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 800;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 80,
        vertical: isMobile ? 5 : 20,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo
          Text(
            'KimOanh',
            style: TextStyle(
              fontSize: isMobile ? 20 : 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: 0.5,
            ),
          ),

          // Navigation Menu (ẩn trên mobile)
          if (!isMobile) ...[
            Row(
              children: [
                _buildNavItem('Home', currentPage == 'Home', 0),
                const SizedBox(width: 40),
                _buildNavItem('About', currentPage == 'About', 1),
                const SizedBox(width: 40),
                _buildNavItem('Portfolio', currentPage == 'Portfolio', 2),
                const SizedBox(width: 40),
                _buildNavItem('Blog', currentPage == 'Blog', 3),
                if (isLoggedIn) ...[
                  const SizedBox(width: 40),
                  _buildNavItem('Settings', currentPage == 'Settings', 4),
                ],
              ],
            ),
          ],

          // Login Button
          if (!isLoggedIn) ...[
            ElevatedButton.icon(
              onPressed: onLoginPressed,
              icon: const Icon(Icons.login, size: 18),
              label: Text(isMobile ? '' : 'Login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 20,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavItem(String title, bool isActive, int index) {
    return InkWell(
      onTap: () => onPageChanged?.call(index),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color:
                    isActive ? AppColors.textPrimary : AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            if (isActive)
              Container(
                width: 40,
                height: 2,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: AppColors.orangeGradient),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
