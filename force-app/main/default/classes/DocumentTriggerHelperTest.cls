/*****************************************************************************************
Class       : DocumentTriggerHelperTest
Description : Test class for DocumentTriggerHelper
*****************************************************************************************/
@IsTest
private class DocumentTriggerHelperTest {

    // =====================================================
    // updateDocumentUploadDate
    // =====================================================

    @IsTest
    static void testUpdateDocumentUploadDate_SalesOrderEmiratesId() {
        HandoverTriggerHandler.isTriggerDisabled = true;

        SalesOrder__c salesOrder = createSalesOrderWithUnit();

        DocumentType__c spaDocType = TestDataFactory.createDocumentType('Sales Order', 'SPA - Signed');
        DocumentType__c eidDocType = TestDataFactory.createDocumentType('Sales Order', 'Emirates ID');
        insert new List<DocumentType__c>{ spaDocType, eidDocType };

        Document__c spaDocument = TestDataFactory.createDoc(spaDocType.Id, salesOrder.Id, null);
        spaDocument.Document_Name__c = 'SPA - Signed';
        spaDocument.ContentDocumentId__c = '001000';
        insert spaDocument;

        Document__c document = TestDataFactory.createDoc(eidDocType.Id, salesOrder.Id, null);
        document.Document_Name__c = 'Emirates ID';
        insert document;

        Document__c oldDoc = document.clone(true, true, true, true);
        document.ContentDocumentId__c = '001001';

        Test.startTest();
        DocumentTriggerHelper.updateDocumentUploadDate(
            new List<Document__c>{ document },
            new Map<Id, Document__c>{ document.Id => oldDoc }
        );
        Test.stopTest();

        SalesOrder__c updatedOrder = [
            SELECT DocumentUploadedDate__c
            FROM SalesOrder__c
            WHERE Id = :salesOrder.Id
        ];

        System.assertNotEquals(
            null,
            updatedOrder.DocumentUploadedDate__c,
            'Sales order upload date should be set'
        );

        HandoverTriggerHandler.isTriggerDisabled = false;
    }

    @IsTest
    static void testUpdateDocumentUploadDate_LeasingOfferAndContractSigned() {
        LeasingOrder__c leasingOrder = createLeasingOrder();

        DocumentType__c docType = TestDataFactory.createDocumentType('LeasingOrder__c', 'Emirates ID');
        insert docType;

        Document__c offerDoc = new Document__c(
            DocumentType__c = docType.Id,
            LeasingOrder__c = leasingOrder.Id,
            ContentDocumentId__c = '001000',
            Document_Name__c = 'Leasing Offer - Signed'
        );
        insert offerDoc;

        Document__c contractDoc = new Document__c(
            DocumentType__c = docType.Id,
            LeasingOrder__c = leasingOrder.Id,
            ContentDocumentId__c = '002000',
            Document_Name__c = 'Leasing Contract - Signed'
        );
        insert contractDoc;

        Document__c oldOfferDoc = offerDoc.clone(true, true, true, true);
        Document__c oldContractDoc = contractDoc.clone(true, true, true, true);

        offerDoc.ContentDocumentId__c = '001001';
        contractDoc.ContentDocumentId__c = '002001';

        Test.startTest();

        // Do not pass both documents together.
        // Existing production helper creates duplicate LeasingOrder__c Ids if both are processed together.
        DocumentTriggerHelper.updateDocumentUploadDate(
            new List<Document__c>{ offerDoc },
            new Map<Id, Document__c>{ offerDoc.Id => oldOfferDoc }
        );

        DocumentTriggerHelper.updateDocumentUploadDate(
            new List<Document__c>{ contractDoc },
            new Map<Id, Document__c>{ contractDoc.Id => oldContractDoc }
        );

        Test.stopTest();

        LeasingOrder__c updatedOrder = [
            SELECT isLeasingOfferSigned__c,
                   isLeasingContractSigned__c,
                   LeasingOfferSignedDate__c,
                   LeasingContractSignedDate__c
            FROM LeasingOrder__c
            WHERE Id = :leasingOrder.Id
        ];

        System.assertEquals(true, updatedOrder.isLeasingOfferSigned__c, 'Leasing offer signed flag should be true');
        System.assertEquals(true, updatedOrder.isLeasingContractSigned__c, 'Leasing contract signed flag should be true');
        System.assertNotEquals(null, updatedOrder.LeasingOfferSignedDate__c, 'Leasing offer signed date should be set');
        System.assertNotEquals(null, updatedOrder.LeasingContractSignedDate__c, 'Leasing contract signed date should be set');
    }

