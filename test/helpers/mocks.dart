import 'package:mockito/annotations.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/services/socket_service.dart';
import 'package:frontend/services/location_service.dart';
import 'package:frontend/services/webrtc_service.dart';
import 'package:frontend/services/group_chat_api_service.dart';
import 'package:frontend/providers/map_pin_provider.dart';

@GenerateMocks([
  ApiService,
  AuthProvider,
  SocketService,
  LocationService,
  WebRTCService,
  GroupChatApiService,
  MapPinProvider,
])
void main() {}
