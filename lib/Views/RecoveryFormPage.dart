import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:intl/intl.dart';
import 'package:order_booking_shop/API/Globals.dart';

import 'package:order_booking_shop/Models/RecoveryFormModel.dart';
import 'package:order_booking_shop/View_Models/RecoveryFormViewModel.dart';
import 'package:order_booking_shop/Views/RecoveryForm_2ndPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../API/DatabaseOutputs.dart';
import '../Databases/DBHelper.dart';

class RecoveryFromPage extends StatefulWidget {
  @override
  _RecoveryFromPageState createState() => _RecoveryFromPageState();
}

class _RecoveryFromPageState extends State<RecoveryFromPage> {
  String recoveryFormCurrentMonth = DateFormat('MMM').format(DateTime.now());
  bool isButtonPressed = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final recoveryformViewModel = Get.put(RecoveryFormViewModel());
  TextEditingController _dateController = TextEditingController();
  TextEditingController _currentBalanceController = TextEditingController();
  // TextEditingController _textField3Controller = TextEditingController();
  TextEditingController _cashRecoveryController = TextEditingController();
  TextEditingController _netBalanceController = TextEditingController();
  List<Map<String, dynamic>> accountsData = []; // Add this line
  String? selectedShopName;
  String selectedShopBrand = '';
  String selectedShopCityR = '';
  List<String> dropdownItems = [];
  List<String> dropdownItems1 = [];
  String? selectedDropdownValue;
  List<Map<String, dynamic>> shopOwners = [];
  DBHelper dbHelper = DBHelper();
  double recoveryFormCurrentBalance = 0.0;
  String recoveryFormCurrentUserId = '';
  int recoveryFormSerialCounter = RecoveryhighestSerial?? 0;



  @override
  void initState() {
    super.initState();
    data();
    _loadRecoveryFormCounter();
    //selectedDropdownValue = dropdownItems[0];
    _dateController.text = getCurrentDate();
    _cashRecoveryController.text = ''; // Assuming initial value is zero
    _netBalanceController.text = '0'; // Assuming initial value is zero
    //fetchShopData();
    onCreatee();
    //fetchShopNames();
    // fetchShopData();
    print(RecoveryhighestSerial);
    fetchShopNamesAndTotals();
    fetchAccountsData();
    fetchShopData1();
    // Add this line
  }

  data(){
    DBHelper dbHelper = DBHelper();
    print('data0');
    dbHelper.getRecoveryHighestSerialNo();
  }

  String? validateCashRecovery(String value) {
    if (value.isEmpty) {
      showToast('Please enter some text');
      return 'Please enter some text';
    } else if (!RegExp(r'^[0-9.]+$').hasMatch(value)) {
      showToast('Please enter valid numbers');
      return 'Please enter valid numbers';
    }

    // Convert values to double for comparison
    double cashRecovery = double.parse(value);
    double currentBalance = double.parse(_currentBalanceController.text);

    // Check if cash recovery is greater than current balance
    if (cashRecovery > currentBalance) {
      showToast('Cash recovery cannot be greater than current balance');
      _cashRecoveryController.clear();
      _netBalanceController.clear();
      return 'Cash recovery cannot be greater than current balance';
    }

    // Check if cash recovery is zero
    if (cashRecovery == 0) {
      showToast('Cash recovery cannot be zero');
      _cashRecoveryController.clear();
      _netBalanceController.clear();
      return 'Cash recovery cannot be zero';
    }

    return null;
  }


  void showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  Future<void> fetchAccountsData() async {
    DBHelper dbHelper = DBHelper();
    List<Map<String, dynamic>>? accounts = await dbHelper.getAccoutsDB();

    setState(() {
      // Filter accountsData based on the selected shop name
      accountsData = accounts
          ?.where((account) =>
      account['order_date'] != null &&
          account['credit'] != null &&
          account['booker_name'] != null &&
          account['shop_name'] == selectedShopName)
          .toList() ??
          [];

      // Reverse the list to get the latest orders at the beginning
      accountsData = accountsData.reversed.toList();

      // Limit to a maximum of three rows
      accountsData = accountsData.length > 3 ? accountsData.sublist(0, 3) : accountsData;
    });
  }



  Future<void> onCreatee() async {
    DatabaseOutputs db = DatabaseOutputs();
    await db.showRecoveryForm();

    // DatabaseOutputs outputs = DatabaseOutputs();
    // outputs.checkFirstRun();

  }


  // void fetchShopData() async {
  //   List<String> shopNames = await dbHelper.getOrderMasterShopNames();
  //   shopOwners = (await dbHelper.getOrderMasterDB())!;
  //   //final shopOwners = await dbHelper.getOwnersDB();
  //   print(shopOwners);
  //
  //   setState(() {
  //     dropdownItems = shopNames.toSet().toList();
  //   });
  // }

