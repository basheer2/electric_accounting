import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
      theme: ThemeData.dark(),
    );
  }
}

class WorkItem {
  String name;
  double total;
  double paid;
  String date;

  WorkItem(this.name, this.total, this.paid, this.date);

  Map<String, dynamic> toJson() => {
    "name": name,
    "total": total,
    "paid": paid,
    "date": date,
  };

  static WorkItem fromJson(Map<String, dynamic> json) {
    return WorkItem(
      json["name"],
      json["total"],
      json["paid"],
      json["date"],
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<WorkItem> items = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString("db");
    if (data != null) {
      List list = jsonDecode(data);
      items = list.map((e) => WorkItem.fromJson(e)).toList();
      setState(() {});
    }
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString("db", jsonEncode(items));
  }

  void add() {
    final name = TextEditingController();
    final total = TextEditingController();
    final paid = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("إضافة"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name),
            TextField(controller: total),
            TextField(controller: paid),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              items.add(WorkItem(
                name.text,
                double.tryParse(total.text) ?? 0,
                double.tryParse(paid.text) ?? 0,
                DateTime.now().toString().substring(0, 10),
              ));
              await save();
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text("حفظ"),
          )
        ],
      ),
    );
  }

  double get t => items.fold(0, (a, b) => a + b.total);
  double get p => items.fold(0, (a, b) => a + b.paid);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("محاسبة كهربائي")),
      floatingActionButton: FloatingActionButton(
        onPressed: add,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Card(
            child: ListTile(
              title: Text("الإجمالي: $t"),
              subtitle: Text("المستلم: $p | المتبقي: ${t - p}"),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (_, i) {
                final x = items[i];
                return ListTile(
                  title: Text(x.name),
                  subtitle: Text(x.date),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async {
                      items.removeAt(i);
                      await save();
                      setState(() {});
                    },
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
