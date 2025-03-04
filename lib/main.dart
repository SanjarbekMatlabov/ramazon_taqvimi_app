import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const RamadanApp());
}

class RamadanApp extends StatelessWidget {
  const RamadanApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ramazon Taqvimi',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Roboto',
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2E7D32), // Forest Green
          elevation: 0,
        ),
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          color: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF4CAF50), // Green
            foregroundColor: Colors.white,
          ),
        ),
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A237E),
          elevation: 0,
        ),
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          color: Color(0xFF283593),
        ),
      ),
      themeMode: ThemeMode.system,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('uz', 'UZ'),
        Locale('ru', 'RU'),
        Locale('en', 'US'),
      ],
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> ramadanData = [];
  Map<String, dynamic> selectedCity = {'name': 'Toshkent', 'offset': 0};
  bool isLoading = true;
  String currentDate = '';
  int currentDayIndex = 0;
  Map<String, dynamic>? currentDayData;
  bool useNotifications = true;
  bool useWidgets = true;
  String selectedLanguage = 'uz';
  bool showDuas = true;
  ThemeMode selectedThemeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final cityName = prefs.getString('selectedCity') ?? 'Toshkent';
    final cityOffset = prefs.getInt('cityOffset') ?? 0;
    final notif = prefs.getBool('useNotifications') ?? true;
    final widget = prefs.getBool('useWidgets') ?? true;
    final lang = prefs.getString('language') ?? 'uz';
    final dua = prefs.getBool('showDuas') ?? true;
    final theme = prefs.getString('themeMode') ?? 'system';

    setState(() {
      selectedCity = {'name': cityName, 'offset': cityOffset};
      useNotifications = notif;
      useWidgets = widget;
      selectedLanguage = lang;
      showDuas = dua;
      selectedThemeMode = theme == 'light'
          ? ThemeMode.light
          : theme == 'dark'
              ? ThemeMode.dark
              : ThemeMode.system;
    });

    String jsonString = await rootBundle.loadString('assets/ramadan_data.json');
    List<dynamic> data = json.decode(jsonString);

    setState(() {
      ramadanData = List<Map<String, dynamic>>.from(data);
      isLoading = false;

      final now = DateTime.now();
      currentDate = DateFormat('d MMMM yyyy').format(now);

      for (int i = 0; i < ramadanData.length; i++) {
        DateTime date = DateTime(2025, 3, ramadanData[i]['day']);
        if (now.day == date.day && now.month == date.month) {
          currentDayIndex = i;
          currentDayData = ramadanData[i];
          break;
        }
      }

      if (currentDayData == null && ramadanData.isNotEmpty) {
        currentDayIndex = 0;
        currentDayData = ramadanData[0];
      }
    });
  }

  String adjustTime(String time, int offset) {
    final parts = time.split(':');
    if (parts.length != 2) return time;

    int hour = int.parse(parts[0]);
    int minute = int.parse(parts[1]);

    final totalMinutes = hour * 60 + minute + offset;
    hour = totalMinutes ~/ 60;
    minute = totalMinutes % 60;

    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (isLoading) {
      return Scaffold(
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return MaterialApp(
      themeMode: selectedThemeMode,
      theme: Theme.of(context).copyWith(),
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: Colors.blue,
        cardColor: Color(0xFF283593),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text(
            'Ramazon Taqvimi 1446 / 2025',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsPage(
                      selectedCity: selectedCity,
                      useNotifications: useNotifications,
                      useWidgets: useWidgets,
                      selectedLanguage: selectedLanguage,
                      showDuas: showDuas,
                      selectedThemeMode: selectedThemeMode,
                      onSettingsChanged: loadData,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDarkMode
                  ? [Color(0xFF1A237E), Color(0xFF121212)]
                  : [Color(0xFF81C784), Color(0xFFE8F5E9)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                currentDate,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.white : Colors.black87,
                                ),
                              ),
                              Text(
                                selectedCity['name'],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: isDarkMode ? Colors.white70 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          if (currentDayData != null) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                TimeInfoColumn(
                                  title: 'Saharlik',
                                  time: adjustTime(currentDayData!['sahoor'], selectedCity['offset']),
                                  icon: Icons.nights_stay,
                                  isDarkMode: isDarkMode,
                                ),
                                TimeInfoColumn(
                                  title: 'Iftorlik',
                                  time: adjustTime(currentDayData!['iftar'], selectedCity['offset']),
                                  icon: Icons.wb_sunny,
                                  isDarkMode: isDarkMode,
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                if (showDuas) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              'Saharlik Duosi',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Navaytu an asuma sovma shahri ramazona minal fajri ilal mag'ribi, xolisan lillahi ta'ala. Allohu akbar.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: isDarkMode ? Colors.white70 : Colors.black54,
                              ),
                            ),
                            const Divider(height: 24),
                            Text(
                              'Iftorlik Duosi',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Allohumma laka sumtu va bika amantu va a'layka tavakkaltu va a'la rizqika aftortu, fag'firliy ya G'offaru ma qoddamtu va ma axxortu.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: isDarkMode ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(8),
                        itemCount: ramadanData.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final dayData = ramadanData[index];
                          final isCurrentDay = index == currentDayIndex;

                          return ListTile(
                            tileColor: isCurrentDay
                                ? (isDarkMode ? Colors.blue.withOpacity(0.3) : Colors.green.withOpacity(0.1))
                                : null,
                            leading: CircleAvatar(
                              backgroundColor: isCurrentDay
                                  ? (isDarkMode ? Colors.blue : Colors.green)
                                  : (isDarkMode ? Colors.blueGrey.shade700 : Colors.grey.shade200),
                              child: Text(
                                dayData['day'].toString(),
                                style: TextStyle(
                                  color: isCurrentDay
                                      ? Colors.white
                                      : (isDarkMode ? Colors.white70 : Colors.black54),
                                ),
                              ),
                            ),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  dayData['weekday'],
                                  style: TextStyle(
                                    fontWeight: isCurrentDay ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                Text(
                                  '${dayData['day']} mart',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDarkMode ? Colors.white70 : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Saharlik: ${adjustTime(dayData['sahoor'], selectedCity['offset'])}',
                                  style: TextStyle(
                                    color: isDarkMode ? Colors.lightBlue.shade100 : Colors.blue.shade700,
                                  ),
                                ),
                                Text(
                                  'Iftorlik: ${adjustTime(dayData['iftar'], selectedCity['offset'])}',
                                  style: TextStyle(
                                    color: isDarkMode ? Colors.amber.shade100 : Colors.orange.shade700,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TimeInfoColumn extends StatelessWidget {
  final String title;
  final String time;
  final IconData icon;
  final bool isDarkMode;

  const TimeInfoColumn({
    Key? key,
    required this.title,
    required this.time,
    required this.icon,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          size: 32,
          color: title == 'Saharlik'
              ? (isDarkMode ? Colors.lightBlue.shade100 : Colors.blue.shade700)
              : (isDarkMode ? Colors.amber.shade100 : Colors.orange.shade700),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          time,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: title == 'Saharlik'
                ? (isDarkMode ? Colors.lightBlue.shade100 : Colors.blue.shade700)
                : (isDarkMode ? Colors.amber.shade100 : Colors.orange.shade700),
          ),
        ),
      ],
    );
  }
}

class SettingsPage extends StatefulWidget {
  final Map<String, dynamic> selectedCity;
  final bool useNotifications;
  final bool useWidgets;
  final String selectedLanguage;
  final bool showDuas;
  final ThemeMode selectedThemeMode;
  final Function onSettingsChanged;

  const SettingsPage({
    Key? key,
    required this.selectedCity,
    required this.useNotifications,
    required this.useWidgets,
    required this.selectedLanguage,
    required this.showDuas,
    required this.selectedThemeMode,
    required this.onSettingsChanged,
  }) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late Map<String, dynamic> selectedCity;
  late bool useNotifications;
  late bool useWidgets;
  late String selectedLanguage;
  late bool showDuas;
  late ThemeMode selectedThemeMode;

  final List<Map<String, dynamic>> cities = [
    {'name': 'Toshkent', 'offset': 0},
    {'name': 'Samarqand', 'offset': -2},
    {'name': 'Buxoro', 'offset': -3},
    {'name': 'Namangan', 'offset': 2},
    {'name': 'Andijon', 'offset': 3},
    {'name': 'Farg\'ona', 'offset': 2},
    {'name': 'Qarshi', 'offset': -2},
    {'name': 'Nukus', 'offset': -9},
    {'name': 'Termiz', 'offset': -5},
  ];

  @override
  void initState() {
    super.initState();
    selectedCity = Map<String, dynamic>.from(widget.selectedCity);
    useNotifications = widget.useNotifications;
    useWidgets = widget.useWidgets;
    selectedLanguage = widget.selectedLanguage;
    showDuas = widget.showDuas;
    selectedThemeMode = widget.selectedThemeMode;
  }

  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedCity', selectedCity['name']);
    await prefs.setInt('cityOffset', selectedCity['offset']);
    await prefs.setBool('useNotifications', useNotifications);
    await prefs.setBool('useWidgets', useWidgets);
    await prefs.setString('language', selectedLanguage);
    await prefs.setBool('showDuas', showDuas);
    await prefs.setString(
        'themeMode',
        selectedThemeMode == ThemeMode.light
            ? 'light'
            : selectedThemeMode == ThemeMode.dark
                ? 'dark'
                : 'system');

    widget.onSettingsChanged();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sozlamalar'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [Color(0xFF1A237E), Color(0xFF121212)]
                : [Color(0xFF81C784), Color(0xFFE8F5E9)],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shahar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedCity['name'],
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: isDarkMode ? Colors.blueGrey.shade800 : Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items: cities.map((city) {
                        return DropdownMenuItem<String>(
                          value: city['name'],
                          child: Text(city['name']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedCity = cities.firstWhere((city) => city['name'] == value);
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Til',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedLanguage,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: isDarkMode ? Colors.blueGrey.shade800 : Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem<String>(
                          value: 'uz',
                          child: Text('O\'zbek'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'ru',
                          child: Text('Русский'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'en',
                          child: Text('English'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedLanguage = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mavzu',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<ThemeMode>(
                      value: selectedThemeMode,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: isDarkMode ? Colors.blueGrey.shade800 : Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: ThemeMode.system,
                          child: Text('Tizim bo\'yicha'),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.light,
                          child: Text('Yorug\'lik'),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.dark,
                          child: Text('Qorong\'i'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedThemeMode = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Xususiyatlar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text('Eslatmalar'),
                      subtitle: const Text('Saharlik va iftorlik vaqtlari uchun eslatmalar'),
                      value: useNotifications,
                      onChanged: (value) {
                        setState(() {
                          useNotifications = value;
                        });
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Bosh ekran vidjetlari'),
                      subtitle: const Text('Ramazon vaqtlarini bosh ekranda ko\'rsatish'),
                      value: useWidgets,
                      onChanged: (value) {
                        setState(() {
                          useWidgets = value;
                        });
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Duo matnlari'),
                      subtitle: const Text('Saharlik va iftorlik duolarini ko\'rsatish'),
                      value: showDuas,
                      onChanged: (value) {
                        setState(() {
                          showDuas = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                await saveSettings();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Saqlash',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}