  Future<void> fetchShopNamesAndTotals() async {
    DBHelper dbHelper = DBHelper();

    // Calculate total debits, credits, and debits minus credits per shop
    Map<String, dynamic> debitsAndCredits = await dbHelper.getDebitsAndCreditsTotal();
    Map<String, double> debitsMinusCreditsPerShop = await dbHelper.getDebitsMinusCreditsPerShop();

    // Extract shop names, debits, credits, and debits minus credits per shop
    List<String> shopNames = debitsAndCredits['debits'].keys.toList();
    Map<String, double> shopDebits = debitsAndCredits['debits'];
    Map<String, double> shopCredits = debitsAndCredits['credits'];

    // Print or use the shop names, debits, credits, and debits minus credits per shop as needed
    print("Shop Names: $shopNames");
    print("Shop Debits: $shopDebits");
    print("Shop Credits: $shopCredits");
    print("Shop Debits - Credits: $debitsMinusCreditsPerShop");

    // You can update the state or perform other actions with the data here
  }
  Future<void> fetchNetBalanceForShop(String shopName) async {
    DBHelper dbHelper = DBHelper();
    double shopDebits = 0.0;
    double shopCredits = 0.0;

    // Fetch net balance for the selected shop
    List<Map<String, dynamic>>? netBalanceData = await dbHelper.getNetBalanceDB();
    for (var row in netBalanceData!) {
      if (row['shop_name'] == shopName) {
        shopDebits += double.parse(row['debit'] ?? '0');
        shopCredits += double.parse(row['credit'] ?? '0');
      }
    }

    // Calculate net balance (shop debits - shop credits)
    double netBalance = shopDebits - shopCredits;

    // Ensure net balance is not less than 0
    netBalance = netBalance < 0 ? 0 : netBalance;

    setState(() {
      // Update the current balance field with the calculated net balance
      recoveryFormCurrentBalance = netBalance;
      // globalnetBalance = netBalance;
      _currentBalanceController.text = recoveryFormCurrentBalance.toString();
    });
  }
  Future<bool> isInternetAvailable() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
    } on SocketException catch (_) {
      return false;
    }
    return false;
  }
  // void fetchShopData() async {
  //   List<String> shopNames = await dbHelper.getOrderMasterShopNames2();
  //   shopOwners = (await dbHelper.getOrderMasterDB())!;
  //
  //   // Remove duplicates from the shopNames list
  //   List<String> uniqueShopNames = shopNames.toSet().toList();
  //
  //   setState(() {
  //     dropdownItems = uniqueShopNames;
  //   });
  // }
  void fetchShopData1() async {
    List<String> shopNames = await dbHelper.getOrderMasterShopNames();
    shopOwners = (await dbHelper.getOrderBookingStatusDB())!;
    setState(() {
      dropdownItems1 = shopNames.toSet().toList();
    });
  }

  // void fetchShopData1() async {
  //   List<Map<String, dynamic>> shopOwners = await dbHelper.getOrderMasterShopNames();
  //   List<String> shopNames = shopOwners.map((map) => map['shop_name'] as String).toList();
  //   setState(() {
  //     dropdownItems1 = shopNames.toSet().toList();
  //   });
  // }


  // Future<void> fetchShopNames() async {
  //   DBOrderMasterGet dbHelper = DBOrderMasterGet();
  //   List<String>? shopNames = await dbHelper.getShopNamesFromNetBalance();
  //
  //   // Remove duplicates from the shopNames list
  //   List<String> uniqueShopNames = shopNames!.toSet().toList();
  //
  //   setState(() {
  //     dropdownItems = uniqueShopNames;
  //     // selectedDropdownValue = uniqueShopNames.isNotEmpty ? uniqueShopNames[0] : null;
  //   });
  // }

  void showLoadingIndicator(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Please Wait..."),
            ],
          ),
        );
      },
    );
  }
  String getCurrentDate() {
    final now = DateTime.now();
    final formatter = DateFormat('dd-MMM-yyyy');
    return formatter.format(now);
  }

  void updateNetBalance() {
    double totalAmount = double.tryParse(_currentBalanceController.text) ?? 0;
    double cashRecovery = double.tryParse(_cashRecoveryController.text) ?? 0;
    double netBalance = totalAmount - cashRecovery;
    _netBalanceController.text = netBalance.toString();
  }

  _loadRecoveryFormCounter() async {
    String currentMonth = DateFormat('MMM').format(DateTime.now());
    if (this.recoveryFormCurrentMonth != currentMonth) {
      recoveryFormSerialCounter = 1;
      this.recoveryFormCurrentMonth = currentMonth;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    //prefs.remove('recoveryFormCurrentMonth')  ;
    setState(() {
      recoveryFormSerialCounter = (prefs.getInt('recoveryFormSerialCounter') ?? RecoveryhighestSerial??1);
      recoveryFormCurrentMonth = prefs.getString('recoveryFormCurrentMonth') ?? recoveryFormCurrentMonth;
      recoveryFormCurrentUserId = prefs.getString('recoveryFormCurrentUserId') ?? '';
    });
    print('SR:$recoveryFormSerialCounter');
  }

  _saveRecoveryFormCounter() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('recoveryFormSerialCounter', recoveryFormSerialCounter);
    await prefs.setString('recoveryFormCurrentMonth', recoveryFormCurrentMonth);
    await prefs.setString('recoveryFormCurrentUserId', recoveryFormCurrentUserId);
  }

  String generateNewRecoveryFormOrderId(String Receipt, String userId) {
    String currentMonth = DateFormat('MMM').format(DateTime.now());

    if (this.recoveryFormCurrentUserId != userId) {
      recoveryFormSerialCounter = RecoveryhighestSerial?? 1;
      this.recoveryFormCurrentUserId = userId;
    }

    if (this.recoveryFormCurrentMonth != currentMonth) {
      recoveryFormSerialCounter = 1;
      this.recoveryFormCurrentMonth = currentMonth;
    }

    String orderId =
        "$Receipt-$userId-$currentMonth-${recoveryFormSerialCounter.toString().padLeft(3, '0')}";
    recoveryFormSerialCounter++;
    _saveRecoveryFormCounter();
    return orderId;
  }


  @override
  Widget build(BuildContext context) {
    double inputWidth = MediaQuery.of(context).size.width * 0.25;
    double dropdownWidth = 1000;


    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white10,
          title: Text(
            'Recovery Form',
            style: TextStyle(fontSize: 16, color: Colors.black),
          ),
          centerTitle: true,
        ),
        body: Form(
            key: _formKey,
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Date:',
                            style: TextStyle(fontSize: 14, color: Colors.black),
                          ),
                          Text(
                            getCurrentDate(),
                            style: TextStyle(fontSize: 14, color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Shop Name',
                              style: TextStyle(fontSize: 16, color: Colors.black),
                            ),
                          ),
                          SizedBox(height: 10),
                          TypeAheadFormField(
                            textFieldConfiguration: TextFieldConfiguration(
                              controller: TextEditingController(text: selectedDropdownValue),
                              decoration: InputDecoration(
                                hintText: '--Select Shop--',
                                border: OutlineInputBorder(

                                  borderRadius: BorderRadius.circular(5.0),
                                ),
                              ),
                            ),
                            suggestionsCallback: (pattern) {
                              return dropdownItems1
                                  .where((item) =>
                                  item.toLowerCase().contains(pattern.toLowerCase()))
                                  .toList();
                            },
                            itemBuilder: (context, suggestion) {
                              return ListTile(
                                title: Text(suggestion),
                              );
                            },
                            onSuggestionSelected: (suggestion) {
                              setState(() {
                                selectedDropdownValue = suggestion;
                                selectedShopName = suggestion;
                                // Fetch and display the net balance for the selected shop
                                fetchNetBalanceForShop(selectedDropdownValue!);
                                fetchAccountsData();
                              });
                              for (var owner in shopOwners) {
                                if (owner['shop_name'] == selectedShopName) {
                                  setState(() {
                                    selectedShopBrand = owner['brand'];
                                    selectedShopCityR= owner['city'];
                                    print(selectedShopCityR);
                                  });
                                }
                              }
                            },
                          ),
                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Column(
                                children: [
                                  Row(
                                    children: [
                                      Text('Current Balance'),
                                      SizedBox(width: 10),
                                      Container(
                                        height: 30,
                                        width: 150,
                                        child: TextFormField(
                                          controller: _currentBalanceController,
                                          readOnly: true,
                                          decoration: InputDecoration(
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(5.0),
                                            ),
                                          ),
                                          textAlign: TextAlign.left,
                                          validator: (value) {
                                            if (value!.isEmpty) {
                                              return 'Please enter some text';
                                            }
                                            double currentBalance = double.parse(value);
                                            if (currentBalance < 1) {
                                              return 'Current balance should be at least 1';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          Center(
                            child: Text(
                              '----- Previous Payment History -----',
                              style: TextStyle(fontSize: 15, color: Colors.black),
                            ),
                          ),
                          SizedBox(height: 20),

                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: DataTable(
                                columns: [
                                  DataColumn(label: Text('Date')),
                                  DataColumn(label: Text('Shop')),
                                  DataColumn(label: Text('Amount')),
                                ],

                                // Modify the DataRow creation inside the DataTable
                                rows: accountsData.map(
                                      (account) => DataRow(
                                    cells: [
                                      DataCell(Text(account['order_date'] ?? '')),
                                      DataCell(Text(account['shop_name'] ?? '')),
                                      DataCell(Text(account['credit']?.toString() ?? '')),
                                    ],
                                  ),
                                ).toList(),


                              ),
                            ),
                          ),

                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Column(
                                children: [
                                  Row(
                                    children: [
                                      Text('Cash Recovery      '),
                                      SizedBox(width: 10),
                                      Container(
                                        height: 30,

                                        width: 175,
                                        child: TextFormField(
                                          controller: _cashRecoveryController,
                                          onChanged: (value) {
                                            updateNetBalance();
                                          },
                                          decoration: InputDecoration(
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(5.0),
                                            ),
                                          ),
                                          textAlign: TextAlign.left,
                                          validator: (value) {
                                            if (value!.isEmpty) {
                                              return 'Please enter some text';
                                            } else if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                                              return 'Please enter digits only';
                                            }

                                            // Convert values to double for comparison
                                            double cashRecovery = double.parse(value);
                                            double currentBalance = double.parse(_currentBalanceController.text);

                                            // Check if cash recovery is greater than current balance
                                            if (cashRecovery > currentBalance) {
                                              selectedDropdownValue='';
                                              _currentBalanceController.clear();
                                              _cashRecoveryController.clear();
                                              _netBalanceController.clear();

                                              return 'Cash recovery cannot be greater than current balance';
                                            }
                                            return null;
                                          },
                                          keyboardType: TextInputType.number, // Restrict keyboard to numeric
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Column(
                                children: [
                                  Row(
                                    children: [
                                      Text('Net Balance          '),
                                      SizedBox(width: 10),
                                      Container(
                                        height: 30,
                                        width: 175,
                                        child: TextFormField(
                                          controller: _netBalanceController,
                                          readOnly: true,
                                          decoration: InputDecoration(
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(5.0),
                                            ),
                                          ),
                                          textAlign: TextAlign.left,
                                          validator: (value) {
                                            if (value!.isEmpty) {
                                              return 'Please enter some text';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),

                          SizedBox(height: 20),

                          ElevatedButton(
                            onPressed: () async {
                              showLoadingIndicator(context);
                             final  bool isConnected = await isInternetAvailable();
                              Navigator.of(context, rootNavigator: true).pop();
                              if (!isConnected) {
                                showToast('Please check your internet connection.');
                                return; // Exit the function early if internet connection is not available
                              }


                              if (_cashRecoveryController.text.isNotEmpty && _netBalanceController.text.isNotEmpty) {
                                if (selectedDropdownValue != null && selectedDropdownValue!.isNotEmpty) {
                                  double cashRecovery = double.tryParse(_cashRecoveryController.text) ?? 0.0;
                                  if (cashRecovery > 0 && cashRecovery <= recoveryFormCurrentBalance) {
                                        String newOrderId2 = generateNewRecoveryFormOrderId(Receipt, userId.toString());
                                      await  recoveryformViewModel.addRecoveryForm(
                                          RecoveryFormModel(
                                            recoveryId: newOrderId2,
                                            shopName: selectedDropdownValue,
                                            cashRecovery: _cashRecoveryController.text,
                                            netBalance: _netBalanceController.text,
                                            date: getCurrentDate(),
                                            userId: userId,
                                            bookerName: userNames,
                                            city: selectedShopCityR,
                                            brand: selectedShopBrand
                                          ),
                                        );

                                        DBHelper dbrecoveryform = DBHelper();
                                        dbrecoveryform.postRecoveryFormTable();

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => RecoveryForm_2ndPage(
                                          formData: {
                                            'recoveryId': newOrderId2,
                                            'shopName': selectedDropdownValue,
                                            'cashRecovery': _cashRecoveryController.text,
                                            'netBalance': _netBalanceController.text,
                                            'date': getCurrentDate(),
                                          },
                                        ),
                                      ),
                                    );
                                  } else {
                                    if (cashRecovery <= 0) {
                                      showToast('Cash recovery must be greater than 0.');
                                    } else {
                                      showToast('Cash recovery cannot be greater than the current balance.');
                                    }
                                  }
                                } else {
                                  showToast('Please select a shop before moving to the next page.');
                                }
                              } else {
                                showToast('Please fill in all fields before moving to the next page.');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Submit',
                              style: TextStyle(
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ],
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