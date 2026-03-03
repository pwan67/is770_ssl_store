import 'package:flutter/material.dart';
import '../models/gold_rate.dart';
import '../services/mock_service.dart';
import '../widgets/gold_rate_card.dart';
import '../models/news_item.dart';
import '../widgets/news_card.dart';
import '../widgets/store_info_card.dart';
import '10_page_catalog.dart';
import '12_page_profile.dart';
import '13_page_inquiry.dart';
import '02_page_trading.dart';

class HomePage extends StatefulWidget {
  // Make the page is interactive
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MockService _service = MockService(); // pull mock up data
  late Stream<GoldRate> _goldRateStream;
  List<NewsItem> _newsList = [];

  @override
  void initState() {
    // load data for home page when 1st open
    super.initState();
    _goldRateStream = _service.getGoldRateStream();
    _newsList = _service.getNews();
  }

  void _navigateTo(Widget page) {
    // add "back" button on the top left
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  @override
  Widget build(BuildContext context) {
    // Menu labels & icons with Thai context
    final menuItems = [
      {
        'title': 'Catalog\nสินค้าทองรูปพรรณ',
        'icon': Icons.grid_view_rounded,
        'page': const CatalogPage(),
      },
      {
        'title': 'Buy / Sell\nซื้อ-ขาย',
        'icon': Icons.currency_exchange,
        'page': const TradingPage(),
      },
      {
        'title': 'Profile\nข้อมูลสมาชิก',
        'icon': Icons.account_circle,
        'page': const ProfilePage(),
      },
      {
        'title': 'Inquiry\nสอบถาม/สั่งทำ',
        'icon': Icons.chat_bubble_outline,
        'page': const InquiryPage(),
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sung Seng Lee Gold'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        // Changed to ScrollView to fit banner
        child: Padding(
          padding: const EdgeInsets.all(16), // page margin
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Real-time Gold Rate
              StreamBuilder<GoldRate>(
                stream: _goldRateStream,
                builder: (context, snapshot) {
                  // if has the value then shows, else load
                  if (snapshot.hasData) {
                    return GoldRateCard(rate: snapshot.data!);
                  } else {
                    return const Center(child: CircularProgressIndicator());
                  }
                },
              ),
              const SizedBox(height: 20),

              // Promotional Banner Carousel
              SizedBox(
                height: 140, // Slightly increased height for indicators
                child: _PromotionCarousel(),
              ),
              const SizedBox(height: 24),

              const Text(
                'Menu',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF800000),
                ),
              ),
              const SizedBox(height: 12),

              GridView.builder(
                shrinkWrap: true, // Important for SingleChildScrollView
                physics: const NeverScrollableScrollPhysics(),
                itemCount: menuItems.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // better fit for mobile UI
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.1,
                ),
                itemBuilder: (context, index) {
                  final item = menuItems[index];
                  return InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      // When tab, go to new page, or shows "coming soon"
                      if (item['page'] != null) {
                        _navigateTo(item['page'] as Widget);
                      } else {
                        // For placeholder
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF800000),
                            content: Text(
                              'Function ${item['title']} coming soon!',
                            ),
                          ),
                        );
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFFFD700).withOpacity(0.5),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF800000).withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFFFF8E1),
                            ),
                            child: Icon(
                              item['icon'] as IconData,
                              size: 32,
                              color: const Color(0xFF800000),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            item['title'] as String,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF4A4A4A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // News Section
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.0),
                child: Text(
                  'News & Insights',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF800000),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _newsList.length,
                itemBuilder: (context, index) {
                  return NewsCard(
                    newsItem:
                        _newsList[index], // Lookup news from _newslist to create card
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Reading: ${_newsList[index].title}'),
                        ), // when push, it shows what you are reading
                      );
                    },
                  );
                },
              ),
              //  Store Info
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.0),
                child: Text(
                  'Our Location',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF800000),
                  ),
                ),
              ),
              const StoreInfoCard(),

              const SizedBox(
                height: 80,
              ), // Extra padding for FAB (FloatingActionButton)
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        // Set Chat with Us Line at the bottom right
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Opening LINE Official Account...')),
          );
        },
        backgroundColor: const Color(0xFF06C755), // LINE Green
        icon: const Icon(Icons.chat_bubble, color: Colors.white),
        label: const Text(
          'Chat with us',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// Mock Widget for Carousel
class _PromotionCarousel extends StatefulWidget {
  @override
  State<_PromotionCarousel> createState() => _PromotionCarouselState();
}

class _PromotionCarouselState extends State<_PromotionCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _promotions = [
    {
      'title': '50% Off Labor Fee\nApp Launch Special',
      'color': const Color(0xFF800000), // Deep Red
      'textColor': Colors.white,
      'image':
          'https://via.placeholder.com/600x200/800000/FFFFFF?text=50%25+OFF',
    },
    {
      'title': 'Golden Dragon Collection\nLunar New Year',
      'color': const Color(0xFFFFD700), // Gold
      'textColor': Colors.black,
      'image':
          'https://via.placeholder.com/600x200/FFD700/000000?text=Dragon+Collection',
    },
    {
      'title': 'Easy Gold Savings\nStart at 100 THB',
      'color': const Color(0xFF1E88E5), // Blue
      'textColor': Colors.white,
      'image':
          'https://via.placeholder.com/600x200/1E88E5/FFFFFF?text=Saving+Plan',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller:
                _pageController, // create slide based on #promotion, change current location
            itemCount: _promotions.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              final promo = _promotions[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: promo['color'],
                  image: promo['image'] != null
                      ? DecorationImage(
                          image: NetworkImage(promo['image']),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            Colors.black.withOpacity(0.3),
                            BlendMode.darken,
                          ),
                        )
                      : null,
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    promo['title'],
                    style: TextStyle(
                      color: promo['textColor'] ?? Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      shadows: [
                        const Shadow(
                          color: Colors.black45,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        // Indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_promotions.length, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentPage == index ? 24 : 8, // Show wide for current
              height: 8,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? const Color(0xFF800000)
                    : Colors.grey.withOpacity(0.5),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }
}
