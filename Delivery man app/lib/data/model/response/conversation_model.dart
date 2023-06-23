class ConversationsModel {
  int totalSize;
  int limit;
  int offset;
  List<Conversation> conversations;

  ConversationsModel({this.totalSize, this.limit, this.offset, this.conversations});

  ConversationsModel.fromJson(Map<String, dynamic> json) {
    totalSize = json['total_size'];
    limit = json['limit'];
    offset = json['offset'];
    if (json['conversation'] != null) {
      conversations = <Conversation>[];
      json['conversation'].forEach((v) {
        conversations.add(new Conversation.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['total_size'] = this.totalSize;
    data['limit'] = this.limit;
    data['offset'] = this.offset;
    if (this.conversations != null) {
      data['conversation'] = this.conversations.map((v) => v.toJson()).toList();
    }
    return data;
  }

}

class Conversation {
  int id;
  int senderId;
  String senderType;
  int receiverId;
  String receiverType;
  int unreadMessageCount;
  int lastMessageId;
  String lastMessageTime;
  String createdAt;
  String updatedAt;
  User sender;
  User receiver;
  LastMessage lastMessage;


  Conversation({
    this.id,
    this.senderId,
    this.senderType,
    this.receiverId,
    this.receiverType,
    this.unreadMessageCount,
    this.lastMessageId,
    this.lastMessageTime,
    this.createdAt,
    this.updatedAt,
    this.sender,
    this.receiver,
    this.lastMessage,
  });

  Conversation.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    senderId = json['sender_id'];
    senderType = json['sender_type'];
    receiverId = json['receiver_id'];
    receiverType = json['receiver_type'];
    unreadMessageCount = json['unread_message_count'];
    lastMessageId = json['last_message_id'];
    lastMessageTime = json['last_message_time'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    sender = json['sender'] != null ? new User.fromJson(json['sender']) : null;
    receiver = json['receiver'] != null ? new User.fromJson(json['receiver']) : null;
    lastMessage = json['last_message'] != null ? new LastMessage.fromJson(json['last_message']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['sender_id'] = this.senderId;
    data['sender_type'] = this.senderType;
    data['receiver_id'] = this.receiverId;
    data['receiver_type'] = this.receiverType;
    data['unread_message_count'] = this.unreadMessageCount;
    data['last_message_id'] = this.lastMessageId;
    data['last_message_time'] = this.lastMessageTime;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    if (this.sender != null) {
      data['sender'] = this.sender.toJson();
    }
    if (this.receiver != null) {
      data['receiver'] = this.receiver.toJson();
    }
    data['last_message'] = this.lastMessage;

    return data;
  }
}

class User {
  int id;
  String fName;
  String lName;
  String phone;
  String email;
  String image;
  int userId;
  int vendorId;
  int deliveryManId;
  String createdAt;
  String updatedAt;

  User(
      {this.id,
        this.fName,
        this.lName,
        this.phone,
        this.email,
        this.image,
        this.userId,
        this.vendorId,
        this.deliveryManId,
        this.createdAt,
        this.updatedAt});

  User.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    fName = json['f_name'];
    lName = json['l_name'];
    phone = json['phone'];
    email = json['email'];
    image = json['image'];
    userId = json['user_id'];
    vendorId = json['vendor_id'];
    deliveryManId = json['deliveryman_id'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['f_name'] = this.fName;
    data['l_name'] = this.lName;
    data['phone'] = this.phone;
    data['email'] = this.email;
    data['image'] = this.image;
    data['user_id'] = this.userId;
    data['vendor_id'] = this.vendorId;
    data['deliveryman_id'] = this.deliveryManId;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    return data;
  }
}

class LastMessage {
  int id;
  int conversationId;
  int senderId;
  String message;
  int isSeen;

  LastMessage({
    this.id,
    this.conversationId,
    this.senderId,
    this.message,
    this.isSeen,
  });

  LastMessage.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    conversationId = json['conversation_id'];
    senderId = json['sender_id'];
    message = json['message'];
    isSeen = json['is_seen'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['conversation_id'] = this.conversationId;
    data['sender_id'] = this.senderId;
    data['message'] = this.message;
    data['is_seen'] = this.isSeen;
    return data;
  }
}
