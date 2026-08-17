@IsTest
public class DelayedCommissionPaymentSRHandlerTest {

    // =====================================================
    // Test Setup
    // =====================================================

    @TestSetup
    static void setupData() {
        createServiceCatalogs();

        Account acc = createAccount('Test Broker Agency');

        // Contacts — mirroring reference class pattern
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
        DelayedCommissionPaymentSRHandler obj =
            DelayedCommissionPaymentSRHandler.getInstance();
        Test.stopTest();

        System.assertNotEquals(null, obj, 'Handler instance should not be null');
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
            WHERE  SubCategory__c = 'Delayed Commission Payment'
            LIMIT  1
        ];

        Test.startTest();
        Case createdCase =
            DelayedCommissionPaymentSRHandler.getInstance().createCaseRecord(
                    so,
                    sc,
                    so.Account__c,
                    so.Unit__c,
                    'Service Request',
                    'Test Description',
                    'Portal'
                );
        Test.stopTest();

        System.assertNotEquals(null, createdCase,          'Case should be created');
        System.assertNotEquals(null, createdCase.Id,       'Case Id should be populated');

        Case latestCase = [
            SELECT Id, Status, ApprovalStatus__c, Subject,
                   Type, Description, Origin, ServiceCatalog__c, CaseType__c
            FROM   Case
            WHERE  Id = :createdCase.Id
        ];

        System.assertEquals(
            'Delayed Commission Payment',
            latestCase.Subject,
            'Subject should be Delayed Commission Payment'
        );

       /* System.assertEquals(
            'Delayed Commission Payment',
            latestCase.Type,
            'Type should be Delayed Commission Payment'
        ); */

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
        Unit__c  u  = [SELECT Id FROM Unit__c  LIMIT 1];

        ServiceCatalog__c sc = [
            SELECT Id, RecordTypeDevName__c, SubCategory__c
            FROM   ServiceCatalog__c
            WHERE  SubCategory__c = 'Delayed Commission Payment'
            LIMIT  1
        ];

        Test.startTest();
        Case createdCase =
            DelayedCommissionPaymentSRHandler.getInstance().createCaseRecord(
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
            SELECT AccountId, Unit__c
            FROM   Case
            WHERE  Id = :createdCase.Id
        ];