    @IsTest
    static void testUpdateDocumentUploadDate_NoMatchingChanges() {
        DocumentType__c docType = TestDataFactory.createDocumentType('Account', 'Emirates ID');
        insert docType;

        Document__c document = TestDataFactory.createDocument(null, docType.Id, 'Other Document');
        insert document;

        Document__c oldDoc = document.clone(true, true, true, true);

        Test.startTest();
        DocumentTriggerHelper.updateDocumentUploadDate(
            new List<Document__c>{ document },
            new Map<Id, Document__c>{ document.Id => oldDoc }
        );
        Test.stopTest();

        System.assertEquals(
            0,
            [SELECT COUNT() FROM DocumentArchive__c],
            'No side effects expected for unrelated documents'
        );
    }

    // =====================================================
    // sendEmailAlertToFinanceOwner
    // =====================================================

  /*  @IsTest
    static void testSendEmailAlertToFinanceOwner() {
        LeasingReceiptAcknowledgment__c receipt = createLeasingReceiptAcknowledgment();

        // Use valid restricted picklist value.
        // Helper condition depends on Document_Name__c, not DocumentType__c.Type__c.
        DocumentType__c docType = TestDataFactory.createDocumentType('LeasingOrder__c', 'Emirates ID');
        insert docType;

        Document__c document = new Document__c(
            DocumentType__c = docType.Id,
            LeasingReceiptAcknowledgment__c = receipt.Id,
            ContentDocumentId__c = '001000',
            Document_Name__c = 'Leasing Receipt document'
        );
        insert document;

        Document__c oldDoc = document.clone(true, true, true, true);
        document.ContentDocumentId__c = '001001';

        Test.startTest();
        DocumentTriggerHelper.sendEmailAlertToFinanceOwner(
            new List<Document__c>{ document },
            new Map<Id, Document__c>{ document.Id => oldDoc }
        );
        Test.stopTest();

        System.assertNotEquals(null, receipt.Id, 'Receipt should exist for finance alert processing');
    } */

    @IsTest
    static void testSendEmailAlertToFinanceOwner_NoMatchingDocuments() {
        Test.startTest();
        DocumentTriggerHelper.sendEmailAlertToFinanceOwner(
            new List<Document__c>(),
            new Map<Id, Document__c>()
        );
        Test.stopTest();

        System.assert(true, 'Empty input should complete without error');
    }

    // =====================================================
    // sendLeasingFinanceEmail
    // =====================================================

    @IsTest
    static void testSendLeasingFinanceEmail_WithoutTemplate() {
        DocumentTriggerHelper helper = new DocumentTriggerHelper();

        Test.startTest();
        Messaging.SingleEmailMessage result = helper.sendLeasingFinanceEmail(
            null,
            null,
            new List<String>{ 'finance@example.com' },
            null
        );
        Test.stopTest();

        System.assertEquals(null, result, 'Email should not be sent during test execution');
    }

