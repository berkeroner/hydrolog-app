import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

void main() {
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
    });
  }

  Future<void> _saveIntake() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_getTodayKey(), _totalIntake);
  }

  void _addWater(int amount) {
    setState(() => _totalIntake += amount);
    _saveIntake();
  }

  @override
  Widget build(BuildContext context) {
    double progress = _totalIntake / _dailyGoal;
    if (progress > 1.0) progress = 1.0;

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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 240,
                  height: 240,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 15,
                    backgroundColor: Colors.blue.shade50,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 54,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Goal Reached',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 60),
            Text(
              '$_totalIntake / $_dailyGoal ml',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAddButton(250, 'Glass', Icons.local_drink),
                _buildAddButton(500, 'Bottle', Icons.water_drop),
              ],
            ),
          ],
        ),
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

  @override
  void initState() {
    super.initState();
    _loadAllHistory();
  }

  Future<void> _loadAllHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    Map<String, int> tempHistory = {};
    for (String key in keys) {
      if (RegExp(r'\d{4}-\d{2}-\d{2}').hasMatch(key)) {
        tempHistory[key] = prefs.getInt(key) ?? 0;
      }
    }
    setState(() {
      _history = tempHistory;
      _dailyGoal = prefs.getInt('daily_goal') ?? 2500;
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
      body: Column(
        children: [
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
        ],
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
}
