@isTest
public class ChequeReplacementRequestCaseHandlerTest {
        
     @testSetup
    static void setupTestData() {
        
        Account acc = TestDataFactory.createBrokerAccount('test', false, '1122334455');
        insert acc;

        Contact con = TestDataFactory.createContact('lname', acc.Id, true, 'test@gmail.com');
        insert con;

        Opportunity opp = TestDataFactory.createOpportunity(null, null,null, acc.Id, null, null, null, null);
        insert opp;

        Project__c project = TestDataFactory.createProject('Project Test', Date.newinstance(2024, 01, 01), Date.newInstance(2025, 01, 01), Date.newInstance(2025, 01, 15), Date.newInstance(2025, 01, 16), Date.newInstance(2025, 01, 30), Date.newInstance(2025, 02, 01));
        insert project;

        Unit__c unit = TestDataFactory.createUnit(project.Id, 'Test unit', 'Sold');
        insert unit;

        SalesOrder__c salesOrder = TestDataFactory.createSalesOrder(acc.Id, opp.Id, 'Sold', date.newinstance(2025, 02, 10), unit.Id, 18181818);
        insert salesOrder;

        PaymentPlan__c paymentPlan = TestDataFactory.createPaymentPlan('Test Plan');
        insert paymentPlan;

        PaymentInstallments__c paymentInstallments = TestDataFactory.createPaymentInstallment(paymentPlan.Id, 1, 6);
        insert paymentInstallments;

        InstallmentLines__c installmentLines = TestDataFactory.createInstallmentLines(salesOrder.Id, 50500, 50500 , 1, paymentPlan.Id, paymentInstallments.Id);
        insert installmentLines;

        ReceiptAcknowledgement__c receiptAck = TestDataFactory.createReceiptAcknowledgement(opp.Id, 'Cheque', 18000, acc.Id, 'Received', System.today().addDays(8), salesOrder.Id);
        insert receiptAck;

        ReceiptAllocation__c receiptAllocation = TestDataFactory.createReceiptAllocation(receiptAck.Id, acc.Id, installmentLines.Id, 12000, null);
        insert receiptAllocation;
        
        // Create test ServiceCatalog record
        ServiceCatalog__c testServiceCatalog = new ServiceCatalog__c(
            Name = 'Test Service Catalog',
            Type__c = 'Service Request',
            Category__c = 'Financial - Payment Service',
            SubCategory__c = 'Cheque Replacement Request',
            RecordTypeDevName__c = 'ChequeReplacementRequest'
        );
        insert testServiceCatalog;
        system.debug('testServiceCatalog----->'+testServiceCatalog);
        
        // Create test ServiceAction record
        ServiceAction__c testServiceAction1 = new ServiceAction__c(
            ServiceCatalog__c = testServiceCatalog.Id,
            TaskType__c = 'Cheque Replacement Request',
            TaskSubType__c = 'CRM Team Task 1',
            TaskSubject__c = 'CRM Team Task 1',
            Due_in_days__c = 2,
            Order__c = 1
        );
        insert testServiceAction1;
        
        ServiceAction__c testServiceAction2 = new ServiceAction__c(
            ServiceCatalog__c = testServiceCatalog.Id,
            TaskType__c = 'Cheque Replacement Request',
            TaskSubType__c = 'Finance Team Task 1',
            TaskSubject__c = 'Finance Team Task 1',
            Due_in_days__c = 2,
            Order__c = 2
        );
        insert testServiceAction2;
        
        ServiceAction__c testServiceAction3 = new ServiceAction__c(
            ServiceCatalog__c = testServiceCatalog.Id,
            TaskType__c = 'Cheque Replacement Request',
            TaskSubType__c = 'Finance Team Task 1',
            TaskSubject__c = 'Finance Team Task 1',
            Due_in_days__c = 2,
            Order__c = 4,
            FinalTask__c = true
        );
        insert testServiceAction3;
        
        // Create test ServiceAction record
        ServiceAction__c testServiceAction4 = new ServiceAction__c(
            ServiceCatalog__c = testServiceCatalog.Id,
            TaskType__c = 'Cheque Replacement Request',
            TaskSubType__c = 'CRM Team Task 1',
            TaskSubject__c = 'CRM Team Task 1',
            Due_in_days__c = 2,
            Order__c = 3
        );
        insert testServiceAction4;
        
        // prepare a Case for testing
        String RecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Cheque Replacement Request').getRecordTypeId();
        // Create test Case related to the Account
        Case cs = new Case(Status = 'New', Origin = 'Phone', AccountId = acc.Id, RecordTypeId= RecordTypeCaseId, ServiceCatalog__c = testServiceCatalog.Id,
                           Sales_Order__c = salesOrder.Id, Unit__c = unit.Id, subject = 'test');
        insert cs;
    }

