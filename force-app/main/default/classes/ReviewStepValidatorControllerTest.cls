@isTest
public class ReviewStepValidatorControllerTest {

    
    @TestSetup
    public static void setupTestData() {
        // Create test ServiceCatalog record
        ServiceCatalog__c testServiceCatalog = new ServiceCatalog__c(
            Name = 'Test Service Catalog',
            Type__c = 'Service Request',
            Category__c = 'BFM Service',
            SubCategory__c = 'BFM Service Request',
            RecordTypeDevName__c = 'Post_Sale_Payment_Deferral'
        );
        insert testServiceCatalog;
        system.debug('testServiceCatalog----->'+testServiceCatalog);

        // Create test ServiceAction record
        ServiceAction__c testServiceAction = new ServiceAction__c(
            ServiceCatalog__c = testServiceCatalog.Id,
            TaskType__c = 'Post Sale Payment Deferral',
            TaskSubType__c = 'Post Sale Payment Deferral',
            Order__c = 1
        );
        insert testServiceAction;
        system.debug('testServiceAction----->'+testServiceAction);
        
         Account testAccount = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId(),
            LastName = 'Test Account',
            PersonEmail = 'testaccount@test.com'
        );
        insert testAccount;
        
        // Create test Events related to the test Account
        Event event1 = new Event(
            WhatId = testAccount.Id,
            Subject = 'Test Event 1',
            StartDateTime = DateTime.now(),
            EndDateTime = DateTime.now().addHours(2)
        );
        Event event2 = new Event(
            WhatId = testAccount.Id,
            Subject = 'Test Event 2',
            StartDateTime = DateTime.now().addDays(1),
            EndDateTime = DateTime.now().addDays(1).addHours(2)
        );
        insert new List<Event>{ event1, event2 };
        
