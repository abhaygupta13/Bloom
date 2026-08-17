/***
Class       : HandoverEmailController
Author      : Rajat Rastogi
Description : 
TestClass   : HandoverEmailControllerTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.      V1.0             	 20/06/2024           Initial Version  
****************************************************************************************************************/ 

public without sharing class HandoverEmailController {
 /*   public static final String Please_send_the_BCC_Announcement = 'Please send the BCC Announcement first before the NOC send to customer';
    public static final String Please_Upload_SOA_Report  = 'Please Upload SOA Report';
    public static final String Please_Upload_Desnagging_Report  = 'Please Upload Desnagging Report';
     public static final String Please_Upload_QA_Desnagging_Report  = 'Please Upload QA-Desnagging Report';
    public static final String Please_Upload_Mortgage_Value_Doc  = 'Please Upload Mortgage Value Doc';
    public static final String Please_Upload_Bloom_Title_Deed_Doc  = 'Please Upload Bloom Title Deed Doc';
    public static final String Please_Generate_Bank_NOC  = 'Please Generate Bank NOC before assign to Treasury Team';
    
    @AuraEnabled
    public static String sendNOCAndDesnaggingReport(Id recordId) {
        try {
           HandoverService HandoverService = HandoverService.getInstance();
           DocumentService DocumentService = DocumentService.getInstance();
            if (recordId != null) {
                Set<Id> contentDocumentIds = new Set<Id>();
                Handover__c handover = HandoverService.getHandoverRecordById(recordId);
                List<Document__c> documentList = DocumentService.getDocumentsByHandoverId(recordId);
                
                Document__c QASnagDoc = null;
                Document__c QADeSnagDoc = null;
                Document__c SOADoc = null;
                
                if(handover.Is_BCC_Announcement_Sent__c != true){
                    return Please_send_the_BCC_Announcement;
                }
                
                for (Document__c doc : documentList) {
                    if (doc.Document_Name__c == HandoverConstants.HO_CHO_DeSnagging_Report) {
                        QASnagDoc = doc;
                    } else if (doc.Document_Name__c == HandoverConstants.HO_SOA) {
                        SOADoc = doc;
                    }else if (doc.Document_Name__c == HandoverConstants.HO_QA_DeSnagging_Report) {
                        QADeSnagDoc = doc;
                    }
                }
                
                if (QASnagDoc.ContentDocumentId__c == null) { 
                    return Please_Upload_Desnagging_Report;
                } else {
                    contentDocumentIds.add(QASnagDoc.ContentDocumentId__c);
                }
                
                if (SOADoc.ContentDocumentId__c == null) {
                    return Please_Upload_SOA_Report;
                } else {
                    contentDocumentIds.add(SOADoc.ContentDocumentId__c);
                }
                if (QADeSnagDoc.ContentDocumentId__c == null) { 
                    return Please_Upload_QA_Desnagging_Report;
                } else {
                    contentDocumentIds.add(QADeSnagDoc.ContentDocumentId__c);
                }
                system.debug('contentDocumentIds'+contentDocumentIds);
                if(contentDocumentIds!=null){
                    List<string> docList = new List<string>();
                    docList.Add(HandoverConstants.HO_CHO_DeSnagging_Report);
                    docList.Add(HandoverConstants.HO_SOA);
                    String result = HandoverEmailHelper.sendEmailProcess(HandoverConstants.Notice_of_Completion_Template, handover.Id,new List<String>(),new List<String>(),docList);
                    if(result.equalsIgnoreCase('SUCCESS')){
                        Handover__c HOObj = new Handover__c();
                        HOObj.Id = handover.Id;
                        HOObj.Is_Notice_of_Completion_Sent__c = true;
                        HOObj.Sub_Status__c = HandoverConstants.Handover_Sub_Status_Notice_of_Completion_Sent;
                        HOObj.Notice_of_Completion_Date__c = Date.Today();
                        HOObj.NOC_Date__c = Date.today().addDays(30);
                       // update HOObj;
                        HandoverService.updateHandovers(new List<Handover__c>{HOObj});
                        if (handover.Unit__c != null) {
                        Unit__c unitObj = new Unit__c();
                        unitObj.Id = handover.Unit__c;
                        unitObj.NOCExpiryDate__c = Date.today().addYears(1);
                        update unitObj;
                    }
                        return 'Success';
                    }else{
                        return result;
                    }
                }else{
                    return 'Something went wrong';
                }
                
                // Assuming there's more logic to handle the ContentDocumentIds here
            }
        } catch (Exception e) {
            ErrorLogHandler.logError('HandoverEmailController','sendNOCAndDesnaggingReport',e,'');
            return 'An error occurred: ' + e.getMessage();
        }
        return '';
    }*/
    
}