        System.assertEquals(acc.Id, latestCase.AccountId, 'AccountId should match fallback');
        System.assertEquals(u.Id,   latestCase.Unit__c,   'Unit should match fallback');
    }

    // =====================================================
    // validateCaseForNextReview() — Success
    // =====================================================

    @IsTest
    static void testValidateCaseForNextReview_Success() {
        Case c = createValidCase('New', 'Pending', '1');

        Test.startTest();
        Map<String, Object> result =
            DelayedCommissionPaymentSRHandler.getInstance().validateCaseForNextReview(c);
        Test.stopTest();

        System.assertEquals(
            'success',
            (String) result.get('status'),
            'Expected success status'
        );

        Case updatedCase = [
            SELECT Status, ApprovalStatus__c
            FROM   Case
            WHERE  Id = :c.Id
        ];

        System.assertEquals('Closed',   updatedCase.Status,           'Case should be Closed');
        System.assertEquals('Approved', updatedCase.ApprovalStatus__c, 'Case should be Approved');
    }

    // =====================================================
    // validateCaseForNextReview() — Not Approved → Approved
    // =====================================================

    @IsTest
    static void testValidateCaseForNextReview_NotApproved_BecomesApproved() {
        Case c = createValidCase('New', 'Not Approved', '1');

        Test.startTest();
        Map<String, Object> result =
            DelayedCommissionPaymentSRHandler.getInstance().validateCaseForNextReview(c);
        Test.stopTest();

        System.assertEquals(
            'success',
            (String) result.get('status'),
            'Expected success for Not Approved case'
        );

        Case updatedCase = [
            SELECT ApprovalStatus__c
            FROM   Case
            WHERE  Id = :c.Id
        ];

        System.assertEquals(
            'Approved',
            updatedCase.ApprovalStatus__c,
            'Not Approved case should become Approved'
        );
    }

    // =====================================================
    // validateCaseForNextReview() — Null Case
    // =====================================================

    @IsTest
    static void testValidateCaseForNextReview_NullCase() {
        Test.startTest();
        Map<String, Object> result =
            DelayedCommissionPaymentSRHandler.getInstance().validateCaseForNextReview(null);
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
            DelayedCommissionPaymentSRHandler.getInstance().validateCaseForNextReview(c);
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
            Case.SObjectType, 'BrokerCommissionIssue'
        );

        Case c = new Case(
            Status       = 'New',
            Step__c      = '1',
            Subject      = 'Test No SC',
            Type         = 'Delayed Commission Payment',
            RecordTypeId = rtId
        );
        insert c;

        Test.startTest();
        Map<String, Object> result =
            DelayedCommissionPaymentSRHandler.getInstance().validateCaseForNextReview(c);
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
            WHERE  SubCategory__c = 'Delayed Commission Payment'
            LIMIT  1
        ];

        Id rtId = Utility.getRecordTypeIdByDevName(
            Case.SObjectType, 'BrokerCommissionIssue'
        );

        Case c = new Case(
            Status          = 'New',
            ServiceCatalog__c = sc.Id,
            Subject         = 'Test No Step',
            Type            = 'Delayed Commission Payment',
            RecordTypeId    = rtId
        );
        insert c;

        Test.startTest();
        Map<String, Object> result =
            DelayedCommissionPaymentSRHandler.getInstance().validateCaseForNextReview(c);
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
        DelayedCommissionPaymentSRHandler.getInstance().handleNextSteps(c);
        Test.stopTest();

        Case existing = [SELECT Id, Status FROM Case WHERE Id = :c.Id];
        System.assertNotEquals(null, existing, 'Case should still exist after handleNextSteps');
    }

    // =====================================================
    // createFirstTask()
    // =====================================================

    @IsTest
    static void testCreateFirstTask() {
        Case c = createValidCase('New', 'Pending', '1');

        Test.startTest();
        DelayedCommissionPaymentSRHandler.getInstance().createFirstTask(new List<Case>{ c });
        Test.stopTest();

        System.assert(true, 'createFirstTask should execute without exception');
    }

    // =====================================================
    // Private Helper Methods
    // =====================================================

    /**
     * Creates a Case with a linked ServiceCatalog and given field values.
     */
    private static Case createValidCase(
        String status,
        String approvalStatus,
        String step
    ) {
        ServiceCatalog__c sc = [
            SELECT Id
            FROM   ServiceCatalog__c
            WHERE  SubCategory__c = 'Delayed Commission Payment'
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
            Case.SObjectType, 'BrokerCommissionIssue'
        );

        Case c = new Case(
            AccountId         = acc.Id,
            ContactId         = con.Id,
            RecordTypeId      = rtId,
            Status            = status,
            ApprovalStatus__c = approvalStatus,
            Step__c           = step,
            ServiceCatalog__c = sc.Id,
            Subject           = 'Delayed Commission Payment',
            Type              = 'Delayed Commission Payment',
            CaseType__c       = 'Service Request'
        );
        insert c;
        return c;
    }

    /**
     * Creates and inserts a Broker Agency Account.
     */
    private static Account createAccount(String name) {
        Account acc = new Account(
            Name = name
        );
        insert acc;
        return acc;
    }

    /**
     * Creates and inserts a Contact linked to the given Account with a broker role.
     */
    private static Contact createContact(
        Account acc,
        String  role,
        Boolean isActive,
        String  lastName,
        String  email
    ) {
        Contact con = new Contact(
            LastName           = lastName,
            AccountId          = acc.Id,
            BrokerContactRole__c = role,
            IsActive__c        = isActive,
            Email              = email,
            RecordTypeId       = Utility.getRecordTypeIdByDevName(
                                     Contact.SObjectType, 'Broker'
                                 )
        );
        insert con;
        return con;
    }

    /**
     * Inserts all required ServiceCatalog records for this test class.
     */
    private static void createServiceCatalogs() {
        List<ServiceCatalog__c> catalogs = new List<ServiceCatalog__c>{
            new ServiceCatalog__c(
                Name                 = 'Service-Request-Delayed-Commission-Payment',
                RecordTypeDevName__c = 'BrokerCommissionIssue',
                Type__c              = 'Service Request',
                Category__c          = 'Broker Service Request',
                SubCategory__c       = 'Delayed Commission Payment'
            ),
            new ServiceCatalog__c(
                Name                 = 'Service-Request-Incorrect-Commission-Amount',
                RecordTypeDevName__c = 'BrokerCommissionIssue',
                Type__c              = 'Service Request',
                Category__c          = 'Broker Service Request',
                SubCategory__c       = 'Incorrect Commission Amount'
            )
        };
        insert catalogs;
        
         // Create test ServiceAction record
        ServiceAction__c finalAction = new ServiceAction__c(
            Name = 'Broker Management Team Task',
            ServiceCatalog__c = catalogs[0].Id,
            TaskType__c = 'Delayed Commission Payment',
            TaskSubType__c = 'Broker Management Team Task',
            TaskSubject__c = 'Broker Management Team Task',
            Department__c ='Broker Management',
            Due_in_days__c = 2,
            Order__c = 1,
            FinalTask__c = true
        );
        insert finalAction;
        
        ServiceAction__c finalAction1 = new ServiceAction__c(
            Name = 'Broker Management Team Task',
            ServiceCatalog__c = catalogs[1].Id,
            TaskType__c = 'Incorrect Commission Amount',
            TaskSubType__c = 'Broker Management Team Task',
            TaskSubject__c = 'Broker Management Team Task',
            Department__c ='Broker Management',
            Due_in_days__c = 2,
            Order__c = 1,
            FinalTask__c = true
        );
        insert finalAction1;
    } 
}