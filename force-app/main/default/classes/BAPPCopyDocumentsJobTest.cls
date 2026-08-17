@IsTest
private class BAPPCopyDocumentsJobTest {

    // -----------------------------------------------------
    // Helper: Get RecordTypeId by DeveloperName
    // -----------------------------------------------------
    private static Id getRecordTypeId(String sObjectName, String developerName) {
        return [SELECT Id FROM RecordType WHERE SObjectType = :sObjectName AND DeveloperName = :developerName LIMIT 1].Id;
    }

    // -----------------------------------------------------
    // Helper: Create a ContentVersion and return Id
    // -----------------------------------------------------
    private static Id createContentVersion(String title, Blob data) {
        ContentVersion cv = new ContentVersion(
            Title = title,
            PathOnClient = title + '.pdf',
            VersionData = data
        );
        insert cv;
        return cv.Id;
    }

    // -----------------------------------------------------
    // Helper: Create Document__c for given Case/Account/Contact
    // -----------------------------------------------------
    private static Document__c createDocument(Id caseId, Id accountId, Id contactId, String name, Id cvId) {
        Document__c doc = new Document__c(
            Document_Name__c = name,
            FileName__c = name + '.pdf',
            FileSizeMB__c = '5',
            FileType__c = 'PDF'
        );
        if (caseId != null) doc.Case__c = caseId;
        if (accountId != null) doc.Account__c = accountId;
        if (contactId != null) doc.Contact__c = contactId;
        if (cvId != null) doc.Content_Version_Id__c = cvId;
        insert doc;
        return doc;
    }

    // -----------------------------------------------------
    // TEST: Copy Documents from Case → Account
    // -----------------------------------------------------
    @IsTest
    static void testCopyDocumentsToAccount() {
        // Get RecordType Ids
        Id accRT = getRecordTypeId('Account', 'Broker_Agency');
        Id caseRT = getRecordTypeId('Case', 'Broker_Registration');

        // Create Account and Case
        Account acc = new Account(Name = 'Test Broker Agency', RecordTypeId = accRT);
        insert acc;

        Case cs = new Case(Subject = 'Broker Registration', RecordTypeId = caseRT, AccountId = acc.Id);
        insert cs;

        // Create ContentVersion for Case Document
        Id cvId = createContentVersion('BrokerCaseDoc', Blob.valueOf('test content'));

        // Create Case Document
        Document__c caseDoc = createDocument(cs.Id, null, null, 'License Proof', cvId);

        // Create Account Document (same name → will be copied)
        Document__c accDoc = createDocument(null, acc.Id, null, 'License Proof', null);

        // Map Case → Account
        Map<Id, Id> caseToAccountMap = new Map<Id, Id>{ cs.Id => acc.Id };

        // Execute Queueable Job
        Test.startTest();
        System.enqueueJob(new BAPPCopyDocumentsJob(caseToAccountMap, 'Account'));
        Test.stopTest();

        // Verify that Account Document now has copied fields and links
        accDoc = [SELECT Id,Account__c,Contact__c, FileName__c, FileSizeMB__c, FileType__c, Content_Version_Id__c, ContentDocumentId__c FROM Document__c WHERE Id = :accDoc.Id
        ];

        System.assertNotEquals(null, accDoc.Content_Version_Id__c, 'Account document should have ContentVersion linked.');
        System.assertNotEquals(null, accDoc.ContentDocumentId__c, 'Account document should have ContentDocument linked.');
        System.assertEquals('License Proof.pdf', accDoc.FileName__c);
        System.assertEquals('5', accDoc.FileSizeMB__c);
    }

    // -----------------------------------------------------
    // TEST: Copy Documents from Case → Contact
    // -----------------------------------------------------
    @IsTest
    static void testCopyDocumentsToContact() {
        // Get RecordType Ids
        Id contactRT = getRecordTypeId('Contact', 'Broker');
        Id caseRT = getRecordTypeId('Case', 'Broker_Registration');

        // Create Contact and Case
        Contact con = new Contact(FirstName = 'John', LastName = 'Doe', Email = 'john@broker.com', RecordTypeId = contactRT);
        insert con;

        Case cs = new Case(Subject = 'Broker Registration for Contact', RecordTypeId = caseRT);
        insert cs;

        // Create ContentVersion for Case Document
        Id cvId = createContentVersion('ContactCaseDoc', Blob.valueOf('contact data'));

        // Create Case Document
        Document__c caseDoc = createDocument(cs.Id, null, null, 'ID Proof', cvId);

        // Create Contact Document (to be updated)
        Document__c conDoc = createDocument(null, null, con.Id, 'ID Proof', null);

        // Map Case → Contact
        Map<Id, Id> caseToContactMap = new Map<Id, Id>{ cs.Id => con.Id };

        // Execute Queueable Job
        Test.startTest();
        System.enqueueJob(new BAPPCopyDocumentsJob(caseToContactMap, 'Contact'));
        Test.stopTest();

        // Verify updated Contact Document
        conDoc = [
            SELECT Id, FileName__c, FileSizeMB__c, FileType__c, 
                   Content_Version_Id__c, ContentDocumentId__c 
            FROM Document__c WHERE Id = :conDoc.Id
        ];

        System.assertNotEquals(null, conDoc.Content_Version_Id__c, 'Contact document should have ContentVersion linked.');
        System.assertNotEquals(null, conDoc.ContentDocumentId__c, 'Contact document should have ContentDocument linked.');
        System.assertEquals('ID Proof.pdf', conDoc.FileName__c);
    }

    // -----------------------------------------------------
    // TEST: Empty Map handling
    // -----------------------------------------------------
    @IsTest
    static void testEmptyMapHandling() {
        Test.startTest();
        System.enqueueJob(new BAPPCopyDocumentsJob(new Map<Id, Id>(), 'Account'));
        System.enqueueJob(new BAPPCopyDocumentsJob(new Map<Id, Id>(), 'Contact'));
        Test.stopTest();
        System.assert(true, 'Empty map execution should complete safely.');
    }
}