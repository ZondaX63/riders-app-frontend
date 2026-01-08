import 'auth_api_service.dart';
import 'user_api_service.dart';
import 'post_api_service.dart';
import 'chat_api_service.dart';
import 'map_pin_api_service.dart';
import 'location_api_service.dart';
import 'notification_api_service.dart';
import 'story_api_service.dart';
import 'route_api_service.dart';
import 'group_chat_api_service.dart';
import '../models/group_chat.dart';
import '../models/message.dart';
import '../models/user.dart';
import '../models/post.dart';
import '../models/chat.dart';
import '../models/comment.dart';
import '../models/map_pin.dart';
import '../models/route.dart';
import '../models/story.dart';
import 'base_api_service.dart';

/// Unified API Service - Facade Pattern
class ApiService extends BaseApiService {
  late final AuthApiService auth;
  late final UserApiService users;
  late final PostApiService posts;
  late final ChatApiService chats;
  late final MapPinApiService mapPins;
  late final LocationApiService locations;
  late final NotificationApiService notifications;
  late final StoryApiService stories;
  late final RouteApiService routes;
  late final GroupChatApiService groupChats;

  ApiService() {
    auth = AuthApiService();
    users = UserApiService();
    posts = PostApiService();
    chats = ChatApiService();
    mapPins = MapPinApiService();
    locations = LocationApiService();
    notifications = NotificationApiService();
    stories = StoryApiService();
    routes = RouteApiService();
    groupChats = GroupChatApiService();
  }

  // Auth methods
  Future<Map<String, dynamic>> login(String email, String password) =>
      auth.login(email, password);

  Future<Map<String, dynamic>> register(
    String username,
    String email,
    String password,
    String fullName,
  ) =>
      auth.register(username, email, password, fullName);

  Future<void> logout() => auth.logout();

  // User methods
  Future<User> getCurrentUser() => users.getCurrentUser();
  Future<User> getUser(String userId) => users.getUser(userId);
  Future<User> updateProfile(String fullName, String bio,
          [Map<String, dynamic>? motorcycleInfo]) =>
      users.updateProfile(fullName, bio, motorcycleInfo);
  Future<User> updateProfilePicture(String imagePath) =>
      users.updateProfilePicture(imagePath);
  Future<void> followUser(String userId) => users.followUser(userId);
  Future<void> unfollowUser(String userId) => users.unfollowUser(userId);
  Future<List<User>> searchUsers(String query) => users.searchUsers(query);
  Future<User> updateUserStatus(
          {required String message, String? customText}) =>
      users.updateUserStatus(message: message, customText: customText);

  // Post methods
  Future<List<Post>> getPosts() => posts.getPosts();
  Future<List<Post>> getExplorePosts({int limit = 20, int offset = 0}) =>
      posts.getExplorePosts(limit: limit, offset: offset);
  Future<Post> createPost(String? content, List<String> images) =>
      posts.createPost(content, images);
  Future<void> likePost(String postId) => posts.likePost(postId);
  Future<void> unlikePost(String postId) => posts.unlikePost(postId);
  Future<void> addComment(String postId, String content) =>
      posts.addComment(postId, content);
  Future<List<Comment>> getComments(String postId) => posts.getComments(postId);
  Future<void> createComment(String postId, String content) =>
      posts.createComment(postId, content);
  Future<void> deleteComment(String postId, String commentId) =>
      posts.deleteComment(postId, commentId);

  // Chat methods
  Future<List<Chat>> getChats() => chats.getChats();
  Future<List<Message>> getChatMessages(String chatId) =>
      chats.getChatMessages(chatId);
  Future<Message> sendMessage(
          String chatId, String content, MessageType type) =>
      chats.sendMessage(chatId, content, type);
  Future<void> markChatAsRead(String chatId) => chats.markChatAsRead(chatId);
  Future<void> deleteMessage(
          String chatId, String messageId, bool deleteForEveryone) =>
      chats.deleteMessage(chatId, messageId, deleteForEveryone);
  Future<void> reactToMessage(
          String chatId, String messageId, String reaction) =>
      chats.reactToMessage(chatId, messageId, reaction);
  Future<void> muteChat(String chatId, bool mute) =>
      chats.muteChat(chatId, mute);
  Future<Chat> getOrCreateChat(String userId) => chats.getOrCreateChat(userId);
  Future<void> deleteChat(String chatId) => chats.deleteChat(chatId);

  // MapPin methods
  Future<MapPin> createMapPin({
    required double latitude,
    required double longitude,
    required String type,
    String? title,
    String? description,
    bool isPublic = true,
    DateTime? expiresAt,
  }) =>
      mapPins.createMapPin(
        latitude: latitude,
        longitude: longitude,
        type: type,
        title: title,
        description: description,
        isPublic: isPublic,
        expiresAt: expiresAt,
      );

