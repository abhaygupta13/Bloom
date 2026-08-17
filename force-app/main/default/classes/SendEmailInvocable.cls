/***
Class       : SendEmailInvocable
Author      : Rajat Rastogi
Description : Use from flow 'Handover Customer Notification' for Handover Process
TestClass   : SendEmailInvocableTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.      V1.0             	 11/06/2024           Initial Version  
****************************************************************************************************************/ 

public without sharing class SendEmailInvocable{
    
    
    
    private static final string HO_CHO_Snagging_Report = 'CHO Snagging Report';
    private static final string HO_CHO_DeSnagging_Report = 'CHO Desnagging Report';
    private static final string HO_SOA = 'SOA';
    private static final string Title_Deed = 'Title Deed';
    
    
    private static final String PAYMENT_RECEIPT = 'Payment Receipt';
    private static final string Full_Guideline_Document = 'Full Guideline Document';
  //  private static final Home_Orientation_Journey = 'Home Orientation Journey';
    private static final string Guideline_1_Arabic = 'Guideline 1 Arabic';
    private static final string Guideline_2_Arabic = 'Guideline 2 Arabic';
    private static final string Guideline_3_Arabic = 'Guideline 3 Arabic';
    private static final string Guideline_1 = 'Guideline 1';
    private static final string Guideline_2 = 'Guideline 2';
    private static final string Guideline_3 = 'Guideline 3';
    private static final String Application_Modification_Fitout_Works_Eng = 'Application for Modification and Fitout Works English';
    private static final String Application_Modification_Fitout_Works_Arb = 'Application for Modification and Fitout Works Arabic';
    private static final String Community_Entry_Permit_English_Eng = 'Community Entry Permit English';
    private static final String Community_Entry_Permit_English_Arb = 'Community Entry Permit Arabic';
    
    
    
    public static void sendEmail(Id templateId, Id recordId) {
        System.debug('SendEmailInvocable -> templateId: ' + templateId + ', recordId: ' + recordId);
        
        if (String.isBlank(templateId) || String.isBlank(recordId)) {
            ErrorLogHandler.logErrorWithoutException('SendEmailInvocable', 'sendEmail', 'Missing required parameters: templateId or recordId');
            return;
        }
        try {
            List<String> docList = new List<String>();
            HandoverService HandoverService = HandoverService.getInstance();
            HandoverPhaseService objHandoverPhaseService = HandoverPhaseService.getInstance();
            
            Handover__c handover = HandoverService.getHandoverById(recordId);
            HandoverPhase__c phaseRec = objHandoverPhaseService.getHandoverPhaseDetails(handover.Handover_Phase__c);
            
            if (templateId == phaseRec.HOTitleDeedEmailTempID__c) {
                docList.add(Title_Deed); 
            }
            //   else if (templateId == phaseRec.Payment_Confirmation_Template_Id__c) {
            //      docList.add(HandoverConstants.PAYMENT_RECEIPT); 
            //  } 
            else if (templateId == phaseRec.CHOAttendedbyCustomerEmailTempId__c || 
                     templateId == phaseRec.HomeOrientationByBloomEmailTempId__c ||
                     templateId == phaseRec.ChoCustomerNotattendedEmailTempId__c) {
                         docList.add(Guideline_2);
                         docList.add(Guideline_2_Arabic);
                         docList.add(Constants.HO_CHO_Snagging_Report);
                     } else if (templateId == phaseRec.ChoDesnaggingEmailTempId__c) {  
                         docList.add(Constants.HO_CHO_DeSnagging_Report);
                     } else if (templateId == phaseRec.HOCongratulationEmailTempId__c) {
                         docList.add(Guideline_3);
                         docList.add(Guideline_3_Arabic);
                         docList.add(HO_SOA);
                         docList.add(Application_Modification_Fitout_Works_Eng);
                         docList.add(Application_Modification_Fitout_Works_Arb);
                         docList.add(Community_Entry_Permit_English_Eng);
                         docList.add(Community_Entry_Permit_English_Arb);
                     } else if (templateId == phaseRec.KeyHandoverInvitationEmailTempId__c) {
                         docList.add(Guideline_1);
                         docList.add(Guideline_1_Arabic);
                     }
            String result = HandoverEmailHelper.sendEmailProcess(
                templateId, 
                recordId, 
                new List<String>(), 
                new List<String>(), 
                docList
            );
            
        } catch (Exception ex) {
            ErrorLogHandler.logError('SendEmailInvocable', 'sendEmail', ex, '');
        }
    }
}


/* public class EmailRequest {
@InvocableVariable(required=true)
public String templateName;

@InvocableVariable(required=true)
public String recordId;
}

@InvocableMethod   
public static void sendEmail(List<EmailRequest> requests){
system.debug('requests--->'+requests);
try{
List<string> docList = new List<string>();
if(requests.size()>0){

if(requests[0].templateName == HandoverConstants.Title_Deed_Registration){
docList.add(HandoverConstants.Title_Deed); 
}
if(requests[0].templateName == HandoverConstants.PAYMENT_Confirmation_Template){
docList.add(HandoverConstants.PAYMENT_RECEIPT); 
}
if(requests[0].templateName == HandoverConstants.Handover_Completion_Customer_Attended || 
requests[0].templateName == HandoverConstants.Home_Orientation_By_Bloom ||
requests[0].templateName == HandoverConstants.Handover_Completion_Customer_Not_Attended){
docList.Add(HandoverConstants.Guideline_2);
docList.Add(HandoverConstants.Guideline_2_Arabic);
// docList.Add(Constants.HO_SOA);
docList.Add(Constants.HO_CHO_Snagging_Report);
}
if(requests[0].templateName == HandoverConstants.CHO_Desnagging_Communication_Email_Template){  
docList.Add(Constants.HO_CHO_DeSnagging_Report);
}
if(requests[0].templateName == HandoverConstants.Handover_Congratulation_Email_Template){
docList.Add(HandoverConstants.Guideline_3);
docList.Add(HandoverConstants.Guideline_3_Arabic);
docList.Add(HandoverConstants.HO_SOA);
docList.Add(HandoverConstants.Application_Modification_Fitout_Works_Eng);
docList.Add(HandoverConstants.Application_Modification_Fitout_Works_Arb);
docList.Add(HandoverConstants.Community_Entry_Permit_English_Eng);
docList.Add(HandoverConstants.Community_Entry_Permit_English_Arb);
}
if(requests[0].templateName == HandoverConstants.KHO_Appointment_Scheduled_Template){
docList.Add(HandoverConstants.Guideline_1);
docList.Add(HandoverConstants.Guideline_1_Arabic);

}
String result = HandoverEmailHelper.sendEmailProcess(requests[0].templateName, requests[0].recordId,new List<String>(),new List<String>(),docList);
}else{
ErrorLogHandler.logErrorWithoutException('SendEmailInvocable','sendEmail','requests not found in sendEmail');
}
}catch(Exception ex){
ErrorLogHandler.logError('SendEmailInvocable','sendEmail',ex,'');
}

}*/