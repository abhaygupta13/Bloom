/***
Class       : BillInstallmentSendReminderMilestone
Author      : Smaartt
Description : 
TestClass   : BillInstallmentSendReminderMilestoneTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.     version              Date                Details
1.          V1.0                                Initial Version 
****************************************************************************************************************/

public class BillInstallmentSendReminderMilestone {
    @AuraEnabled
    public static String BillInstallmentSendReminder(String req){
        String Success = 'Success'; // Initialize Success variable
        
        try {
            Milestone__c newmilestone = [SELECT Id, Milestone_Status__c, Milestone_Date__c FROM Milestone__c WHERE Id = :req];
           
            
            if (newmilestone != null && newmilestone.Milestone_Status__c == 'Reached' && newmilestone.Milestone_Date__c > Date.today()) {
                List<InstallmentLines__c> installmentsLines = [SELECT Id, InstallmentDate__c, ERP_ID__c, PaymentInstallments__r.Milestone__c
                                                               FROM InstallmentLines__c
                                                               WHERE PaymentInstallments__r.Milestone__c = :newmilestone.Id
                                                               AND InstallmentDate__c > :Date.today()
                                                               AND ERP_ID__c = NULL];
                System.debug('installmentsToUpdate: ' + installmentsLines);
                
                if (!installmentsLines.isEmpty()) { 
                    System.debug('inside check');
                    BillInstallmentSendReminderMilestone.sendSuccessEmail();
                    return Success;
                } else {
                    return null;
                }
            } else {
                return null;
            }
        } catch (Exception e) {
            // Handle exception appropriately, log or throw as needed
            System.debug('Exception occurred: ' + e.getMessage());
            return 'Error occurred: ' + e.getMessage();
        }
    }
    private static void sendSuccessEmail() {
        List<String> toAddresses = new List<String>();
        String BillInstallmentReminder = System.Label.BillInstallmentReminder;

        EmailTemplate emailTemplate = [SELECT Id, Subject, HtmlValue FROM EmailTemplate WHERE DeveloperName=:BillInstallmentReminder];
       
        toAddresses.addAll(Utilities.getUsersInPublicGroup(System.Label.Finance_Group));
         toAddresses.addAll(Utilities.getUsersInPublicGroup(System.Label.Operations_Team));
            
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setTemplateId(emailTemplate.Id);
        mail.setToAddresses(toAddresses);
        mail.setSaveAsActivity(true);
        mail.setTreatTargetObjectAsRecipient(false);
        mail.setTargetObjectId(userinfo.getUserId());
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        
        
        
    }
    
    
    
    
}