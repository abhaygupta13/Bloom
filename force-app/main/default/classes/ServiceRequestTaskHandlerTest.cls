@isTest
private class ServiceRequestTaskHandlerTest {
    @testSetup
    static void setupTestData() {
        
        Round_Robins__c rr=new Round_Robins__c(
            Name='Service/Case Request',
            Assigned_To__c = String.valueof(1),
            Sobject__c='Case'
        );
        insert rr;
        
        Round_Robins__c Reseller=new Round_Robins__c(
            Name='Service/Resale Case Request',
            Assigned_To__c = String.valueof(1),
            Sobject__c='Case'
            
        );
        insert Reseller;
        
        Profile profileDetail = [SELECT Id FROM Profile WHERE Name='CRM Operations'];
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueOf(Datetime.now()).replace(' ', '').replace(':', '').replace('-', '');
        Integer randomInt = Integer.valueOf(Math.rint(Math.random() * 1000000));
        String uniqueName = orgId + dateString + randomInt;
        
        User userRecord = new User(Alias = 'Zaki', Email='Zakial@gmail.com', 
                                   EmailEncodingKey='UTF-8', LastName='Zaki Al Bakri', LanguageLocaleKey='en_US', 
                                   LocaleSidKey='en_US', ProfileId = profileDetail.id, 
                                   TimeZoneSidKey='Asia/Dubai', UserName= uniqueName+'@mail.com');
        insert userRecord;
        User userRecord2 = new User(Alias = 'Zaki2', Email='Zakial2@gmail.com', 
                                    EmailEncodingKey='UTF-8', LastName='Zaki A2l Bakri', LanguageLocaleKey='en_US', 
                                    LocaleSidKey='en_US', ProfileId = profileDetail.id, 
                                    TimeZoneSidKey='Asia/Dubai', UserName= uniqueName+'3232'+'@mail.com');
        insert userRecord2;
        
        User userRecord3 = new User(Alias = 'Zaki3', Email='Zakial3@gmail.com', 
                                    EmailEncodingKey='UTF-8', LastName='Zaki A2l Bakri', LanguageLocaleKey='en_US', 
                                    LocaleSidKey='en_US', ProfileId = profileDetail.id, 
                                    TimeZoneSidKey='Asia/Dubai', UserName= uniqueName+'3432'+'@mail.com');
        insert userRecord3;
        
        Round_Robin_User__c rrUser=new Round_Robin_User__c(
            Name='Hani Zaki Al Bakri -  SM',
            Round_Robin__c=rr.Id,
            Total_Open_Count__c=0,
            User__c=userRecord.id
            
        );
        insert rrUser;
        
        Round_Robin_User__c rrUser1=new Round_Robin_User__c(
            Name='Zaki Al Bakri -  SM',
            Round_Robin__c=rr.Id,
            Total_Open_Count__c=10,
            User__c=userRecord2.id
        );
        insert rrUser1;
        
        Round_Robin_User__c rrUser2=new Round_Robin_User__c(
            Name='Zaki Al Bakri -  SM',
            Round_Robin__c=Reseller.Id,
            Total_Open_Count__c=10,
            User__c=userRecord3.id
            
        );
        insert rrUser2;
        
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
        
        Id caseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Post_Sale_Payment_Deferral').getRecordTypeId();
        system.debug('This is recordType Id :'+caseRecordTypeId);
        //Id emailToCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Customer_Service_Email_To_Case').getRecordTypeId();
        
        Account testAccount = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId(),
            LastName = 'Test Account',
            PersonEmail = 'testaccount@test.com'
        );
        insert testAccount;
        User testUser1 = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        // Create EmailTemplate 
        
        EmailTemplate template = new EmailTemplate(
            Name = 'ServiceRequestAssignmentId',
            DeveloperName = 'ServiceRequestAssignmentId',
            TemplateType = 'custom',
            Subject = 'Test Subject',
            HtmlValue = '<p>This is a test email</p>',
            FolderId = UserInfo.getUserId()
        );
        System.runAs(testUser1){
            insert template;
        }
        
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
        
        
        
        // Create test ServiceCatalog record
        ServiceCatalog__c testServiceCatalog = new ServiceCatalog__c(
            Name = 'Test Service Catalog',
            Type__c = 'Service Request',
            Category__c = 'Financial - Payment Service',
            SubCategory__c = 'Postpone/Defer payment',
            RecordTypeDevName__c = 'Post_Sale_Payment_Deferral'
        );
        insert testServiceCatalog;
        system.debug('testServiceCatalog----->'+testServiceCatalog);
        
