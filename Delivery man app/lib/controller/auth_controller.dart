import 'dart:async';
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sixam_mart_delivery/controller/splash_controller.dart';
import 'package:sixam_mart_delivery/data/api/api_checker.dart';
import 'package:sixam_mart_delivery/data/api/api_client.dart';
import 'package:sixam_mart_delivery/data/model/body/delivery_man_body.dart';
import 'package:sixam_mart_delivery/data/model/body/record_location_body.dart';
import 'package:sixam_mart_delivery/data/model/response/address_model.dart';
import 'package:sixam_mart_delivery/data/model/response/profile_model.dart';
import 'package:sixam_mart_delivery/data/model/response/response_model.dart';
import 'package:sixam_mart_delivery/data/model/response/zone_model.dart';
import 'package:sixam_mart_delivery/data/model/response/zone_response_model.dart';
import 'package:sixam_mart_delivery/data/repository/auth_repo.dart';
import 'package:sixam_mart_delivery/helper/route_helper.dart';
import 'package:sixam_mart_delivery/util/images.dart';
import 'package:sixam_mart_delivery/view/base/confirmation_dialog.dart';
import 'package:sixam_mart_delivery/view/base/custom_alert_dialog.dart';
import 'package:sixam_mart_delivery/view/base/custom_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geocoding/geocoding.dart' as GeoCoding;

class AuthController extends GetxController implements GetxService {
  final AuthRepo authRepo;
  AuthController({@required this.authRepo}) {
   _notification = authRepo.isNotificationActive();
  }

  bool _isLoading = false;
  bool _notification = true;
  ProfileModel _profileModel;
  XFile _pickedFile;
  Timer _timer;

  XFile _pickedImage;
  List<XFile> _pickedIdentities = [];
  List<String> _identityTypeList = ['passport', 'driving_license', 'nid'];
  int _identityTypeIndex = 0;
  List<String> _dmTypeList = ['freelancer', 'salary_based'];
  int _dmTypeIndex = 0;
  XFile _pickedLogo;
  XFile _pickedCover;
  List<ZoneModel> _zoneList;
  int _selectedZoneIndex = 0;
  LatLng _restaurantLocation;
  List<int> _zoneIds;
  bool _loading = false;
  bool _inZone = false;
  int _zoneID = 0;

  bool get isLoading => _isLoading;
  bool get notification => _notification;
  ProfileModel get profileModel => _profileModel;
  XFile get pickedFile => _pickedFile;

  XFile get pickedImage => _pickedImage;
  List<XFile> get pickedIdentities => _pickedIdentities;
  List<String> get identityTypeList => _identityTypeList;
  int get identityTypeIndex => _identityTypeIndex;
  List<String> get dmTypeList => _dmTypeList;
  int get dmTypeIndex => _dmTypeIndex;
  XFile get pickedLogo => _pickedLogo;
  XFile get pickedCover => _pickedCover;
  List<ZoneModel> get zoneList => _zoneList;
  int get selectedZoneIndex => _selectedZoneIndex;
  LatLng get restaurantLocation => _restaurantLocation;
  List<int> get zoneIds => _zoneIds;
  bool get loading => _loading;
  bool get inZone => _inZone;
  int get zoneID => _zoneID;

  Future<ResponseModel> login(String phone, String password) async {
    _isLoading = true;
    update();
    Response response = await authRepo.login(phone, password);
    ResponseModel responseModel;
    if (response.statusCode == 200) {
      authRepo.saveUserToken(response.body['token'], response.body['zone_wise_topic']);
      await authRepo.updateToken();
      responseModel = ResponseModel(true, 'successful');
    } else {
      responseModel = ResponseModel(false, response.statusText);
    }
    _isLoading = false;
    update();
    return responseModel;
  }

  Future<void> getProfile() async {
    Response response = await authRepo.getProfileInfo();
    if (response.statusCode == 200) {
      _profileModel = ProfileModel.fromJson(response.body);
      if (_profileModel.active == 1) {
        LocationPermission permission = await Geolocator.checkPermission();
        if(permission == LocationPermission.denied || permission == LocationPermission.deniedForever
            || (GetPlatform.isIOS ? false : permission == LocationPermission.whileInUse)) {
          Get.dialog(ConfirmationDialog(
            icon: Images.location_permission,
            iconSize: 200,
            hasCancel: false,
            description: 'this_app_collects_location_data'.tr,
            onYesPressed: () {
              Get.back();
              _checkPermission(() => startLocationRecord());
            },
          ), barrierDismissible: false);
        }else {
          startLocationRecord();
        }
      } else {
        stopLocationRecord();
      }
    } else {
      ApiChecker.checkApi(response);
    }
    update();
  }

