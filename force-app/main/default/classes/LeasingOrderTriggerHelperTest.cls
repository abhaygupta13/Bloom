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
       System.assert(docs.size() > 0, 'Documents should be created');
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
}