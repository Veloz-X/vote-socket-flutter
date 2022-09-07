import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:provider/provider.dart';

import '../models/candidate.dart';
import '../services/socket_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Candidate> candidates = [];

  @override
  void initState() {
    final socketService = Provider.of<SocketService>(context, listen: false);
    socketService.socket.on('active-candidates', _handleActiveCandidates);
    super.initState();
  }

  _handleActiveCandidates(dynamic payload) {
    this.candidates =
        (payload as List).map((candidate) => Candidate.fromMap(candidate)).toList();
    setState(() {});
  }

  @override
  void dispose() {
    final socketService = Provider.of<SocketService>(context, listen: false);
    socketService.socket.off('active-candidates');
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
                ? Icon(Icons.wifi_rounded, color: Colors.green[400])
                : Icon(Icons.wifi_off_outlined, color: Colors.red),
          )
        ],
      ),
      body: Column(
        children: <Widget>[
          if (candidates.isNotEmpty)
            _showGraph()
          else
            Container(
              width: double.infinity,
              height: 200,
              child: Center(
                child: Text(
                  'No hay Candidatos',
                  style: TextStyle(
                      color: Colors.black54,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: candidates.length,
              itemBuilder: (context, i) => _candidateTile(candidates[i]),
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: addNewCandidate,
        elevation: 1,
      ),
    );
  }

  Widget _showGraph() {
    Map<String, double> dataMap = new Map();
    candidates.forEach((candidate) {
      dataMap.putIfAbsent(candidate.name, () => candidate.votes.toDouble());
    });
    return Container(
        padding: EdgeInsets.only(top: 10),
        width: double.infinity,
        height: 200,
        child: PieChart(dataMap: dataMap));
  }

  Widget _candidateTile(Candidate candidate) {
    final socketService = Provider.of<SocketService>(context, listen: false);
    return Dismissible(
      key: Key(candidate.id),
      direction: DismissDirection.startToEnd,
      onDismissed: (_) =>
          socketService.socket.emit('delete-candidate', {'id': candidate.id}),
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
            child: Text(candidate.name.substring(0, 2)),
            backgroundColor: Colors.blue[100],
          ),
          title: Text(candidate.name),
          trailing: Text(
            '${candidate.votes}',
            style: TextStyle(fontSize: 20),
          ),
          onTap: () {
            socketService.socket.emit('vote-candidate', {'id': candidate.id});
          }),
    );
  }

  addNewCandidate() {
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
                    onPressed: () => addCandidateToList(textController.text),
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
                onPressed: () => addCandidateToList(textController.text),
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

  void addCandidateToList(String name) {
    if (name.length > 1) {
      final socketService = Provider.of<SocketService>(context, listen: false);
      socketService.socket.emit('add-candidate', {'name': name});
    }
    Navigator.pop(context);
  }
}