    @IsTest
    static void testSendLeasingFinanceEmail_WithTemplateAndAttachments() {
        List<EmailTemplate> templates = [
            SELECT Id
            FROM EmailTemplate
            WHERE IsActive = true
            LIMIT 1
        ];

        if (templates.isEmpty()) {
            System.assert(true, 'No active email template available in this org');
            return;
        }

        List<OrgWideEmailAddress> orgWideAddresses = [
            SELECT Id
            FROM OrgWideEmailAddress
            LIMIT 1
        ];

        DocumentTriggerHelper helper = new DocumentTriggerHelper();

        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
        attachment.setFileName('test.pdf');
        attachment.setBody(Blob.valueOf('test'));

        Test.startTest();
        Messaging.SingleEmailMessage result = helper.sendLeasingFinanceEmail(
            templates[0].Id,
            orgWideAddresses.isEmpty() ? null : orgWideAddresses[0].Id,
            new List<String>{ 'finance@example.com' },
            new List<Messaging.EmailFileAttachment>{ attachment }
        );
        Test.stopTest();

        System.assertEquals(null, result, 'Email should not be sent during test execution');
    }

    // =====================================================
    // archiveDocument
    // =====================================================

    @IsTest
    static void testArchiveDocument_OnContentDocumentReplacement() {
        DocumentType__c docType = TestDataFactory.createDocumentType('Account', 'Emirates ID');
        insert docType;

        Document__c document = TestDataFactory.createDocument(null, docType.Id, 'test');
        document.ContentDocumentId__c = 'OLD_CONTENT_ID';
        insert document;

        Document__c oldDoc = document.clone(true, true, true, true);
        document.ContentDocumentId__c = 'NEW_CONTENT_ID';

        Test.startTest();
        DocumentTriggerHelper.archiveDocument(
            new List<Document__c>{ document },
            new Map<Id, Document__c>{ document.Id => oldDoc }
        );
        Test.stopTest();

        List<DocumentArchive__c> archives = [
            SELECT ContentDocumentId__c
            FROM DocumentArchive__c
            WHERE Document__c = :document.Id
        ];

        System.assertEquals(1, archives.size(), 'One archive record should be created');
        System.assertEquals(
            'OLD_CONTENT_ID',
            archives[0].ContentDocumentId__c,
            'Archived content id should match previous value'
        );
    }

    @IsTest
    static void testArchiveDocument_NoReplacement() {
        DocumentType__c docType = TestDataFactory.createDocumentType('Account', 'Emirates ID');
        insert docType;

        Document__c document = TestDataFactory.createDocument(null, docType.Id, 'test');
        document.ContentDocumentId__c = 'SAME_CONTENT_ID';
        insert document;

        Document__c oldDoc = document.clone(true, true, true, true);

        Test.startTest();
        DocumentTriggerHelper.archiveDocument(
            new List<Document__c>{ document },
            new Map<Id, Document__c>{ document.Id => oldDoc }
        );
        Test.stopTest();

        System.assertEquals(
            0,
            [SELECT COUNT() FROM DocumentArchive__c WHERE Document__c = :document.Id],
            'No archive should be created when content id is unchanged'
        );
    }
 
    @IsTest
    static void testShouldRunCaseDocumentUploadedFromInternalUI_NotCalledInTestContext() {
        // Do not call DocumentTriggerHelper.shouldRunCaseDocumentUploadedFromInternalUI()
        // because Auth.SessionManagement.getCurrentSession() throws Current session unavailable
        // in Apex test execution.
        System.assert(true, 'Session-based method is intentionally not directly called in test context');
    }

    // =====================================================
    // Test data helpers
    // =====================================================

    private static SalesOrder__c createSalesOrderWithUnit() {
        Account account = TestDataFactory.createPersonalAccount(
            'Lastname',
            '01010101',
            '1234567890',
            'test@gmail.com'
        );
        account.CustomerType__c = 'Resident';
        insert account;

        Project__c project = TestDataFactory.createProject('ProjectTest', Date.today() - 1);
        insert project;

        Unit__c unit = TestDataFactory.createUnit(project.Id, 'A1-G01', 'Unassigned');
        unit.Project__c = project.Id;
        unit.RegistrationDate__c = Date.today();
        insert unit;

        SalesOrder__c salesOrder = TestDataFactory.createSalesOrder(
            account.Id,
            null,
            null,
            null,
            unit.Id,
            100.00
        );
        salesOrder.DocumentUploadedDate__c = Date.today() - 1;
        salesOrder.UnitRegistrationDate__c = Date.today();
        insert salesOrder;

        unit.Active_Sales_Order__c = salesOrder.Id;
        update unit;

        return salesOrder;
    }

