@isTest
private class PostSalePaymentDeferalCaseHandlerTest {
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
        test.startTest();
        Id caseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Post_Sale_Payment_Deferral').getRecordTypeId();
        //Id emailToCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Customer_Service_Email_To_Case').getRecordTypeId(); 
        
        Account testAccount = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId(),
            LastName = 'Test Account',
            PersonEmail = 'testaccount@test.com',
            NameinArabic__c = 'عميل تجريبي'
        );
        insert testAccount; 
        
              // Account
        Account acc = new Account(
            Name = 'Test Customer',
            NameinArabic__c = 'عميل تجريبي'
        );
        insert acc;

        // Create Contact with Email
        Contact testContact = new Contact(
            LastName = 'Test Contact',
            Email = 'sonali.sengar@infobeans.com',
            AccountId = acc.id
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
            Name='Test Project',
            chequePostponeFeeLongTerm__c = 100,
            chequePostponeFeeShortTerm__c = 200,
            ChequePostponementFeeCondType__c ='P092'
        );
        insert testProject;
        
       
        
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
            Account__c = testAccount.Id,
            Unit__c = testUnit.Id,
            Opportunity__c = testOpportunity.Id
        );
        insert testSalesOrder;
        
        SalesOrder__c testSalesOrder1 = new SalesOrder__c(
            Name = 'Test Sales Order1',
            Status__c = 'Sold',
            //Offer__c = testOfferPromotion.Id,
            Account__c = testAccount.Id,
            IsDefaulted__c = true,
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
        installmentLines.InstallmentDate__c= Date.today() + 2;
        installmentLines.AmountReceived__c=1500;
        installmentLines.CutOffDate__c=date.today();
        installmentLines.LPCAmount__c=500;
        insert installmentLines;
        
        SalesOrderOtherCharges__c soc = TestDataFactory.createOtherCharge(testSalesOrder1.id, testAccount.id, 'ADM Fee', false, null, null, null, null, null, 12000);
        insert soc;
        ReceiptAcknowledgement__c testData1 = TestDataFactory.createReceiptAcknowledgement(testOpportunity.id, 'Online', 12000, testAccount.Id, 'Received', null, testSalesOrder1.id);
        insert testData1;

        ReceiptAllocation__c rec = TestDataFactory.createReceiptAllocation(testData1.id, testAccount.id, installmentLines.id, 12000, soc.id);
        insert rec;
     
        // Create test ServiceCatalog record
        ServiceCatalog__c testServiceCatalog = new ServiceCatalog__c(
            Name = 'Test Service Catalog',
            Type__c = 'Service Request',
            Category__c = 'Financial - Payment Service',
            SubCategory__c = 'Postpone/Defer payment',
            RecordTypeDevName__c = 'Post_Sale_Payment_Deferral'
        );
        insert testServiceCatalog;        
        Case testCase = new Case(
            CurrencyIsoCode = 'AED',
            Origin = 'Walk-In',
            Subject = 'test',
            OwnerId = testUser.Id,
            RecordTypeId = caseRecordTypeId,
            Sales_Order__c = testSalesOrder1.Id,
            CaseType__c = 'Service Request',
            ServiceCatalog__c = testServiceCatalog.Id,
            Case_Contact_Name__c = testContact.Id,
            ContactId = testContact.Id
      );
       
        
        Case testCase1 = new Case(
            CurrencyIsoCode = 'AED',
            Origin = 'Walk-In',
            OwnerId = testUser.Id,
            Subject = 'test',
            RecordTypeId = caseRecordTypeId,
            Sales_Order__c = testSalesOrder1.Id,
            CaseType__c = 'Service Request',
            ServiceCatalog__c = testServiceCatalog.Id,
            Unit__c = testUnit.ID,
             ContactId = testContact.Id,
            Step__c = String.valueOf(1),
            Deferral_Fee_Paid__c = 'Yes',
            PaymentDeferralReason__c = 'Changing date with replacing the cheque'
        );
        
        
        Case testCase2 = new Case(
            CurrencyIsoCode = 'AED',
            Origin = 'Walk-In',
            OwnerId = testUser.Id,
            Subject = 'test',
            RecordTypeId = caseRecordTypeId,
            Sales_Order__c = testSalesOrder1.Id,
            ContactId = testContact.Id,
            CaseType__c = 'Service Request',
            ServiceCatalog__c = testServiceCatalog.Id,
            Step__c = String.valueOf(2),
            Deferral_Within_1_Month__c = 'Yes',
            ChequeScanned__c =  'Yes' ,
            Deferral_Fee_Paid__c = 'Yes'
        );
        
        
        Case testCase3 = new Case(
            CurrencyIsoCode = 'AED',
            Origin = 'Walk-In',
            OwnerId = testUser.Id,
            Subject = 'test',
            RecordTypeId = caseRecordTypeId,
            CaseType__c = 'Service Request',
            AccountId = testAccount.id,
            Sales_Order__c = testSalesOrder1.Id,
            ServiceCatalog__c = testServiceCatalog.Id,
            Step__c = String.valueOf(2),
            Deferral_Within_1_Month__c = 'No',
            ChequeScanned__c =  'No' ,
            Deferral_Fee_Paid__c = 'No',
            DeferralApprovalStatus__c = 'Approved',
            ContactId = testContact.Id
        );
       
        
   
          Case testCase4 = new Case(
            CurrencyIsoCode = 'AED',
            Origin = 'Email',
            Subject = 'test',
            OwnerId = testUser.Id,
            RecordTypeId = caseRecordTypeId,
            ContactId = testContact.Id,
            AccountId = testAccount.id
        
        );
        
     insert new List<Case>{ testCase, testCase1, testCase2, testCase3, testCase4 };
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
            Task crmTask = new Task(
            Status = 'Completed', 
            Type__c = 'Post Sale Payment Deferral',
            SubType__c = 'CRM Team Task',
            WhatId = testCase1.id
        );
        insert crmTask;
        Task financeTask = new Task( 
            Status = 'Open', 
            Type__c = 'Post Sale Payment Deferral',
            SubType__c = 'Finance Team Task',
            WhatId = testCase2.id
        );
        insert financeTask;
        
      
        
        CaseInstallment__c caseInstallment = new CaseInstallment__c(/*Name = installmentLines1.Name,*/
            Case__c = testCase3.Id,
            OwnerId = testUser.Id,
            Installment__c = installmentLines.id,
            NewInstallmentDate__c = system.today().addDays(5));
        
        insert caseInstallment;
        CaseInstallment__c caseInstallment1 = new CaseInstallment__c(/*Name = installmentLines1.Name,*/
            Case__c = testCase1.Id,
            OwnerId = testUser.Id,
            Installment__c = installmentLines.id,
            NewInstallmentDate__c = system.today().addDays(5));
        
        insert caseInstallment1;
         CaseInstallment__c caseInstallment2 = new CaseInstallment__c(
            Case__c = testCase4.Id,
            OwnerId = testUser.Id,
            Installment__c = installmentLines.id);
          
        
        insert caseInstallment2;
       // Create setup objects separately
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
   System.runAs(u) {

    EmailTemplate et = new EmailTemplate(
        Name = 'TP Form Template',
        DeveloperName = 'TP_Form_Template',
        FolderId = UserInfo.getUserId(),
        TemplateType = 'custom',
        Subject = 'Test Subject',
        Body = 'Test Body'
    );

    insert et;
}
    
      
        test.stoptest();
        
    }
    
    @isTest
    static void testCreateFirstTask(){
        List<Case> testCases = [SELECT Id, RecordTypeId,Status,Step__c,CaseType__c, ServiceCatalog__c FROM Case where Step__c ='1'];
        Task crmTsk = [Select id from Task where SubType__c = 'CRM Team Task'];
        Task financeTsk = [Select id from Task where SubType__c = 'Finance Team Task'];
        ServiceAction__c testServiceAction = [SELECT Id,Due_in_days__c,OwnerId,Order__c, FinalTask__c, Department__c, AssignToOwner__c,TaskSubject__c,TaskType__c, 
                                              TaskSubType__c,ServiceCatalog__c FROM ServiceAction__c];
        Test.startTest();
        PostSalePaymentDeferalCaseHandler.getInstance().createFirstTask(testCases);
        Test.stopTest();
        
    }
    
    @isTest
    static void testValidateEligibility() {
        SalesOrder__c testSalesOrder = [SELECT Id, Status__c,First_Installment_Received_Amount__c FROM SalesOrder__c WHERE Name ='Test Sales Order' LIMIT 1];
        
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        String message = PostSalePaymentDeferalCaseHandler.getInstance().validateEligibility(testSalesOrder, testCase);
        
        
        
        System.debug('message---->'+message);
        System.assertEquals('This unit is not eligible for the selected service request', message, 'Only Sold order should be eligible.');
    }
    
    @isTest
    static void testConvertToComplaint() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        ServiceCatalog__c testServiceCatalog = [SELECT Id, RecordTypeDevName__c FROM ServiceCatalog__c LIMIT 1];
        
        Map<String, String> response = PostSalePaymentDeferalCaseHandler.getInstance().convertToComplaint(testCase.Id, testServiceCatalog, null, null,'Service Request','test',null);
        System.assertEquals('error', response.get('status'), 'Case should be converted successfully.');
    }
    
    @isTest
    static void testConvertToComplaint_Exception() {
        ServiceCatalog__c testServiceCatalog = [SELECT Id, RecordTypeDevName__c FROM ServiceCatalog__c LIMIT 1];
        
        Id fakeCaseId = '001000000000AAA';  // Invalid ID, which will cause an exception
        
        Test.startTest();
        Map<String, String> result = PostSalePaymentDeferalCaseHandler.getInstance().convertToComplaint(fakeCaseId, testServiceCatalog, null, null,'Service Request','test',null);
        Test.stopTest();
        
        System.assertEquals('error', result.get('status'), 'Expected error status');
        System.assert(result.get('message').contains('Error updating case'), 'Error message should be returned');
    }
    @isTest
    static void testAfterUpdate(){
        Case testCase3 = [SELECT Id, Step__c,ServiceCatalog__c, Status,
                          Deferral_Fee_Paid__c,ChequeScanned__c, Deferral_Within_1_Month__c, DeferralApprovalStatus__c
                          FROM Case WHERE Origin ='Email' and AccountId!=null LIMIT 1];
        Id caseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Post_Sale_Payment_Deferral').getRecordTypeId();
        Test.startTest();
        testCase3.RecordTypeId = caseRecordTypeId;
        Test.stopTest();
    }
    
    @isTest
    static void testGetDefaultValues(){ 
        SalesOrder__c testSalesOrder = [SELECT Id, Offer__c, Offer__r.Name,First_Installment_Received_Amount__c,
                                        First_Installment_Amount__c, Account__c,Account__r.Name, Unit__c, Unit__r.Name FROM SalesOrder__c WHERE Name = 'Test Sales Order1' LIMIT 1];
        Id recordTypeId  = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        Account testAccount = [SELECT Id FROM Account where  RecordTypeId = :recordTypeId];
        ServiceCatalog__c testServiceCatalogue = [SELECT Id,RecordTypeDevName__c,SubCategory__c FROM ServiceCatalog__c];
        Unit__c testUnit = [SELECT Id FROM Unit__c];
        Test.startTest();
        
        Case caseObj = PostSalePaymentDeferalCaseHandler.getInstance().createCaseRecord(testSalesOrder, testServiceCatalogue, testAccount.Id, testUnit.Id,'Service Request','test',null,false);
         Test.stopTest();
        System.assertNotEquals(null, caseObj, 'Result map should not be null');
        System.assertEquals(testSalesOrder.Account__c, caseObj.get('AccountId'), 'AccountId should match Sales Order Account');
        System.assertEquals(testServiceCatalogue.Id, caseObj.get('ServiceCatalog__c'), 'ServiceCatalog__c should match the input ServiceCatalog Id');
        System.assertEquals(testSalesOrder.Unit__c, caseObj.get('Unit__c'), 'Unit__c should match Sales Order Unit');
        System.assertEquals('New', caseObj.get('Status'), 'Status should be set to New');
        System.assertEquals('Walk-In', caseObj.get('Origin'), 'Origin should be Walk-in');
    }
    
    @isTest
    static void testCreateCaseInstallments() {
       
        Case testCase = [SELECT Id,Sales_Order__c,Step__c,AccountId,CaseType__c,RecordTypeId,Status,ServiceCatalog__c FROM Case WHERE DeferralApprovalStatus__c = 'Approved' LIMIT 1];
        SalesOrder__c order = [Select id from SalesOrder__c where name ='Test Sales Order1'];
        InstallmentLines__c ins = [Select id from InstallmentLines__c where SalesOrder__c = :order.id];
        Test.startTest();
        PostSalePaymentDeferalCaseHandler.getInstance().createCaseInstallments(new List<Case>{testCase});
        //PostSalePaymentDeferalCaseHandler.getInstance().handleNextSteps(testCase);
        testCase.PaymentDeferralReason__c='';
        testCase.Step__c ='1';
        update testCase;
        PostSalePaymentDeferalCaseHandler.getInstance().checkRequiredFields(testCase);
        Test.stopTest();
        
       
    }
    
    @isTest
    static void testValidateCaseForNextReview() {
        Case testCase = [SELECT Id, Step__c FROM Case LIMIT 1];
        
        Test.startTest();
        Map<String, Object> response = PostSalePaymentDeferalCaseHandler.getInstance().validateCaseForNextReview(testCase);
        Map<String, Object> response2 = PostSalePaymentDeferalCaseHandler.getInstance().validateCaseForNextReview(null);
        Test.stopTest();
        System.assertEquals('error', response.get('status'), 'Validation should fail due to missing fields.');
    }
    
    
    @isTest
    static void testCheckRequiredFields(){
        Case testCase = [SELECT Id, Step__c,ServiceCatalog__c, Status FROM Case LIMIT 1];
        Case testCase2 = [SELECT Id, Step__c,ServiceCatalog__c, Status,
                          Deferral_Fee_Paid__c,ChequeScanned__c, Deferral_Within_1_Month__c,WithdrawlRequestInitiated__c FROM Case WHERE Step__c = '2' LIMIT 1];
        
        Test.startTest();
        PostSalePaymentDeferalCaseHandler.getInstance().checkRequiredFields(testCase);
        //PostSalePaymentDeferalCaseHandler.checkRequiredFields(testCase1);
        PostSalePaymentDeferalCaseHandler.getInstance().checkRequiredFields(testCase2);
        Test.stopTest();
    }
    
    
    @isTest
    static void testValidateCaseEligibility(){
        Case testCase3 = [SELECT Id, Step__c,ServiceCatalog__c, Status,
                          Deferral_Fee_Paid__c,ChequeScanned__c, Deferral_Within_1_Month__c, DeferralApprovalStatus__c
                          FROM Case WHERE Deferral_Within_1_Month__c = 'No' LIMIT 1];
        Case testCase4 = [SELECT Id, Origin
                          FROM Case WHERE Origin = 'Email' LIMIT 1];
        CaseInstallment__c installment = [Select id from CaseInstallment__c where Case__c=:testCase4.id];
        
        
        Test.startTest();
        
        PostSalePaymentDeferalCaseHandler.getInstance().validateCaseEligibility(testCase3.id);
        PostSalePaymentDeferalCaseHandler.getInstance().validateCaseEligibility(testCase4.id);
        
        Test.stopTest(); 
    }
    
    @isTest
    static void testCopyNewInstallmentDates(){
        Case testCase3 = [SELECT Id, Step__c,ServiceCatalog__c, Status,
                          Deferral_Fee_Paid__c,ChequeScanned__c, Deferral_Within_1_Month__c, DeferralApprovalStatus__c,Sales_Order__r.Project__c
                          FROM Case WHERE Deferral_Within_1_Month__c = 'No' LIMIT 1];
        
        List<CaseInstallment__c> caseInstallments = [SELECT Id,Installment__c,NewInstallmentDate__c FROM CaseInstallment__c limit 1];
        ReceiptAllocation__c alloc = [Select id,ReceiptAcknowledgement__c from ReceiptAllocation__c limit 1];
       
        
        Test.startTest();
        
        PostSalePaymentDeferalCaseHandler.getInstance().copyNewInstallmentDates(caseInstallments, testCase3);
        
        Test.stopTest();
    }
    
   
    
    @isTest
    static void testValidateForDeferralApproval(){
        Case testCase1 = [SELECT Id, Step__c,ServiceCatalog__c, Status,
                          Deferral_Fee_Paid__c,ChequeScanned__c, Deferral_Within_1_Month__c, DeferralApprovalStatus__c
                          FROM Case WHERE Deferral_Within_1_Month__c = 'No'  LIMIT 1];
        List<CaseInstallment__c> caseIns = [Select Id, NewInstallmentDate__c,InstallmentDate__c from CaseInstallment__c];
        
        Test.startTest();
        
        PostSalePaymentDeferalCaseHandler.validateForDeferralApproval(testCase1);
       
        Test.stopTest();
    }
    @isTest
    static void testValidateForDeferralFeeCalculation(){
        Case testCase1 = [SELECT Id, Step__c,ServiceCatalog__c, Status,Sales_Order__c,AccountId,
                          Deferral_Fee_Paid__c,ChequeScanned__c,Unit__r.Project__r.chequePostponeFeeShortTerm__c,Unit__r.Project__r.chequePostponeFeeLongTerm__c, Deferral_Within_1_Month__c, DeferralApprovalStatus__c
                          FROM Case WHERE Step__c ='1'];
        List<CaseInstallment__c> caseIns = [Select Id, NewInstallmentDate__c,InstallmentDate__c from CaseInstallment__c];
        
        Test.startTest();
        PostSalePaymentDeferalCaseHandler obj = PostSalePaymentDeferalCaseHandler.getInstance();
        obj.evaluateDeferralFeeAndCalculateOtherCharges(testCase1);
        Test.stopTest();
    }
    
    @isTest
    static void testHandleDeferralApproval(){
        Case testCase = [SELECT Id, Step__c,ServiceCatalog__c, Status,
                          Deferral_Fee_Paid__c,ChequeScanned__c, Deferral_Within_1_Month__c, DeferralApprovalStatus__c,Sales_Order__r.Project__c
                          FROM Case WHERE DeferralApprovalStatus__c = 'Approved' LIMIT 1];
        
        Test.startTest();
        
        PostSalePaymentDeferalCaseHandler.validateForDeferralApproval(testCase);
        
        Test.stopTest();
    }
        @isTest
    static void testPostponeApproval(){
        Case testCase = [SELECT Id, Step__c,ServiceCatalog__c, Status,
                          Deferral_Fee_Paid__c,ChequeScanned__c,PostponeApproved__c, Deferral_Within_1_Month__c, DeferralApprovalStatus__c,Sales_Order__r.Project__c
                          FROM Case WHERE DeferralApprovalStatus__c = 'Approved' LIMIT 1];
        SalesOrder__c order = [Select id from SalesOrder__c where name ='Test Sales Order1'];
        InstallmentLines__c ins = [Select id from InstallmentLines__c where SalesOrder__c = :order.id];
        List<CaseInstallment__c> ci = [Select id,Installment__c,NewInstallmentDate__c from CaseInstallment__c where Case__c=:testCase.id] ; 
                                    
        Test.startTest();
        
        PostSalePaymentDeferalCaseHandler.getInstance().postponeApprovalUpdate(testCase.id,'Yes');
        
        Test.stopTest();
    }
  
     @isTest
    static void testValidatePOPDocument() {
     Case testCase = [SELECT Id, Step__c
                          FROM Case WHERE DeferralApprovalStatus__c = 'Approved' LIMIT 1];

        // Create and insert the custom Document__c record
        Document__c testDoc = new Document__c(
            Document_Name__c = 'Proof of Payment',
            Case__c = testCase.Id 
        );
        insert testDoc;

        // Create test ContentVersion (this automatically creates a ContentDocument)
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'testfile.pdf',
            VersionData = Blob.valueOf('Test content')
        );
        insert contentVersion;

        // Query the auto-created ContentDocument
        ContentDocument contentDoc = [SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId = :contentVersion.Id LIMIT 1];

        // Link the ContentDocument to the Document__c record
        ContentDocumentLink docLink = new ContentDocumentLink(
            ContentDocumentId = contentDoc.Id,
            LinkedEntityId = testDoc.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert docLink;

        // Call the method under test
        Test.startTest();
        List<ContentDocumentLink> result = PostSalePaymentDeferalCaseHandler.validatePOPDocument(testCase); // Replace with your actual class name
        Test.stopTest();

        // Assert results
        System.assertEquals(1, result.size(), 'Should return one ContentDocumentLink');
        System.assertEquals(testDoc.Id, result[0].LinkedEntityId, 'LinkedEntityId should match test document ID');
    }
    @isTest
    static void testValidatePaymentDeferralFeeReceipt() {
     Case testCase = [SELECT Id, Step__c
                          FROM Case WHERE DeferralApprovalStatus__c = 'Approved' LIMIT 1];

        // Create and insert the custom Document__c record
        Document__c testDoc = new Document__c(
            Document_Name__c = 'Payment Deferral Fees Receipt',
            Case__c = testCase.Id 
        );
        insert testDoc;

        // Create test ContentVersion (this automatically creates a ContentDocument)
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'testfile.pdf',
            VersionData = Blob.valueOf('Test content')
        );
        insert contentVersion;

        // Query the auto-created ContentDocument
        ContentDocument contentDoc = [SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId = :contentVersion.Id LIMIT 1];

        // Link the ContentDocument to the Document__c record
        ContentDocumentLink docLink = new ContentDocumentLink(
            ContentDocumentId = contentDoc.Id,
            LinkedEntityId = testDoc.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert docLink;

        // Call the method under test
        Test.startTest();
        List<ContentDocumentLink> result = PostSalePaymentDeferalCaseHandler.validatePaymentDeferralFeeReceipt(testCase); // Replace with your actual class name
        Test.stopTest();

        // Assert results
        System.assertEquals(1, result.size(), 'Should return one ContentDocumentLink');
        System.assertEquals(testDoc.Id, result[0].LinkedEntityId, 'LinkedEntityId should match test document ID');
    }
      @isTest
    static void testGetCaseInstallments() {
     Case testCase3 = [SELECT Id, Step__c,ServiceCatalog__c, Status,
                          Deferral_Fee_Paid__c,ChequeScanned__c, Deferral_Within_1_Month__c, DeferralApprovalStatus__c
                          FROM Case WHERE Deferral_Within_1_Month__c = 'No' LIMIT 1];
        Case testCase4 = [SELECT Id, Step__c,ServiceCatalog__c, Status,
                          Deferral_Fee_Paid__c,ChequeScanned__c, Deferral_Within_1_Month__c, DeferralApprovalStatus__c
                          FROM Case WHERE Deferral_Within_1_Month__c = 'Yes' LIMIT 1];
        List<CaseInstallment__c> caseInstallments = [SELECT Id,Installment__c,NewInstallmentDate__c,Case__c FROM CaseInstallment__c];
        Test.startTest(); 
        //PostSalePaymentDeferalCaseHandler.getCaseInstallments(testCase3.id);
        PostSalePaymentDeferalCaseHandler.validateForDeferralApproval(testCase4);
        Test.stopTest();
    }
    @isTest
    static void testPostponeApprovalUpdate_NullCaseId() {
       PostSalePaymentDeferalCaseHandler obj = PostSalePaymentDeferalCaseHandler.getInstance();
        Map<String, Object> result = obj.postponeApprovalUpdate(null, 'Yes');
        System.assertEquals('error', result.get('status'));
        System.assertEquals('Invalid Case ID.', result.get('message'));
    }
      @isTest
    static void testPostponeApprovalUpdate_ExceptionHandling() {
         Case testCase = [SELECT Id, Step__c,ServiceCatalog__c, Status,
                          Deferral_Fee_Paid__c,ChequeScanned__c, Deferral_Within_1_Month__c, DeferralApprovalStatus__c
                          FROM Case WHERE Deferral_Within_1_Month__c = 'No' LIMIT 1];


        Test.startTest();
        PostSalePaymentDeferalCaseHandler obj = PostSalePaymentDeferalCaseHandler.getInstance();
        Map<String, Object> result = obj.postponeApprovalUpdate(testCase.Id, 'Yes');
         Map<String, Object> resultForEmptyValue = obj.postponeApprovalUpdate(testCase.Id, '');
        Test.stopTest();

       System.assertEquals('success', result.get('status'));
    }


    @isTest
    static void testValidateEligibility_ElseIf_DefaultedUnit() {
        
          Case testCase = [SELECT Id, Step__c,ServiceCatalog__c, Status,
                          Deferral_Fee_Paid__c,ChequeScanned__c, Deferral_Within_1_Month__c, DeferralApprovalStatus__c
                          FROM Case WHERE Deferral_Within_1_Month__c = 'No' LIMIT 1];
       SalesOrder__c salesOrder = [SELECT Id,Status__c,IsDefaulted__c, Offer__c, Offer__r.Name,First_Installment_Received_Amount__c,
                                        First_Installment_Amount__c, Account__c,Account__r.Name, Unit__c, Unit__r.Name FROM SalesOrder__c WHERE Name = 'Test Sales Order1' LIMIT 1];

     
        // Call the method
        PostSalePaymentDeferalCaseHandler obj = PostSalePaymentDeferalCaseHandler.getInstance();  // Replace with your actual class
        String result = obj.validateEligibility(salesOrder, testCase);

        // Verify the 'else if' block was hit
        System.assertEquals(
            'A payment deferral request cannot be created for a defaulted unit',
            result
        );
    }
     @isTest
    static void testValidateEligibility_CaseMissingFields() { 
        SalesOrder__c salesOrder = null;
        Case testCase = [SELECT Id,Sales_Order__c,PaymentDeferralReason__c,Deferral_Fee_Paid__c,CaseType__c,RecordTypeId,ServiceCatalog__c,status,AccountId,Unit__c,Step__c,StopEmailsToCustomer__c from Case where Step__c='2' Limit 1]; 
        PostSalePaymentDeferalCaseHandler obj = PostSalePaymentDeferalCaseHandler.getInstance(); 
        String result = obj.validateEligibility(salesOrder, testCase);
        
        obj.handleNextSteps(testCase);
        testCase.Step__c = '1';
        testCase.PaymentDeferralReason__c ='Changing date';
        testCase.Deferral_Fee_Paid__c = 'Yes';
        testCase.DeferralApprovalStatus__c = 'Approved';
        List<Case> caseList = new  List<Case>();
        caseList.add(testCase);
        CaseService.getInstance().updateCasesWithoutTrigger(caseList);
        obj.checkRequiredFields(testCase);
        PostSalePaymentDeferalCaseHandler.handleDeferralApproval(testCase);
        testCase.DeferralApprovalStatus__c = 'Rejected';
        CaseService.getInstance().updateCasesWithoutTrigger(caseList);
        PostSalePaymentDeferalCaseHandler.handleDeferralApproval(testCase);
        testCase.DeferralApprovalStatus__c = '';
        CaseService.getInstance().updateCasesWithoutTrigger(caseList);
                PostSalePaymentDeferalCaseHandler.handleDeferralApproval(testCase);
       
    }
     @IsTest
    static void testSendTPFormCustomerEmail() {

        Case cs = [SELECT Id FROM Case LIMIT 1];

        Test.startTest();
        PostSalePaymentDeferalCaseHandler.getInstance().sendTPFormCustomerEmail(cs.Id);
        Test.stopTest();
    }


}