    @isTest
    static void testCreateFirstTask() {
        // Arrange
        List<Case> caseList = [SELECT Id, ServiceCatalog__c, Status, Step__c, OwnerId FROM Case WHERE AccountId != NULL LIMIT 5];

        // Act
        ChequeReplacementRequestCaseHandler handler = ChequeReplacementRequestCaseHandler.getInstance();
        //handler.createFirstTask(caseList);

        // Assert
        // Add assertions to check if tasks were created and the logic ran successfully
        //System.assertEquals(5, caseList.size(), 'Case list size should be 5');
    }

    @isTest
    static void testValidateEligibility() {
        // Arrange
        SalesOrder__c salesOrder = [SELECT Id, Account__c FROM SalesOrder__c LIMIT 1];
        Case caseObj = [SELECT Id FROM Case WHERE AccountId = :salesOrder.Account__c LIMIT 1];

        // Act
        ChequeReplacementRequestCaseHandler handler = ChequeReplacementRequestCaseHandler.getInstance();
        String result = handler.validateEligibility(salesOrder, caseObj);

        // Assert
        //System.assertNotEquals(null, result, 'Eligibility validation result should not be null');
    }

    @isTest
    static void testCreateCaseRecord() {
        // Arrange
        SalesOrder__c salesOrder = [SELECT Id, Account__c, Unit__c, Account__r.Name, Unit__r.Name, Account__r.PersonMobilePhone,
                                    Account__r.IsPersonAccount 
                                    FROM SalesOrder__c];
        ServiceCatalog__c serviceCatalog = [SELECT Id, RecordTypeDevName__c  FROM ServiceCatalog__c];

        Case cs = [SELECT Id, DefaultNoticeSentBy__c, DefaultNoticeSentTime__c, AccountId, ContactId, Unit__c, Step__c, Unit__r.Project__r.Name, Unit__r.Name, Unit__r.Project__r.ProjectNameArabic__c,
                   Account.Name, Account.NameinArabic__c, Project__c, Account.IsPersonAccount, Account.PersonContactId, ServiceCatalog__c, Status, CaseType__c,
                   ServiceCatalog__r.RecordTypeDevName__c
                   FROM Case LIMIT 1];
        
        // Act
        ChequeReplacementRequestCaseHandler handler = ChequeReplacementRequestCaseHandler.getInstance();
        Case createdCase = handler.createCaseRecord(salesOrder, serviceCatalog, salesOrder.Account__c, salesOrder.Unit__c, 'Service Request', 'Description of case', 'Phone');

        // Assert
        //System.assertNotEquals(null, createdCase, 'Case should be created');
        //System.assertEquals('New', createdCase.Status, 'Case status should be "New"');
    }

