import 'dart:io';

import 'package:band_name/models/band.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:provider/provider.dart';

import '../services/socket_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Band> bands = [];

  @override
  void initState() {
    final socketService = Provider.of<SocketService>(context, listen: false);
    socketService.socket.on('active-bands', _handleActiveBands);
    super.initState();
  }

  _handleActiveBands(dynamic payload) {
    this.bands = (payload as List).map((band) => Band.fromMap(band)).toList();
    setState(() {});
  }

  @override
  void dispose() {
    final socketService = Provider.of<SocketService>(context, listen: false);
    socketService.socket.off('active-bands');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final socketService = Provider.of<SocketService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '¡Vota por tu Favorito!',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        actions: <Widget>[
          Container(
            margin: EdgeInsets.only(right: 10),
            child: (socketService.serverStatus == ServerStatus.Online)
                ? Icon(Icons.wifi_rounded ,color: Colors.green[400])
                : Icon(Icons.wifi_off_outlined ,color: Colors.red),
          )
        ],
      ),
      body: Column(
        children: <Widget>[
          if (bands.isNotEmpty)
            _showGraph()
          else
            Container(
              width: double.infinity,
              height: 200,
              child: Center(
                child: Text(
                  'No hay Candidatos',
                  style: TextStyle(color: Colors.black54, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: bands.length,
              itemBuilder: (context, i) => _bandTile(bands[i]),
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: addNewBand,
        elevation: 1,
      ),
    );
  }

  Widget _showGraph() {
  Map<String, double> dataMap =new Map();
  bands.forEach((band) {
    dataMap.putIfAbsent(band.name, () => band.votes.toDouble());
  });
  return Container(
    padding: EdgeInsets.only(top: 10),
    width: double.infinity,
    height: 200,
    child: PieChart(dataMap: dataMap)) ;
}

  Widget _bandTile(Band band) {
    final socketService = Provider.of<SocketService>(context, listen: false);
    return Dismissible(
      key: Key(band.id),
      direction: DismissDirection.startToEnd,
      onDismissed: (_) =>
          socketService.socket.emit('delete-band', {'id': band.id}),
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.only(left: 20),
            child: Text(
              'Eliminar Candidato',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
      child: ListTile(
          leading: CircleAvatar(
            child: Text(band.name.substring(0, 2)),
            backgroundColor: Colors.blue[100],
          ),
          title: Text(band.name),
          trailing: Text(
            '${band.votes}',
            style: TextStyle(fontSize: 20),
          ),
          onTap: () {
            socketService.socket.emit('vote-band', {'id': band.id});
          }),
    );
  }

  addNewBand() {
    final textController = new TextEditingController();
    if (Platform.isAndroid) {
      return showDialog(
          context: context,
          builder: (_) => AlertDialog(
                title: Text('Añador nuevo Candidato'),
                content: TextField(
                  controller: textController,
                  autofocus: true,
                ),
                actions: <Widget>[
                  MaterialButton(
                    child: Text('Añadir'),
                    elevation: 5,
                    textColor: Colors.blue,
                    onPressed: () => addBandToList(textController.text),
                  ),
                ],
              ));
    }
    showCupertinoDialog(
        context: context,
        builder: (_) {
          return CupertinoAlertDialog(
            title: Text('Añador nuevo Candidato'),
            content: CupertinoTextField(
              controller: textController,
              autofocus: true,
            ),
            actions: <Widget>[
              CupertinoDialogAction(
                child: Text('Añadir'),
                isDefaultAction: true,
                onPressed: () => addBandToList(textController.text),
              ),
              CupertinoDialogAction(
                child: Text('Cancelar'),
                isDestructiveAction: true,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          );
        });
  }

  void addBandToList(String name) {
    if (name.length > 1) {
      // this.bands.add(Band(id: DateTime.now().toString(), name: name, votes: 0));
      // setState(() {}); // refresh the UI
      final socketService = Provider.of<SocketService>(context, listen: false);
      socketService.socket.emit('add-band', {'name': name});
    }
    Navigator.pop(context);
  }
}


