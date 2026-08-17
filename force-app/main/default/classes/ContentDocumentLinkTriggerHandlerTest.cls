@IsTest
public class ContentDocumentLinkTriggerHandlerTest {

    
    @IsTest
    static void testgetProjects() {
     ContentVersion contentVersion = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestDoc.pdf',
            VersionData = Blob.valueOf('Test content'),
            IsMajorVersion = true
        );
        insert contentVersion;
          ContentVersion insertedVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id];
        String contentDocumentId = insertedVersion.ContentDocumentId;
                Customer_Document__c custDocs=BCAPP_TestDataFactory.createCustomerDocument();
        insert custDocs;
        ContentDocumentLink documentLink = new ContentDocumentLink(
            ContentDocumentId = contentDocumentId,
            LinkedEntityId = custDocs.Id,
            ShareType = 'V', // Viewer access
            Visibility = 'AllUsers'
        );
        insert documentLink;
        update documentLink;
        delete documentLink;
        
}
}