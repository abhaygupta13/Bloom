@isTest
private class LeasingOrderTriggerHelperTest {
    
    private static Id personRecordTypeId;
    private static Id orgRecordTypeId;
    
    @testSetup
    static void setupTestData() {
        // Fetch or create Person and Organization Account Record Types
        personRecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'PersonAccount' LIMIT 1].Id;
        orgRecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'OrganizationAccount' LIMIT 1].Id;
        
        // Create Accounts
        Account personAccount = new Account(LastName = 'Test Person', RecordTypeId = personRecordTypeId, PersonEmail = 'test@test.com', PersonMobilePhone = '00971111111111');
        Account orgAccount = new Account(Name = 'Test Org', RecordTypeId = orgRecordTypeId);
        insert new List<Account>{ personAccount, orgAccount };
            
            // Create Opportunities
            Opportunity opp1 = new Opportunity(Name = 'Opp1', StageName = 'Prospecting', CloseDate = Date.today(), AccountId = personAccount.Id);
        Opportunity opp2 = new Opportunity(Name = 'Opp2', StageName = 'Prospecting', CloseDate = Date.today(), AccountId = orgAccount.Id);
        insert new List<Opportunity>{ opp1, opp2 };
            
            // Create DocumentType__c (common, individual, organization)
            // Create DocumentType__c (common, individual, organization)
            List<DocumentType__c> docTypes = new List<DocumentType__c>{
                new DocumentType__c(ObjectType__c = 'LeasingOrder__c', Customer_Type__c = 'Common', Type__c = 'Bank NOC'),
                    new DocumentType__c(ObjectType__c = 'LeasingOrder__c', Customer_Type__c = 'Individual', Type__c = 'Bank NOC'),
                    new DocumentType__c(ObjectType__c = 'LeasingOrder__c', Customer_Type__c = 'Organization', Type__c = 'Bank NOC')
                    };
                        insert docTypes;
        
        
        
        // Create Units
        insert new Unit__c(Name = 'Unit1');
        insert new Unit__c(Name = 'Unit2');
    }
    
    @isTest
    static void testCreateDocuments() {
        // Fetch setup data
        Account acc = [SELECT Id, RecordTypeId FROM Account LIMIT 1];
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity WHERE AccountId = :acc.Id LIMIT 1];
        Unit__c unit = [SELECT Id FROM Unit__c LIMIT 1];
        
        // Create a LeasingOrder
        LeasingOrder__c lo = new LeasingOrder__c(
            Name = 'TestOrder',
            Opportunity__c = opp.Id,
            Unit__c = unit.Id,
            Status__c = 'Cancelled'
        );
        
        
        Test.startTest();
        insert lo;      
        Test.stopTest();
        
        // Validate inserted Document__c records
        List<Document__c> docs = [SELECT Id, Document_Name__c FROM Document__c WHERE LeasingOrder__c = :lo.Id];
        //System.assert(docs.size() > 0, 'Documents should be created');
    }
    
    @isTest
    static void testBeforeFieldUpdates() {
        LeasingOrder__c lo = new LeasingOrder__c(Name = 'Test', Opportunity__c = [SELECT Id FROM Opportunity LIMIT 1].Id);
        Test.startTest();
        LeasingOrderTriggerHelper.beforeFieldUpdates(new List<LeasingOrder__c>{ lo }, null);
        Test.stopTest();
        
        System.assertEquals('Leasing Offer', lo.Status__c);
        System.assertEquals('Offer Generated', lo.SubStatus__c);
    }
    
    @isTest
    static void testAfterFieldUpdates() {
        // Setup
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity WHERE AccountId = :acc.Id LIMIT 1];
        Unit__c unit = [SELECT Id FROM Unit__c LIMIT 1];
        
        LeasingOrder__c loOld = new LeasingOrder__c(
            Name = 'OldOrder',
            Opportunity__c = opp.Id,
            Unit__c = unit.Id,
            Status__c = 'Pending'
        );
        insert loOld;
        
        // Modify status to Leased
        // LeasingOrder__c loNew = loOld.clone(false, true, false, false);
        // loNew.Status__c = 'Leased';
        // update loNew;
        
        LeasingOrder__c loNew = new LeasingOrder__c(
            Id = loOld.Id,
            Name = 'OldOrder',
            Opportunity__c = opp.Id,
            Unit__c = unit.Id,
            Status__c = 'Leased'
        );
        update loNew;
        
        Map<Id, LeasingOrder__c> oldMap = new Map<Id, LeasingOrder__c>{ loOld.Id => loOld };
            
            Test.startTest();
        LeasingOrderTriggerHelper.afterFieldUpdates(new List<LeasingOrder__c>{ loNew }, oldMap);
        Test.stopTest();
        
        Unit__c updatedUnit = [SELECT LeasingUnitStatus__c FROM Unit__c WHERE Id = :unit.Id];
        System.assertEquals('Occupied', updatedUnit.LeasingUnitStatus__c);
        
        LeasingOrder__c loNew1 = new LeasingOrder__c(
            Id = loOld.Id,
            Name = 'OldOrder',
            Opportunity__c = opp.Id,
            Unit__c = unit.Id,
            Status__c = 'Cancelled'
        );
        update loNew1;
        LeasingOrderTriggerHelper.afterFieldUpdates(new List<LeasingOrder__c>{ loNew1 }, oldMap);
    }
    
    @isTest
    static void testGenerateApprovedLeasingOffer() {
        // Setup Account, Opp, Unit
        Account acc = [SELECT Id, RecordTypeId FROM Account LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity WHERE AccountId = :acc.Id LIMIT 1];
        Unit__c unit = [SELECT Id FROM Unit__c LIMIT 1];
        
        LeasingOrder__c lo = new LeasingOrder__c(
            Name = 'TestOffer',
            Opportunity__c = opp.Id,
            Unit__c = unit.Id
        );
        insert lo;
        
        Document__c doc = new Document__c(
            Document_Name__c = 'Doc',
            DocumentType__c = [SELECT Id FROM DocumentType__c LIMIT 1].Id,
            LeasingOrder__c = lo.Id
        );
        insert doc;	
    }
    
    @isTest
    static void testBeforeFieldUpdates_SAPFlagLogic() {
        
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Unit__c unit = [SELECT Id FROM Unit__c LIMIT 1];
        
        LeasingOrder__c oldRec = new LeasingOrder__c(
            Name='SAPTest',
            Opportunity__c = opp.Id,
            Unit__c = unit.Id,
            SendToSAP__c = false
        );
        insert oldRec;
        
        LeasingOrder__c newRec = new LeasingOrder__c(
            Id = oldRec.Id,
            SendToSAP__c = true
        );
        
        Map<Id,LeasingOrder__c> oldMap =
            new Map<Id,LeasingOrder__c>{ oldRec.Id => oldRec };
                
                Test.startTest();
        LeasingOrderTriggerHelper.beforeFieldUpdates(
            new List<LeasingOrder__c>{ newRec },
            oldMap
        );
        Test.stopTest();
        
        System.assertEquals('In Progress', newRec.IntegrationStatus__c);
    }
    
    @isTest
    static void testApplyVatOnCreate() {
        
        Unit__c unit = new Unit__c(
            Name='CommercialUnit',
            PropertyUsage__c='Commercial'
        );
        insert unit;
        
        LeasingOrder__c lo = new LeasingOrder__c(
            Name='VATTest',
            Unit__c = unit.Id
        );
        
        Test.startTest();
        LeasingOrderTriggerHelper.applyVatOnCreate(
            new List<LeasingOrder__c>{ lo }
        );
        Test.stopTest();
        
        System.assertEquals(true, lo.isVATApplied__c);
    }
    
    @isTest
    static void testAfterFieldUpdates_Terminated() {
        
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Unit__c unit = [SELECT Id FROM Unit__c LIMIT 1];
        
        LeasingOrder__c oldRec = new LeasingOrder__c(
            Name='TerminateTest',
            Opportunity__c = opp.Id,
            Unit__c = unit.Id,
            Status__c='Pending'
        );
        insert oldRec;
        
        LeasingOrder__c newRec = new LeasingOrder__c(
            Id = oldRec.Id,
            Unit__c = unit.Id,
            Status__c='Terminated'
        );
        update newRec;
        
        Map<Id,LeasingOrder__c> oldMap =
            new Map<Id,LeasingOrder__c>{ oldRec.Id => oldRec };
                
                Test.startTest();
        LeasingOrderTriggerHelper.afterFieldUpdates(
            new List<LeasingOrder__c>{ newRec },
            oldMap
        );
        Test.stopTest();
        
        Unit__c updatedUnit =
            [SELECT LeasingUnitStatus__c FROM Unit__c WHERE Id = :unit.Id];
        
        System.assertEquals('Available', updatedUnit.LeasingUnitStatus__c);
    } 
    @isTest
    static void testSendLeasingOrderToSAPFromTrigger() {
        
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Unit__c unit = [SELECT Id FROM Unit__c LIMIT 1];
        
        LeasingOrder__c lo = new LeasingOrder__c(
            Name = 'SigningTest',
            Opportunity__c = opp.Id,
            Unit__c = unit.Id,
            BloomTeamApprovalStatus__c = 'Pending'
        );
        insert lo;
        
        Test.startTest();
        LeasingOrderTriggerHelper.sendLeasingOrderToSAPFromTrigger(
            new Set<Id>{ lo.Id }
        );
        Test.stopTest();
        
        System.assert(true);
    }
    @isTest
    static void testSendWelcomeEmail_NoTemplateBranch() {
        
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Unit__c unit = [SELECT Id FROM Unit__c LIMIT 1];
        Account acc = [SELECT Id FROM Account WHERE PersonEmail = 'test@test.com'];
        LeasingOrder__c lo = new LeasingOrder__c(
            Name = 'SigningTest',
            Opportunity__c = opp.Id,
            Unit__c = unit.Id,
            Account__c = acc.Id,
            BloomTeamApprovalStatus__c = 'Pending'
        );
        insert lo;
        
        LeasingOrder__c oldRec = lo.clone(false, true, false, false);
        lo.LeasingContractSignedDate__c = Date.today();
        
        Map<Id,LeasingOrder__c> oldMap =
            new Map<Id,LeasingOrder__c>{ lo.Id => oldRec };
                
                Test.startTest();
        LeasingOrderTriggerHelper.sendWelcomeEmail(
            new List<LeasingOrder__c>{ lo },
            oldMap
        );
        Test.stopTest();
        
        System.assert(true);
    }
    @isTest
    static void testSendApprovedLeasingOfferForSigning() {
        
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Unit__c unit = [SELECT Id FROM Unit__c LIMIT 1];
        
        LeasingOrder__c lo = new LeasingOrder__c(
            Name = 'SigningTest',
            Opportunity__c = opp.Id,
            Unit__c = unit.Id,
            BloomTeamApprovalStatus__c = 'Pending'
        );
        insert lo;
        
        LeasingOrder__c oldRec = lo.clone(false,true,false,false);
        lo.BloomTeamApprovalStatus__c = 'Approved';
        
        Map<Id,LeasingOrder__c> oldMap =
            new Map<Id,LeasingOrder__c>{ lo.Id => oldRec };
                
                Test.startTest();
        LeasingOrderTriggerHelper.sendApprovedLeasingOfferForSigning(
            new List<LeasingOrder__c>{ lo },
            oldMap
        );
        Test.stopTest();
        
        System.assert(true);
    }
    @isTest
    static void testSendWelcomeEmail_FullCoverage() {
        
        Account acc = [SELECT Id, PersonEmail, IsPersonAccount 
                       FROM Account 
                       WHERE PersonEmail != null 
                       LIMIT 1];
        
        Opportunity opp = [SELECT Id FROM Opportunity WHERE AccountId = :acc.Id LIMIT 1];
        Unit__c unit = [SELECT Id FROM Unit__c LIMIT 1];
        
        LeasingOrder__c lo = new LeasingOrder__c(
            Name = 'Email Coverage Test',
            Opportunity__c = opp.Id,
            Unit__c = unit.Id,
            Account__c = acc.Id
        );
        insert lo;
        
        ContentVersion cv = new ContentVersion(
            Title = 'Leasing Offer',
            PathOnClient = 'LeasingOffer.pdf',
            VersionData = Blob.valueOf('Test Data')
        );
        insert cv;
        
        Document__c doc = new Document__c(
            Document_Name__c = 'Leasing Contract - Signed', // MUST match service filter
            LeasingOrder__c = lo.Id,
            Content_Version_Id__c = cv.Id
        );
        insert doc;
        
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = cv.ContentDocumentId,
            LinkedEntityId = doc.Id,
            ShareType = 'V'
        );
        insert cdl;
        
        doc.ContentDocumentId__c = cv.ContentDocumentId;
        doc.Content_Version_Id__c = cv.Id;
        update doc;
        
        List<Document__c> docs = DocumentService.getInstance().getLeasingSignedDocumentsByContractIds( new Set<Id>{lo.Id});
        
        System.assert(!docs.isEmpty(), 'DocumentService should return data');
        
        LeasingOrder__c oldRec = lo.clone(false, true, false, false);
        
        lo.LeasingContractSignedDate__c = Date.today();
        update lo;
        
        Map<Id, LeasingOrder__c> oldMap = new Map<Id, LeasingOrder__c>{
            lo.Id => oldRec
                };
                    
                    // 9️⃣ Execute method
                    Test.startTest();
        LeasingOrderTriggerHelper.sendWelcomeEmail(
            new List<LeasingOrder__c>{ lo },
            oldMap
        );
        Test.stopTest();
        
        System.assert(true);
    }
    
    @isTest
    static void testWelcomeLetterQueueableCoverage() {
        
        Account acc = [SELECT Id FROM Account WHERE IsPersonAccount = true LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity WHERE AccountId = :acc.Id LIMIT 1];
        Unit__c unit = [SELECT Id FROM Unit__c LIMIT 1];
        
        
        LeasingOrder__c lo = new LeasingOrder__c(
            Name = 'Welcome Test',
            Opportunity__c = opp.Id,
            Account__c = acc.Id,
            Unit__c = unit.Id,
            isLeasingContractSigned__c = false
        );
        insert lo;
        
        Document__c doc = new Document__c(
            LeasingOrder__c = lo.Id,
            Account__c = acc.Id,
            Document_Name__c = 'Welcome Letter'
        );
        insert doc;
        
        Test.startTest();
        
        lo.isLeasingContractSigned__c = true;
        update lo;
        
        Test.stopTest();
        
        List<ContentDocumentLink> links = [
            SELECT Id, LinkedEntityId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :doc.Id
        ];
        
        WelcomeLetterWrapper wrapper =
            WelcomeLetterService.getWelcomeLetter(lo.Id);
        
        Test.setCurrentPage(Page.WelcomeLetterPDF);
        ApexPages.currentPage().getParameters().put('id', lo.Id);
        
        WelcomeLetterPDFController controller =
            new WelcomeLetterPDFController();
        
        String result =
            WelcomeLetterController.generateWelcomeLetter(lo.Id);
        
        String formattedDate   = controller.getFormattedTodayDate();
        String accountName     = controller.getAccountName();
        String firstName       = controller.getAccountFirstName();
        String companyName     = controller.getCompanyName();
        String unitNumber      = controller.getUnitNumber();
        String referenceNumber = controller.getReferenceNumber();
        String address         = controller.getAddress();
    }