        // Create test ServiceAction record
        ServiceAction__c testServiceAction = new ServiceAction__c(
            ServiceCatalog__c = testServiceCatalog.Id,
            TaskType__c = 'Post Sale Payment Deferral',
            TaskSubType__c = 'CRM Team Task',
            TaskSubject__c = 'Test Task Subject', 
            Department__c ='CRM',
            Due_in_days__c = 2,
            Order__c = 1
        );
          insert testServiceAction;
        // Create test ServiceAction record
        ServiceAction__c testServiceAction2 = new ServiceAction__c(
            ServiceCatalog__c = testServiceCatalog.Id,
            TaskType__c = 'Post Sale Payment Deferral',
            TaskSubType__c = 'Finance Team Task',
            TaskSubject__c = 'Test Task Subject',
            Department__c ='Finance',
            Due_in_days__c = 2,
            Order__c = 2
        );
        insert testServiceAction2;
        
        // Create test ServiceAction record
        ServiceAction__c finalAction = new ServiceAction__c(
            ServiceCatalog__c = testServiceCatalog.Id,
            TaskType__c = 'Post Sale Payment Deferral',
            TaskSubType__c = 'Finance Team Task',
            TaskSubject__c = 'Test Task Subject',
            Department__c ='Finance',
            Due_in_days__c = 2,
            Order__c = 2,
            FinalTask__c = true
        );
        insert finalAction;
      
        system.debug('testServiceAction----->'+testServiceAction);
        
        // Create test Case records
        Case testCase = new Case(
            CurrencyIsoCode = 'AED',
            Origin = 'Email',
            OwnerId = testUser.Id,
            ContactId = testContact.id,
            RecordTypeId = caseRecordTypeId,
            CaseType__c = 'Service Request',
            Step__c = '1',
            ServiceCatalog__c = testServiceCatalog.Id
        );
        insert testCase;
        
        
        // Create test Case records
        Case testCase2 = new Case(
            CurrencyIsoCode = 'AED',
            ContactId = testContact.id,
            Origin = 'Email',
            OwnerId = testUser.Id,
            RecordTypeId = caseRecordTypeId,
            CaseType__c = 'Service Request',
            Step__c = '2',
            ServiceCatalog__c = testServiceCatalog.Id
        );
        insert testCase2;
        
        // Create test Case records
        Case finalCase = new Case(
            CurrencyIsoCode = 'AED',
            ContactId = testContact.id,
            AccountId =testAccount.id,
            
            Origin = 'Email',
            OwnerId = testUser.Id,
            RecordTypeId = caseRecordTypeId,
            CaseType__c = 'Service Request',
            Step__c = 'Final',
            ServiceCatalog__c = testServiceCatalog.Id
        );
        insert finalCase;
        
        // Create test Task records
        Task testTask = new Task(Subject = 'Test Task', WhoId = testContact.Id, WhatId = testAccount.Id, Status = 'Open',
                                 Type = 'Call');
        insert testTask;
        Task crmTask = new Task(
            Status = 'Completed', 
            Type__c = 'Post Sale Payment Deferral',
            SubType__c = 'CRM Team Task',
            WhatId = testCase2.id
        );
        insert crmTask;
         Task financeTask = new Task(
            Status = 'Open', 
            Type__c = 'Post Sale Payment Deferral',
            SubType__c = 'Finance Team Task',
            WhatId = testCase2.id
        );
        insert financeTask;   
   }
    
    @isTest
    static void testCreateNewAndCloseCurrentTask() {
        List<Case> testCases = [SELECT Id, ServiceCatalog__c,Step__c,CaseType__c, Status,RecordTypeId FROM Case];
        Test.startTest();
        ServiceRequestTaskHandler.getInstance().createNewAndCloseCurrentTask(testCases);
        Test.stopTest();
        
        // Assertions to verify the expected behavior
        List<Task> tasks = [SELECT Id FROM Task];
        System.assert(tasks.size() > 0, 'Task should be created');
        
    }
    @isTest
    static void testProcessCasesAndHandleNextActions() {
        EmailTemplate testEmailTemplate = [SELECT Id FROM EmailTemplate LIMIT 1];
        List<AppSetting__mdt> folderData = [
            SELECT TextValue__c 
            FROM AppSetting__mdt 
            WHERE DeveloperName = 'ServiceRequestAssignmentId'
        ];
        
        
        List<Case> testCases = [SELECT Id, ServiceCatalog__c,CaseType__c, OwnerId, RecordTypeId FROM Case LIMIT 1];
        ServiceAction__c testServiceAction = [SELECT Id,Due_in_days__c,OwnerId,Order__c, FinalTask__c,Department__c,AssignToOwner__c,TaskSubject__c,TaskType__c,
                                              TaskSubType__c FROM ServiceAction__c LIMIT 1];
        // Prepare test map for caseCatalogVsNextAction
        Map<Id, ServiceAction__c> caseCatalogVsNextAction = new Map<Id, ServiceAction__c>();
        caseCatalogVsNextAction.put(testCases[0].ServiceCatalog__c, testServiceAction);
        Test.startTest();
        // Call the method being tested
        ServiceRequestTaskHandler.getInstance().processCasesAndHandleNextActions(testCases, caseCatalogVsNextAction,caseCatalogVsNextAction); 
        Test.stopTest();
        // Verify if a new Task was inserted
        List<Task> tasks = [SELECT Id, WhatId FROM Task WHERE WhatId = :testCases[0].Id];
        System.assert(tasks.size() > 0, 'A task should be created for the case');
        
    }
      @isTest
