import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart_delivery/controller/chat_controller.dart';
import 'package:sixam_mart_delivery/controller/splash_controller.dart';
import 'package:sixam_mart_delivery/data/model/body/notification_body.dart';
import 'package:sixam_mart_delivery/data/model/response/conversation_model.dart';
import 'package:sixam_mart_delivery/helper/date_converter.dart';
import 'package:sixam_mart_delivery/helper/route_helper.dart';
import 'package:sixam_mart_delivery/helper/user_type.dart';
import 'package:sixam_mart_delivery/util/dimensions.dart';
import 'package:sixam_mart_delivery/util/styles.dart';
import 'package:sixam_mart_delivery/view/base/custom_app_bar.dart';
import 'package:sixam_mart_delivery/view/base/custom_image.dart';
import 'package:sixam_mart_delivery/view/base/custom_ink_well.dart';
import 'package:sixam_mart_delivery/view/base/custom_snackbar.dart';
import 'package:sixam_mart_delivery/view/base/paginated_list_view.dart';
import 'package:sixam_mart_delivery/view/screens/chat/widget/search_field.dart';
class ConversationScreen extends StatefulWidget {
  const ConversationScreen({Key key}) : super(key: key);

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    Get.find<ChatController>().getConversationList(1);

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'conversation_list'.tr),
      body: GetBuilder<ChatController>(builder: (chatController) {

        ConversationsModel _conversation;
        if(chatController.searchConversationModel != null) {
          _conversation = chatController.searchConversationModel;
        }else {
          _conversation = chatController.conversationModel;
        }

        return Padding(
          padding: EdgeInsets.all(Dimensions.PADDING_SIZE_SMALL),
          child: Column(children: [

            (_conversation != null && _conversation.conversations != null) ? SearchField(
              controller: _searchController,
              hint: 'search'.tr,
              suffixIcon: chatController.searchConversationModel != null ? Icons.close : Icons.search,
              onSubmit: (String text) {
                if(_searchController.text.trim().isNotEmpty) {
                  chatController.searchConversation(_searchController.text.trim());
                }else {
                  showCustomSnackBar('write_somethings'.tr);
                }
              },
              iconPressed: () {
                if(chatController.searchConversationModel != null) {
                  _searchController.text = '';
                  chatController.removeSearchMode();
                }else {
                  if(_searchController.text.trim().isNotEmpty) {
                    chatController.searchConversation(_searchController.text.trim());
                  }else {
                    showCustomSnackBar('write_somethings'.tr);
                  }
                }
              },
            ) : SizedBox(),

            SizedBox(height: (_conversation != null && _conversation.conversations != null
                && chatController.conversationModel.conversations.isNotEmpty) ? Dimensions.PADDING_SIZE_SMALL : 0),

            Expanded(
              child: (_conversation != null && _conversation.conversations != null)
                  ? _conversation.conversations.length > 0 ? RefreshIndicator(
                    onRefresh: () async {
                      chatController.getConversationList(1);
                    },
                    child: Scrollbar(child: SingleChildScrollView(controller: _scrollController,
                        child: Center(child: SizedBox(width: 1170,
                        child:  PaginatedListView(
                          scrollController: _scrollController,
                          onPaginate: (int offset) => chatController.getConversationList(offset),
                          totalSize: _conversation.totalSize,
                          offset: _conversation.offset,
                          enabledPagination: chatController.searchConversationModel == null,
                          productView: ListView.builder(
                            itemCount: _conversation.conversations.length,
                            padding: EdgeInsets.zero,
                            physics: NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemBuilder: (context, index) {

                              Conversation conversation = _conversation.conversations[index];

                              User _user;
                              String _type;
                              if(conversation.senderType == UserType.delivery_man.name) {
                                _user = conversation.receiver;
                                _type = conversation.receiverType;
                              }else {
                                _user = conversation.sender;
                                _type = conversation.senderType;
                              }

                              String _baseUrl = '';
                              if(_type == UserType.customer.name) {
                                _baseUrl = Get.find<SplashController>().configModel.baseUrls.customerImageUrl;
                              }else {
                                _baseUrl = Get.find<SplashController>().configModel.baseUrls.storeImageUrl;
                              }

                              return Container(
                                margin: EdgeInsets.symmetric(vertical: Dimensions.PADDING_SIZE_EXTRA_SMALL),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(Dimensions.RADIUS_SMALL),
                                  boxShadow: [BoxShadow(color: Colors.grey[Get.isDarkMode ? 800 : 200], spreadRadius: 1, blurRadius: 5)],
                                ),
                                child: CustomInkWell(
                                  onTap: (){
                                    if(_user != null){
                                      Get.toNamed(RouteHelper.getChatRoute(
                                        notificationBody: NotificationBody(
                                          type: conversation.senderType, notificationType: NotificationType.message,
                                          customerId: _type == UserType.customer.name ? _user.userId : null,
                                          vendorId: _type == UserType.vendor.name ? _user.vendorId : null,
                                        ),
                                        conversationId: conversation.id,
                                      )).then((value) => Get.find<ChatController>().getConversationList(1));
                                    }else{
                                      showCustomSnackBar('${_type.tr} ${'not_found'.tr}');
                                    }
                                  },
                                  highlightColor: Theme.of(context).backgroundColor.withOpacity(0.1),
                                  radius: Dimensions.RADIUS_SMALL,
                                  child: Stack(children: [
                                    Padding(
                                      padding: const EdgeInsets.all(Dimensions.PADDING_SIZE_SMALL),
                                      child: Row(children: [
                                        ClipOval(
                                          child: CustomImage(
                                            height: 50, width: 50,fit: BoxFit.cover,
                                            image: '$_baseUrl/${_user != null ? _user.image : ''}'?? '',
                                          ),
                                        ),
                                        SizedBox(width: Dimensions.PADDING_SIZE_SMALL),

                                        Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: [

                                          _user != null ? Text('${_user.fName} ${_user.lName}', style: robotoMedium)
                                              : Text('${_type.tr} ${'deleted'.tr}', style: robotoMedium),
                                          SizedBox(height: Dimensions.PADDING_SIZE_EXTRA_SMALL),

                                          Text(
                                            '${_type.tr}',
                                            style: robotoRegular.copyWith(fontSize: Dimensions.FONT_SIZE_SMALL, color: Theme.of(context).disabledColor),
                                          ),
                                        ])),
                                      ]),
                                    ),

                                    Positioned( right: 5,bottom: 5,
                                      child: Text(
                                        DateConverter.localDateToIsoStringAMPM(DateConverter.dateTimeStringToDate(conversation.lastMessageTime)),
                                        style: robotoRegular.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.FONT_SIZE_EXTRA_SMALL),
                                      ),
                                    ),

                                    conversation.unreadMessageCount > 0 ? Positioned( right: 5,top: 5,
                                      child: Container(
                                          padding: EdgeInsets.all((conversation.lastMessage.senderId == _user.id) ? Dimensions.PADDING_SIZE_EXTRA_SMALL : 0.0),
                                          decoration: BoxDecoration(color: Theme.of(context).primaryColor, shape: BoxShape.circle),
                                          child: Text(
                                            conversation.lastMessage != null ? (conversation.lastMessage.senderId == _user.id)
                                                ? conversation.unreadMessageCount.toString() : '' : conversation.unreadMessageCount.toString(),
                                            style: robotoMedium.copyWith(color: Theme.of(context).cardColor, fontSize: Dimensions.FONT_SIZE_EXTRA_SMALL),
                                          )),
                                    ) : SizedBox(),

                                  ]),
                                ),
                              );
                            },
                          ),
                        ))))),
                  ) : Center(child: Text('no_conversation_found'.tr, style: robotoMedium)) : Center(child: CircularProgressIndicator()),
            ) ,
          ]),
        );
      }),
    );
  }
}
