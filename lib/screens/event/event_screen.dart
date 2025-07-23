import 'package:flutter/material.dart';
import 'package:myapp/widgets/attended_event_tab.dart';
import 'package:myapp/widgets/created_event_tab.dart';
import 'package:myapp/widgets/interested_event_tab.dart';
import 'package:provider/provider.dart';
import 'package:myapp/providers/post_provider.dart';

class EventFeedScreen extends StatefulWidget {
  const EventFeedScreen({super.key});

  @override
  State<EventFeedScreen> createState() => _EventFeedScreenState();
}

class _EventFeedScreenState extends State<EventFeedScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PostProvider>(context, listen: false).fetchAllPosts();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Event"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Created"),
            Tab(text: "Interested"),
            Tab(text: "Attended"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          CreatedEventsTab(),
          InterestedEventsTab(),
          AttendedEventsTab(),
        ],
      ),
    );
  }
}