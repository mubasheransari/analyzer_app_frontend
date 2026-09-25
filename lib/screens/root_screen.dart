import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/watchlist_provider.dart';
import 'trade/trade_of_day_screen.dart';
import 'market/market_screen.dart';
import 'news/news_screen.dart';
import 'analyzer/analyzer_screen.dart';
import 'chat/chat_screen.dart';
import 'learn/learn_screen.dart';
import 'profile/profile_screen.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _index = 0;

  final _screens = const [
    TradeOfDayScreen(),
    MarketScreen(),
    NewsScreen(),
    AnalyzerScreen(),
    ChatScreen(),
    LearnScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WatchlistProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.bolt_rounded), label: 'Trade'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart_rounded), label: 'Market'),
          BottomNavigationBarItem(icon: Icon(Icons.article_outlined), label: 'News'),
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome_outlined), label: 'Analyzer'),
          BottomNavigationBarItem(icon: Icon(Icons.smart_toy_outlined), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.school_outlined), label: 'Learn'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
