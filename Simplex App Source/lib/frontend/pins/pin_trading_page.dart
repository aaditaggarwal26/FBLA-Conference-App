import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../backend/pin_trading/pin_model.dart';
import '../../backend/pin_trading/pin_service.dart';
import '../flutter_flow/flutter_flow_theme.dart';
import 'create_pin_page.dart';
import 'pin_detail_page.dart';

class PinTradingPage extends StatefulWidget {
  const PinTradingPage({super.key});

  @override
  State<PinTradingPage> createState() => _PinTradingPageState();
}

class _PinTradingPageState extends State<PinTradingPage> with SingleTickerProviderStateMixin {
  final PinService _pinService = PinService();
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  List<PinModel>? _searchResults;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _searchPins(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = null;
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    final results = await _pinService.searchPins(query);
    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F7),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              floating: true,
              pinned: true,
              snap: false,
              elevation: 0,
              backgroundColor: FlutterFlowTheme.of(context).primary,
              expandedHeight: 180,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        FlutterFlowTheme.of(context).primary,
                        FlutterFlowTheme.of(context).secondary,
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 80, 24, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '📌 Pin Trading',
                          style: TextStyle(
                            fontFamily: 'Google Sans',
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Trade conference pins with others',
                          style: TextStyle(
                            fontFamily: 'Google Sans',
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Container(
                  color: FlutterFlowTheme.of(context).primary,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _searchPins,
                      decoration: InputDecoration(
                        hintText: 'Search pins...',
                        hintStyle: TextStyle(
                          fontFamily: 'Google Sans',
                          color: Colors.grey[400],
                        ),
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF3B58F4)),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.grey),
                                onPressed: () {
                                  _searchController.clear();
                                  _searchPins('');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ];
        },
        body: _searchResults != null
            ? _buildSearchResults()
            : Column(
                children: [
                  Container(
                    color: Colors.white,
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: FlutterFlowTheme.of(context).primary,
                      indicatorWeight: 3,
                      labelColor: FlutterFlowTheme.of(context).primary,
                      unselectedLabelColor: Colors.grey,
                      labelStyle: const TextStyle(
                        fontFamily: 'Google Sans',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      tabs: const [
                        Tab(text: 'Explore'),
                        Tab(text: 'My Pins'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildExplorePins(),
                        _buildMyPins(currentUserId),
                      ],
                    ),
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreatePinPage()),
          );
        },
        backgroundColor: FlutterFlowTheme.of(context).primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Create Pin',
          style: TextStyle(
            fontFamily: 'Google Sans',
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFFD8DEFE),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 64,
                color: Color(0xFF3B58F4),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No pins found',
              style: TextStyle(
                fontFamily: 'Google Sans',
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: TextStyle(
                fontFamily: 'Google Sans',
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _searchResults!.length,
      itemBuilder: (context, index) {
        return _buildPinCard(_searchResults![index]);
      },
    );
  }

  Widget _buildExplorePins() {
    return StreamBuilder<List<PinModel>>(
      stream: _pinService.getAllPins(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final pins = snapshot.data ?? [];

        if (pins.isEmpty) {
          return _buildEmptyState('No pins available yet', 'Be the first to create one!');
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
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

  Widget _buildMyPins(String? userId) {
    if (userId == null) {
      return const Center(child: Text('Please sign in to view your pins'));
    }

    return StreamBuilder<List<PinModel>>(
      stream: _pinService.getUserPins(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final pins = snapshot.data ?? [];

        if (pins.isEmpty) {
          return _buildEmptyState('No pins yet', 'Create your first pin listing!');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: pins.length,
          itemBuilder: (context, index) {
            return _buildMyPinCard(pins[index]);
          },
        );
      },
    );
  }

  Widget _buildPinCard(PinModel pin) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PinDetailPage(pin: pin)),
        );
      },
      child: Hero(
        tag: 'pin_${pin.id}',
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B58F4).withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFFD8DEFE),
                        const Color(0xFFD8DEFE).withOpacity(0.6),
                      ],
                    ),
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
                      ? const Center(
                          child: Icon(
                            Icons.push_pin_rounded,
                            size: 50,
                            color: Color(0xFF3B58F4),
                          ),
                        )
                      : null,
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pin.pinName,
                        style: const TextStyle(
                          fontFamily: 'Google Sans',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Want: ${pin.wantInReturn}',
                        style: TextStyle(
                          fontFamily: 'Google Sans',
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: const Color(0xFFD8DEFE),
                            backgroundImage: pin.userPhotoUrl != null
                                ? NetworkImage(pin.userPhotoUrl!)
                                : null,
                            child: pin.userPhotoUrl == null
                                ? const Icon(
                                    Icons.person,
                                    size: 14,
                                    color: Color(0xFF3B58F4),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              pin.userName,
                              style: const TextStyle(
                                fontFamily: 'Google Sans',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
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

  Widget _buildMyPinCard(PinModel pin) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PinDetailPage(pin: pin)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD8DEFE), Color(0xFFB8C9FE)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    image: pin.imageUrls.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(pin.imageUrls.first),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: pin.imageUrls.isEmpty
                      ? const Center(
                          child: Icon(
                            Icons.push_pin_rounded,
                            size: 32,
                            color: Color(0xFF3B58F4),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              pin.pinName,
                              style: const TextStyle(
                                fontFamily: 'Google Sans',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: pin.isAvailable
                                  ? const Color(0xFF10B981).withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              pin.isAvailable ? 'Available' : 'Traded',
                              style: TextStyle(
                                fontFamily: 'Google Sans',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: pin.isAvailable
                                    ? const Color(0xFF10B981)
                                    : Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Want: ${pin.wantInReturn}',
                        style: TextStyle(
                          fontFamily: 'Google Sans',
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        pin.description,
                        style: TextStyle(
                          fontFamily: 'Google Sans',
                          fontSize: 13,
                          color: Colors.grey[500],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFD8DEFE), Color(0xFFB8C9FE)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inventory_2_rounded,
              size: 64,
              color: Color(0xFF3B58F4),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Google Sans',
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: 'Google Sans',
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
