import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

enum ServerStatus {
  Online,
  Offline,
  Connecting,
}

class SocketService with ChangeNotifier {
  ServerStatus _serverStatus = ServerStatus.Connecting;
  late IO.Socket _socket;

  ServerStatus get serverStatus => this._serverStatus;
  IO.Socket get socket=>this._socket;
  Function get emit => this._socket.emit;

  SocketService() {
    this._initConfig();
  }

  void _initConfig() {
    this._socket = IO.io('http://flutter-soket-server-votes.herokuapp.com',{
    // this._socket = IO.io('http://<IP LOCAL:PORT SERVER NODE>',{
      'transports': ['websocket'],
      'autoConnect': true,
    });
    this._socket.onConnect((_) {
      print('CONECTADO CON EL SERVIDOR');
      this._serverStatus = ServerStatus.Online;
      notifyListeners();
    });
    this._socket.onDisconnect((_) {
      print('DESCONECTADO CON EL SERVIDOR');
      this._serverStatus = ServerStatus.Offline;
      notifyListeners();
    });
  }
}
