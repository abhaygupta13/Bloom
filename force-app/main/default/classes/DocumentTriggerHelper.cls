/*
* @Author : Jayesh
* @CreatedDate : 12th DEC 2024
* @Description : Document object trigger helper
*/
/*****************************************************************************************************
* Version       Author      	Date             Comment                                                                       
* 1.0           Jayesh		   	12DEC24        Initial draft                                                                 
*****************************************************************************************************/
public class DocumentTriggerHelper {
    
    private static final string SPA_SIGNED_DOC_TYPE { get { return 'SPA - Signed'; } }
    private static final string PASSPORT_DOC_TYPE { get { return 'Passport'; } }
    private static final string EID_DOC_TYPE { get { return 'Emirates ID'; } }
    public static final String SPA_DOC_TYPE = 'SPA';
    private static final String LOOffer {get{ return 'Leasing Offer - Signed';} }
    private static final String LOContract {get{ return 'Leasing Contract - Signed';} }
    private static final String LContractDoc {get{ return 'Leasing Receipt document';} }
    private static final String BrokerAgreement {get{ return 'Broker Agreement';} }
    
    public static void updateDocumentUploadDate(List<Document__c> newDocumentsList, Map<Id, Document__c> oldMap){
        Set<String> setOfSalesOrderIds = new Set<String>();
        List<LeasingOrder__c> loList = new List<LeasingOrder__c>();
        for(Document__c newDoc : newDocumentsList){
            Document__c oldDoc = oldMap.get(newDoc.Id);
            if(newDoc.SalesOrder__c != null && newDoc.DocumentType__c != null
               && newDoc.ContentDocumentId__c != null && oldDoc.ContentDocumentId__c == null
               && (newDoc.Document_Name__c == SPA_SIGNED_DOC_TYPE || newDoc.Document_Name__c == PASSPORT_DOC_TYPE || newDoc.Document_Name__c == EID_DOC_TYPE)){
                   setOfSalesOrderIds.add(newDoc.SalesOrder__c);
               }
            if(newDoc.LeasingOrder__c != Null && newDoc.ContentDocumentId__c != Null && newDoc.ContentDocumentId__c != oldDoc.ContentDocumentId__c){
                if(newDoc.Document_Name__c == LOOffer){
                    LeasingOrder__c lo = new LeasingOrder__c(Id = newDoc.LeasingOrder__c, isLeasingOfferSigned__c = true, LeasingOfferSignedDate__c = System.now());
                    loList.add(lo);
                }
                if(newDoc.Document_Name__c == LOContract){
                    LeasingOrder__c lo = new LeasingOrder__c(Id = newDoc.LeasingOrder__c, isLeasingContractSigned__c = true, LeasingContractSignedDate__c = System.now());
                    loList.add(lo);
                }
            }
        }
        if(loList != null && !loList.isEmpty()){
            LeasingOrderService.getInstance().updateLeasingOrderswithOutTrigger(loList);
        }
        if(setOfSalesOrderIds != null && !setOfSalesOrderIds.isEmpty()){
            SalesOrderService sos = SalesOrderService.getInstance();
            sos.updateDocumentUploadDate(setOfSalesOrderIds);
        }
    }
    /* public static void changeHandoverOwnerOnSpaUpdate(List<Document__c> newDocumentsList, Map<Id, Document__c> oldMap) {
System.debug('trigger fire');
Set<Id> handoverIdsToUpdate = new Set<Id>();

for (Document__c newDoc : newDocumentsList) {
Document__c oldDoc = oldMap.get(newDoc.Id);

if (
newDoc.Handover__c != null &&
newDoc.Document_Name__c == SPA_DOC_TYPE &&
newDoc.ContentDocumentId__c != null &&
(oldDoc == null || oldDoc.ContentDocumentId__c == null) // i.e., new upload
) {
handoverIdsToUpdate.add(newDoc.Handover__c);
System.debug('handoverIdsToUpdate'+handoverIdsToUpdate);
}
}

if (!handoverIdsToUpdate.isEmpty()) {
List<Handover__c> handoversToUpdate = new List<Handover__c>();

for (Handover__c handover : [SELECT Id, Sub_Status__c, OwnerId,CRM_Team_Assigned_User__c FROM Handover__c WHERE Id IN :handoverIdsToUpdate]) {
if (handover.Sub_Status__c == 'QA De-Snagging Completed') {
handover.OwnerId = handover.CRM_Team_Assigned_User__c;
//handoversToUpdate.add(handover);
System.debug('handoversToUpdate'+handoversToUpdate);
}
}

if (!handoversToUpdate.isEmpty()) {
//update handoversToUpdate;
}
}
} */
    
    
    public static void sendEmailAlertToFinanceOwner(List<Document__c> newDocumentsList, Map<Id,Document__c> oldMap){
        Set<Id> ackIds=new Set<Id>();
        for(Document__c newDoc:newDocumentsList){
            Document__c oldDoc=oldMap.get(newDoc.Id);
            if(newDoc.LeasingReceiptAcknowledgment__c!=null && newDoc.ContentDocumentId__c!=null && newDoc.ContentDocumentId__c!=oldDoc.ContentDocumentId__c && newDoc.Document_Name__c==LContractDoc){
                ackIds.add(newDoc.LeasingReceiptAcknowledgment__c);
            }
        }
        LeasingReceiptAcknowledgementService.sendEmailAlertToFinanceOwnerOnDocumentUpdate(ackIds);
    }
    
