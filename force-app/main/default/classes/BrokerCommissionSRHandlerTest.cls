@IsTest
public class BrokerCommissionSRHandlerTest {

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

    @IsTest
    static void testGetInstance() {
        Test.startTest();
        BrokerCommissionSRHandler obj = BrokerCommissionSRHandler.getInstance();
        Test.stopTest();

        System.assertNotEquals(null, obj, 'Handler instance should not be null');
    }

    @IsTest
    static void testCreateCaseRecord_DelayedCommissionPayment_Success() {
        SalesOrder__c so = [
            SELECT Id, Account__c, Project__c, Unit__c
            FROM SalesOrder__c
            LIMIT 1
        ];

        ServiceCatalog__c sc = [
            SELECT Id, RecordTypeDevName__c, SubCategory__c, Category__c
            FROM ServiceCatalog__c
            WHERE SubCategory__c = 'Delayed Commission Payment'
            LIMIT 1
        ];

        Test.startTest();
        Case createdCase =
            BrokerCommissionSRHandler.getInstance().createCaseRecord(
                so,
                sc,
                so.Account__c,
                so.Unit__c,
                'Service Request',
                'Delayed commission description',
                'Portal',
                false
            );
        Test.stopTest();

        System.assertNotEquals(null, createdCase, 'Case should be created');
        System.assertNotEquals(null, createdCase.Id, 'Case Id should be populated');

        Case latestCase = [
            SELECT Id, Status, ApprovalStatus__c, Subject, Type, Description, Origin,
                   ServiceCatalog__c, CaseType__c, Sales_Order__c
            FROM Case
            WHERE Id = :createdCase.Id
        ];

        System.assertEquals(
            'Delayed Commission Payment',
            latestCase.Subject,
            'Subject should be Delayed Commission Payment'
        );
        System.assertEquals(
            'Delayed commission description',
            latestCase.Description,
            'Description should match'
        );
        System.assertEquals('Portal', latestCase.Origin, 'Origin should be Portal');
        System.assertEquals('New', latestCase.Status, 'Status should be New');
        System.assertEquals(so.Id, latestCase.Sales_Order__c, 'Sales Order should be linked');
        System.assertNotEquals(null, latestCase.ServiceCatalog__c, 'ServiceCatalog should be linked');
        System.assertEquals(
            'Service Request',
            latestCase.CaseType__c,
            'CaseType should be Service Request'
        );
        System.assertEquals(
            'Pending',
            latestCase.ApprovalStatus__c,
            'ApprovalStatus should be Pending after case creation'
        );
    }

    @IsTest
    static void testCreateCaseRecord_IncorrectCommissionAmount_Success() {
        SalesOrder__c so = [
            SELECT Id, Account__c, Project__c, Unit__c
            FROM SalesOrder__c
            LIMIT 1
        ];

        ServiceCatalog__c sc = [
            SELECT Id, RecordTypeDevName__c, SubCategory__c, Category__c
            FROM ServiceCatalog__c
            WHERE SubCategory__c = 'Incorrect Commission Amount'
            LIMIT 1
        ];

        Test.startTest();
        Case createdCase =
            BrokerCommissionSRHandler.getInstance().createCaseRecord(
                so,
                sc,
                so.Account__c,
                so.Unit__c,
                'Service Request',
                'Incorrect commission description',
                'Portal',
                false
            );
        Test.stopTest();

        System.assertNotEquals(null, createdCase, 'Case should be created');
        System.assertNotEquals(null, createdCase.Id, 'Case Id should be populated');

        Case latestCase = [
            SELECT Id, Subject, Type, Description, ApprovalStatus__c
            FROM Case
            WHERE Id = :createdCase.Id
        ];

        System.assertEquals(
            'Incorrect Commission Amount',
            latestCase.Subject,
            'Subject should be Incorrect Commission Amount'
        );
        System.assertEquals(
            'Incorrect commission description',
            latestCase.Description,
            'Description should match'
        );
        System.assertEquals(
            'Pending',
            latestCase.ApprovalStatus__c,
            'ApprovalStatus should be Pending after case creation'
        );
    }

    @IsTest
    static void testCreateCaseRecord_DelayedCommissionPayment_NullSalesOrder() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Broker Agency' LIMIT 1];
        Unit__c unitRec = [SELECT Id FROM Unit__c LIMIT 1];

        ServiceCatalog__c sc = [
            SELECT Id, RecordTypeDevName__c, SubCategory__c, Category__c
            FROM ServiceCatalog__c
            WHERE SubCategory__c = 'Delayed Commission Payment'
            LIMIT 1
        ];

