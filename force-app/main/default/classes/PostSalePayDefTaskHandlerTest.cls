@isTest
private class PostSalePayDefTaskHandlerTest {
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
        List<Case> testCases = [SELECT Id, ServiceCatalog__c,Step__c,CaseType__c, Status FROM Case];
        Test.startTest();
        PostSalePayDefTaskHandler.getInstance().createNewAndCloseCurrentTask(testCases);
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
        
        
        List<Case> testCases = [SELECT Id, ServiceCatalog__c,CaseType__c, OwnerId FROM Case LIMIT 1];
        ServiceAction__c testServiceAction = [SELECT Id,Due_in_days__c,OwnerId,Order__c, FinalTask__c,Department__c,AssignToOwner__c,TaskSubject__c,TaskType__c,
                                              TaskSubType__c FROM ServiceAction__c LIMIT 1];
        // Prepare test map for caseCatalogVsNextAction
        Map<Id, ServiceAction__c> caseCatalogVsNextAction = new Map<Id, ServiceAction__c>();
        caseCatalogVsNextAction.put(testCases[0].ServiceCatalog__c, testServiceAction);
        Test.startTest();
        // Call the method being tested
        PostSalePayDefTaskHandler.getInstance().processCasesAndHandleNextActions(testCases, caseCatalogVsNextAction,caseCatalogVsNextAction); 
        Test.stopTest();
        // Verify if a new Task was inserted
        List<Task> tasks = [SELECT Id, WhatId FROM Task WHERE WhatId = :testCases[0].Id];
        System.assert(tasks.size() > 0, 'A task should be created for the case');
        
    }
    @isTest
    static void testopenOldAndCloseCurrentTask(){
       
        List<Case> testCases = [SELECT Id, ServiceCatalog__c,CaseType__c, OwnerId FROM Case where Step__c='2' LIMIT 1];
         List<ServiceAction__c> testServiceAction = [SELECT Id,Due_in_days__c,OwnerId,Order__c, FinalTask__c, Department__c,AssignToOwner__c,TaskSubject__c,TaskType__c, 
                                              TaskSubType__c,ServiceCatalog__c FROM ServiceAction__c ];
        Task crmTsk = [Select id from Task where SubType__c = 'CRM Team Task'];
        Task financeTsk = [Select id from Task where SubType__c = 'Finance Team Task'];
        Test.startTest();
        PostSalePayDefTaskHandler.getInstance().openOldAndCloseCurrentTask(testCases[0].id,'Test','TPF required');
        Test.stopTest(); 
    }
    @isTest
    static void testNewAndCloseFinalTask(){
       
        List<Case> testCases = [SELECT Id, ServiceCatalog__c,CaseType__c,Status,OwnerId,Step__c,AccountId FROM Case where Step__c='Final' LIMIT 1];
        List<ServiceAction__c> testServiceAction = [SELECT Id,Due_in_days__c,OwnerId,Order__c, FinalTask__c, Department__c,AssignToOwner__c,TaskSubject__c,TaskType__c, 
                                              TaskSubType__c,ServiceCatalog__c FROM ServiceAction__c where FinalTask__c = true];
        Contact ct =   [Select id from Contact where  LastName = 'Test Contact'];
           
        Task financeTsk = [Select id from Task where SubType__c = 'Finance Team Task'];
        Test.startTest();
        PostSalePayDefTaskHandler.getInstance().createNewAndCloseCurrentTask(testCases);
        Test.stopTest(); 
    }
    
    
}