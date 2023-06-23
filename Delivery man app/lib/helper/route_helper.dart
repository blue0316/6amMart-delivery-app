import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sixam_mart_delivery/data/model/body/notification_body.dart';
import 'package:sixam_mart_delivery/data/model/response/conversation_model.dart';
import 'package:sixam_mart_delivery/view/screens/auth/sign_in_screen.dart';
import 'package:sixam_mart_delivery/view/screens/auth/delivery_man_registration_screen.dart';
import 'package:sixam_mart_delivery/view/screens/chat/chat_screen.dart';
import 'package:sixam_mart_delivery/view/screens/chat/conversation_screen.dart';
import 'package:sixam_mart_delivery/view/screens/dashboard/dashboard_screen.dart';
import 'package:sixam_mart_delivery/view/screens/forget/forget_pass_screen.dart';
import 'package:sixam_mart_delivery/view/screens/forget/new_pass_screen.dart';
import 'package:sixam_mart_delivery/view/screens/forget/verification_screen.dart';
import 'package:sixam_mart_delivery/view/screens/html/html_viewer_screen.dart';
import 'package:sixam_mart_delivery/view/screens/language/language_screen.dart';
import 'package:sixam_mart_delivery/view/screens/notification/notification_screen.dart';
import 'package:sixam_mart_delivery/view/screens/order/order_details_screen.dart';
import 'package:sixam_mart_delivery/view/screens/order/running_order_screen.dart';
import 'package:sixam_mart_delivery/view/screens/profile/update_profile_screen.dart';
import 'package:sixam_mart_delivery/view/screens/splash/splash_screen.dart';
import 'package:sixam_mart_delivery/view/screens/update/update_screen.dart';
import 'package:get/get.dart';

class RouteHelper {
  static const String initial = '/';
  static const String splash = '/splash';
  static const String signIn = '/sign-in';
  static const String verification = '/verification';
  static const String main = '/main';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String orderDetails = '/order-details';
  static const String updateProfile = '/update-profile';
  static const String notification = '/notification';
  static const String runningOrder = '/running-order';
  static const String terms = '/terms-and-condition';
  static const String privacy = '/privacy-policy';
  static const String language = '/language';
  static const String update = '/update';
  static const String chatScreen = '/chat-screen';
  static const String conversationListScreen = '/conversation-list-screen';
  static const String deliveryManRegistration = '/delivery-man-registration';

  static String getInitialRoute() => '$initial';
  static String getSplashRoute(NotificationBody body) {
    String _data = 'null';
    if(body != null) {
      List<int> _encoded = utf8.encode(jsonEncode(body.toJson()));
      _data = base64Encode(_encoded);
    }
    return '$splash?data=$_data';
  }
  static String getSignInRoute() => '$signIn';
  static String getVerificationRoute(String number) => '$verification?number=$number';
  static String getMainRoute(String page) => '$main?page=$page';
  static String getForgotPassRoute() => '$forgotPassword';
  static String getResetPasswordRoute(String phone, String token, String page) => '$resetPassword?phone=$phone&token=$token&page=$page';
  static String getOrderDetailsRoute(int id, {bool fromNotification}) => '$orderDetails?id=$id&from=${fromNotification.toString()}';
  static String getUpdateProfileRoute() => '$updateProfile';
  static String getNotificationRoute({bool fromNotification}) => '$notification?from=${fromNotification.toString()}';
  static String getRunningOrderRoute() => '$runningOrder';
  static String getTermsRoute() => '$terms';
  static String getPrivacyRoute() => '$privacy';
  static String getLanguageRoute() => '$language';
  static String getUpdateRoute(bool isUpdate) => '$update?update=${isUpdate.toString()}';
  static String getChatRoute({@required NotificationBody notificationBody, User user, int conversationId, bool fromNotification}) {

    String _notificationBody = 'null';
    String _user = 'null';

    if(notificationBody != null) {
      _notificationBody = base64Encode(utf8.encode(jsonEncode(notificationBody)));
    }
    if(user != null) {
      _user = base64Encode(utf8.encode(jsonEncode(user.toJson())));
    }
    return '$chatScreen?notification_body=$_notificationBody&user=$_user&conversation_id=$conversationId&from=${fromNotification.toString()}';
  }
  static String getConversationListRoute() => '$conversationListScreen';
  static String getDeliverymanRegistrationRoute() => '$deliveryManRegistration';

  static List<GetPage> routes = [
    GetPage(name: initial, page: () => DashboardScreen(pageIndex: 0)),
    GetPage(name: splash, page: () {
      NotificationBody _data;
      if(Get.parameters['data'] != 'null') {
        List<int> _decode = base64Decode(Get.parameters['data'].replaceAll(' ', '+'));
        _data = NotificationBody.fromJson(jsonDecode(utf8.decode(_decode)));
      }
      return SplashScreen(body: _data);
    }),
    GetPage(name: signIn, page: () => SignInScreen()),
    GetPage(name: verification, page: () => VerificationScreen(number: Get.parameters['number'])),
    GetPage(name: main, page: () => DashboardScreen(
      pageIndex: Get.parameters['page'] == 'home' ? 0 : Get.parameters['page'] == 'order-request' ? 1
          : Get.parameters['page'] == 'order' ? 2 : Get.parameters['page'] == 'profile' ? 3 : 0,
    )),
    GetPage(name: forgotPassword, page: () => ForgetPassScreen()),
    GetPage(name: resetPassword, page: () => NewPassScreen(
      resetToken: Get.parameters['token'], number: Get.parameters['phone'], fromPasswordChange: Get.parameters['page'] == 'password-change',
    )),
    GetPage(name: orderDetails, page: () {
      OrderDetailsScreen _orderDetails = Get.arguments;
      return _orderDetails != null ? _orderDetails : OrderDetailsScreen(
        fromNotification: Get.parameters['from'] == 'true', isRunningOrder: null, orderIndex: null, orderId: int.parse(Get.parameters['id']
      ));
    }),
    GetPage(name: updateProfile, page: () => UpdateProfileScreen()),
    GetPage(name: notification, page: () => NotificationScreen(fromNotification: Get.parameters['from'] == 'true')),
    GetPage(name: runningOrder, page: () => RunningOrderScreen()),
    GetPage(name: terms, page: () => HtmlViewerScreen(isPrivacyPolicy: false)),
    GetPage(name: privacy, page: () => HtmlViewerScreen(isPrivacyPolicy: true)),
    GetPage(name: language, page: () => ChooseLanguageScreen()),
    GetPage(name: update, page: () => UpdateScreen(isUpdate: Get.parameters['update'] == 'true')),
    GetPage(name: chatScreen, page: () {

      NotificationBody _notificationBody;
      if(Get.parameters['notification_body'] != 'null') {
        _notificationBody = NotificationBody.fromJson(jsonDecode(utf8.decode(base64Url.decode(Get.parameters['notification_body'].replaceAll(' ', '+')))));
      }
      User _user;
      if(Get.parameters['user'] != 'null') {
        _user = User.fromJson(jsonDecode(utf8.decode(base64Url.decode(Get.parameters['user'].replaceAll(' ', '+')))));
      }
      return ChatScreen(
        notificationBody : _notificationBody, user: _user, fromNotification: Get.parameters['from'] == 'true',
        conversationId: Get.parameters['conversation_id'] != null && Get.parameters['conversation_id'] != 'null' ? int.parse(Get.parameters['conversation_id']) : null,
      );
    }),
    GetPage(name: conversationListScreen, page: () => ConversationScreen()),
    GetPage(name: deliveryManRegistration, page: () => DeliveryManRegistrationScreen()),
  ];
}