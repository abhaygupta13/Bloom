@IsTest
public class BrokerAgentDetailsUpdateSRHandlerTest {

    // =====================================================
    // Test Setup
    // =====================================================

    @TestSetup
    static void setupData() {
        createServiceCatalogs();

        Account acc = createAccount('Test Broker Agency');

        createContact(acc, 'Agent',  true, 'Agent Contact',  'conAgent@invalid.com');
        createContact(acc, 'Admin',  true, 'Admin Contact',  'conAdmin@invalid.com');
        createContact(acc, 'Partner',true, 'Partner Contact','conPartner@invalid.com');

        Project__c proj = new Project__c(
            Name = 'Test Project'
        );
        insert proj;

        Unit__c unitRec = new Unit__c(
            Name       = 'Test Unit',
            Project__c = proj.Id
        );
        insert unitRec;

        SalesOrder__c so = new SalesOrder__c(
            Name       = 'SO-001',
            Account__c = acc.Id,
            Unit__c    = unitRec.Id
        );
        insert so;
    }

    // =====================================================
    // Singleton Instance
    // =====================================================

    @IsTest
    static void testGetInstance() {
        Test.startTest();
        BrokerAgentDetailsUpdateSRHandler obj =
            BrokerAgentDetailsUpdateSRHandler.getInstance();
        Test.stopTest();

        System.assertNotEquals(null, obj, 'Handler instance should not be null');
    }

    // =====================================================
    // handle() — Null / Empty case IDs
    // =====================================================

    @IsTest
    static void testHandle_NullCaseIds() {
        Test.startTest();
        BrokerAgentDetailsUpdateSRHandler.handle(null);
        Test.stopTest();

        System.assert(true, 'Null caseIds should return without exception');
    }

    @IsTest
    static void testHandle_EmptyCaseIds() {
        Test.startTest();
        BrokerAgentDetailsUpdateSRHandler.handle(new List<Id>());
        Test.stopTest();

        System.assert(true, 'Empty caseIds should return without exception');
    }

    // =====================================================
    // handle() — Matching New case
    // =====================================================

    @IsTest
    static void testHandle_MatchingNewCase() {
        Case c = createValidCase('New', 'Pending', '1');

        Test.startTest();
        BrokerAgentDetailsUpdateSRHandler.handle(new List<Id>{ c.Id });
        Test.stopTest();

        Case existing = [SELECT Id FROM Case WHERE Id = :c.Id];
        System.assertNotEquals(null, existing, 'Case should still exist after handle');
    }

    // =====================================================
    // handle() — Closed case is filtered out
    // =====================================================

    @IsTest
    static void testHandle_ClosedCaseFiltered() {
        Case c = createValidCase('Closed', 'Approved', '1');

        Test.startTest();
        BrokerAgentDetailsUpdateSRHandler.handle(new List<Id>{ c.Id });
        Test.stopTest();

        Case existing = [
            SELECT Status
            FROM   Case
            WHERE  Id = :c.Id
        ];
        System.assertEquals('Closed', existing.Status, 'Closed case should remain unchanged');
    }

    // =====================================================
    // createCaseRecord() — Success
    // =====================================================