        // Create Test Opportunity
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'New',
            CloseDate = System.today(),
            LeadChannel__c = 'Walk in',
            AccountId = testAccount.Id,
            WinReason__c = 'Loyalty'
        );
        insert testOpportunity;
        
        // Create Test Project
        Project__c testProject=new Project__c(
            Name='Test Project'
        );
        insert testProject;
        
        // Create Test Buidling
        BuildingSection__c testBuilding=new BuildingSection__c(
            Name='Test Building',
            BuildingSectionCode__c='BL-CAS',
            Project__c=testProject.Id
            
        );
        insert testBuilding;
        
        // Create Test Unit
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
        
        // Create Test Sales Order
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
        
        // Create test Case record
        Case testCase = new Case(
            CurrencyIsoCode = 'AED',
            Origin = 'Email',
            Status = 'Assigned',
            Step__c = '1',
            //OwnerId = testUser.Id,
            RecordTypeId = caseRecordTypeId,
            Sales_Order__c = testSalesOrder.Id,
            ServiceCatalog__c = testServiceCatalog.Id
        );
        insert testCase;
    }
    
    @isTest
    static void testValidateForNextReview() {
        // Fetch the test case inserted in @TestSetup
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        
        // Call the method
        Test.startTest();
        Map<String, Object> result = ReviewStepValidatorController.validateForNextReview(testCase.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Expected a non-null response');
    }
    
    @isTest
    static void testValidateForNextReviewEmpty() {
		Id recordId = null;        
        // Call the method
        Test.startTest();
        Map<String, Object> result = ReviewStepValidatorController.validateForNextReview(recordId);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Expected a null response');
    }
    
    @isTest
    static void testValidateForCaseReview() {
        // Fetch the test case inserted in @TestSetup
        Case testCase = [SELECT Id,Unit__r.Name,Unit__r.Project__r.name,owner.name,owner.email,CaseNumber,City__c,Unit__r.UnitType__c,
                        Unit__r.RegistrationDate__c,Account__r.Legal_Status__c,BouncedChequeFees__c,LatePaymentFees__c,
                        PendingFees__c,Sales_Order__r.NetAmount__c,PaymentReceived__c,Sales_Order__r.Account__c,
                        Sales_Order__r.name,Mobile_Number__c, Unit__r.Project__r.ProjectNameArabic__c, Account.NameinArabic__c,
                        Account.Name, NumberOfDefaultNoticeRemindersSent__c, Account__c,Account.Legal_Status__c,
                        Last_Name__c,First_Name__c,Mobile_Country_Code__c,Emirates_ID_expiry_date__c,Nationality__c,Email_Address__c,PostponementFeesBooked__c,PostponeApproved__c,
                        Subject, RequesterRemarks__c, Description, Unit__r.BFMUnitNumber__c, Unit__r.Building__r.Name, Unit__r.BuildingSectionName__r.Name, Customer_Name__c, Account_Mobile_Number__c, Account_Email__c,
                        RequesterName__c, RequesterContactNumber__c, RequesterEmail__c, AccountId, Account.PersonEmail, Account.RecordTypeId, Account.RecordType.DeveloperName, RefundAmount__c,
                        Unit__c,Unit__r.Active_Sales_Order__c,Unit__r.Active_Sales_Order__r.Account__c,BFMServiceRequestId__c,Account.IsBFMVIPCustomer__c, Drawloop_Next_1__c, Contacts_Case_Email__c,
                        Priority, RequestType__c, Discipline__c, Type, Category__c, SubCategory__c, Origin, InAMC__c, InScope__c, Area__c,Status,Request_Number__c,User_Type__c,
                        OwnerId, CreatedById, RoundRobinNumber__c,Sales_Order__c,contact.email,Sales_Order__r.Sales_Order_Number__c,Contact.Name,WithdrawlRequestInitiated__c, TotalInstalmentDue__c,
                        Sales_Order__r.Offer__r.Name,Sales_Order__r.First_Installment_Received_Amount__c,DeferralApprovalStatus__c,Deferral_Within_1_Month__c, Project__c, Account.IsPersonAccount, Account.PersonContactId,
                        Sales_Order__r.First_Installment_Amount__c,Sales_Order__r.Offer__c,RecordTypeId,ServiceCatalog__c,DefaultNoticeSentTime__c,DefaultNoticeSentBy__c,Service_Catalog__c,
                        IsDPCleared__c,RecordType.Name,RecordType.DeveloperName,Sales_Order__r.Unit__r.Name,Sales_Order__r.Project__c,Step__c,PaymentDeferralReason__c,ChequeScanned__c,Deferral_Fee_Paid__c,Comments,CaseType__c
                        FROM Case LIMIT 1];
        
        // Call the internal method directly
        Test.startTest();
        Map<String, Object> result = ReviewStepValidatorController.validateForCaseReview(testCase);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Expected a non-null response');
    }
    
    @isTest
    static void testValidateForCaseReviewEmpty() {
        
        Case caseobj = null;
        // Call the internal method directly
        Test.startTest();
        Map<String, Object> result = ReviewStepValidatorController.validateForCaseReview(caseobj);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Expected a null response');
    }
    
    ///////////////////////////////
    @isTest
    private static void createCaseTest1(){
        List<Case> caseList = [SELECT Id,AccountId, Unit__c FROM Case LIMIT 1];
        caseList[0].recordtypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Third Party Form').getRecordTypeId();
        caseList[0].step__c = '1';
        update caseList;
        Test.startTest();
        ReviewStepValidatorController.validateForNextReview(caseList[0].id);
        Test.stopTest();
    }
    
    @isTest
    private static void createCaseTest2(){
        List<Case> caseList = [SELECT Id,AccountId, Unit__c FROM Case LIMIT 1];
        caseList[0].recordtypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Payment SR').getRecordTypeId();
        caseList[0].step__c = '1';
        update caseList;
        Test.startTest();
        ReviewStepValidatorController.validateForNextReview(caseList[0].id);
        Test.stopTest();
    }
    
    @isTest
    private static void createCaseTest3(){
        List<Case> caseList = [SELECT Id,AccountId, Unit__c FROM Case LIMIT 1];
        caseList[0].recordtypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType,'Acknowledgment_Receipt');
        caseList[0].step__c = '1';
        update caseList;
        Test.startTest();
        ReviewStepValidatorController.validateForNextReview(caseList[0].id);
        Test.stopTest();
    }
    
    @isTest
    private static void createCaseTest4(){
        List<Case> caseList = [SELECT Id,AccountId, Unit__c FROM Case LIMIT 1];
        caseList[0].recordtypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType,'Payment_Due_Date_Update');
        caseList[0].step__c = '1';
        update caseList;
        Test.startTest();
        ReviewStepValidatorController.validateForNextReview(caseList[0].id);
        Test.stopTest();
    }
   @isTest
   static void testQueueOwnerValidation() {

    Group queue = new Group(
        Name = 'Test Queue',
        Type = 'Queue'
    );
    insert queue;  
    QueueSobject qs = new QueueSobject(
        QueueId = queue.Id,
        SobjectType = 'Case'
    );
    insert qs;

    Profile p = [SELECT Id FROM Profile LIMIT 1];
    User u = new User(
        Alias = 'testu',
        Email = 'testuser@test.com',
        EmailEncodingKey = 'UTF-8',
        LastName = 'Test',
        LanguageLocaleKey = 'en_US',
        LocaleSidKey = 'en_US',
        ProfileId = p.Id,
        TimeZoneSidKey = 'Asia/Kolkata',
        UserName = 'testuser' + System.currentTimeMillis() + '@test.com'
    );
    insert u;
    
    Case testCase = [SELECT Id FROM Case LIMIT 1];
    System.runAs(u) {       
        testCase.OwnerId = queue.Id;
        update testCase;
        Test.startTest();
        Map<String, Object> result = ReviewStepValidatorController.validateForNextReview(testCase.Id);
        Test.stopTest();
        System.assertEquals('error', result.get('status'));
        System.assertEquals('Assign to yourself before proceeding', result.get('message'));
    }
}