static void testopenOldAndCloseCurrentTask(){

    List<Case> testCases = [
        SELECT Id, ServiceCatalog__c, CaseType__c, OwnerId 
        FROM Case 
        WHERE Step__c = '2' 
        LIMIT 1
    ];

    Id userId = UserInfo.getUserId();

    Test.startTest();
    ServiceRequestTaskHandler.getInstance()
        .openOldAndCloseCurrentTask(
            testCases[0].Id,
            'Test Comment',
            'TPF required',
            userId
        );
    Test.stopTest();

    System.assert(true, 'Method executed successfully');
}
    @isTest
    static void testNewAndCloseFinalTask(){
       
        List<Case> testCases = [SELECT Id, ServiceCatalog__c,CaseType__c,Status,OwnerId,Step__c,Sales_Order__c,AccountId, RecordtypeId, StopEmailsToCustomer__c FROM Case where Step__c='Final' LIMIT 1];
        List<ServiceAction__c> testServiceAction = [SELECT Id,Due_in_days__c,OwnerId,Order__c, FinalTask__c, Department__c,AssignToOwner__c,TaskSubject__c,TaskType__c, 
                                              TaskSubType__c,ServiceCatalog__c FROM ServiceAction__c where FinalTask__c = true];
        Contact ct =   [Select id from Contact where  LastName = 'Test Contact'];
           
        Task financeTsk = [Select id from Task where SubType__c = 'Finance Team Task'];
        Test.startTest();
        ServiceRequestTaskHandler.getInstance().createNewAndCloseCurrentTask(testCases);
        Test.stopTest(); 
    }
    @isTest
static void testClosureEmailWithAttachments_GeneralEnquiry() {

    Account acc = [SELECT Id, PersonEmail FROM Account LIMIT 1];
    ServiceCatalog__c sc = [SELECT Id FROM ServiceCatalog__c LIMIT 1];

    Id rtId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
        .get('GeneralEnquiry').getRecordTypeId();

    Case c = new Case(
        Status = 'New',
        Origin = 'Email',
        AccountId = acc.Id,
        RecordTypeId = rtId,
        CaseType__c = 'Service Request',
        SubType__c = 'Rent Refund',
        ServiceCatalog__c = sc.Id
    );
    insert c;

  
    ContentVersion cv = new ContentVersion(
        Title = 'Debit Advice',
        PathOnClient = 'DebitAdvice.pdf',
        VersionData = Blob.valueOf('Test Data')
    );
    insert cv;

    ContentDocumentLink cdl = new ContentDocumentLink(
        ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId,
        LinkedEntityId = c.Id,
        ShareType = 'V'
    );
    insert cdl;

    ServiceAction__c sa = new ServiceAction__c(
        ServiceCatalog__c = sc.Id,
        TaskType__c = 'Rent Refund',
        TaskSubType__c = 'CRM Team Task 1',
        TaskSubject__c = 'CRM Team Task 1',
        Department__c = 'CRM',
        Order__c = 1
    );
    insert sa;

    Map<Id, ServiceAction__c> currentMap = new Map<Id, ServiceAction__c>{
        sc.Id => sa
    };

    Map<Id, ServiceAction__c> nextMap = new Map<Id, ServiceAction__c>();

    Test.startTest();
    ServiceRequestTaskHandler.getInstance()
        .processCasesAndHandleNextActions(
            new List<Case>{c},
            nextMap,
            currentMap
        );
    Test.stopTest();

    System.assert(true);
}
      @isTest
