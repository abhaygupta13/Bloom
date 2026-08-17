@isTest
private class ContentDocumentLinkServiceTest {

    @testSetup
    static void setupTestData() {
        // Create a parent record (Account)
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create a ContentVersion (automatically creates a ContentDocument)
        ContentVersion cv = new ContentVersion(
            Title = 'Generated Invoice',
            PathOnClient = 'Invoice.pdf',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert cv;
        
        //  Requery to get the ContentDocumentId
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];

        // Get the related ContentDocument
        ContentDocument cd = [
            SELECT Id, LatestPublishedVersionId
            FROM ContentDocument
            WHERE Id = :cv.ContentDocumentId
            LIMIT 1
        ];

        // Create a ContentDocumentLink for Account
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = cd.Id,
            LinkedEntityId = acc.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert cdl;

        // Create BrokerApplication__c record
        BrokerApplication__c app = new BrokerApplication__c(Name = 'BrokerAppTest');
        insert app;

        // Create ContentDocumentLink for BrokerApplication
        ContentDocumentLink cdlApp = new ContentDocumentLink(
            ContentDocumentId = cd.Id,
            LinkedEntityId = app.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert cdlApp;

        // Create Document__c record with matching Document_Name__c
        Document__c doc = new Document__c(Document_Name__c = 'Generated Invoice');
        insert doc;
        
        // Create ContentDocumentLink for Document__c (optional, only if you want a match)
        ContentDocumentLink cdlDoc = new ContentDocumentLink(
            ContentDocumentId = cd.Id,
            LinkedEntityId = doc.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert cdlDoc;
    }

    
    @isTest
    static void testInsertGetDeleteContentDocumentLinks() {
        ContentDocumentLinkService service = ContentDocumentLinkService.getInstance();
        
        // Use a different Account to avoid duplicate link
        Account acc2 = new Account(Name = 'Test Account 2');
        insert acc2;
        
        ContentDocument cd = [SELECT Id FROM ContentDocument LIMIT 1];
        
        ContentDocumentLink newCdl = new ContentDocumentLink(
            ContentDocumentId = cd.Id,
            LinkedEntityId = acc2.Id, // avoid duplicate
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        
        // Test insert
        List<ContentDocumentLink> insertedLinks =
            service.insertContentDocumentLinkWithTrigger(new List<ContentDocumentLink>{ newCdl });
        System.assertEquals(1, insertedLinks.size(), 'Link should be inserted successfully');
        
        // Test getcontentDocumentLinksByIds
        List<ContentDocumentLink> fetchedLinks =
            service.getcontentDocumentLinksByIds(new Set<Id>{ acc2.Id });
        System.assertNotEquals(0, fetchedLinks.size(), 'Should return ContentDocumentLinks for Account');
        
        // Test delete
        List<ContentDocumentLink> deletedLinks = service.deleteContentDocumentLinks(insertedLinks);
        System.assertEquals(1, deletedLinks.size(), 'Inserted link should be deleted successfully');
    }
    
    
    @isTest
    static void testGetContentDocumentsByIds() {
        ContentDocumentLinkService service = ContentDocumentLinkService.getInstance();
        ContentDocument doc = [SELECT Id FROM ContentDocument LIMIT 1];
        
        List<ContentDocument> docs = service.getContentDocumentsByIds(new Set<Id>{ doc.Id });
        System.assertEquals(1, docs.size(), 'Should return one ContentDocument');
    }
    
    @isTest
    static void testGetBrokerFileLinksByBrokerAppIds() {
        ContentDocumentLinkService service = ContentDocumentLinkService.getInstance();
        BrokerApplication__c app = [SELECT Id FROM BrokerApplication__c LIMIT 1];
        
        List<ContentDocumentLink> links = service.getBrokerFileLinksByBrokerAppIds(new Set<Id>{ app.Id });
        System.assertNotEquals(0, links.size(), 'Should return BrokerApplication links');
    }
    
    @isTest
    static void testGetExistingAccountLinks() {
        ContentDocumentLinkService service = ContentDocumentLinkService.getInstance();
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        List<ContentDocumentLink> links = service.getExistingAccountLinks(new Set<Id>{ acc.Id });
        System.assertNotEquals(0, links.size(), 'Should return existing Account links');
    }
    
    @isTest
    static void testGetLatestContentDocumentLinkByRecordAndTitle() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        ContentDocumentLink result =
            ContentDocumentLinkService.getLatestContentDocumentLinkByRecordAndTitle(acc.Id, 'Generated%');
        System.assertNotEquals(null, result, 'Should fetch latest link by title pattern');
    }

    @isTest
    static void testGetLatestContentDocumentLinkByRecordAndName() {
        Document__c doc = [SELECT Id,Document_Name__c FROM Document__c LIMIT 1];
        Test.startTest();
        ContentDocumentLink result =
            ContentDocumentLinkService.getLatestContentDocumentLinkByRecordAndName(doc.Id, 'Generated Invoice');
        Test.stopTest();
        System.assertEquals(null, result,
            'Should return null since no link exists for the Document__c record');
    }
}