@isTest
static void test_WithOpenTask() {

    Profile p = [SELECT Id FROM Profile LIMIT 1];
    User u = new User(
        Alias = 'testu',
        Email = 'testuser@test.com',
        EmailEncodingKey = 'UTF-8',
        LastName = 'Test',
        LanguageLocaleKey = 'en_US',
        LocaleSidKey = 'en_US',
        ProfileId = p.Id,
        TimeZoneSidKey = 'Asia/Kolkata',
        UserName = 'testuser' + System.currentTimeMillis() + '@test.com'
    );
    insert u;
        
        Id caseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Post_Sale_Payment_Deferral').getRecordTypeId();
    Id caseRecTypeResale = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Resale_Property_For_Completed_Project').getRecordTypeId();
           Id caseRecordTypeAR= Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Acknowledgment_Receipt').getRecordTypeId();
    Id caseRecTypePaymentDueDate= Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Payment_Due_Date_Update').getRecordTypeId();
       
        Id caseCRRRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ChequeReplacementRequest').getRecordTypeId();
    Id caseCWRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ChequeWithdrawalRequest').getRecordTypeId();
           Id caseLPFWaiverRecordTypeId= Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('LPFWaiverRequest').getRecordTypeId();
    Id caseSOARecTypeId= Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('SOARequest').getRecordTypeId();


    System.runAs(u) {

        // Create test Case record
        Case testCase = new Case(
            CurrencyIsoCode = 'AED',
            Origin = 'Email',
            Status = 'Assigned',
            Step__c = '1',
            OwnerId = u.Id,
            RecordTypeId = caseRecordTypeId
          
        );
        insert testCase;

        // Create OPEN task for same user
        Task t = new Task(
            Subject = 'Follow up',
            Status = 'Not Started', // open status
            Priority = 'Normal',
            OwnerId = u.Id,
            WhatId = testCase.Id
        );
        insert t;

        Test.startTest();

        Map<String, Object> response =
        ReviewStepValidatorController.validateForCaseReview(testCase);
        testCase.RecordTypeId = caseRecTypeResale;
        update testCase;
        ReviewStepValidatorController.validateForCaseReview(testCase);        
        testCase.RecordTypeId = caseRecordTypeAR;
        update testCase;
        ReviewStepValidatorController.validateForCaseReview(testCase);  
        testCase.RecordTypeId = caseRecTypePaymentDueDate;
        update testCase;
        ReviewStepValidatorController.validateForCaseReview(testCase);  
         
        testCase.RecordTypeId = caseCRRRecordTypeId;
        update testCase;
        ReviewStepValidatorController.validateForCaseReview(testCase);        
        testCase.RecordTypeId = caseCWRecTypeId;
        update testCase;
        ReviewStepValidatorController.validateForCaseReview(testCase);  
        testCase.RecordTypeId = caseLPFWaiverRecordTypeId;
        update testCase;
        ReviewStepValidatorController.validateForCaseReview(testCase);  
       
        Test.stopTest();

        /* Add assertions based on expected outcome
        System.assertNotEquals(
            'You must have at least one open task assigned to you before marking the case as complete.',
            (String)response.get('message')
        );*/
    }
}

}