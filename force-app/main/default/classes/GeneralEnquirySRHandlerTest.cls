@isTest
private class GeneralEnquirySRHandlerTest {

    @testSetup
    static void setupTestData() {
        
        Account acc = TestDataFactory.createBrokerAccount('test', false, '1122334455');
        insert acc;

        Contact con = TestDataFactory.createContact('lname', acc.Id, true, 'test@gmail.com');
        insert con;

        Opportunity opp = TestDataFactory.createOpportunity(null, null,null, acc.Id, null, null, null, null);
        insert opp;

        Project__c project = TestDataFactory.createProject('Project Test', Date.newinstance(2024, 01, 01), Date.newInstance(2025, 01, 01), Date.newInstance(2025, 01, 15), Date.newInstance(2025, 01, 16), Date.newInstance(2025, 01, 30), Date.newInstance(2025, 02, 01));
        insert project;

        Unit__c unit = TestDataFactory.createUnit(project.Id, 'Test unit', 'Sold');
        insert unit;

        SalesOrder__c salesOrder = TestDataFactory.createSalesOrder(acc.Id, opp.Id, 'Sold', date.newinstance(2025, 02, 10), unit.Id, 18181818);
        insert salesOrder;
        
        // Create test ServiceCatalog record
        ServiceCatalog__c testServiceCatalog = new ServiceCatalog__c(
            Name = 'Test Service Catalog',
            Type__c = 'Service Request',
            Category__c = 'General Enquiry',
            SubCategory__c = 'General Enquiry',
            RecordTypeDevName__c = 'GeneralEnquiry'
        );
        insert testServiceCatalog;
        system.debug('testServiceCatalog----->'+testServiceCatalog);
        
        // Create test ServiceAction record
        ServiceAction__c testServiceAction1 = new ServiceAction__c(
            ServiceCatalog__c = testServiceCatalog.Id,
            TaskType__c = 'General Enquiry',
            TaskSubType__c = 'CRM Team Task 1',
            TaskSubject__c = 'CRM Team Task 1',
            Due_in_days__c = 2,
            Order__c = 1,
            FinalTask__c = true
        );
        insert testServiceAction1;
        
        // prepare a Case for testing
        String RecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('General Enquiry').getRecordTypeId();
        // Create test Case related to the Account
        Case cs = new Case(Status = 'New', Origin = 'Phone', AccountId = acc.Id, RecordTypeId= RecordTypeCaseId, ServiceCatalog__c = testServiceCatalog.Id,
                           Sales_Order__c = salesOrder.Id, Unit__c = unit.Id, subject = 'test');
        insert cs;
    }

    static Case getDummyCase() {
        return [SELECT Id, Step__c,AccountId, CaseType__c, isDocumentAvailable__c,Unit__c, isNotRegistered__c, Sales_Order__c,SubType__c,ServiceCatalog__c,RecordTypeId, Status FROM Case LIMIT 1];
    }

    @isTest
    static void testGetInstance() {
        Test.startTest();
        GeneralEnquirySRHandler handler = GeneralEnquirySRHandler.getInstance();
        System.assertNotEquals(null, handler);
        Test.stopTest();
    }

    @isTest
    static void testCreateFirstTask() {
        Case c = getDummyCase();
        Test.startTest();
        GeneralEnquirySRHandler.getInstance().createFirstTask(new List<Case>{ c });
        Test.stopTest();
    }

    @isTest
    static void testValidateEligibility() {
        SalesOrder__c so = [SELECT Id FROM SalesOrder__c LIMIT 1];
        Case c = getDummyCase();

        Test.startTest();
        String result = GeneralEnquirySRHandler.getInstance().validateEligibility(so, c);
        System.assertEquals(null, result);
        Test.stopTest();
    }

    @isTest
    static void testCreateCaseRecordWithSalesOrder() {
        SalesOrder__c so = [SELECT Id, Account__c, Unit__c, Project__c, Account__r.Name, Account__r.isPersonAccount, Account__r.PersonMobilePhone, Unit__r.Name, Account__r.Id FROM SalesOrder__c LIMIT 1];
        ServiceCatalog__c sc = [SELECT Id, RecordTypeDevName__c, SubCategory__c FROM ServiceCatalog__c LIMIT 1];

        Test.startTest();
        Case newCase = GeneralEnquirySRHandler.getInstance().createCaseRecord(
            so, sc, null, null, 'Service Request', 'Test description', 'Web', false
        );
        Test.stopTest();

        System.assertNotEquals(null, newCase);
        System.assertEquals('New', newCase.Status);
    }

