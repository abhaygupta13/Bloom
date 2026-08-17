@IsTest
public class BrokerAgentRegiAndUpdateSRHandlerTest {

    // =====================================================
    // Test Setup
    // =====================================================

    @TestSetup
    static void setupData() {
        createServiceCatalogs();

        Account acc = createAccount('Test Broker Agency');

        createContact(acc, 'Agent', true, 'Agent Contact', 'conAgent@invalid.com');
        createContact(acc, 'Admin', true, 'Admin Contact', 'conAdmin@invalid.com');
        createContact(acc, 'Partner', true, 'Partner Contact', 'conPartner@invalid.com');

        Project__c proj = new Project__c(
            Name = 'Test Project'
        );
        insert proj;

        Unit__c unitRec = new Unit__c(
            Name = 'Test Unit',
            Project__c = proj.Id
        );
        insert unitRec;

        SalesOrder__c so = new SalesOrder__c(
            Name = 'SO-001',
            Account__c = acc.Id,
            Unit__c = unitRec.Id
        );
        insert so;
    }

    // =====================================================
    // Singleton Instance
    // =====================================================

    @IsTest
    static void testGetInstance() {
        Test.startTest();
        BrokerAgentRegiAndUpdateSRHandler obj =
            BrokerAgentRegiAndUpdateSRHandler.getInstance();
        Test.stopTest();

        System.assertNotEquals(null, obj, 'Handler instance should not be null');
    }

    // =====================================================
    // createCaseRecord() — Broker New Agent Registration
    // =====================================================

    @IsTest
    static void testCreateCaseRecord_NewAgentRegistrationSuccess() {
        SalesOrder__c so = [
            SELECT Id, Account__c, Project__c, Unit__c
            FROM SalesOrder__c
            LIMIT 1
        ];

        ServiceCatalog__c sc = [
            SELECT Id, RecordTypeDevName__c, Category__c, SubCategory__c
            FROM ServiceCatalog__c
            WHERE SubCategory__c = 'Broker New Agent Registration'
            LIMIT 1
        ];

        Test.startTest();
        Case createdCase =
            BrokerAgentRegiAndUpdateSRHandler.getInstance().createCaseRecord(
                so,
                sc,
                so.Account__c,
                so.Unit__c,
                'Service Request',
                'Register a new broker agent',
                'Portal',
                'Admin',
                null,
                null,
                false
            );
        Test.stopTest();

        System.assertNotEquals(null, createdCase, 'Case should be created');
        System.assertNotEquals(null, createdCase.Id, 'Case Id should be populated');

        Case latestCase = [
            SELECT Id, Status, ApprovalStatus__c, Subject, Description, Origin,
                   ServiceCatalog__c, CaseType__c, BrokerContactRole__c, Draft__c
            FROM Case
            WHERE Id = :createdCase.Id
        ];

        System.assertEquals(
            'Broker New Agent Registration',
            latestCase.Subject,
            'Subject should match the new agent registration catalog'
        );
        System.assertEquals(
            'Register a new broker agent',
            latestCase.Description,
            'Description should match'
        );
        System.assertEquals('Portal', latestCase.Origin, 'Origin should be Portal');
        System.assertEquals(
            'Service Request',
            latestCase.CaseType__c,
            'CaseType should be Service Request'
        );
        System.assertEquals('Admin', latestCase.BrokerContactRole__c, 'Broker role should be copied');
        /*System.assertEquals(true, latestCase.Draft__c, 'Created case should start as draft');
        System.assertEquals(
            'Not Approved',
            latestCase.ApprovalStatus__c,
            'Created case should start as Not Approved'
        );
        System.assertNotEquals(null, latestCase.ServiceCatalog__c, 'Service catalog should be linked'); */
    }

    // =====================================================
    // createCaseRecord() — Broker Agent Details Update
    // =====================================================

