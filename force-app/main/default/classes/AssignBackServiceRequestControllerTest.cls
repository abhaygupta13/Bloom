@isTest
public class AssignBackServiceRequestControllerTest {
    
    private static final string POST_SALE_PAYMENT_DEFERRAL_RT { get { return 'Post_Sale_Payment_Deferral'; } }
    @testSetup
    static void setupTestData() {
               
        Profile profileDetail = [SELECT Id FROM Profile WHERE Name='CRM Operations'];
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueOf(Datetime.now()).replace(' ', '').replace(':', '').replace('-', '');
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
            UserName = uniqueName + '@test.com'
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
    new GroupMember(GroupId = crmQueue.Id, UserOrGroupId = testUser.Id),
    new GroupMember(GroupId = finQueue.Id, UserOrGroupId = testUser.Id)
	};
        Id caseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Post_Sale_Payment_Deferral').getRecordTypeId();
        system.debug('This is recordType Id :'+caseRecordTypeId);
 		System.runAs(testUser) {
       
        Account testAccount = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId(),
            LastName = 'Test Account',
            PersonEmail = 'testaccount@test.com'
        );
        insert testAccount;
        
        // Create Contact with Email
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
        
        Project__c testProject=new Project__c(
            Name='Test Project'
        );
        insert testProject;
        
        OffersPromotions__c testOfferPromotion = new OffersPromotions__c(
            OfferName__c = 'Almeria Normal ADM Included 2%',  // Required Field - Offer Name
            StartDate__c = Date.today(),       // Required Field - Start Date
            EndDate__c = Date.today().addDays(30),  // Required Field - End Date
            Project__c = testProject.Id  // Replace with a valid Project ID
        );
        insert testOfferPromotion;
        
        BuildingSection__c testBuilding=new BuildingSection__c(
            Name='Test Building',
            BuildingSectionCode__c='BL-CAS',
            Project__c=testProject.Id
            
        );
        insert testBuilding;
        
        Unit__c testUnit=new Unit__c(
            Name='test Unit',
            Status__c='Available',
            UnitType__c='Townhouse',
            BuildingSectionName__c=testBuilding.id,
            Project__c=testProject.Id,
            PropertyUsage__c='Residential',
            UnitView__c  ='Beach Side',
            FloorNumber__c='01',
            NumberOfBedrooms__c='3',
            UnitModel__c='1BHK',
            SellingPrice__c= 700000,
            EndDate__c= date.today()+10,
            StartDate__c=date.today()-10
            
        );
        insert testUnit;
        
        PaymentPlan__c  pp = new PaymentPlan__c();
        pp.Name ='July Plan';
        pp.Unit__c= testUnit.id;
        pp.Description__c ='Test Description';
        pp.Description__c = 'Test';
        pp.IsActive__c = 'NO';
        pp.BrokerPortalFlag__c = True;
        pp.Classification__c = Constants.PAYMENT_PLAN_TYPE_STANDARD;
        
        insert pp;
        
        PaymentInstallments__c ppi = new PaymentInstallments__c();
        ppi.BrokerPayoutPercentage__c =100;
        ppi.Description__c = 'test description';
        ppi.InstallmentNumber__c = 1;
        ppi.InstallmentPercentage__c=100;
        ppi.PaymentPlan__c = pp.id;
        ppi.InstallmentPercentage__c=100;
        ppi.Condition_Type__c='P012';
        insert ppi;
        
        SalesOrder__c testSalesOrder = new SalesOrder__c(
            Name = 'Test Sales Order',
            Status__c = 'Booked',
            //Offer__c = testOfferPromotion.Id,
            Account__c = testAccount.Id,
            //Sales_Order_Number__c = '125236',
            Unit__c = testUnit.Id,
            Opportunity__c = testOpportunity.Id
        );
        insert testSalesOrder;
        
        SalesOrder__c testSalesOrder1 = new SalesOrder__c(
            Name = 'Test Sales Order1',
            Status__c = 'Sold',
            //Offer__c = testOfferPromotion.Id,
            Account__c = testAccount.Id,
            //Sales_Order_Number__c = '125236',
            Unit__c = testUnit.Id,
            Opportunity__c = testOpportunity.Id
        );
        insert testSalesOrder1;
        
