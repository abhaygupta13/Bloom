/*****************************************************************************************
Class       : VehicleRegistrationEmailBatch
Author      : Aman Bharti
Description : VehicleRegistrationEmailBatch
Test Class  : VehicleRegistrationEmailBatchTest
Created Date: 23 July 2025 
*****************************************************************************************/
public class VehicleRegistrationEmailBatch implements Database.Batchable<SObject>, Schedulable {

    private static final string VEHICLE_REGISTRATION_UNITID { get { return 'VehicleRegistrationUnitId'; } }
    private static final string BLOOM_NO_REPLY_SALES_OW_EMAIL_ID { get { return 'BloomNoReplySalesOWEmailId'; } }
    private static final string VEHICLE_REGISTRATION_URL { get { return 'VehicleRegistrationURL'; } }
    private static final string VEHICLE_REGISTRATION_EMAIL_ID { get { return 'VehicleRegistrationEmailTempId'; } }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        MetadataService objMetadataService = MetadataService.getInstance();
        String unitIds = objMetadataService.getAppSettingTextValue(VEHICLE_REGISTRATION_UNITID);
        List<String> unitIdList = unitIds.split(',');
        
        //if running from test class
        if(Test.isRunningTest()){
            Unit__c unit = [SELECT Id FROM Unit__c LIMIT 1];
            unitIdList.add(unit.Id);
        }

        List<String> userTypeList = new List<String>{'Owner','Tenant'};
        String query = 'SELECT Id, Account__c, Account__r.Name, Account__r.isPersonAccount, Account__r.PersonContactId,Unit__r.Project__r.Name FROM Unit_Allocation__c WHERE Unit__c IN :unitIdList AND Active__c = true AND User_Type__c IN :userTypeList';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<Unit_Allocation__c> scope) {
        
        EmailService objEmailService = EmailService.getInstance();
        MetadataService objMetadataService = MetadataService.getInstance();
        AccountService accService = AccountService.getInstance();
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        Id noReplyBloomSalesOWDId = objMetadataService.getAppSettingTextValue(BLOOM_NO_REPLY_SALES_OW_EMAIL_ID);
        Id vehicleRegistrationEmailId = objMetadataService.getAppSettingTextValue(VEHICLE_REGISTRATION_EMAIL_ID);
        String baseURL = objMetadataService.getAppSettingTextValue(VEHICLE_REGISTRATION_URL);
        Set<Id> newAccSet = new Set<Id>();
        for (Unit_Allocation__c alloc : scope) {
            newAccSet.add(alloc.Account__c);
        }
        System.debug('--->>>newAccSet--->>>'+newAccSet);
        List<Account> accList = accService.getAccountsWithPrimrayContact(newAccSet);
        for (Account acc : accList) {
            String recipientId = '';
            if(acc.isPersonAccount){
                recipientId = acc.PersonContactId;
            }
            else if(!acc.Contacts.isEmpty()){
                recipientId = acc.Contacts[0].Id;
            }
            else if(String.isBlank(recipientId)){
                continue;
            }
            EmailTemplate vehicleRegistrationET = objEmailService.getEmailTemplateById(vehicleRegistrationEmailId);
            String registrationLink = baseURL + acc.Id;
            String emailBody = vehicleRegistrationET.HtmlValue;
            emailBody = emailBody.replace('[Link]', '<a href="' + registrationLink + '">Click here</a>');
            
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            emails.add(objEmailService.getSingleEmailMessage(null, acc.Id, recipientId, vehicleRegistrationET.Subject, emailBody, noReplyBloomSalesOWDId));
        }
		System.debug('--->>>emails isze--->>>'+emails.size());
        if (!emails.isEmpty()) {
            Messaging.SendEmailResult[] results = objEmailService.sendEmail(emails);
        }
    }

    public void finish(Database.BatchableContext BC) {
        //finish logic here
    }
    // Scheduling the batch
    public void execute(SchedulableContext sc) {
        VehicleRegistrationEmailBatch batch = new VehicleRegistrationEmailBatch();
        Database.executeBatch(batch, 200);
    }
}