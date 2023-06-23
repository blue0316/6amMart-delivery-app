import 'dart:async';

import 'package:sixam_mart_delivery/controller/auth_controller.dart';
import 'package:sixam_mart_delivery/controller/localization_controller.dart';
import 'package:sixam_mart_delivery/controller/order_controller.dart';
import 'package:sixam_mart_delivery/controller/splash_controller.dart';
import 'package:sixam_mart_delivery/data/model/body/notification_body.dart';
import 'package:sixam_mart_delivery/data/model/response/conversation_model.dart';
import 'package:sixam_mart_delivery/data/model/response/order_model.dart';
import 'package:sixam_mart_delivery/helper/route_helper.dart';
import 'package:sixam_mart_delivery/util/app_constants.dart';
import 'package:sixam_mart_delivery/util/dimensions.dart';
import 'package:sixam_mart_delivery/util/images.dart';
import 'package:sixam_mart_delivery/util/styles.dart';
import 'package:sixam_mart_delivery/view/base/confirmation_dialog.dart';
import 'package:sixam_mart_delivery/view/base/custom_app_bar.dart';
import 'package:sixam_mart_delivery/view/base/custom_button.dart';
import 'package:sixam_mart_delivery/view/base/custom_image.dart';
import 'package:sixam_mart_delivery/view/base/custom_snackbar.dart';
import 'package:sixam_mart_delivery/view/screens/order/widget/order_item_widget.dart';
import 'package:sixam_mart_delivery/view/screens/order/widget/verify_delivery_sheet.dart';
import 'package:sixam_mart_delivery/view/screens/order/widget/info_card.dart';
import 'package:sixam_mart_delivery/view/screens/order/widget/slider_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OrderDetailsScreen extends StatefulWidget {
  final int orderId;
  final bool isRunningOrder;
  final int orderIndex;
  final bool fromNotification;
  OrderDetailsScreen({@required this.orderId, @required this.isRunningOrder, @required this.orderIndex, this.fromNotification = false});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  Timer _timer;

  void _startApiCalling(){
    _timer = Timer.periodic(Duration(seconds: 10), (timer) {
      Get.find<OrderController>().getOrderWithId(Get.find<OrderController>().orderModel.id);
    });
  }

  Future<void> _loadData() async {
    await Get.find<OrderController>().getOrderWithId(widget.orderId);
    Get.find<OrderController>().getOrderDetails(widget.orderId, Get.find<OrderController>().orderModel.orderType == 'parcel');
  }

  @override
  void initState() {
    super.initState();

    _loadData();
    _startApiCalling();
  }

  @override
  void dispose() {
    super.dispose();
    _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {

    bool _cancelPermission = Get.find<SplashController>().configModel.canceledByDeliveryman;
    bool _selfDelivery = Get.find<AuthController>().profileModel.type != 'zone_wise';

    return WillPopScope(
      onWillPop: () async{
        if(widget.fromNotification) {
          Get.offAllNamed(RouteHelper.getInitialRoute());
          return true;
        } else {
          Get.back();
          return true;
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).cardColor,
        appBar: CustomAppBar(title: 'order_details'.tr, onBackPressed: (){
          if(widget.fromNotification) {
            Get.offAllNamed(RouteHelper.getInitialRoute());
          } else {
            Get.back();
          }
        }),
        body: Padding(
          padding: EdgeInsets.all(Dimensions.PADDING_SIZE_SMALL),
          child: GetBuilder<OrderController>(builder: (orderController) {

            OrderModel controllerOrderModel = orderController.orderModel;

            bool _restConfModel = Get.find<SplashController>().configModel.orderConfirmationModel != 'deliveryman';

            bool _parcel, _processing, _accepted, _confirmed, _handover, _pickedUp, _cod, _wallet;

            bool _showBottomView;
            bool _showSlider;

            if(controllerOrderModel != null){
                 _parcel = controllerOrderModel.orderType == 'parcel';
                 _processing = controllerOrderModel.orderStatus == AppConstants.PROCESSING;
                 _accepted = controllerOrderModel.orderStatus == AppConstants.ACCEPTED;
                 _confirmed = controllerOrderModel.orderStatus == AppConstants.CONFIRMED;
                 _handover = controllerOrderModel.orderStatus == AppConstants.HANDOVER;
                 _pickedUp = controllerOrderModel.orderStatus == AppConstants.PICKED_UP;
                 _cod = controllerOrderModel.paymentMethod == 'cash_on_delivery';
                 _wallet = controllerOrderModel.paymentMethod == 'wallet';

              bool _restConfModel = Get.find<SplashController>().configModel.orderConfirmationModel != 'deliveryman';
              _showBottomView = (_parcel && _accepted) || _accepted || _confirmed || _processing || _handover
                  || _pickedUp || (widget.isRunningOrder ?? true);
              _showSlider = (_cod && _accepted && !_restConfModel && !_selfDelivery) || _handover || _pickedUp
                  || (_parcel && _accepted);
            }

            return (orderController.orderDetailsModel != null && controllerOrderModel != null) ? Column(children: [

              Expanded(child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: Column(children: [

                  Row(children: [
                    Text('${_parcel ? 'delivery_id'.tr : 'order_id'.tr}:', style: robotoRegular),
                    SizedBox(width: Dimensions.PADDING_SIZE_EXTRA_SMALL),
                    Text(controllerOrderModel.id.toString(), style: robotoMedium),
                    SizedBox(width: Dimensions.PADDING_SIZE_EXTRA_SMALL),
                    Expanded(child: SizedBox()),
                    Container(height: 7, width: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.green)),
                    SizedBox(width: Dimensions.PADDING_SIZE_EXTRA_SMALL),
                    Text(
                      controllerOrderModel.orderStatus.tr,
                      style: robotoRegular,
                    ),
                  ]),
                  SizedBox(height: Dimensions.PADDING_SIZE_LARGE),

                  Row(children: [
                    Text('${_parcel ? 'charge_payer'.tr : 'item'.tr}:', style: robotoRegular),
                    SizedBox(width: Dimensions.PADDING_SIZE_EXTRA_SMALL),
                    Text(
                      _parcel ? controllerOrderModel.chargePayer.tr : orderController.orderDetailsModel.length.toString(),
                      style: robotoMedium.copyWith(color: Theme.of(context).primaryColor),
                    ),
                    Expanded(child: SizedBox()),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: Dimensions.PADDING_SIZE_SMALL, vertical: Dimensions.PADDING_SIZE_EXTRA_SMALL),
                      decoration: BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
                      child: Text(
                        _cod ? 'cod'.tr : _wallet ? 'wallet'.tr : 'digitally_paid'.tr,
                        style: robotoMedium.copyWith(fontSize: Dimensions.FONT_SIZE_EXTRA_SMALL, color: Theme.of(context).primaryColor),
                      ),
                    ),
                  ]),
                  Divider(height: Dimensions.PADDING_SIZE_LARGE),
                  SizedBox(height: Dimensions.PADDING_SIZE_SMALL),

                  InfoCard(
                    title: _parcel ? 'sender_details'.tr : 'store_details'.tr,
                    address: _parcel ? controllerOrderModel.deliveryAddress : DeliveryAddress(address: controllerOrderModel.storeAddress),
                    image: _parcel ? '' : '${Get.find<SplashController>().configModel.baseUrls.storeImageUrl}/${controllerOrderModel.storeLogo}',
                    name: _parcel ? controllerOrderModel.deliveryAddress.contactPersonName : controllerOrderModel.storeName,
                    phone: _parcel ? controllerOrderModel.deliveryAddress.contactPersonNumber : controllerOrderModel.storePhone,
                    latitude: _parcel ? controllerOrderModel.deliveryAddress.latitude : controllerOrderModel.storeLat,
                    longitude: _parcel ? controllerOrderModel.deliveryAddress.longitude : controllerOrderModel.storeLng,
                    showButton: (controllerOrderModel.orderStatus != 'delivered' && controllerOrderModel.orderStatus != 'failed'
                        && controllerOrderModel.orderStatus != 'canceled' && controllerOrderModel.orderStatus != 'refunded'),
                    isStore: true,
                    messageOnTap: () => Get.toNamed(RouteHelper.getChatRoute(
                      notificationBody: NotificationBody(
                        orderId: controllerOrderModel.id, vendorId: controllerOrderModel.storeId,
                      ),
                      user: User(
                        id: controllerOrderModel.storeId, fName: controllerOrderModel.storeName,
                        image: controllerOrderModel.storeLogo,
                      ),
                    )),
                  ),
                  SizedBox(height: Dimensions.PADDING_SIZE_LARGE),

                  InfoCard(
                    title: _parcel ? 'receiver_details'.tr : 'customer_contact_details'.tr,
                    address: _parcel ? controllerOrderModel.receiverDetails : controllerOrderModel.deliveryAddress,
                    image: _parcel ? '' : controllerOrderModel.customer != null ? '${Get.find<SplashController>().configModel.baseUrls.customerImageUrl}/${controllerOrderModel.customer.image}' : '',
                    name: _parcel ? controllerOrderModel.receiverDetails.contactPersonName : controllerOrderModel.deliveryAddress.contactPersonName,
                    phone: _parcel ? controllerOrderModel.receiverDetails.contactPersonNumber : controllerOrderModel.deliveryAddress.contactPersonNumber,
                    latitude: _parcel ? controllerOrderModel.receiverDetails.latitude : controllerOrderModel.deliveryAddress.latitude,
                    longitude: _parcel ? controllerOrderModel.receiverDetails.longitude : controllerOrderModel.deliveryAddress.longitude,
                    showButton: controllerOrderModel.orderStatus != 'delivered' && controllerOrderModel.orderStatus != 'failed'
                        && controllerOrderModel.orderStatus != 'canceled' && controllerOrderModel.orderStatus != 'refunded',
                    isStore: _parcel ? false : true,
                    messageOnTap: () => Get.toNamed(RouteHelper.getChatRoute(
                      notificationBody: NotificationBody(
                        orderId: controllerOrderModel.id, customerId: controllerOrderModel.customer.id,
                      ),
                      user: User(
                        id: controllerOrderModel.customer.id, fName: controllerOrderModel.customer.fName,
                        lName: controllerOrderModel.customer.lName, image: controllerOrderModel.customer.image,
                      ),
                    )),
                  ),
                  SizedBox(height: Dimensions.PADDING_SIZE_LARGE),

                  _parcel ? Container(
                    padding: EdgeInsets.all(Dimensions.PADDING_SIZE_SMALL),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(Dimensions.RADIUS_SMALL),
                      boxShadow: [BoxShadow(color: Colors.grey[Get.isDarkMode ? 700 : 200], spreadRadius: 1, blurRadius: 5)],
                    ),
                    child: controllerOrderModel.parcelCategory != null ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('parcel_category'.tr, style: robotoRegular),
                      SizedBox(height: Dimensions.PADDING_SIZE_EXTRA_SMALL),
                      Row(children: [
                        ClipOval(child: CustomImage(
                          image: '${Get.find<SplashController>().configModel.baseUrls.parcelCategoryImageUrl}/${controllerOrderModel.parcelCategory.image}',
                          height: 35, width: 35, fit: BoxFit.cover,
                        )),
                        SizedBox(width: Dimensions.PADDING_SIZE_SMALL),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(
                            controllerOrderModel.parcelCategory.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: robotoRegular.copyWith(fontSize: Dimensions.FONT_SIZE_SMALL),
                          ),
                          Text(
                            controllerOrderModel.parcelCategory.description, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: robotoRegular.copyWith(fontSize: Dimensions.FONT_SIZE_SMALL, color: Theme.of(context).disabledColor),
                          ),
                        ])),
                      ]),
                    ]) : SizedBox(
                      width: context.width,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('parcel_category'.tr, style: robotoRegular),
                        SizedBox(height: Dimensions.PADDING_SIZE_EXTRA_SMALL),

                        Text('no_parcel_category_data_found'.tr, style: robotoMedium),
                      ]),
                    ),
                  ) : ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: orderController.orderDetailsModel.length,
                    itemBuilder: (context, index) {
                      return OrderItemWidget(order: controllerOrderModel, orderDetails: orderController.orderDetailsModel[index]);
                    },
                  ),

                  (controllerOrderModel.orderNote  != null && controllerOrderModel.orderNote.isNotEmpty) ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('additional_note'.tr, style: robotoRegular),
                    SizedBox(height: Dimensions.PADDING_SIZE_SMALL),
                    Container(
                      width: 1170,
                      padding: EdgeInsets.all(Dimensions.PADDING_SIZE_SMALL),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(width: 1, color: Theme.of(context).disabledColor),
                      ),
                      child: Text(
                        controllerOrderModel.orderNote,
                        style: robotoRegular.copyWith(fontSize: Dimensions.FONT_SIZE_SMALL, color: Theme.of(context).disabledColor),
                      ),
                    ),
                    SizedBox(height: Dimensions.PADDING_SIZE_LARGE),

                    (Get.find<SplashController>().getModule(controllerOrderModel.moduleType).orderAttachment
                    && controllerOrderModel.orderAttachment != null && controllerOrderModel.orderAttachment.isNotEmpty)
                    ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('prescription'.tr, style: robotoRegular),
                      SizedBox(height: Dimensions.PADDING_SIZE_SMALL),
                      Center(child: ClipRRect(
                        borderRadius: BorderRadius.circular(Dimensions.RADIUS_SMALL),
                        child: CustomImage(
                          image: '${Get.find<SplashController>().configModel.baseUrls.orderAttachmentUrl}/${controllerOrderModel.orderAttachment}',
                          width: 200,
                        ),
                      )),
                      SizedBox(height: Dimensions.PADDING_SIZE_LARGE),
                    ]) : SizedBox(),

                  ]) : SizedBox(),

                ]),
              )),

              _showBottomView ? ((_accepted && !_parcel && (!_cod || _restConfModel || _selfDelivery))
               || _processing || _confirmed) ? Container(
                padding: EdgeInsets.all(Dimensions.PADDING_SIZE_DEFAULT),
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Dimensions.RADIUS_SMALL),
                  border: Border.all(width: 1),
                ),
                alignment: Alignment.center,
                child: Text(
                  _processing ? 'order_is_preparing'.tr : 'order_waiting_for_process'.tr,
                  style: robotoMedium,
                ),
              ) : _showSlider ? ((_cod && _accepted && !_restConfModel && _cancelPermission && !_selfDelivery)
              || (_parcel && _accepted && _cancelPermission)) ? Row(children: [

                Expanded(child: TextButton(
                  onPressed: () => Get.dialog(ConfirmationDialog(
                    icon: Images.warning, title: 'are_you_sure_to_cancel'.tr,
                    description: _parcel ? 'you_want_to_cancel_this_delivery'.tr : 'you_want_to_cancel_this_order'.tr,
                    onYesPressed: () {
                      orderController.updateOrderStatus(controllerOrderModel, AppConstants.CANCELED, back: true);
                    },
                  ), barrierDismissible: false),
                  style: TextButton.styleFrom(
                    minimumSize: Size(1170, 40), padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Dimensions.RADIUS_SMALL),
                      side: BorderSide(width: 1, color: Theme.of(context).textTheme.bodyText1.color),
                    ),
                  ),
                  child: Text('cancel'.tr, textAlign: TextAlign.center, style: robotoRegular.copyWith(
                    color: Theme.of(context).textTheme.bodyText1.color,
                    fontSize: Dimensions.FONT_SIZE_LARGE,
                  )),
                )),
                SizedBox(width: Dimensions.PADDING_SIZE_SMALL),
                Expanded(child: CustomButton(
                  buttonText: 'confirm'.tr, height: 40,
                  onPressed: () {
                    Get.dialog(ConfirmationDialog(
                      icon: Images.warning, title: 'are_you_sure_to_confirm'.tr,
                      description: _parcel ? 'you_want_to_confirm_this_delivery'.tr : 'you_want_to_confirm_this_order'.tr,
                      onYesPressed: () {
                        orderController.updateOrderStatus(
                          controllerOrderModel, _parcel ? AppConstants.HANDOVER : AppConstants.CONFIRMED, back: true,
                        );
                      },
                    ), barrierDismissible: false);
                  },
                )),

              ]) : SliderButton(
                action: () {

                  if((_cod && _accepted && !_restConfModel && !_selfDelivery) || (_parcel && _accepted)) {

                    if(orderController.isLoading){
                      orderController.initLoading();
                    }
                    Get.dialog(ConfirmationDialog(
                      icon: Images.warning, title: 'are_you_sure_to_confirm'.tr,
                      description: _parcel ? 'you_want_to_confirm_this_delivery'.tr : 'you_want_to_confirm_this_order'.tr,
                      onYesPressed: () {
                        orderController.updateOrderStatus(
                          controllerOrderModel, _parcel ? AppConstants.HANDOVER : AppConstants.CONFIRMED, back: true,
                        );
                      },
                    ), barrierDismissible: false);
                  }

                  else if(_pickedUp) {
                    if(_parcel && _cod && controllerOrderModel.chargePayer != 'sender') {
                      Get.bottomSheet(VerifyDeliverySheet(
                        currentOrderModel: controllerOrderModel, verify: Get.find<SplashController>().configModel.orderDeliveryVerification,
                        orderAmount: controllerOrderModel.orderAmount, cod: _cod,
                      ), isScrollControlled: true);
                    }
                    else if((Get.find<SplashController>().configModel.orderDeliveryVerification || _cod) && !_parcel){
                      Get.bottomSheet(VerifyDeliverySheet(
                        currentOrderModel: controllerOrderModel, verify: Get.find<SplashController>().configModel.orderDeliveryVerification,
                        orderAmount: controllerOrderModel.orderAmount, cod: _cod,
                      ), isScrollControlled: true);
                    } else {
                      Get.find<OrderController>().updateOrderStatus(controllerOrderModel, AppConstants.DELIVERED);
                    }
                  }

                  else if(_parcel && controllerOrderModel.chargePayer == 'sender' && _cod){
                    Get.bottomSheet(VerifyDeliverySheet(
                      currentOrderModel: controllerOrderModel, verify: Get.find<SplashController>().configModel.orderDeliveryVerification,
                      orderAmount: controllerOrderModel.orderAmount, cod: _cod, isSenderPay: true,
                    ), isScrollControlled: true);
                  }

                  else if(_handover) {
                    if(Get.find<AuthController>().profileModel.active == 1) {
                      Get.find<OrderController>().updateOrderStatus(controllerOrderModel, AppConstants.PICKED_UP);
                    }else {
                      showCustomSnackBar('make_yourself_online_first'.tr);
                    }
                  }

                },
                label: Text(
                  (_parcel && _accepted) ? 'swipe_to_confirm_delivery'.tr
                      : (_cod && _accepted && !_restConfModel && !_selfDelivery) ? 'swipe_to_confirm_order'.tr
                      : _pickedUp ? _parcel ? 'swipe_to_deliver_parcel'.tr
                      : 'swipe_to_deliver_order'.tr : _handover ? _parcel ? 'swipe_to_pick_up_parcel'.tr
                      : 'swipe_to_pick_up_order'.tr : '',
                  style: robotoMedium.copyWith(fontSize: Dimensions.FONT_SIZE_LARGE, color: Theme.of(context).primaryColor),
                ),
                dismissThresholds: 0.5, dismissible: false, shimmer: true,
                width: 1170, height: 60, buttonSize: 50, radius: 10,
                icon: Center(child: Icon(
                  Get.find<LocalizationController>().isLtr ? Icons.double_arrow_sharp : Icons.keyboard_arrow_left,
                  color: Colors.white, size: 20.0,
                )),
                isLtr: Get.find<LocalizationController>().isLtr,
                boxShadow: BoxShadow(blurRadius: 0),
                buttonColor: Theme.of(context).primaryColor,
                backgroundColor: Color(0xffF4F7FC),
                baseColor: Theme.of(context).primaryColor,
              ) : SizedBox() : SizedBox(),

            ]) : Center(child: CircularProgressIndicator());
          }),
        ),
      ),
    );
  }
}