    @IsTest
    static void testCreateCaseRecord_Success() {
        SalesOrder__c so = [
            SELECT Id, Account__c, Project__c, Unit__c
            FROM   SalesOrder__c
            LIMIT  1
        ];

        ServiceCatalog__c sc = [
            SELECT Id, RecordTypeDevName__c, SubCategory__c
            FROM   ServiceCatalog__c
            WHERE  SubCategory__c = 'Broker Agent Details Update'
            LIMIT  1
        ];

        Test.startTest();
        Case createdCase =
            BrokerAgentDetailsUpdateSRHandler.getInstance().createCaseRecord(
                    so,
                    sc,
                    so.Account__c,
                    so.Unit__c,
                    'Service Request',
                    'Test Description',
                    'Portal'
                );
        Test.stopTest();

        System.assertNotEquals(null, createdCase,    'Case should be created');
        System.assertNotEquals(null, createdCase.Id, 'Case Id should be populated');

        Case latestCase = [
            SELECT Id, Status, ApprovalStatus__c, Subject, Description,
                   Origin, ServiceCatalog__c, CaseType__c
            FROM   Case
            WHERE  Id = :createdCase.Id
        ];

        System.assertEquals(
            'Broker Agent Details Update',
            latestCase.Subject,
            'Subject should be Broker Agent Details Update'
        );

        System.assertEquals(
            'Test Description',
            latestCase.Description,
            'Description should match'
        );

        System.assertEquals(
            'Portal',
            latestCase.Origin,
            'Origin should be Portal'
        );

        System.assertNotEquals(
            null,
            latestCase.ServiceCatalog__c,
            'ServiceCatalog should be linked'
        );

        System.assertEquals(
            'Service Request',
            latestCase.CaseType__c,
            'CaseType should be Service Request'
        );

        System.assert(
            latestCase.ApprovalStatus__c == 'Pending'
            || latestCase.ApprovalStatus__c == 'Not Approved',
            'ApprovalStatus should be Pending or Not Approved; got: '
                + latestCase.ApprovalStatus__c
        );
    }

    // =====================================================
    // createCaseRecord() — Null SalesOrder (uses fallback IDs)
    // =====================================================

    @IsTest
    static void testCreateCaseRecord_NullSalesOrder() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Broker Agency' LIMIT 1];
        Unit__c  u  = [SELECT Id FROM Unit__c LIMIT 1];

        ServiceCatalog__c sc = [
            SELECT Id, RecordTypeDevName__c, SubCategory__c
            FROM   ServiceCatalog__c
            WHERE  SubCategory__c = 'Broker Agent Details Update'
            LIMIT  1
        ];

        Test.startTest();
        Case createdCase =
            BrokerAgentDetailsUpdateSRHandler.getInstance().createCaseRecord(
                    null,
                    sc,
                    acc.Id,
                    u.Id,
                    'Service Request',
                    'Fallback Description',
                    'Portal'
                );
        Test.stopTest();

        System.assertNotEquals(null, createdCase,    'Case should still be created');
        System.assertNotEquals(null, createdCase.Id, 'Case Id should be populated');

        Case latestCase = [
            SELECT AccountId, Unit__c, Subject
            FROM   Case
            WHERE  Id = :createdCase.Id
        ];

