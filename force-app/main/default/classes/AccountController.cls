/*****************************************************************************************
Class       : AccountController
Author      : Jay
Description : Account Controller class
Test class  : AccountControllerTest
Created Date: 29 AUG 2024
------------------------------------------------------------------------------------------
-- History --
------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.          V1.0             29AUG2024           Initial Version 
*****************************************************************************************/
public without sharing class AccountController {
    
    private static final string ACCOUNT_RT_DEV_NAME_PERSON_ACCOUNT { get { return 'PersonAccount'; } }
    private static final string ACCOUNT_RT_DEV_NAME_ORGANIZATION_ACCOUNT { get { return 'OrganizationAccount'; } }
    private static final string ACCOUNT_RT_DEV_NAME_BROKER_ACCOUNT { get { return 'Broker_Agency'; } }
    
    @AuraEnabled
    public static List<Account> getIndividualAccount(String email, String countryCode, String phoneNumber, String eid, String passportNumber, String nationality) {
        Id personAccountRecordTypeId = Utility.getRecordTypeIdByDevName(Account.SObjectType, ACCOUNT_RT_DEV_NAME_PERSON_ACCOUNT);
        List<Account> accList = new List<Account>();
        if(String.isNotBlank(eid)){
            eid = Utility.formatEmiratesId(eid);
            accList = [SELECT Id, Name, NameinArabic__c FROM Account WHERE Emirates_Id__pc = :eid AND RecordTypeId = :personAccountRecordTypeId];
        }else if(String.isNotBlank(email)){
            accList = [SELECT Id, Name, NameinArabic__c FROM Account WHERE PersonEmail = :email AND RecordTypeId = :personAccountRecordTypeId];
        }else if(String.isNotBlank(phoneNumber) && String.isNotBlank(countryCode)){
            accList = [SELECT Id, Name, NameinArabic__c FROM Account WHERE MobileCountryCode__c = :countryCode AND PersonMobilePhone = :phoneNumber AND RecordTypeId = :personAccountRecordTypeId];
        }else if(String.isNotBlank(nationality) && String.isNotBlank(passportNumber) ){
            accList = [SELECT Id, Name, NameinArabic__c FROM Account WHERE Nationality__c = :nationality AND PassportNumber__pc = :passportNumber AND RecordTypeId = :personAccountRecordTypeId];
        }
        return accList;
    }
    
    @AuraEnabled
    public static List<Account> getOrganizationAccount(String registrationAuthority, String tradeLicenseNumber) {
        Id organizationAccountRecordTypeId = Utility.getRecordTypeIdByDevName(Account.SObjectType, ACCOUNT_RT_DEV_NAME_ORGANIZATION_ACCOUNT);
        List<Account> accList = new List<Account>();
        accList = [SELECT Id, Name, NameinArabic__c FROM Account 
                   WHERE Trade_License_No__c = :tradeLicenseNumber
                   AND Registration_Authority__c = :registrationAuthority 
                   AND RecordTypeId = :organizationAccountRecordTypeId];
        return accList;
    }
    
    @AuraEnabled
    public static Map<String,String> getNationality(){
        return Utility.getPicklistValues(Account.SObjectType, 'Nationality__c');
    }
    
    @AuraEnabled
    public static Map<String,String> getMobileCountryCode(){
        return Utility.getPicklistValues(Contact.SObjectType, 'MobileCountryCode__c');
    }
    
    @AuraEnabled
    public static Map<String,String> getRegistrationAuthority(){
        return Utility.getPicklistValues(Lead.SObjectType, 'RegistrationAuthority__c');
    }
    
    @AuraEnabled
    public static Id getBrokerAccountRecordTypeId(){
        return Utility.getRecordTypeIdByDevName(Account.SObjectType, ACCOUNT_RT_DEV_NAME_BROKER_ACCOUNT);
    }
}