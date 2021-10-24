import 'dart:core';
import 'dart:io';
import 'package:LoliSnatcher/widgets/FlashElements.dart';
import 'package:LoliSnatcher/widgets/SettingsWidgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:LoliSnatcher/ServiceHandler.dart';
import 'package:LoliSnatcher/SettingsHandler.dart';
import 'package:LoliSnatcher/libBooru/LoliSync.dart';
import 'package:LoliSnatcher/pages/LoliSyncSendPage.dart';
import 'package:LoliSnatcher/pages/LoliSyncServerPage.dart';

class LoliSyncPage extends StatefulWidget {
  LoliSyncPage();
  @override
  _LoliSyncPageState createState() => _LoliSyncPageState();
}
class _LoliSyncPageState extends State<LoliSyncPage> {
  final SettingsHandler settingsHandler = Get.find();
  final ipController = TextEditingController();
  final portController = TextEditingController();
  bool favourites = false, settings = false, booru = false;
  final LoliSync loliSync = LoliSync();
  List<NetworkInterface> ipList = [];
  List<String> ipListNames = ['Auto', 'Localhost'];
  String selectedInterface = 'Auto';
  String? selectedAddress;

  final startPortController = TextEditingController();
  String startPort = '';

  Future<bool> _onWillPop() async {
    settingsHandler.lastSyncIp = ipController.text;
    settingsHandler.lastSyncPort = portController.text;
    settingsHandler.saveSettings();
    return true;
  }

  @override
  void initState() {
    super.initState();
    ipController.text = settingsHandler.lastSyncIp;
    portController.text = settingsHandler.lastSyncPort;
    getIPList();
  }

  void getIPList() async {
    List<NetworkInterface> temp = await ServiceHandler.getIPList();
    ipList.addAll(temp);
    ipListNames.addAll(temp.map((e) => e.name).toList());
    setState(() { });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Text("LoliSync"),
          leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () async {
                Get.back();
              }),
        ),
        body: Center(
          child: ListView(
            children: <Widget>[
              Container(
                margin: EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: Text(
                  "Start the server on another device it will show an ip and port, fill those in and then hit start sync to send data from this device to the other"),
                ),
              SettingsTextInput(
                controller: ipController,
                title: 'IP Address',
                hintText: "Host IP Address (i.e. 192.168.1.1)",
                inputType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9.]'))],
              ),
              SettingsTextInput(
                controller: portController,
                title: 'Port',
                hintText: "Host Port (i.e. 7777)",
                inputType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
              ),
              SettingsToggle(
                value: favourites,
                onChanged: (newValue) {
                  setState(() {
                    favourites = newValue;
                  });
                },
                title: 'Send Favourites',
              ),
              SettingsToggle(
                value: settings,
                onChanged: (newValue) {
                  setState(() {
                    settings = newValue;
                  });
                },
                title: 'Send Settings',
              ),
              SettingsToggle(
                value: booru,
                onChanged: (newValue) {
                  setState(() {
                    booru = newValue;
                  });
                },
                title: 'Send Booru Configs',
              ),

              SettingsButton(name: '', enabled: false),
              SettingsButton(
                name: 'Start Sync',
                icon: Icon(Icons.send_to_mobile),
                action: () {
                  bool isAddressEntered = ipController.text.isNotEmpty && portController.text.isNotEmpty;
                  bool isAnySyncSelected = favourites || settings || booru;
                  bool syncAllowed = isAddressEntered && isAnySyncSelected;

                  if(syncAllowed) {
                    var page = () => LoliSyncSendPage(ipController.text, portController.text, settings, favourites, booru);
                    // TODO move the desktop check and dialog build to separate unified function
                    if(Get.find<SettingsHandler>().appMode == "Desktop" || Platform.isWindows || Platform.isLinux) {
                      Get.dialog(Dialog(
                        child: Container(
                          width: 500,
                          child: page.call(),
                        ),
                      ));
                    } else {
                      Navigator.push(context, CupertinoPageRoute(builder: (BuildContext context) => page.call()));
                    }
                  } else {
                    String errorString = '???';
                    if (!isAddressEntered) {
                      errorString = 'The Port and IP fields cannot be empty!';
                    } else if (!isAnySyncSelected) {
                      errorString = "You haven't selected anything to sync!";
                    }
                    FlashElements.showSnackbar(
                      context: context,
                      title: Text(
                        "Error!",
                        style: TextStyle(fontSize: 20)
                      ),
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(errorString),
                        ],
                      ),
                      sideColor: Colors.red,
                      leadingIcon: Icons.error,
                      leadingIconColor: Colors.red,
                    );
                  }
                },
              ),

              SettingsButton(name: '', enabled: false),
              Container(
                margin: EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: Text("Start the server if you want your device to recieve data from another, do not use this on public wifi as you might get pozzed"),
              ),
              SettingsDropdown(
                selected: selectedInterface,
                values: ipListNames,
                onChanged: (String? newValue) {
                  selectedInterface = newValue!;
                  NetworkInterface? findInterface;
                  try {
                     findInterface = ipList.firstWhere((el) => el.name == newValue);
                  } catch (e) {
                    
                  }
                  if(newValue == 'Localhost') {
                    selectedAddress = '127.0.0.1';
                  } else {
                    selectedAddress = findInterface?.addresses[0].address;
                  }
                  setState(() { });
                },
                title: 'Available Network Interfaces'
              ),
              Container(
                margin: EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: Text('Selected Interface IP: ${selectedAddress ?? 'none'}'),
              ),
              SettingsTextInput(
                controller: startPortController,
                title: 'Start Server at Port',
                hintText: "Server Port (will default to '1234' if empty)",
                inputType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
              ),
              SettingsButton(
                name: 'Start Receiver Server',
                icon: Icon(Icons.dns_outlined),
                page: () => LoliSyncServerPage(selectedAddress, startPortController.text.isEmpty ? '1234' : startPortController.text),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