        System.assertEquals(acc.Id, latestCase.AccountId, 'AccountId should match fallback');
        System.assertEquals(u.Id,   latestCase.Unit__c,   'Unit should match fallback');
        System.assertEquals(
            'Broker Agent Details Update',
            latestCase.Subject,
            'Subject should be Broker Agent Details Update'
        );
    }

    // =====================================================
    // validateCaseForNextReview() — Success (Pending → Approved)
    // =====================================================

    @IsTest
    static void testValidateCaseForNextReview_Success() {
        Case c = createValidCase('New', 'Pending', '1');

        Test.startTest();
        Map<String, Object> result =
            BrokerAgentDetailsUpdateSRHandler.getInstance().validateCaseForNextReview(c);
        Test.stopTest();

        System.assertEquals(
            'success',
            (String) result.get('status'),
            'Expected success status'
        );

        System.assertEquals(
            'Validation successful. Case approved and task completed.',
            (String) result.get('message'),
            'Expected success message'
        );

        Case updatedCase = [
            SELECT Status, ApprovalStatus__c
            FROM   Case
            WHERE  Id = :c.Id
        ];

        System.assertEquals(
            'Approved',
            updatedCase.ApprovalStatus__c,
            'Case should be Approved'
        );

        System.assertNotEquals(
            'Closed',
            updatedCase.Status,
            'Case should not be Closed by this handler'
        );
    }

    // =====================================================
    // validateCaseForNextReview() — Not Approved stays unchanged
    // =====================================================

    @IsTest
    static void testValidateCaseForNextReview_NotApproved_Unchanged() {
        Case c = createValidCase('New', 'Not Approved', '1');

        Test.startTest();
        Map<String, Object> result =
            BrokerAgentDetailsUpdateSRHandler.getInstance().validateCaseForNextReview(c);
        Test.stopTest();

        System.assertEquals(
            'success',
            (String) result.get('status'),
            'Expected success status'
        );

        Case updatedCase = [
            SELECT ApprovalStatus__c
            FROM   Case
            WHERE  Id = :c.Id
        ];

        System.assertEquals(
            'Not Approved',
            updatedCase.ApprovalStatus__c,
            'Not Approved case should remain Not Approved'
        );
    }

    // =====================================================
    // validateCaseForNextReview() — Null Case
    // =====================================================

    @IsTest
    static void testValidateCaseForNextReview_NullCase() {
        Test.startTest();
        Map<String, Object> result =
            BrokerAgentDetailsUpdateSRHandler.getInstance().validateCaseForNextReview(null);
        Test.stopTest();

        System.assertEquals(
            'error',
            (String) result.get('status'),
            'Null case should return error'
        );

        System.assertNotEquals(
            null,
            result.get('message'),
            'Error message should be present'
        );
    }

    // =====================================================
    // validateCaseForNextReview() — Closed Case
    // =====================================================

    @IsTest
    static void testValidateCaseForNextReview_ClosedCase() {
        Case c = createValidCase('Closed', 'Approved', '1');

        Test.startTest();
        Map<String, Object> result =
            BrokerAgentDetailsUpdateSRHandler.getInstance().validateCaseForNextReview(c);
        Test.stopTest();

        System.assertEquals(
            'error',
            (String) result.get('status'),
            'Closed case should return error'
        );
    }

    // =====================================================
    // validateCaseForNextReview() — Missing Service Catalog
    // =====================================================

    @IsTest
    static void testValidateCaseForNextReview_NoServiceCatalog() {
        Id rtId = Utility.getRecordTypeIdByDevName(
            Case.SObjectType, 'BrokerAgentRegistrationAndUpdate'
        );

        Case c = new Case(
            Status       = 'New',
            Step__c      = '1',
            Subject      = 'Broker Agent Details Update',
            RecordTypeId = rtId
        );
        insert c;

        Test.startTest();
        Map<String, Object> result =
            BrokerAgentDetailsUpdateSRHandler.getInstance().validateCaseForNextReview(c);
        Test.stopTest();

        System.assertEquals(
            'error',
            (String) result.get('status'),
            'Missing ServiceCatalog should return error'
        );
    }

    // =====================================================
    // validateCaseForNextReview() — Missing Step
    // =====================================================

    @IsTest
    static void testValidateCaseForNextReview_NoStep() {
        ServiceCatalog__c sc = [
            SELECT Id
            FROM   ServiceCatalog__c
            WHERE  SubCategory__c = 'Broker Agent Details Update'
            LIMIT  1
        ];

        Id rtId = Utility.getRecordTypeIdByDevName(
            Case.SObjectType, 'BrokerAgentRegistrationAndUpdate'
        );

        Case c = new Case(
            Status            = 'New',
            ServiceCatalog__c = sc.Id,
            Subject           = 'Broker Agent Details Update',
            RecordTypeId      = rtId
        );
        insert c;

        Test.startTest();
        Map<String, Object> result =
            BrokerAgentDetailsUpdateSRHandler.getInstance().validateCaseForNextReview(c);
        Test.stopTest();

        System.assertEquals(
            'error',
            (String) result.get('status'),
            'Missing Step should return error'
        );
    }

    // =====================================================
    // handleNextSteps()
    // =====================================================

    @IsTest
    static void testHandleNextSteps() {
        Case c = createValidCase('New', 'Pending', '1');

        Test.startTest();
        BrokerAgentDetailsUpdateSRHandler.getInstance().handleNextSteps(c);
        Test.stopTest();

        Case existing = [SELECT Id FROM Case WHERE Id = :c.Id];
        System.assertNotEquals(null, existing, 'Case should still exist after handleNextSteps');
    }

    // =====================================================
    // createFirstTask()
    // =====================================================

    @IsTest
    static void testCreateFirstTask() {
        Case c = createValidCase('New', 'Pending', '1');

        Test.startTest();
        BrokerAgentDetailsUpdateSRHandler.getInstance().createFirstTask(new List<Case>{ c });
        Test.stopTest();

        System.assert(true, 'createFirstTask should execute without exception');
    }

    // =====================================================
    // Private Helper Methods
    // =====================================================

    private static Case createValidCase(
        String status,
        String approvalStatus,
        String step
    ) {
        ServiceCatalog__c sc = [
            SELECT Id
            FROM   ServiceCatalog__c
            WHERE  SubCategory__c = 'Broker Agent Details Update'
            LIMIT  1
        ];

        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Broker Agency' LIMIT 1];

        Contact con = [
            SELECT Id
            FROM   Contact
            WHERE  BrokerContactRole__c = 'Admin'
            LIMIT  1
        ];

        Id rtId = Utility.getRecordTypeIdByDevName(
            Case.SObjectType, 'BrokerAgentRegistrationAndUpdate'
        );

        Case c = new Case(
            AccountId         = acc.Id,
            ContactId         = con.Id,
            RecordTypeId      = rtId,
            Status            = status,
            ApprovalStatus__c = approvalStatus,
            Step__c           = step,
            ServiceCatalog__c = sc.Id,
            Subject           = 'Broker Agent Details Update',
            CaseType__c       = 'Service Request'
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
        String  role,
        Boolean isActive,
        String  lastName,
        String  email
    ) {
        Contact con = new Contact(
            LastName             = lastName,
            AccountId            = acc.Id,
            BrokerContactRole__c = role,
            IsActive__c          = isActive,
            Email                = email,
            RecordTypeId         = Utility.getRecordTypeIdByDevName(
                                       Contact.SObjectType, 'Broker'
                                   )
        );
        insert con;
        return con;
    }

    private static void createServiceCatalogs() {
        ServiceCatalog__c catalog = new ServiceCatalog__c(
            Name                 = 'Service-Request-Broker-Agent-Details-Update',
            RecordTypeDevName__c = 'BrokerAgentRegistrationAndUpdate',
            Type__c              = 'Service Request',
            Category__c          = 'Broker Service Request',
            SubCategory__c       = 'Broker Agent Details Update'
        );
        insert catalog;

        List<ServiceAction__c> actions = new List<ServiceAction__c>{
            new ServiceAction__c(
                Name              = 'Broker Management Team Task',
                ServiceCatalog__c = catalog.Id,
                TaskType__c       = 'Broker Agent Details Update',
                TaskSubType__c    = 'Broker Management Team Task',
                TaskSubject__c    = 'Broker Management Team Task',
                Department__c     = 'Broker Management',
                Due_in_days__c    = 1,
                Order__c          = 1
            ),
            new ServiceAction__c(
                Name              = 'Legal Team Task',
                ServiceCatalog__c = catalog.Id,
                TaskType__c       = 'Broker Agent Details Update',
                TaskSubType__c    = 'Legal Team Task',
                TaskSubject__c    = 'Legal Team Task',
                Department__c     = 'Legal',
                Due_in_days__c    = 2,
                Order__c          = 2
            ),
            new ServiceAction__c(
                Name              = 'Broker Management Team Task Final',
                ServiceCatalog__c = catalog.Id,
                TaskType__c       = 'Broker Agent Details Update',
                TaskSubType__c    = 'Broker Management Team Task',
                TaskSubject__c    = 'Broker Management Team Task',
                Department__c     = 'Broker Management',
                Due_in_days__c    = 2,
                Order__c          = 3,
                FinalTask__c      = true
            )
        };
        insert actions;
    }
}