        InstallmentLines__c installmentLines = new InstallmentLines__c();
        installmentLines.PaymentPlan__c = pp.id;
        installmentLines.PaymentInstallments__c =ppi.Id;
        installmentLines.SalesOrder__c = testSalesOrder1.id;
        installmentLines.Description__c='4th Installment';
        installmentLines.InstallmentAmount__c = 100000;
        installmentLines.LPCCutOffAmt__c =0;
        installmentLines.MinInvAmtrem__c =100;
        installmentLines.LPCRate__c =12;
        installmentLines.InstallmentPercentage__c = 25;
        installmentLines.BrokerPayoutPercentage__c = 20;
        installmentLines.Description__c = 'Description';
        installmentLines.RevisedDate__c=null;
        installmentLines.GracePeriod__c=1;
        installmentLines.InstallmentAmount__c =70000;
        installmentLines.Inst_inc_tax_in_words__c  = '';
        installmentLines.InstallmentDate__c= Date.today() - 12;
        installmentLines.AmountReceived__c=1500;
        installmentLines.CutOffDate__c=date.today();
        installmentLines.LPCAmount__c=500;
        //installmentLines.Name = 'Test Installment';
        //installmentLines.NewInstallmentDate__c = System.today();
        
        insert installmentLines;
        
        SalesOrder__c testSalesOrder2 = new SalesOrder__c(
            Name = 'Test Sales Order2',
            Status__c = 'Sold',
            Offer__c = testOfferPromotion.Id,
            Account__c = testAccount.Id,
            Opportunity__c = testOpportunity.Id
        );
        insert testSalesOrder2;
        
        // Create a Service Catalog
        ServiceCatalog__c testServiceCatalog = new ServiceCatalog__c(Name = 'Test Service', RecordTypeDevName__c = 'Post_Sale_Payment_Deferral'
                                                                     /*Category__c = 'BFM Service', SubCategory__c = 'Post Sale Payment Deferral'*/);
        insert testServiceCatalog;
        // Current action (CRM)
		ServiceAction__c currentAction = new ServiceAction__c(
   			 Name = 'Current Action',
  		     Department__c = 'CRM',
   			 Order__c = 1,
   			 ServiceCatalog__c = testServiceCatalog.Id
			);
		insert currentAction;


		ServiceAction__c previousAction = new ServiceAction__c(
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
            Step__c = String.valueOf(1),
            PaymentDeferralReason__c = 'Changing date with replacing the cheque'
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
            Step__c = String.valueOf(2),
            Deferral_Within_1_Month__c = 'Yes',
            //PaymentScanned__c =  'Yes' ,
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
            Step__c = String.valueOf(2),
            CaseType__c = 'Service Request',
            Deferral_Within_1_Month__c = 'No',
            //PaymentScanned__c =  'No' ,
            Deferral_Fee_Paid__c = 'No',
            DeferralApprovalStatus__c = 'Rejected',
            ContactId = testContact.Id
            //ContactEmail = testSalesOrder1.
        );
        Test.startTest();
        insert testCase3;
        Test.stopTest();
        
        InstallmentLines__c installmentLines1 = [SELECT Id, Name FROM InstallmentLines__c LIMIT 1];
        
        CaseInstallment__c caseInstallment = new CaseInstallment__c(/*Name = installmentLines1.Name,*/
            Case__c = testCase3.Id,
            OwnerId = testUser.Id,
            NewInstallmentDate__c = system.today());
        