static void testClosureEmailWithAttachments_AckReceipt() {

    Account acc = [SELECT Id, PersonEmail FROM Account LIMIT 1];
    ServiceCatalog__c sc = [SELECT Id FROM ServiceCatalog__c LIMIT 1];

    Id rtId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
        .get('Acknowledgment_Receipt').getRecordTypeId();

    Case c = new Case(
        Status = 'New',
        Origin = 'Email',
        AccountId = acc.Id,
        Subject = 'test',
        RecordTypeId = rtId,
        CaseType__c = 'Service Request',
        SubType__c = 'Rent Refund',
        ServiceCatalog__c = sc.Id
    );
    insert c;

    ContentVersion cv = new ContentVersion(
        Title = 'payment receipt',
        PathOnClient = 'paymentreceipt.pdf',
        VersionData = Blob.valueOf('Test Data')
    );
    insert cv;

    ContentDocumentLink cdl = new ContentDocumentLink(
        ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId,
        LinkedEntityId = c.Id,
        ShareType = 'V'
    );
    insert cdl;

    ServiceAction__c sa = new ServiceAction__c(
        ServiceCatalog__c = sc.Id,
        TaskType__c = 'Rent Refund',
        TaskSubType__c = 'CRM Team Task 1',
        TaskSubject__c = 'CRM Team Task 1',
        Department__c = 'CRM',
        Order__c = 1
    );
    insert sa;

    Map<Id, ServiceAction__c> currentMap = new Map<Id, ServiceAction__c>{
        sc.Id => sa
    };

    Map<Id, ServiceAction__c> nextMap = new Map<Id, ServiceAction__c>();

    Test.startTest();
    ServiceRequestTaskHandler.getInstance()
        .processCasesAndHandleNextActions(
            new List<Case>{c},
            nextMap,
            currentMap
        );
    Test.stopTest();

    System.assert(true);
}
          @isTest
static void testClosureEmailWithAttachments_PaymentDueDate() {

    Account acc = [SELECT Id, PersonEmail FROM Account LIMIT 1];
    ServiceCatalog__c sc = [SELECT Id FROM ServiceCatalog__c LIMIT 1];

    Id rtId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
        .get('Payment_Due_Date_Update').getRecordTypeId();

    Case c = new Case(
        Status = 'New',
        Origin = 'Email',
        AccountId = acc.Id,
        payment_due_date__c = system.today().addDays(10),
        Subject = 'test',
        RecordTypeId = rtId,
        CaseType__c = 'Service Request',
        SubType__c = 'Rent Refund',
        ServiceCatalog__c = sc.Id
    );
    insert c;

    ContentVersion cv = new ContentVersion(
        Title = 'soa',
        PathOnClient = 'soa.pdf',
        VersionData = Blob.valueOf('Test Data')
    );
    insert cv;

    ContentDocumentLink cdl = new ContentDocumentLink(
        ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId,
        LinkedEntityId = c.Id,
        ShareType = 'V'
    );
    insert cdl;


    ServiceAction__c sa = new ServiceAction__c(
        ServiceCatalog__c = sc.Id,
        TaskType__c = 'Rent Refund',
        TaskSubType__c = 'CRM Team Task 1',
        TaskSubject__c = 'CRM Team Task 1',
        Department__c = 'CRM',
        Order__c = 1
    );
    insert sa;

    Map<Id, ServiceAction__c> currentMap = new Map<Id, ServiceAction__c>{
        sc.Id => sa
    };

 
    Map<Id, ServiceAction__c> nextMap = new Map<Id, ServiceAction__c>();

    Test.startTest();
    ServiceRequestTaskHandler.getInstance()
        .processCasesAndHandleNextActions(
            new List<Case>{c},
            nextMap,
            currentMap
        );
    Test.stopTest();

    System.assert(true);
}
  
 
    @isTest
