import 'dart:convert';
import 'dart:io';

class RoomManager {
  final Map<String, Set<WebSocket>> rooms = {};

  void joinRoom(String roomName, WebSocket socket) {
    rooms.putIfAbsent(roomName, () => <WebSocket>{});
    rooms[roomName]!.add(socket);
    socket.add(jsonEncode({'action': 'join', 'roomId': roomName}));
  }

  void leaveRoom(String roomName, WebSocket socket) {
    if (rooms.containsKey(roomName)) {
      rooms[roomName]!.remove(socket);
      if (rooms[roomName]!.isEmpty) {
        rooms.remove(roomName);
      }
      socket.add(jsonEncode({'action': 'leave', 'roomId': roomName}));
      print('Socket left room: $roomName');
    }
  }

  void broadcastToRoom(String roomName, String message, WebSocket sender) {
    if (rooms.containsKey(roomName)) {
      for (var socket in rooms[roomName]!) {
        if (socket != sender) {
          socket.add(jsonEncode({
            'action': 'message',
            'roomId': roomName,
            'message': message,
            'sender': sender
                .hashCode, // You might want to use a more meaningful sender ID
          }));
        }
      }
    }
  }

  void leaveRoomFromAllRooms(WebSocket socket) {
    rooms.forEach((roomName, sockets) {
      if (sockets.contains(socket)) {
        leaveRoom(roomName, socket);
      }
    });
  }

  List<Map<String, Set<WebSocket>>> getRooms() {
    return rooms.entries.map((entry) => {entry.key: entry.value}).toList();
  }
}
