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
      body: Column(
        children: [
          // TabBar placed directly in the body
          Material(
            color: Theme.of(context).colorScheme.surface,
            elevation: 2,
            child: TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Theme.of(context).colorScheme.primary,
              tabs: const [
                Tab(text: "Created"),
                Tab(text: "Interested"),
                Tab(text: "Attended"),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                CreatedEventsTab(),
                InterestedEventsTab(),
                AttendedEventsTab(),
              ],
            ),
          ),
        ],
      )
    );
  }
}