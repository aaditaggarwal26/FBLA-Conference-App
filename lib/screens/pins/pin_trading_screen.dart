import 'package:flutter/material.dart';
import '../../models/pin_model.dart';
import '../../services/pin_service.dart';
import '../../theme/app_theme.dart';
import 'create_pin_screen.dart';
import 'pin_detail_screen.dart';
import 'my_pins_screen.dart';

class PinTradingScreen extends StatefulWidget {
  const PinTradingScreen({super.key});

  @override
  State<PinTradingScreen> createState() => _PinTradingScreenState();
}

class _PinTradingScreenState extends State<PinTradingScreen>
    with SingleTickerProviderStateMixin {
  final PinService _pinService = PinService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // Consistent Header with other screens
          SliverAppBar(
            expandedHeight: 100,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: isDark
                ? AppTheme.darkBackground
                : AppTheme.background,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.only(
                left: 24,
                bottom: 60,
                right: 24,
              ),
              title: Text(
                'Pin Trading',
                style: TextStyle(
                  color: isDark ? Colors.white : AppTheme.black,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkBackground : AppTheme.background,
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (isDark ? AppTheme.darkCard : AppTheme.lightGray)
                        .withValues(alpha: 0.5),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: AppTheme.primaryBlue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: isDark
                      ? Colors.white.withValues(alpha: 0.6)
                      : AppTheme.darkGray,
                  labelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                  tabs: const [
                    Tab(text: 'Explore'),
                    Tab(text: 'My Pins'),
                  ],
                ),
              ),
            ),
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [_buildExploreTab(), const MyPinsScreen()],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreatePinScreen()),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Create Pin'),
        backgroundColor: AppTheme.primaryBlue,
      ),
    );
  }

  Widget _buildExploreTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<List<PinModel>>(
      stream: _pinService.getAllPins(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          final errorMessage = snapshot.error.toString();

          // Check if it's an index error
          if (errorMessage.contains('index') ||
              errorMessage.contains('requires an index')) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.hourglass_empty_rounded,
                        size: 48,
                        color: AppTheme.warning,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Setting Up Pins...',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Database indexes are being created.\nThis usually takes a few minutes.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.7)
                            : AppTheme.darkGray,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {}); // Trigger rebuild to retry
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Other errors
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 64,
                    color: AppTheme.error.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error Loading Pins',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppTheme.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    errorMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.6)
                          : AppTheme.darkGray,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {}); // Trigger rebuild to retry
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final pins = snapshot.data ?? [];

        if (pins.isEmpty) {
          return _buildEmptyState();
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.65,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: pins.length,
          itemBuilder: (context, index) {
            return _buildPinCard(pins[index]);
          },
        );
      },
    );
  }

  Widget _buildPinCard(PinModel pin) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PinDetailScreen(pin: pin)),
        );
      },
      child: Hero(
        tag: 'pin_${pin.id}',
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: (isDark ? AppTheme.darkCard : AppTheme.lightGray)
                  .withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pin Image with subtle overlay
              Expanded(
                flex: 4,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : AppTheme.lightBlue,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        image: pin.imageUrls.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(pin.imageUrls.first),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: pin.imageUrls.isEmpty
                          ? Center(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue.withValues(
                                    alpha: 0.1,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.push_pin_rounded,
                                  size: 32,
                                  color: AppTheme.primaryBlue.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                            )
                          : null,
                    ),
                    // Subtle gradient overlay on image
                    if (pin.imageUrls.isNotEmpty)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.2),
                              ],
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Pin Info
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pin name with proper space allocation
                      Flexible(
                        flex: 2,
                        fit: FlexFit.tight,
                        child: Text(
                          pin.pinName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppTheme.black,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Badge - fixed height
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppTheme.warning.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.swap_horiz_rounded,
                              size: 12,
                              color: AppTheme.warning,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                pin.wantInReturn ?? 'Any offers',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.warning,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: AppTheme.primaryBlue.withValues(
                              alpha: 0.1,
                            ),
                            backgroundImage: pin.userPhotoUrl != null
                                ? NetworkImage(pin.userPhotoUrl!)
                                : null,
                            child: pin.userPhotoUrl == null
                                ? Text(
                                    pin.userName[0].toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryBlue,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              pin.userName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.7)
                                    : AppTheme.darkGray,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.push_pin_rounded,
              size: 60,
              color: AppTheme.primaryBlue.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No pins available yet',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to create a pin listing!',
            style: TextStyle(
              fontSize: 15,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.6)
                  : AppTheme.mediumGray,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreatePinScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text('Create Your First Pin'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}