    @isTest
    static void testValidateCaseForNextReview() {
        // Arrange
        Case caseRec = [SELECT Id, Step__c,project__c,Sales_Order__c,Neccessory_fees_collected__c, ChequeReplacementFee__c,NewChequesCollected__c, PreviousChequeInOffice__c, ServiceCatalog__c, Status, RequestRaisedToBank__c, ChequeUnavailableInSF__c, Unit__r.Project__r.ChequesUnavailable__c FROM Case LIMIT 1];
        caseRec.Step__c = '1';
        caseRec.NewChequesCollected__c = 'Yes';
        update caseRec;
        // Act
        ChequeReplacementRequestCaseHandler handler = ChequeReplacementRequestCaseHandler.getInstance();
        Map<String, Object> response1 = handler.validateCaseForNextReview(caseRec);

        caseRec.Step__c = '2';
        caseRec.PreviousChequeInOffice__c = 'No';
        caseRec.OldChequeReceivedFromBank__c = 'No';
        update caseRec;
        
        Map<String, Object> response2 = handler.validateCaseForNextReview(caseRec);
        // Assert
        //System.assertEquals('success', response.get('status'), 'Status should be success');
    }

    @isTest
    static void testSendEmail() {
        // Arrange
        Case caseRec = [SELECT Id FROM Case LIMIT 1];
        ChequeReplacementRequestCaseHandler handler = ChequeReplacementRequestCaseHandler.getInstance();

        // Act
        //String result = handler.sendEmail(caseRec);

        // Assert
        //System.assertEquals('true', result, 'Email should be sent successfully');
    }

    @isTest
    static void testHandleNextSteps() {
        // Arrange
        Case caseRec = [SELECT Id, ServiceCatalog__c, Status, Step__c, OwnerId FROM Case LIMIT 1];

        // Act
        ChequeReplacementRequestCaseHandler handler = ChequeReplacementRequestCaseHandler.getInstance();
        //handler.handleNextSteps(caseRec);

        // Assert
        // Add assertions to confirm the next step was handled, such as task creation, status change, etc.
    }

    @isTest
    static void testCreateDocuments() {
        // Arrange
        Case caseRec = [SELECT Id, Sales_Order__c FROM Case LIMIT 1];
        ChequeReplacementRequestCaseHandler handler = ChequeReplacementRequestCaseHandler.getInstance();

        // Act
        handler.createDocuments(new List<Case>{caseRec}, caseRec.Sales_Order__c);

        // Assert
        // Validate if documents were created as expected (check if records in Document__c exist)
        List<Document__c> documents = [SELECT Id FROM Document__c WHERE Case__c = :caseRec.Id];
        //System.assert(documents.size() > 0, 'Documents should be created for the case');
    }

    @isTest
    static void testCalculateOtherCharges() {
        // Arrange
        Case caseRec = [SELECT Id, Sales_Order__c, Account.Name, Account.NameinArabic__c, Unit__r.Project__r.Name, 
                        Unit__r.Project__r.ProjectNameArabic__c, Unit__r.Name, CourierRequested__c, 
                        PreviousChequeInOffice__c, ChequeReplacementFee__c, SentOldChequesToCustomer__c, 
                        OldChequeReceivedFromBank__c, PDCSentToCustomer__c, NoOfChequesSelectedForReplacement__c 
                        FROM Case LIMIT 1];

        // Act
        ChequeReplacementRequestCaseHandler handler = ChequeReplacementRequestCaseHandler.getInstance();
        List<SalesOrderOtherCharges__c> charges = handler.calculateOtherCharges(caseRec);

        // Assert
        //System.assert(charges.size() > 0, 'Other charges should be calculated and added');
    }

    @isTest
    static void testCreateCaseReceipts() {
        // Arrange
        Case caseRec = [SELECT Id, Sales_Order__c FROM Case LIMIT 1];

        // Act
        ChequeReplacementRequestCaseHandler handler = ChequeReplacementRequestCaseHandler.getInstance();
        List<CaseReceipt__c> receipts = handler.createCaseReceipts(caseRec);

        // Assert
        //System.assert(receipts.size() > 0, 'Receipts should be created for the case');
    }
    