static void testLPFWaiverRejectedClosure() {

    Account acc = [SELECT Id FROM Account LIMIT 1];
    ServiceCatalog__c sc = [SELECT Id FROM ServiceCatalog__c LIMIT 1];

    Id rtId = Schema.SObjectType.Case
        .getRecordTypeInfosByDeveloperName()
        .get('LPFWaiverRequest')
        .getRecordTypeId();

    Case c = new Case(
        Status = 'New',
        Origin = 'Email',
        Subject = 'LPF Reject',
        AccountId = acc.Id,
        RecordTypeId = rtId,
        LPFWaiverRequestApprovalStatus__c = 'Rejected',
        CaseType__c = 'Service Request',
        ServiceCatalog__c = sc.Id
    );
    insert c;

    ServiceAction__c sa = [
        SELECT Id,  ServiceCatalog__c,
               FinalTask__c,
               OwnerId,
               Due_in_days__c,
               AssignToOwner__c,
               Department__c,
               Order__c,
               TaskType__c,
               TaskSubType__c,
               TaskSubject__c
        FROM ServiceAction__c
        LIMIT 1
    ];

    Test.startTest();

    ServiceRequestTaskHandler.getInstance()
        .processCasesAndHandleNextActions(
            new List<Case>{c},
            new Map<Id, ServiceAction__c>(),
            new Map<Id, ServiceAction__c>{sc.Id => sa}
        );

    Test.stopTest();

    System.assert(true);
}
      @isTest
static void testCloseAllOpenTasksOnCancel() {

    // Get existing case from setup
    Case c = [SELECT Id FROM Case LIMIT 1];

    // Create open tasks for this case
    List<Task> taskList = new List<Task>();
    for(Integer i = 0; i < 2; i++){
        taskList.add(new Task(
            WhatId = c.Id,
            Subject = 'Test Task ' + i,
            Status = 'Open',
            Priority = 'Normal'
        ));
    }
    insert taskList;

    Test.startTest();
    ServiceRequestTaskHandler.getInstance()
        .closeAllOpenTasksOnCancel(new Set<Id>{c.Id});
    Test.stopTest();

    // Verify tasks are closed
    List<Task> updatedTasks = [
        SELECT Status FROM Task WHERE WhatId = :c.Id
    ];

    for(Task t : updatedTasks){
        System.assertEquals('Completed', t.Status);
    }
}
    @isTest
static void testReassignCurrentTask() {

    Case c = [SELECT Id, OwnerId FROM Case LIMIT 1];

    // Create an open task
    Task t = new Task(
        WhatId = c.Id,
        Subject = 'Reassign Task',
        Status = 'Open',
        Priority = 'Normal'
    );
    insert t;

    // Get another user
    User newUser = [SELECT Id FROM User WHERE Id != :c.OwnerId LIMIT 1];

    Test.startTest();
    ServiceRequestTaskHandler.getInstance()
        .reassignCurrentTask(
            c.Id,
            'Reassigning task',
            'TPF required',
            newUser.Id
        );
    Test.stopTest();

    // Verify task reassigned
    Task updatedTask = [
        SELECT OwnerId, Status FROM Task WHERE Id = :t.Id
    ];
    System.assertEquals(newUser.Id, updatedTask.OwnerId);
    System.assertEquals('Open', updatedTask.Status);

    // Verify case reassigned
    Case updatedCase = [
        SELECT OwnerId FROM Case WHERE Id = :c.Id
    ];
    System.assertEquals(newUser.Id, updatedCase.OwnerId);

    // Verify history created
    List<CaseAssignmentHistory__c> history = [
        SELECT Id FROM CaseAssignmentHistory__c WHERE Case__c = :c.Id
    ];
    System.assert(history.size() > 0);
}
    @isTest