  Future<List<MapPin>> getNearbyMapPins({
    required double latitude,
    required double longitude,
    int radius = 5000,
    String? type,
    List<String>? types,
  }) =>
      mapPins.getNearbyMapPins(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
        type: type,
        types: types,
      );

  Future<List<MapPin>> getMyMapPins() => mapPins.getMyMapPins();
  Future<void> deleteMapPin(String pinId) => mapPins.deleteMapPin(pinId);

  // Location methods
  Future<void> updateUserLocation({
    required double latitude,
    required double longitude,
    required bool isVisible,
    String? status,
    String? statusMessage,
    double? speed,
    double? heading,
    double? altitude,
    double? accuracy,
  }) =>
      locations.updateUserLocation(
        latitude: latitude,
        longitude: longitude,
        isVisible: isVisible,
        status: status,
        statusMessage: statusMessage,
        speed: speed,
        heading: heading,
        altitude: altitude,
        accuracy: accuracy,
      );

  Future<void> toggleLocationVisibility(bool isVisible) =>
      locations.toggleLocationVisibility(isVisible);

  Future getNearbyLocations({
    required double latitude,
    required double longitude,
    int radius = 10000,
    int limit = 50,
  }) =>
      locations.getNearbyLocations(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
        limit: limit,
      );

  Future getMyLocation() => locations.getMyLocation();

  // Story methods
  Future<List<Story>> getStories({int limit = 20, int offset = 0}) =>
      stories.getStories(limit: limit, offset: offset);
  Future<Story> createStory(
          {required String mediaPath,
          required String mediaType,
          int duration = 24}) =>
      stories.createStory(
          mediaPath: mediaPath, mediaType: mediaType, duration: duration);
  Future<void> viewStory(String storyId) => stories.viewStory(storyId);
  Future<List<User>> getStoryViews(String storyId,
          {int limit = 20, int offset = 0}) =>
      stories.getStoryViews(storyId, limit: limit, offset: offset);

  // Route methods
  Future<List<RidersRoute>> getPublicRoutes({int limit = 20, int offset = 0}) =>
      routes.getPublicRoutes(limit: limit, offset: offset);
  Future<List<RidersRoute>> getUserRoutes(String userId,
          {int limit = 20, int offset = 0}) =>
      routes.getUserRoutes(userId, limit: limit, offset: offset);
  Future<RidersRoute> getRoute(String routeId) => routes.getRoute(routeId);
  Future<RidersRoute> createRoute({
    required String name,
    String? description,
    required List<Map<String, dynamic>> waypoints,
    bool isPublic = true,
  }) =>
      routes.createRoute(
        name: name,
        description: description,
        waypoints: waypoints,
        isPublic: isPublic,
      );
  Future<void> shareRoute(String routeId, String userId) =>
      routes.shareRoute(routeId, userId);
  Future<void> deleteRoute(String routeId) => routes.deleteRoute(routeId);

  // GroupChat methods
  Future<List<GroupChat>> getGroupChats() => groupChats.getGroupChats();
  Future createGroupChat(
          {required String name,
          String? description,
          bool isPrivate = false}) =>
      groupChats.createGroupChat(
          name: name, description: description, isPrivate: isPrivate);
  Future<GroupChat> getGroupChat(String id) => groupChats.getGroupChat(id);
  Future<List<GroupMessage>> getGroupMessages(String id,
          {int limit = 50, DateTime? before}) =>
      groupChats.getGroupMessages(id, limit: limit, before: before);
  Future sendGroupMessage(
          {required String groupId,
          required String content,
          String type = 'text',
          Map<String, double>? location}) =>
      groupChats.sendGroupMessage(
          groupId: groupId, content: content, type: type, location: location);
  Future<void> attachRouteToGroup(String groupId, String routeId) =>
      groupChats.attachRoute(groupId, routeId);
  Future<void> updateGroupRideStatus(String groupId, String status) =>
      groupChats.updateRideStatus(groupId, status);

  Future<List<Map<String, dynamic>>> getUserPosts(String userId) =>
      users.getUserPosts(userId);

  Future<void> deletePost(String postId) => posts.deletePost(postId);

  Future<User> updateMotorcyclePicture(String path) =>
      users.updateMotorcyclePicture(path);

  Future<void> addGroupMember(String groupId, String userId) =>
      groupChats.addMember(groupId, userId);
  Future<void> removeGroupMember(String groupId, String userId) =>
      groupChats.removeMember(groupId, userId);
}
