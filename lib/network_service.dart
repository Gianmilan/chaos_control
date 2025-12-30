import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:logger/logger.dart';
import 'package:nsd/nsd.dart';
import 'hive_service.dart';

class NetworkService {
  var logger = Logger();
  ServerSocket? _server;
  Discovery? _discovery;
  Registration? _registration;

  Future<void> startServer() async {
    _server = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
    logger.d(
      "Server listening on ${_server!.address.address}:${_server!.port}",
    );

    _server!.listen((Socket client) {
      _handleClient(client);
    });

    _registration = await register(
      Service(
        name: "ChaosControl-${Platform.localHostname}",
        type: "_chaoscontrol._tcp",
        port: _server!.port,
      ),
    );
    logger.d("Service registered: ${_registration!.service.name}");
  }

  Future<void> discoverDevices(Function(Service) onFound) async {
    _discovery = await startDiscovery('_chaoscontrol._tcp');

    _discovery!.addListener(() {
      for (var service in _discovery!.services) {
        if (service.name != _registration?.service.name) {
          onFound(service);
        }
      }
    });

    Timer(const Duration(seconds: 5), () {
      if (_discovery != null) {
        stopDiscovery(_discovery!);
        _discovery = null;
      }
    });
  }

  void _handleClient(Socket client) {
    client.listen((data) async {
      final message = utf8.decode(data);
      try {
        final decoded = jsonDecode(message);

        if (decoded['type'] == 'GET_REMINDERS') {
          final data = HiveService.getAllReminders();
          client.write(jsonEncode(data));
        }
      } catch (e) {
        logger.d("Error handling client: $e");
      }
    }, onDone: () => client.destroy());
  }

  Future<void> syncWithDevice(Service service) async {
    try {
      final socket = await Socket.connect(
        service.host,
        service.port!,
        timeout: const Duration(seconds: 5),
      );
      socket.write(jsonEncode({'type': 'GET_REMINDERS'}));

      final buffer = StringBuffer();

      socket.listen(
        (data) => buffer.write(utf8.decode(data)),
        onDone: () async {
          final response = buffer.toString();

          if (response.isNotEmpty) {
            final Map<String, dynamic> remoteData = jsonDecode(response);
            await HiveService.addAllReminders(remoteData);
            logger.d('Sync complete!');
          }
          socket.destroy();
        },
        onError: (e) => logger.d('Socket error: $e'),
      );
    } catch (e) {
      logger.d('Connection failed: $e');
    }
  }

  void dispose() {
    stopDiscovery(_discovery!);
    unregister(_registration!);
    _server?.close();
  }
}
