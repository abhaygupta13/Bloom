@IsTest
private class NewOfferPDFControllerTest {
    private static final String OFFER_DOCUMENT_NAME = 'Leasing Offer';
    private static final String CONTRACT_NAME = 'Test Contract';

    @TestSetup
    static void dataSetup() {
        Account personAccount = createPersonAccount();
        createDocumentTypes();
        Opportunity opp = createOpportunity(personAccount.Id);
        Company__c leasingCompany = createLeasingCompany();
        Project__c project = createProject(leasingCompany.Id);
        Building__c building = TestDataFactory.createBuilding('Building 1', project.Id);
        insert building;
        Unit__c unit = createUnit(project.Id, building.Id);
        LeasingOrder__c leasingOrder = createLeasingOrder(
            opp.Id,
            personAccount.Id,
            unit.Id,
            project.Id
        );
        insert new Document__c(
            Document_Name__c = OFFER_DOCUMENT_NAME,
            LeasingOrder__c = leasingOrder.Id
        );
    }

    private static Account createPersonAccount() {
        Id personAccountRecordTypeId = Utility.getRecordTypeIdByDevName(
            Account.SObjectType,
            'PersonAccount'
        );
        Account acc = new Account(
            RecordTypeId = personAccountRecordTypeId,
            LastName = 'Test Person Account',
            Phone = '971202520',
            PersonEmail = 'abc@gmail.com',
            Nationality__c = 'Indian',
            PrimaryMobilePhone__pc = '1234567890',
            SecondaryMobilePhone__pc = '9876543210',
            TertiaryMobilePhone__pc = '1122334455'
        );
        insert acc;
        return acc;
    }

    private static void createDocumentTypes() {
        List<DocumentType__c> documentTypes = new List<DocumentType__c>();
        DocumentType__c dt1 = TestDataFactory.createDocumentType('Opportunity', 'Emirates ID');
        dt1.Customer_Type__c = 'Individual';
        documentTypes.add(dt1);
        DocumentType__c dt2 = TestDataFactory.createDocumentType('Opportunity', 'Visa');
        dt2.Customer_Type__c = 'Individual';
        documentTypes.add(dt2);
        DocumentType__c dt3 = TestDataFactory.createDocumentType('LeasingOrder__c', 'Emirates ID');
        dt3.Customer_Type__c = 'Individual';
        documentTypes.add(dt3);
        DocumentType__c dt4 = TestDataFactory.createDocumentType('LeasingOrder__c', 'Visa');
        dt4.Customer_Type__c = 'Individual';
        documentTypes.add(dt4);
        DocumentType__c dt5 = TestDataFactory.createDocumentType('LeasingOrder__c', OFFER_DOCUMENT_NAME);
        dt5.Customer_Type__c = 'Individual';
        documentTypes.add(dt5);
        DocumentType__c dt6 = TestDataFactory.createDocumentType('Opportunity', OFFER_DOCUMENT_NAME);
        dt6.Customer_Type__c = 'Individual';
        documentTypes.add(dt6);
        insert documentTypes;
    }

