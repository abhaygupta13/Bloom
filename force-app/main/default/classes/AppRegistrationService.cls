/***
Class       : AppRegistrationService
Author      : Biswajeet
Description : 
TestClass   : AppRegistrationServiceTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.          V1.0              25/08/23           Initial Version 
1.1		    V1.1			  29/04/25		    Added new method for evaluate SAP Integration Fields
****************************************************************************************************************/
public class AppRegistrationService {
    
    private static final String SUPER_APP_UNDER_REVIEW_EMAIL_TEMPLATE_ID { get { return 'SuperAppUnderReviewEmailTemplateId'; } }
    private static final String SUPER_APP_REJECTION_EMAIL_TEMPLATE_ID { get { return 'SuperAppRejectionEmailTemplateId'; } }
    private static final string BLOOM_NO_REPLY_SALES_OW_EMAIL_ID { get { return 'BloomNoReplySalesOWEmailId'; } }

    private static AppRegistrationService instance;
    
    private AppRegistrationService() {
        
    }
    
    public static AppRegistrationService getInstance() { 
        if(instance == null) {
            instance = new AppRegistrationService();
        }
        return instance;
    }
    
    public AppRegistration__c getAppRegistration(string customerId, string firstName, string middleName, 
                                                 string lastName, string emiratesId, string passportNumber,
                                                 String nationality, string phoneCountryCode, string mobileNumber,
                                                 string email, String deviceId, String registrationType){
                                                     AppRegistration__c objAppRegistration = new AppRegistration__c();
                                                     objAppRegistration.FirstName__c = firstName;
                                                     objAppRegistration.MiddleName__c = middleName;
                                                     objAppRegistration.LastName__c = lastName;
                                                     objAppRegistration.EmiratesID__c = emiratesId;
                                                     objAppRegistration.PassportNumber__c = passportNumber;
                                                     objAppRegistration.Nationality__c = nationality;
                                                     objAppRegistration.MobileCountryCode__c = phoneCountryCode;
                                                     objAppRegistration.MobilePhone__c = mobileNumber;
                                                     objAppRegistration.Email__c = email;
                                                     objAppRegistration.DeviceId__c = deviceId;
                                                     objAppRegistration.RegistrationType__c = registrationType;
                                                     if(String.isNotBlank(customerId)){
                                                         objAppRegistration.Contact__c = customerId;
                                                     }
                                                     return objAppRegistration;
                                                 }
    
    public List<AppRegistration__c> getExistingAppRegistration(string emiratesId, string passportNumber, String nationality){
        List<AppRegistration__c> objAppRegistrationList = new List<AppRegistration__c>();
        if(string.isNotBlank(emiratesId)){
            objAppRegistrationList = [SELECT Id, Status__c, Name, RegistrationType__c, DeviceId__c, LastModifiedDate 
                                      FROM AppRegistration__c WHERE EmiratesID__c = :emiratesId];
        }
        if(string.isNotBlank(passportNumber) && string.isNotBlank(nationality) && objAppRegistrationList.isEmpty()){
            objAppRegistrationList = [SELECT Id, Status__c, Name, RegistrationType__c, DeviceId__c, LastModifiedDate 
                                      FROM AppRegistration__c WHERE Nationality__c = :nationality
                                      AND PassportNumber__c = :passportNumber];
        }
        return objAppRegistrationList;
    }
    
    //Update App Registrations
    public List<AppRegistration__c> updateAppRegistrations(List<AppRegistration__c> appRegistrationList){
        if(appRegistrationList != NULL && !appRegistrationList.isEmpty()){
            update appRegistrationList;
        }
        return appRegistrationList;
    }
    
    //Update App Registration
    public AppRegistration__c updateAppRegistration(AppRegistration__c appRegistration){
        return updateAppRegistrations(new List<AppRegistration__c>{appRegistration})[0];
    }
    
    //Insert App Registrations
    public List<AppRegistration__c> insertAppRegistrations(List<AppRegistration__c> appRegistrationList){
        if(appRegistrationList != NULL && !appRegistrationList.isEmpty()){
            insert appRegistrationList;
        }
        return appRegistrationList; 
    }
    
    //Insert App Registration
    public AppRegistration__c insertAppRegistration(AppRegistration__c appRegistration){
        return insertAppRegistrations(new List<AppRegistration__c>{appRegistration})[0];
    }
    
    public List<AppRegistration__c> getAppRegistrationById(Id recordId){
        return [SELECT Id, Status__c,MobilePhone__c,MobileCountryCode__c, Name, Email__c, Contact__r.IsPrimaryEmailVerified__c, Contact__r.IsPrimaryMobileVerified__c, Contact__r.Account.Owner__c, Contact__r.Account.Tenant__c, Contact__c, RegistrationType__c, DeviceId__c, LastModifiedDate FROM AppRegistration__c WHERE Id = :recordId];
    }
    
    public List<AppRegistration__c> getAppRegistrationByContactId(Id contactId){
        return [SELECT Id, Status__c, Name,Email__c,MobilePhone__c, Contact__r.Account.Owner__c, Contact__r.Account.Tenant__c, Contact__c, DeviceId__c, RegistrationType__c, LastModifiedDate FROM AppRegistration__c WHERE Contact__c = :contactId LIMIT 1];
    }

    public void sendBloomAppEmail(List<AppRegistration__c> appRegistrationsList){
        if(appRegistrationsList != NULL && !appRegistrationsList.isEmpty()){
            MetadataService objMetadataService = MetadataService.getInstance();
            EmailService objEmailService = EmailService.getInstance();
            List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
            
            Id superAppUnderReviewEmailTemplateId = objMetadataService.getAppSettingTextValue(SUPER_APP_UNDER_REVIEW_EMAIL_TEMPLATE_ID);
            Id SuperAppRejectionEmailTemplateId = objMetadataService.getAppSettingTextValue(SUPER_APP_REJECTION_EMAIL_TEMPLATE_ID);
            Id noReplyBloomSalesOWDId = objMetadataService.getAppSettingTextValue(BLOOM_NO_REPLY_SALES_OW_EMAIL_ID);
            
            for(AppRegistration__c objAppRegistration :appRegistrationsList){
                if(objAppRegistration.Status__c == 'Under Review' && objAppRegistration.Contact__c != NULL){
                    Messaging.SingleEmailMessage objMail = objEmailService.getSingleEmailMessageWithTargetObjectAsRecipient(superAppUnderReviewEmailTemplateId, noReplyBloomSalesOWDId, objAppRegistration.Id, objAppRegistration.Contact__c, null, null, null);
                    emailList.add(objMail); 
                }
                else if(objAppRegistration.Status__c == 'Rejected' && objAppRegistration.Contact__c != NULL){
                    Messaging.SingleEmailMessage objMail = objEmailService.getSingleEmailMessageWithTargetObjectAsRecipient(SuperAppRejectionEmailTemplateId, noReplyBloomSalesOWDId, objAppRegistration.Id, objAppRegistration.Contact__c, null, null, null);
                    emailList.add(objMail); 
                }
            }
            objEmailService.sendEmail(emailList);
        }
    }
}