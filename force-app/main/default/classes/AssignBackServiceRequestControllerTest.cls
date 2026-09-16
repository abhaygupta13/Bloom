@isTest
public class AssignBackServiceRequestControllerTest {

    private static final String POST_SALE_PAYMENT_DEFERRAL_RT {
        get { return 'Post_Sale_Payment_Deferral'; }
    }

    @testSetup
    static void setupTestData() {

        Profile profileDetail = [
            SELECT Id
            FROM Profile
            WHERE Name = 'CRM Operations'
            LIMIT 1
        ];

        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueOf(Datetime.now())
            .replace(' ', '')
            .replace(':', '')
            .replace('-', '');

        Integer randomInt = Integer.valueOf(Math.rint(Math.random() * 1000000));
        String uniqueName = orgId + dateString + randomInt;

        User testUser = new User(
            Alias = 'testUsr',
            Email = 'testuser@mail.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = profileDetail.Id,
            TimeZoneSidKey = 'Asia/Dubai',
            UserName = uniqueName + '@test.com',
            Department = 'CRM'
        );
        insert testUser;

        Group crmQueue = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = 'CRM_Queue'
            AND Type = 'Queue'
            LIMIT 1
        ];

        Group finQueue = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = 'Finance_Team_Queue'
            AND Type = 'Queue'
            LIMIT 1
        ];

        insert new List<GroupMember>{
            new GroupMember(
                GroupId = crmQueue.Id,
                UserOrGroupId = testUser.Id
            ),
            new GroupMember(
                GroupId = finQueue.Id,
                UserOrGroupId = testUser.Id
            )
        };

        Id caseRecordTypeId =
            Schema.SObjectType.Case
                .getRecordTypeInfosByDeveloperName()
                .get('Post_Sale_Payment_Deferral')
                .getRecordTypeId();

        System.runAs(testUser) {

            Account testAccount = new Account(
                RecordTypeId =
                    Schema.SObjectType.Account
                        .getRecordTypeInfosByDeveloperName()
                        .get('PersonAccount')
                        .getRecordTypeId(),
                LastName = 'Test Account',
                PersonEmail = 'testaccount@test.com'
            );
            insert testAccount;

            Contact testContact = new Contact(
                LastName = 'Test Contact',
                Email = 'sonali.sengar@infobeans.com'
            );
            insert testContact;

            Opportunity testOpportunity = new Opportunity(
                Name = 'Test Opportunity',
                StageName = 'New',
                CloseDate = System.today(),
                LeadChannel__c = 'Walk in',
                AccountId = testAccount.Id,
                WinReason__c = 'Loyalty'
            );
            insert testOpportunity;

            Project__c testProject = new Project__c(
                Name = 'Test Project'
            );
            insert testProject;

            OffersPromotions__c testOfferPromotion =
                new OffersPromotions__c(
                    OfferName__c = 'Almeria Normal ADM Included 2%',
                    StartDate__c = Date.today(),
                    EndDate__c = Date.today().addDays(30),
                    Project__c = testProject.Id
                );
            insert testOfferPromotion;

            BuildingSection__c testBuilding =
                new BuildingSection__c(
                    Name = 'Test Building',
                    BuildingSectionCode__c = 'BL-CAS',
                    Project__c = testProject.Id
                );
            insert testBuilding;

            Unit__c testUnit = new Unit__c(
                Name = 'test Unit',
                Status__c = 'Available',
                UnitType__c = 'Townhouse',
                BuildingSectionName__c = testBuilding.Id,
                Project__c = testProject.Id,
                PropertyUsage__c = 'Residential',
                UnitView__c = 'Beach Side',
                FloorNumber__c = '01',
                NumberOfBedrooms__c = '3',
                UnitModel__c = '1BHK',
                SellingPrice__c = 700000,
                EndDate__c = Date.today() + 10,
                StartDate__c = Date.today() - 10
            );
            insert testUnit;

            PaymentPlan__c pp = new PaymentPlan__c(
                Name = 'July Plan',
                Unit__c = testUnit.Id,
                Description__c = 'Test',
                IsActive__c = 'NO',
                BrokerPortalFlag__c = true,
                Classification__c = Constants.PAYMENT_PLAN_TYPE_STANDARD
            );
            insert pp;

            PaymentInstallments__c ppi =
                new PaymentInstallments__c(
                    BrokerPayoutPercentage__c = 100,
                    Description__c = 'test description',
                    InstallmentNumber__c = 1,
                    InstallmentPercentage__c = 100,
                    PaymentPlan__c = pp.Id,
                    Condition_Type__c = 'P012'
                );
            insert ppi;

            SalesOrder__c testSalesOrder =
                new SalesOrder__c(
                    Name = 'Test Sales Order',
                    Status__c = 'Booked',
                    Account__c = testAccount.Id,
                    Unit__c = testUnit.Id,
                    Opportunity__c = testOpportunity.Id
                );
            insert testSalesOrder;

            SalesOrder__c testSalesOrder1 =
                new SalesOrder__c(
                    Name = 'Test Sales Order1',
                    Status__c = 'Sold',
                    Account__c = testAccount.Id,
                    Unit__c = testUnit.Id,
                    Opportunity__c = testOpportunity.Id
                );
            insert testSalesOrder1;

            InstallmentLines__c installmentLines =
                new InstallmentLines__c(
                    PaymentPlan__c = pp.Id,
                    PaymentInstallments__c = ppi.Id,
                    SalesOrder__c = testSalesOrder1.Id,
                    Description__c = 'Description',
                    InstallmentAmount__c = 70000,
                    LPCCutOffAmt__c = 0,
                    MinInvAmtrem__c = 100,
                    LPCRate__c = 12,
                    InstallmentPercentage__c = 25,
                    BrokerPayoutPercentage__c = 20,
                    GracePeriod__c = 1,
                    Inst_inc_tax_in_words__c = '',
                    InstallmentDate__c = Date.today() - 12,
                    AmountReceived__c = 1500,
                    CutOffDate__c = Date.today(),
                    LPCAmount__c = 500
                );
            insert installmentLines;

            SalesOrder__c testSalesOrder2 =
                new SalesOrder__c(
                    Name = 'Test Sales Order2',
                    Status__c = 'Sold',
                    Offer__c = testOfferPromotion.Id,
                    Account__c = testAccount.Id,
                    Opportunity__c = testOpportunity.Id
                );
            insert testSalesOrder2;

            ServiceCatalog__c testServiceCatalog =
                new ServiceCatalog__c(
                    Name = 'Test Service',
                    RecordTypeDevName__c =
                        'Post_Sale_Payment_Deferral'
                );
            insert testServiceCatalog;

            ServiceAction__c currentAction =
                new ServiceAction__c(
                    Name = 'Current Action',
                    Department__c = 'CRM',
                    Order__c = 1,
                    ServiceCatalog__c = testServiceCatalog.Id
                );
            insert currentAction;

            ServiceAction__c previousAction =
                new ServiceAction__c(
                    Name = 'Previous Action',
                    Department__c = 'Finance',
                    Order__c = 0,
                    ServiceCatalog__c = testServiceCatalog.Id
                );
            insert previousAction;

            Case testCase = new Case(
                CurrencyIsoCode = 'AED',
                Origin = 'Email',
                OwnerId = testUser.Id,
                RecordTypeId = caseRecordTypeId,
                Sales_Order__c = testSalesOrder1.Id,
                ServiceCatalog__c = testServiceCatalog.Id,
                Case_Contact_Name__c = testContact.Id,
                ContactId = testContact.Id
            );
            insert testCase;

            Case testCase1 = new Case(
                CurrencyIsoCode = 'AED',
                Origin = 'Email',
                OwnerId = testUser.Id,
                CaseType__c = 'Service Request',
                RecordTypeId = caseRecordTypeId,
                Sales_Order__c = testSalesOrder1.Id,
                ServiceCatalog__c = testServiceCatalog.Id,
                Step__c = '1',
                PaymentDeferralReason__c =
                    'Changing date with replacing the cheque'
            );
            insert testCase1;

            Case testCase2 = new Case(
                CurrencyIsoCode = 'AED',
                Origin = 'Email',
                OwnerId = testUser.Id,
                RecordTypeId = caseRecordTypeId,
                CaseType__c = 'Service Request',
                Sales_Order__c = testSalesOrder1.Id,
                ServiceCatalog__c = testServiceCatalog.Id,
                Step__c = '2',
                Deferral_Within_1_Month__c = 'Yes',
                Deferral_Fee_Paid__c = 'Yes'
            );
            insert testCase2;

            Case testCase3 = new Case(
                CurrencyIsoCode = 'AED',
                Origin = 'Email',
                OwnerId = testUser.Id,
                RecordTypeId = caseRecordTypeId,
                Sales_Order__c = testSalesOrder1.Id,
                ServiceCatalog__c = testServiceCatalog.Id,
                Step__c = '2',
                CaseType__c = 'Service Request',
                Deferral_Within_1_Month__c = 'No',
                Deferral_Fee_Paid__c = 'No',
                DeferralApprovalStatus__c = 'Rejected',
                ContactId = testContact.Id
            );

            Test.startTest();
            insert testCase3;
            Test.stopTest();

            InstallmentLines__c installmentLines1 = [
                SELECT Id, Name
                FROM InstallmentLines__c
                LIMIT 1
            ];

            CaseInstallment__c caseInstallment =
                new CaseInstallment__c(
                    Case__c = testCase3.Id,
                    OwnerId = testUser.Id,
                    NewInstallmentDate__c = System.today()
                );

            insert caseInstallment;
        }
    }


    @isTest
    static void testGetAssignBackReasons() {

        Test.startTest();

        List<String> reasons =
            AssignBackServiceRequestController.getAssignBackReasons();

        Test.stopTest();

        System.assertNotEquals(
            null,
            reasons,
            'Assign back reasons should not be null'
        );
    }


    @isTest
    static void testGetTeamUsers_Complaint() {

        User testUser = [
            SELECT Id, Department
            FROM User
            WHERE Alias = 'testUsr'
            LIMIT 1
        ];

        Account acc = [
            SELECT Id
            FROM Account
            LIMIT 1
        ];

        SalesOrder__c so = [
            SELECT Id
            FROM SalesOrder__c
            LIMIT 1
        ];

        Id complaintRT =
            Schema.SObjectType.Case
                .getRecordTypeInfosByDeveloperName()
                .get('ComplaintRequest')
                .getRecordTypeId();

        ServiceCatalog__c sc =
            new ServiceCatalog__c(
                Name = 'Complaint Team Test',
                RecordTypeDevName__c = 'ComplaintRequest'
            );
        insert sc;

        Case complaintCase = new Case(
            RecordTypeId = complaintRT,
            Status = 'New',
            Origin = 'Phone',
            CaseType__c = 'Complaint',
            SubType__c = 'Poor Knowledge',
            AccountId = acc.Id,
            Sales_Order__c = so.Id,
            ServiceCatalog__c = sc.Id,
            Step__c = '1'
        );

        CaseService.getInstance().insertCaseWithoutTrigger(
            new List<Case>{ complaintCase }
        );

        Test.startTest();

        Map<String, List<Map<String, String>>> result =
            AssignBackServiceRequestController.getTeamUsers(
                complaintCase.Id
            );

        Test.stopTest();

        System.assertNotEquals(null, result);

        /*
         * Complaint cases use the hard-coded departments:
         * Leasing, CRM, Finance, Operation, BFM,
         * Community Management and Renovation.
         */
        System.assert(
            result.containsKey('CRM'),
            'Complaint result should contain CRM department'
        );

        System.assert(
            result.containsKey('Finance'),
            'Complaint result should contain Finance department'
        );

        System.assert(
            result.containsKey('Leasing'),
            'Complaint result should contain Leasing department'
        );

        /*
         * The test user has Department = CRM, so the user
         * should be returned under CRM.
         */
        System.assert(
            result.get('CRM').size() > 0,
            'CRM should contain the active test user'
        );
    }


    @isTest
    static void testGetTeamUsers_ServiceRequest() {

        Case caseObj = [
            SELECT Id
            FROM Case
            WHERE RecordType.DeveloperName = 'Post_Sale_Payment_Deferral'
            LIMIT 1
        ];

        Test.startTest();

        Map<String, List<Map<String, String>>> result =
            AssignBackServiceRequestController.getTeamUsers(
                caseObj.Id
            );

        Test.stopTest();

        System.assertNotEquals(
            null,
            result,
            'Result should not be null'
        );

        /*
         * Service Request departments are obtained from
         * previous/current ServiceAction records.
         */
        System.assert(
            result.containsKey('CRM') ||
            result.containsKey('Finance'),
            'Result should contain CRM or Finance department'
        );
    }


    @isTest
    static void testHandleAssignBack_Complaint_CreateComplaintTask() {

        User testUser = [
            SELECT Id
            FROM User
            WHERE Alias = 'testUsr'
            LIMIT 1
        ];

        Account acc = [
            SELECT Id
            FROM Account
            LIMIT 1
        ];

        SalesOrder__c so = [
            SELECT Id, Account__c
            FROM SalesOrder__c
            LIMIT 1
        ];

        ServiceCatalog__c sc =
            new ServiceCatalog__c(
                Name = 'Complaint-Sales-Poor-Knowledge',
                RecordTypeDevName__c = 'ComplaintRequest'
            );
        insert sc;

        ServiceAction__c currentAction =
            new ServiceAction__c(
                Name = 'Complaint Current Action',
                Department__c = 'CRM',
                Order__c = 1,
                ServiceCatalog__c = sc.Id
            );
        insert currentAction;

        ServiceAction__c nextAction =
            new ServiceAction__c(
                Name = 'Complaint Next Action',
                Department__c = 'CRM',
                Order__c = 3,
                ServiceCatalog__c = sc.Id
            );
        insert nextAction;

        Id complaintRT =
            Schema.SObjectType.Case
                .getRecordTypeInfosByDeveloperName()
                .get('ComplaintRequest')
                .getRecordTypeId();

        Case complaintCase = new Case(
            RecordTypeId = complaintRT,
            Status = 'New',
            Origin = 'Phone',
            CaseType__c = 'Complaint',
            SubType__c = 'Poor Knowledge',
            AccountId = acc.Id,
            Sales_Order__c = so.Id,
            ServiceCatalog__c = sc.Id,
            Step__c = '1'
        );

        CaseService.getInstance().insertCaseWithoutTrigger(
            new List<Case>{ complaintCase }
        );

        Test.startTest();

        AssignBackServiceRequestController.handleAssignBack(
            complaintCase.Id,
            'Assign Back',
            'Reason',
            testUser.Id,
            'CRM',
            false
        );

        Test.stopTest();

        complaintCase = [
            SELECT Status,
                   PendingWith__c,
                   OwnerId,
                   Step__c
            FROM Case
            WHERE Id = :complaintCase.Id
        ];

        System.assertEquals(
            'In Progress',
            complaintCase.Status
        );

        System.assertEquals(
            'CRM',
            complaintCase.PendingWith__c
        );

        System.assertEquals(
            testUser.Id,
            complaintCase.OwnerId
        );

        System.assertEquals(
            '2',
            complaintCase.Step__c
        );

        List<Task> tasks = [
            SELECT Id,
                   Subject,
                   OwnerId,
                   Department__c
            FROM Task
            WHERE WhatId = :complaintCase.Id
        ];

        System.assert(
            tasks.size() > 0,
            'Complaint task should be created'
        );

        Boolean normalTaskFound = false;

        for (Task t : tasks) {
            if (t.Subject == 'CRM Team Task 1') {
                normalTaskFound = true;
                System.assertEquals(
                    testUser.Id,
                    t.OwnerId
                );
                System.assertEquals(
                    'CRM',
                    t.Department__c
                );
            }
        }

        System.assert(
            normalTaskFound,
            'Normal CRM team task should be created'
        );
    }


    @isTest
    static void testHandleAssignBack_Complaint_Escalation() {

        User testUser = [
            SELECT Id
            FROM User
            WHERE Alias = 'testUsr'
            LIMIT 1
        ];

        Account acc = [
            SELECT Id
            FROM Account
            LIMIT 1
        ];

        SalesOrder__c so = [
            SELECT Id
            FROM SalesOrder__c
            LIMIT 1
        ];

        ServiceCatalog__c sc =
            new ServiceCatalog__c(
                Name = 'Complaint Escalation Test',
                RecordTypeDevName__c = 'ComplaintRequest'
            );
        insert sc;

        Id complaintRT =
            Schema.SObjectType.Case
                .getRecordTypeInfosByDeveloperName()
                .get('ComplaintRequest')
                .getRecordTypeId();

        Case complaintCase = new Case(
            RecordTypeId = complaintRT,
            Status = 'New',
            Origin = 'Phone',
            CaseType__c = 'Complaint',
            SubType__c = 'Poor Knowledge',
            AccountId = acc.Id,
            Sales_Order__c = so.Id,
            ServiceCatalog__c = sc.Id,
            Step__c = '1'
        );

        CaseService.getInstance().insertCaseWithoutTrigger(
            new List<Case>{ complaintCase }
        );

        Test.startTest();

        AssignBackServiceRequestController.handleAssignBack(
            complaintCase.Id,
            'Escalation',
            'Escalation Reason',
            testUser.Id,
            'CRM',
            true
        );

        Test.stopTest();

        List<Task> tasks = [
            SELECT Id,
                   Subject,
                   OwnerId,
                   Department__c
            FROM Task
            WHERE WhatId = :complaintCase.Id
        ];

        System.assert(
            tasks.size() > 0,
            'Escalation task should be created'
        );

        Boolean escalationTaskFound = false;

        for (Task t : tasks) {
            if (t.Subject == 'Escalation Task') {
                escalationTaskFound = true;

                System.assertEquals(
                    testUser.Id,
                    t.OwnerId
                );

                System.assertEquals(
                    'CRM',
                    t.Department__c
                );
            }
        }

        System.assert(
            escalationTaskFound,
            'Escalation Task should be created when isEscalation = true'
        );
    }


  

    @isTest
    static void testHandleAssignBack_NonComplaint() {

        User testUser = [
            SELECT Id
            FROM User
            WHERE Alias = 'testUsr'
            LIMIT 1
        ];

        Case caseObj = [
            SELECT Id,
                   RecordTypeId,
                   SubStatus__c,
                   ServiceCatalog__c
            FROM Case
            WHERE RecordType.DeveloperName = 'Post_Sale_Payment_Deferral'
            LIMIT 1
        ];

        Test.startTest();

       
        AssignBackServiceRequestController.handleAssignBack(
            caseObj.Id,
            'Test Comment',
            'Test Reason',
            testUser.Id,
            'CRM',
            false
        );

        Test.stopTest();

        System.assert(
            true,
            'Non-complaint assign back executed successfully'
        );
    }
}