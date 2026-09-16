/*****************************************************************************************
Class       : BrokerRegistrationExpiryBatch
Author      : Biswajeet
Description : Batch class to send broker registration expiry email notification
Test Class  : BrokerRegistrationExpiryBatchTest
Created Date: 29 AUG 2024
*****************************************************************************************/
public class BrokerRegistrationExpiryBatch implements Database.Batchable<sObject>, Schedulable{
    
    private static final string ACCOUNT_RT_DEV_NAME_BROKER_AGENCY { get { return 'Broker_Agency'; } }
    private static final string MTD_LEAD_NOTIFICATION_EMAIL_TEMPLATE_ID { get { return 'LeadCreatedEmailTemplateId'; } }
    private static final string MTD_BROKER_REG_EXPIRY_FIRST_NOTIFICATION_DAYS { get { return 'FirstNotificationDays'; } }
    private static final string MTD_BROKER_REG_EXPIRY_SECOND_NOTIFICATION_DAYS { get { return 'SecondNotificationDays'; } }
    
    private static final string MTD_BROKER_TRADE_LICENSE_EXPIRY_NOTIFICATION_EMAIL_TEMPLATE_ID { get { return 'BrokerTradeLicenseExpiryETId'; } }
    private static final string MTD_BROKER_AGREEMENT_EXPIRY_NOTIFICATION_EMAIL_TEMPLATE_ID { get { return 'BrokerAgreementExpiryETId'; } }
    private static final string MTD_BROKER_AGENT_RERA_CERTIFICATE_EXPIRY_NOTIFICATION_EMAIL_TEMPLATE_ID { get { return 'BrokerAgentRERAExpiryETId'; } }
    private static final string MTD_BROKER_COMMERCIAL_LICENSE_EXPIRY_NOTIFICATION_EMAIL_TEMPLATE_ID { get { return 'BrokerCommercialLicenseExpiryETId'; } }
    private static final string MTD_BAPP_BROKER_NO_REPLY_EMAIL_ID { get { return 'BAPPOrgWideEmailAddress'; } }
    private static final string MTD_BROKER_EXPIRY_REMINDER_BCC_EMAILS { get { return 'BrokerExpiryReminderBCCEmails'; } }
    private static final string BROKER_CONTACT_TYPE_AGENCY_ADMIN { get { return 'Agency Admin'; } }
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        MetadataService objMetadataService = MetadataService.getInstance();
        
        Id brokerAccountRecordTypeId = Utility.getRecordTypeIdByDevName(Account.SObjectType, ACCOUNT_RT_DEV_NAME_BROKER_AGENCY);         
        
        Integer firstNotificationDays = objMetadataService.getAppSettingNumberValue(MTD_BROKER_REG_EXPIRY_FIRST_NOTIFICATION_DAYS);
        Integer secondNotificationDays = objMetadataService.getAppSettingNumberValue(MTD_BROKER_REG_EXPIRY_SECOND_NOTIFICATION_DAYS);
        
        Date currentDate = System.today();
        Date firstNotificationDate = System.today().addDays(firstNotificationDays);
        Date secondNotificationDate = System.today().addDays(secondNotificationDays);
        