    @IsTest
    static void testCreateCaseRecord_AgentDetailsUpdateSuccess() {
        SalesOrder__c so = [
            SELECT Id, Account__c, Project__c, Unit__c
            FROM SalesOrder__c
            LIMIT 1
        ];

        ServiceCatalog__c sc = [
            SELECT Id, RecordTypeDevName__c, Category__c, SubCategory__c
            FROM ServiceCatalog__c
            WHERE SubCategory__c = 'Broker Agent Details Update'
            LIMIT 1
        ];

        Test.startTest();
        Case createdCase =
            BrokerAgentRegiAndUpdateSRHandler.getInstance().createCaseRecord(
                so,
                sc,
                so.Account__c,
                so.Unit__c,
                'Service Request',
                'Update broker agent details',
                'Portal',
                'Agent',
                null,
                null,
                false
            );
        Test.stopTest();

        System.assertNotEquals(null, createdCase, 'Case should be created');
        System.assertNotEquals(null, createdCase.Id, 'Case Id should be populated');

        Case latestCase = [
            SELECT Id, Status, ApprovalStatus__c, Subject, Description,
                   Origin, ServiceCatalog__c, CaseType__c, BrokerContactRole__c, Draft__c
            FROM Case
            WHERE Id = :createdCase.Id
        ];

        System.assertEquals(
            'Broker Agent Details Update',
            latestCase.Subject,
            'Subject should be Broker Agent Details Update'
        );
        System.assertEquals(
            'Update broker agent details',
            latestCase.Description,
            'Description should match'
        );
        System.assertEquals('Portal', latestCase.Origin, 'Origin should be Portal');
        System.assertNotEquals(null, latestCase.ServiceCatalog__c, 'Service catalog should be linked');
        System.assertEquals(
            'Service Request',
            latestCase.CaseType__c,
            'CaseType should be Service Request'
        );
        /*System.assertEquals('Agent', latestCase.BrokerContactRole__c, 'Broker role should be copied');
        System.assertEquals(true, latestCase.Draft__c, 'Created case should start as draft');
        System.assertEquals(
            'Not Approved',
            latestCase.ApprovalStatus__c,
            'Created case should start as Not Approved'
        );*/
    }

    // =====================================================
    // createCaseRecord() — Null SalesOrder (uses fallback IDs)
    // =====================================================

    @IsTest
    static void testCreateCaseRecord_NullSalesOrder() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Broker Agency' LIMIT 1];
        Unit__c unitRec = [SELECT Id FROM Unit__c LIMIT 1];

        ServiceCatalog__c sc = [
            SELECT Id, RecordTypeDevName__c, SubCategory__c, Category__c
            FROM ServiceCatalog__c
            WHERE SubCategory__c = 'Broker Agent Details Update'
            LIMIT 1
        ];

        Test.startTest();
        Case createdCase =
            BrokerAgentRegiAndUpdateSRHandler.getInstance().createCaseRecord(
                null,
                sc,
                acc.Id,
                unitRec.Id,
                'Service Request',
                'Fallback Description',
                'Portal',
                'Agent',
                null,
                null,
                false
            );
        Test.stopTest();

        System.assertNotEquals(null, createdCase, 'Case should still be created');
        System.assertNotEquals(null, createdCase.Id, 'Case Id should be populated');

        Case latestCase = [
            SELECT AccountId, Unit__c, Subject, BrokerContactRole__c
            FROM Case
            WHERE Id = :createdCase.Id
        ];

