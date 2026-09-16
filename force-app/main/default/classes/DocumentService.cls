/*****************************************************************************************
Class       : DocumentService
Author      : Biswajeet 
Description : 
TestClass   : DocumentServiceTest
Created Date: 15 Oct 2024
------------------------------------------------------------------------------------------
-- History --
------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.      V1.0             15Oct2024           Initial Version 
*****************************************************************************************/
public inherited sharing class DocumentService {
    public static final String SUQUR_AL_WATAN_DOC_TYPE = 'Suqur Al Watan Employee Document';
    private static DocumentService instance;
    
    private DocumentService() {
        
    }
    
    public static DocumentService getInstance() { 
        if(instance == null) {
            instance = new DocumentService();
        }
        return instance;
    }
    public static final Set<String> requiredDocNames = new Set<String>{'MOU','Buyer Passport','CIF','Undertaking Letter','Resale Cancellation','POA Document','Buyer Emirates ID','Unit Registration','Title Deed','Passport'};
    public List<Document__c> getDocumentByHandoverIdAndName(Id handoverId, String documentName){
        return [SELECT Id, Name, Document_Name__c, DocumentType__c, ContentDocumentId__c,
                    DocumentType__r.ShareWithCustomer__c, DocumentType__r.IsSystemUpload__c,
                    DocumentType__r.MultiDocuments__c FROM Document__c WHERE Document_Name__c = :documentName 
                AND Handover__c = :handoverId  AND ContentDocumentId__c=null LIMIT 1];
    }
    
    public List<Document__c> getDocumentByAccountIdAndName(Id AccountId, String documentName){
        return [SELECT Id, ContentDocumentId__c, Content_Version_Id__c, Document_Name__c
                FROM Document__c
                WHERE Account__c = :AccountId
                AND Document_Name__c = :documentName
                LIMIT 1];
    }
    
    public List<Document__c> getDocumentsByHandoverId(Id recordId) {
        return [SELECT Id, Document_Name__c, ContentDocumentId__c FROM Document__c WHERE (Document_Name__c = :HandoverConstants.HO_CHO_DeSnagging_Report 
                                                                                          OR Document_Name__c = :HandoverConstants.HO_SOA OR Document_Name__c = :HandoverConstants.HO_QA_DeSnagging_Report) AND Handover__c = :recordId];
    }
    
    public ContentVersion insertContentVersion(String base64, String fileName) {
        ContentVersion cv = new ContentVersion();
        cv.VersionData = EncodingUtil.base64Decode(base64);
        cv.Title = fileName;
        cv.Origin = 'H';
        cv.PathOnClient = '/' + fileName;
        insert cv;
        return cv;
    }
    
    public List<DocumentType__c> getDocTypes(String objectType, String recTypeDevName) { 
        return [SELECT Id, Name, Type__c,Project__c,BrokerContactRole__c,TypeofEstablishment__c,IsDocgen__c,Active__c,DigitalSignature__c, ObjectType__c, Resale__c FROM DocumentType__c WHERE ObjectType__c = :objectType AND RecordTypeDevName__c=:recTypeDevName];
    }
    
    public List<Document__c> getDocumentsByObjectIds(Set<Id> targetIds, String objectType) {
        if (targetIds == null || targetIds.isEmpty()) {
            return new List<Document__c>();
        }    
        String query = 'SELECT Id, Account__c,Contact__c, Document_Name__c, FileName__c, FileSizeMB__c, FileType__c, ' + 
            'ContentDocumentId__c, Content_Version_Id__c ' +
            'FROM Document__c WHERE ' + objectType + ' IN :targetIds';
        
        return Database.query(query);
    }
    
    public ContentDocumentLink insertContentDocumentLink(Id contentDocumentId, Id recordId) {
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = contentDocumentId;
        cdl.LinkedEntityId = recordId;       
        cdl.ShareType = 'I';
        insert cdl;
        return cdl;
    }
    
    public Id getContentDocumentId(Id contentVersionId) {
        return [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersionId].ContentDocumentId;
    }
    
    public Document__c getDocumentById(Id documentId) {
        return [SELECT Name, ContentDocumentId__c, DocumentType__r.Type__c,
                Content_Version_Id__c, Account__c, BrokerCommission__c, Project__c FROM Document__c WHERE Id = :documentId];
    }
    
    public List<Document__c> getDocumentsForHandovers(List<String> documentsListToAttach, List<Handover__c> handoverIds) {
        return [SELECT Id, Document_Name__c, Handover__c, ContentDocumentId__c FROM Document__c
                WHERE Document_Name__c IN :documentsListToAttach AND Handover__c IN :handoverIds];
    }
    
    public List<Document__c> getDocumentsByNameAndParentIds(List<String> documentNameList, Set<Id> recordIds) {
        return [SELECT Id, Document_Name__c, Handover__c, ContentDocumentId__c FROM Document__c
                WHERE Document_Name__c IN :documentNameList AND Handover__c IN :recordIds];
    }
    
     public void addFile(String base64, String filename, Id documentId){       
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

    
    public List<Document__c> getDocumentsForHandover(List<String> documentsListToAttach, Handover__c handover) {
        return [SELECT Id, Document_Name__c, ContentDocumentId__c FROM Document__c
                WHERE Document_Name__c IN :documentsListToAttach AND (Handover__c = :handover.Id OR Project__c = :handover.Project__c)];
    }
    
    public List<Document__c> getAccountDocuments(Id recordId) {
        return [SELECT Id, Name, ContentDocumentId__c, DocumentType__r.Type__c, Content_Version_Id__c
                FROM Document__c WHERE Account__c = :recordId];
    }
    
    public Document__c getCaseDocumentByName(Id recordId,String documentName) {
        return [SELECT Id, Name, Document_Name__c, ContentDocumentId__c, DocumentType__r.Type__c, Content_Version_Id__c
                FROM Document__c WHERE Case__c = :recordId and Document_Name__c =:documentName];
    }
    
    public List<Document__c> getCaseDocumentsByNames(Id recordId,List<String> documentNames) {
        return [SELECT Id, Name, Document_Name__c, ContentDocumentId__c, DocumentType__r.Type__c, Content_Version_Id__c
                FROM Document__c WHERE Case__c = :recordId and Document_Name__c IN:documentNames];
    }

    public List<Document__c> getCaseDocumentsWithAttachmentsByNames(Id recordId, List<String> documentNames) {
        return [SELECT Id, Name, Document_Name__c, ContentDocumentId__c, DocumentType__r.Type__c, Content_Version_Id__c
                FROM Document__c WHERE Case__c = :recordId and Document_Name__c IN :documentNames AND Content_Version_Id__c != NULL];
    }

    public Document__c updateDocument(Document__c objDocument){
        if(objDocument != NULL ){
            objDocument = updateDocuments(new List<Document__c>{objDocument})[0];
        }
        return objDocument;
    }
    
    public List<Document__c> updateDocuments(List<Document__c> documentList){
        if(documentList != NULL && !documentList.isEmpty()){
            update documentList;
        }
        return documentList;
    }
    
    public List<Document__c> getDocumentsByPatternAndHandoverIds(Set<Id> handoverIds, String documentPattern) {
        return [SELECT Id, Document_Name__c, ContentDocumentId__c, Handover__c FROM Document__c 
                WHERE Document_Name__c LIKE :documentPattern AND Handover__c IN :handoverIds];
    }
    
    
    public Document__c insertDocument(Document__c objDocument){
        if(objDocument != NULL ){
            objDocument = insertDocuments(new List<Document__c>{objDocument})[0];
        }
        return objDocument;
    }
    
    public List<Document__c> insertDocuments(List<Document__c> documentList){
        if(documentList != NULL && !documentList.isEmpty()){
            insert documentList;
        }
        return documentList;
    }
    public ContentDocument deleteContentDocument(ContentDocument objDocument){
        if(objDocument != NULL ){
            objDocument = deleteContentDocuments(new List<ContentDocument>{objDocument})[0];
        }
        return objDocument;
    }
    
    public List<ContentDocument> deleteContentDocuments(List<ContentDocument> documentList){
        if(documentList != NULL && !documentList.isEmpty()){
            delete documentList;
        }
        return documentList;
    }
    
    public List<Document__c> deleteDocuments(List<Document__c> documentList) {
        if (documentList != null && !documentList.isEmpty()) {
            delete documentList;
        }
        return documentList;
    }
    
    public List<Document__c> deleteDocumentsByApplicantIds(Set<Id> applicantIds) {
        List<Document__c> docsToDelete = [
            SELECT Id 
            FROM Document__c 
            WHERE BrokerApplicant__c IN :applicantIds
        ];
        return deleteDocuments(docsToDelete);
    }
    
    public List<Document__c> getDocumentsByHandoverAndName(Set<Id> handoverIds, List<String> documentNames) {
        return [SELECT Id, Document_Name__c, ContentDocumentId__c, Handover__c, Content_Version_Id__c
                FROM Document__c WHERE Document_Name__c IN :documentNames AND Handover__c IN :handoverIds];
    }
    
    public List<Document__c> getDocumentWithContentVersion(Set<Id> handoverIds, List<String> documentNames) {
        return [SELECT Id, Document_Name__c, ContentDocumentId__c, Handover__c, Content_Version_Id__c
                FROM Document__c WHERE Document_Name__c IN :documentNames AND Handover__c IN :handoverIds AND Content_Version_Id__c != null];
    } 

    public List<Document__c> getDocumentsWithAttachments(Set<Id> handoverIds, List<String> documentNames) {
        return [SELECT Id, Name, DocumentType__c, Handover__c FROM Document__c 
                    WHERE Handover__c IN :handoverIds AND Document_Name__c IN :documentNames AND ContentDocumentId__c != NULL];
    } 

    public List<Document__c> getDocumentsOnHandoverWithAttachments(Id handoverId) {
        return [SELECT Id, Name, Document_Name__c, DocumentType__c, Handover__c, ContentDocumentId__c, Content_Version_Id__c FROM Document__c 
                    WHERE Handover__c = :handoverId AND ContentDocumentId__c != NULL];
    } 

    public List<Document__c> getDocumentsOnHandoversWithAttachments(Set<Id> handoverIds) {
        return [SELECT Id, Name, Document_Name__c, DocumentType__c, Handover__c FROM Document__c 
                    WHERE Handover__c IN :handoverIds AND ContentDocumentId__c != NULL];
    } 
    
    public List<DocumentType__c> getDocTypes(String objectType) { 
        return [SELECT Id, Name, Type__c, ObjectType__c,Project__c,BrokerContactRole__c,IsDocgen__c,Active__c,DigitalSignature__c, Customer_Type__c,RecordTypeDevName__c,TypeofEstablishment__c, Resale__c FROM DocumentType__c WHERE ObjectType__c = :objectType];
    }
    public List<DocumentType__c> getActiveDocTypesForRecordType(String objectType,String recTypeDevName) { 
        return [SELECT Id, Name, Type__c,Project__c,IsDocgen__c,Active__c,DigitalSignature__c,Customer_Type__c FROM DocumentType__c WHERE ObjectType__c = :objectType AND RecordTypeDevName__c=:recTypeDevName AND Active__c = true];
    }
    
    //Get the documents
    public List<Document__c> getDocumentBasedonType(Id recordId, String documentType) { 
        List<Document__c> documentList = new List<Document__c>();
        if(recordId.getSObjectType() == Project__c.SobjectType){
            documentList = [SELECT Id, Name, Document_Name__c, DocumentType__c, ContentDocumentId__c,
                            DocumentType__r.ShareWithCustomer__c, DocumentType__r.IsSystemUpload__c,
                            DocumentType__r.MultiDocuments__c
                            FROM Document__c 
                            WHERE Project__c = :recordId AND DocumentType__r.Type__c = :documentType];
            return documentList;
        }else if(recordId.getSObjectType() == SalesOrder__c.SobjectType){
            documentList = [SELECT Id, Name, Document_Name__c, DocumentType__c, ContentDocumentId__c,
                            DocumentType__r.ShareWithCustomer__c, DocumentType__r.IsSystemUpload__c,
                            DocumentType__r.MultiDocuments__c
                            FROM Document__c 
                            WHERE SalesOrder__c = :recordId AND DocumentType__r.Type__c = :documentType];
            return documentList;
        }
        else if(recordId.getSObjectType() == BrokerCommission__c.SobjectType){
            documentList = [SELECT Id, Name, Document_Name__c, DocumentType__c, ContentDocumentId__c,
                            DocumentType__r.MultiDocuments__c
                            FROM Document__c 
                            WHERE BrokerCommission__c = :recordId AND DocumentType__r.Type__c = :documentType];
            return documentList;
        }
        else if(recordId.getSObjectType() == Unit__c.SobjectType){
            return documentList = [SELECT Id, Name, Unit__c, Document_Name__c, DocumentType__c, ContentDocumentId__c,
                                   CreatedDate, CreatedById, CreatedBy.Name,
                                   DocumentType__r.ShareWithCustomer__c, DocumentType__r.IsSystemUpload__c,
                                   DocumentType__r.MultiDocuments__c,Content_Version_Id__c
                                   FROM Document__c WHERE Unit__c = :recordId AND DocumentType__r.Type__c = :documentType];
        }
        //BAPP
        else if(recordId.getSObjectType() == BrokerApplication__c.SObjectType){
            documentList = [SELECT Id, Name, Document_Name__c, DocumentType__c, ContentDocumentId__c,
                            DocumentType__r.ShareWithCustomer__c, DocumentType__r.IsSystemUpload__c,
                            DocumentType__r.MultiDocuments__c
                            FROM Document__c 
                            WHERE BrokerApplication__c = :recordId AND DocumentType__r.Type__c = :documentType];
            return documentList;
        }
         else if(recordId.getSObjectType() == Handover__c.SObjectType){
            documentList = [SELECT Id, Name, Document_Name__c, DocumentType__c, ContentDocumentId__c,
                            DocumentType__r.ShareWithCustomer__c, DocumentType__r.IsSystemUpload__c,
                            DocumentType__r.MultiDocuments__c
                            FROM Document__c 
                            WHERE Handover__c = :recordId AND DocumentType__r.Type__c = :documentType];
            return documentList;
        }
        return null;
    }
    
    public List<Document__c> getDocumentByNameAndProject(List<String> documentTypes, Set<Id> projectIds) {
        return [SELECT Id, Document_Name__c, Project__c  FROM Document__c WHERE Project__c IN :projectIds AND Document_Name__c IN :documentTypes];
    } 
    
    //get document records for broker commision
    public List<Document__c> getBrokerCommissionDocuments(String recordId, String docName){
        return [SELECT Id,BrokerCommission__c,ContentDocumentId__c FROM Document__c WHERE BrokerCommission__c = :recordId AND Document_Name__c = :docName];
    }
    //get document records for broker commision list
    public List<Document__c> getBrokerCommissionDocuments(List<BrokerCommission__c> brokerList, String docName){
        return [SELECT Id, BrokerCommission__c,Content_Version_Id__c,ContentDocumentId__c,DocumentType__r.Type__c FROM Document__c WHERE BrokerCommission__c IN :brokerList AND DocumentType__r.Type__c = :docName];
    }
    
    public List<String> getDocWithProfileAccess(String profileName){
        List<String> docList = new List<String>();
        if(String.isNotBlank(profileName)){
            List<Document_Set_Up_Config__mdt> documentList = [SELECT Id, MasterLabel FROM Document_Set_Up_Config__mdt WHERE Sobject_lkup_Api_Name__c = :HandoverConstants.HANDOVER_SOBJECT 
                                                              AND ProfileAccess__c LIKE :('%' + profileName + '%')];
            if(documentList != null && !documentList.isEmpty()){
                for(Document_Set_Up_Config__mdt doc : documentList){
                    docList.add(doc.MasterLabel);
                }
                return docList;
            }
        }
        return null;
    }
    
    public List<Document__c> getAllSalesOrderDocuments(List<String> salesOrderIds){
        return [SELECT Id, Document_Name__c, ContentDocumentId__c, Case__c, SalesOrder__c FROM Document__c WHERE SalesOrder__c IN :salesOrderIds];
    }
    
    public List<Document__c> getSalesOrderDocumentsByName(List<String> salesOrderIds, String docName){
        return [SELECT Id, Document_Name__c, ContentDocumentId__c, SalesOrder__c FROM Document__c WHERE SalesOrder__c In :salesOrderIds AND Document_Name__c =:docName];
    }
    
    public List<Document__c> getUnitDocumentsByName(List<String> unitIds, String docName){
        return [SELECT Id, Document_Name__c, ContentDocumentId__c, Unit__c FROM Document__c WHERE Unit__c In :unitIds AND Document_Name__c =:docName];
    }
    
    //BAPPP
    public List<Document__c> getApplicationDocumentsByName(List<Id> applicationIds, String docName) {
        return [
            SELECT Id, Document_Name__c, ContentDocumentId__c, BrokerApplication__c
            FROM Document__c
            WHERE BrokerApplication__c IN :applicationIds AND Document_Name__c = :docName
        ];
    }
    
    public List<Document__c> getCaseDocuments(Set<Id> parentIds) {
        return [
            SELECT Id, Case__c, Document_Name__c, DocumentType__c,DocumentType__r.Type__c, BrokerApplication__c, BrokerApplicant__c,Content_Version_Id__c, ContentDocumentId__c
            FROM Document__c WHERE Case__c IN :parentIds OR Case__c IN :parentIds OR Case__c IN :parentIds
        ];
    }
    
    //Get Documents by record id
    public static List<Document__c> getDocuments(Id recordId) {
        List<Document__c> documentList = new List<Document__c>();
        if(recordId.getSObjectType() == Account.SobjectType){
            documentList = [SELECT Id, Name, Document_Name__c, DocumentType__c, ContentDocumentId__c,
                            CreatedDate, CreatedById, CreatedBy.Name,
                            DocumentType__r.ShareWithCustomer__c, DocumentType__r.IsSystemUpload__c,
                            DocumentType__r.MultiDocuments__c
                            FROM Document__c WHERE Account__c = :recordId];
        }
        if(recordId.getSObjectType() == Project__c.SobjectType){
            documentList = [SELECT Id, Name, Document_Name__c, DocumentType__c, ContentDocumentId__c,
                            CreatedDate, CreatedById, CreatedBy.Name,
                            DocumentType__r.ShareWithCustomer__c, DocumentType__r.IsSystemUpload__c,
                            DocumentType__r.MultiDocuments__c
                            FROM Document__c WHERE Project__c = :recordId];
        }
        if(recordId.getSObjectType() == SalesOrder__c.SobjectType){
            documentList = [SELECT Id, Name, SalesOrder__c, Document_Name__c, DocumentType__c, ContentDocumentId__c,
                            CreatedDate, CreatedById, CreatedBy.Name,
                            DocumentType__r.ShareWithCustomer__c, DocumentType__r.IsSystemUpload__c,
                            DocumentType__r.MultiDocuments__c
                            FROM Document__c WHERE SalesOrder__c = :recordId];
        }
        // BAPP
        if(recordId.getSObjectType() == BrokerApplication__c.SObjectType){
            documentList = [SELECT Id, Name, BrokerApplication__c, Document_Name__c, DocumentType__c, ContentDocumentId__c,
                            CreatedDate, CreatedById, CreatedBy.Name,
                            DocumentType__r.ShareWithCustomer__c, DocumentType__r.IsSystemUpload__c,
                            DocumentType__r.MultiDocuments__c
                            FROM Document__c WHERE BrokerApplication__c = :recordId];
        }
        else if(recordId.getSObjectType() == Unit__c.SobjectType){
            documentList = [SELECT Id, Name, Unit__c, Document_Name__c, FileName__c, DocumentType__c, ContentDocumentId__c,
                            CreatedDate, CreatedById, CreatedBy.Name,
                            DocumentType__r.ShareWithCustomer__c, DocumentType__r.IsSystemUpload__c,
                            DocumentType__r.MultiDocuments__c
                            FROM Document__c WHERE Unit__c = :recordId];
        }
        else if(recordId.getSObjectType() == BrokerCommission__c.SobjectType){
            documentList = [SELECT Id, Name, Unit__c, Document_Name__c, DocumentType__c, ContentDocumentId__c,
                            CreatedDate, CreatedById, CreatedBy.Name,
                            DocumentType__r.ShareWithCustomer__c, DocumentType__r.IsSystemUpload__c,
                            DocumentType__r.MultiDocuments__c
                            FROM Document__c WHERE BrokerCommission__c = :recordId];
        }
        return documentList;
    }
    
    /*  public List<Document__c> getExistingDocuments(Set<Id> parentIds) {
return [
SELECT Id, DocumentType__c,DocumentType__r.Type__c, BrokerApplication__c, BrokerApplicant__c,Content_Version_Id__c, ContentDocumentId__c
FROM Document__c WHERE BrokerApplication__c IN :parentIds
];
}*/
    
    public List<Document__c> getExistingDocuments(Set<Id> parentIds) {
        return [
            SELECT Id, DocumentType__c,DocumentType__r.Type__c, BrokerApplication__c, BrokerApplicant__c,Content_Version_Id__c, ContentDocumentId__c
            FROM Document__c WHERE BrokerApplication__c IN :parentIds OR BrokerApplicant__c IN :parentIds OR Case__c IN :parentIds
        ];
    }
    
    public List<Document__c> getExistingDocumentsForApplicant(Set<Id> parentIds) {
        return [
            SELECT Id, DocumentType__c,DocumentType__r.Type__c, BrokerApplication__c, BrokerApplicant__c,Content_Version_Id__c, ContentDocumentId__c
            FROM Document__c WHERE BrokerApplicant__c IN :parentIds
        ];
    }
    
    //Rushikesh
    public List<Document__c> getDocumentsByApplicationNumber(String applicationNumber) {
        List<Document__c> allDocuments = new List<Document__c>();
        
        // 1. Get the BrokerApplication record
        BrokerApplication__c app = [
            SELECT Id
            FROM BrokerApplication__c
            WHERE ApplicationNumber__c = :applicationNumber
            LIMIT 1
        ];
        
        if (app == null) return allDocuments;
        
        // 2. Query for documents directly linked to BrokerApplication
        List<Document__c> applicationDocs = [
            SELECT ContentDocumentId__c,
            DocumentType__c,
            DocumentType__r.ObjectType__c,
            Content_Version_Id__c,
            Document_Name__c,
            FileName__c,
            FileSizeMB__c,
            FileType__c,
            BrokerApplication__r.Name,
            BrokerApplication__r.Id
            FROM Document__c
            WHERE BrokerApplication__c = :app.Id
        ];
        
        allDocuments.addAll(applicationDocs);
        
        // 3. Query for applicants under this application
        List<BrokerApplicant__c> applicants = [
            SELECT Id
            FROM BrokerApplicant__c
            WHERE BrokerApplication__c = :app.Id
        ];
        
        // 4. Query documents linked to those applicants (if any)
        if (!applicants.isEmpty()) {
            List<Id> applicantIds = new List<Id>();
            for (BrokerApplicant__c ba : applicants) {
                applicantIds.add(ba.Id);
            }
            
            List<Document__c> applicantDocs = [
                SELECT ContentDocumentId__c,
                DocumentType__c,
                DocumentType__r.ObjectType__c,
                Content_Version_Id__c,
                Document_Name__c,
                FileName__c,
                FileSizeMB__c,
                FileType__c,
                BrokerApplicant__r.BrokerContactRole__c,
                BrokerApplicant__r.Title__c,
                BrokerApplicant__r.FirstName__c,
                BrokerApplicant__r.MiddleName__c,
                BrokerApplicant__r.LastName__c,
                BrokerApplicant__r.Id,
                BrokerApplication__r.Id,
                BrokerApplication__r.Name
                FROM Document__c
                WHERE BrokerApplicant__c IN :applicantIds
            ];
            
            allDocuments.addAll(applicantDocs);
        }
        
        return allDocuments;
    }
    
    public List<Document__c> getDocumentsByIds(Set<Id> documentIds) {
        if (documentIds != null && !documentIds.isEmpty()) {
            return [SELECT Id, BrokerApplication__c,BrokerApplicant__c,Case__c FROM Document__c WHERE Id IN :documentIds];
        }
        return new List<Document__c>();
    }
    
    public List<Document__c> getDocumentByAccountIds(Set<Id> accountIds) {
        if (accountIds != null && !accountIds.isEmpty()) {
            return [
                SELECT Id, Document_Name__c, Account__c,DocumentType__c
                FROM Document__c
                WHERE Account__c IN :accountIds
            ];
        }
        return new List<Document__c>();
    }
    
    public List<Document__c> getDocumentsByAccountIds(Set<Id> accountIds) {
        if (accountIds == null || accountIds.isEmpty()) {
            return new List<Document__c>();
        }
        
        return [
            SELECT Id,Account__c,Case__c,BrokerApplication__c,DocumentType__c,
            Document_Name__c,
            FileName__c,
            FileSizeMB__c,
            FileType__c,
            ContentDocumentId__c,
            Content_Version_Id__c
            FROM Document__c
            WHERE Account__c IN :accountIds
        ];
    }
    
    public List<Document__c> getDocumentsByBrokerApplicantIds(Set<Id> brokerAppIds) {
        if (brokerAppIds != null && !brokerAppIds.isEmpty()) {
            return [
                SELECT Id, Document_Name__c, BrokerApplicant__c,BrokerApplication__c, ContentDocumentId__c, 
                Content_Version_Id__c, FileName__c, FileSizeMB__c, FileType__c
                FROM Document__c
                WHERE BrokerApplicant__c IN :brokerAppIds
            ];
        }
        return new List<Document__c>();
    }
    
    public List<Document__c> getDocumentsByCaseIds(Set<Id> caseIds) {
        if (caseIds != null && !caseIds.isEmpty()) {
            return [
                SELECT Id,
                Document_Name__c,
                Case__c,
                ContentDocumentId__c,
                Content_Version_Id__c,
                FileName__c,
                FileSizeMB__c,
                FileType__c
                FROM Document__c
                WHERE Case__c IN :caseIds
            ];
        }
        return new List<Document__c>();
    }
    
    
    public List<Document__c> getDocumentsByBrokerApplicationIds(Set<Id> brokerAppIds) {
        if (brokerAppIds != null && !brokerAppIds.isEmpty()) {
            return [
                SELECT Id, Document_Name__c, BrokerApplicant__c,BrokerApplication__c, ContentDocumentId__c, 
                Content_Version_Id__c, FileName__c, FileSizeMB__c, FileType__c
                FROM Document__c
                WHERE BrokerApplication__c IN :brokerAppIds
            ];
        }
        return new List<Document__c>();
    }
    
    public List<ContentVersion> getContentVersionsByIds(Set<Id> contentVersionIds) {
        if (contentVersionIds != null && !contentVersionIds.isEmpty()) {
            return [
                SELECT Id, Title, VersionData, FileExtension
                FROM ContentVersion
                WHERE Id IN :contentVersionIds
            ];
        }
        return new List<ContentVersion>();
    }
    
    public List<Document__c> getDocumentsByContactIds(Set<Id> contactIds) {
        if (contactIds != null && !contactIds.isEmpty()) {
            return [
                SELECT Id, Document_Name__c, Contact__c
                FROM Document__c
                WHERE Contact__c IN :contactIds
            ];
        }
        return new List<Document__c>();
    }
    
    
    public List<Document__c> getBappDocuments(Set<Id> parentIds) {
        return [
            SELECT Id, DocumentType__c,DocumentType__r.Type__c, BrokerApplication__c, BrokerApplicant__c,Content_Version_Id__c, ContentDocumentId__c
            FROM Document__c WHERE BrokerApplication__c IN :parentIds OR BrokerApplicant__c IN :parentIds OR Case__c IN :parentIds
        ];
    }
    
    public List<Document__c> getLeasingOfferDocumentsByContractIds(Set<Id> contractIds) {
        return [ SELECT Id , LeasingOrder__c, Document_Name__c 
                FROM Document__c WHERE LeasingOrder__c IN :contractIds AND Document_Name__c = 'Leasing Offer'];
    }
    
    public List<Document__c> getLeasingSignedDocumentsByContractIds(Set<Id> contractIds) {
        return [ SELECT Id, LeasingOrder__c, Content_Version_Id__c
                FROM Document__c
                WHERE LeasingOrder__c IN :contractIds
                AND Document_Name__c = 'Leasing Contract - Signed'];
    }
    
    public List<Document__c> getDocumentsByOpportunityId(Id opportunityId) {
        return [SELECT Id, Name, Document_Name__c FROM Document__c
                WHERE Opportunity__c = :opportunityId AND Document_Name__c != null];
    }
    
    public List<Document__c> getDocumentsByLeasingOrderId(Id leasingOrderId) {
        return [SELECT Id, Name, Document_Name__c FROM Document__c 
                WHERE LeasingOrder__c = :leasingOrderId AND Document_Name__c != null];
    }
    
    //Pranav
    public List<Document__c> getRequiredLeasingOrderDocument(Id leasingOrderId, String docName){
        return [SELECT Id, Name, Document_Name__c, LeasingOrder__c, ContentDocumentId__c FROM Document__c 
                WHERE LeasingOrder__c = :leasingOrderId AND Document_Name__c = :docName];
    }
    //Pranav
    public List<Document__c> getRequiredLeasingReceiptAckDocument(Id leasingOrderId, String docName){
        return [SELECT Id, Name, Document_Name__c, LeasingReceiptAcknowledgment__c, ContentDocumentId__c FROM Document__c 
                WHERE LeasingReceiptAcknowledgment__c = :leasingOrderId AND Document_Name__c = :docName];
    }
    
    public  List<Document__c> getLeasingOfferDocumentsByOppIdAndCategory(Id recordId,String category) {
        List<Document__c> result = [SELECT Id, Name, Document_Name__c FROM Document__c
                                    WHERE Document_Name__c =:category AND ( Opportunity__c =:recordId ) ];
        
        return result ;
    }
    
    //Pranav
    public List<Document__c> getCaseDocumentsByName(Id recordId,set<String> docNames) {
        return [SELECT Id, Name, Document_Name__c,ContentDocumentId__c, DocumentType__r.Type__c, Content_Version_Id__c
                FROM Document__c WHERE Case__c = :recordId and Document_Name__c IN :docNames];
    }
    
    public List<Document__c> getExistingDocumentsByCaseId(Set<Id> caseIds) {
        return [
            SELECT Id,
            ContentDocumentId__c,
            DocumentType__c,
            DocumentType__r.ObjectType__c, DocumentType__r.Type__c,
            Content_Version_Id__c,
            Document_Name__c,
            FileName__c,
            FileSizeMB__c,
            FileType__c,
            BrokerApplication__r.Name,
            BrokerApplication__r.Id,
            Case__c
            FROM Document__c
            WHERE Case__c IN :caseIds
        ];
    }
    public List<Document__c> getDocumentByContactIds(Set<Id> contactIds) {
        if (contactIds == null || contactIds.isEmpty()) {
            return new List<Document__c>();
        }
        
        return [
            SELECT Id, Contact__c, Case__c, BrokerApplication__c, DocumentType__c,BrokerApplicant__c,
            Document_Name__c,
            FileName__c,
            FileSizeMB__c,
            FileType__c,
            ContentDocumentId__c,
            Content_Version_Id__c
            FROM Document__c
            WHERE Contact__c IN :contactIds
        ];
    }
    
    public List<Document__c> getCommissionDocumentsByName(Id recordId,List<String> docNames) {
        return [SELECT Id, ContentDocumentId__c, Document_Name__c
                FROM Document__c
                WHERE BrokerCommission__c = :recordId
                AND Document_Name__c IN :docNames];
    }

    public List<Document__c> getDocumentByParentIdAndType(Id parentId, String documentType) {
        List<Document__c> objDocumentList = new List<Document__c>();
        if(parentId.getSObjectType() == AppRegistration__c.SobjectType){
            objDocumentList = [SELECT Id, Name, ContentDocumentId__c, DocumentType__r.Type__c, Content_Version_Id__c
                               FROM Document__c WHERE AppRegistration__c = :parentId
                               AND DocumentType__r.Type__c = :documentType];
        }else if(parentId.getSObjectType() == SalesOrder__c.SobjectType){
            objDocumentList = [SELECT Id, Name, ContentDocumentId__c, DocumentType__r.Type__c, Content_Version_Id__c
                               FROM Document__c WHERE SalesOrder__c = :parentId
                               AND DocumentType__r.Type__c = :documentType];
        }else if(parentId.getSObjectType() == Account.SobjectType){
            objDocumentList = [SELECT Id, Name, ContentDocumentId__c, DocumentType__r.Type__c, Content_Version_Id__c
                               FROM Document__c WHERE Account__c = :parentId
                               AND DocumentType__r.Type__c = :documentType];
        }
        return objDocumentList;
    }

    //Get App Documents by record id
    public List<Document__c> getAppDocumentsByParentId(Id recordId) {
        List<Document__c> documentList = new List<Document__c>();
        if(recordId.getSObjectType() == Account.SobjectType){
            documentList = [SELECT Id, Name, Document_Name__c, DocumentType__c, ContentDocumentId__c,
                            CreatedDate, CreatedById, CreatedBy.Name,
                            DocumentType__r.ShareWithCustomer__c, DocumentType__r.IsSystemUpload__c,
                            DocumentType__r.MultiDocuments__c, DocumentType__r.Type__c
                            FROM Document__c WHERE Account__c = :recordId AND DocumentType__r.IsAvailableForApp__c = true];
        }else if(recordId.getSObjectType() == Contact.SobjectType){
            documentList = [SELECT Id, Name, Document_Name__c, DocumentType__c, ContentDocumentId__c,
                            CreatedDate, CreatedById, CreatedBy.Name,
                            DocumentType__r.ShareWithCustomer__c, DocumentType__r.IsSystemUpload__c,
                            DocumentType__r.MultiDocuments__c, DocumentType__r.Type__c
                            FROM Document__c WHERE Project__c = :recordId AND DocumentType__r.IsAvailableForApp__c = true];
        }
        return documentList;
    }
    //Commented below method for deployment
    public List<Document__c> getDocumentsByParentId(Id recordId) {
        List<Document__c> documentList = new List<Document__c>();
        if(recordId.getSObjectType() == Account.SobjectType){
            documentList = [SELECT Id, Name, Document_Name__c, DocumentType__c, ContentDocumentId__c,
                            CreatedDate, CreatedById, CreatedBy.Name,
                            DocumentType__r.ShareWithCustomer__c, DocumentType__r.IsSystemUpload__c,
                            DocumentType__r.MultiDocuments__c
                            FROM Document__c WHERE Account__c = :recordId];
        }
        if(recordId.getSObjectType() == Project__c.SobjectType){
            documentList = [SELECT Id, Name, Document_Name__c, DocumentType__c, ContentDocumentId__c,
                            CreatedDate, CreatedById, CreatedBy.Name,
                            DocumentType__r.ShareWithCustomer__c, DocumentType__r.IsSystemUpload__c,
                            DocumentType__r.MultiDocuments__c
                            FROM Document__c WHERE Project__c = :recordId];
        }
        if(recordId.getSObjectType() == SalesOrder__c.SobjectType){
            documentList = [SELECT Id, Name, SalesOrder__c, Document_Name__c, DocumentType__c, ContentDocumentId__c,
                            CreatedDate, CreatedById, CreatedBy.Name,
                            DocumentType__r.ShareWithCustomer__c, DocumentType__r.IsSystemUpload__c,
                            DocumentType__r.MultiDocuments__c
                            FROM Document__c WHERE SalesOrder__c = :recordId];
        }
        else if(recordId.getSObjectType() == Unit__c.SobjectType){
            documentList = [SELECT Id, Name, Unit__c, Document_Name__c, DocumentType__c, ContentDocumentId__c,
                            CreatedDate, CreatedById, CreatedBy.Name,
                            DocumentType__r.ShareWithCustomer__c, DocumentType__r.IsSystemUpload__c,
                            DocumentType__r.MultiDocuments__c
                            FROM Document__c WHERE Unit__c = :recordId];
        }
        else if(recordId.getSObjectType() == BrokerCommission__c.SobjectType){
            documentList = [SELECT Id, Name, Unit__c, Document_Name__c, DocumentType__c, ContentDocumentId__c,
                            CreatedDate, CreatedById, CreatedBy.Name,
                            DocumentType__r.ShareWithCustomer__c, DocumentType__r.IsSystemUpload__c,
                            DocumentType__r.MultiDocuments__c
                            FROM Document__c WHERE BrokerCommission__c = :recordId];
        }else if(recordId.getSObjectType() == AppRegistration__c.SobjectType){
            documentList = [SELECT Id, Name, Unit__c, Document_Name__c, DocumentType__c, ContentDocumentId__c,
                            CreatedDate, CreatedById, CreatedBy.Name,
                            DocumentType__r.ShareWithCustomer__c, DocumentType__r.IsSystemUpload__c,
                            DocumentType__r.MultiDocuments__c, DocumentType__r.Type__c
                            FROM Document__c WHERE AppRegistration__c = :recordId];
        }
        return documentList;
    }
    
    
    public List<Document__c> getDocumentsWithContentDocIds(Set<Id> documentIds) {
        if (documentIds == null || documentIds.isEmpty()) {
            return new List<Document__c>();
        }
        
        return [
            SELECT Id, ContentDocumentId__c
            FROM Document__c
            WHERE Id IN :documentIds
            AND ContentDocumentId__c != null
        ];
    }
    
    public Document__c getDocumentByIdBAPP(Id documentId) {
        List<Document__c> docs = [SELECT Name, ContentDocumentId__c, DocumentType__r.Type__c, Content_Version_Id__c, Account__c, Project__c, Case__c, Case__r.AccountId, BrokerCommission__c, BrokerCommission__r.SalesOrder__r.Opportunity__r.AccountId, Contact__c, Contact__r.AccountId,BrokerApplicant__c,BrokerApplicant__r.BrokerApplication__c,BrokerApplication__c FROM Document__c WHERE Id = :documentId LIMIT 1];
        return (docs.isEmpty()) ? null : docs[0];
    }
    
    
    public List<Document__c> getDocumentsByParentIdsAndType(Set<Id> recordIds, String documentType, Schema.SObjectType sObjType){
        List<Document__c> documentList = new List<Document__c>();
        
        if (sObjType == Handover__c.SobjectType) {
            return [SELECT Id, Document_Name__c, ContentDocumentId__c, Project__c, Handover__c, DocumentType__r.Type__c
                    FROM Document__c 
                    WHERE DocumentType__r.Type__c = :documentType 
                    AND Handover__c IN :recordIds];
        }
        else if (sObjType == Project__c.SobjectType) {
            return [ SELECT Id, Document_Name__c, ContentDocumentId__c, Project__c, Handover__c, DocumentType__r.Type__c
                    FROM Document__c 
                    WHERE DocumentType__r.Type__c = :documentType 
                    AND Project__c IN :recordIds];
        }
        else if (sObjType == HandoverPhase__c.SobjectType) {
            return [ SELECT Id, Document_Name__c, HandoverPhase__c,ContentDocumentId__c, Project__c, Handover__c, DocumentType__r.Type__c
                    FROM Document__c 
                    WHERE DocumentType__r.Type__c = :documentType 
                    AND HandoverPhase__c IN :recordIds];
        }
        
        
        return documentList;
    }
    
    public List<ContentVersion> insertContentVersions(List<ContentVersion> contentVersionList) {
        if (contentVersionList != null && !contentVersionList.isEmpty()) {
            insert contentVersionList; 
        }
        return contentVersionList;   
    }
    
    public List<ContentVersion> getInsertedContentVersions(Set<Id> versionIds) {
        if (versionIds == null || versionIds.isEmpty()) {
            return new List<ContentVersion>();
        }
        return [SELECT Id, ContentDocumentId, PathOnClient, FirstPublishLocationId FROM ContentVersion WHERE Id IN :versionIds];
    }
    
    
    public Map<Id, Map<String, Document__c>> getDocumentsByParentIds(Set<Id> recordIds, Schema.SObjectType sObjType){
        Map<Id, Map<String, Document__c>> parentIdToDocumentListMap = new Map<Id, Map<String, Document__c>>();
        
        if (sObjType == SalesOrder__c.SobjectType) {
            for(Document__c objDocument :[SELECT Id, Document_Name__c, ContentDocumentId__c, Project__c, SalesOrder__c, DocumentType__r.Type__c
                                          FROM Document__c  WHERE SalesOrder__c IN :recordIds]){
                                              Map<String, Document__c> documentMap = new Map<String, Document__c>();
                                              if (!parentIdToDocumentListMap.containsKey(objDocument.SalesOrder__c)) {
                                                  documentMap.put(objDocument.DocumentType__r.Type__c, objDocument);
                                              }else{
                                                  documentMap = parentIdToDocumentListMap.get(objDocument.SalesOrder__c);
                                                  if(!documentMap.containsKey(objDocument.DocumentType__r.Type__c)){
                                                      documentMap.put(objDocument.DocumentType__r.Type__c, objDocument);
                                                  }
                                              }
                                              parentIdToDocumentListMap.put(objDocument.SalesOrder__c, documentMap);
                                          }
        }else  if (sObjType == Handover__c.SobjectType) {
                    for(Document__c objDocument :[SELECT Id, Document_Name__c, ContentDocumentId__c, Project__c, Handover__c, DocumentType__r.Type__c
                                          FROM Document__c  WHERE Handover__c IN :recordIds]){
                                              Map<String, Document__c> documentMap = new Map<String, Document__c>();
                                              if (!parentIdToDocumentListMap.containsKey(objDocument.Handover__c)) {
                                                  documentMap.put(objDocument.DocumentType__r.Type__c, objDocument);
                                              }else{
                                                  documentMap = parentIdToDocumentListMap.get(objDocument.Handover__c);
                                                  if(!documentMap.containsKey(objDocument.DocumentType__r.Type__c)){
                                                      documentMap.put(objDocument.DocumentType__r.Type__c, objDocument);
                                                  }
                                              }
                                              parentIdToDocumentListMap.put(objDocument.Handover__c, documentMap);
                                          }
        }
        return parentIdToDocumentListMap;
    }
    
    public List<Document__c> getLeasingSignDocuments(Set<Id> leasingOrderIds, List<String> documentList){
        return [SELECT Id, LeasingOrder__c, Document_Name__c, ContentDocumentId__c, Content_Version_Id__c
            FROM Document__c
            WHERE LeasingOrder__c IN :leasingOrderIds
            AND Document_Name__c IN :documentList];
    }
   
    public List<DocumentType__c> getDocTypesByTypeNames(
        String objectType,
        List<String> typeNames
    ) {
        if (typeNames == null || typeNames.isEmpty()) {
            return new List<DocumentType__c>();
        }
        
        return [
            SELECT Id, Name, Type__c, ObjectType__c,
            Project__c, BrokerContactRole__c,
            IsDocgen__c, Active__c,
            DigitalSignature__c,
            TypeofEstablishment__c, Resale__c
            FROM DocumentType__c
            WHERE ObjectType__c = :objectType
            AND Type__c IN :typeNames
            AND Active__c = true
        ];
    }
    public List<Document__c> getCaseDocumentsWithFiles(Id caseId) {
        return [
            SELECT Id, Document_Name__c, ContentDocumentId__c
            FROM Document__c
            WHERE Case__c = :caseId
            AND ContentDocumentId__c != null
            AND Document_Name__c IN :requiredDocNames
        ];
    }
    public List<Document__c> getSalesOrderDocuments(Id salesOrderId) {
        return [
            SELECT Id, Document_Name__c, ContentDocumentId__c
            FROM Document__c
            WHERE SalesOrder__c = :salesOrderId
            AND Document_Name__c IN :requiredDocNames
        ];
    }
    public List<DocumentType__c> getSuqurAlWatanDocumentTypes(Id accountI) {
        return [
            SELECT Id, Name, Type__c 
            FROM DocumentType__c 
            WHERE Type__c = :SUQUR_AL_WATAN_DOC_TYPE
            AND Active__c = true
        ];
    }

    public Document__c getPaymentPlanDocumentByName(Id paymentPlanScheduleId,String docNames) {
        return [SELECT Id
            FROM Document__c
            WHERE PaymentPlanSchedule__c  = :paymentPlanScheduleId
            AND Document_Name__c = :docNames
            LIMIT 1];
    }

    public Document__c getOtherChargeDocumentByName(Id ocId,String docNames) {
        return [SELECT Id
            FROM Document__c
            WHERE LeasingOrdersOtherCharges__c  = :ocId
            AND Document_Name__c = :docNames
            LIMIT 1];
    }
    
    public Map<Id, Map<String, Document__c>>getSalesOrderDocumentsByTypes(Set<Id> salesOrderIds,List<String> documentTypes){
        Map<Id, Map<String, Document__c>> result = new Map<Id, Map<String, Document__c>>();
        for(Document__c doc : [SELECT Id,SalesOrder__c,ContentDocumentId__c,Content_Version_Id__c,FileName__c,DocumentType__r.Type__c
                               FROM Document__c WHERE SalesOrder__c IN :salesOrderIds AND DocumentType__r.Type__c IN :documentTypes AND ContentDocumentId__c != null]){
                                   if(!result.containsKey(doc.SalesOrder__c)){
                                       result.put(doc.SalesOrder__c,new Map<String, Document__c>());
                                   }
                                   result.get(doc.SalesOrder__c).put(doc.DocumentType__r.Type__c, doc);
                               }
        return result;
    }
}