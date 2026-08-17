/*
* @Author: Shruti Kulkarni
* @CreatedDate: 28th May 2025
* @Description: Class created to build and utilize the generic methods needed for any OTP generation/verification functionality
*/
/*****************************************************************************************************
* Version       Author      	   Date             Comment                                                                       
* 1.1           Shruti Kulkarni    28th MAY 2025    Initial Draft
*****************************************************************************************************/
public class OTPService {
    
    private static final String MTD_OWE_SUPER_APP_EMAIL_TEMPLATE_ID { get { return 'SuperAppOTPEmailTemplateId'; } }
    private static final String MTD_OWE_SUPER_APP_ORG_WIDE_EMAIL_ADDRESS_ID { get { return 'SuperAppOrgWideEmailAddressId'; } }

    private OTPService() {

    }
    private static OTPService instance;

    public static OTPService getInstance() {
        if (instance == null) {
            instance = new OTPService();
        }
        return instance;
    }

    /**
     * Generate OTP with the length specified 
     * @param length The length of the OTP to be generated.
     * @return The newly generated OTP.
     */
    public String generateOTP(Integer length) {
        if (length == null || length == 0) {
            length = 6;
        }
        String otpValue = '';
        for (Integer i = 0; i < length; i++) {
            Integer randomInt = Math.abs(Math.mod(Crypto.getRandomInteger(), 10));
            otpValue += String.valueOf(randomInt);
        }
        return otpValue;
    }

    /**
     * Creates an OTP record.
     * @param otpData The OTP object to insert.
     * @return The Id of the newly created OTP record.
     */
    public OTP__c createOTPRecord(OTP__c otpData) {
        if (otpData == null) {
            throw new AuraHandledException('Null or Blank Data');
        }

        insert otpData;
        return otpData;
    }

    /**
     * Updates an OTP record.
     * @param objOTP The OTP object to be updated.
     * @return The Id of the updated OTP record.
     */
    public OTP__c updateOTP(OTP__c objOTP) {
        return updateOTPs(new List<OTP__c>{objOTP})[0];
    }

    /**
     * Get OTP records based on Transaction Id.
     * @param transactionId The transaction Id for querying OTP records.
     * @return The list of the matching OTP records.
     */
    public List<OTP__c> getOTPRecords(String transactionId) {
        List<OTP__c> listOTPRecords;
        if (transactionId == '') {
            throw new AuraHandledException('Transaction Id is mandatory');
        } else {
            listOTPRecords = [SELECT  Id
                            , OTPCode__c
                            , OTPCodeExpiration__c
                            , Verified__c
                            , CustomerKey__c
                            , ProcessType__c
                            , Contact__c
                              FROM OTP__c 
                              WHERE TransactionId__c = :transactionId
                              ORDER BY CreatedDate DESC
                              LIMIT 1];
        }
        return listOTPRecords;
    }
    
    public OTP__c insertOTP(OTP__c objOTP){
        if(objOTP != NULL ){
            objOTP = insertOTPs(new List<OTP__c>{objOTP})[0];
        }
        return objOTP;
    }
    
    public List<OTP__c> insertOTPs(List<OTP__c> otpList){
        if(otpList != NULL && !otpList.isEmpty()){
            insert otpList;
        }
        return otpList;
    }
    
    public List<OTP__c> updateOTPs(List<OTP__c> otpList){
        if(otpList != NULL && !otpList.isEmpty()){
            update otpList;
        }
        return otpList;
    }
    
    public OTP__c getOTP(String processType, String email, String mobile, String otp, integer otpExpirationMinutes, String commType, String parentId) {
        OTP__c objOTP = new OTP__c();
        objOTP.Email__c = email;
        objOTP.PhoneNumber__c = mobile;
        objOTP.OTPCode__c = otp;
        objOTP.OTPCodeExpiration__c = DateTime.now().addMinutes(otpExpirationMinutes);
        objOTP.CommunicationType__c = commType;
        objOTP.ProcessType__c = processType;
        objOTP.ParentId__c = parentId;
        return objOTP;
    }
    
    public OTP__c getOTPById(Id recordId) {
        return [SELECT  Id, OTPCode__c, OTPCodeExpiration__c, Verified__c, CustomerKey__c, ProcessType__c, Contact__c, ParentId__c
                FROM OTP__c WHERE Id = :recordId ORDER BY CreatedDate DESC LIMIT 1];
    }

    public List<OTP__c> getVerifiedOTP(String processType, String customerId, Set<String> txnId){
        return [SELECT Id, Verified__c, Contact__c,CommunicationType__c,TransactionId__c, Email__c, PhoneNumber__c FROM OTP__c WHERE Verified__c = true AND ProcessType__c =: processType AND  Id IN :txnId AND CreatedDate = TODAY];
    }
    
    
    public void sendSuperAppOTPEmail(List<OTP__c> otpList){
        if(!otpList.isEmpty() && otpList != NULL){
            MetadataService objMetadataService = MetadataService.getInstance();
            EmailService objEmailService = EmailService.getInstance();
            List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
            
            Id superAppOWEId = objMetadataService.getAppSettingTextValue(MTD_OWE_SUPER_APP_ORG_WIDE_EMAIL_ADDRESS_ID);
            Id superAppOTPEmailTemplateId = objMetadataService.getAppSettingTextValue(MTD_OWE_SUPER_APP_EMAIL_TEMPLATE_ID);
            
            for(OTP__c objOTP :otpList){
                if(String.isNotBlank(objOTP.Email__c)){
                    Messaging.SingleEmailMessage objMail = objEmailService.getSingleEmailMessageWithoutTargetObjectId(superAppOTPEmailTemplateId, null, objOTP.Id, new List<String>{objOTP.Email__c}, null, null);
                    emailList.add(objMail); 
                }
            }
            objEmailService.sendEmail(emailList);
        }
    }
    
    public void sendSuperAppOTPSMS(List<OTP__c> otpList){
        if(otpList != NULL && !otpList.isEmpty()){
            System.enqueueJob(new SMSHandler(SMSHandler.getSuperAppOTPSMS(otpList)));
        }
    }
}