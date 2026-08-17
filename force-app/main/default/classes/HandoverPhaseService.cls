/***
Class       : HandoverPhaseService
Author      : Smaartt
Description : 
TestClass   : HandoverPhaseServiceTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version    ¯          Date                Details
1.          V1.0              03/02/26          Initial Version 
****************************************************************************************************************/
public inherited sharing class HandoverPhaseService {
  private static HandoverPhaseService instance;
    
    private HandoverPhaseService(){
        
    }
    
    public static HandoverPhaseService getInstance() {
        if(instance == null) {
            instance = new HandoverPhaseService();
        }
        return instance;
    }
    
     public List<HandoverPhase__c> getHandoverPhase(String projectId) {
       return [select id,Name,Project__c from HandoverPhase__c WHERE Project__c = :projectId];
     }
     public HandoverPhase__c getHandoverPhaseDetails(Id phaseId) {
       return [select id,Name,FirstHOPaymentReminderEmailTempId__c,SecondHOPaymentReminderEmailTempId__c,ThirdHOPaymentReminderEmailTempId__c,BCCEmailTemplateId__c,CHOinviteEmailTempId__c,DoorNumberClarificationEmailTempId__c,SignHoDOCInvitationTempId__c,KHOAppointmentConfirmEmailTempId__c,HOTitleDeedEmailTempID__c,
               HOOutstandingConfirmationTempId__c,CHOReschedulingappoingmentTempId__c,CHOAppointmentConfirmEmailTempId__c,
               AppointmentConfirmSignEmailTempId__c,ChoAppointmentCanceledEmailTempId__c,NOCCHOEmailtemplateId__c,ChoDesnaggingEmailTempId__c,
               HomeOrientationByBloomEmailTempId__c,ChoCustomerNotattendedEmailTempId__c,CHOAttendedbyCustomerEmailTempId__c,
               HOCongratulationEmailTempId__c,KeyHandoverInvitationEmailTempId__c from HandoverPhase__c WHERE Id = :phaseId LIMIT 1];
     }
    
     public List<HandoverPhase__c> getHandoverPhaseInfo(set<id>phaseids) {
       return [select id,Name,FirstHOPaymentReminderEmailTempId__c,SecondHOPaymentReminderEmailTempId__c,ThirdHOPaymentReminderEmailTempId__c,BCCEmailTemplateId__c,CHOinviteEmailTempId__c,DoorNumberClarificationEmailTempId__c,SignHoDOCInvitationTempId__c,KHOAppointmentConfirmEmailTempId__c,HOTitleDeedEmailTempID__c,
               HOOutstandingConfirmationTempId__c,CHOReschedulingappoingmentTempId__c,CHOAppointmentConfirmEmailTempId__c,
               AppointmentConfirmSignEmailTempId__c,ChoAppointmentCanceledEmailTempId__c,NOCCHOEmailtemplateId__c,ChoDesnaggingEmailTempId__c,
               HomeOrientationByBloomEmailTempId__c,ChoCustomerNotattendedEmailTempId__c,CHOAttendedbyCustomerEmailTempId__c,
               HOCongratulationEmailTempId__c,KeyHandoverInvitationEmailTempId__c,Project__c from HandoverPhase__c WHERE Id = :phaseids];
     }
  
}