
enum NotificationType{
  message,
  order,
  general,
  order_request
}

class NotificationBody {
  NotificationType notificationType;
  int orderId;
  int customerId;
  int vendorId;
  String type;
  int conversationId;

  NotificationBody({
    this.notificationType,
    this.orderId,
    this.customerId,
    this.vendorId,
    this.type,
    this.conversationId,
  });

  NotificationBody.fromJson(Map<String, dynamic> json) {
    notificationType = convertToEnum(json['order_notification']);
    orderId = json['order_id'];
    customerId = json['customer_id'];
    vendorId = json['vendor_id'];
    type = json['type'];
    conversationId = json['conversation_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['order_notification'] = this.notificationType.toString();
    data['order_id'] = this.orderId;
    data['customer_id'] = this.customerId;
    data['vendor_id'] = this.vendorId;
    data['type'] = this.type;
    data['conversation_id'] = this.conversationId;
    return data;
  }

  NotificationType convertToEnum(String enumString) {
    if(enumString == NotificationType.general.toString()) {
      return NotificationType.general;
    }else if(enumString == NotificationType.order.toString()) {
      return NotificationType.order;
    }else if(enumString == NotificationType.order_request.toString()) {
      return NotificationType.order_request;
    }else if(enumString == NotificationType.message.toString()) {
      return NotificationType.message;
    }
    return NotificationType.general;
  }
}