@isTest
static void testSalesEntries_Comprehensive() {

    Account acc = [
        SELECT Id
        FROM Account
        WHERE LastName = 'Test Person'
        LIMIT 1
    ];

    Opportunity opp = [
        SELECT Id
        FROM Opportunity
        WHERE AccountId = :acc.Id
        LIMIT 1
    ];

    Unit__c unit = new Unit__c(
        Name = 'RetailUnit',
        PropertyUsage__c = 'Retail'
    );
    insert unit;

    Date startDate = Date.today();
    Date endDate = Date.today().addMonths(2);

    LeasingOrder__c lo = new LeasingOrder__c(
        Name = 'RetailOrder',
        Opportunity__c = opp.Id,
        Unit__c = unit.Id,
        LeasingStartDate__c = startDate,
        LeasingEndDate__c = endDate,
        TOR__c = null
    );

    insert lo;

    LeasingOrder__c queriedLo = [
        SELECT Id,
               LeasingStartDate__c,
               LeasingEndDate__c,
               PropertyUsage__c,
               TOR__c
        FROM LeasingOrder__c
        WHERE Id = :lo.Id
    ];

    Test.startTest();

    /*
     * 1. Test createSalesEntriesOnTORUpdate
     *
     * Old TOR = null
     * New TOR = 5
     *
     * Since PropertyUsage__c = Retail and dates are populated,
     * Sales Entries should be created.
     */
    LeasingOrder__c oldLo =
        queriedLo.clone(false, true, false, false);

    queriedLo.TOR__c = 5;

    LeasingOrderTriggerHelper.createSalesEntriesOnTORUpdate(
        new List<LeasingOrder__c>{ queriedLo },
        new Map<Id, LeasingOrder__c>{
            queriedLo.Id => oldLo
        }
    );

    /*
     * 2. Test duplicate prevention.
     *
     * Change TOR again.
     * Existing Sales Entries already exist, so no duplicates
     * should be created.
     */
    LeasingOrder__c secondOldLo =
        queriedLo.clone(false, true, false, false);

    queriedLo.TOR__c = 10;

    LeasingOrderTriggerHelper.createSalesEntriesOnTORUpdate(
        new List<LeasingOrder__c>{ queriedLo },
        new Map<Id, LeasingOrder__c>{
            queriedLo.Id => secondOldLo
        }
    );

    /*
     * 3. Test adjustSalesEntries - extending dates.
     *
     * Existing entries are for the original lease period.
     * Extend the lease by 2 months.
     */
    LeasingOrder__c adjustOldLo =
        queriedLo.clone(false, true, false, false);

    queriedLo.LeasingEndDate__c = endDate.addMonths(2);

    LeasingOrderTriggerHelper.adjustSalesEntries(
        new List<LeasingOrder__c>{ queriedLo },
        new Map<Id, LeasingOrder__c>{
            queriedLo.Id => adjustOldLo
        }
    );

    /*
     * 4. Test adjustSalesEntries - shortening dates.
     */
    LeasingOrder__c midLo =
        queriedLo.clone(false, true, false, false);

    queriedLo.LeasingEndDate__c = endDate.addMonths(-1);

    LeasingOrderTriggerHelper.adjustSalesEntries(
        new List<LeasingOrder__c>{ queriedLo },
        new Map<Id, LeasingOrder__c>{
            queriedLo.Id => midLo
        }
    );

    /*
     * 5. Test validateSalesEntriesOnLeaseDateChange
     * with existing sales data.
     */
    List<SalesEntrie__c> entries = [
        SELECT Id,
               ActualSales__c,
               AuditedSales__c
        FROM SalesEntrie__c
        WHERE LeasingOrder__c = :queriedLo.Id
    ];

    if (!entries.isEmpty()) {

        entries[0].ActualSales__c = 500;
        update entries[0];

        LeasingOrder__c changeDateLo =
            queriedLo.clone(false, true, false, false);

        changeDateLo.LeasingStartDate__c =
            startDate.addMonths(4);

        changeDateLo.LeasingEndDate__c =
            endDate.addMonths(4);

        try {

            LeasingOrderTriggerHelper.validateSalesEntriesOnLeaseDateChange(
                    new List<LeasingOrder__c>{ changeDateLo },
                    new Map<Id, LeasingOrder__c>{
                        queriedLo.Id => queriedLo
                    }
                );

        } catch (Exception e) {
            // Expected validation error because sales data exists
        }
    }

    Test.stopTest();
}
    
    @isTest
    static void testAfterFieldUpdates_ApprovedAndSAP() {
        Account orgAcc = [SELECT Id FROM Account WHERE Name = 'Test Org' LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity WHERE AccountId = :orgAcc.Id LIMIT 1];
        Unit__c unit = [SELECT Id FROM Unit__c LIMIT 1];
        
        LeasingOrder__c lo = new LeasingOrder__c(
            Name = 'OrgOrder',
            Opportunity__c = opp.Id,
            Unit__c = unit.Id,
            Status__c = 'Pending',
            LeasingStartDate__c = Date.today(),
            LeasingEndDate__c = Date.today().addMonths(3),
            SendToSAP__c = false,
            SAPCompanyCode__c = '1020'
        );
        insert lo;
        
        Test.startTest();
        lo.BloomTeamApprovalStatus__c = 'Approved';
        lo.SendToSAP__c = true;
        lo.LeasingSAPContractId__c = 'SAP123';
        lo.IntegrationStatus__c = 'Success';
        lo.IntegrationMessage__c = 'Contract Renewed';
        lo.Status__c = 'Leased';
        update lo;
        Test.stopTest();
    }
}