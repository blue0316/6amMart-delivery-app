import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sixam_mart_delivery/controller/auth_controller.dart';
import 'package:sixam_mart_delivery/controller/chat_controller.dart';
import 'package:sixam_mart_delivery/controller/notification_controller.dart';
import 'package:sixam_mart_delivery/controller/order_controller.dart';
import 'package:sixam_mart_delivery/data/model/body/notification_body.dart';
import 'package:sixam_mart_delivery/helper/route_helper.dart';
import 'package:sixam_mart_delivery/helper/user_type.dart';
import 'package:sixam_mart_delivery/util/app_constants.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class NotificationHelper {

  static Future<void> initialize(FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) async {
    var androidInitialize = new AndroidInitializationSettings('notification_icon');
    var iOSInitialize = new DarwinInitializationSettings();
    var initializationsSettings = new InitializationSettings(android: androidInitialize, iOS: iOSInitialize);
    flutterLocalNotificationsPlugin.initialize(initializationsSettings, onDidReceiveNotificationResponse: (payload) async{
      try{
        if(payload != null && payload.payload.isNotEmpty){

          NotificationBody _payload = NotificationBody.fromJson(jsonDecode(payload.payload));

          if(_payload.notificationType == NotificationType.order){
            Get.offAllNamed(RouteHelper.getOrderDetailsRoute(_payload.orderId, fromNotification: true));
          }else if(_payload.notificationType == NotificationType.order_request){
            Get.toNamed(RouteHelper.getMainRoute('order-request'));

          }else if(_payload.notificationType == NotificationType.general){
            Get.offAllNamed(RouteHelper.getNotificationRoute(fromNotification: true));
          }else{
            Get.offAllNamed(RouteHelper.getChatRoute(notificationBody: _payload, conversationId: _payload.conversationId, fromNotification: true));
          }

        }
      }catch(e){}
      return;
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("onMessage: ${message.notification.title}/${message.notification.body}/${message.notification.titleLocKey}");
      print("onMessage message type:${message.data['type']}");
      print("onMessage message:${message.data}");

      if(message.data['type'] == 'message' && Get.currentRoute.startsWith(RouteHelper.chatScreen)){
        if(Get.find<AuthController>().isLoggedIn()) {
          Get.find<ChatController>().getConversationList(1);
          if(Get.find<ChatController>().messageModel.conversation.id.toString() == message.data['conversation_id'].toString()) {
            Get.find<ChatController>().getMessages(
              1, NotificationBody(
              notificationType: NotificationType.message,
              customerId: message.data['sender_type'] == UserType.user.name ? 0 : null,
              vendorId: message.data['sender_type'] == UserType.vendor.name ? 0 : null,
            ),
              null, int.parse(message.data['conversation_id'].toString()),
            );
          }else {
            NotificationHelper.showNotification(message, flutterLocalNotificationsPlugin);
          }
        }
      }else if(message.data['type'] == 'message' && Get.currentRoute.startsWith(RouteHelper.conversationListScreen)) {
        if(Get.find<AuthController>().isLoggedIn()) {
          Get.find<ChatController>().getConversationList(1);
        }
        NotificationHelper.showNotification(message, flutterLocalNotificationsPlugin);
      }else {
        String _type = message.data['type'];

        if (_type != 'assign' && _type != 'new_order' /*&& _type != 'order_request'*/) {
          NotificationHelper.showNotification(message, flutterLocalNotificationsPlugin);
          Get.find<OrderController>().getCurrentOrders();
          Get.find<OrderController>().getLatestOrders();
          Get.find<NotificationController>().getNotificationList();
        }
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("onOpenApp: ${message.notification.title}/${message.notification.body}/${message.notification.titleLocKey}");
      print("onOpenApp message type:${message.data['type']}");
      try{
        if(message.data != null || message.data.isNotEmpty){

          NotificationBody _notificationBody = convertNotification(message.data);

          if(_notificationBody.notificationType == NotificationType.order){
            Get.toNamed(RouteHelper.getOrderDetailsRoute(int.parse(message.data['order_id'])));
          }
          else if(_notificationBody.notificationType == NotificationType.order_request){
            Get.toNamed(RouteHelper.getMainRoute('order-request'));
          }
          else if(_notificationBody.notificationType == NotificationType.general){
            Get.toNamed(RouteHelper.getNotificationRoute());
          }
          else{
            Get.toNamed(RouteHelper.getChatRoute(notificationBody: _notificationBody, conversationId: _notificationBody.conversationId));
          }
        }
      }catch (e) {}
    });
  }

  static Future<void> showNotification(RemoteMessage message, FlutterLocalNotificationsPlugin fln) async {
    if(!GetPlatform.isIOS) {
      String _title;
      String _body;
      String _image;
      NotificationBody _notificationBody;

      _title = message.notification.title;
      _body = message.notification.body;
      _notificationBody = convertNotification(message.data);

      if(GetPlatform.isAndroid) {
        _image = (message.notification.android.imageUrl != null && message.notification.android.imageUrl.isNotEmpty)
            ? message.notification.android.imageUrl.startsWith('http') ? message.notification.android.imageUrl
            : '${AppConstants.BASE_URL}/storage/app/public/notification/${message.notification.android.imageUrl}' : null;
      }else if(GetPlatform.isIOS) {
        _image = (message.notification.apple.imageUrl != null && message.notification.apple.imageUrl.isNotEmpty)
            ? message.notification.apple.imageUrl.startsWith('http') ? message.notification.apple.imageUrl
            : '${AppConstants.BASE_URL}/storage/app/public/notification/${message.notification.apple.imageUrl}' : null;
      }

      if(_image != null && _image.isNotEmpty /*&& _notificationBody.notificationType != NotificationType.message*/) {
        try{
          await showBigPictureNotificationHiddenLargeIcon(_title, _body, _notificationBody, _image, fln);
        }catch(e) {
          await showBigTextNotification(_title, _body, _notificationBody, fln);
        }
      }else {
        await showBigTextNotification(_title, _body, _notificationBody, fln);
      }
    }
  }

  static Future<void> showTextNotification(String title, String body, NotificationBody notificationBody, FlutterLocalNotificationsPlugin fln) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      '6ammart', '6ammart', playSound: true,
      importance: Importance.max, priority: Priority.max, sound: RawResourceAndroidNotificationSound('notification'),
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await fln.show(0, title, body, platformChannelSpecifics, payload: notificationBody != null ? jsonEncode(notificationBody.toJson()) : null);
  }

  static Future<void> showBigTextNotification(String title, String body, NotificationBody notificationBody, FlutterLocalNotificationsPlugin fln) async {
    BigTextStyleInformation bigTextStyleInformation = BigTextStyleInformation(
      body, htmlFormatBigText: true,
      contentTitle: title, htmlFormatContentTitle: true,
    );
    AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      '6ammart', '6ammart', importance: Importance.max,
      styleInformation: bigTextStyleInformation, priority: Priority.max, playSound: true,
      sound: RawResourceAndroidNotificationSound('notification'),
    );
    NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await fln.show(0, title, body, platformChannelSpecifics, payload: notificationBody != null ? jsonEncode(notificationBody.toJson()) : null);
  }

  static Future<void> showBigPictureNotificationHiddenLargeIcon(String title, String body, NotificationBody notificationBody, String image, FlutterLocalNotificationsPlugin fln) async {
    final String largeIconPath = await _downloadAndSaveFile(image, 'largeIcon');
    final String bigPicturePath = await _downloadAndSaveFile(image, 'bigPicture');
    final BigPictureStyleInformation bigPictureStyleInformation = BigPictureStyleInformation(
      FilePathAndroidBitmap(bigPicturePath), hideExpandedLargeIcon: true,
      contentTitle: title, htmlFormatContentTitle: true,
      summaryText: body, htmlFormatSummaryText: true,
    );
    final AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      '6ammart', '6ammart',
      largeIcon: FilePathAndroidBitmap(largeIconPath), priority: Priority.max, playSound: true,
      styleInformation: bigPictureStyleInformation, importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('notification'),
    );
    final NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await fln.show(0, title, body, platformChannelSpecifics, payload: notificationBody != null ? jsonEncode(notificationBody.toJson()) : null);
  }

  static Future<String> _downloadAndSaveFile(String url, String fileName) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final String filePath = '${directory.path}/$fileName';
    final http.Response response = await http.get(Uri.parse(url));
    final File file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return filePath;
  }

  static NotificationBody convertNotification(Map<String, dynamic> data){
    if(data['type'] == 'general'){
      return NotificationBody(notificationType: NotificationType.general) ;
    }
    else if(  data['type'] == 'order_status'){
      return NotificationBody(orderId: int.parse(data['order_id']), notificationType: NotificationType.order);
    }
    else if(  data['type'] == 'order_request'){
      return NotificationBody(orderId: int.parse(data['order_id']), notificationType: NotificationType.order_request);
    }
    else if(data['type'] == 'message'){
      return NotificationBody(
        conversationId: (data['conversation_id'] != null && data['conversation_id'].isNotEmpty) ? int.parse(data['conversation_id']) : null,
        notificationType: NotificationType.message,
        type: data['sender_type'] == UserType.user.name ? UserType.user.name : UserType.vendor.name,
      );
    }else{
      return null;
    }
  }

}

Future<dynamic> myBackgroundMessageHandler(RemoteMessage message) async {
  print("onBackground: ${message.notification.title}/${message.notification.body}/${message.notification.titleLocKey}");
  // var androidInitialize = new AndroidInitializationSettings('notification_icon');
  // var iOSInitialize = new IOSInitializationSettings();
  // var initializationsSettings = new InitializationSettings(android: androidInitialize, iOS: iOSInitialize);
  // FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  // flutterLocalNotificationsPlugin.initialize(initializationsSettings);
  // NotificationHelper.showNotification(message, flutterLocalNotificationsPlugin, true);
}