    public Messaging.SingleEmailMessage sendLeasingFinanceEmail( Id emailTemplateId, Id orgWideEmailAddressId, List<String> toAddresses, List<Messaging.EmailFileAttachment> attachments ){
        Messaging.SingleEmailMessage mail;
        
        if(emailTemplateId != null){
            // Use template WITHOUT whatId dependency
            mail = Messaging.renderStoredEmailTemplate(emailTemplateId, null, null);
        } else {
            mail = new Messaging.SingleEmailMessage();
            mail.setSubject('Finance Task Notification');
            mail.setHtmlBody('Please review the finance task related to Leasing Order.');
        }
        
        if(String.isNotBlank(orgWideEmailAddressId)){
            mail.setOrgWideEmailAddressId(orgWideEmailAddressId);
        }
        
        if(toAddresses != null && !toAddresses.isEmpty()){
            mail.setToAddresses(toAddresses);
        }
        
        if(attachments != null && !attachments.isEmpty()){
            mail.setFileAttachments(attachments);
        }
        
        mail.setSaveAsActivity(true);
        mail.setTreatTargetObjectAsRecipient(false);
        
        if(Test.isRunningTest()){
            return null;
        }
        
        return mail;
    }
    
    // public static void updateLeasingOrderData( List<Document__c> newDocList, Map<Id, Document__c> oldDocMap){
    //     List<LeasingOrder__c> loList = new List<LeasingOrder__c>();
    
    //     for(Document__c doc : newDocList){
    //         if(doc.LeasingOrder__c != Null && doc.ContentDocumentId__c != Null && doc.ContentDocumentId__c != oldDocMap.get(doc.Id).ContentDocumentId__c){
    //             if(doc.Document_Name__c == LOOffer){
    //                 LeasingOrder__c lo = new LeasingOrder__c(Id = doc.LeasingOrder__c, isLeasingOfferSigned__c = true, LeasingOfferSignedDate__c = System.today());
    //                 loList.add(lo);
    //             }
    //             if(doc.Document_Name__c == LOContract){
    //                 LeasingOrder__c lo = new LeasingOrder__c(Id = doc.LeasingOrder__c, isLeasingContractSigned__c = true, LeasingContractSignedDate__c = System.today());
    //                 loList.add(lo);
    //             }
    //         }
    //     }
    //     LeasingOrderService.getInstance().updateLeasingOrderswithOutTrigger(loList);
    // }
    
    
    
    //Added By Ranjan
    // Archive document when ContentDocumentId__c is replaced on any Document__c
    // Works for ALL parent objects (Case, SalesOrder, Opportunity, etc.) automatically
    public static void archiveDocument(
        List<Document__c> newList, 
        Map<Id, Document__c> oldMap
    ) {
        List<DocumentArchive__c> documentArchiveList = new List<DocumentArchive__c>();
        for (Document__c objDocument : newList) {
            Document__c oldDoc = oldMap.get(objDocument.Id);
            if (oldDoc.ContentDocumentId__c != null 
                && objDocument.ContentDocumentId__c != oldDoc.ContentDocumentId__c
               ) {
                   documentArchiveList.add(new DocumentArchive__c(
                       Document__c = objDocument.Id, 
                       ContentDocumentId__c = oldDoc.ContentDocumentId__c
                   ));
               }
        }
        if (!documentArchiveList.isEmpty()) {
            DocumentArchiveService.getInstance().insertdocumentArchives(documentArchiveList);
        }
    }
}