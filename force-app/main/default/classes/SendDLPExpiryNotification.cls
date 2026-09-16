public class SendDLPExpiryNotification implements Database.Batchable<sObject>, Schedulable {
    
    private static final String MDT_HANDOVER_ORG_WIDE_EMAIL_ADDRESS_ID = 'BloomNoReplySalesOWEmailId';
    
    private static final String DLP_EXPIRY_EMAIL_TEMPLATE_NAME = 'DLP Expiy Information Email Tempate'; 

    public Database.QueryLocator start(Database.BatchableContext BC) {
        
        String query = 'SELECT Id, Name,Unit__c, Unit_Code__c, ProjectNameArabic__c, ProjectName__c, ' +
                       'Customer_Name__c, Sub_Status__c, BloomPhone__c, BloomEmail__c, DLPExpiryEmail__c, ' +
                       'CustomerEmail__c, Notice_of_Completion_Date__c, NOC_Date__c, NOC_Expiry_Date__c, ' +
                       'Account_Manager_Name__c, Account_Manager_Email__c, Account_Manager_Phone__c, ' +
                       'HO_DD_MM_YYYY__c, Location__c, Location_Name__c, Date__c, Promise_to_Pay_Date__c, ' +
                       'Customer_Number__c, Address__c, Project__r.Handover_Community_Guidelines_English__c, ' +
                       'Project__r.Handover_Community_Guidelines_Arabic__c, SettlementFollowUpDate__c, ' +
                       'HomeOrientationInvitationDate__c, Customer_Name_Arabic__c, ProjectbyFormula__c, ' +
                       'Account_Manager_Name_Arabic__c, LocationName__c ' +
                       'FROM Handover__c ' +
                       'WHERE NOC_Expiry_Date__c = TODAY AND DLPExpiryEmail__c = false';
        
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<Handover__c> scope) {
        HandoverService objHandoverService = HandoverService.getInstance();
        EmailService objEmailService = EmailService.getInstance();
        MetadataService handoverMetadataService = MetadataService.getInstance();
        
        Id orgWideEmailAddressId = handoverMetadataService.getAppSettingTextValue(MDT_HANDOVER_ORG_WIDE_EMAIL_ADDRESS_ID);
        EmailTemplate mailTemplate = objEmailService.getEmailTemplateByName(DLP_EXPIRY_EMAIL_TEMPLATE_NAME);
        
        if (mailTemplate == null) {
            System.debug('Email Template not found: ' + DLP_EXPIRY_EMAIL_TEMPLATE_NAME);
            return;
        }

        List<Messaging.SingleEmailMessage> mailList = new List<Messaging.SingleEmailMessage>();
        List<Handover__c> handoversToUpdate = new List<Handover__c>();

        for (Handover__c ho : scope) {
            if (String.isNotBlank(ho.CustomerEmail__c ) && !ho.DLPExpiryEmail__c) {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                
               
                String subject = HandoverController.getDynamicSubject(mailTemplate.Subject, ho);
                String htmlBody = HandoverController.getDynamicBody(mailTemplate.HtmlValue, ho);
                
                mail.setToAddresses(new List<String>{ho.CustomerEmail__c});
                mail.setSubject(subject);
                mail.setHtmlBody(htmlBody);
                if (ho.Unit__c != null) {
            mail.setWhatId(ho.Unit__c); 
        }
                mail.setSaveAsActivity(true);
                mail.setUseSignature(false);

                if (orgWideEmailAddressId != null) {
                    mail.setOrgWideEmailAddressId(orgWideEmailAddressId);
                }

                mailList.add(mail);
                
                ho.DLPExpiryEmail__c = true;
                handoversToUpdate.add(ho);
            }
        }

        if (!mailList.isEmpty()) {
            objEmailService.sendEmail(mailList);
            objHandoverService.updateHandoversWithoutTrigger(handoversToUpdate);
        }
    }

    public void finish(Database.BatchableContext BC) {}

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new sendDLPExpiryNotification(), 50);
    }
}