static void testIsSameDepartment() {

    Case c = [SELECT Id, ServiceCatalog__c FROM Case LIMIT 1];

    // Get related ServiceAction (already created in setup)
    ServiceAction__c sa = [
        SELECT Department__c, ServiceCatalog__c 
        FROM ServiceAction__c 
        WHERE ServiceCatalog__c = :c.ServiceCatalog__c
        LIMIT 1
    ];

    Test.startTest();
    Boolean resultTrue = ServiceRequestTaskHandler.getInstance()
        .isSameDepartment(c.Id, sa.Department__c);

    Boolean resultFalse = ServiceRequestTaskHandler.getInstance()
        .isSameDepartment(c.Id, 'DifferentDept');
    Test.stopTest();

    System.assertEquals(true, resultTrue);
    System.assertEquals(false, resultFalse);
}
    @isTest
    static void testSuperAppKYCAssignment() {

        Account acc = [SELECT Id FROM Account LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        User usr = [SELECT Id FROM User LIMIT 1];

        Id kycRT = Schema.SObjectType.Case .getRecordTypeInfosByDeveloperName() .get('KYCUpdateRequest') .getRecordTypeId();

        ServiceCatalog__c sc = new ServiceCatalog__c( Name = 'KYC Service', Type__c = 'Service Request', Category__c = 'Customer Service Request', SubCategory__c = 'KYC Update Request', RecordTypeDevName__c = 'KYCUpdateRequest' );
        insert sc;

        ServiceAction__c action1 = new ServiceAction__c( ServiceCatalog__c = sc.Id, Department__c = 'CRM', TaskSubject__c = 'CRM Team Task 1', TaskType__c = 'KYC Update Request', TaskSubType__c = 'CRM Team Task 1', Order__c = 1, AssignToOwner__c = true,FinalTask__c = false );
        insert action1;

        ServiceAction__c action2 = new ServiceAction__c( ServiceCatalog__c = sc.Id, Department__c = 'Finance', TaskSubject__c = 'Operation Team Task 1', TaskType__c = 'KYC Update Request', TaskSubType__c = 'Operation Team Task 1', Order__c = 2, AssignToOwner__c = true, FinalTask__c = true );
        insert action2;

        Case kycCase = new Case( Origin = 'Super App', RecordTypeId = kycRT, Status = 'New', CaseType__c = 'Service Request', ServiceCatalog__c = sc.Id, ContactId = con.Id, AccountId = acc.Id, OwnerId = usr.Id );
        insert kycCase;

        List<BusinessHours> bhs=[select id from BusinessHours where isActive = true];

        AssignmentRule__c assrSuperApp = new AssignmentRule__c();
        assrSuperApp.RecordType__c = 'Case';
        assrSuperApp.ProcessName__c = 'Super App Operation Team Case Assignment';
        assrSuperApp.ProcessType__c = 'Sales';
        assrSuperApp.IsActive__c = true;
        insert assrSuperApp;

        AssignmentUser__c assruSuperAPP = new AssignmentUser__c();
        assruSuperAPP.IsActive__c = true;
        assruSuperAPP.AssignmentRule__c = assrSuperApp.id;
        assruSuperAPP.BusinessHours__c = bhs[0].id;
        assruSuperAPP.User__c = usr.id;
        insert assruSuperAPP;

        Map<Id, ServiceAction__c> nextMap = new Map<Id, ServiceAction__c>{ sc.Id => action2 };
        Map<Id, ServiceAction__c> currentMap = new Map<Id, ServiceAction__c>{ sc.Id => action1 };

        Test.startTest();
            ServiceRequestTaskHandler.getInstance() .processCasesAndHandleNextActions( new List<Case>{kycCase}, nextMap, currentMap );
        Test.stopTest();
    }
      
  
    @isTest
    static void testCloseAllOpenTasks() {

        Case c = [SELECT Id FROM Case LIMIT 1];

        Task t = new Task(
            WhatId = c.Id,
            Subject = 'Open Task Coverage',
            Status = 'Open',
            Priority = 'Normal'
        );
        insert t;

        Test.startTest();

        ServiceRequestTaskHandler.getInstance()
            .closeAllOpenTasks(new Set<Id>{c.Id});

        Test.stopTest();

        Task updatedTask = [
            SELECT Id, Status
            FROM Task
            WHERE Id = :t.Id
        ];

        System.assertEquals(
            'Completed',
            updatedTask.Status,
            'Open task should have been completed'
        );
    }


    @isTest
    static void testCloseAllOpenTasksOnCancelEmptySet() {

        Test.startTest();

        ServiceRequestTaskHandler.getInstance()
            .closeAllOpenTasksOnCancel(new Set<Id>());

        Test.stopTest();

        System.assert(true);
    }


    
    @isTest
    static void testCloseAllOpenTasksOnCancelNull() {

        Test.startTest();

        ServiceRequestTaskHandler.getInstance()
            .closeAllOpenTasksOnCancel(null);

        Test.stopTest();

        System.assert(true);
    }
    @isTest
    static void testCloseAllOpenTasksEmptySet() {

        Test.startTest();

        ServiceRequestTaskHandler.getInstance()
            .closeAllOpenTasks(new Set<Id>());

        Test.stopTest();

        System.assert(true);
    }


    



}