  Future<bool> updateUserInfo(ProfileModel updateUserModel, String token) async {
    _isLoading = true;
    update();
    Response response = await authRepo.updateProfile(updateUserModel, _pickedFile, token);
    _isLoading = false;
    bool _isSuccess;
    if (response.statusCode == 200) {
      _profileModel = updateUserModel;
      showCustomSnackBar(response.body['message'], isError: false);
      _isSuccess = true;
    } else {
      ApiChecker.checkApi(response);
      _isSuccess = false;
    }
    update();
    return _isSuccess;
  }

  void pickImage() async {
    _pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    update();
  }

  Future<bool> changePassword(ProfileModel updatedUserModel, String password) async {
    _isLoading = true;
    update();
    bool _isSuccess;
    Response response = await authRepo.changePassword(updatedUserModel, password);
    _isLoading = false;
    if (response.statusCode == 200) {
      String message = response.body["message"];
      showCustomSnackBar(message, isError: false);
      _isSuccess = true;
    } else {
      ApiChecker.checkApi(response);
      _isSuccess = false;
    }
    update();
    return _isSuccess;
  }

  Future<bool> updateActiveStatus() async {
    Response response = await authRepo.updateActiveStatus();
    bool _isSuccess;
    if (response.statusCode == 200) {
      _profileModel.active = _profileModel.active == 0 ? 1 : 0;
      showCustomSnackBar(response.body['message'], isError: false);
      _isSuccess = true;
      if (_profileModel.active == 1) {
        LocationPermission permission = await Geolocator.checkPermission();
        if(permission == LocationPermission.denied || permission == LocationPermission.deniedForever
            || (GetPlatform.isIOS ? false : permission == LocationPermission.whileInUse)) {
          Get.dialog(ConfirmationDialog(
            icon: Images.location_permission,
            iconSize: 200,
            hasCancel: false,
            description: 'this_app_collects_location_data'.tr,
            onYesPressed: () {
              Get.back();
              _checkPermission(() => startLocationRecord());
            },
          ), barrierDismissible: false);
        }else {
          startLocationRecord();
        }
      } else {
        stopLocationRecord();
      }
    } else {
      ApiChecker.checkApi(response);
      _isSuccess = false;
    }
    update();
    return _isSuccess;
  }

