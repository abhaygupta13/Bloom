/***
Class       : BAWebServiceHandler
Author      : Biswajeet
Description : 
TestClass   : BAWebServiceHandlerTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.          V1.0              25/08/23           Initial Version 
****************************************************************************************************************/
public class BAWebServiceHandler {
    
    private static BAWebServiceHandler instance;
    
    private BAWebServiceHandler() {
        
    }
    
    public static BAWebServiceHandler getInstance() { 
        if(instance == null) {
            instance = new BAWebServiceHandler();
        }
        return instance;
    }
    
    public void getCustomerDetailsForRegistration(Map<String, Object> data) {
        Map<String, Object> response = new Map<String, Object>();
        
        String documentType = (String)data.get('id_type');
        String documentNumber = (String)data.get('id_value');
        String nationality = (String)data.get('nationality');
        
        String emiratesId = documentType == 'EID' ? documentNumber : '';
        String passportNumber = documentType == 'PASSPORT' ? documentNumber : '';
        response = BAWebServiceHelper.getInstance().getCustomerDetailsForRegistration(emiratesId, passportNumber, nationality);
        String message = !response.isEmpty() ? 'Customer data available' : 'Customer data is not available';
        getSuccessResponse(response, message);
    }
    
    public void createAppRegistrationRequest(Map<String, Object> data) {
        Map<String, Object> response = new Map<String, Object>();
        String customerId = (String)data.get('customer_id');
        String firstName = (String)data.get('first_name');
        String middleName = (String)data.get('middle_name');
        String lastName = (String)data.get('last_name');
        String emiratesId = (String)data.get('emirates_id');
        String passportNumber = (String)data.get('passport_number');
        String nationality = (String)data.get('nationality');
        String phoneCountryCode = (String)data.get('country_code');
        String mobileNumber = (String)data.get('phone_number');
        String email = (String)data.get('email');
        String deviceId = (String)data.get('device_id');
        String registrationType = (String)data.get('registration_type');
        String documentType = (String)data.get('doc_type');
        String otpEmailTxnId = (String)data.get('otpEmailTxnId');
        String otpSMSTxnId = (String)data.get('otpSMSTxnId');
        
        List<AppRegistration__c> objAppRegistrationList = BAWebServiceHelper.getInstance().getExistingAppRegistration(emiratesId, passportNumber, nationality);
        if(objAppRegistrationList != NULL && !objAppRegistrationList.isEmpty()){
            response.put('registration_id', objAppRegistrationList[0].Id);
            getSuccessResponse(response, 'You are already registered');
        }
        else{
            response = BAWebServiceHelper.getInstance().createAppRegistrationRequest(customerId, firstName, middleName, 
                                                                                     lastName, emiratesId, passportNumber,
                                                                                     nationality, phoneCountryCode, mobileNumber,
                                                                                     email, deviceId, registrationType, documentType,
                                                                                     otpEmailTxnId, otpSMSTxnId);
            if (response != null && response.containsKey('registration_id')) {
                getSuccessResponse(response, 'App registration request created successfully');
            }
            else{
                getSuccessResponse(response);
            }
        }  
    }
    
    public void getAppRegistrationStatus(Map<String, Object> data) {
        Map<String, Object> response = new Map<String, Object>();
        String recordId = (String)data.get('registration_id');
        String message = 'Application is exist';
        if(String.isNotBlank(recordId)){
            response = BAWebServiceHelper.getInstance().getAppRegistrationStatus(recordId);
        }else{
            message = 'Invalid application id';
        }
        getSuccessResponse(response, message);
    }
    
    public void getMyProfile(Map<String, Object> data) {
        Map<String, Object> response = new Map<String, Object>();
        String id_type = (String)data.get('id_type');
        String id_value = (String)data.get('id_value');
        response = BAWebServiceHelper.getInstance().getMyProfile(id_type, id_value);
        String message = !response.isEmpty() ? 'This is an active customer' : 'There is no active customers';
        getSuccessResponse(response, message);
    }
    
    public void getUnitInstallments(Map<String, Object> data) {
        Map<String, Object> response = new Map<String, Object>();
        Id salesOrderId = (String)data.get('salesorder_id');
        Id customerId = (String)data.get('customer_id');
        response = BAWebServiceHelper.getInstance().getSalesOrderInstallmentsAndOtherCharges(salesOrderId, customerId);
        getSuccessResponse(response);
    }
    
    public void updateCustomer(Map<String, Object> data) {
        Map<String, Object> response = new Map<String, Object>();
        String communicationType = (String)data.get('comm_type');
        String countryCode = (String)data.get('country_code');
        String mobile = (String)data.get('mobile');
        String email = (String)data.get('email');
        Id customerId = (String)data.get('customer_id');
        response = BAWebServiceHelper.getInstance().updateCustomer(customerId, communicationType, countryCode, mobile,  email);
        String message = 'Customer information has been updated';
        getSuccessResponse(response, message);
    }
    
    public void generateOTP(Map<String, Object> data) {
        Map<String, Object> response = new Map<String, Object>();
        String processType = (String)data.get('processType');
        String commType = (String)data.get('commType');
        String mobileNumber = (String)data.get('mobileNumber');
        String email = (String)data.get('email');
        String parentId = (String)data.get('parentId');
        response = BAWebServiceHelper.getInstance().sendOTP(processType, email, mobileNumber, commType, parentId);
        String message = 'OTP was sent successfully!';
        getSuccessResponse(response, message);
    }
    
