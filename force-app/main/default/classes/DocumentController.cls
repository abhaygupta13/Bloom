/*****************************************************************************************
Class       : DocumentController
Author      : Biswajeet 
Description : 
TestClass   : DocumentControllerTest
Created Date: 15 Oct 2024
------------------------------------------------------------------------------------------
-- History --
------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.      V1.0             15Oct2024           Initial Version 
*****************************************************************************************/
public class DocumentController {

    @AuraEnabled
    public static List<Document__c> getDocuments(Id recordId) {
        List<Document__c> documentList = new List<Document__c>();
        if(recordId.getSObjectType() == Account.SobjectType){
            documentList = [SELECT Id, Name, Document_Name__c, DocumentType__c, ContentDocumentId__c,
                            CreatedDate, CreatedById, CreatedBy.Name, LastModifiedDate, LastModifiedBy.Name,
                            DocumentType__r.ShareWithCustomer__c, DocumentType__r.IsSystemUpload__c,
                            DocumentType__r.MultiDocuments__c
                            FROM Document__c WHERE Account__c = :recordId AND DocumentType__c != null];
        }
        else if(recordId.getSObjectType() == Project__c.SobjectType){
            documentList = [SELECT Id, Name, Document_Name__c, DocumentType__c, ContentDocumentId__c,
                            CreatedDate, CreatedById, CreatedBy.Name, LastModifiedDate, LastModifiedBy.Name,
                            DocumentType__r.ShareWithCustomer__c, DocumentType__r.IsSystemUpload__c,
                            DocumentType__r.MultiDocuments__c
                            FROM Document__c WHERE Project__c = :recordId AND DocumentType__c != null];
        }
        else if(recordId.getSObjectType() == HandoverPhase__c.SobjectType){
            documentList = [SELECT Id, Name, Document_Name__c, DocumentType__c, ContentDocumentId__c,
                            CreatedDate, CreatedById, CreatedBy.Name, LastModifiedDate, LastModifiedBy.Name,
                            DocumentType__r.ShareWithCustomer__c, DocumentType__r.IsSystemUpload__c,
                            DocumentType__r.MultiDocuments__c
                            FROM Document__c WHERE HandoverPhase__c = :recordId AND DocumentType__c != null];
        }
        else if(recordId.getSObjectType() == SalesOrder__c.SobjectType){
            documentList = [SELECT Id, Name, SalesOrder__c, Document_Name__c, DocumentType__c, ContentDocumentId__c,
                            CreatedDate, CreatedById, CreatedBy.Name, LastModifiedDate, LastModifiedBy.Name,
                            DocumentType__r.ShareWithCustomer__c, DocumentType__r.IsSystemUpload__c,
                            DocumentType__r.MultiDocuments__c
                            FROM Document__c WHERE SalesOrder__c = :recordId AND DocumentType__c != null];
        }
        else if(recordId.getSObjectType() == BrokerCommission__c.SobjectType){
            documentList = [SELECT Id, Name, BrokerCommission__c, SalesOrder__c, Document_Name__c, DocumentType__c, ContentDocumentId__c,
                            CreatedDate, CreatedById, CreatedBy.Name, LastModifiedDate, LastModifiedBy.Name,
                            DocumentType__r.ShareWithCustomer__c, DocumentType__r.IsSystemUpload__c,
                            DocumentType__r.MultiDocuments__c
                            FROM Document__c WHERE BrokerCommission__c = :recordId AND DocumentType__c != null];
        }
        else if(recordId.getSObjectType() == Unit__c.SobjectType){
            documentList = [SELECT Id, Name, Unit__c, Document_Name__c, DocumentType__c, ContentDocumentId__c,
                            CreatedDate, CreatedById, CreatedBy.Name, LastModifiedDate, LastModifiedBy.Name,
                            DocumentType__r.ShareWithCustomer__c, DocumentType__r.IsSystemUpload__c,
                            DocumentType__r.MultiDocuments__c
                            FROM Document__c WHERE Unit__c = :recordId AND DocumentType__c != null];
        }else if(recordId.getSObjectType() == Handover__c.SobjectType){
            documentList = [SELECT Id, Name, Handover__c, Document_Name__c, DocumentType__c, ContentDocumentId__c,
                            CreatedDate, CreatedById, CreatedBy.Name, LastModifiedDate, LastModifiedBy.Name,
                            DocumentType__r.ShareWithCustomer__c, DocumentType__r.IsSystemUpload__c,
                            DocumentType__r.MultiDocuments__c
                            FROM Document__c WHERE Handover__c = :recordId AND DocumentType__c != null];
        }
         else if(recordId.getSObjectType() == Case.SobjectType){
            documentList = [SELECT Id, Name, Unit__c, Document_Name__c, DocumentType__c, ContentDocumentId__c,
                            CreatedDate, CreatedById, CreatedBy.Name, LastModifiedDate, LastModifiedBy.Name,
                            DocumentType__r.ShareWithCustomer__c, DocumentType__r.IsSystemUpload__c,
                            DocumentType__r.MultiDocuments__c
                            FROM Document__c WHERE Case__c = :recordId AND DocumentType__c != null];
        }
        else if(recordId.getSObjectType() == BrokerApplication__c.SobjectType){
            documentList = [SELECT Id, Name, BrokerApplication__c, Document_Name__c, DocumentType__c, ContentDocumentId__c,
                            CreatedDate, CreatedById, CreatedBy.Name, LastModifiedDate, LastModifiedBy.Name,
                            DocumentType__r.ShareWithCustomer__c, DocumentType__r.IsSystemUpload__c,
                            DocumentType__r.MultiDocuments__c
                            FROM Document__c WHERE BrokerApplication__c = :recordId AND DocumentType__c != null];
        }
        else if(recordId.getSObjectType() == BrokerApplicant__c.SobjectType){
            documentList = [SELECT Id, Name, BrokerApplicant__c, Document_Name__c, DocumentType__c, ContentDocumentId__c,
                            CreatedDate, CreatedById, CreatedBy.Name, LastModifiedDate, LastModifiedBy.Name,
                            DocumentType__r.ShareWithCustomer__c, DocumentType__r.IsSystemUpload__c,
                            DocumentType__r.MultiDocuments__c
                            FROM Document__c WHERE BrokerApplicant__c = :recordId AND DocumentType__c != null];
        }else if(recordId.getSObjectType() == LeasingOrder__c.SobjectType){
           documentList = [SELECT Id, Name, SalesOrder__c, Document_Name__c, DocumentType__c, ContentDocumentId__c,
                            CreatedDate, CreatedById, CreatedBy.Name, LastModifiedDate, LastModifiedBy.Name,
                            DocumentType__r.ShareWithCustomer__c, DocumentType__r.IsSystemUpload__c,
                            DocumentType__r.MultiDocuments__c
                            FROM Document__c WHERE LeasingOrder__c = :recordId AND DocumentType__c != null];
        }else if(recordId.getSObjectType() == PaymentPlanSchedule__c.SobjectType){
            documentList = [SELECT Id, Name, SalesOrder__c, Document_Name__c, DocumentType__c, ContentDocumentId__c,
                            CreatedDate, CreatedById, CreatedBy.Name, LastModifiedDate, LastModifiedBy.Name,
                            DocumentType__r.ShareWithCustomer__c, DocumentType__r.IsSystemUpload__c,
                            DocumentType__r.MultiDocuments__c
                            FROM Document__c WHERE PaymentPlanSchedule__c = :recordId AND DocumentType__c != null];
        }
        else if(recordId.getSObjectType() == LeasingOrdersOtherCharges__c.SobjectType){
            documentList = [SELECT Id, Name, SalesOrder__c, Document_Name__c, DocumentType__c, ContentDocumentId__c,
                            CreatedDate, CreatedById, CreatedBy.Name, LastModifiedDate, LastModifiedBy.Name,
                            DocumentType__r.ShareWithCustomer__c, DocumentType__r.IsSystemUpload__c,
                            DocumentType__r.MultiDocuments__c
                            FROM Document__c WHERE LeasingOrdersOtherCharges__c = :recordId AND DocumentType__c != null];
        }
         else if(recordId.getSObjectType() == Opportunity.SobjectType){
           documentList = [SELECT Id, Name, SalesOrder__c, Document_Name__c, DocumentType__c, ContentDocumentId__c,
                            CreatedDate, CreatedById, CreatedBy.Name, LastModifiedDate, LastModifiedBy.Name,
                            DocumentType__r.ShareWithCustomer__c, DocumentType__r.IsSystemUpload__c,
                            DocumentType__r.MultiDocuments__c,Opportunity__c
                            FROM Document__c WHERE Opportunity__c = :recordId AND DocumentType__c != null];
        }
        else if(recordId.getSObjectType() == Contact.SobjectType){
           documentList = [SELECT Id, Name, SalesOrder__c, Document_Name__c, DocumentType__c, ContentDocumentId__c,
                            CreatedDate, CreatedById, CreatedBy.Name, LastModifiedDate, LastModifiedBy.Name,
                            DocumentType__r.ShareWithCustomer__c, DocumentType__r.IsSystemUpload__c,
                            DocumentType__r.MultiDocuments__c,Contact__c
                            FROM Document__c WHERE Contact__c = :recordId AND DocumentType__c != null];
        } else if(recordId.getSObjectType() == LeasingReceiptAcknowledgment__c.SobjectType){
            documentList = [SELECT Id, Name, LeasingReceiptAcknowledgment__c , Document_Name__c, DocumentType__c, ContentDocumentId__c,
                            CreatedDate, CreatedById, CreatedBy.Name, LastModifiedDate, LastModifiedBy.Name,
                            DocumentType__r.ShareWithCustomer__c, DocumentType__r.IsSystemUpload__c,
                            DocumentType__r.MultiDocuments__c,Contact__c
                            FROM Document__c WHERE LeasingReceiptAcknowledgment__c = :recordId AND DocumentType__c != null];
        }
        else if(recordId.getSObjectType() == AppRegistration__c.SobjectType){
            documentList = [SELECT Id, Name, AppRegistration__c, Document_Name__c, DocumentType__c, ContentDocumentId__c,
                            CreatedDate, CreatedById, CreatedBy.Name, LastModifiedDate, LastModifiedBy.Name,
                            DocumentType__r.ShareWithCustomer__c, DocumentType__r.IsSystemUpload__c,
                            DocumentType__r.MultiDocuments__c,Contact__c
                            FROM Document__c WHERE AppRegistration__c = :recordId AND DocumentType__c != null];
        }

        return documentList;
    }
    
