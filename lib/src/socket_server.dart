import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_fv_connector/src/room_manager.dart';

class SocketServer {
  final Map<String, RoomManager> _roomManagers = {};

  SocketServer(int port) {
    _printLogIPs();
    runZoned(() async {
      final server = await HttpServer.bind("0.0.0.0", port);

      server.listen((HttpRequest request) async {
        print(
            'Connected ws://${request.connectionInfo?.remoteAddress.address}:$port');
        if (WebSocketTransformer.isUpgradeRequest(request)) {
          //Handle path in url
          await for (HttpRequest request in server) {
            switch (request.uri.path) {
              default:
                WebSocketTransformer.upgrade(request)
                    .then((socket) => {_listenSocketEvent(socket, "")});
            }
          }
        } else {
          request.response
            ..statusCode = HttpStatus.notFound
            ..write('Not found')
            ..close();
        }
      });
    });
  }

  void _printLogIPs() async {
    List<NetworkInterface> interfaces = await NetworkInterface.list();
    for (var interface in interfaces) {
      for (var address in interface.addresses) {
        if (address.type == InternetAddressType.IPv4) {
          print('Server IP: ${address.address}');
        }
      }
    }
  }

  void _listenSocketEvent(WebSocket socket, String path) {
    final roomManager = _roomManagers.putIfAbsent(path, () => RoomManager());

    socket.listen((data) {
      final message = jsonDecode(data as String);
      final action = message['action'] as String;
      final roomId = message["roomId"] as String;

      switch (action) {
        case 'join':
          roomManager.joinRoom(roomId, socket);
          break;
        case 'leave':
          roomManager.leaveRoom(roomId, socket);
          break;

        case 'message':
          final roomMessage = message["message"] as String;
          roomManager.broadcastToRoom(roomId, roomMessage, socket);
          break;
      }
    }, onError: (error) {
      print('WebSocket error: $error');
      roomManager.leaveRoomFromAllRooms(socket); // Leave all rooms on error
    }, onDone: () {
      print('WebSocket connection closed');
      roomManager
          .leaveRoomFromAllRooms(socket); // Leave all rooms on disconnect
    });
  }
}
