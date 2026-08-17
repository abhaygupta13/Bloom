/***
Class       : leadTaskCreationHandler
Author      : Smaartt
Description : 
TestClass   : LeadTaskCreationHandlerTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.          V1.0              27/04/23           Initial Version 
****************************************************************************************************************/
public class leadTaskCreationHandler {
    
    @InvocableMethod
    Public Static void createATaskonlead(List<id> leadId){
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        EmailTemplate emailTemplate = [SELECT Id, Subject, HtmlValue FROM EmailTemplate WHERE DeveloperName='Lead_notification_on_creation'];
        list<Lead> leadList = [select id,name,status,OwnerId from Lead where Id=:leadId];
        list<Task> tasklist = [select id,WhoId,subject From Task where WhoId =:leadId And subject = 'CC - Day 1 Call 1 - Follow Up'];
        if(tasklist.size()==0){
        if(leadList.size()>0){
            Task t = new Task();                
            if(leadList[0].Status=='New'){
                TaskUtilityHandler.TaskWrapper CcDay1Call1 = TaskUtilityHandler.getTaskConfigDetails('New',1);
                t.Subject = string.valueof(CcDay1Call1.taskSubject);
                DateTime.newInstance(CcDay1Call1.slaTime.dateGMT().year(), CcDay1Call1.slaTime.dateGMT().month(), CcDay1Call1.slaTime.dateGMT().day());
                t.ActivityDate = CcDay1Call1.slaTime.dateGMT();
                t.Due_Date_Time__c= CcDay1Call1.slaTime;
            }else{
                TaskUtilityHandler.TaskWrapper SmDay1Call1 = TaskUtilityHandler.getTaskConfigDetails('Qualified',1);
                t.Subject = string.valueof(SmDay1Call1.taskSubject);
                t.ActivityDate = SmDay1Call1.slaTime.dateGMT();
                System.debug(t.ActivityDate);
                t.Due_Date_Time__c=Datetime.valueof(SmDay1Call1.slaTime);
                
            }
            t.Description = 'Follow up with this lead to qualify their interest.';
            t.Status = 'Open';
            t.Type='Call';       
            t.Priority = 'Normal';
            t.Count__c= 1;
            t.OwnerId = leadList[0].OwnerId;//userInfo.getUserId();             
            t.WhoId = leadId[0];
            insert t;             
            /*User owner = [SELECT Id,Email FROM User WHERE Id = :leadList[0].OwnerId];
            String toAddress = owner.Email;
            system.debug('toAddress'+toAddress);
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setTemplateId(emailTemplate.Id);
            email.setTargetObjectId(leadList[0].id);
            email.setSaveAsActivity(true);
            email.setToAddresses(new String[] {toAddress});
            email.setTreatTargetObjectAsRecipient(false);
            emails.add(email);*/
            
            
        }
        }
        
        try{
            if(emails.size()>0){
               //Messaging.sendEmail(emails);
            }
        }catch (System.EmailException e) {
            // Handle the exception
            if(e.getMessage().contains('EMAIL_ADDRESS_BOUNCED')) {
                System.debug('incorrect email address');
            }
        }
        
    }
    
}