    public void verifyOTP(Map<String, Object> data) {
        Map<String, Object> response = new Map<String, Object>();
        String transactionId = (String)data.get('transactionId');
        String parentId = (String)data.get('parentId');
        String otp = (String)data.get('otp');
        response = BAWebServiceHelper.getInstance().verifyOTP(parentId, otp, transactionId);
        String message = 'OTP verified successfully!';
        if(response != NULL && !response.isEmpty()){
            message = (Boolean)response.get('isValid') ? 'OTP verified successfully!' : 'OTP verified unsuccessfully!';
        }
        getSuccessResponse(response, message);
    }
    
    public void getListValues(Map<String, Object> data) {
        Map<String, Object> response = new Map<String, Object>();
        String lisType = (String)data.get('lisType');
        response = BAWebServiceHelper.getInstance().getListValues(lisType);
        String message = 'List values fetched successfully!';
        getSuccessResponse(response, message);
    }
    
    public void doCreateSR(Map<String, Object> data) {
        Map<String, Object> response = new Map<String, Object>();
        String customerId = (String)data.get('customer_Id');
        Id requestTypeId = (Id)data.get('request_Type_Id');
        String parentId = (String)data.get('parentId');
        String email = (String)data.get('email');
        String mobileCountryCode = (String)data.get('country_code');
        String mobile = (String)data.get('phone_number');
        String subject = (String)data.get('subject');
        String description = (String)data.get('description');
        response = BAWebServiceHelper.getInstance().doCreateSR(requestTypeId, customerId, parentId, email, mobileCountryCode, mobile, subject, description);
        String message = 'SR created successfully!';
        getSuccessResponse(response, message);
    }
    
    public void getSRs(Map<String, Object> data) {
        Map<String, Object> response = new Map<String, Object>();
        Id customerId = (Id)data.get('customer_id');
        response = BAWebServiceHelper.getInstance().getSRs(customerId);
        String message = 'SR list fetched successfully!';
        getSuccessResponse(response, message);
    }
    
    public void doPostSRFollowUp(Map<String, Object> data) {
        Map<String, Object> response = new Map<String, Object>();
        Id srId = (Id)data.get('sr_id');
        Id customerId = (Id)data.get('customer_id');
        String remarks = (String)data.get('remarks');
        response = BAWebServiceHelper.getInstance().doPostSRFollowUp(customerId, srId, remarks);
        String message = 'SR follow up created successfully!';
        getSuccessResponse(response, message);
    }
    
    public void downloadDocument(Map<String, Object> data) {
        Map<String, Object> response = new Map<String, Object>();
        String docType = (String)data.get('doc_type');
        Id parentId = (Id)data.get('parent_id');
        Id customerId = (Id)data.get('customer_id');
        Boolean sendAsEmail = (Boolean)data.get('send_as_email');
        response = BAWebServiceHelper.getInstance().downloadDocument(docType, parentId, customerId, sendAsEmail);
        String message = '';
        getSuccessResponse(response, message);
    }
    
    public void uploadDocument(Map<String, Object> data) {
        Map<String, Object> response = new Map<String, Object>();
        String docType = (String)data.get('doc_type');
        Id parentId = (Id)data.get('parent_id');
        Id customerId = (Id)data.get('customer_id');
        Boolean sendAsEmail = (Boolean)data.get('send_as_email');
        response = BAWebServiceHelper.getInstance().uploadDocument(docType, parentId, customerId);
        String message = '';
        getSuccessResponse(response, message);
    }

    public void getAuthorizedUAEPassLoginUser(Map<String, Object> data){
        Map<String, Object> response = new Map<String, Object>();
        String eid = (String)data.get('eid');
        String uuid = (String)data.get('uuid');
        String phoneNumber = (String)data.get('phone_number');
        String email = (String)data.get('email');

        response = BAWebServiceHelper.getInstance().getAuthorizedUAEPassLoginUser(eid, uuid, phoneNumber, email);
        String message = '';
        getSuccessResponse(response, message);
    }

     public void manageAppointment(Map<String, Object> data) {
        Map<String, Object> response = new Map<String, Object>();
        String customerId = (String)data.get('customer_id');
        String actionType = (String)data.get('action_type');
        String reason = (String)data.get('reason');
        String appointmentSlotId = (String)data.get('appointment_slot_id');
        String eventId = (String)data.get('event_id');
        String mode = (String)data.get('mode');

        response = BAWebServiceHelper.getInstance().manageAppointment(customerId, appointmentSlotId, actionType, reason, eventId, mode);
        String message = '';
        getSuccessResponse(response, message);
    }
    
    public void getSuccessResponse(Map<String, Object> response) {
        Map<String, Object> result = new Map<String, Object>();
        RestResponse res = RestContext.response;
        res.statusCode = 200; // HTTP 200 OK
        res.headers.put('Content-Type', 'application/json');
        result.put('data', response);
        if(response != NULL && !response.isEmpty()){
            result.put('message', 'Data available');
        }else{
            result.put('message', 'Data not available');
        }
        result.put('status', 'success');
        res.responseBody = Blob.valueOf(JSON.serialize(result));
    }
    
    public void getSuccessResponse(Map<String, Object> response, string message) {
        Map<String, Object> result = new Map<String, Object>();
        RestResponse res = RestContext.response;
        if(res != null) {
            res.statusCode = 200; // HTTP 200 OK
            res.headers.put('Content-Type', 'application/json');
            result.put('data', response);
            result.put('message', message);
            result.put('status', 'success');
            res.responseBody = Blob.valueOf(JSON.serialize(result));
        }
    }
    
    public void getServerErrorResponse(Map<String, Object> response) {
        RestResponse res = RestContext.response;
        Map<String, Object> result = new Map<String, Object>();
        res.statusCode = 500;
        res.headers.put('Content-Type', 'application/json');
        result.put('message', response);
        result.put('status', 'error');
        res.responseBody = Blob.valueOf(JSON.serialize(result));
    }
}