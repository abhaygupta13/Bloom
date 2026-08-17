/*****************************************************************************************
Class       : DocumentArchiveService
Author      : Ranjan
Description : Service class for DocumentArchive__c object
TestClass   : DocumentArchiveServiceTest
Created Date: 27 Apr 2026
------------------------------------------------------------------------------------------
-- History --
------------------------------------------------------------------------------------------
Sr.No.  Version         Date            Details
1.      V1.0            27 Apr 2026       
*****************************************************************************************/
public class DocumentArchiveService {
    
    private static DocumentArchiveService instance;
    
    private DocumentArchiveService() {
        
    }
    
    public static DocumentArchiveService getInstance() { 
        if(instance == null) {
            instance = new DocumentArchiveService();
        }
        return instance;
    }
    
    public List<DocumentArchive__c> insertdocumentArchives(
        List<DocumentArchive__c> documentArchiveList
    ) {
        if(documentArchiveList != null && !documentArchiveList.isEmpty()) {
            insert documentArchiveList;
        }
        return documentArchiveList;
    }
    
    public List<DocumentArchive__c> getDocumentArchiveByDocumentId(Id documentId) {
        return [
            SELECT Id, 
                   Name, 
                   Document__c, 
                   ContentDocumentId__c, 
                   LastModifiedDate, 
                   CreatedDate, 
                   LastModifiedBy.Name
            FROM DocumentArchive__c 
            WHERE Document__c = :documentId 
            ORDER BY CreatedDate DESC
        ];
    }
}