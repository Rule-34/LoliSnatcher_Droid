import 'dart:async';
import 'dart:io';

import 'package:LoliSnatcher/SearchGlobals.dart';
import 'package:LoliSnatcher/widgets/SettingsWidgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WaterfallErrorButtons extends StatefulWidget {
  WaterfallErrorButtons({Key? key}) : super(key: key);

  @override
  _WaterfallErrorButtonsState createState() => _WaterfallErrorButtonsState();
}

class _WaterfallErrorButtonsState extends State<WaterfallErrorButtons> {
  final SearchHandler searchHandler = Get.find<SearchHandler>();

  int _startedAt = 0;
  Timer? checkInterval;
  StreamSubscription<bool>? loadingListener;

  @override
  void initState() {
    super.initState();
    startTimer();
    loadingListener = searchHandler.isLoading.listen((bool isLoading) {
      if(isLoading) {
        startTimer();
      } else {
        stopTimer();
      }
    });
  }

  void updateState() {
    if (mounted) {
      setState(() {});
    }
  }

  void startTimer() {
    if (_startedAt == 0) {
      _startedAt = DateTime.now().millisecondsSinceEpoch;
      checkInterval?.cancel();
      checkInterval = Timer.periodic(const Duration(seconds: 1), (timer) {
        // force restate every second to refresh all timers/indicators, even when loading has stopped/slowed down
        updateState();
      });
    }
  }

  void stopTimer() {
    _startedAt = 0;
    checkInterval?.cancel();
    updateState();
  }

  @override
  void dispose() {
    checkInterval?.cancel();
    loadingListener?.cancel();
    super.dispose();
  }


  Widget wrapButton(Widget child) {
    return Container(color: Get.theme.colorScheme.background.withOpacity(0.66), child: child);
  }

  @override
  Widget build(BuildContext context) {
    final String errorFormatted = searchHandler.currentBooruHandler.errorString.isNotEmpty ? '\n${searchHandler.currentBooruHandler.errorString}' : '';
    final String clickName = (Platform.isWindows || Platform.isLinux) ? 'Click' : 'Tap';
    int nowMils = DateTime.now().millisecondsSinceEpoch;
    int sinceStart = _startedAt == 0 ? 0 : Duration(milliseconds: nowMils - _startedAt).inSeconds;
    String sinceStartText = sinceStart > 0 ? 'Started ${sinceStart.toString()} second${sinceStart == 1 ? '' : 's'} ago' : '';

    return Obx(() {
      if(searchHandler.isLastPage.value) {
        // if last page...
        if(searchHandler.currentFetched.length == 0) {
          // ... and no items loaded
          return wrapButton(SettingsButton(
            name: 'No Data Loaded',
            subtitle: Text('$clickName Here to Reload'),
            icon: Icon(Icons.refresh),
            dense: true,
            action: () {
              searchHandler.retrySearch();
            },
            drawBottomBorder: false,
          ));
        } else { //if(searchHandler.currentFetched.length > 0) {
          // .. has items loaded
          return wrapButton(SettingsButton(
            name: 'You Reached the End (${searchHandler.currentBooruHandler.pageNum} ${searchHandler.currentBooruHandler.pageNum.value == 1 ? 'page' : 'pages'})',
            subtitle: Text('$clickName Here to Reload Last Page'),
            icon: Icon(Icons.refresh),
            dense: true,
            action: () {
              searchHandler.retrySearch();
            },
            drawBottomBorder: false,
          ));
        }
      } else {
        // if not last page...
        if(searchHandler.isLoading.value) {
          // ... and is currently loading
          return wrapButton(SettingsButton(
            name: 'Loading Page #${searchHandler.currentBooruHandler.pageNum}',
            subtitle: AnimatedOpacity(
              opacity: sinceStartText.isNotEmpty ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Text(sinceStartText),
            ),
            icon: SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Get.theme.colorScheme.secondary)
              ),
            ),
            dense: true,
            action: () {
              searchHandler.retrySearch();
            },
            drawBottomBorder: false,
          ));
        } else {
          if (searchHandler.currentBooruHandler.errorString.isNotEmpty) {
            // ... if error happened
            return wrapButton(SettingsButton(
              name: 'Error happened when Loading Page #${searchHandler.currentBooruHandler.pageNum}: $errorFormatted',
              subtitle: Text('$clickName Here to Retry'),
              icon: Icon(Icons.refresh),
              dense: true,
              action: () {
                searchHandler.retrySearch();
              },
              drawBottomBorder: false,
            ));
          } else if(searchHandler.currentFetched.length == 0) {
            // ... no items loaded
            return wrapButton(SettingsButton(
              name: 'Error, no data loaded:',
              subtitle: Text('$clickName Here to Retry'),
              icon: Icon(Icons.refresh),
              dense: true,
              action: () {
                searchHandler.retrySearch();
              },
              drawBottomBorder: false,
            ));
          } else {
            // return const SizedBox.shrink();

            // add a small container to avoid scrolling when swiping from the bottom of the screen (navigation gestures)
            return Container(height: 10, color: Colors.transparent);
          }
        }
      }
    });
  }
}