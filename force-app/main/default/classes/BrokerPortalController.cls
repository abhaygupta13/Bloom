/*****************************************************************************************
Class       : BrokerPortalController
Author      : Aman Bharti
Description : BrokerPortalController
Test Class  : 
Created Date: 29 OCT 2025 
*****************************************************************************************/
public without sharing class BrokerPortalController {

    private static final String SHARED_STR { get { return 'Shared'; } }

    @AuraEnabled
    public static void uploadBrokerSharedInvoice(Id documentId,String fileName, String fileBase64Data){
        try{
            ContentService objContentService = ContentService.getInstance();
            ContentVersion cv = objContentService.createContentVersion(EncodingUtil.base64Decode(fileBase64Data), fileName, fileName);

            List<ContentVersion> cvList = objContentService.createContentVersion(new List<ContentVersion>{cv});

            Id ContentDocumentId = objContentService.getContentDocumentId(cvList[0].Id);

            objContentService.createContentDocumentLink(ContentDocumentId, documentId, 'V', 'AllUsers');
        } catch (Exception e) {
            throw new AuraHandledException('Error uploading files: ' + e.getMessage());
        }  
    }

    @AuraEnabled
    public static Boolean isValidInvoiceRecord(Id documentId){
        try {
            DocumentService objDocumentService = DocumentService.getInstance();
            Document__c doc = objDocumentService.getDocumentById(documentId);
            if(doc == null || doc.BrokerCommission__c == null){
                return false;
            }
            BrokerCommissionService objBrokerCommissionService = BrokerCommissionService.getInstance();
            BrokerCommission__c brokerCommission = objBrokerCommissionService.getOnlyBrokerCommissionFields(doc.BrokerCommission__c);
            return brokerCommission.Status__c == SHARED_STR;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}