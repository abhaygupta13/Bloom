/*
* @Author: Shruti Kulkarni
* @CreatedDate: 28th May 2025
* @Description: Class contains the logic to handle the OTP functionalities through API
*/
/*****************************************************************************************************
* Version       Author      	   Date             Comment                                                                       
* 1.1           Shruti Kulkarni    28th MAY 2025    Initial Draft
*****************************************************************************************************/
public class OTPHandler {
    
    private static final String MTD_OWE_OTP_EXPIRATION_MINUTES { get { return 'OTPExpirationMinutes'; } }
    private static final String MTD_OWE_OTP_LENGTH { get { return 'OTPLength'; } }
    
    public OTPHandler() {
        
    }
    
    private static OTPHandler instance;
    
    public static OTPHandler getInstance() {
        if (instance == null) {
            instance = new OTPHandler();
        }
        return instance;
    }
    public static void generateAndSendOTP(String reqInput) {
        Map<String, Object> returnValue = new Map<String, Object>();
        try {
            Map<String, Object> jsonData = (Map<String, Object>) JSON.deserializeUntyped(
                reqInput
            );
            
            String email = (String) jsonData.get('email');
            String contactId = (String) jsonData.get('contactId');
            String phoneNumber = (String) jsonData.get('phoneNumber');
            String commType = (String) jsonData.get('commType');
            String processType = (String) jsonData.get('processType');
            String transactionId = (String) jsonData.get('transactionId');
            String customerKey = (String) jsonData.get('customerKey');    
            /**
            * Check required parameters 
            * */
            if (String.isBlank(transactionId)) {
                throw new CustomException(Label.MissingRequiredParameterTransactionId);
            } else if (String.isBlank(processType)) {
                throw new CustomException(Label.MissingRequiredParameterProcessType);
            }
            
            OTPService objOTPService = OTPService.getInstance();
            CustomUserService objCustomUserService = CustomUserService.getInstance();
            
            /***
            * Process Type identifies the process for which the OTP is being generated.
            * Example: OTP generation for Email verification during the 'registration' process
            * Or OTP generation for Track my application process
            */
            switch on processType{ 
                when 'Registration' {
                    /**
                    * Check required parameters 
                    * */
                    if (String.isBlank(email)) {
                        throw new CustomException(Label.MissingRequiredParameterEmail);
                    } else if (String.isBlank(commType)) {
                        throw new CustomException(label.MissingRequiredParameterCommType);
                    }
                    
                    /**
                    * Create OTP record 
                    * */
                    Integer otpLength = Integer.valueOf(Label.OTPLength);
                    Integer otpExpirationMinutes = Integer.valueOf(Label.OTPExpirationMinutes);
                    String randomOtp = objOTPService.generateOTP(otpLength);
                    OTP__c otpData = new OTP__c();
                    otpData.Email__c = email;
                    otpData.TransactionId__c = transactionId;
                    otpData.OTPCode__c = randomOtp;
                    otpData.OTPCodeExpiration__c = DateTime.now().addMinutes(otpExpirationMinutes);
                    otpData.CommunicationType__c = commType;
                    otpData.ProcessType__c	= processType;
                    OTP__c insertedOTPRecord = objOTPService.createOTPRecord(otpData);
                    Id insertedOTPId = insertedOTPRecord.Id;
                    
                    /**
                    * Add Send Email logic here
                    */
                    
                    // Load the Classic Email Template
                    EmailTemplate template = EmailService.getInstance().getEmailTemplateByDevName('EmailVerificationOTP');
                    
                    // Query Org-Wide Email Address
                    String orgWideEmail = MetadataService.getInstance().getAppSettingTextValue('BAPPOrgWideEmailAddress');
                    
                    List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
                    if(template!=null) {
                        String htmlBody = template.HtmlValue;
                        
                        // Replace merge fields
                        htmlBody = htmlBody
                            .replace('{!OTP__c.OTPCode__c}', randomOtp != null ? randomOtp : '')
                            .replace('{!$Label.OTPExpirationMinutes}', Label.OTPExpirationMinutes);
                        
                        Messaging.SingleEmailMessage agreementEmail = new Messaging.SingleEmailMessage();
                        if (orgWideEmail!=null) {
                            agreementEmail.setOrgWideEmailAddressId(orgWideEmail);
                        }
                        agreementEmail.setToAddresses(new String[] { email });
                        agreementEmail.setSubject(template.subject);
                        agreementEmail.setHtmlBody(htmlBody);
                        emails.add(agreementEmail);
                        
                    }
                    
                    if (!emails.isEmpty()) {
                        Messaging.sendEmail(emails);
                    }
                    
                    Map<String, String> response = new Map<String, String> {
                        'transactionId' => transactionId,
                            'message' => Label.OTPSentSuccessfully,
                            'status' => 'success',
                            'isSuspended' => ''
                            };
                                makeSuccessResponse(response);
                }
                when 'Track My Application' {
                    /**
                    * Check required parameters 
                    * */
                    if (String.isBlank(commType)) {
                        throw new CustomException(Label.MissingRequiredParameterCommType);
                    }
                    if (String.isBlank(customerKey)) {
                        throw new CustomException(Label.MissingRequiredParameterCustomerKey);
                    }
                    BrokerApplicationService objBrokerApplicationService = BrokerApplicationService.getInstance();
                    BrokerApplication__c matchingBrokerApplication = objBrokerApplicationService.getBrokerApplicationByNumber(customerKey);
                    if(matchingBrokerApplication==null) {
                        //throw new CustomException('Invalid Application Number, no matching records found!');');
                        Map<String, String> errorResponse = new Map<String, String> { 'transactionId' => transactionId, 'message' => Label.BAAP_InvalidApplicationNumber, 'status' => 'fail'};
                            makeErrorResponse(errorResponse);
                        return; 
                    }
                    
                    /**
                    * Create OTP record 
                    * */
                    if(matchingBrokerApplication!=null) {
                        Integer otpLength = Integer.valueOf(Label.OTPLength);
                        Integer otpExpirationMinutes = Integer.valueOf(Label.OTPExpirationMinutes);
                        String randomOtp = objOTPService.generateOTP(otpLength);
                        OTP__c otpData = new OTP__c();
                        otpData.Email__c = matchingBrokerApplication.AgencyEmail__c;
                        otpData.PhoneNumber__c = matchingBrokerApplication.CompanyPhone_Number__c;
                        otpData.TransactionId__c = transactionId;
                        otpData.OTPCode__c = randomOtp;
                        otpData.OTPCodeExpiration__c = DateTime.now().addMinutes(otpExpirationMinutes);
                        otpData.CommunicationType__c = commType;
                        otpData.ProcessType__c	= processType;
                        otpData.CustomerKey__c = customerKey;
                        OTP__c insertedOTPRecord = objOTPService.createOTPRecord(otpData);
                        Id insertedOTPId = insertedOTPRecord.Id;
                        
                        if(commType.contains('Email') && matchingBrokerApplication.AgencyEmail__c!=null) {
                            /**
                            * Add Send Email logic here
                            */
                            
                            // Load the Classic Email Template
                            EmailTemplate template = EmailService.getInstance().getEmailTemplateByDevName('TrackMyApplicationOTP');
                            
                            // Query Org-Wide Email Address
                            String orgWideEmail = MetadataService.getInstance().getAppSettingTextValue('BAPPOrgWideEmailAddress');
                            
                            List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
                            if(template!=null && matchingBrokerApplication!=null) {
                                String htmlBody = template.HtmlValue;
                                
                                // Replace merge fields
                                htmlBody = htmlBody
                                    .replace('{!OTP__c.OTPCode__c}', randomOtp != null ? randomOtp : '')
                                    .replace('{!$Label.OTPExpirationMinutes}', Label.OTPExpirationMinutes);
                                
                                String toEmail;
                                if(matchingBrokerApplication.AgencyEmail__c !=null) {
                                    toEmail = matchingBrokerApplication.AgencyEmail__c;
                                    
                                    Messaging.SingleEmailMessage agreementEmail = new Messaging.SingleEmailMessage();
                                    if (orgWideEmail!=null) {
                                        agreementEmail.setOrgWideEmailAddressId(orgWideEmail);
                                    }
                                    agreementEmail.setToAddresses(new String[] { toEmail });
                                    agreementEmail.setSubject(template.subject);
                                    agreementEmail.setHtmlBody(htmlBody);
                                    emails.add(agreementEmail);
                                    
                                }    
                            }
                            
                            if (!emails.isEmpty()) {
                                Messaging.sendEmail(emails);
                            }
                        }
                        if(commType.contains('SMS') && matchingBrokerApplication.CompanyPhone_Number__c!=null) {
                            /**
                            * Add Send SMS notification logic here
                            */
                        }
                        
                        Map<String, String> response = new Map<String, String> {
                            'transactionId' => transactionId,
                                'message' => Label.OTPSentSuccessfully,
                                'status' => 'success',
                                'isSuspended' => ''
                                };
                                    makeSuccessResponse(response);
                    }
                }
                when 'Forgot Password' {
                    /**
                    * Check required parameters 
                    * */
                    if (String.isBlank(commType)) {
                        throw new CustomException(Label.MissingRequiredParameterCommType);
                    }
                    if (String.isBlank(contactId) && String.isBlank(email)) {
                        throw new CustomException(Label.MissingRequiredParameterContactIdorEmail);
                    } 
                    
                    String message='';
                    User__c userByContactIdOrEmailId;
                    if ((String.isNotBlank(contactId) || String.isNotBlank(email) )) {
                        userByContactIdOrEmailId = objCustomUserService.getUserByContactIdOrEmail(contactId, email);
                        
                        if (userByContactIdOrEmailId == null) {
                            throw new CustomException(Label.UserNotFoundwithContactIdorEmail);
                        }
                        /***
                        * Check if User is Inactive
                        */
                        if (!userByContactIdOrEmailId.Is_Azure_Active__c && !userByContactIdOrEmailId.Contact__r.IsSuspended__c && !userByContactIdOrEmailId.Contact__r.Blacklisted__c) {
                            message =Label.UserIsNotActive;
                            Map<String, String> errorResponse = new Map<String, String> { 
                                'transactionId' => transactionId, 
                                    'message' => message, 
                                    'status' => 'fail',
                                    'isTerminated' =>  String.valueOf(userByContactIdOrEmailId.Contact__r.Blacklisted__c),
                                    'isAzureActive' => String.valueOf(userByContactIdOrEmailId.Is_Azure_Active__c)
                                    };
                                        makeErrorResponse(errorResponse);
                            return; 
                        }
                        /***
                        * Check if User is Terminated
                        */
                        
                        if (!userByContactIdOrEmailId.Is_Azure_Active__c && userByContactIdOrEmailId.Contact__r.Blacklisted__c) {
                            message =Label.UserIsTerminated;
                            Map<String, String> errorResponse = new Map<String, String> { 
                                'transactionId' => transactionId, 
                                    'message' => message, 
                                    'status' => 'fail',
                                    'isTerminated' =>  String.valueOf(userByContactIdOrEmailId.Contact__r.Blacklisted__c),
                                    'isAzureActive' => String.valueOf(userByContactIdOrEmailId.Is_Azure_Active__c)
                                    };
                                        makeErrorResponse(errorResponse);
                            return;
                        }
                        
                        
                    }
                    
                    /**
                    * Create OTP record for Active Users Forgot Password
                    * */
                    Integer otpLength = Integer.valueOf(Label.OTPLength);
                    Integer otpExpirationMinutes = Integer.valueOf(Label.OTPExpirationMinutes);
                    String randomOtp = objOTPService.generateOTP(otpLength);
                    OTP__c otpData = new OTP__c();
                    otpData.Email__c = userByContactIdOrEmailId.Email__c;
                    otpData.PhoneNumber__c = userByContactIdOrEmailId.Mobile_Number__c;
                    otpData.TransactionId__c = transactionId;
                    otpData.OTPCode__c = randomOtp;
                    otpData.OTPCodeExpiration__c = DateTime.now().addMinutes(otpExpirationMinutes);
                    otpData.CommunicationType__c = commType;
                    otpData.ProcessType__c	= processType;
                    otpData.Account__c = userByContactIdOrEmailId.Account__c;
                    otpData.Contact__c = userByContactIdOrEmailId.Contact__c;
                    otpData.Verified__c = false;
                    OTP__c insertedOTPRecord = objOTPService.createOTPRecord(otpData);
                    Id insertedOTPId = insertedOTPRecord.Id;
                    
                    if(commType.contains('Email')) {
                        /**
                        * Add Send Email logic here
                        */
                        // Load the Classic Email Template
                        EmailTemplate template = EmailService.getInstance().getEmailTemplateByDevName('ForgotPasswordOTP');
                        
                        // Query Org-Wide Email Address
                        String orgWideEmail = MetadataService.getInstance().getAppSettingTextValue('BAPPOrgWideEmailAddress');
                        
                        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
                        if(template!=null && userByContactIdOrEmailId!=null) {
                            String htmlBody = template.HtmlValue;
                            
                            // Replace merge fields
                            htmlBody = htmlBody
                                .replace('{!Contact.Name}', userByContactIdOrEmailId.Contact__r.Name != null ? userByContactIdOrEmailId.Contact__r.Name : '')
                                .replace('{!OTP__c.OTPCode__c}', randomOtp != null ? randomOtp : '')
                                .replace('{!$Label.OTPExpirationMinutes}', Label.OTPExpirationMinutes);
                            
                            String toEmail;
                            if(userByContactIdOrEmailId.Contact__r.Email !=null) {
                                toEmail = userByContactIdOrEmailId.Contact__r.Email;
                                
                                Messaging.SingleEmailMessage agreementEmail = new Messaging.SingleEmailMessage();
                                if (orgWideEmail!=null) {
                                    agreementEmail.setOrgWideEmailAddressId(orgWideEmail);
                                }
                                agreementEmail.setToAddresses(new String[] { toEmail });
                                agreementEmail.setSubject(template.subject);
                                agreementEmail.setHtmlBody(htmlBody);
                                emails.add(agreementEmail);
                                
                            }    
                        }
                        
                        if (!emails.isEmpty()) {
                            Messaging.sendEmail(emails);
                        }
                    }
                    if(commType.contains('SMS')) {
                        /**
                        * Add Send SMS notification logic here
                        */
                    }
                    if(commType.contains('WhatsApp')) {
                        /**
                        * Add Send WhatsApp SMS notification logic here
                        */
                    }    
                    
                    Map<String, String> response = new Map<String, String> {
                        'transactionId' => transactionId,
                            'message' => Label.OTPSentSuccessfully,
                            'status' => 'success',
                            'isSuspended' => String.valueOf(userByContactIdOrEmailId.Contact__r.IsSuspended__c)
                            };
                                makeSuccessResponse(response);
                }
            }
        } catch (Exception e) {
            returnValue.put('errorMessage', e.getMessage());
            makeServerErrorResponse(returnValue);    
        }
    }
    public static void verifyOTP(String reqInput) {
        Map<String, Object> returnValue = new Map<String, Object>();
        String successResponseMessage ='';
        String successStatus='';
        String errorResponseMessage ='';
        String errorStatus='';
        try {
            Map<String, Object> jsonData = (Map<String, Object>) JSON.deserializeUntyped(
                reqInput
            );
            OTPService objOTPService = OTPService.getInstance();
            
            /**Request parameters from Front-end 
            * @param otpValue The OTP entered by the user
            * @param transactionId Unique identifier for the request 
            * @param customerKey applicable in case of process type as Track My Application 
            */
            String enteredOTP = (String) jsonData.get('otpValue');
            String transactionId = (String) jsonData.get('transactionId');
            String customerKey = (String) jsonData.get('customerKey');
            
            /**
            * Check required parameters 
            * */
            if (String.isBlank(enteredOTP)) {
                throw new CustomException(Label.MissingRequiredParameterOTP);
            } else if (String.isBlank(transactionId)) {
                throw new CustomException(Label.MissingRequiredParameterTransactionId);
            }
            
            /**
            * Get OTP records 
            * */
            
            List<OTP__c> otpRecords = objOTPService.getOTPRecords(transactionId);
            
            /**Check if there are no matching OTP records */
            if (otpRecords.isEmpty()) {
                /**Create Error Response structure */
                Map<String, String> errorResponse = new Map<String, String> { 'transactionId' => transactionId, 'message' => Label.OTPNotFound, 'status' => 'fail'};
                    makeErrorResponse(errorResponse);
                return;
            }
            OTP__c otpRecord = otpRecords[0];

            //Send bad request error response for Process types other than 'Track My Application' 
            if(otpRecord.ProcessType__c != 'Track My Application' && String.isNotBlank(customerKey)) {
                Map<String, String> errorResponse = new Map<String, String> { 'transactionId' => transactionId, 'message' => 'Bad Request', 'status' => 'fail'};
                    makeErrorResponse(errorResponse);
                return;       
            } 

            /**
            * Check required parameters customerKey for track my application
            * */
            if(otpRecord.ProcessType__c == 'Track My Application' && String.isBlank(customerKey)) {
                throw new CustomException(Label.MissingRequiredParameterCustomerKey);    
            }
            
            /** Check if the OTP is already verified */
            if (otpRecord.Verified__c) {
                Map<String, String> errorResponse = new Map<String, String> { 'transactionId' => transactionId, 'message' => Label.OTPAlreadyVerified, 'status' => 'fail'};
                    makeErrorResponse(errorResponse);
                return;
            }
            
            /**Check if OTP is expired or valid */
            if (DateTime.now() > otpRecord.OTPCodeExpiration__c) {
                
                /**Create Error Response structure */
                Map<String, String> errorResponse = new Map<String, String> { 'transactionId' => transactionId, 'message' => Label.OTPExpired, 'status' => 'fail'};
                    makeErrorResponse(errorResponse);
                return;
            }
            
            /**Check if OTP entered does not matches with the OTP on record */
            if (otpRecord.OTPCode__c != enteredOTP) {
                
                /**Create Error Response structure */
                Map<String, String> errorResponse = new Map<String, String> { 'transactionId' => transactionId, 'message' => Label.InvalidOTP, 'status' => 'fail'};
                    makeErrorResponse(errorResponse);
                return; 
            }

            /**Check if the CustomerKey has value */
            if(String.isNotBlank(customerKey) && String.isNotBlank(otpRecord.CustomerKey__c)) {
                if((otpRecord.OTPCode__c == enteredOTP && otpRecord.CustomerKey__c == customerKey ) && (errorResponseMessage == '' && errorStatus== '')) {
                
                    /**Create Success Response structure */
                    Map<String, String> successResponse = new Map<String, String> {'transactionId' => transactionId, 'message' => Label.OTPVerifiedSuccessfully, 'status' => 'success'};
                        makeSuccessResponse(successResponse);
                    
                    OTP__c otpToUpdate = new OTP__c();
                    otpToUpdate.Id = otpRecord.Id;
                    otpToUpdate.Verified__c = true;
                    OTP__c updatedOTPRecord = objOTPService.updateOTP(otpToUpdate);
                    Id updatedOTPId = updatedOTPRecord.Id;
                } else {
                    /**Create Error Response structure */
                    Map<String, String> errorResponse = new Map<String, String> { 'transactionId' => transactionId, 'message' => Label.InvalidOTP, 'status' => 'fail'};
                    makeErrorResponse(errorResponse);
                    return;   
                } 
            } 
            
            if (String.isBlank(customerKey) && String.isBlank(otpRecord.CustomerKey__c) && otpRecord.ProcessType__c!='Track My Application'){
                if(otpRecord.OTPCode__c == enteredOTP && (errorResponseMessage == '' && errorStatus== '')) {
                
                    if(otpRecord.ProcessType__c=='Forgot Password'){
                        String userOID = '';
                        CustomUserService objCustomUserService = CustomUserService.getInstance();
                        User__c userByContactIdOrEmailId = objCustomUserService.getUserByContactIdOrEmail(otpRecord.Contact__c, '');
                        if(userByContactIdOrEmailId!=null) {
                            userOID = userByContactIdOrEmailId.Azure_UserId__c;        
                        }
                        /**Create Success Response structure */
                        Map<String, String> successResponse = new Map<String, String> {'transactionId' => transactionId, 'message' => Label.OTPVerifiedSuccessfully, 'status' => 'success', 'OID' => userOID};
                            makeSuccessResponse(successResponse);
                        
                        OTP__c otpToUpdate = new OTP__c();
                        otpToUpdate.Id = otpRecord.Id;
                        otpToUpdate.Verified__c = true;
                        OTP__c updatedOTPRecord = objOTPService.updateOTP(otpToUpdate);
                        Id updatedOTPId = updatedOTPRecord.Id;
                    }
                    else {
                        /**Create Success Response structure */
                        Map<String, String> successResponse = new Map<String, String> {'transactionId' => transactionId, 'message' => Label.OTPVerifiedSuccessfully, 'status' => 'success'};
                            makeSuccessResponse(successResponse);
                        
                        OTP__c otpToUpdate = new OTP__c();
                        otpToUpdate.Id = otpRecord.Id;
                        otpToUpdate.Verified__c = true;
                        OTP__c updatedOTPRecord = objOTPService.updateOTP(otpToUpdate);
                        Id updatedOTPId = updatedOTPRecord.Id;
                    }
                }        
            }             
            
            
        } catch (Exception e) {
            returnValue.put('errorMessage', e.getMessage());
            makeServerErrorResponse(returnValue);    
        }
    }
    //Success Response
    public static void makeSuccessResponse(Map<String, Object> response) { // String
        RestContext.response.addHeader('Content-Type', 'application/json;charset=UTF-8');
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(response));
        RestContext.response.statusCode = 200;
    }
    // Server Error Response
    public static void makeServerErrorResponse(Map<String, Object> error) {
        error.put('status', 'error');
        error.put('message', 'Server Error');
        RestContext.response.addHeader('Content-Type', 'application/json;charset=UTF-8');
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(error));
        RestContext.response.statusCode = 500;
    }
    //Error Response
    public static void makeErrorResponse(Map<String, Object> error) {
        RestContext.response.addHeader('Content-Type', 'application/json;charset=UTF-8');
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(error));
        RestContext.response.statusCode = 400;
    }
    public class CustomException extends Exception {}
    
    public OTP__c generateSuperAppOTP(String processType, String email, String mobile, String commType, String parentId){
        OTPService objOTPService = OTPService.getInstance();
        MetadataService objMetadataService = MetadataService.getInstance();
        OTP__c objOTP = new OTP__c();
        Integer otpLength = objMetadataService.getAppSettingNumberValue(MTD_OWE_OTP_LENGTH);
        Integer otpExpirationMinutes = objMetadataService.getAppSettingNumberValue(MTD_OWE_OTP_EXPIRATION_MINUTES);
        String otp = objOTPService.generateOTP(otpLength);
        objOTP = objOTPService.getOTP(processType, email, mobile, otp, otpExpirationMinutes, commType, parentId);
        objOTP = objOTPService.insertOTP(objOTP);
        return objOTP;
    }
    
    public Boolean verifySuperAppOTP(String parentId, string otp, String transactionId){
        OTPService objOTPService = OTPService.getInstance();
        OTP__c objOTP = objOTPService.getOTPById(transactionId);
        Boolean isValid = false;
        if(!objOTP.Verified__c && objOTP.OTPCode__c  == otp && String.isBlank(parentId) && objOTP.OTPCodeExpiration__c >= DateTime.now()){
            isValid = true;
        }else if(!objOTP.Verified__c && objOTP.OTPCode__c  == otp && objOTP.ParentId__c  == parentId && String.isNotBlank(parentId) && objOTP.OTPCodeExpiration__c >= DateTime.now()){
            isValid = true;
        }
        if(isValid){
            objOTP.Verified__c = true;
            objOTPService.updateOTP(objOTP);
        }
        return isValid;
    }
}