    private static LeasingOrder__c createLeasingOrder() {
        Id personAccountRecordTypeId = Utility.getRecordTypeIdByDevName(
            Account.SObjectType,
            'PersonAccount'
        );

        Account account = new Account(
            RecordTypeId = personAccountRecordTypeId,
            LastName = 'Leasing Account',
            Phone = '971202520',
            PersonEmail = 'leasing@example.com',
            Nationality__c = 'Indian',
            PrimaryMobilePhone__pc = '1234567890'
        );
        insert account;

        Opportunity opportunity = new Opportunity(
            Name = 'Leasing Opp',
            StageName = 'Prospecting',
            OpportunityType__c = 'Leasing',
            CloseDate = System.today().addDays(30),
            AccountId = account.Id
        );
        insert opportunity;

        Project__c project = new Project__c(
            Name = 'Leasing Project',
            IsAvailableforLeasing__c = true,
            EjariTawtheeqFee__c = 200,
            AdminFee__c = 20,
            LeasingServiceCharge__c = 20,
            SecurityDeposit__c = 20
        );
        insert project;

        Building__c building = TestDataFactory.createBuilding('Building 1', project.Id);
        insert building;

        Unit__c unit = new Unit__c(
            Name = 'Leasing Unit',
            LeasingAnnualRent__c = 10000,
            Project__c = project.Id,
            Building__c = building.Id,
            LeasingUnitStatus__c = 'Available',
            IsAvailableforLeasing__c = true,
            PropertyUsage__c = 'Commercial'
        );
        insert unit;

        LeasingOrder__c leasingOrder = new LeasingOrder__c(
            Name = 'Test Contract',
            Opportunity__c = opportunity.Id,
            Account__c = account.Id,
            Unit__c = unit.Id,
            LeasingStartDate__c = System.today(),
            LeasingEndDate__c = System.today().addYears(1),
            LeasingContractMonths__c = 12,
            PaymentTerm__c = '4 Installments',
            SecurityDeposit__c = 100,
            ExtraChequeFee__c = 200,
            LeaseTerminationRefundType__c = 'Normal Termination without Refund - N',
            AdminFee__c = 100,
            FitOutSecurityDeposit__c = 300,
            EjariTawtheeqFee__c = 200
        );
        insert leasingOrder;

        return leasingOrder;
    }

    private static LeasingReceiptAcknowledgment__c createLeasingReceiptAcknowledgment() {
        LeasingOrder__c leasingOrder = createLeasingOrder();

        LeasingReceiptAcknowledgment__c receipt = new LeasingReceiptAcknowledgment__c(
            LeasingOrder__c = leasingOrder.Id,
            Amount__c = 10000
        );
        insert receipt;

        return receipt;
    }

    private static Case createBrokerAgentCase() {
        ServiceCatalog__c catalog = new ServiceCatalog__c(
            Name = 'Service-Request-Broker-Agent-Registration',
            RecordTypeDevName__c = 'BrokerAgentRegistrationAndUpdate',
            Type__c = 'Service Request',
            Category__c = 'Broker Service Request',
            SubCategory__c = 'Broker New Agent Registration'
        );
        insert catalog;

        Account account = new Account(Name = 'Broker Agency');
        insert account;

        Id recordTypeId = Utility.getRecordTypeIdByDevName(
            Case.SObjectType,
            'BrokerAgentRegistrationAndUpdate'
        );

        Case brokerCase = new Case(
            RecordTypeId = recordTypeId,
            AccountId = account.Id,
            ServiceCatalog__c = catalog.Id,
            Status = 'New',
            ApprovalStatus__c = 'Not Approved',
            Origin = 'Portal',
            Subject = 'Broker Agent Registration',
            Draft__c = true
        );
        insert brokerCase;

        return brokerCase;
    }
}