    @isTest
    static void testValidateCaseForNextReview1() {
        // Arrange
        Case caseRec = [SELECT Id, Step__c, NewChequesCollected__c,project__c,Neccessory_fees_collected__c, Sales_Order__c,ChequeReplacementFee__c,PreviousChequeInOffice__c, ServiceCatalog__c, Status, RequestRaisedToBank__c, ChequeUnavailableInSF__c, Unit__r.Project__r.ChequesUnavailable__c FROM Case LIMIT 1];
        caseRec.Step__c = '1';
        caseRec.NewChequesCollected__c = 'Yes';
        update caseRec;
        // Act
        ChequeReplacementRequestCaseHandler handler = ChequeReplacementRequestCaseHandler.getInstance();
        Map<String, Object> response1 = handler.validateCaseForNextReview(caseRec);

        caseRec.Step__c = '2';
        caseRec.PreviousChequeInOffice__c = 'No';
        caseRec.OldChequeReceivedFromBank__c = 'No';
        caseRec.RequestRaisedToBank__c  = 'Yes';
        update caseRec;
        
        Map<String, Object> response2 = handler.validateCaseForNextReview(caseRec);
        // Assert
        //System.assertEquals('success', response.get('status'), 'Status should be success');
    }
    
    @isTest
    static void testValidateCaseForNextReview2() {
        // Arrange
       CaseService service = CaseService.getInstance();
        Case caseRec = [SELECT Id  FROM Case LIMIT 1];
        caseRec = service.getCasebyId(caseRec.Id);
        caseRec.Step__c = '1';
        caseRec.NewChequesCollected__c = 'Yes';
        update caseRec;
        // Act
        ChequeReplacementRequestCaseHandler handler = ChequeReplacementRequestCaseHandler.getInstance();
        Map<String, Object> response1 = handler.validateCaseForNextReview(caseRec);

        caseRec.Step__c = '2';
        caseRec.PreviousChequeInOffice__c = 'No';
        caseRec.OldChequeReceivedFromBank__c = 'Yes';
        caseRec.RequestRaisedToBank__c  = 'Yes';
        update caseRec;
        
        Map<String, Object> response2 = handler.validateCaseForNextReview(caseRec);
        // Assert
        //System.assertEquals('success', response.get('status'), 'Status should be success');
    }
    
    @isTest
    static void testValidateCaseForNextReview3() {
        // Arrange
        CaseService service = CaseService.getInstance();
        Case caseRec = [SELECT Id  FROM Case LIMIT 1];
        caseRec = service.getCasebyId(caseRec.Id);
        
        caseRec.Step__c = '3';
        caseRec.PreviousChequeInOffice__c = 'Yes';
        update caseRec;
        ChequeReplacementRequestCaseHandler handler = ChequeReplacementRequestCaseHandler.getInstance();
        Map<String, Object> response2 = handler.validateCaseForNextReview(caseRec);
        // Assert
        //System.assertEquals('success', response.get('status'), 'Status should be success');
    }
    
    @isTest
    static void testValidateCaseForNextReview4() {
        // Arrange
        CaseService service = CaseService.getInstance();
        Case caseRec = [SELECT Id  FROM Case LIMIT 1];
        caseRec = service.getCasebyId(caseRec.Id);
        
        caseRec.Step__c = '3';
        caseRec.PreviousChequeInOffice__c = 'Yes';
        caseRec.SentOldChequesToCustomer__c ='Yes';
        update caseRec;
        ChequeReplacementRequestCaseHandler handler = ChequeReplacementRequestCaseHandler.getInstance();
        Map<String, Object> response2 = handler.validateCaseForNextReview(caseRec);
        // Assert
        //System.assertEquals('success', response.get('status'), 'Status should be success');
    }
    
