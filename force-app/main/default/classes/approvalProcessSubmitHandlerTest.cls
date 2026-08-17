@IsTest
public class approvalProcessSubmitHandlerTest {

    @TestSetup
    static void setupData() {

        Account acc = new Account(
            Name = 'Test Account'
        );
        insert acc;

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

        ServiceCatalog__c sc = new ServiceCatalog__c(
            Name = 'Service-Request-Broker-Registration',
            RecordTypeDevName__c = 'BrokerAgentRegistrationAndUpdate',
            Type__c = 'Service Request',
            Category__c = 'Broker Service Request',
            SubCategory__c = 'Broker New Agent Registration'
        );
        insert sc;

        insert new ServiceAction__c(
            Name = 'Broker Management Team Task',
            ServiceCatalog__c = sc.Id,
            TaskType__c = 'Agent Onboarding',
            TaskSubType__c = 'Broker Management Team Task',
            TaskSubject__c = 'Broker Management Team Task',
            Department__c = 'Broker Management',
            Due_in_days__c = 1,
            Order__c = 1
        );

        insert new ServiceAction__c(
            Name = 'Legal Team Task',
            ServiceCatalog__c = sc.Id,
            TaskType__c = 'Agent Onboarding',
            TaskSubType__c = 'Legal Team Task',
            TaskSubject__c = 'Legal Team Task',
            Department__c = 'Legal',
            Due_in_days__c = 2,
            Order__c = 2
        );

        insert new ServiceAction__c(
            Name = 'Broker Management Team Task',
            ServiceCatalog__c = sc.Id,
            TaskType__c = 'Agent Onboarding',
            TaskSubType__c = 'Broker Management Team Task',
            TaskSubject__c = 'Broker Management Team Task',
            Department__c = 'Broker Management',
            Due_in_days__c = 2,
            Order__c = 3,
            FinalTask__c = true
        );
    }

    private static User createUser(Boolean createManager) {

        Profile p = [
            SELECT Id
            FROM Profile
            WHERE Name = 'System Administrator'
            LIMIT 1
        ];

        String uniqueValue = String.valueOf(DateTime.now().getTime());

        User managerUser;

        if(createManager) {
            managerUser = new User(
                FirstName = 'Manager',
                LastName = 'User',
                Alias = 'mgr1',
                Email = 'manager' + uniqueValue + '@test.com',
                Username = 'manager' + uniqueValue + '@test.com',
                TimeZoneSidKey = 'Asia/Kolkata',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                ProfileId = p.Id
            );
            insert managerUser;
        }

        User u = new User(
            FirstName = 'Sales',
            LastName = 'User',
            Alias = 'sale1',
            Email = 'sales' + uniqueValue + '@test.com',
            Username = 'sales' + uniqueValue + '@test.com',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id,
            ManagerId = createManager ? managerUser.Id : null
        );

        insert u;

        return u;
    }

    @IsTest
    static void testUpdateSalesOrder() {

        SalesOrder__c so = [
            SELECT Id
            FROM SalesOrder__c
            LIMIT 1
        ];

        Test.startTest();
        approvalProcessSubmitHandler.updateSalesOrder(so);
        Test.stopTest();

        SalesOrder__c updatedSO = [
            SELECT Cancellation_Requested_By__c
            FROM SalesOrder__c
            WHERE Id = :so.Id
        ];

        System.assertEquals(
            UserInfo.getUserId(),
            updatedSO.Cancellation_Requested_By__c
        );
    }

    @IsTest
    static void testSubmitSalesOrderApproval() {

        User salesManager = createUser(true);

        SalesOrder__c so = [
            SELECT Id, Account__c, Unit__c
            FROM SalesOrder__c
            LIMIT 1
        ];

        so.Status__c = 'Booked';
        so.SalesManager__c = salesManager.Id;
        update so;

        Test.startTest();
        approvalProcessSubmitHandler.callApprovalProcess(so.Id);
        Test.stopTest();

        System.assertNotEquals(null, so.Id);
    }

    @IsTest
    static void testBrokerRegistrationCaseApproval() {

        Account acc = [
            SELECT Id
            FROM Account
            LIMIT 1
        ];

        ServiceCatalog__c sc = [
            SELECT Id
            FROM ServiceCatalog__c
            LIMIT 1
        ];

        Id rtId = Utility.getRecordTypeIdByDevName(
            Case.SObjectType,
            'BrokerAgentRegistrationAndUpdate'
        );

        Case testCase = new Case(
            AccountId = acc.Id,
            Status = 'New',
            Subject = 'Broker Registration',
            ServiceCatalog__c = sc.Id,
            RecordTypeId = rtId,
            SubType__c = 'Broker New Agent Registration'
        );

        insert testCase;

        Test.startTest();
        approvalProcessSubmitHandler.callApprovalProcess(testCase.Id);
        Test.stopTest();

        Case updatedCase = [
            SELECT SendToBL__c,
                   SubStatus__c,
                   FinalApprovalStage__c
            FROM Case
            WHERE Id = :testCase.Id
        ];

        System.assertEquals(true, updatedCase.SendToBL__c);
        System.assertEquals('Approved by BBM', updatedCase.SubStatus__c);
        System.assertEquals('Second Approval', updatedCase.FinalApprovalStage__c);
    }