  void startLocationRecord() {
    // _location.enableBackgroundMode(enable: true);
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 10), (timer) {
      recordLocation();
    });
  }

  void stopLocationRecord() {
    // _location.enableBackgroundMode(enable: false);
    _timer?.cancel();
  }

  Future<void> recordLocation() async {
    final Position _locationResult = await Geolocator.getCurrentPosition();
    print('This is current Location: Latitude: ${_locationResult.latitude} Longitude: ${_locationResult.longitude}');
    String _address;
    try{
      List<GeoCoding.Placemark> _addresses = await GeoCoding.placemarkFromCoordinates(_locationResult.latitude, _locationResult.longitude);
      GeoCoding.Placemark _placeMark = _addresses.first;
      _address = '${_placeMark.name}, ${_placeMark.subAdministrativeArea}, ${_placeMark.isoCountryCode}';
    }catch(e) {
      _address = 'Unknown Location Found';
    }
    RecordLocationBody _recordLocation = RecordLocationBody(
      location: _address, latitude: _locationResult.latitude, longitude: _locationResult.longitude,
    );

    await authRepo.recordLocation(_recordLocation);
  }

  Future<ResponseModel> forgetPassword(String email) async {
    _isLoading = true;
    update();
    Response response = await authRepo.forgetPassword(email);

    ResponseModel responseModel;
    if (response.statusCode == 200) {
      responseModel = ResponseModel(true, response.body["message"]);
    } else {
      responseModel = ResponseModel(false, response.statusText);
    }
    _isLoading = false;
    update();
    return responseModel;
  }

  Future<void> updateToken() async {
    await authRepo.updateToken();
  }

  Future<ResponseModel> verifyToken(String number) async {
    _isLoading = true;
    update();
    Response response = await authRepo.verifyToken(number, _verificationCode);
    ResponseModel responseModel;
    if (response.statusCode == 200) {
      responseModel = ResponseModel(true, response.body["message"]);
    } else {
      responseModel = ResponseModel(false, response.statusText);
    }
    _isLoading = false;
    update();
    return responseModel;
  }

  Future<ResponseModel> resetPassword(String resetToken, String phone, String password, String confirmPassword) async {
    _isLoading = true;
    update();
    Response response = await authRepo.resetPassword(resetToken, phone, password, confirmPassword);
    ResponseModel responseModel;
    if (response.statusCode == 200) {
      responseModel = ResponseModel(true, response.body["message"]);
    } else {
      responseModel = ResponseModel(false, response.statusText);
    }
    _isLoading = false;
    update();
    return responseModel;
  }

  String _verificationCode = '';

  String get verificationCode => _verificationCode;

  void updateVerificationCode(String query) {
    _verificationCode = query;
    update();
  }


  bool _isActiveRememberMe = false;

  bool get isActiveRememberMe => _isActiveRememberMe;

  void toggleRememberMe() {
    _isActiveRememberMe = !_isActiveRememberMe;
    update();
  }

  bool isLoggedIn() {
    return authRepo.isLoggedIn();
  }

  Future<bool> clearSharedData() async {
    return await authRepo.clearSharedData();
  }

  void saveUserNumberAndPassword(String number, String password, String countryCode) {
    authRepo.saveUserNumberAndPassword(number, password, countryCode);
  }

  String getUserNumber() {
    return authRepo.getUserNumber() ?? "";
  }

  String getUserCountryCode() {
    return authRepo.getUserCountryCode() ?? "";
  }

  String getUserPassword() {
    return authRepo.getUserPassword() ?? "";
  }

  Future<bool> clearUserNumberAndPassword() async {
    return authRepo.clearUserNumberAndPassword();
  }

  String getUserToken() {
    return authRepo.getUserToken();
  }

  bool setNotificationActive(bool isActive) {
    _notification = isActive;
    authRepo.setNotificationActive(isActive);
    update();
    return _notification;
  }

  void initData() {
    _pickedFile = null;
  }

  void _checkPermission(Function callback) async {
    LocationPermission permission = await Geolocator.requestPermission();
    permission = await Geolocator.checkPermission();
    if(permission == LocationPermission.denied
        || (GetPlatform.isIOS ? false : permission == LocationPermission.whileInUse)) {
      Get.dialog(CustomAlertDialog(description: 'you_denied'.tr, onOkPressed: () async {
        Get.back();
        await Geolocator.requestPermission();
        _checkPermission(callback);
      }), barrierDismissible: false);
    }else if(permission == LocationPermission.deniedForever) {
      Get.dialog(CustomAlertDialog(description: 'you_denied_forever'.tr, onOkPressed: () async {
        Get.back();
        await Geolocator.openAppSettings();
        _checkPermission(callback);
      }), barrierDismissible: false);
    }else {
      callback();
    }
  }

  Future removeDriver() async {
    _isLoading = true;
    update();
    Response response = await authRepo.deleteDriver();
    _isLoading = false;
    if (response.statusCode == 200) {
      showCustomSnackBar('your_account_remove_successfully'.tr, isError: false);
      Get.find<AuthController>().clearSharedData();
      Get.find<AuthController>().stopLocationRecord();
      Get.offAllNamed(RouteHelper.getSignInRoute());
    }else{
      Get.back();
      ApiChecker.checkApi(response);
    }
  }

  void setDMTypeIndex(String dmType, bool notify) {
    _dmTypeIndex = _dmTypeList.indexOf(dmType);
    if(notify) {
      update();
    }
  }

  void setZoneIndex(int index) {
    _selectedZoneIndex = index;
    update();
  }

  Future<void> getZoneList() async {
    _pickedLogo = null;
    _pickedCover = null;
    _selectedZoneIndex = 0;
    _restaurantLocation = null;
    _zoneIds = null;
    Response response = await authRepo.getZoneList();
    if (response.statusCode == 200) {
      _zoneList = [];
      response.body.forEach((zone) => _zoneList.add(ZoneModel.fromJson(zone)));
      setLocation(LatLng(
        double.parse(Get.find<SplashController>().configModel.defaultLocation.lat ?? '0'),
        double.parse(Get.find<SplashController>().configModel.defaultLocation.lng ?? '0'),
      ));
    } else {
      ApiChecker.checkApi(response);
    }
    update();
  }

  void setLocation(LatLng location) async {
    ZoneResponseModel _response = await getZone(
      location.latitude.toString(), location.longitude.toString(), false,
    );
    if(_response != null && _response.isSuccess && _response.zoneIds.length > 0) {
      _restaurantLocation = location;
      _zoneIds = _response.zoneIds;
      for(int index=0; index<_zoneList.length; index++) {
        if(_zoneIds.contains(_zoneList[index].id)) {
          _selectedZoneIndex = index;
          break;
        }
      }
    }else {
      _restaurantLocation = null;
      _zoneIds = null;
    }
    update();
  }

  Future<ZoneResponseModel> getZone(String lat, String long, bool markerLoad, {bool updateInAddress = false}) async {
    if(markerLoad) {
      _loading = true;
    }else {
      _isLoading = true;
    }
    print('problem start');
    if(!updateInAddress){
      update();
    }
    ZoneResponseModel _responseModel;
    Response response = await authRepo.getZone(lat, long);
    if(response.statusCode == 200) {
      _inZone = true;
      _zoneID = int.parse(jsonDecode(response.body['zone_id'])[0].toString());
      List<int> _zoneIds = [];
      jsonDecode(response.body['zone_id']).forEach((zoneId){
        _zoneIds.add(int.parse(zoneId.toString()));
      });
      // List<ZoneData> _zoneData = [];
      // response.body['zone_data'].forEach((zoneData) => _zoneData.add(ZoneData.fromJson(zoneData)));
      // _responseModel = ZoneResponseModel(true, '' , _zoneIds, _zoneData);
      // if(updateInAddress) {
      //   print('here problem');
      //   AddressModel _address = getUserAddress();
      //   _address.zoneData = _zoneData;
      //   saveUserAddress(_address);
      // }
    }else {
      _inZone = false;
      _responseModel = ZoneResponseModel(false, response.statusText, [], []);
    }
    if(markerLoad) {
      _loading = false;
    }else {
      _isLoading = false;
    }
    update();
    return _responseModel;
  }

  AddressModel getUserAddress() {
    AddressModel _addressModel;
    try {
      _addressModel = AddressModel.fromJson(jsonDecode(authRepo.getUserAddress()));
    }catch(e) {}
    return _addressModel;
  }

  Future<bool> saveUserAddress(AddressModel address) async {
    String userAddress = jsonEncode(address.toJson());
    return await authRepo.saveUserAddress(userAddress, address.zoneIds);
  }

  void setIdentityTypeIndex(String identityType, bool notify) {
    int _index = 0;
    for(int index=0; index<_identityTypeList.length; index++) {
      if(_identityTypeList[index] == identityType) {
        _index = index;
        break;
      }
    }
    _identityTypeIndex = _index;
    if(notify) {
      update();
    }
  }

  void pickDmImage(bool isLogo, bool isRemove) async {
    if(isRemove) {
      _pickedImage = null;
      _pickedIdentities = [];
    }else {
      if (isLogo) {
        _pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
      } else {
        XFile _xFile = await ImagePicker().pickImage(source: ImageSource.gallery);
        if(_xFile != null) {
          _pickedIdentities.add(_xFile);
        }
      }
      update();
    }
  }

  void removeIdentityImage(int index) {
    _pickedIdentities.removeAt(index);
    update();
  }

  Future<void> registerDeliveryMan(DeliveryManBody deliveryManBody) async {
    _isLoading = true;
    update();
    List<MultipartBody> _multiParts = [];
    _multiParts.add(MultipartBody('image', _pickedImage));
    for(XFile file in _pickedIdentities) {
      _multiParts.add(MultipartBody('identity_image[]', file));
    }
    Response response = await authRepo.registerDeliveryMan(deliveryManBody, _multiParts);
    if (response.statusCode == 200) {
      Get.offAllNamed(RouteHelper.getInitialRoute());
      showCustomSnackBar('delivery_man_registration_successful'.tr, isError: false);
    } else {
      ApiChecker.checkApi(response);
    }
    _isLoading = false;
    update();
  }

}