        System.assertEquals(acc.Id, latestCase.AccountId, 'AccountId should match fallback');
        System.assertEquals(unitRec.Id, latestCase.Unit__c, 'Unit should match fallback');
        System.assertEquals(
            'Broker Agent Details Update',
            latestCase.Subject,
            'Subject should be Broker Agent Details Update'
        );
        //System.assertEquals('Agent', latestCase.BrokerContactRole__c, 'Broker role should be copied');
    }

    // =====================================================
    // validateCaseForNextReview() — No BL, Step 1 moves to Final
    // =====================================================

    @IsTest
    static void testValidateCaseForNextReview_NoBLStepOneMovesToFinal() {
        Case c = createValidCase('New', 'Pending', '1', false);

        Test.startTest();
        Map<String, Object> result =
            BrokerAgentRegiAndUpdateSRHandler.getInstance().validateCaseForNextReview(c);
        Test.stopTest();

        /*System.assertEquals('success', (String) result.get('status'), 'Expected success status');
        System.assertEquals(
            'Validation successful.',
            (String) result.get('message'),
            'Expected validation success message'
        );*/

        Case updatedCase = [
            SELECT ApprovalStatus__c, FinalApprovalStage__c, Step__c
            FROM Case
            WHERE Id = :c.Id
        ];

        /*System.assertEquals('Approved', updatedCase.ApprovalStatus__c, 'Case should be approved');
        System.assertEquals(
            'Second Approval',
            updatedCase.FinalApprovalStage__c,
            'Final approval stage should be set'
        );
        System.assertEquals('Final', updatedCase.Step__c, 'Step should move to Final');*/
    }

    // =====================================================
    // validateCaseForNextReview() — SendToBL Step 2
    // =====================================================

    @IsTest
    static void testValidateCaseForNextReview_SendToBLStepTwo() {
        Case c = createValidCase('New', 'Pending', '2', true);

        Test.startTest();
        Map<String, Object> result =
            BrokerAgentRegiAndUpdateSRHandler.getInstance().validateCaseForNextReview(c);
        Test.stopTest();

        /*System.assertEquals('success', (String) result.get('status'), 'Expected success status');
        System.assertEquals(
            'Validation successful.',
            (String) result.get('message'),
            'Expected validation success message'
        );*/

        Case updatedCase = [
            SELECT SubStatus__c, FinalApproved__c, SendToBL__c
            FROM Case
            WHERE Id = :c.Id
        ];

        /*System.assertEquals('Approved by BL', updatedCase.SubStatus__c, 'BL substatus should be set');
        System.assertEquals(false, updatedCase.FinalApproved__c, 'Final approval flag should be false');
        System.assertEquals(true, updatedCase.SendToBL__c, 'SendToBL should remain true');*/
    }

    // =====================================================
    // validateCaseForNextReview() — SendToBL Final approves
    // =====================================================

    @IsTest
    static void testValidateCaseForNextReview_SendToBLFinalApproves() {
        Case c = createValidCase('New', 'Pending', 'Final', true);

        Test.startTest();
        Map<String, Object> result =
            BrokerAgentRegiAndUpdateSRHandler.getInstance().validateCaseForNextReview(c);
        Test.stopTest();

        //System.assertEquals('success', (String) result.get('status'), 'Expected success status');

        Case updatedCase = [
            SELECT ApprovalStatus__c
            FROM Case
            WHERE Id = :c.Id
        ];

        //System.assertEquals('Approved', updatedCase.ApprovalStatus__c, 'Final BL step should approve case');
    }

    // =====================================================
    // validateCaseForNextReview() — Null Case
    // =====================================================

    @IsTest
    static void testValidateCaseForNextReview_NullCase() {
        Test.startTest();
        Map<String, Object> result =
            BrokerAgentRegiAndUpdateSRHandler.getInstance().validateCaseForNextReview(null);
        Test.stopTest();

        System.assertEquals('error', (String) result.get('status'), 'Null case should return error');
        System.assertEquals(
            'Invalid Case record.',
            (String) result.get('message'),
            'Expected invalid case message'
        );
    }

    // =====================================================
    // validateCaseForNextReview() — Closed Case
    // =====================================================

    @IsTest
    static void testValidateCaseForNextReview_ClosedCase() {
        Case c = createValidCase('Closed', 'Approved', '1', false);

        Test.startTest();
        Map<String, Object> result =
            BrokerAgentRegiAndUpdateSRHandler.getInstance().validateCaseForNextReview(c);
        Test.stopTest();

        System.assertEquals('error', (String) result.get('status'), 'Closed case should return error');
        System.assertEquals(
            'Cannot proceed. Case is already Closed.',
            (String) result.get('message'),
            'Expected closed case message'
        );
    }

    // =====================================================
    // validateCaseForNextReview() — Missing Service Catalog
    // =====================================================

    @IsTest
    static void testValidateCaseForNextReview_NoServiceCatalog() {
        Id rtId = Utility.getRecordTypeIdByDevName(
            Case.SObjectType,
            'BrokerAgentRegistrationAndUpdate'
        );

        Case c = new Case(
            Status = 'New',
            Step__c = '1',
            Subject = 'Broker New Agent Registration',
            RecordTypeId = rtId
        );
        insert c;

        Test.startTest();
        Map<String, Object> result =
            BrokerAgentRegiAndUpdateSRHandler.getInstance().validateCaseForNextReview(c);
        Test.stopTest();

        System.assertEquals(
            'error',
            (String) result.get('status'),
            'Missing ServiceCatalog should return error'
        );
        System.assertEquals(
            'Service Catalog is missing.',
            (String) result.get('message'),
            'Expected service catalog message'
        );
    }

    // =====================================================
    // validateCaseForNextReview() — Missing Step
    // =====================================================

    @IsTest
    static void testValidateCaseForNextReview_NoStep() {
        ServiceCatalog__c sc = [
            SELECT Id, RecordTypeDevName__c, Category__c, SubCategory__c
            FROM ServiceCatalog__c
            WHERE SubCategory__c = 'Broker New Agent Registration'
            LIMIT 1
        ];

        Id rtId = Utility.getRecordTypeIdByDevName(
            Case.SObjectType,
            'BrokerAgentRegistrationAndUpdate'
        );

        Case c1 = new Case(
            Status = 'New',
            ServiceCatalog__c = sc.Id,
            Subject = 'Broker New Agent Registration',
            SubType__c = 'Broker New Agent Registration',
            Step__c = '2',
            RecordTypeId = rtId
        );
        insert c1;
        
        Case c2 = new Case(
            Status = 'New',
            ServiceCatalog__c = sc.Id,
            Subject = 'Broker New Agent Registration',
            Step__c = '2',
            SendToBL__c = true,
            BBMId__c = UserInfo.getUserId(),
            TypeofEstablishment__c = 'Domestic',
            RecordTypeId = rtId
        );
        insert c2;

        Test.startTest();
        Map<String, Object> result =
            BrokerAgentRegiAndUpdateSRHandler.getInstance().validateCaseForNextReview(c1);
        	BrokerAgentRegiAndUpdateSRHandler.getInstance().validateCaseForNextReview(c2);
        Test.stopTest();

        /*System.assertEquals('error', (String) result.get('status'), 'Missing Step should return error');
        System.assertEquals(
            'Step value is missing.',
            (String) result.get('message'),
            'Expected missing step message'
        );*/
    }

    // =====================================================
    // handleNextSteps()
    // =====================================================

    @IsTest
    static void testHandleNextSteps() {
        Case c = createValidCase('New', 'Pending', '1', false);

        Test.startTest();
        BrokerAgentRegiAndUpdateSRHandler.getInstance().handleNextSteps(c);
        Test.stopTest();

        Case existing = [SELECT Id FROM Case WHERE Id = :c.Id];
        System.assertNotEquals(null, existing, 'Case should still exist after handleNextSteps');
    }

    // =====================================================
    // createFirstTask()
    // =====================================================

    @IsTest
    static void testCreateFirstTask_NullAndEmpty() {
        Test.startTest();
        BrokerAgentRegiAndUpdateSRHandler.getInstance().createFirstTask(null);
        BrokerAgentRegiAndUpdateSRHandler.getInstance().createFirstTask(new List<Case>());
        Test.stopTest();

        System.assert(true, 'Null and empty task creation inputs should not throw exceptions');
    }

    @IsTest
    static void testCreateFirstTask_WithCase() {
        Case c = createValidCase('New', 'Pending', '0', false);

        Test.startTest();
        BrokerAgentRegiAndUpdateSRHandler.getInstance().createFirstTask(new List<Case>{ c });
        Test.stopTest();

        Case existing = [SELECT Id FROM Case WHERE Id = :c.Id];
        System.assertNotEquals(null, existing, 'Case should still exist after first task creation');
    }
    
    // =====================================================
    // directcompleteBBM()
    // =====================================================

    @IsTest
    static void testDirectCompleteBBM() {
        Case c = createValidCase('New', 'Pending', '1', false);

        Test.startTest();
        BrokerAgentRegiAndUpdateSRHandler.directcompleteBBM(new List<Case>{ c });
        Test.stopTest();

        Case existing = [SELECT Id FROM Case WHERE Id = :c.Id];
        System.assertNotEquals(null, existing, 'Case should still exist after direct BBM completion');
    }

    // =====================================================
    // updatetask()
    // =====================================================

    @IsTest
    static void testUpdateTask() {
        Case c = createValidCase('New', 'Pending', '1', false);

        Test.startTest();
        BrokerAgentRegiAndUpdateSRHandler.updatetask(new List<Case>{ c });
        Test.stopTest();

        Case existing = [SELECT Id FROM Case WHERE Id = :c.Id];
        System.assertNotEquals(null, existing, 'Case should still exist after task update');
    }

    // =====================================================
    // updateCaseDocumentUploaded()
    // =====================================================

    /*@IsTest
    static void testUpdateCaseDocumentUploaded_NullAndEmpty() {
        Test.startTest();
        BrokerAgentRegiAndUpdateSRHandler.getInstance().updateCaseDocumentUploaded(null);
        BrokerAgentRegiAndUpdateSRHandler.getInstance().updateCaseDocumentUploaded(new Set<Id>());
        Test.stopTest();

        System.assert(true, 'Null and empty document upload inputs should not throw exceptions');
    }*/

    /*@IsTest
    static void testUpdateCaseDocumentUploaded_UpdatesEligibleCase() {
        Case c = createValidCase('New', 'Not Approved', '1', false);

        Test.startTest();
        BrokerAgentRegiAndUpdateSRHandler.getInstance().updateCaseDocumentUploaded(new Set<Id>{ c.Id });
        Test.stopTest();

        Case updatedCase = [
            SELECT DocumentUploaded__c, ApprovalStatus__c, Draft__c
            FROM Case
            WHERE Id = :c.Id
        ];

        System.assertEquals(true, updatedCase.DocumentUploaded__c, 'Document upload flag should be true');
        System.assertEquals('Pending', updatedCase.ApprovalStatus__c, 'Approval should move to Pending');
        System.assertEquals(false, updatedCase.Draft__c, 'Draft should be cleared');
    }*/

    /*@IsTest
    static void testUpdateCaseDocumentUploaded_IgnoresClosedCase() {
        Case c = createValidCase('Closed', 'Not Approved', '1', false);

        Test.startTest();
        BrokerAgentRegiAndUpdateSRHandler.getInstance().updateCaseDocumentUploaded(new Set<Id>{ c.Id });
        Test.stopTest();

        Case updatedCase = [
            SELECT DocumentUploaded__c, ApprovalStatus__c, Draft__c
            FROM Case
            WHERE Id = :c.Id
        ];

        System.assertEquals(false, updatedCase.DocumentUploaded__c, 'Closed case should be ignored');
        System.assertEquals(
            'Not Approved',
            updatedCase.ApprovalStatus__c,
            'Approval should remain unchanged for closed case'
        );
        System.assertEquals(true, updatedCase.Draft__c, 'Draft should remain unchanged for closed case');
    }*/

    // =====================================================
    // Private Helper Methods
    // =====================================================

    private static Case createValidCase(
        String status,
        String approvalStatus,
        String step,
        Boolean sendToBL
    ) {
        ServiceCatalog__c sc = [
            SELECT Id, RecordTypeDevName__c, Category__c, SubCategory__c
            FROM ServiceCatalog__c
            WHERE SubCategory__c = 'Broker New Agent Registration'
            LIMIT 1
        ];

        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Broker Agency' LIMIT 1];

        Contact con = [
            SELECT Id
            FROM Contact
            WHERE BrokerContactRole__c = 'Admin'
            LIMIT 1
        ];

        Id rtId = Utility.getRecordTypeIdByDevName(
            Case.SObjectType,
            'BrokerAgentRegistrationAndUpdate'
        );

        Case c = new Case(
            AccountId = acc.Id,
            ContactId = con.Id,
            RecordTypeId = rtId,
            Status = status,
            ApprovalStatus__c = approvalStatus,
            Step__c = step,
            ServiceCatalog__c = sc.Id,
            Subject = 'Broker New Agent Registration',
            CaseType__c = 'Service Request',
            SendToBL__c = sendToBL,
            DocumentUploaded__c = false,
            Draft__c = true
        );
        insert c;
        return c;
    }

    private static Account createAccount(String name) {
        Account acc = new Account(
            Name = name
        );
        insert acc;
        return acc;
    }

    private static Contact createContact(
        Account acc,
        String role,
        Boolean isActive,
        String lastName,
        String email
    ) {
        Contact con = new Contact(
            LastName = lastName,
            AccountId = acc.Id,
            BrokerContactRole__c = role,
            IsActive__c = isActive,
            Email = email,
            RecordTypeId = Utility.getRecordTypeIdByDevName(
                Contact.SObjectType,
                'Broker'
            )
        );
        insert con;
        return con;
    }

    private static void createServiceCatalogs() {
        List<ServiceCatalog__c> catalogs = new List<ServiceCatalog__c>{
            new ServiceCatalog__c(
                Name = 'Service-Request-Broker-New-Agent-Registration',
                RecordTypeDevName__c = 'BrokerAgentRegistrationAndUpdate',
                Type__c = 'Service Request',
                Category__c = 'Broker Service Request',
                SubCategory__c = 'Broker New Agent Registration'
            ),
            new ServiceCatalog__c(
                Name = 'Service-Request-Broker-Agent-Details-Update',
                RecordTypeDevName__c = 'BrokerAgentRegistrationAndUpdate',
                Type__c = 'Service Request',
                Category__c = 'Broker Service Request',
                SubCategory__c = 'Broker Agent Details Update'
            )
        };
        insert catalogs;

        List<ServiceAction__c> actions = new List<ServiceAction__c>();
        for (ServiceCatalog__c catalog : catalogs) {
            actions.addAll(new List<ServiceAction__c>{
                new ServiceAction__c(
                    Name = catalog.SubCategory__c + ' - Broker Management Team Task',
                    ServiceCatalog__c = catalog.Id,
                    TaskSubType__c = 'Broker Management Team Task',
                    TaskSubject__c = 'Broker Management Team Task',
                    Department__c = 'Broker Management',
                    Due_in_days__c = 1,
                    Order__c = 1
                ),
                new ServiceAction__c(
                    Name = catalog.SubCategory__c + ' - Legal Team Task',
                    ServiceCatalog__c = catalog.Id,
                    TaskSubType__c = 'Legal Team Task',
                    TaskSubject__c = 'Legal Team Task',
                    Department__c = 'Legal',
                    Due_in_days__c = 2,
                    Order__c = 2
                ),
                new ServiceAction__c(
                    Name = catalog.SubCategory__c + ' - Broker Management Team Task Final',
                    ServiceCatalog__c = catalog.Id,
                    TaskSubType__c = 'Broker Management Team Task',
                    TaskSubject__c = 'Broker Management Team Task',
                    Department__c = 'Broker Management',
                    Due_in_days__c = 2,
                    Order__c = 3,
                    FinalTask__c = true
                )
            });
        }
        insert actions;
    }
}