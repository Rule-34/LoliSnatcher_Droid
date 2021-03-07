import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class InfoDialog extends StatefulWidget {
  String title;
  List<Widget> bodyWidgets;
  CrossAxisAlignment horizontalAlignment;
  @override
  _InfoDialogState createState() => _InfoDialogState();
  InfoDialog(this.title,this.bodyWidgets,this.horizontalAlignment);
}

class _InfoDialogState extends State<InfoDialog> {
  List<Widget> widgets = [];
  @override
  void initState(){
    super.initState();
    widgets.insert(0, Text(widget.title, textScaleFactor: 2,));
    widgets.addAll(widget.bodyWidgets);
  }
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.title, textScaleFactor: 2,),
            Container(
                margin: EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: widget.horizontalAlignment,
                  children: widget.bodyWidgets,
                )
            )
          ],
        ),
    );
  }
}


