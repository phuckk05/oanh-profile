import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/cosmic_background.dart';
import '../widgets/cosmic_header.dart';
import '../utils/app_colors.dart';
import '../providers/auth_provider.dart';
import 'about_page.dart';
import 'portfolio_page.dart';
import 'blog_page.dart';
import 'settings_page.dart';
import 'login_page.dart';

/// Home Page - Trang chủ với cosmic theme
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _currentIndex = 0;

  String _getPageName() {
    switch (_currentIndex) {
      case 0:
        return 'Home';
      case 1:
        return 'About';
      case 2:
        return 'Portfolio';
      case 3:
        return 'Blog';
      case 4:
        return 'Settings';
      default:
        return 'Home';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Reset currentIndex to Home if user logs out while on Settings page
    if (!authState.isLoggedIn && _currentIndex == 4) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _currentIndex = 0);
        }
      });
    }

    return Scaffold(
      body: CosmicBackground(
        child: Column(
          children: [
            // Header
            CosmicHeader(
              currentPage: _getPageName(),
              isLoggedIn: authState.isLoggedIn,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              onLoginPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
            ),

            // Content
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  _buildHomePage(),
                  const AboutPage(),
                  const PortfolioPage(),
                  const BlogPage(),
                  if (authState.isLoggedIn) const SettingsPage(),
                ],
              ),
            ),
          ],
        ),
      ),
      // Bottom Navigation (for mobile/tablet)
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHomePage() {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 800;

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 20 : 160,
            vertical: 40,
          ),
          child:
              isMobile
                  ? Column(
                    children: [
                      _buildHeroText(isMobile),
                      const SizedBox(height: 40),
                      _buildAvatar(),
                    ],
                  )
                  : Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Left side - Text
                      Expanded(flex: 1, child: _buildHeroText(isMobile)),

                      const SizedBox(width: 10),
                      // Right side - Avatar
                      Expanded(flex: 1, child: Center(child: _buildAvatar())),
                    ],
                  ),
        ),
      ),
    );
  }

  Widget _buildHeroText(bool isMobile) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('information')
              .limit(1)
              .snapshots(),
      builder: (context, snapshot) {
        String name = 'Kim Oanh';
        String major = 'Sinh viên ngành kinh tế';

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
          name = data['name'] ?? name;
          major = data['major'] ?? major;
        }

        return Column(
          crossAxisAlignment:
              isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          children: [
            Text(
              "Hello World, I'm",
              style: TextStyle(
                fontSize: isMobile ? 18 : 22,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
              textAlign: isMobile ? TextAlign.center : TextAlign.left,
            ),
            const SizedBox(height: 12),

            // Name with gradient from Firestore
            ShaderMask(
              shaderCallback:
                  (bounds) => const LinearGradient(
                    colors: AppColors.orangeGradient,
                  ).createShader(bounds),
              child: Text(
                name,
                style: TextStyle(
                  fontSize: isMobile ? 48 : 72,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
                textAlign: isMobile ? TextAlign.center : TextAlign.left,
              ),
            ),

            const SizedBox(height: 16),

            // Major from Firestore
            Text(
              major,
              style: TextStyle(
                fontSize: isMobile ? 20 : 28,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                letterSpacing: 1,
              ),
              textAlign: isMobile ? TextAlign.center : TextAlign.left,
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment:
                  isMobile ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Text(
                  'Welcome to My personal website',
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildAvatar() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('information')
              .limit(1)
              .snapshots(),
      builder: (context, snapshot) {
        String imageUrl = 'https://picsum.photos/400/400';

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
          final fetchedImage = data['image'] as String?;
          if (fetchedImage != null && fetchedImage.isNotEmpty) {
            imageUrl = fetchedImage;
          }
        }

        return Container(
          width: 320,
          height: 320,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // Yellow glow effect
            boxShadow: [
              BoxShadow(
                color: AppColors.glowYellow.withOpacity(0.4),
                blurRadius: 80,
                spreadRadius: 20,
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: AppColors.orangeGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryBg,
              ),
              padding: const EdgeInsets.all(4),
              child: ClipOval(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppColors.cardBg,
                      child: const Icon(
                        Icons.person,
                        size: 120,
                        color: AppColors.textMuted,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget? _buildBottomNav() {
    final authState = ref.watch(authProvider);
    final size = MediaQuery.of(context).size;
    if (size.width >= 800) return null; // Hide on desktop

    return Container(
      decoration: BoxDecoration(
        color: AppColors.secondaryBg,
        border: Border(top: BorderSide(color: AppColors.borderColor, width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: Colors.transparent,
        selectedItemColor: AppColors.primaryOrange,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'About',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.work),
            label: 'Portfolio',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.article),
            label: 'Blog',
          ),
          if (authState.isLoggedIn)
            const BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
        ],
      ),
    );
  }
}
