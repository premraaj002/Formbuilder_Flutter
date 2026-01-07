import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme_notifier.dart';
import '../auth_wrapper.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({Key? key}) : super(key: key);

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with TickerProviderStateMixin {
  late AnimationController _floatingController;
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> _showBackToTop = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _floatingController.repeat(reverse: true);

    _scrollController.addListener(() {
      final show = _scrollController.offset > 200;
      if (show != _showBackToTop.value) {
        _showBackToTop.value = show;
      }
    });
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _showBackToTop.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDark = themeNotifier.themeMode == ThemeMode.dark;
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    
    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      body: Stack(
        children: [
          // Animated Background
          _buildAnimatedBackground(isDark),
          
          // Main Content - wrapped in SingleChildScrollView to prevent overflow
          SingleChildScrollView(
            controller: _scrollController,
            physics: const ClampingScrollPhysics(),
            child: Column(
              children: [
                // App Bar as regular widget for better mobile control
                Container(
                  color: isDark 
                      ? Colors.grey[900]!.withOpacity(0.95)
                      : Colors.white.withOpacity(0.95),
                  child: SafeArea(
                    child: _buildAppBarContent(context, isDark),
                  ),
                ),
                // Main content sections
                _buildHeroSection(context, isDark),
                _buildFeaturesSection(context, isDark),
                _buildStatsSection(context, isDark),
                _buildAboutDeveloperSection(context, isDark),
                _buildFAQSection(context, isDark),
                _buildCTASection(context, isDark),
                _buildFooter(context, isDark),
              ],
            ),
          ),
          
          // Back to top button
          ValueListenableBuilder<bool>(
            valueListenable: _showBackToTop,
            builder: (_, show, __) {
              return Positioned(
                bottom: isSmallScreen ? 16 : 24,
                right: isSmallScreen ? 16 : 24,
                child: AnimatedOpacity(
                  opacity: show ? 1 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: IgnorePointer(
                    ignoring: !show,
                    child: FloatingActionButton(
                      mini: isSmallScreen,
                      onPressed: () {
                        _scrollController.animateTo(
                          0,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOut,
                        );
                      },
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      child: const Icon(Icons.keyboard_arrow_up),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppBarContent(BuildContext context, bool isDark) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 20,
        vertical: 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo section
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLogo(isSmallScreen),
                SizedBox(width: isSmallScreen ? 8 : 10),
                Flexible(
                  child: Text(
                    isSmallScreen ? 'Mvit' : 'Mvit Forms',
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 20 : 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Navigation section
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (MediaQuery.of(context).size.width > 800) ...[
                _buildNavButton('Features', isDark),
                _buildNavButton('About', isDark),
                _buildNavButton('FAQ', isDark),
                SizedBox(width: 10),
              ],
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const AuthWrapper()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 16 : 24,
                    vertical: isSmallScreen ? 10 : 12,
                  ),
                ),
                child: Text(
                  isSmallScreen ? 'Start' : 'Get Started',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: isSmallScreen ? 14 : 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground(bool isDark) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    Colors.grey[900]!,
                    Colors.grey[800]!,
                    Colors.grey[900]!,
                  ]
                : [
                    Colors.blue[50]!,
                    Colors.blue[100]!,
                    Colors.blue[50]!,
                  ],
          ),
        ),
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: _floatingController,
              builder: (context, child) {
                return Positioned(
                  top: 100 + (_floatingController.value * 50),
                  left: 50 + (_floatingController.value * 30),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.blue.withOpacity(0.1),
                          Colors.blue.withOpacity(0.05),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            AnimatedBuilder(
              animation: _floatingController,
              builder: (context, child) {
                return Positioned(
                  top: 300 - (_floatingController.value * 40),
                  right: 80 + (_floatingController.value * 20),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.blue.withOpacity(0.1),
                          Colors.blue.withOpacity(0.05),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildLogo(bool isSmallScreen) {
    final size = isSmallScreen ? 28.0 : 32.0;
    
    try {
      return Container(
        width: size,
        height: size,
        child: SvgPicture.asset(
          'assets/icons/app_logo.svg',
          colorFilter: ColorFilter.mode(
            Colors.blue[600]!,
            BlendMode.srcIn,
          ),
          width: size,
          height: size,
        ),
      );
    } catch (e) {
      // Fallback to icon if SVG fails to load
      return Icon(
        Icons.dynamic_form,
        color: Colors.blue[600],
        size: size,
      );
    }
  }

  Widget _buildNavButton(String text, bool isDark) {
    return TextButton(
      onPressed: () {},
      child: Text(
        text,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.grey[700],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final isMediumScreen = screenWidth < 800;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 20,
        vertical: isSmallScreen ? 40 : 60,
      ),
      child: Column(
        children: [
          SizedBox(height: isSmallScreen ? 40 : 80),
          AnimationLimiter(
            child: isMediumScreen
                ? Column(
                    children: [
                      // Mobile/tablet layout - stacked
                      AnimationConfiguration.staggeredList(
                        position: 0,
                        duration: const Duration(milliseconds: 800),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: _buildHeroContent(context, isDark, isSmallScreen),
                          ),
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 40 : 60),
                      if (!isSmallScreen)
                        AnimationConfiguration.staggeredList(
                          position: 1,
                          duration: const Duration(milliseconds: 800),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: _buildHeroVisual(isDark),
                            ),
                          ),
                        ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Desktop layout - side by side
                      Expanded(
                        flex: 3,
                        child: AnimationConfiguration.staggeredList(
                          position: 0,
                          duration: const Duration(milliseconds: 800),
                          child: SlideAnimation(
                            horizontalOffset: -50.0,
                            child: FadeInAnimation(
                              child: _buildHeroContent(context, isDark, isSmallScreen),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 40),
                      Expanded(
                        flex: 2,
                        child: AnimationConfiguration.staggeredList(
                          position: 1,
                          duration: const Duration(milliseconds: 800),
                          child: SlideAnimation(
                            horizontalOffset: 50.0,
                            child: FadeInAnimation(
                              child: _buildHeroVisual(isDark),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          SizedBox(height: isSmallScreen ? 60 : 100),
        ],
      ),
    );
  }

  Widget _buildHeroContent(BuildContext context, bool isDark, bool isSmallScreen) {
    final screenWidth = MediaQuery.of(context).size.width;
    final titleSize = isSmallScreen ? 28.0 : screenWidth > 1200 ? 56.0 : 48.0;
    
    return Column(
      crossAxisAlignment: screenWidth > 800 
          ? CrossAxisAlignment.start 
          : CrossAxisAlignment.center,
      children: [
        Text(
          'Create',
          style: GoogleFonts.poppins(
            fontSize: titleSize,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.grey[800],
          ),
        ),
        SizedBox(
          height: titleSize + 10,
          child: AnimatedTextKit(
            animatedTexts: [
              TypewriterAnimatedText(
                'Smart Forms',
                textStyle: GoogleFonts.poppins(
                  fontSize: titleSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[600],
                ),
                speed: const Duration(milliseconds: 100),
              ),
              TypewriterAnimatedText(
                'Amazing Surveys',
                textStyle: GoogleFonts.poppins(
                  fontSize: titleSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[600],
                ),
                speed: const Duration(milliseconds: 100),
              ),
              TypewriterAnimatedText(
                'Powerful Quizzes',
                textStyle: GoogleFonts.poppins(
                  fontSize: titleSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[600],
                ),
                speed: const Duration(milliseconds: 100),
              ),
            ],
            totalRepeatCount: 4,
            pause: const Duration(milliseconds: 1000),
            displayFullTextOnTap: true,
            stopPauseOnTap: true,
          ),
        ),
        Text(
          'in Minutes',
          style: GoogleFonts.poppins(
            fontSize: titleSize,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.grey[800],
          ),
        ),
        const SizedBox(height: 20),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: screenWidth > 800 ? 600 : double.infinity,
          ),
          child: Text(
            'Build stunning, responsive forms with advanced analytics, real-time collaboration, and seamless integrations. Transform your data collection experience with Mvit Forms.',
            style: GoogleFonts.inter(
              fontSize: isSmallScreen ? 16 : 18,
              color: isDark ? Colors.grey[300] : Colors.grey[600],
              height: 1.6,
            ),
            textAlign: screenWidth > 800 
                ? TextAlign.left 
                : TextAlign.center,
          ),
        ),
        const SizedBox(height: 30),
        _buildHeroButtons(context, isDark, isSmallScreen),
      ],
    );
  }

  Widget _buildHeroButtons(BuildContext context, bool isDark, bool isSmallScreen) {
    if (isSmallScreen) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const AuthWrapper()),
                );
              },
              icon: const Icon(Icons.rocket_launch, size: 20),
              label: const Text('Start Building Free'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 5,
                shadowColor: Colors.blue.withOpacity(0.3),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.play_arrow, size: 20),
              label: const Text('Watch Demo'),
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? Colors.white : Colors.grey[700],
                side: BorderSide(
                  color: isDark ? Colors.white : Colors.grey[400]!,
                  width: 2,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );
    }
    
    return Wrap(
      spacing: 15,
      runSpacing: 12,
      alignment: MediaQuery.of(context).size.width > 800 
          ? WrapAlignment.start 
          : WrapAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const AuthWrapper()),
            );
          },
          icon: const Icon(Icons.rocket_launch),
          label: const Text('Start Building Free'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
            elevation: 5,
            shadowColor: Colors.blue.withOpacity(0.3),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.play_arrow),
          label: const Text('Watch Demo'),
          style: OutlinedButton.styleFrom(
            foregroundColor: isDark ? Colors.white : Colors.grey[700],
            side: BorderSide(
              color: isDark ? Colors.white : Colors.grey[400]!,
              width: 2,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroVisual(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue[600]!, Colors.blue[400]!],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Icon(
              Icons.dynamic_form,
              size: 80,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.grey[800]!.withOpacity(0.8)
                  : Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: Colors.blue.withOpacity(0.2),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Text(
              '✨ Smart Forms Made Simple',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blue[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildFeaturesSection(BuildContext context, bool isDark) {
    final features = [
      {
        'icon': Icons.auto_awesome,
        'title': 'Drag & Drop Builder',
        'description': 'Create professional forms with our intuitive drag-and-drop interface. No coding required!',
      },
      {
        'icon': Icons.analytics,
        'title': 'Advanced Analytics',
        'description': 'Get detailed insights with real-time analytics, response tracking, and comprehensive reports.',
      },
      {
        'icon': Icons.phone_android,
        'title': 'Mobile Optimized',
        'description': 'All forms are automatically optimized for mobile devices and tablets for maximum reach.',
      },
      {
        'icon': Icons.security,
        'title': 'Secure & Compliant',
        'description': 'GDPR compliant with enterprise-grade security. Your data is always safe with us.',
      },
      {
        'icon': Icons.extension,
        'title': '50+ Integrations',
        'description': 'Connect with your favorite tools including Slack, Google Sheets, Mailchimp, and more.',
      },
      {
        'icon': Icons.groups,
        'title': 'Team Collaboration',
        'description': 'Work together with your team in real-time. Share, edit, and manage forms collaboratively.',
      },
    ];

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final crossAxisCount = screenWidth > 1200 ? 3 : screenWidth > 800 ? 2 : 1;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 20,
        vertical: isSmallScreen ? 40 : 60,
      ),
      child: Column(
        children: [
          Text(
            'Why Choose Mvit Forms?',
            style: GoogleFonts.poppins(
              fontSize: isSmallScreen ? 28 : 36,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey[800],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isSmallScreen ? 30 : 50),
          AnimationLimiter(
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: isSmallScreen ? 16 : 20,
                mainAxisSpacing: isSmallScreen ? 16 : 20,
                childAspectRatio: screenWidth < 600 ? 1.1 : 1.2,
              ),
              itemCount: features.length,
              itemBuilder: (context, index) {
                return AnimationConfiguration.staggeredGrid(
                  position: index,
                  duration: const Duration(milliseconds: 500),
                  columnCount: crossAxisCount,
                  child: ScaleAnimation(
                    child: FadeInAnimation(
                      child: _buildFeatureCard(
                        features[index]['icon'] as IconData,
                        features[index]['title'] as String,
                        features[index]['description'] as String,
                        isDark,
                        isSmallScreen,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: isSmallScreen ? 60 : 80),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(IconData icon, String title, String description, bool isDark, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 20 : 30),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
        color: isDark ? Colors.grey[800] : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: isSmallScreen ? 8 : 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: Colors.blue.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: isSmallScreen ? 40 : 48,
            color: Colors.blue[600],
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: isSmallScreen ? 18 : 20,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.grey[800],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: isSmallScreen ? 8 : 10),
          Expanded(
            child: Text(
              description,
              style: GoogleFonts.inter(
                fontSize: isSmallScreen ? 13 : 14,
                color: isDark ? Colors.grey[300] : Colors.grey[600],
                height: 1.5,
              ),
              maxLines: isSmallScreen ? 4 : 5,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, bool isDark) {
    final stats = [
      {'number': '99%', 'label': 'Uptime Guarantee'},
      {'number': '24/7', 'label': 'Customer Support'},
    ];

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final crossAxisCount = screenWidth > 600 ? 2 : 1;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 24 : 40),
      margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue[600]!, Colors.blue[500]!],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: AnimationLimiter(
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: isSmallScreen ? 16 : 20,
            mainAxisSpacing: isSmallScreen ? 16 : 20,
            childAspectRatio: isSmallScreen ? 2.5 : 2.0,
          ),
          itemCount: stats.length,
          itemBuilder: (context, index) {
            return AnimationConfiguration.staggeredGrid(
              position: index,
              duration: const Duration(milliseconds: 500),
              columnCount: crossAxisCount,
              child: FadeInAnimation(
                child: ScaleAnimation(
                  child: Container(
                    padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white.withOpacity(0.1),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          stats[index]['number']!,
                          style: GoogleFonts.poppins(
                            fontSize: isSmallScreen ? 28 : 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 4 : 8),
                        Text(
                          stats[index]['label']!,
                          style: GoogleFonts.inter(
                            fontSize: isSmallScreen ? 14 : 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAboutDeveloperSection(BuildContext context, bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final isDesktop = screenWidth > 800;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 40,
        vertical: isSmallScreen ? 40 : 60,
      ),
      color: isDark ? Colors.grey[800] : Colors.grey[100],
      child: Column(
        children: [
          Text(
            'About the Developer',
            style: GoogleFonts.poppins(
              fontSize: isSmallScreen ? 28 : 32,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey[800],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isSmallScreen ? 30 : 40),
          isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDeveloperAvatar(isSmallScreen),
                    const SizedBox(width: 40),
                    Expanded(
                      child: _buildDeveloperInfo(isDark, isSmallScreen),
                    ),
                  ],
                )
              : Column(
                  children: [
                    _buildDeveloperAvatar(isSmallScreen),
                    SizedBox(height: isSmallScreen ? 20 : 30),
                    _buildDeveloperInfo(isDark, isSmallScreen),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildDeveloperAvatar(bool isSmallScreen) {
    final avatarSize = isSmallScreen ? 120.0 : 200.0;
    
    return Container(
      width: avatarSize,
      height: avatarSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
        child: Image.asset(
          'assets/images/developer_avatar.jpg',
          width: avatarSize,
          height: avatarSize,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to icon if image fails to load
            return Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
                color: Colors.blue[600],
              ),
              child: Icon(
                Icons.person,
                size: isSmallScreen ? 60.0 : 100.0,
                color: Colors.white,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDeveloperInfo(bool isDark, bool isSmallScreen) {
    return Column(
      crossAxisAlignment: isSmallScreen 
          ? CrossAxisAlignment.center 
          : CrossAxisAlignment.start,
      children: [
        Text(
          'Hi, I\'m Premraaj!',
          style: GoogleFonts.poppins(
            fontSize: isSmallScreen ? 22 : 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue[600],
          ),
          textAlign: isSmallScreen ? TextAlign.center : TextAlign.left,
        ),
        SizedBox(height: isSmallScreen ? 12 : 15),
        Text(
          'I\'m a passionate Flutter Developer who loves creating innovative solutions for everyday problems. This form management system was built with the goal of simplifying data collection and analysis for educational institutions.',
          style: GoogleFonts.inter(
            fontSize: isSmallScreen ? 15 : 16,
            color: isDark ? Colors.grey[300] : Colors.grey[700],
            height: 1.6,
          ),
          textAlign: isSmallScreen ? TextAlign.center : TextAlign.left,
        ),
        SizedBox(height: isSmallScreen ? 12 : 15),
        Text(
          'Now the platform is full of free cost and open-source. Feel free to explore, contribute, or reach out if you have any questions or feedback!',
          style: GoogleFonts.inter(
            fontSize: isSmallScreen ? 15 : 16,
            color: isDark ? Colors.grey[300] : Colors.grey[700],
            height: 1.6,
          ),
          textAlign: isSmallScreen ? TextAlign.center : TextAlign.left,
        ),
        SizedBox(height: isSmallScreen ? 16 : 20),
        Wrap(
          spacing: isSmallScreen ? 8 : 10,
          runSpacing: isSmallScreen ? 8 : 10,
          alignment: isSmallScreen 
              ? WrapAlignment.center 
              : WrapAlignment.start,
          children: [
            _buildSkillChip('Flutter', isDark, isSmallScreen),
            _buildSkillChip('Firebase', isDark, isSmallScreen),
            _buildSkillChip('Dart', isDark, isSmallScreen),
            _buildSkillChip('UI/UX Design', isDark, isSmallScreen),
          ],
        ),
      ],
    );
  }

  Widget _buildSkillChip(String skill, bool isDark, bool isSmallScreen) {
    return Chip(
      label: Text(
        skill,
        style: TextStyle(
          color: Colors.blue[800],
          fontSize: isSmallScreen ? 12 : 14,
        ),
      ),
      backgroundColor: isDark 
          ? Colors.blue[100]!.withOpacity(0.9) 
          : Colors.blue[100],
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 8 : 12,
        vertical: isSmallScreen ? 4 : 8,
      ),
    );
  }

  Widget _buildFAQSection(BuildContext context, bool isDark) {
    final faqs = [
      {
        'question': 'How do I create my first form?',
        'answer': 'After logging in as an admin, navigate to the form builder where you can drag and drop elements to create your form. It\'s intuitive and requires no coding knowledge.'
      },
      {
        'question': 'Is my data secure?',
        'answer': 'Yes! All data is encrypted and stored securely using Firebase. We follow industry best practices for data protection and privacy.'
      },
      {
        'question': 'Can students access forms on mobile devices?',
        'answer': 'Absolutely! The platform is fully responsive and works seamlessly on all devices - phones, tablets, and computers.'
      },
      {
        'question': 'How do I view form responses and analytics?',
        'answer': 'Admins can access comprehensive analytics and response data through the dashboard. You can export data, view charts, and generate reports.'
      },
      {
        'question': 'Is there a limit on the number of forms I can create?',
        'answer': 'No! You can create unlimited forms and collect unlimited responses. This platform is designed to scale with your needs.'
      },
      {
        'question': 'How do I reset my password?',
        'answer': 'Click on "Forgot Password" on the login page and enter your email. You\'ll receive instructions to reset your password.'
      },
    ];

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 40,
        vertical: isSmallScreen ? 40 : 60,
      ),
      child: Column(
        children: [
          Text(
            'Frequently Asked Questions',
            style: GoogleFonts.poppins(
              fontSize: isSmallScreen ? 28 : 32,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey[800],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isSmallScreen ? 30 : 40),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: screenWidth > 1000 ? 800 : double.infinity,
            ),
            child: Column(
              children: faqs.asMap().entries.map((entry) {
                int index = entry.key;
                Map<String, String> faq = entry.value;
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 500),
                  child: SlideAnimation(
                    verticalOffset: 30.0,
                    child: FadeInAnimation(
                      child: Container(
                        margin: EdgeInsets.only(bottom: isSmallScreen ? 16 : 20),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.white,
                          borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: isSmallScreen ? 8 : 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            dividerColor: Colors.transparent,
                            expansionTileTheme: const ExpansionTileThemeData(
                              tilePadding: EdgeInsets.zero,
                            ),
                          ),
                          child: ExpansionTile(
                            tilePadding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 16 : 20,
                              vertical: isSmallScreen ? 8 : 12,
                            ),
                            childrenPadding: EdgeInsets.zero,
                            title: Text(
                              faq['question']!,
                              style: GoogleFonts.poppins(
                                fontSize: isSmallScreen ? 15 : 16,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.grey[800],
                              ),
                            ),
                            children: [
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.fromLTRB(
                                  isSmallScreen ? 16 : 20,
                                  0,
                                  isSmallScreen ? 16 : 20,
                                  isSmallScreen ? 16 : 20,
                                ),
                                child: Text(
                                  faq['answer']!,
                                  style: GoogleFonts.inter(
                                    fontSize: isSmallScreen ? 14 : 14,
                                    color: isDark ? Colors.grey[300] : Colors.grey[600],
                                    height: 1.6,
                                  ),
                                ),
                              ),
                            ],
                            iconColor: Colors.blue[600],
                            collapsedIconColor: Colors.blue[600],
                            expandedCrossAxisAlignment: CrossAxisAlignment.start,
                            maintainState: true,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCTASection(BuildContext context, bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 40,
        vertical: isSmallScreen ? 40 : 60,
      ),
      child: Column(
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: screenWidth > 800 ? 700 : double.infinity,
            ),
            child: Text(
              'Ready to Transform Your Forms?',
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 28 : 32,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: screenWidth > 800 ? 600 : double.infinity,
            ),
            child: Text(
              'Join the Trusted platform for Creating Smart, Secure, and Stunning Forms Today.',
              style: GoogleFonts.inter(
                fontSize: isSmallScreen ? 16 : 18,
                color: isDark ? Colors.grey[300] : Colors.grey[600],
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: isSmallScreen ? 32 : 40),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isSmallScreen ? double.infinity : 300,
            ),
            child: SizedBox(
              width: isSmallScreen ? double.infinity : null,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const AuthWrapper()),
                  );
                },
                icon: Icon(Icons.rocket_launch, size: isSmallScreen ? 18 : 20),
                label: Text(
                  isSmallScreen ? 'Start Building' : 'Start Building Forms',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 32 : 40,
                    vertical: isSmallScreen ? 16 : 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 50),
                  ),
                  elevation: 10,
                  shadowColor: Colors.blue.withOpacity(0.3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 40,
        vertical: isSmallScreen ? 32 : 40,
      ),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[800],
      ),
      child: Column(
        children: [
          // Logo section
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLogo(isSmallScreen),
              SizedBox(width: isSmallScreen ? 8 : 10),
              Text(
                'Mvit Forms',
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 20 : 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[600],
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isSmallScreen ? double.infinity : 600,
            ),
            child: Text(
              '© 2025 Mvit Forms. All rights reserved. Built with ❤️ for better forms.',
              style: GoogleFonts.inter(
                color: Colors.grey[400],
                fontSize: isSmallScreen ? 13 : 14,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),
          Wrap(
            spacing: isSmallScreen ? 8 : 20,
            runSpacing: isSmallScreen ? 8 : 10,
            alignment: WrapAlignment.center,
            children: [
              _buildFooterLink('Privacy Policy', isSmallScreen),
              _buildFooterLink('Terms of Service', isSmallScreen),
              _buildFooterLink('Contact Us', isSmallScreen),
              _buildFooterLink('Help Center', isSmallScreen),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLink(String text, bool isSmallScreen) {
    return TextButton(
      onPressed: () {},
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 8 : 12,
          vertical: isSmallScreen ? 6 : 8,
        ),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey[400],
          fontSize: isSmallScreen ? 13 : 14,
        ),
      ),
    );
  }
}