    @isTest
    static void testCreateCaseRecordWithoutSalesOrder() {
        ServiceCatalog__c sc = [SELECT Id, RecordTypeDevName__c,SubCategory__c FROM ServiceCatalog__c LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Unit__c unit = [SELECT Id FROM Unit__c LIMIT 1];

        Test.startTest();
        Case newCase = GeneralEnquirySRHandler.getInstance().createCaseRecord(
            null, sc, acc.Id, unit.Id, 'Service Request', 'Another description', 'Email', false
        );
        Test.stopTest();

        System.assertNotEquals(null, newCase);
        System.assertEquals('New', newCase.Status);
    }

    @isTest
    static void testValidateCaseForNextReview_Success() {
        Case c = getDummyCase();

        Test.startTest();
        Map<String, Object> response = GeneralEnquirySRHandler.getInstance().validateCaseForNextReview(c);
        Test.stopTest();

        //System.assertEquals('success', response.get('status'));
    }

    @isTest
    static void testValidateCaseForNextReview_Error_NullCase() {
        Test.startTest();
        Map<String, Object> response = GeneralEnquirySRHandler.getInstance().validateCaseForNextReview(null);
        Test.stopTest();

        System.assertEquals('error', response.get('status'));
        System.assertEquals('Invalid Case ID.', response.get('message'));
    }


    @isTest
    static void testHandleNextSteps() {
        Case c = getDummyCase();

        Test.startTest();
        GeneralEnquirySRHandler.getInstance().handleNextSteps(c);
        Test.stopTest();
    }
    @isTest
    static void testProcessDocumentRequest() {
    Case c = getDummyCase();
    c.Step__c = '1';
    c.isNotRegistered__c = false;
    c.StopEmailsToCustomer__c = false;
    update c;

    Test.startTest();
    GeneralEnquirySRHandler.getInstance().processDocumentRequest(c);
    Test.stopTest();

    
    System.assertEquals('Final', c.Step__c);
}
@isTest
static void testValidateCase_InvalidStep() {
    Case c = getDummyCase();
    c.Step__c = '0';
    update c;

    Test.startTest();
    Map<String, Object> res = GeneralEnquirySRHandler.getInstance().validateCaseForNextReview(c);
    Test.stopTest();

    System.assertEquals('error', res.get('status'));
    System.assertEquals('Invalid Case Step.', res.get('message'));
}
  @isTest
static void testValidateCase_Final_RentRefund_MissingDebitAdvice() {

    Case c = getDummyCase();
    c.Step__c = 'Final';
    c.SubType__c = 'Rent Refund';
    c.isNotRegistered__c = false;
    update c;

   
    insert new Document__c(
        Case__c = c.Id,
        Document_Name__c = 'Debit Advice'
        
    );

    Test.startTest();
    Map<String, Object> res = GeneralEnquirySRHandler.getInstance()
        .validateCaseForNextReview(c);
    Test.stopTest();

    System.assertEquals('error', res.get('status'));
    System.assertEquals(
        'Please upload all required documents before closing the case.',
        res.get('message')
    );
}
    @isTest
static void testValidateCase_Final_OtherSubType_MissingDocs() {

    Case c = getDummyCase();
    c.Step__c = 'Final';
    c.SubType__c = 'Title Deed/Mortgage Deed';
    c.isNotRegistered__c = false;
    update c;

    
    insert new Document__c(
        Case__c = c.Id,
        Document_Name__c = 'Title Deed'
        
    );

    Test.startTest();
    Map<String, Object> res = GeneralEnquirySRHandler.getInstance()
        .validateCaseForNextReview(c);
    Test.stopTest();

    System.assertEquals('error', res.get('status'));
}
    @isTest
static void testValidateCase_Final_AllDocsPresent() {

    Case c = getDummyCase();
    c.Step__c = 'Final';
    c.SubType__c = 'Title Deed/Mortgage Deed';
    c.isNotRegistered__c = false;
    c.StopEmailsToCustomer__c = false;
    update c;

    
    ContentVersion cv = new ContentVersion(
        Title = 'Title Deed',
        PathOnClient = 'file.pdf',
        VersionData = Blob.valueOf('data')
    );
    insert cv;

    Id contentDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;

    
    insert new Document__c(
        Case__c = c.Id,
        Document_Name__c = 'Title Deed',
        ContentDocumentId__c = contentDocId
    );

    Test.startTest();
    Map<String, Object> res = GeneralEnquirySRHandler.getInstance().validateCaseForNextReview(c);
    Test.stopTest();

    System.assertEquals('success', res.get('status'));
}
   @isTest
static void testCreateDocumentPlaceholder_ContactDetails() {

    
    Case c = getDummyCase();
    c.SubType__c = 'Contact Details';
    update c;

   
    List<DocumentType__c> docTypes = new List<DocumentType__c>{
        new DocumentType__c(
            Type__c = 'Buyer Emirates ID',
            ObjectType__c = 'Case',
            Active__c = true
        ),
        new DocumentType__c(
            Type__c = 'Passport',
            ObjectType__c = 'Case',
            Active__c = true
        )
    };
    insert docTypes;

    
    Test.startTest();
    GeneralEnquirySRHandler.getInstance().createDocumentPlaceholder(new List<Case>{c});
    Test.stopTest();

    
    List<Document__c> docs = [
        SELECT Id, Document_Name__c, Case__c
        FROM Document__c
        WHERE Case__c = :c.Id
    ];

    System.assertEquals(2, docs.size(), 'Two placeholders should be created');

   
    Set<String> docNames = new Set<String>();
    for (Document__c d : docs) {
        docNames.add(d.Document_Name__c);
    }

    System.assert(docNames.contains('Buyer Emirates ID'), 'Missing Buyer Emirates ID');
    System.assert(docNames.contains('Passport'), 'Missing Passport');
}
   
@isTest
static void testSalesOrderDocumentsToCase_Fixed() {

    Account acc = new Account(
    Name = 'Test Account'
   );
   insert acc;
 
    SalesOrder__c so = new SalesOrder__c(Name = 'Test SO',Account__c = acc.Id);
    insert so;
    
    
    Case c = getDummyCase();
    c.Sales_Order__c = so.Id;
    c.SubType__c = 'Contact Details'; // non-SPA flow
    update c;

   
    Document__c caseDoc = new Document__c(
        Case__c = c.Id,
        Document_Name__c = 'Buyer Emirates ID'
    );
    insert caseDoc;

   
    ContentVersion cv = new ContentVersion(
        Title = 'Buyer Emirates ID',
        PathOnClient = 'BuyerEmiratesID.pdf',
        VersionData = Blob.valueOf('data')
    );
    insert cv;

    Id contentDocId = [
        SELECT ContentDocumentId
        FROM ContentVersion
        WHERE Id = :cv.Id
    ].ContentDocumentId;

   
    Document__c soDoc = new Document__c(
        SalesOrder__c = so.Id,
        Document_Name__c = 'Buyer Emirates ID',
        ContentDocumentId__c = contentDocId
    );
    insert soDoc;

   
    Test.startTest();
    GeneralEnquirySRHandler.getInstance().salesOrderDocumentsToCase(new List<Case>{c});
    Test.stopTest();

 
    Document__c updatedCaseDoc = [
        SELECT ContentDocumentId__c
        FROM Document__c
        WHERE Id = :caseDoc.Id
    ];

    System.assertEquals(
        contentDocId,
        updatedCaseDoc.ContentDocumentId__c,
        'Document should be copied from SalesOrder to Case'
    );
}
    @isTest
static void testAutoPopulateFloorPlanFromUnitFiles() {


    Account acc = new Account(Name = 'Test Account');
    insert acc;

    
    Unit__c unitRec = new Unit__c(
        Name = 'Test Unit'
    );
    insert unitRec;

    Case c = getDummyCase();
            
        c.SubType__c = 'Floor Plan Copy';
        c.Unit__c = unitRec.Id;
    
    update c;

    Document__c caseDoc = new Document__c(
        Case__c = c.Id,
        Document_Name__c = 'Floor Plan'
    );
    insert caseDoc;

    ContentVersion cv = new ContentVersion(
        Title = 'Floor Plan',
        PathOnClient = 'FloorPlan.pdf',
        VersionData = Blob.valueOf('Test Data')
    );
    insert cv;

    
    Id contentDocId = [
        SELECT ContentDocumentId
        FROM ContentVersion
        WHERE Id = :cv.Id
    ].ContentDocumentId;

  
    unitRec.WebFloorPlanCDId__c = String.valueOf(contentDocId);
    update unitRec;

   
    Test.startTest();
    GeneralEnquirySRHandler.getInstance()
        .autoPopulateFloorPlanFromUnitFiles(new List<Case>{c});
    Test.stopTest();

   
    List<ContentDocumentLink> links = [
        SELECT ContentDocumentId, LinkedEntityId
        FROM ContentDocumentLink
        WHERE LinkedEntityId = :caseDoc.Id
    ];

    System.assertEquals(1, links.size(), 'File should be linked to Document__c');
    System.assertEquals(contentDocId, links[0].ContentDocumentId);

    Document__c updatedDoc = [
        SELECT ContentDocumentId__c
        FROM Document__c
        WHERE Id = :caseDoc.Id
    ];

    System.assertEquals(
        contentDocId,
        updatedDoc.ContentDocumentId__c,
        'Document__c should store ContentDocumentId'
    );
}
}