        String query = 'SELECT Id, Name, Broker_Registration_Expiry_Date__c, Trade_License_Expiry_Date__c,RERACertificateExpiryDate__c,CommercialLicenseExpiryDate__c,Broker_Application__c, (SELECT Id, Name, Email FROM Contacts WHERE BrokerType__c = :BROKER_CONTACT_TYPE_AGENCY_ADMIN OR BrokerContactRole__c INCLUDES (\'SuperAdmin\')) FROM Account WHERE RecordTypeId = :brokerAccountRecordTypeId AND Broker_Application__c != null';
        query += ' AND (RERACertificateExpiryDate__c =:firstNotificationDate OR RERACertificateExpiryDate__c =:secondNotificationDate OR Broker_Registration_Expiry_Date__c = :firstNotificationDate OR Broker_Registration_Expiry_Date__c = :secondNotificationDate OR Trade_License_Expiry_Date__c = :firstNotificationDate OR Trade_License_Expiry_Date__c = :secondNotificationDate OR CommercialLicenseExpiryDate__c = :firstNotificationDate OR CommercialLicenseExpiryDate__c = :secondNotificationDate  OR Trade_License_Expiry_Date__c = :currentDate OR CommercialLicenseExpiryDate__c = :currentDate)';
        
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<Account> scope){
        
        MetadataService objMetadataService = MetadataService.getInstance();
        EmailService objEmailService = EmailService.getInstance();
        
        Id brokerAgreementExpiryETId = objMetadataService.getAppSettingTextValue(MTD_BROKER_AGREEMENT_EXPIRY_NOTIFICATION_EMAIL_TEMPLATE_ID);
        Id brokerTradeLicenseEpiryETId = objMetadataService.getAppSettingTextValue(MTD_BROKER_TRADE_LICENSE_EXPIRY_NOTIFICATION_EMAIL_TEMPLATE_ID);
        Id brokerAgentRERAExpiryETId = objMetadataService.getAppSettingTextValue(MTD_BROKER_AGENT_RERA_CERTIFICATE_EXPIRY_NOTIFICATION_EMAIL_TEMPLATE_ID);
        Id brokerCommercialLicenseExpiryETId = objMetadataService.getAppSettingTextValue(MTD_BROKER_COMMERCIAL_LICENSE_EXPIRY_NOTIFICATION_EMAIL_TEMPLATE_ID);
        Id bloomBrokerNoReplyId = objMetadataService.getAppSettingTextValue(MTD_BAPP_BROKER_NO_REPLY_EMAIL_ID);        
        String brokerExpiryReminderBCCEmails = objMetadataService.getAppSettingTextValue(MTD_BROKER_EXPIRY_REMINDER_BCC_EMAILS);
        
        Integer firstNotificationDays = objMetadataService.getAppSettingNumberValue(MTD_BROKER_REG_EXPIRY_FIRST_NOTIFICATION_DAYS);
        Integer secondNotificationDays = objMetadataService.getAppSettingNumberValue(MTD_BROKER_REG_EXPIRY_SECOND_NOTIFICATION_DAYS);
        
        Date currentDate = System.today();
        Date firstNotificationDate = System.today().addDays(firstNotificationDays);
        Date secondNotificationDate = System.today().addDays(secondNotificationDays);
        
        List<String> toAddressesOfCustomereaddressList = new List<String>();
        
        List<Messaging.SingleEmailMessage> msgList =new List<Messaging.SingleEmailMessage>();
        
        List<String> bccEmailAddress = String.isNotBlank(brokerExpiryReminderBCCEmails) ? brokerExpiryReminderBCCEmails.split(',') : null;
        
        List<Account> accountsToUpdate = New List<Account>();
        Set<Id> expiredAccountIds = new Set<Id>();
        
        for(Account acc :scope){
            if(acc.Trade_License_Expiry_Date__c == firstNotificationDate || acc.Trade_License_Expiry_Date__c == secondNotificationDate){
                for(Contact con :acc.Contacts){
                    msgList.add(objEmailService.getSingleEmailMessageWithTargetObjectAsRecipient(brokerTradeLicenseEpiryETId, bloomBrokerNoReplyId, acc.Id, con.Id, null, null, bccEmailAddress));
                }
            }
            if((acc.CommercialLicenseExpiryDate__c == firstNotificationDate || acc.CommercialLicenseExpiryDate__c == secondNotificationDate)){
                for(Contact con :acc.Contacts){
                    msgList.add(objEmailService.getSingleEmailMessageWithTargetObjectAsRecipient(brokerCommercialLicenseExpiryETId, bloomBrokerNoReplyId, acc.Id, con.Id, null, null, bccEmailAddress));
                }
            }
            if (acc.Trade_License_Expiry_Date__c != null) {
                Integer tradeLicenseExpiryDelta = currentDate.daysBetween(acc.Trade_License_Expiry_Date__c);
                if (tradeLicenseExpiryDelta == 0) {
                    acc.isActive__c = false;
                    expiredAccountIds.add(acc.Id);
                }
            }
            if (acc.CommercialLicenseExpiryDate__c != null) {
                Integer commercialLicenseExpiryDelta = currentDate.daysBetween(acc.CommercialLicenseExpiryDate__c);
                if (commercialLicenseExpiryDelta == 0) {
                    acc.isActive__c = false;
                    expiredAccountIds.add(acc.Id);
                }
            }
            accountsToUpdate.add(acc);
        }
        
        AccountService.getInstance().updateAccounts(accountsToUpdate);
        objEmailService.sendEmail(msgList);
        
        // Deactivate Contacts
        if(!expiredAccountIds.isEmpty()){
            ContactService objConService = ContactService.getInstance();
            List<Contact> contactsToUpdate = objConService.getActiveContactByAccountId(expiredAccountIds);
            for(Contact con : contactsToUpdate){
                con.IsActive__c = false;
            }
            objConService.updateContacts(contactsToUpdate);
        }
    }
    
    public void finish(Database.BatchableContext BC) {
        
    }
    
    public void execute(SchedulableContext sc){
        Database.executeBatch(new BrokerRegistrationExpiryBatch());
    }
}