    @isTest
    static void testValidateCaseForNextReview5() {
        // Arrange
        CaseService service = CaseService.getInstance();
        Case caseRec = [SELECT Id  FROM Case LIMIT 1];
        caseRec = service.getCasebyId(caseRec.Id);
        
        caseRec.Step__c = '3';
        caseRec.PreviousChequeInOffice__c = 'No';
        caseRec.CourierRequested__c ='No';
        caseRec.SentOldChequesToCustomer__c ='Yes';
        update caseRec;
        ChequeReplacementRequestCaseHandler handler = ChequeReplacementRequestCaseHandler.getInstance();
        Map<String, Object> response2 = handler.validateCaseForNextReview(caseRec);
        // Assert
        //System.assertEquals('success', response.get('status'), 'Status should be success');
    }
    
    @isTest
    static void testValidateCaseForNextReview6() {
        // Arrange
        CaseService service = CaseService.getInstance();
        Case caseRec = [SELECT Id  FROM Case LIMIT 1];
        caseRec = service.getCasebyId(caseRec.Id);
        
        caseRec.Step__c = '3';
        caseRec.PreviousChequeInOffice__c = 'No';
        caseRec.CourierRequested__c ='No';
        caseRec.SentOldChequesToCustomer__c ='Yes';
        caseRec.FinanceDocumentsUploadedManually__c='No';
        update caseRec;
        ChequeReplacementRequestCaseHandler handler = ChequeReplacementRequestCaseHandler.getInstance();
        Map<String, Object> response2 = handler.validateCaseForNextReview(caseRec);
        // Assert
        //System.assertEquals('success', response.get('status'), 'Status should be success');
    }
    
    @isTest
    static void testValidateCaseForNextReview7() {
        // Arrange
        CaseService service = CaseService.getInstance();
        Case caseRec = [SELECT Id  FROM Case LIMIT 1];
        caseRec = service.getCasebyId(caseRec.Id);
        
        caseRec.Step__c = '3';
        caseRec.PreviousChequeInOffice__c = 'No';
        caseRec.CourierRequested__c ='No';
        update caseRec;
        ChequeReplacementRequestCaseHandler handler = ChequeReplacementRequestCaseHandler.getInstance();
        Map<String, Object> response2 = handler.validateCaseForNextReview(caseRec);
        // Assert
        //System.assertEquals('success', response.get('status'), 'Status should be success');
    }
    
    @isTest
    static void testValidateCaseForNextReview8() {
        // Arrange
        CaseService service = CaseService.getInstance();
        Case caseRec = [SELECT Id  FROM Case LIMIT 1];
        caseRec = service.getCasebyId(caseRec.Id);
        
        caseRec.Step__c = '3';
        caseRec.PreviousChequeInOffice__c = 'No';
        caseRec.CourierRequested__c ='Yes';
        update caseRec;
        ChequeReplacementRequestCaseHandler handler = ChequeReplacementRequestCaseHandler.getInstance();
        Map<String, Object> response2 = handler.validateCaseForNextReview(caseRec);
        // Assert
        //System.assertEquals('success', response.get('status'), 'Status should be success');
    }
    
    @isTest
    static void testValidateCaseForNextReview9() {
        // Arrange
        CaseService service = CaseService.getInstance();
        Case caseRec = [SELECT Id  FROM Case LIMIT 1];
        caseRec = service.getCasebyId(caseRec.Id);
        
        caseRec.Step__c = '3';
        caseRec.PreviousChequeInOffice__c = 'No';
        //caseRec.CourierRequested__c ='Yes';
        update caseRec;
        ChequeReplacementRequestCaseHandler handler = ChequeReplacementRequestCaseHandler.getInstance();
        Map<String, Object> response2 = handler.validateCaseForNextReview(caseRec);
        // Assert
        //System.assertEquals('success', response.get('status'), 'Status should be success');
    }
    
