import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../auth_wrapper.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({Key? key}) : super(key: key);

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>(); 

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.offset > 50 && !_isScrolled) {
        setState(() => _isScrolled = true);
      } else if (_scrollController.offset <= 50 && _isScrolled) {
        setState(() => _isScrolled = false);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey, 
      extendBodyBehindAppBar: true,
      drawer: _buildMobileDrawer(context), 
      body: Stack(
        children: [
          // 1. Global Gradient Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0F172A),
                    Color(0xFF311B92),
                    Color(0xFF4A148C),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          
          // 2. Animated Orbs
          Positioned(
            top: -150,
            right: -100,
            child: _buildGlowingOrb(Colors.blueAccent, 500),
          ),
          Positioned(
            bottom: -200,
            left: -100,
            child: _buildGlowingOrb(Colors.purpleAccent, 600),
          ),

          // 3. Main Scrollable Content with Staggered Animations
          SelectionArea(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: AnimationLimiter(
                child: Column(
                  children: AnimationConfiguration.toStaggeredList(
                    duration: const Duration(milliseconds: 800),
                    childAnimationBuilder: (widget) => SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: widget,
                      ),
                    ),
                    children: [
                       _buildHeroSection(context),
                      _buildFeaturesSection(context),
                      _buildHowItWorksContainer(context), 
                      _buildDeveloperSection(context),
                      _buildCTASection(context),
                      _buildFooter(context),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 4. Sticky Glass Navbar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildNavbar(context),
          ),
        ],
      ),
    );
  }

  Widget _buildGlowingOrb(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 150,
            spreadRadius: 20,
          ),
        ],
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
        child: Container(color: Colors.transparent),
      ),
    );
  }

  // ===========================================================================
  // NAVBAR & DRAWER
  // ===========================================================================
  Widget _buildNavbar(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 900;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: _isScrolled 
                ? const Color(0xFF0A0E21).withOpacity(0.8) 
                : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.08),
                width: 0.5,
              ),
            ),
            boxShadow: _isScrolled ? [BoxShadow(color: Colors.black12, blurRadius: 20)] : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Colors.blueAccent, Colors.purpleAccent]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.dashboard_customize, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'FormBuilder',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),

              // Desktop Menu
              if (!isSmallScreen)
                Row(
                  children: [
                    _buildNavLink('Features'),
                    _buildNavLink('Templates'),
                    const SizedBox(width: 32),
                     TextButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) => const AuthWrapper()),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white70,
                      ),
                      child: Text(
                        'Log In',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ScaleButton(
                      onPressed: () {
                         Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) => const AuthWrapper()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Colors.blueAccent, Colors.purpleAccent]),
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [
                             BoxShadow(color: Colors.blueAccent.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8)),
                          ]
                        ),
                        child: Text("Get Started", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white)),
                      ),
                    ),
                  ],
                ),

              // Mobile Menu Icon
              if (isSmallScreen)
                IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  onPressed: () {
                    _scaffoldKey.currentState?.openDrawer();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF0F172A),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Colors.blueAccent, Colors.purpleAccent]),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.dashboard_customize, color: Colors.white, size: 40),
                const SizedBox(height: 16),
                Text('FormBuilder', style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.star, color: Colors.white70),
            title: Text('Features', style: GoogleFonts.inter(color: Colors.white)),
            onTap: () => Navigator.pop(context),
          ),
           ListTile(
            leading: const Icon(Icons.layers, color: Colors.white70),
            title: Text('Templates', style: GoogleFonts.inter(color: Colors.white)),
            onTap: () => Navigator.pop(context),
          ),
          const Divider(color: Colors.white24),
          ListTile(
            title: Text('Log In', style: GoogleFonts.inter(color: Colors.white)),
            onTap: () {
               Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const AuthWrapper()));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavLink(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: () {},
        overlayColor: MaterialStateProperty.all(Colors.transparent),
        child: Text(
          text,
          style: GoogleFonts.inter(
            color: Colors.white.withOpacity(0.85),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // HERO SECTION
  // ===========================================================================
  Widget _buildHeroSection(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1100;
    final isMobile = screenWidth < 600;

    return Container(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 24 : 32, 
        isMobile ? 120 : 180, 
        isMobile ? 24 : 32, 
        isMobile ? 60 : 100
      ),
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 1440),
      child: isDesktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 5, child: _buildHeroContent(context, true)),
                 const SizedBox(width: 80),
                Expanded(flex: 6, child: _buildHeroMockup(false)),
              ],
            )
          : Column(
              children: [
                _buildHeroContent(context, false),
                const SizedBox(height: 60),
                _buildHeroMockup(true),
              ],
            ),
    );
  }

  Widget _buildHeroContent(BuildContext context, bool isDesktop) {
    return Column(
      crossAxisAlignment: isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Text(
            "✨ New: AI Form Generation",
            style: GoogleFonts.inter(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          "Build Powerful Forms\nWithout Writing Code",
          style: GoogleFonts.poppins(
            fontSize: isDesktop ? 60 : 40,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1.1,
            letterSpacing: -1.0,
          ),
          textAlign: isDesktop ? TextAlign.start : TextAlign.center,
        ),
        const SizedBox(height: 24),
        Text(
          "Create, share, and analyze forms using a modern drag-and-drop builder. Perfect for students, teams, and enterprises.",
          style: GoogleFonts.inter(
            fontSize: isDesktop ? 18 : 16,
            color: Colors.white.withOpacity(0.8),
            height: 1.6,
          ),
          textAlign: isDesktop ? TextAlign.start : TextAlign.center,
        ),
        const SizedBox(height: 40),
        
        Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: isDesktop ? WrapAlignment.start : WrapAlignment.center,
          children: [
             ScaleButton(
               onPressed: () {
                 Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const AuthWrapper()));
               },
               child: Container(
                 padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 20),
                 decoration: BoxDecoration(
                   gradient: const LinearGradient(colors: [Colors.blueAccent, Colors.purpleAccent]),
                   borderRadius: BorderRadius.circular(50),
                   boxShadow: [BoxShadow(color: Colors.blueAccent.withOpacity(0.3), blurRadius: 20, offset: const Offset(0,8))]
                 ),
                 child: Text("Get Started Free", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
               ),
             ),
             ScaleButton(
               onPressed: () {},
               child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: const Text("View Live Demo", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
               ),
             ),
          ],
        ),
        const SizedBox(height: 32),
        Text(
          "Free & Open Source  •  No Credit Card Required",
          style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withOpacity(0.5), fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildHeroMockup(bool isMobile) {
    return Container(
      height: isMobile ? 300 : 400,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 60,
            offset: const Offset(0, 30),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Container(height: 30, color: Colors.white.withOpacity(0.05)),
            Expanded(
              child: Row(
                children: [
                  Container(width: 50, color: Colors.white.withOpacity(0.02)),
                  Expanded(
                    child: Center(
                      child: Icon(Icons.backup_table, size: 80, color: Colors.white.withOpacity(0.1)),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // FEATURES SECTION
  // ===========================================================================
  Widget _buildFeaturesSection(BuildContext context) {
    return Container(
      // color: const Color(0xFF0B1120), // Removed to restore gradient
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      width: double.infinity,
      child: Column(
        children: [
          Text("Everything You Need", style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          Text("Powerful features to help you build better forms.", style: GoogleFonts.inter(fontSize: 16, color: Colors.white60)),
          const SizedBox(height: 60),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: [
              _buildFeatureCard(Icons.drag_indicator, "Drag & Drop", "Intuitive editor to build forms in minutes."),
              _buildFeatureCard(Icons.dashboard_customize, "Templates", "Start fast with pre-made templates."),
              _buildFeatureCard(Icons.api, "API Access", "Seamlessly integrate with your existing stack."),
              _buildFeatureCard(Icons.security, "Enterprise Secure", "Bank-grade encryption for all your data."),
              _buildFeatureCard(Icons.insights, "Smart Analytics", "Real-time insights and response tracking."),
              _buildFeatureCard(Icons.file_download, "Export Data", "Download your data in CSV, Excel, or JSON."),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(IconData icon, String title, String description) {
    return HoverCard(
      child: Container(
        width: 350,
        height: 220, // Uniform Height
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center, // Center Vertically
          children: [
            Icon(icon, color: Colors.blueAccent[100], size: 28),
            const SizedBox(height: 20),
            Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
            const SizedBox(height: 8),
            Text(description, style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withOpacity(0.6), height: 1.5)),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // HOW IT WORKS + STATS (Combined Container)
  // ===========================================================================
  Widget _buildHowItWorksContainer(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Column(
        children: [
          // 1. How It Works Card
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
              padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 40),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1B4B), // Deep Indigo match
                borderRadius: BorderRadius.circular(4), // Shallower radius from image
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))
                ]
              ),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Text(
                    "How It Works",
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 60),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 600;
                      return isMobile 
                        ? Column(
                            children: [
                               _buildStep(Icons.notes, "1. Create", "Build your form."),
                               Padding(padding: const EdgeInsets.symmetric(vertical: 24), child: Icon(Icons.arrow_downward, color: Colors.white24)),
                               _buildStep(Icons.share, "2. Share", "Send link to users."),
                               Padding(padding: const EdgeInsets.symmetric(vertical: 24), child: Icon(Icons.arrow_downward, color: Colors.white24)),
                               _buildStep(Icons.pie_chart, "3. Analyze", "View results."),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildStep(Icons.notes, "1. Create", "Build your form."),
                              Padding(padding: const EdgeInsets.only(top: 30), child: Icon(Icons.arrow_right_alt, color: Colors.white24, size: 30)),
                              _buildStep(Icons.share, "2. Share", "Send link to users."),
                              Padding(padding: const EdgeInsets.only(top: 30), child: Icon(Icons.arrow_right_alt, color: Colors.white24, size: 30)),
                              _buildStep(Icons.pie_chart, "3. Analyze", "View results."),
                            ],
                          );
                    }
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 60),

          // 2. Stats
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 60,
            runSpacing: 40,
            children: [
              _buildStat("1000+", "Forms Created", Colors.white),
              _buildStat("Open Source", "100% Free", Colors.blueAccent),
              _buildStat("Education", "Trusted by Schools", Colors.blueAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep(IconData icon, String title, String text) {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.1),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Icon(icon, size: 28, color: Colors.white),
        ),
        const SizedBox(height: 20),
        Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 8),
        Text(text, style: GoogleFonts.inter(fontSize: 12, color: Colors.white70), textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildStat(String value, String label, Color titleColor) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: titleColor)),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
      ],
    );
  }

  // ===========================================================================
  // DEVELOPER, CTA, FOOTER
  // ===========================================================================
  Widget _buildDeveloperSection(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900),
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: isMobile 
            ? Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundImage: AssetImage('assets/images/developer_avatar.jpg'),
                  ),
                  const SizedBox(height: 32),
                  _buildDeveloperContent(),
                ],
              )
            : Row(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.1), width: 2),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/developer_avatar.jpg'),
                        fit: BoxFit.cover,
                      )
                    ),
                  ),
                  const SizedBox(width: 40),
                  Expanded(child: _buildDeveloperContent()),
                ],
            ),
        ),
    );
  }

  Widget _buildDeveloperContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Built by Premraaj", style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 12),
        Text(
          "I'm a Flutter developer passionate about simplifying tools for education. FormBuilder is designed to be the easiest way to collect data, completely free and open-source.",
          style: GoogleFonts.inter(color: Colors.white70, height: 1.5, fontSize: 15),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          children: [
            _buildChip("Flutter"),
            _buildChip("Firebase"),
            _buildChip("Open Source"),
          ],
        ),
      ],
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
    );
  }

  Widget _buildCTASection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      padding: const EdgeInsets.all(60),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text("Ready to Build Your First Form?", style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
          const SizedBox(height: 32),
           ScaleButton(
             onPressed: () {
                Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const AuthWrapper()));
             },
             child: Container(
               padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
               decoration: BoxDecoration(
                 color: Colors.white,
                 borderRadius: BorderRadius.circular(50),
               ),
               child: Text("Start for Free", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.black)),
             ),
           ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      color: Colors.black,
      width: double.infinity,
      child: Column(
        children: [
          Row(
             mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.dashboard_customize, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text("FormBuilder", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          Text("Simple, fast, open-source form builder.", style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
           const SizedBox(height: 32),
           Row(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
               Icon(FontAwesomeIcons.github, color: Colors.white54, size: 18),
               const SizedBox(width: 24),
               Icon(FontAwesomeIcons.twitter, color: Colors.white54, size: 18),
               const SizedBox(width: 24),
               Icon(FontAwesomeIcons.linkedin, color: Colors.white54, size: 18),
             ],
           ),
          const SizedBox(height: 32),
          Text("© 2024 FormBuilder. All rights reserved.", style: GoogleFonts.inter(color: Colors.white24, fontSize: 11)),
        ],
      ),
    );
  }
}

class HoverCard extends StatefulWidget {
  final Widget child;
  const HoverCard({Key? key, required this.child}) : super(key: key);

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: Matrix4.identity()
          ..translate(0.0, _isHovering ? -6.0 : 0.0) // Lift 6px
          ..scale(_isHovering ? 1.02 : 1.0), // Scale 1.02
        decoration: BoxDecoration(
           borderRadius: BorderRadius.circular(20),
           boxShadow: _isHovering ? [
             BoxShadow(
               color: Colors.blueAccent.withOpacity(0.15),
               blurRadius: 30,
               offset: const Offset(0, 20),
             ),
           ] : [],
        ),
        child: widget.child,
      ),
    );
  }
}

class ScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  
  const ScaleButton({Key? key, required this.child, required this.onPressed}) : super(key: key);

  @override
  State<ScaleButton> createState() => _ScaleButtonState();
}

class _ScaleButtonState extends State<ScaleButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(_controller);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
         _controller.reverse();
         widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        cursor: SystemMouseCursors.click,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value * (_isHovering ? 1.02 : 1.0),
              child: widget.child,
            );
          },
        ),
      ),
    );
  }
}