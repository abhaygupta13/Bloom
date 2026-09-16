/***
Class       : HandoverNoticeDoorEmailController
Author      : Antriksh 
Description : Class used for send the Door Number email communication after handover notice.
TestClass   : HandoverNoticeDoorEmailControllerTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version    ¯    Date                Details
1.          V1.0              18/05/26            Initial Version 

****************************************************************************************************************/
public class HandoverNoticeDoorEmailController implements Queueable {
    private List<Id> recordIds;
    private static final string HANDOVER_DOORNUMBER_EMAIL_TEMPLATE_NAME { get { return 'Handover Notice Door Number email communication'; } }
    private static final string MDT_HANDOVER_ORG_WIDE_EMAIL_ADDRESS_ID { get { return 'BloomNoReplySalesOWEmailId'; } }
    
    public HandoverNoticeDoorEmailController(List<Id> ids) { 
        this.recordIds = ids; 
    }

    public void execute(QueueableContext context) {
        if (recordIds == null || recordIds.isEmpty()) return;

        // 1. Establish the transaction Savepoint for all-or-none rollback capability
        Savepoint sp = Database.setSavepoint();

        try {
            EmailService objEmailService = EmailService.getInstance();
            MetadataService handoverMetadataService = MetadataService.getInstance();
            
            List<Handover__c> handoverUpdateList = new List<Handover__c>();
            List<Messaging.SingleEmailMessage> mailList = new List<Messaging.SingleEmailMessage>();

            EmailTemplate mailTemplate = objEmailService.getEmailTemplateByName(HANDOVER_DOORNUMBER_EMAIL_TEMPLATE_NAME);
            Id orgWideEmailAddressId = handoverMetadataService.getAppSettingTextValue(MDT_HANDOVER_ORG_WIDE_EMAIL_ADDRESS_ID);

            // Fetch records ensuring they haven't already been processed
            List<Handover__c> handovers = [SELECT Id, unit__r.UnitNumber__c, Account__r.Name, Unit__r.ADMAddressingNumber__c, Account__r.NameinArabic__c, Name, Unit__r.Name, Unit_Plot_Number__c, Unit__r.DoorNumber__c, Unit_Code__c, ProjectNameArabic__c, ProjectName__c, 
                                                  Customer_Name__c, Sub_Status__c, Account_Manager_Name__c, 
                                                  Account_Manager_Email__c, Account_Manager_Phone__c, 
                                                  HO_DD_MM_YYYY__c, Location__c, Location_Name__c, Date__c, 
                                                  CustomerEmail__c, Promise_to_Pay_Date__c, Customer_Number__c, 
                                                  Address__c, Project__r.Handover_Community_Guidelines_English__c, 
                                                  Project__r.Handover_Community_Guidelines_Arabic__c, 
                                                  NOC_Expiry_Date__c, Purchase_Price__c, SettlementFollowUpDate__c, 
                                                  NOC_Date__c, HomeOrientationInvitationDate__c, Customer_Name_Arabic__c, 
                                                  ProjectbyFormula__c, Account_Manager_Name_Arabic__c, 
                                                  LocationName__c, BloomPhone__c, BloomEmail__c, Sales_Order__c,
                                                  Is_Notice_of_Completion_Sent__c, HasDoorNumberEmailSent__c
                                           FROM Handover__c 
                                           WHERE Id IN :recordIds 
                                           AND Is_Notice_of_Completion_Sent__c = true 
                                           AND HasDoorNumberEmailSent__c = false];

            if (handovers.isEmpty()) return;

            for (Handover__c ho : handovers) {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                
                String customSubject = HandoverController.getDynamicSubject(mailTemplate.Subject, ho);
                String customBody = HandoverController.getDynamicBody(mailTemplate.HtmlValue, ho, null);

                mail.setSubject(customSubject);
                mail.setHtmlBody(customBody);
                mail.setToAddresses(new List<String>{ ho.CustomerEmail__c });
                mail.setOrgWideEmailAddressId(orgWideEmailAddressId);
                mail.setWhatId(ho.Id);
                mail.setSaveAsActivity(true);
                
                mailList.add(mail);

                // Stage the update for this record
                handoverUpdateList.add(new Handover__c(
                    Id = ho.Id,
                    HasDoorNumberEmailSent__c = true
                ));
            }

            if (!mailList.isEmpty()) {
                List<Messaging.SendEmailResult> emailResultList = Messaging.sendEmail(mailList);
                
                for (Messaging.SendEmailResult res : emailResultList) {
                    if (!res.isSuccess()) {
                        String locErr = res.getErrors()[0].getMessage();
                        throw new AuraHandledException('Email engine transmission failure: ' + locErr);
                    }
                }

               
                    
                    HandoverService.getInstance().updateHandoversWithoutTrigger(handoverUpdateList);
                
            }

        } catch (Exception e) {
            // Explicitly roll back the transaction if any single email or DML component throws an error
            Database.rollback(sp);
            System.debug('Queueable execution failed. Transaction rolled back. Line: ' + e.getLineNumber() + ' | Error: ' + e.getMessage());
            throw e; 
        }
    }
}