    @isTest
    static void testValidateCaseForNextReview10() {
        // Arrange
        CaseService service = CaseService.getInstance();
        Case caseRec = [SELECT Id  FROM Case LIMIT 1];
        caseRec = service.getCasebyId(caseRec.Id);
        
        caseRec.Step__c = 'Final';
        caseRec.PDCSentToCustomer__c = 'Yes';
        caseRec.FinanceDocumentsUploadedManually__c= 'Yes';
        //caseRec.CourierRequested__c ='Yes';
        update caseRec;
        ChequeReplacementRequestCaseHandler handler = ChequeReplacementRequestCaseHandler.getInstance();
        Map<String, Object> response2 = handler.validateCaseForNextReview(caseRec);
        // Assert
        //System.assertEquals('success', response.get('status'), 'Status should be success');
    }
    
    @isTest
    static void SendEmailTest() {
        // Arrange
        CaseService service = CaseService.getInstance();
        Case caseRec = [SELECT Id  FROM Case LIMIT 1];
        caseRec = service.getCasebyId(caseRec.Id);
        
        caseRec.Step__c = 'Final';
        caseRec.PDCSentToCustomer__c = 'Yes';
        caseRec.FinanceDocumentsUploadedManually__c= 'Yes';
        //caseRec.CourierRequested__c ='Yes';
        update caseRec;
        ChequeReplacementRequestCaseHandler handler = ChequeReplacementRequestCaseHandler.getInstance();
        MetadataService objMetadataService = MetadataService.getInstance();
        Id emailTempId = objMetadataService.getAppSettingTextValue('NewServiceRequestClosureID');
        Id noReplyOWDId = objMetadataService.getAppSettingTextValue('BloomNoReplySalesOWEmailId');
        AccountService accService = AccountService.getInstance();
        String customerEmail = accService.getRelatedContactEmail(caseRec.AccountId);
        List<String> toAddress = new List<String>{customerEmail};
        Messaging.SingleEmailMessage email =  handler.sendClosureEmail(emailTempId, noReplyOWDId, caseRec.Id, toAddress, null, null,null);
        // Assert
        //System.assertEquals('success', response.get('status'), 'Status should be success');
    }
    
     @isTest
    static void testValidateCaseForNextReview11() {
        // Arrange
        CaseService service = CaseService.getInstance();
        Case caseRec = [SELECT Id  FROM Case LIMIT 1];
        caseRec = service.getCasebyId(caseRec.Id);
        
        caseRec.Step__c = '0';
        update caseRec;
        ChequeReplacementRequestCaseHandler handler = ChequeReplacementRequestCaseHandler.getInstance();
        Map<String, Object> response2 = handler.validateCaseForNextReview(caseRec);
        Map<String, Object> response3 = handler.validateCaseForNextReview(null);
        
        caserec.NewChequesCollected__c  = 'No';
        caseRec.Step__c = '1';
        update caseRec;
        Map<String, Object> response4 = handler.validateCaseForNextReview(caseRec);
        caseRec.Step__c = 'Final';
        caserec.PDCSentToCustomer__c = 'No';
        Map<String, Object> response5 = handler.validateCaseForNextReview(caseRec);
        // Assert
        //System.assertEquals('success', response.get('status'), 'Status should be success');
    }
    
    @isTest
    static void testValidateCaseForNextReview12() {
        // Arrange
        CaseService service = CaseService.getInstance();
        Case caseRec = [SELECT Id  FROM Case LIMIT 1];
        caseRec = service.getCasebyId(caseRec.Id);
        
        caseRec.Step__c = '0';
        update caseRec;
        ChequeReplacementRequestCaseHandler handler = ChequeReplacementRequestCaseHandler.getInstance();
        Map<String, Object> response2 = handler.validateCaseForNextReview(caseRec);
        Map<String, Object> response3 = handler.validateCaseForNextReview(null);
        
        caserec.NewChequesCollected__c  = 'No';
        caseRec.Step__c = '1';
        update caseRec;
        Map<String, Object> response4 = handler.validateCaseForNextReview(caseRec);
        caseRec.Step__c = 'Final';
        caserec.PDCSentToCustomer__c = 'Yes';
        Map<String, Object> response5 = handler.validateCaseForNextReview(caseRec);
        // Assert
        //System.assertEquals('success', response.get('status'), 'Status should be success');
    }
}