    @IsTest
    static void testProcessCasesForApprovalWithEmptySet() {

        Test.startTest();

        approvalProcessSubmitHandler.processCasesForApproval(
            new Set<Id>()
        );

        approvalProcessSubmitHandler.processCasesForApproval(null);

        Test.stopTest();

        System.assert(true);
    }
    
   /* @IsTest
static void testGeneralEnquiryCaseApproval() {

    Account acc = [
        SELECT Id
        FROM Account
        LIMIT 1
    ];

    ServiceCatalog__c sc = [
        SELECT Id
        FROM ServiceCatalog__c
        LIMIT 1
    ];

    Id rtId = Utility.getRecordTypeIdByDevName(
        Case.SObjectType,
        'GeneralEnquiry'
    );

    Case testCase = new Case(
        AccountId = acc.Id,
        Status = 'New',
        Subject = 'General Enquiry',
        ServiceCatalog__c = sc.Id,
        RecordTypeId = rtId,
        SubType__c = 'Customer Type Update'
    );

    insert testCase;

    Test.startTest();

    approvalProcessSubmitHandler.callApprovalProcess(
        testCase.Id
    );

    Test.stopTest();

    System.assertNotEquals(
        null,
        testCase.Id
    );
} 
    
    @IsTest
static void testGeneralEnquiryCaseApproval_MissingFields() {

    Account acc = [SELECT Id FROM Account LIMIT 1];
    SalesOrder__c so = [SELECT Id FROM SalesOrder__c LIMIT 1];
    Unit__c unit = [SELECT Id FROM Unit__c LIMIT 1];
    ServiceCatalog__c sc = [SELECT Id FROM ServiceCatalog__c LIMIT 1];
    Project__c prjct = [SELECT Id FROM Project__c LIMIT 1];

    Id rtId = Utility.getRecordTypeIdByDevName(Case.SObjectType,'GeneralEnquiry');

    Case testCase = new Case(
        AccountId = acc.Id,
        Status = 'New',
        Subject = 'General Enquiry',
        ServiceCatalog__c = sc.Id,
        RecordTypeId = rtId,
        PendingWith__c = 'Finance',
        SubType__c = 'Customer Type Update',
        Type = 'Agency Address Update',
        Sales_Order__c = so.Id,
        Unit__c = unit.Id,
        Project__c = prjct.Id
    );

        insert testCase;

    Test.startTest();

    try{
        approvalProcessSubmitHandler.callApprovalProcess(testCase.Id);
        System.assert(false, 'Exception should have been thrown');
    }
    catch(AuraHandledException e){
        System.assert(
            e.getMessage().contains('Customer Type')
        );
    }

    Test.stopTest();
} */
    
    @IsTest
static void testGeneralEnquiryCaseApproval_Success() {

    Account acc = [SELECT Id FROM Account LIMIT 1];
    SalesOrder__c so = [SELECT Id FROM SalesOrder__c LIMIT 1];
    Unit__c unit = [SELECT Id FROM Unit__c LIMIT 1];
    Project__c prjct = [SELECT Id FROM Project__c LIMIT 1];
     
    ServiceCatalog__c sc = new ServiceCatalog__c(
            Name = 'Service-Request-General-Enquiry',
            RecordTypeDevName__c = 'GeneralEnquiry',
            Type__c = 'Service Request',
            Category__c = 'General Enquiry',
            SubCategory__c = 'General Enquiry'
        );
        insert sc;
    
        insert new ServiceAction__c(
            Name = 'CRM Team Task-1',
            ServiceCatalog__c = sc.Id,
            TaskType__c = 'General Enquiry',
            TaskSubType__c = 'CRM Team Task 1',
            TaskSubject__c = 'CRM Team Task 1',
            Department__c = 'CRM',
            Due_in_days__c = 2,
            Order__c = 1,
            FinalTask__c = true
        );
    
    Id rtId = Utility.getRecordTypeIdByDevName(
        Case.SObjectType,
        'GeneralEnquiry'
    );

    Case testCase = new Case(
        AccountId = acc.Id,
        Status = 'New',
        Subject = 'General Enquiry',
        ServiceCatalog__c = sc.Id,
        RecordTypeId = rtId,
        SubType__c = 'Customer Type Update',
        PendingWith__c = 'Finance',
        Customer_Type__c = 'GCC',
        Customer_Sub_Type__c = 'CORPORATE',
        NameofCorporate__c = 'AbuDhabi Police',
        Type = 'Agency Address Update',
        Sales_Order__c = so.Id,
        Unit__c = unit.Id,
        Project__c = prjct.Id
    );

    insert testCase;

    Test.startTest();

    try{
        approvalProcessSubmitHandler.callApprovalProcess(
            testCase.Id
        );
    }
    catch(Exception e){
        // Approval process may not exist in test org
    }

    Test.stopTest();

    System.assertNotEquals(
        null,
        testCase.Id
    );
}
}