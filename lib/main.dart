import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  runApp(EventNotificationApp());
}

class EventNotificationApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Event Notifier',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Segoe UI',
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[900],
          titleTextStyle: TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        primarySwatch: Colors.deepPurple,
      ),
      home: EventNotificationPage(),
    );
  }
}

class EventNotificationPage extends StatefulWidget {
  @override
  _EventNotificationPageState createState() => _EventNotificationPageState();
}

class _EventNotificationPageState extends State<EventNotificationPage> {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final TextEditingController _eventController = TextEditingController();
  final List<Map<String, dynamic>> _events = [];

  DateTime? _selectedDateTime;

  @override
  void initState() {
    super.initState();
    initializeNotifications();
  }

  Future<void> initializeNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notificationsPlugin.initialize(initSettings);
  }

  Future<void> scheduleNotification(String title, DateTime dateTime) async {
    final tzScheduled = tz.TZDateTime.from(dateTime, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'event_channel',
      'Event Notifications',
      importance: Importance.max,
      priority: Priority.high,
      color: Colors.deepPurple,
    );

    const platformDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.zonedSchedule(
      0,
      '🕒 Event Reminder',
      title,
      tzScheduled,
      platformDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  void _addEvent() {
    if (_eventController.text.isEmpty || _selectedDateTime == null) return;

    final event = {
      'title': _eventController.text,
      'datetime': _selectedDateTime!,
    };

    setState(() {
      _events.add(event);
    });

    scheduleNotification(_eventController.text, _selectedDateTime!);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ Notification scheduled')),
    );

    _eventController.clear();
    _selectedDateTime = null;
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(minutes: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) => Theme(
          data: ThemeData.dark().copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.grey[900],
              hourMinuteTextColor: Colors.white,
              dialHandColor: Colors.deepPurple,
            ),
          ),
          child: child!,
        ),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  String formatDateTime(DateTime dateTime) {
    return "${dateTime.day}/${dateTime.month}/${dateTime.year}  ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _eventController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Event Notifier'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          children: [
            TextField(
              controller: _eventController,
              decoration: InputDecoration(
                labelText: 'Event Title',
                filled: true,
                fillColor: Colors.white,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _pickDateTime,
              icon: Icon(Icons.calendar_today),
              label: Text(_selectedDateTime == null
                  ? 'Pick Date & Time'
                  : '📅 ${formatDateTime(_selectedDateTime!)}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[850],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _addEvent,
              icon: Icon(Icons.notifications_active),
              label: Text('Add & Notify'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 20),
            Divider(),
            Expanded(
              child: _events.isEmpty
                  ? Center(
                      child: Text('No events scheduled yet.',
                          style: TextStyle(color: Colors.grey[600])))
                  : ListView.builder(
                      itemCount: _events.length,
                      itemBuilder: (_, index) {
                        final event = _events[index];
                        return Card(
                          elevation: 3,
                          margin: EdgeInsets.symmetric(vertical: 8),
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading:
                                Icon(Icons.event, color: Colors.deepPurple),
                            title: Text(event['title'],
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(
                                "Scheduled at: ${formatDateTime(event['datetime'])}"),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
