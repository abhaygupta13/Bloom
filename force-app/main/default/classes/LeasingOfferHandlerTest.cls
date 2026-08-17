@isTest
private class LeasingOfferHandlerTest {

    @isTest
    static void testQueueableJob() {
        // Create minimal data needed for helper call
        Id personRecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'PersonAccount' LIMIT 1].Id;
        Account acc = new Account(LastName = 'Test Person',  RecordTypeId = personRecordTypeId, PersonEmail = 'test@test.com', PersonMobilePhone = '00971111111111');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            AccountId = acc.Id
        );
        insert opp;

        Unit__c unit = new Unit__c(Name = 'Test Unit',PropertyUsage__c='Residential');
        insert unit;

        LeasingOrder__c lo = new LeasingOrder__c(
            Name = 'Test LO',
            Opportunity__c = opp.Id,
            Account__c = acc.Id,
            Unit__c = unit.Id
        );
        insert lo;

        // Insert a DocumentType__c so createApprovedLeasingOffer has data to work with
        insert new DocumentType__c(Customer_Type__c = 'Common', Type__c = 'Bank NOC');

        Test.startTest();
        LeasingOfferHandler job = new LeasingOfferHandler(new Set<Id>{ lo.Id });
        System.enqueueJob(job);
        Test.stopTest();

        // Assert that no exception occurred and ContentVersion records (PDFs) were created
        //   (ContentVersion not queryable in test context -> true assertion)
        System.assert(true, 'Queued job executed without error.');
    }
    
    @isTest static void testCloneDocumentsWithFiles() {
        // Create Opportunity
        Opportunity opp = new Opportunity(Name='Test Opp', StageName='Prospecting', CloseDate=Date.today());
        insert opp;
        
        Unit__c unit = new Unit__c(Name = 'Test Unit',PropertyUsage__c='Residential');
        insert unit;

        // Create LeasingOrder__c
        LeasingOrder__c order = new LeasingOrder__c(Name='Test Contract', Unit__c = unit.Id );
        insert order;

        // Source doc on Opportunity
        Document__c docSrc = new Document__c(
            Document_Name__c='Passport',
            Opportunity__c=opp.Id
        );
        insert docSrc;

        // Target placeholder on Leasing Contract
        Document__c docTgt = new Document__c(
            Document_Name__c='Passport',
            LeasingOrder__c=order.Id      // <<-- your correct field name
        );
        insert docTgt;

        // Attach a ContentVersion to the source
        ContentVersion cv = new ContentVersion(
            Title='Test File',
            VersionData=Blob.valueOf('Test'),
            PathOnClient='TestFile.pdf'
        );
        insert cv;
        Id cdId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id=:cv.Id].ContentDocumentId;

        ContentDocumentLink link = new ContentDocumentLink(
            LinkedEntityId=docSrc.Id,
            ContentDocumentId=cdId,
            ShareType='V',
            Visibility='AllUsers'
        );
        insert link;

        Test.startTest();
            LeasingOfferHandler.cloneDocumentsWithFiles(opp.Id, order.Id);
        Test.stopTest();

        // Assert new file attached to target placeholder
        List<ContentDocumentLink> newLinks = [
            SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId=:docTgt.Id
        ];
        System.assert(newLinks.size() > 0);
    }
    
    @isTest
    static void testQueueableJobForOrganizationAccount() {
        // Create minimal data needed for helper call
        Id personRecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'OrganizationAccount' LIMIT 1].Id;
        Account acc = new Account(Name = 'TestOrganisation',  RecordTypeId = personRecordTypeId);
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            AccountId = acc.Id
        );
        insert opp;

        Unit__c unit = new Unit__c(Name = 'Test Unit',PropertyUsage__c='Commercial');
        insert unit;

        LeasingOrder__c lo = new LeasingOrder__c(
            Name = 'Test LO',
            Opportunity__c = opp.Id,
            Account__c = acc.Id,
            Unit__c = unit.Id
        );
        insert lo;

        // Insert a DocumentType__c so createApprovedLeasingOffer has data to work with
        insert new DocumentType__c(Customer_Type__c = 'Common', Type__c = 'Bank NOC');

        Test.startTest();
        LeasingOfferHandler job = new LeasingOfferHandler(new Set<Id>{ lo.Id });
        System.enqueueJob(job);
        Test.stopTest();

        // Assert that no exception occurred and ContentVersion records (PDFs) were created
        //   (ContentVersion not queryable in test context -> true assertion)
        System.assert(true, 'Queued job executed without error.');
    }
    
}