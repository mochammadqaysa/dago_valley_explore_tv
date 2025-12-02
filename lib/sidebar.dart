import 'package:collapsible_sidebar/collapsible_sidebar.dart';
import 'package:dago_valley_explore_tv/app/config/app_colors.dart';
import 'package:dago_valley_explore_tv/presentation/pages/dashboard/dashboard_page.dart';
import 'package:dago_valley_explore_tv/presentation/pages/event/event_detail_page.dart';
import 'package:dago_valley_explore_tv/deletedsoon/dasbor_awal.dart';
import 'package:dago_valley_explore_tv/deletedsoon/sample.dart';
import 'package:flutter/material.dart';

class SidebarPage extends StatefulWidget {
  @override
  _SidebarPageState createState() => _SidebarPageState();
}

class _SidebarPageState extends State<SidebarPage> {
  late List<CollapsibleItem> _items;
  late String _headline;
  AssetImage _avatarImg = AssetImage('assets/logo-dago.webp');

  // Widget untuk menyimpan halaman yang aktif
  Widget _currentPage = DashboardPage();

  @override
  void initState() {
    super.initState();
    _items = _generateItems;
    _headline = _items.firstWhere((item) => item.isSelected).text;
  }

  List<CollapsibleItem> get _generateItems {
    return [
      CollapsibleItem(
        text: 'Home',
        icon: Icons.home_work,
        onPressed: () => setState(() {
          _headline = 'Home';
          _currentPage = DashboardPage();
        }),
        isSelected: true,
        onHold: () => ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: const Text("Search"))),
      ),
      CollapsibleItem(
        text: 'Site Plan',
        icon: Icons.map,
        onPressed: () => setState(() {
          _headline = 'Site Plan';
          _currentPage = NotificationsPage();
        }),
        onHold: () => ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: const Text("Notifications"))),
      ),
      CollapsibleItem(
        text: '360 View',
        icon: Icons.threesixty,
        onPressed: () => setState(() {
          _headline = '360 View';
          _currentPage = SettingsPage();
        }),
        onHold: () => ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: const Text("Settings"))),
      ),
      CollapsibleItem(
        text: 'Simulasi KPR',
        icon: Icons.credit_score,
        onPressed: () => setState(() {
          _headline = 'Simulasi KPR';
          _currentPage = AlarmPage();
        }),
        onHold: () => ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: const Text("Alarm"))),
      ),
      CollapsibleItem(
        text: 'Event',
        icon: Icons.event,
        onPressed: () => setState(() {
          _headline = 'Event';
          _currentPage = EventDetailPage();
        }),
        onHold: () => ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: const Text("Event"))),
      ),
      CollapsibleItem(
        text: 'No Icon',
        onPressed: () => setState(() {
          _headline = 'No Icon';
          _currentPage = NoIconPage();
        }),
        onHold: () => ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: const Text("No Icon"))),
      ),
      CollapsibleItem(
        text: 'No Icon',
        onPressed: () => setState(() {
          _headline = 'No Icon';
          _currentPage = NoIconPage();
        }),
        onHold: () => ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: const Text("No Icon"))),
      ),
      CollapsibleItem(
        text: 'No Icon',
        onPressed: () => setState(() {
          _headline = 'No Icon';
          _currentPage = NoIconPage();
        }),
        onHold: () => ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: const Text("No Icon"))),
      ),
      CollapsibleItem(
        text: 'No Icon',
        onPressed: () => setState(() {
          _headline = 'No Icon';
          _currentPage = NoIconPage();
        }),
        onHold: () => ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: const Text("No Icon"))),
      ),
      CollapsibleItem(
        text: 'No Icon',
        onPressed: () => setState(() {
          _headline = 'No Icon';
          _currentPage = NoIconPage();
        }),
        onHold: () => ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: const Text("No Icon"))),
      ),
      CollapsibleItem(
        text: 'No Icon',
        onPressed: () => setState(() {
          _headline = 'No Icon';
          _currentPage = NoIconPage();
        }),
        onHold: () => ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: const Text("No Icon"))),
      ),
      CollapsibleItem(
        text: 'Booking Online',
        icon: Icons.receipt_long,
        onPressed: () => setState(() {
          _headline = 'Booking Online';
          _currentPage = EmailPage();
        }),
        onHold: () => ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: const Text("Email"))),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return SafeArea(
      child: CollapsibleSidebar(
        isCollapsed: true,
        showToggleButton: false,
        items: _items,
        collapseOnBodyTap: false,
        avatarImg: _avatarImg,
        avatarBackgroundColor: Colors.transparent,
        borderRadius: 10,
        topPadding: 20,
        onTitleTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Yay! Flutter Collapsible Sidebar!')),
          );
        },
        body: _body(size, context),
        screenPadding: 8,
        minWidth: 80,
        backgroundColor: AppColors.lightGrey,
        selectedTextColor: AppColors.primary,
        selectedIconColor: AppColors.white,
        badgeBackgroundColor: AppColors.lightGrey,
        textStyle: TextStyle(fontSize: 15, fontStyle: FontStyle.italic),
        titleStyle: TextStyle(
          fontSize: 20,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.bold,
        ),
        toggleTitleStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        sidebarBoxShadow: [],
      ),
    );
  }

  Widget _body(Size size, BuildContext context) {
    return Container(
      height: double.infinity,
      width: double.infinity,
      color: Colors.blueGrey[50],
      child: _currentPage, // Menampilkan halaman yang dipilih
    );
  }
}