    private static Opportunity createOpportunity(Id accountId) {
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            OpportunityType__c = 'Leasing',
            CloseDate = System.today().addDays(30),
            AccountId = accountId
        );
        insert opp;
        return opp;
    }

    private static Company__c createLeasingCompany() {
        Company__c company = new Company__c(
            Name = 'Leasing Com 101',
            LeasingPostingClosureDate__c = Date.today()
        );
        insert company;
        return company;
    }

    private static Project__c createProject(Id companyId) {
        Project__c project = new Project__c(
            Name = 'Test Project',
            IsAvailableforLeasing__c = true,
            EjariTawtheeqFee__c = 200,
            AdminFee__c = 20,
            LeasingServiceCharge__c = 20,
            SecurityDeposit__c = 20,
            Leasing_Company__c = companyId
        );
        insert project;
        return project;
    }

    private static Unit__c createUnit(Id projectId, Id buildingId) {
        Unit__c unit = new Unit__c(
            Name = 'TestU',
            LeasingAnnualRent__c = 10000,
            Project__c = projectId,
            Building__c = buildingId,
            LeasingUnitStatus__c = 'Available',
            IsAvailableforLeasing__c = true,
            PropertyUsage__c = 'Commercial'
        );
        insert unit;
        return unit;
    }

    private static LeasingOrder__c createLeasingOrder(
        Id oppId,
        Id accountId,
        Id unitId,
        Id projectId
    ) {
        LeasingOrder__c lo = new LeasingOrder__c(
            Name = CONTRACT_NAME,
            Opportunity__c = oppId,
            Account__c = accountId,
            Unit__c = unitId,
            Project__c = projectId,
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
        insert lo;
        return lo;
    }

    @IsTest
    static void testGeneratePDF_Success() {
        LeasingOrder__c leasingOrder = [
            SELECT Id, Account__r.Name
            FROM LeasingOrder__c
            WHERE Name = :CONTRACT_NAME
            LIMIT 1
        ];
        Document__c offerDocument = [
            SELECT Id
            FROM Document__c
            WHERE LeasingOrder__c = :leasingOrder.Id
            AND Document_Name__c = :OFFER_DOCUMENT_NAME
            LIMIT 1
        ];

        Test.startTest();
        Id resultId = NewOfferPDFController.generatePDF(leasingOrder.Id);
        Test.stopTest();

        Assert.areEqual(
            leasingOrder.Id,
            resultId,
            'generatePDF should return the Leasing Order Id.'
        );

        List<ContentVersion> files = [
            SELECT Id, Title, PathOnClient, VersionData, FirstPublishLocationId
            FROM ContentVersion
            WHERE FirstPublishLocationId = :offerDocument.Id
        ];

        Assert.areEqual(
            1,
            files.size(),
            'Exactly one ContentVersion should be created.'
        );

        ContentVersion generatedFile = files[0];
        String expectedAccountName = leasingOrder.Account__r.Name;

        Assert.areEqual(
            expectedAccountName + ' - ' + OFFER_DOCUMENT_NAME,
            generatedFile.Title,
            'ContentVersion Title is incorrect.'
        );

        Assert.areEqual(
            expectedAccountName + '_LeasingOffer.pdf',
            generatedFile.PathOnClient,
            'ContentVersion PathOnClient is incorrect.'
        );

        Assert.isNotNull(
            generatedFile.VersionData,
            'VersionData should not be null.'
        );

        Assert.areEqual(
            offerDocument.Id,
            generatedFile.FirstPublishLocationId,
            'ContentVersion should be published to the Leasing Offer Document.'
        );
    }

    @IsTest
    static void testGeneratePDF_NullId_ThrowsException() {
        Test.startTest();
        try {
            NewOfferPDFController.generatePDF(null);
            Assert.fail('AuraHandledException should have been thrown for a null Id.');
        } catch (AuraHandledException e) {
        }
        Test.stopTest();
    }

    @IsTest
    static void testGeneratePDF_LeasingOrderNotFound_ThrowsException() {
        Opportunity opp = [
            SELECT Id
            FROM Opportunity
            WHERE Name = 'Test Opp'
            LIMIT 1
        ];

        Test.startTest();
        try {
            NewOfferPDFController.generatePDF(opp.Id);
            Assert.fail('AuraHandledException should have been thrown for an unknown Leasing Order Id.');
        } catch (AuraHandledException e) {
        }
        Test.stopTest();
    }

    @IsTest
    static void testLeasingOfferDocument_IsCreatedForLeasingOrder() {
        LeasingOrder__c leasingOrder = [
            SELECT Id
            FROM LeasingOrder__c
            WHERE Name = :CONTRACT_NAME
            LIMIT 1
        ];
        Document__c offerDocument = [
            SELECT Id, Document_Name__c, LeasingOrder__c
            FROM Document__c
            WHERE LeasingOrder__c = :leasingOrder.Id
            AND Document_Name__c = :OFFER_DOCUMENT_NAME
            LIMIT 1
        ];

        Assert.areEqual(
            OFFER_DOCUMENT_NAME,
            offerDocument.Document_Name__c,
            'Document_Name__c should be Leasing Offer.'
        );

        Assert.areEqual(
            leasingOrder.Id,
            offerDocument.LeasingOrder__c,
            'Document should be linked to the Leasing Order.'
        );
    }

    @IsTest
    static void testConstructorWithValidId() {
        LeasingOrder__c leasingOrder = [
            SELECT Id
            FROM LeasingOrder__c
            WHERE Name = :CONTRACT_NAME
            LIMIT 1
        ];

        Test.setCurrentPage(Page.NewOfferPDF);
        ApexPages.currentPage().getParameters().put(
            'id',
            String.valueOf(leasingOrder.Id)
        );

        Test.startTest();
        NewOfferPDFController controller = new NewOfferPDFController();
        Test.stopTest();

        Assert.isNotNull(controller);
        Assert.isNotNull(controller.wrapper);
    }

    @IsTest
    static void testConstructorWithoutId_ThrowsException() {
        Test.setCurrentPage(Page.NewOfferPDF);

        Test.startTest();
        try {
            new NewOfferPDFController();
            Assert.fail('AuraHandledException should have been thrown when Id is missing.');
        } catch (AuraHandledException e) {
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetRenewalOffer_Success() {
        LeasingOrder__c leasingOrder = [
            SELECT Id
            FROM LeasingOrder__c
            WHERE Name = :CONTRACT_NAME
            LIMIT 1
        ];

        Test.startTest();
        CommercialOfferWrapper wrapper =
            NewOfferPDFController.getRenewalOffer(leasingOrder.Id);
        Test.stopTest();

        Assert.isNotNull(wrapper);
        Assert.areEqual(
            Decimal.valueOf(100),
            wrapper.securityDeposit,
            'Security deposit should be populated.'
        );
        Assert.areEqual(
            Decimal.valueOf(300),
            wrapper.fitOutSecurity,
            'Fit-out security should be populated.'
        );
        Assert.areEqual(
            Date.today(),
            wrapper.renewalDate,
            'Renewal date should be populated.'
        );
        Assert.areEqual(
            Date.today().addYears(1),
            wrapper.renewalExpiry,
            'Renewal expiry should be populated.'
        );
        Assert.areEqual(
            '4 Installments',
            wrapper.termOfPayment,
            'Payment term should be populated.'
        );
    }

    @IsTest
    static void testGetRenewalOffer_NullId_ThrowsException() {
        Test.startTest();
        try {
            NewOfferPDFController.getRenewalOffer(null);
            Assert.fail('AuraHandledException should have been thrown for a null Id.');
        } catch (AuraHandledException e) {
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testFormatAmount() {
        Test.startTest();
        String s = NewOfferPDFController.formatAmount(10.00);
        s = NewOfferPDFController.formatAmount(null);
        Test.stopTest();
    }
}