        Test.startTest();
        Case createdCase =
            BrokerCommissionSRHandler.getInstance().createCaseRecord(
                null,
                sc,
                acc.Id,
                unitRec.Id,
                'Service Request',
                'Fallback Description',
                'Portal',
                false
            );
        Test.stopTest();

        System.assertNotEquals(null, createdCase, 'Case should still be created');
        System.assertNotEquals(null, createdCase.Id, 'Case Id should be populated');

        Case latestCase = [
            SELECT AccountId, Unit__c, Subject, Sales_Order__c
            FROM Case
            WHERE Id = :createdCase.Id
        ];

        System.assertEquals(acc.Id, latestCase.AccountId, 'AccountId should match fallback');
        System.assertEquals(unitRec.Id, latestCase.Unit__c, 'Unit should match fallback');
        System.assertEquals(
            'Delayed Commission Payment',
            latestCase.Subject,
            'Subject should be Delayed Commission Payment'
        );
        System.assertEquals(null, latestCase.Sales_Order__c, 'Sales Order should be null');
    }

    @IsTest
    static void testCreateCaseRecord_IncorrectCommissionAmount_NullSalesOrder() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Broker Agency' LIMIT 1];
        Unit__c unitRec = [SELECT Id FROM Unit__c LIMIT 1];

        ServiceCatalog__c sc = [
            SELECT Id, RecordTypeDevName__c, SubCategory__c, Category__c
            FROM ServiceCatalog__c
            WHERE SubCategory__c = 'Incorrect Commission Amount'
            LIMIT 1
        ];

        Test.startTest();
        Case createdCase =
            BrokerCommissionSRHandler.getInstance().createCaseRecord(
                null,
                sc,
                acc.Id,
                unitRec.Id,
                'Service Request',
                'Fallback Description',
                'Portal',
                false
            );
        Test.stopTest();

        System.assertNotEquals(null, createdCase, 'Case should still be created');
        System.assertNotEquals(null, createdCase.Id, 'Case Id should be populated');

        Case latestCase = [
            SELECT AccountId, Unit__c, Subject
            FROM Case
            WHERE Id = :createdCase.Id
        ];

        System.assertEquals(acc.Id, latestCase.AccountId, 'AccountId should match fallback');
        System.assertEquals(unitRec.Id, latestCase.Unit__c, 'Unit should match fallback');
        System.assertEquals(
            'Incorrect Commission Amount',
            latestCase.Subject,
            'Subject should be Incorrect Commission Amount'
        );
    }

    @IsTest
    static void testValidateCaseForNextReview_Success() {
        Case c = createValidCase('New', 'Pending', '1', 'Delayed Commission Payment');

        Test.startTest();
        Map<String, Object> result =
            BrokerCommissionSRHandler.getInstance().validateCaseForNextReview(c);
        Test.stopTest();

        System.assertEquals('success', (String) result.get('status'), 'Expected success status');
        System.assertEquals(
            'Validation successful. Processing next step.',
            (String) result.get('message'),
            'Expected validation success message'
        );

        Case updatedCase = [
            SELECT Status, ApprovalStatus__c
            FROM Case
            WHERE Id = :c.Id
        ];

        System.assertEquals('Closed', updatedCase.Status, 'Case should be Closed');
        System.assertEquals('Approved', updatedCase.ApprovalStatus__c, 'Case should be Approved');
    }

    @IsTest
    static void testValidateCaseForNextReview_NotApproved_BecomesApproved() {
        Case c = createValidCase('New', 'Not Approved', '1', 'Incorrect Commission Amount');

        Test.startTest();
        Map<String, Object> result =
            BrokerCommissionSRHandler.getInstance().validateCaseForNextReview(c);
        Test.stopTest();

        System.assertEquals(
            'success',
            (String) result.get('status'),
            'Expected success for Not Approved case'
        );

        Case updatedCase = [
            SELECT ApprovalStatus__c
            FROM Case
            WHERE Id = :c.Id
        ];

        System.assertEquals(
            'Approved',
            updatedCase.ApprovalStatus__c,
            'Not Approved case should become Approved'
        );
    }

    @IsTest
    static void testValidateCaseForNextReview_NullCase() {
        Test.startTest();
        Map<String, Object> result =
            BrokerCommissionSRHandler.getInstance().validateCaseForNextReview(null);
        Test.stopTest();

        System.assertEquals('error', (String) result.get('status'), 'Null case should return error');
        System.assertEquals(
            'Invalid Case record.',
            (String) result.get('message'),
            'Expected invalid case message'
        );
    }

    @IsTest
    static void testValidateCaseForNextReview_ClosedCase() {
        Case c = createValidCase('Closed', 'Approved', '1', 'Delayed Commission Payment');

        Test.startTest();
        Map<String, Object> result =
            BrokerCommissionSRHandler.getInstance().validateCaseForNextReview(c);
        Test.stopTest();

        System.assertEquals('error', (String) result.get('status'), 'Closed case should return error');
        System.assertEquals(
            'Cannot proceed. Case is already Closed.',
            (String) result.get('message'),
            'Expected closed case message'
        );
    }

    @IsTest
    static void testValidateCaseForNextReview_NoServiceCatalog() {
        Id rtId = Utility.getRecordTypeIdByDevName(
            Case.SObjectType,
            'BrokerCommissionIssue'
        );

        Case c = new Case(
            Status = 'New',
            Step__c = '1',
            Subject = 'Test No SC',
            Type = 'Delayed Commission Payment',
            RecordTypeId = rtId
        );
        insert c;

        Test.startTest();
        Map<String, Object> result =
            BrokerCommissionSRHandler.getInstance().validateCaseForNextReview(c);
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

    @IsTest
    static void testValidateCaseForNextReview_NoStep() {
        ServiceCatalog__c sc = [
            SELECT Id
            FROM ServiceCatalog__c
            WHERE SubCategory__c = 'Incorrect Commission Amount'
            LIMIT 1
        ];

        Id rtId = Utility.getRecordTypeIdByDevName(
            Case.SObjectType,
            'BrokerCommissionIssue'
        );

        Case c = new Case(
            Status = 'New',
            ServiceCatalog__c = sc.Id,
            Subject = 'Test No Step',
            Type = 'Incorrect Commission Amount',
            RecordTypeId = rtId
        );
        insert c;

        Test.startTest();
        Map<String, Object> result =
            BrokerCommissionSRHandler.getInstance().validateCaseForNextReview(c);
        Test.stopTest();

        System.assertEquals('error', (String) result.get('status'), 'Missing Step should return error');
        System.assertEquals(
            'Step value is missing.',
            (String) result.get('message'),
            'Expected missing step message'
        );
    }

    @IsTest
    static void testHandleNextSteps() {
        Case c = createValidCase('New', 'Pending', '1', 'Delayed Commission Payment');

        Test.startTest();
        BrokerCommissionSRHandler.getInstance().handleNextSteps(c);
        Test.stopTest();

        Case existing = [SELECT Id FROM Case WHERE Id = :c.Id];
        System.assertNotEquals(null, existing, 'Case should still exist after handleNextSteps');
    }

    @IsTest
    static void testCreateFirstTask() {
        Case c = createValidCase('New', 'Pending', '1', 'Incorrect Commission Amount');

        Test.startTest();
        BrokerCommissionSRHandler.getInstance().createFirstTask(new List<Case>{ c });
        Test.stopTest();

        System.assert(true, 'createFirstTask should execute without exception');
    }

    private static Case createValidCase(
        String status,
        String approvalStatus,
        String step,
        String subCategory
    ) {
        ServiceCatalog__c sc = [
            SELECT Id
            FROM ServiceCatalog__c
            WHERE SubCategory__c = :subCategory
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
            'BrokerCommissionIssue'
        );

        Case c = new Case(
            AccountId = acc.Id,
            ContactId = con.Id,
            RecordTypeId = rtId,
            Status = status,
            ApprovalStatus__c = approvalStatus,
            Step__c = step,
            ServiceCatalog__c = sc.Id,
            Subject = subCategory,
            Type = subCategory,
            CaseType__c = 'Service Request'
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
                Name = 'Service-Request-Delayed-Commission-Payment',
                RecordTypeDevName__c = 'BrokerCommissionIssue',
                Type__c = 'Service Request',
                Category__c = 'Broker Service Request',
                SubCategory__c = 'Delayed Commission Payment'
            ),
            new ServiceCatalog__c(
                Name = 'Service-Request-Incorrect-Commission-Amount',
                RecordTypeDevName__c = 'BrokerCommissionIssue',
                Type__c = 'Service Request',
                Category__c = 'Broker Service Request',
                SubCategory__c = 'Incorrect Commission Amount'
            )
        };
        insert catalogs;

        List<ServiceAction__c> actions = new List<ServiceAction__c>();
        for (ServiceCatalog__c catalog : catalogs) {
            actions.add(
                new ServiceAction__c(
                    Name = catalog.SubCategory__c + ' - Broker Management Team Task',
                    ServiceCatalog__c = catalog.Id,
                    TaskType__c = catalog.SubCategory__c,
                    TaskSubType__c = 'Broker Management Team Task',
                    TaskSubject__c = 'Broker Management Team Task',
                    Department__c = 'Broker Management',
                    Due_in_days__c = 2,
                    Order__c = 1,
                    FinalTask__c = true
                )
            );
        }
        insert actions;
    }
}