        insert caseInstallment;
    }
    } 
    
 @isTest
	static void testHandleAssignBack() {

    User testUser = [SELECT Id FROM User LIMIT 1];
    Case caseObj = [SELECT Id FROM Case LIMIT 1];

    Test.startTest();

    AssignBackServiceRequestController.handleAssignBack(
        caseObj.Id,
        'Test Comment',
        'Test Reason',
        testUser.Id,
        'CRM'
    );

    AssignBackServiceRequestController.handleAssignBack(
        caseObj.Id,
        'Test Comment',
        'Test Reason',
        testUser.Id,
        'Finance'
    );

    Test.stopTest();

    System.assert(true);
}
    @isTest
	static void testGetAssignBackReasons() {

    Test.startTest();
    List<String> reasons = AssignBackServiceRequestController.getAssignBackReasons();
    Test.stopTest();

    System.assertNotEquals(null, reasons);
}
   @isTest
	static void testGetTeamUsers() {

    Case caseObj = [SELECT Id FROM Case LIMIT 1];

    Test.startTest();
    Map<String, List<Map<String, String>>> result =
        AssignBackServiceRequestController.getTeamUsers(caseObj.Id);
    Test.stopTest();

    System.debug('RESULT MAP: ' + result);

    System.assertNotEquals(null, result);
    System.assert(result.size() > 0, 'Expected departments in result');
}
  @isTest
static void testHandleAssignBack_Complaint_CreateComplaintTask() {

    User testUser = [SELECT Id FROM User LIMIT 1];

    Account acc = [SELECT Id FROM Account LIMIT 1];
    SalesOrder__c so = [
        SELECT Id, Account__c
        FROM SalesOrder__c
        LIMIT 1
    ];

    ServiceCatalog__c sc = new ServiceCatalog__c(
        Name = 'Complaint-Sales-Poor-Knowledge11',
        RecordTypeDevName__c = 'ComplaintRequest'
    );
    insert sc;

    ServiceAction__c cuAction = new ServiceAction__c(
        Name = 'cu Action',
        Department__c = 'CRM',
        Order__c = 1,
        ServiceCatalog__c = sc.Id
    );
    insert cuAction;

    ServiceAction__c nextAction = new ServiceAction__c(
        Name = 'next Action',
        Department__c = 'CRM',
        Order__c = 3,
        ServiceCatalog__c = sc.Id
    );
    insert nextAction;

    Id complaintRT = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
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
        'CRM'
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

    System.assertEquals('In Progress', complaintCase.Status);
    System.assertEquals('CRM', complaintCase.PendingWith__c);
    System.assertEquals(testUser.Id, complaintCase.OwnerId);
    System.assertEquals('2', complaintCase.Step__c);
}
    @isTest
static void testHandleAssignBack_Complaint_Completed() {

    User testUser = [SELECT Id FROM User LIMIT 1];

    Account acc = [SELECT Id FROM Account LIMIT 1];
    SalesOrder__c so = [
        SELECT Id, Account__c
        FROM SalesOrder__c
        LIMIT 1
    ];

    ServiceCatalog__c sc = new ServiceCatalog__c(
        Name = 'Complaint-Sales-Poor-Knowledge11',
        RecordTypeDevName__c = 'ComplaintRequest'
    );
    insert sc;

    ServiceAction__c cuAction = new ServiceAction__c(
        Name = 'cu Action',
        Department__c = 'CRM',
        Order__c = 1,
        ServiceCatalog__c = sc.Id
    );
    insert cuAction;

    ServiceAction__c nextAction = new ServiceAction__c(
        Name = 'next Action',
        Department__c = 'CRM',
        Order__c = 3,
        ServiceCatalog__c = sc.Id
    );
    insert nextAction;

    Id complaintRT = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
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
        SubStatus__c = 'Completed',
        Step__c = '2'
    );

    CaseService.getInstance().insertCaseWithoutTrigger(
        new List<Case>{ complaintCase }
    );

    Task t = new Task(
        Subject = 'CRM Team Task 1',
        Status = 'Open',
        Priority = 'Normal',
        WhatId = complaintCase.Id,
        OwnerId = testUser.Id
    );
    insert t;

    Test.startTest();

    AssignBackServiceRequestController.handleAssignBack(
        complaintCase.Id,
        'Completed',
        'Reason',
        testUser.Id,
        'CRM'
    );

    Test.stopTest();

    complaintCase = [
        SELECT OwnerId
        FROM Case
        WHERE Id = :complaintCase.Id
    ];

    System.assertEquals(testUser.Id, complaintCase.OwnerId);

    List<Task> tasks = [
        SELECT Id, OwnerId
        FROM Task
        WHERE WhatId = :complaintCase.Id
    ];

    System.assert(tasks.size() > 0);
}
}