    @AuraEnabled
    public static void addFile(String base64, String filename, Id documentId){       
        try {
            DocumentService objDocumentService = DocumentService.getInstance();
            Document__c objDocument = objDocumentService.getDocumentById(documentId);
            if(String.isNotBlank(objDocument.ContentDocumentId__c)){
                objDocumentService.deleteContentDocument(new ContentDocument(Id = objDocument.ContentDocumentId__c));
            }
            ContentVersion cv = objDocumentService.insertContentVersion(base64, fileName);
            Id contentDocumentId = objDocumentService.getContentDocumentId(cv.Id);
            ContentDocumentLink cdl = objDocumentService.insertContentDocumentLink(contentDocumentId, documentId);
            objDocument.ContentDocumentId__c = contentDocumentId;
            objDocumentService.updateDocument(objDocument);
        }catch(System.exception ex){
            throw new AuraHandledException('Error: '+ ex.getMessage());   
        }
    }
    
    @AuraEnabled
    public static void deleteFile(Id documentId) {
        try{
            DocumentService objDocumentService = DocumentService.getInstance();
            Document__c objDocument = objDocumentService.getDocumentById(documentId);
            objDocumentService.deleteContentDocument(new ContentDocument(Id = objDocument.ContentDocumentId__c));
            objDocument.ContentDocumentId__c = NULL;
            objDocumentService.updateDocument(objDocument);
        }catch(System.exception ex){
            throw new AuraHandledException('Error: '+ ex.getMessage());   
        }
    }
    
    @AuraEnabled
    public static void shareDocument(Id recordId){
        MetadataService objMetadataService = MetadataService.getInstance();
        EmailService objEmailService = EmailService.getInstance();
        DocumentService objDocumentService = DocumentService.getInstance();
        List<Messaging.SingleEmailMessage> emailList = new list<Messaging.SingleEmailMessage>();
        
        
        Document__c objDocument = objDocumentService.getDocumentById(recordId);
        Id emailTemplateId = objDocument.DocumentType__r.EmailTemplateId__c;
        
        List<ContentDocumentLink> cdlList = [SELECT Id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId = :recordId];
   
    }
    
    //Added By Ranjan
    @AuraEnabled
    public static List<DocumentArchive__c> getArchiveDocuments(Id documentId) {
    List<DocumentArchive__c> documentArchiveList = new List<DocumentArchive__c>();
    documentArchiveList = DocumentArchiveService.getInstance()
        .getDocumentArchiveByDocumentId(documentId);
    return documentArchiveList;
    }
}