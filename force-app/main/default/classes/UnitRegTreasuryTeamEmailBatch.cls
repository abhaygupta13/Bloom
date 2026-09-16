/*****************************************************************************************
Class       : UnitRegTreasuryTeamEmailBatch
Author      : Dhanraj
Description : Batch class to send email to Treasury Team for Unit Registration.
Test Class  : UnitRegTreasuryTeamEmailBatchTest
Created Date: 19 Jun 2026
*****************************************************************************************/
public class UnitRegTreasuryTeamEmailBatch implements Database.Batchable<SObject>, Schedulable{
    private static final String MTD_NO_REPLY_OWEID_SETTING { get { return 'NoReplySalesIT'; }}
    private static final string MTD_UNIT_REGISTRATION_TREASURY_EMAIL_TEMPLATE_ID { get { return 'UnitRegistrationTreasuryEmailTemplateId'; } }
    private static final string MTD_TREASURY_TEAM_EMAIL_ADDSS { get { return 'TreasuryTeamEmailAddresses'; } }
    // Query to fetch records
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Date yesterdayDate = System.today().addDays(-1);
        return Database.getQueryLocator([
            Select Id, Name,Account__c,Account__r.Name,Unit__c,Unit__r.Name,Unit__r.ADMPlotNumber__c,Unit__r.Project__r.Name,FundMovedToGRDate__c,SellingPrice__c,
            OwnerSharePercentage__c
            FROM SalesOrder__c
            WHERE FundMovedToGRDate__c = :yesterdayDate
        ]);
    }
    
    // Processing each batch
    public void execute(Database.BatchableContext bc, List<SalesOrder__c> scope) {
        MetadataService objMetadataService = MetadataService.getInstance();
        EmailService objEmailService = EmailService.getInstance();
        AccountService objAccountService = AccountService.getInstance();
        DocumentService objDocumentService = DocumentService.getInstance();
        Id noReplyOWDId = objMetadataService.getAppSettingTextValue(MTD_NO_REPLY_OWEID_SETTING);
        String treasuryEmails = objMetadataService.getAppSettingTextValue(MTD_TREASURY_TEAM_EMAIL_ADDSS);
        List<String> toAddresses = treasuryEmails.split(',');
        EmailTemplate treasuryBatchET = objEmailService.getEmailTemplateById(objMetadataService.getAppSettingTextValue(MTD_UNIT_REGISTRATION_TREASURY_EMAIL_TEMPLATE_ID));
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        String emailBody = treasuryBatchET.HtmlValue;
        String emailSubject = treasuryBatchET.Subject;
        Set<Id> soIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();

        for(SalesOrder__c so : scope) {
            soIds.add(so.Id);
            if(so.Account__c != null){
                accountIds.add(so.Account__c);
            }
        }
        
        Map<Id, Account> accountMap = objAccountService.getAccountWithJointOwners(accountIds);
        Map<Id, String> accountJointOwnersMap = new Map<Id, String>();
        for(Account acc : accountMap.values()){
            Set<String> uniqueNames = new Set<String>();
            List<String> ownerNames = new List<String>();
            // Add primary account name first
            if(String.isNotBlank(acc.Name)){
                ownerNames.add(acc.Name);
                uniqueNames.add(acc.Name.trim().toLowerCase());
            }
            if(acc.Joint_Owners__r != null){
                for(JointOwner__c jo : acc.Joint_Owners__r){
                    String ownerName = '';
                    if(String.isNotBlank(jo.First_Name__c)){
                        ownerName += jo.First_Name__c.trim();
                    }
                    if(String.isNotBlank(jo.Last_Name__c)){
                        ownerName += (ownerName != '' ? ' ' : '') + jo.Last_Name__c.trim();
                    }
                    if(String.isBlank(ownerName)){
                        ownerName = jo.Name;
                    }
                    String normalizedName = String.isNotBlank(ownerName) ? ownerName.trim().toLowerCase() : '';
                    // Skip duplicates
                    if(String.isNotBlank(normalizedName) && !uniqueNames.contains(normalizedName)){
                        ownerNames.add(ownerName);
                        uniqueNames.add(normalizedName);
                    }
                }
            }
            accountJointOwnersMap.put(acc.Id,String.join(ownerNames, '; '));
        }
        
        String salesOrderTable = objEmailService.customSalesOrderTableHeader();
        Integer serialNo = 1;
        for(SalesOrder__c so : scope) {
            String jointOwners = (accountJointOwnersMap != null && accountJointOwnersMap.containsKey(so.Account__c) ? accountJointOwnersMap.get(so.Account__c): '');
            salesOrderTable += objEmailService.makeTable(serialNo,so,jointOwners);
            serialNo++;
        }
        salesOrderTable += '</table>';
        String csv = objEmailService.generateCSV(scope, accountJointOwnersMap);
            Blob csvBlob = Blob.valueOf(csv);
            Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
            attachment.setFileName('TreasuryBatchFiles.csv');
            attachment.setBody(csvBlob);
            attachment.setContentType('text/csv');
            emailBody = emailBody.replace('{{REGISTRATION_TABLE}}', salesOrderTable);
            Messaging.SingleEmailMessage email = objEmailService.getSingleEmailMessage(toAddresses, emailSubject, emailBody, noReplyOWDId); 
            email.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment});
            
            Messaging.SendEmailResult[] results = objEmailService.sendEmail(new List<Messaging.SingleEmailMessage>{email});        
    }
    
    public void finish(Database.BatchableContext bc) {
        
    }
    
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new UnitRegTreasuryTeamEmailBatch(),5);
    }
}