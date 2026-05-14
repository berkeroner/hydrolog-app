import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  runApp(const HydrologApp());
}

class HydrologApp extends StatelessWidget {
  const HydrologApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hydrolog',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
      ),
      home: const Dashboard(),
    );
  }
}

// --- DASHBOARD ---
class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _totalIntake = 0;
  int _dailyGoal = 2500; // Varsayılan hedef
  String _userName = "User";
  List<String> _todayLogs = [];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  String _getTodayKey() {
    DateTime now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  Future<void> _loadAllData() async {
    final prefs = await SharedPreferences.getInstance();
    String key = _getTodayKey();
    setState(() {
      _totalIntake = prefs.getInt(key) ?? 0;
      _dailyGoal = prefs.getInt('daily_goal') ?? 2500;
      _userName = prefs.getString('user_name') ?? "User";
      _todayLogs = prefs.getStringList('${key}_logs') ?? [];
    });
  }

  Future<void> _saveIntake() async {
    final prefs = await SharedPreferences.getInstance();
    String key = _getTodayKey();
    await prefs.setInt(key, _totalIntake);
    await prefs.setStringList('${key}_logs', _todayLogs);
  }

  void _addWater(int amount) {
    setState(() {
      _totalIntake += amount;
      _todayLogs.add("${DateTime.now().toIso8601String()}|$amount");
    });
    _saveIntake();
  }

  @override
  Widget build(BuildContext context) {
    double rawProgress = _totalIntake / _dailyGoal;
    double progress = rawProgress > 1.0 ? 1.0 : rawProgress;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Hi, $_userName!',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HistoryScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            ).then((_) => _loadAllData()),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  ClipPath(
                    clipper: BottleClipPath(),
                    child: Container(
                      width: 140,
                      height: 280,
                      color: Colors.blue.shade50,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 1200),
                            curve: Curves.elasticOut,
                            height: 280 * progress,
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.lightBlueAccent,
                                  Colors.blueAccent,
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  CustomPaint(
                    size: const Size(140, 280),
                    painter: BottleOutlinePainter(),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(rawProgress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: progress > 0.45
                              ? Colors.white
                              : Colors.blueAccent,
                        ),
                      ),
                      Text(
                        rawProgress >= 1.0 ? 'Goal Met!' : 'Goal',
                        style: TextStyle(
                          color: progress > 0.45 ? Colors.white70 : Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 60),
              Text(
                '$_totalIntake / $_dailyGoal ml',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 50),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAddButton(250, 'Glass', Icons.local_drink),
                  _buildAddButton(500, 'Bottle', Icons.water_drop),
                  _buildCustomAddButton(),
                ],
              ),
              const SizedBox(height: 40),
              _buildHourlyChart(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHourlyChart() {
    Map<int, int> hourlyData = {};
    for (int i = 0; i < 24; i++) {
      hourlyData[i] = 0;
    }

    for (String log in _todayLogs) {
      final parts = log.split('|');
      if (parts.length == 2) {
        final time = DateTime.tryParse(parts[0]);
        final amount = int.tryParse(parts[1]) ?? 0;
        if (time != null) {
          hourlyData[time.hour] = (hourlyData[time.hour] ?? 0) + amount;
        }
      }
    }

    int maxAmount = 500;
    hourlyData.values.forEach((v) {
      if (v > maxAmount) maxAmount = v;
    });

    List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < 24; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: hourlyData[i]!.toDouble(),
              color: Colors.blueAccent,
              width: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Hourly Consumption (ml)',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxAmount.toDouble() * 1.2,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        int hour = value.toInt();
                        if (hour % 4 == 0) {
                          return Text(
                            '$hour:00',
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 22,
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: barGroups,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(int amount, String label, IconData icon) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () => _addWater(amount),
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(24),
            backgroundColor: Colors.blue.shade50,
          ),
          child: Icon(icon, size: 35, color: Colors.blueAccent),
        ),
        const SizedBox(height: 10),
        Text(
          '+$amount ml',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildCustomAddButton() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _showCustomAddDialog,
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(24),
            backgroundColor: Colors.blue.shade50,
          ),
          child: const Icon(Icons.add, size: 35, color: Colors.blueAccent),
        ),
        const SizedBox(height: 10),
        const Text('Custom', style: TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Future<void> _showCustomAddDialog() async {
    final TextEditingController amountController = TextEditingController();
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Custom Amount'),
          content: TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Amount (ml)',
              suffixText: 'ml',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final int? amount = int.tryParse(amountController.text);
                if (amount != null && amount > 0) {
                  _addWater(amount);
                }
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}

// --- PROFILE SCREEN ---
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  final _goalController = TextEditingController();

  bool _notificationsEnabled = false;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 22, minute: 0);
  int _interval = 2;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('user_name') ?? "";
      _weightController.text = (prefs.getInt('user_weight') ?? "").toString();
      _goalController.text = (prefs.getInt('daily_goal') ?? 2500).toString();

      _notificationsEnabled = prefs.getBool('notif_enabled') ?? false;
      _startTime = TimeOfDay(
        hour: prefs.getInt('notif_start_h') ?? 9,
        minute: prefs.getInt('notif_start_m') ?? 0,
      );
      _endTime = TimeOfDay(
        hour: prefs.getInt('notif_end_h') ?? 22,
        minute: prefs.getInt('notif_end_m') ?? 0,
      );
      _interval = prefs.getInt('notif_interval') ?? 2;
    });
  }

  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _nameController.text);
    await prefs.setInt(
      'user_weight',
      int.tryParse(_weightController.text) ?? 0,
    );
    await prefs.setInt(
      'daily_goal',
      int.tryParse(_goalController.text) ?? 2500,
    );

    await prefs.setBool('notif_enabled', _notificationsEnabled);
    await prefs.setInt('notif_start_h', _startTime.hour);
    await prefs.setInt('notif_start_m', _startTime.minute);
    await prefs.setInt('notif_end_h', _endTime.hour);
    await prefs.setInt('notif_end_m', _endTime.minute);
    await prefs.setInt('notif_interval', _interval);

    if (_notificationsEnabled) {
      await NotificationService().scheduleWaterReminders(
        startHour: _startTime.hour,
        endHour: _endTime.hour,
        intervalHours: _interval,
      );
    } else {
      await NotificationService().cancelAllReminders();
    }

    if (mounted)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile Saved!')));
  }

  void _calculateSuggestedGoal() {
    int weight = int.tryParse(_weightController.text) ?? 0;
    if (weight > 0) {
      setState(() {
        _goalController.text = (weight * 35).toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const CircleAvatar(
                radius: 50,
                child: Icon(Icons.person, size: 50),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _weightController,
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: _calculateSuggestedGoal,
                icon: const Icon(Icons.auto_fix_high),
                label: const Text('Suggest Goal Based on Weight'),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _goalController,
                decoration: const InputDecoration(
                  labelText: 'Daily Goal (ml)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 30),
              const Divider(),
              const SizedBox(height: 10),
              const Text(
                'Notifications',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SwitchListTile(
                title: const Text('Enable Water Reminders'),
                value: _notificationsEnabled,
                onChanged: (val) => setState(() => _notificationsEnabled = val),
              ),
              if (_notificationsEnabled) ...[
                ListTile(
                  title: const Text('Start Time'),
                  trailing: Text(_startTime.format(context)),
                  onTap: () async {
                    final t = await showTimePicker(
                      context: context,
                      initialTime: _startTime,
                    );
                    if (t != null) setState(() => _startTime = t);
                  },
                ),
                ListTile(
                  title: const Text('End Time'),
                  trailing: Text(_endTime.format(context)),
                  onTap: () async {
                    final t = await showTimePicker(
                      context: context,
                      initialTime: _endTime,
                    );
                    if (t != null) setState(() => _endTime = t);
                  },
                ),
                ListTile(
                  title: const Text('Reminder Interval'),
                  trailing: DropdownButton<int>(
                    value: _interval,
                    items: [1, 2, 3, 4]
                        .map(
                          (i) => DropdownMenuItem(
                            value: i,
                            child: Text('$i Hours'),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _interval = val);
                    },
                  ),
                ),
              ],
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(15),
                  ),
                  child: const Text(
                    'SAVE PROFILE',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- HISTORY SCREEN (CALENDAR) ---
// (Bir önceki adımda verdiğim HistoryScreen kodunun aynısını buraya ekleyebilirsin,
// Dashboard'daki _dailyGoal'e göre renklendirme yapması için _loadAllHistory içinde
// prefs.getInt('daily_goal') değerini de okumayı unutma.)
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  Map<String, int> _history = {};
  int _dailyGoal = 2500;
  DateTime _focusedDay = DateTime.now();
  int _streak = 0;
  int _avg7Days = 0;
  int _avg30Days = 0;
  int _totalAllTime = 0;

  @override
  void initState() {
    super.initState();
    _loadAllHistory();
  }

  Future<void> _loadAllHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    Map<String, int> tempHistory = {};
    int totalAllTime = 0;
    for (String key in keys) {
      if (RegExp(r'\d{4}-\d{2}-\d{2}').hasMatch(key)) {
        int amt = prefs.getInt(key) ?? 0;
        tempHistory[key] = amt;
        totalAllTime += amt;
      }
    }

    int dailyGoal = prefs.getInt('daily_goal') ?? 2500;

    int streak = 0;
    DateTime today = DateTime.now();
    String todayKey =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    bool todayMet = (tempHistory[todayKey] ?? 0) >= dailyGoal;

    DateTime dateToCheck = todayMet
        ? today
        : today.subtract(const Duration(days: 1));

    while (true) {
      String key =
          "${dateToCheck.year}-${dateToCheck.month.toString().padLeft(2, '0')}-${dateToCheck.day.toString().padLeft(2, '0')}";
      if ((tempHistory[key] ?? 0) >= dailyGoal) {
        streak++;
        dateToCheck = dateToCheck.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    int total7 = 0;
    for (int i = 0; i < 7; i++) {
      DateTime d = today.subtract(Duration(days: i));
      String k =
          "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
      total7 += tempHistory[k] ?? 0;
    }

    int total30 = 0;
    for (int i = 0; i < 30; i++) {
      DateTime d = today.subtract(Duration(days: i));
      String k =
          "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
      total30 += tempHistory[k] ?? 0;
    }

    setState(() {
      _history = tempHistory;
      _dailyGoal = dailyGoal;
      _streak = streak;
      _avg7Days = total7 ~/ 7;
      _avg30Days = total30 ~/ 30;
      _totalAllTime = totalAllTime;
    });
  }

  Color _getDayColor(DateTime day) {
    String key =
        "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";
    int amount = _history[key] ?? 0;
    if (amount == 0) return Colors.transparent;
    return amount >= _dailyGoal ? Colors.green.shade400 : Colors.red.shade400;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hydration Calendar')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          "Streak",
                          "$_streak",
                          Icons.local_fire_department,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          "Weekly Avg.",
                          "$_avg7Days",
                          Icons.water_drop,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          "Monthly Avg.",
                          "$_avg30Days",
                          Icons.analytics,
                          Colors.purple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.teal.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star, color: Colors.teal, size: 28),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "All-Time Total",
                              style: TextStyle(
                                color: Colors.teal,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "$_totalAllTime ml",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            TableCalendar(
              firstDay: DateTime.utc(2024, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: CalendarFormat.month,
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  Color bgColor = _getDayColor(day);
                  return Container(
                    margin: const EdgeInsets.all(6.0),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: bgColor,
                      shape: BoxShape.circle,
                      border: bgColor == Colors.transparent
                          ? Border.all(color: Colors.grey.shade200)
                          : null,
                    ),
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color: bgColor == Colors.transparent
                            ? Colors.black87
                            : Colors.white,
                      ),
                    ),
                  );
                },
                todayBuilder: (context, day, focusedDay) {
                  return Container(
                    margin: const EdgeInsets.all(6.0),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blueAccent, width: 2),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${day.day}',
                      style: const TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegend(Colors.green.shade400, "Goal Met"),
                const SizedBox(width: 20),
                _buildLegend(Colors.red.shade400, "Goal Missed"),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// --- CUSTOM DRAWINGS FOR BOTTLE ---
class BottleClipPath extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    double w = size.width;
    double h = size.height;

    double neckWidth = w * 0.4;
    double neckLeft = (w - neckWidth) / 2;
    double neckRight = neckLeft + neckWidth;

    // Start top left neck
    path.moveTo(neckLeft, 0);
    // Top flat
    path.lineTo(neckRight, 0);
    // Neck right side
    path.lineTo(neckRight, h * 0.15);
    // Shoulder right side
    path.quadraticBezierTo(w, h * 0.2, w, h * 0.3);
    // Body right side
    path.lineTo(w, h * 0.95);
    // Bottom right corner
    path.quadraticBezierTo(w, h, w * 0.85, h);
    // Bottom flat
    path.lineTo(w * 0.15, h);
    // Bottom left corner
    path.quadraticBezierTo(0, h, 0, h * 0.95);
    // Body left side
    path.lineTo(0, h * 0.3);
    // Shoulder left side
    path.quadraticBezierTo(0, h * 0.2, neckLeft, h * 0.15);
    // Neck left side
    path.lineTo(neckLeft, 0);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class BottleOutlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    final path = BottleClipPath().getClip(size);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
