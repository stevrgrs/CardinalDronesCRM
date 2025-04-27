import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(CardinalDronesCRM());
}

class CardinalDronesCRM extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cardinal Drones CRM',
      theme: ThemeData(primarySwatch: Colors.red),
      home: ClientListScreen(),
    );
  }
}

class Client {
  final String id;
  final String firstName;
  final String lastName;
  final String phone;

  Client(
      {required this.id,
      required this.firstName,
      required this.lastName,
      required this.phone});

  factory Client.fromJson(Map<String, dynamic> json) => Client(
        id: json['id'],
        firstName: json['firstName'],
        lastName: json['lastName'],
        phone: json['phone'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
      };
}

class ClientListScreen extends StatefulWidget {
  @override
  _ClientListScreenState createState() => _ClientListScreenState();
}

class _ClientListScreenState extends State<ClientListScreen> {
  List<Client> clients = [];
  List<Client> searchResults = [];
  List<String> searchResultIds = [];
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadClients();
  }

  Future<void> loadClients() async {
    final prefs = await SharedPreferences.getInstance();
    final String? clientsString = prefs.getString('clients');
    if (clientsString != null) {
      List decoded = jsonDecode(clientsString);
      setState(() {
        clients = decoded.map((e) => Client.fromJson(e)).toList();
      });
    }
  }

  Future<void> saveClients() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(
        'clients', jsonEncode(clients.map((c) => c.toJson()).toList()));
  }

  void addClient(Client client) {
    setState(() {
      clients.add(client);
    });
    saveClients();
  }

  void deleteClient(int index) {
    setState(() {
      clients.removeAt(index);
    });
    saveClients();
  }

  void showAddClientDialog() {
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: Text('Add Client'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: firstNameController,
                    decoration: InputDecoration(labelText: 'First Name'),
                  ),
                  TextField(
                    controller: lastNameController,
                    decoration: InputDecoration(labelText: 'Last Name'),
                  ),
                  TextField(
                    controller: phoneController,
                    decoration: InputDecoration(labelText: 'Phone'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (firstNameController.text.isNotEmpty &&
                        lastNameController.text.isNotEmpty &&
                        phoneController.text.isNotEmpty) {
                      addClient(Client(
                          id: DateTime.now().toString(),
                          firstName: firstNameController.text.trim(),
                          lastName: lastNameController.text.trim(),
                          phone: phoneController.text.trim()));
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text('Add'),
                )
              ],
            ));
  }

  void searchClients(String query) {
    setState(() {
      searchResults = clients
          .where((client) =>
              ('${client.firstName} ${client.lastName}')
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              client.phone.contains(query))
          .toList();
      searchResultIds = searchResults.map((c) => c.id).toList();
    });
  }

  void showSearchDialog() {
    searchController.clear();
    showDialog(
        context: context,
        builder: (_) => StatefulBuilder(
              builder: (context, setStateDialog) => AlertDialog(
                title: Text('Search Clients'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: searchController,
                      decoration:
                          InputDecoration(labelText: 'Search by name or phone'),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      searchClients(searchController.text);
                      Navigator.of(context).pop();
                    },
                    child: Text('Submit'),
                  )
                ],
              ),
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Clients')),
      body: ListView.builder(
        itemCount: clients.length,
        itemBuilder: (context, index) {
          bool isHighlighted = searchResultIds.contains(clients[index].id);
          return Container(
            color: isHighlighted ? Colors.yellow.withOpacity(0.5) : null,
            child: ListTile(
              title: Text(
                  '${clients[index].firstName} ${clients[index].lastName}'),
              subtitle: Text(clients[index].phone),
              trailing: IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () => deleteClient(index),
              ),
            ),
          );
        },
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: showSearchDialog,
            child: Icon(Icons.search),
            heroTag: 'searchButton',
          ),
          SizedBox(width: 10),
          FloatingActionButton(
            onPressed: showAddClientDialog,
            child: Icon(Icons.add),
            heroTag: 'addButton',
          ),
        ],
      ),
    );
  }
}
