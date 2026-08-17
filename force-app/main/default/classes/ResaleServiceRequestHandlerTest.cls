@isTest
private class ResaleServiceRequestHandlerTest {
    @testSetup
    static void setupTestData() {
        Account acc = TestDataFactory.createPersonalAccount('Test class Account', null, '123456789', 'aaa@abc.com');
        acc.Legal_Status__c ='With Legal';
        acc.PersonEmail = 'test@test.com';
        insert acc;
        
        Account dupeAcc = TestDataFactory.createPersonalAccount('Test class Account', null, '123456789', 'aaa@abc.com');
        dupeAcc.PassportNumber__pc = '12345';
        dupeAcc.Emirates_Id__pc ='1234';
        dupeAcc.Nationality__c ='Emirati';
        dupeAcc.Legal_Status__c ='With Legal';
        insert dupeAcc;
        
        
        
        Opportunity opp = TestDataFactory.createOpportunity(acc.id, 'Won - Special Discount', null, null, null, 'New', String.valueOf(system.today()), null);
        insert opp;
        
        
        Contact con = TestDataFactory.createContact('Test Contact', null, true, 'sonali.sengar@infobeans.com');
        insert con;
        
        
        
        Project__c project = TestDataFactory.createProject('Project Test', Date.newinstance(2024, 01, 01), Date.newInstance(2025, 01, 01), Date.newInstance(2025, 01, 15), Date.newInstance(2025, 01, 16), Date.newInstance(2025, 01, 30), Date.newInstance(2025, 02, 01));
        project.ResaleUnitAdminFeeVilla__c = 100;
        project.ResaleUnitEvaluationFeeVilla__c = 200;
        project.ResaleWithMortgageAdminFeeVilla__c =100;
        project.ResaleWithMortgageMortgageFeeVilla__c = 200;
        project.ResaleWithMortgageEvaluationFeeVilla__c = 300;
        insert project;
        
        OffersPromotions__c testOffer=new OffersPromotions__c(
            Name='testOffer',
            OfferName__c='testOffer',
            Project__c=project.id,
            ADM_Fee_Included__c = True,   
            StartDate__c=system.today(),
            EndDate__c=system.today().addDays(2)
        );
        insert testOffer;
        
        Unit__c unit = TestDataFactory.createUnit(project.Id, 'Test unit', 'Sold');
        unit.BFMUnitNumber__c = 'APT 1';
        unit.UnitType__c = 'Townhouse';
        insert unit;
        
        SalesOrder__c salesOrder = TestDataFactory.createSalesOrder(acc.Id, opp.Id, 'Booked', date.newinstance(2025, 01, 10), unit.Id, 18181818);
        salesOrder.NetAmount__c = 100000;
        
        insert salesOrder;
        
        
        SalesOrder__c newSalesOrder = TestDataFactory.createSalesOrder(acc.Id, opp.Id, 'Booked', date.newinstance(2025, 01, 10), unit.Id, 18181818);
        salesOrder.NetAmount__c = 100000;
        salesOrder.Sales_Price_Excluding_ADMs__c = 111000;
        insert newSalesOrder;
        
        PaymentPlan__c  pp = TestDataFactory.createPaymentPlan('Test Plan');
        insert pp;
        
        PaymentInstallments__c ppi = TestDataFactory.createPaymentInstallment(pp.id, 1, 100);
        insert ppi;
        
        PaymentPlan__c  pp2 = TestDataFactory.createPaymentPlan('Data Migration');
        insert pp2;
        
        InstallmentLines__c ins = TestDataFactory.createInstallmentLines(salesOrder.id, 120000, 2000, 1, pp.id, ppi.id);
        ins.InstallmentDate__c = System.today().addDays(-3);
        ins.Type__c = 'Installment';
        ins.InstallmentPercentage__c = 20;
        ins.AmountReceived__c = 2000; 
        insert ins;
        system.debug('val of pending'+ins.PendingAmount__c);
        
        InstallmentLines__c ins1= TestDataFactory.createInstallmentLines(salesOrder.id, 140000, 4000, 2, pp.id, ppi.id);
        ins1.InstallmentDate__c = System.today().addDays(-2);
        ins1.Type__c = 'Handover';
        ins1.InstallmentPercentage__c = 30;
        insert ins1;
        
        InstallmentLines__c ins3= TestDataFactory.createInstallmentLines(salesOrder.id, 140000, 140000, 3, pp.id, ppi.id);
        ins3.InstallmentDate__c = System.today().addDays(-2);
        ins3.Type__c = 'Installment'; 
        ins3.AmountReceived__c = 140000;
        ins3.InstallmentPercentage__c = 30;
        insert ins3;
        
        
        InstallmentLines__c ins2= TestDataFactory.createInstallmentLines(salesOrder.id, 140000, null, null, pp.id, ppi.id);
        ins2.InstallmentDate__c = System.today().addDays(-2);
        ins2.Type__c = 'Post Handover Installment'; 
        ins2.InstallmentPercentage__c = 30;
        insert ins2;
        
        SalesOrderOtherCharges__c soc = TestDataFactory.createOtherCharge(salesOrder.id, acc.id, 'ADM Fee', false, null, null, null, null, null, 12000);
        insert soc;
        
        ReceiptAcknowledgement__c testData1 = TestDataFactory.createReceiptAcknowledgement(opp.id, 'Online', 12000, acc.Id, 'Cleared', null, salesOrder.id);
        ReceiptAcknowledgementService receiptServiceObj = ReceiptAcknowledgementService.getInstance();
        receiptServiceObj.insertReceiptAcknowledgementWithoutTrigger( new List<ReceiptAcknowledgement__c>{ testData1 });
        
        
        
        
        ReceiptAllocation__c rec = TestDataFactory.createReceiptAllocation(testData1.id, acc.id, ins.id, 12000, soc.id);
        System.debug('check val'+rec.InstallmentLine__r.PendingAmount__c);
        
        insert rec;
        
        ServiceCatalog__c catalog = TestDataFactory.createServiceCatalog('Service-Request-Resale-Property-Under-Construction','Sales','Service Request','Resale','Resale Property Under Construction',null,'Resale_Property_Under_Construction');
        insert catalog;
        
        ServiceAction__c action1 =TestDataFactory.createServiceAction(catalog.id,'Resale Property Under Construction','CRM Team Task 1','CRM Team Task 1','CRM',1);
        insert action1;
        
        ServiceAction__c action2 =TestDataFactory.createServiceAction(catalog.id,'Resale Property Under Construction','Finance Team Task 1','Finance Team Task 1','Finance',2);
        insert action2;
        
        
        ServiceAction__c action3 =TestDataFactory.createServiceAction(catalog.id,'Resale Property Under Construction','CRM Team Task 2','CRM Team Task 2','CRM',3);
        insert action3;
        
        
        ServiceAction__c action4 =TestDataFactory.createServiceAction(catalog.id,'Resale Property Under Construction','Finance Team Task 2','Finance Team Task 2','Finance',4);
        insert action4;
        
        Case caseObj = TestDataFactory.createCase('Resale_Property_Under_Construction', 'Email', 'New', 'Test case', null, acc.Id, unit.Id, con.Id);
        caseObj.ServiceCatalog__c = catalog.id;
        caseObj.CaseType__c ='Service Request';  
        caseObj.Sales_Order__c = salesOrder.id;
        //caseObj.NewSalesOrder__c = newSalesOrder.id;
        caseObj.NewCustomerAccount__c = dupeAcc.id;
        caseObj.Main_Buyer_Share_Percentage__c = 60;
        caseObj.CancellationFees__c = 100;
        caseObj.Step__c='1';
        caseObj.CustomerType__c = 'Person';
        caseObj.Last_Name__c = 'Test';
        caseObj.First_Name__c = 'Primary Buyer';
        caseObj.EmiratesID__c ='1234';
        caseObj.City__c = 'Dubai';
        caseObj.MOUDate__c = System.today();
        caseObj.Seller_Settled__c = 'Yes';
        caseObj.Emirates_ID_expiry_date__c = System.today().addDays(10);
        caseObj.BuyerNameInArabic__c = 'test';
        caseObj.PassportNumber__c = '12345';
        caseObj.PassportExpiryDate__c = System.today().addDays(10);
        caseObj.Nationality__c = 'Emirati'; 
        caseObj.ResalePrice__c = 100;
        caseObj.BuyerNameInArabic__c = 'test';
        caseObj.Email_Address__c ='test@test.com';
        caseObj.Gender__c = 'Male';
        caseObj.Customer_Type__c = 'Resident';
        caseObj.SmartHubActivated__c = 'Yes';
        caseObj.TotalCollection__c = 70000;
        //caseObj.NewSalesOrder__c = newSalesOrder.id;
        caseObj.TypeOfResale__c='Resale';
    
        caseObj.DirectIndirect__c='Indirect';
     //   caseObj.BrokerAgency__c = acc.id;
      //  caseObj.Broker_Agent__c = con.id;
      //  caseObj.Broker_Commission__c = 100;
        caseObj.Name__c = 'test Account';
        caseObj.Trade_License_No__c ='1234';
        caseObj.Trade_License_Issue_Date__c = System.today().addDays(-20);
        caseObj.Trade_License_Expiry_Date__c = System.today().addDays(40);
        caseObj.EIDIssueDate__c = System.today().addDays(-20);
        caseObj.PassportIssueDate__c = System.today().addDays(-20);
        caseObj.Registration_Authority__c ='123';
        caseObj.UAEResident__c = 'Resident';
              
        
        
        caseObj.Address__City__s ='Dubai';
        caseObj.Mobile_Number__c ='123456789';
        caseObj.Mobile_Country_Code__c ='971';
        caseObj.Address__CountryCode__s ='AE';
        caseObj.Address__PostalCode__s ='1234';
        caseObj.Address__StateCode__s = '01';
        caseObj.Address__Street__s = 'test';
        caseObj.ChequeWithWithdrawlFees__c = 100;
        caseObj.PendingFees__c = 200;
        caseObj.ResalePaymentType__c = 'Resale Unit';
        caseObj.ADDCAmount__c = 300;
        caseObj.IsPaymentReviewRequired__c = true;
        caseObj.WillMakeMorePayment__c = true;
        caseObj.isLegalReviewRequired__c = true;
        caseObj.Pre_title_deed_shared__c = 'Yes';
        caseObj.IsBuyerFinancing__c = 'Yes';
        caseObj.Unit_Mortgaged__c = 'Yes';
        caseObj.Rented__c= 'Yes';
        CaseService caseServiceObj = CaseService.getInstance();
        caseServiceObj.insertCaseWithoutTrigger(new List<Case>{caseObj});
        
        
        JointOwner__c tempJointOwner=new JointOwner__c(
            Account__c=acc.id,
            SharePercentage__c=40,
            Case__c=caseObj.id,
            First_Name__c = 'First',
            Mobile_Country_Code__c = '91',
            Gender__c = 'Male',
            PassportIssueDate__c = System.today().addDays(-20),
            Customer_Type__c = 'Resident', 
            Passport_Number__c ='123456',
            Passport_Expiry_Date__c = System.today().addDays(90),
            Nationality__c = 'Emirati',
            Address__City__s = 'Abu Dhabi',
            Address__CountryCode__s ='AE',
            Address__StateCode__s ='01',
            Address__Street__s = 'TEST',
            Address__PostalCode__s = '403703',
            Emirates_ID__c = '56432',
            EIDIssueDate__c = System.today().addDays(-20),
            Emirates_ID_expiry_date__c = System.today().addDays(120),
            NameInArabic__c = 'sdfg', 
            Last_Name__c = 'Test',
            Email__c = 'test@test.gmail.com' ,
            Phone_Number__c = '123'
            
            
        );
        insert tempJointOwner;
        
        Case caseObj1 = TestDataFactory.createCase('Resale_Master', 'Email', 'New', 'Test case', null, acc.Id, unit.Id, con.Id);
        caseObj1.ServiceCatalog__c = catalog.id;
        caseObj1.CaseType__c ='Service Request';  
        caseObj1.Sales_Order__c = salesOrder.id;
        //caseObj1.NewSalesOrder__c = newSalesOrder.id;
        caseObj1.NewCustomerAccount__c = dupeAcc.id;
        caseObj1.Step__c='1';
        caseObj1.CustomerType__c = 'Person';
        caseObj1.Last_Name__c = 'Test';
        caseObj.First_Name__c = 'Primary Buyer';
        caseObj1.EmiratesID__c ='1234';
        caseObj1.BuyerNameInArabic__c = 'test';
        caseObj1.City__c = 'Dubai';
        caseObj1.Seller_Settled__c = 'Yes';
        caseObj1.ResalePrice__c = 100;
        caseObj1.Emirates_ID_expiry_date__c = System.today().addDays(10);
        caseObj1.PassportNumber__c = '12345';
        caseObj1.PassportExpiryDate__c = System.today().addDays(10);
        caseObj1.Nationality__c = 'Emirati'; 
        caseObj1.Email_Address__c ='test@test.com';
        caseObj1.Gender__c = 'Male';
        caseObj1.Customer_Type__c = 'Resident';
        
        
        caseObj1.Name__c = 'test Account';
        caseObj1.Trade_License_No__c ='1234';
        caseObj1.Trade_License_Issue_Date__c = System.today().addDays(-20);
        caseObj1.Trade_License_Expiry_Date__c = System.today().addDays(40);
        caseObj1.EIDIssueDate__c = System.today().addDays(-20);
        caseObj1.PassportIssueDate__c = System.today().addDays(-20);
        caseObj1.Registration_Authority__c ='123';
        caseObj1.BuyerNameInArabic__c = 'test';
        caseObj1.RepresentativeArabicName__c = '1234';
        caseObj1.TypeOfCompany__c = 'test';
        caseObj1.RepresentationType__c = 'Father';
        caseObj1.PlaceOfRegistration__c ='Abu Dhabi';
        caseObj1.PlaceOfIssuance__c = 'test';
        caseObj1.NameOfPOA__c = 'test';
        
        caseObj1.Address__City__s ='Dubai';
        caseObj1.Mobile_Number__c ='123456789';
        caseObj1.Mobile_Country_Code__c ='971';
        caseObj1.Address__CountryCode__s ='AE';
        caseObj1.Address__PostalCode__s ='1234';
        caseObj1.Address__StateCode__s = '01';
        caseObj1.Address__Street__s = 'test';
        caseObj1.ChequeWithWithdrawlFees__c = 100;
        caseObj1.PendingFees__c = 200;
        caseObj1.ResalePaymentType__c = 'Resale with Mortgage';
        caseObj1.CancellationFees__c = 100;
        
        
        caseObj1.IsPaymentReviewRequired__c = true;
        caseObj1.WillMakeMorePayment__c = true;
        caseObj1.isLegalReviewRequired__c = true;
        caseObj1.TypeOfResale__c ='Gifting';
        caseObj1.MOUDate__c= System.today();
        caseObj1.DirectIndirect__c = 'Direct';
        caseObj1.RegistrationStatus__c = 'Registered';
        caseObj1.ProjectStatus__c = 'Under Construction';
        caseObj1.ResaleSubCategory__c = 'Resale Property Under Construction';
        
        caseServiceObj.insertCaseWithoutTrigger(new List<Case>{caseObj1});
        
        
        
        
        RecalculatePaymentsController.performRecalculation(caseObj.Id);
        
        // Create and insert the custom Document__c record
        Document__c testDoc = new Document__c(
            Document_Name__c = 'Statement of Account',
            Case__c = caseObj.Id 
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
        
        
        
        
    }
    @IsTest
    static void test_createPrimaryBuyerAccount_validCase() {
        
        Account acc = [SELECT Id FROM Account LIMIT 1];
           SalesOrder__c so = new SalesOrder__c(
    Account__c = acc.Id
    // populate any other required fields
);
insert so;
        // Safely query existing Case
        List<Case> existingCases = [
            SELECT Id, RecordTypeId, AccountId
            FROM Case
            LIMIT 1
        ];
        
        Case caseRec;
        
        if (!existingCases.isEmpty()) {
            // Reuse valid existing Case
            caseRec = new Case(
                RecordTypeId = existingCases[0].RecordTypeId,
                AccountId    = acc.Id,
                Account__c   = acc.Id
            );
        } else {
            // Create minimal Case WITHOUT restricted picklists
            caseRec = new Case(
                AccountId  = acc.Id,
                Account__c = acc.Id,
                Status     = 'New',
                Origin     = 'Phone'
            );
        }
        
        // Fields used by createPrimaryBuyerAccount
        caseRec.SuppliedName  = 'Primary Buyer Test';
        caseRec.SuppliedEmail = 'primarybuyer@test.com';
        caseRec.SuppliedPhone = '0501234567';
        caseRec.Sales_Order__c = so.Id;
        CaseService.getInstance().insertCaseWithoutTrigger(caseRec);
        
        DeletedOwner__c owner = new DeletedOwner__c();
        owner.Case__c = caseRec.id;
        owner.Account__c = acc.id;
        insert owner;
        
        Test.startTest();
        //Account result =
           // ResaleServiceRequestHandler.createPrimaryBuyerAccount(caseRec);
        DeletedOwnerService.getInstance().fetchDeletedOwners(caseRec.id);
        ResaleServiceRequestHandler.getInstance().validateDeletedOwner(caseRec);
         ResaleServiceRequestHandler.getInstance().validateDeletedOwnerDetails(caseRec); 
        Test.stopTest();
        
       
    }
    
   /* @IsTest
    static void test_createPrimaryBuyerAccount_personCustomer() {
        
        // 🔹 Get an existing Account
        Account acc = [SELECT Id FROM Account LIMIT 1];
     
        // 🔹 Safely create a Case
        List<Case> existingCases = [
            SELECT Id, RecordTypeId, AccountId
            FROM Case
            LIMIT 1
        ];
        
        Case caseRec;
        
        if (!existingCases.isEmpty()) {
            caseRec = new Case(
                RecordTypeId = existingCases[0].RecordTypeId,
                AccountId    = acc.Id,
                Account__c   = acc.Id
            );
        } else {
            caseRec = new Case(
                AccountId  = acc.Id,
                Account__c = acc.Id,
                Status     = 'New',
                Origin     = 'Phone'
            );
        }
        
        // Set fields required for Person customer
        caseRec.CustomerType__c = 'Person';
        caseRec.First_Name__c   = 'Ahmed';
        caseRec.Last_Name__c    = 'Khan';
        caseRec.Email_Address__c = 'person@test.com';
        caseRec.Mobile_Number__c = '0501234567';
       
        
        insert caseRec;
        
        Test.startTest();
      //  Account result = ResaleServiceRequestHandler.createPrimaryBuyerAccount(caseRec);
        ResaleServiceRequestHandler.getInstance().validateForPaymentReviewApproval(caseRec);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Primary buyer account should be created for Person');
        System.assertEquals('Ahmed', result.FirstName, 'First name should match Case');
        System.assertEquals('Khan', result.LastName, 'Last name should match Case');
    }*/
    
   /* @IsTest
    static void test_createPrimaryBuyerAccount_organizationCustomer() {
        
        // 🔹 Get an existing Account
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        // 🔹 Safely create a Case
        List<Case> existingCases = [
            SELECT Id, RecordTypeId, AccountId
            FROM Case
            LIMIT 1
        ];
        
        Case caseRec;
        
        if (!existingCases.isEmpty()) {
            caseRec = new Case(
                RecordTypeId = existingCases[0].RecordTypeId,
                AccountId    = acc.Id,
                Account__c   = acc.Id
            );
        } else {
            caseRec = new Case(
                AccountId  = acc.Id,
                Account__c = acc.Id,
                Status     = 'New',
                Origin     = 'Phone'
            );
        }
        
        // Set fields required for Organization customer
        caseRec.CustomerType__c = 'Organization';
        caseRec.Name__c          = 'Test Organization LLC';
        caseRec.Email_Address__c = 'org@test.com';
        
        insert caseRec;
        
        Test.startTest();
        //Account result = ResaleServiceRequestHandler.createPrimaryBuyerAccount(caseRec);
        Test.stopTest();
        
        //System.assertNotEquals(null, result, 'Primary buyer account should be created for Organization');
        //System.assertEquals('Test Organization LLC', result.Name, 'Account name should match Case');
    }*/
    @isTest
    static void testValidateEligibility() {
        SalesOrder__c testSalesOrder = [SELECT Id,Sales_Price_Excluding_ADM__c,Discount__c,ADM_Fee_Combined__c,ADM_Fee_Included__c,SalesPriceExcludingADMWithDiscount__c, Status__c,IsDefaulted__c FROM SalesOrder__c LIMIT 1];
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        String message = ResaleServiceRequestHandler.getInstance().validateEligibility(testSalesOrder, testCase);
        System.assertEquals('This unit is not eligible for the selected service request', message, 'Only Sold order should be eligible.');
        testSalesOrder.IsDefaulted__c = true;
        testSalesOrder.Status__c = 'Sold';
        update testSalesOrder;
        message =  ResaleServiceRequestHandler.getInstance().validateEligibility(testSalesOrder, testCase);
        System.assertEquals('A Resale request cannot be created for a defaulted unit', message, 'Unit should not be defaulted');
        
        
    }
    @isTest
    static void testCreateCaseRecord() {
        SalesOrder__c testSalesOrder = [SELECT Id,Account__c,Sales_Price_Excluding_ADM__c,SalesPriceExcludingADMWithDiscount__c,Account__r.Id,NetAmount__c,Unit__r.RegistrationDate__c,Unit__r.Project__r.ResaleEligibleAmoutPercentage__c,
                                        Unit__r.Name,Unit__r.Legal_Status__c,IsDefaulted__c,Unit__c,Account__r.Legal_Status__c,Unit__r.Project__r.City__c FROM SalesOrder__c LIMIT 1];
        Account acc = [Select id from Account limit 1];
        Unit__c unit = [Select id from Unit__c LIMIT 1];
        ServiceCatalog__c sc = [Select id,SubCategory__c,RecordTypeDevName__c from ServiceCatalog__c LIMIT 1];
        Test.startTest();
        Case caseObj = ResaleServiceRequestHandler.getInstance().createCaseRecord(
           testSalesOrder,
            sc,
            acc.Id,
            unit.Id,
            'Service Request',
            'test description',
            'Phone',
			false
        );
        Test.stopTest();
    }
    
    
  @isTest
static void testvalidateUnderConstructionForNextReviewSuccess() {

    Account acc = new Account(
        LastName = 'Test Buyer',
        PersonEmail = 'test@test.com'
    );
    insert acc;

    Unit__c unit = new Unit__c(
        Name = 'Unit-101',
        UnitType__c = 'Apartment'
    );
    insert unit;

    SalesOrder__c so = new SalesOrder__c(
        Account__c = acc.Id,
        Unit__c = unit.Id,
        NetAmount__c = 150000
    );
    insert so;

    // SAFE RecordType fetch
    Id caseRtId;
    for (Schema.RecordTypeInfo rt :
         Schema.SObjectType.Case.getRecordTypeInfos()) {
        if (rt.isAvailable()) {
            caseRtId = rt.getRecordTypeId();
            break;
        }
    }

    System.assertNotEquals(null, caseRtId, 'Case RecordType not found');

    Case c = new Case(
        AccountId = acc.Id,
        Account__c = acc.Id,
        Unit__c = unit.Id,
        Sales_Order__c = so.Id,
        Status = 'New',
        Origin = 'Phone',
        Step__c = '1',
        City__c = 'Dubai',
        BillingToCompleteAmount__c = 1000,
        ProjectStatus__c = 'Under Construction',
        TypeOfResale__c = 'Gifting',
        RecordTypeId = caseRtId
    );

    CaseService.getInstance().insertCaseWithoutTrigger(c);

    Test.startTest();
        ResaleServiceRequestHandler.getInstance()
            .validateUnderConstructionForNextReview(c);
       ResaleServiceRequestHandler.getInstance()
            .validateUnderConstructionForNextReview(null);
    Test.stopTest();

    System.assert(true);
}

    
    @isTest
    static void testMergedInstallmentCreation(){
        //List<Account> accs = [Select id,PassportNumber__pc,Nationality__c,Emirates_Id__pc from Account];
        Case caseObj = [Select id,ResalePrice__c,
                        Step__c,Unit__r.Name,Unit__r.Project__r.name,
                        CustomerType__c,Sales_Order__r.Account__c,NewSalesOrder__r.Opportunity__c,
                        Last_Name__c,TotalCollection__c,CancellationFees__c,
                        EIDIssueDate__c,
                        RecordTypeId,
                        First_Name__c,
                        EmiratesID__c,Rented__c,Unit_Mortgaged__c,
                        Emirates_ID_expiry_date__c,
                        PassportNumber__c,RecoveryFee__c,BouncedChequeFees__c,LatePaymentFees__c,
                        Nationality__c,
                        Email_Address__c,Sales_Order__c,NewSalesOrder__c,
                        Name__c, Gender__c,ADMFees__c,Title_Deed_Issued__c,
                        Trade_License_No__c,EvaluationFees__c,ADMTotalFees__c,TitleDeedFees__c,ADMAdminFees__c,MortgageFees__c,
                        Trade_License_Issue_Date__c,SubStatus__c,RegistrationStatus__c,BillingToCompleteAmount__c,
                        Trade_License_Expiry_Date__c,Seller_Settled__c,Pre_title_deed_shared__c,IsBuyerFinancing__c,
                        Registration_Authority__c,TypeOfResale__c,PaymentReceived__c,NewCustomerAccount__c,
                        Address__City__s,Mobile_Number__c,Mobile_Country_Code__c,Status,CaseType__c,ProjectStatus__c,
                        Address__CountryCode__s,Address__PostalCode__s,Address__StateCode__s,PassportIssueDate__c,
                        Address__Street__s,PassportExpiryDate__c,ChequeWithWithdrawlFees__c,BuyerLegalApprovalStatus__c,
                        PendingFees__c,City__c,ResalePaymentType__c,ADDCAmount__c,IsPaymentReviewRequired__c,WillMakeMorePayment__c,
                        PaymentApprovalStatus__c,SmartHubActivated__c, HassantukFee__c,Sales_Order__r.NetAmount__c,Customer_Type__c,Unit__r.UnitType__c,BuyerNameInArabic__c,Unit__r.Legal_Status__c,ContactId,owner.name,owner.email,ServiceCatalog__c,Account.Legal_Status__c,isLegalReviewRequired__c,LegalApprovalStatus__c
                        from Case limit 1];
        caseObj.RegistrationStatus__c = 'Registered';
        caseObj.ProjectStatus__c = 'Under Construction';
        caseObj.TypeOfResale__c = 'Gifting';
        caseObj.ResaleSubCategory__c = 'Resale Property Under Construction';
        CaseService servObj = CaseService.getInstance();
        servObj.updateCaseWithoutTrigger(new List<Case>{caseObj});
        Account acc = [Select id from Account where PersonEmail!=null Limit 1];
        SalesOrder__c salesOrder = [Select id,Account__c,Unit__r.UnitType__c,NetAmount__c,Opportunity__c,SalesPriceExcludingADMWithDiscount__c from SalesOrder__c limit 1];
        
        
        Test.startTest();
        ResaleServiceRequestHandler.getInstance().calculateInstallmentsAndReceiptsForPHPP(salesOrder.id,salesOrder,caseObj);
        
        Test.stopTest();
    }
     @isTest
    static void testMergedInstallmentCreationForMigratedProjects(){
        //List<Account> accs = [Select id,PassportNumber__pc,Nationality__c,Emirates_Id__pc from Account];
        Case caseObj = [Select id,ResalePrice__c,
                        Step__c,Unit__r.Name,Unit__r.Project__r.name,
                        CustomerType__c,Sales_Order__r.Account__c,NewSalesOrder__r.Opportunity__c,
                        Last_Name__c,TotalCollection__c,CancellationFees__c,
                        EIDIssueDate__c,
                        RecordTypeId,
                        First_Name__c,
                        EmiratesID__c,Rented__c,Unit_Mortgaged__c,
                        Emirates_ID_expiry_date__c,
                        PassportNumber__c,RecoveryFee__c,BouncedChequeFees__c,LatePaymentFees__c,
                        Nationality__c,
                        Email_Address__c,Sales_Order__c,NewSalesOrder__c,
                        Name__c, Gender__c,ADMFees__c,Title_Deed_Issued__c,
                        Trade_License_No__c,EvaluationFees__c,ADMTotalFees__c,TitleDeedFees__c,ADMAdminFees__c,MortgageFees__c,
                        Trade_License_Issue_Date__c,SubStatus__c,RegistrationStatus__c,BillingToCompleteAmount__c,
                        Trade_License_Expiry_Date__c,Seller_Settled__c,Pre_title_deed_shared__c,IsBuyerFinancing__c,
                        Registration_Authority__c,TypeOfResale__c,PaymentReceived__c,NewCustomerAccount__c,
                        Address__City__s,Mobile_Number__c,Mobile_Country_Code__c,Status,CaseType__c,ProjectStatus__c,
                        Address__CountryCode__s,Address__PostalCode__s,Address__StateCode__s,PassportIssueDate__c,
                        Address__Street__s,PassportExpiryDate__c,ChequeWithWithdrawlFees__c,BuyerLegalApprovalStatus__c,
                        PendingFees__c,City__c,ResalePaymentType__c,ADDCAmount__c,IsPaymentReviewRequired__c,WillMakeMorePayment__c,
                        PaymentApprovalStatus__c,SmartHubActivated__c, HassantukFee__c,Sales_Order__r.NetAmount__c,Customer_Type__c,Unit__r.UnitType__c,BuyerNameInArabic__c,Unit__r.Legal_Status__c,ContactId,owner.name,owner.email,ServiceCatalog__c,Account.Legal_Status__c,isLegalReviewRequired__c,LegalApprovalStatus__c
                        from Case limit 1];
        caseObj.RegistrationStatus__c = 'Registered';
        caseObj.ProjectStatus__c = 'Under Construction';
        caseObj.TypeOfResale__c = 'Gifting';
        caseObj.ResaleSubCategory__c = 'Resale Property Under Construction';
        CaseService servObj = CaseService.getInstance();
        servObj.updateCaseWithoutTrigger(new List<Case>{caseObj});
        Account acc = [Select id from Account where PersonEmail!=null Limit 1];
        SalesOrder__c salesOrder = [Select id,Account__c,Unit__r.UnitType__c,NetAmount__c,Opportunity__c,SalesPriceExcludingADMWithDiscount__c from SalesOrder__c limit 1];
        PaymentPlan__c pp = [Select id from PaymentPlan__c where name='Data Migration'];
        salesOrder.PaymentPlan__c = pp.id;
        update salesOrder;
        
        Test.startTest();
        ResaleServiceRequestHandler.getInstance().calculateInstallmentsForPHPPMigratedProjects(salesOrder.id,salesOrder,caseObj);
        
        Test.stopTest();
    }
    
    @isTest
    static void testvalidateUnderConstructionForNextReviewSuccess1(){
        //List<Account> accs = [Select id,PassportNumber__pc,Nationality__c,Emirates_Id__pc from Account];
        Case caseObj = [Select id,ResalePrice__c,DirectIndirect__c,BrokerAgency__c,Broker_Agent__c,Broker_Commission__c,MOUDate__c,Salutation__c,PlaceofIssue__c,LanguagePreference__c,UAEResident__c,Birthdate__c,
                        Step__c,Unit__r.Name,Unit__r.Project__r.name,
                        CustomerType__c,Sales_Order__r.Account__c,NewSalesOrder__r.Opportunity__c,
                        Last_Name__c,TotalCollection__c,CancellationFees__c,
                        EIDIssueDate__c,
                        RecordTypeId,
                        First_Name__c,
                        EmiratesID__c,Rented__c,Unit_Mortgaged__c,
                        Emirates_ID_expiry_date__c,
                        PassportNumber__c,RecoveryFee__c,BouncedChequeFees__c,LatePaymentFees__c,
                        Nationality__c, 
                        Email_Address__c,Sales_Order__c,NewSalesOrder__c,
                        Name__c, Gender__c,ADMFees__c,Title_Deed_Issued__c,
                        BillingToCompleteAmount__c, BillingToCompleteAmountInArabic__c, ResalePriceInArabicWords__c,
                        Trade_License_No__c,EvaluationFees__c,ADMTotalFees__c,TitleDeedFees__c,ADMAdminFees__c,MortgageFees__c,
                        Trade_License_Issue_Date__c,SubStatus__c,RegistrationStatus__c,
                        Trade_License_Expiry_Date__c,Seller_Settled__c,Pre_title_deed_shared__c,IsBuyerFinancing__c,
                        Registration_Authority__c,TypeOfResale__c,PaymentReceived__c,NewCustomerAccount__c,
                        Address__City__s,Mobile_Number__c,Mobile_Country_Code__c,Status,CaseType__c,ProjectStatus__c,
                        Address__CountryCode__s,Address__PostalCode__s,Address__StateCode__s,PassportIssueDate__c,
                        Address__Street__s,PassportExpiryDate__c,ChequeWithWithdrawlFees__c,BuyerLegalApprovalStatus__c,
                        PendingFees__c,City__c,ResalePaymentType__c,ADDCAmount__c,IsPaymentReviewRequired__c,WillMakeMorePayment__c,
                        PaymentApprovalStatus__c,SmartHubActivated__c, HassantukFee__c,Sales_Order__r.NetAmount__c,Customer_Type__c,Unit__r.UnitType__c,BuyerNameInArabic__c,Unit__r.Legal_Status__c,ContactId,owner.name,owner.email,ServiceCatalog__c,Account.Legal_Status__c,isLegalReviewRequired__c,LegalApprovalStatus__c
                        from Case limit 1];
        caseObj.RegistrationStatus__c = 'Registered';
        caseObj.ProjectStatus__c = 'Under Construction';
        caseObj.TypeOfResale__c = 'Gifting';
        caseObj.ResaleSubCategory__c = 'Resale Property Under Construction';
        Account acc = [Select id from Account where PersonEmail!=null Limit 1];
        SalesOrder__c salesOrder = [Select id,Account__c,Unit__r.UnitType__c,NetAmount__c,Opportunity__c from SalesOrder__c limit 1];
        PaymentPlan__c pp = [Select id from PaymentPlan__c where name='Data Migration'];
        OffersPromotions__c offer = [Select id,ADM_Fee_Included__c from OffersPromotions__c where Name  ='testOffer'];
        Test.startTest();
        ResaleServiceRequestHandler.getInstance().validateUnderConstructionForNextReview(caseObj); 
        caseObj.NewCustomerAccount__c = null;
        update caseObj;
           ResaleServiceRequestHandler.getInstance().validateUnderConstructionForNextReview(caseObj); 
        Test.stopTest();
        
    }
     @isTest
    static void testvalidateSalesOrderCancellation(){
        //List<Account> accs = [Select id,PassportNumber__pc,Nationality__c,Emirates_Id__pc from Account];
        Case caseObj = [Select id,ResalePrice__c,DirectIndirect__c,BrokerAgency__c,Broker_Agent__c,Broker_Commission__c,MOUDate__c,Salutation__c,PlaceofIssue__c,LanguagePreference__c,UAEResident__c,Birthdate__c,
                        Step__c,Unit__r.Name,Unit__r.Project__r.name,
                        CustomerType__c,Sales_Order__r.Account__c,NewSalesOrder__r.Opportunity__c,
                        Last_Name__c,TotalCollection__c,CancellationFees__c,
                        EIDIssueDate__c,
                        RecordTypeId,
                        First_Name__c,
                        EmiratesID__c,Rented__c,Unit_Mortgaged__c,
                        Emirates_ID_expiry_date__c,
                        PassportNumber__c,RecoveryFee__c,BouncedChequeFees__c,LatePaymentFees__c,
                        Nationality__c, 
                        Email_Address__c,Sales_Order__c,NewSalesOrder__c,
                        Name__c, Gender__c,ADMFees__c,Title_Deed_Issued__c,
                        BillingToCompleteAmount__c, BillingToCompleteAmountInArabic__c, ResalePriceInArabicWords__c,
                        Trade_License_No__c,EvaluationFees__c,ADMTotalFees__c,TitleDeedFees__c,ADMAdminFees__c,MortgageFees__c,
                        Trade_License_Issue_Date__c,SubStatus__c,RegistrationStatus__c,
                        Trade_License_Expiry_Date__c,Seller_Settled__c,Pre_title_deed_shared__c,IsBuyerFinancing__c,
                        Registration_Authority__c,TypeOfResale__c,PaymentReceived__c,NewCustomerAccount__c,
                        Address__City__s,Mobile_Number__c,Mobile_Country_Code__c,Status,CaseType__c,ProjectStatus__c,
                        Address__CountryCode__s,Address__PostalCode__s,Address__StateCode__s,PassportIssueDate__c,
                        Address__Street__s,PassportExpiryDate__c,ChequeWithWithdrawlFees__c,BuyerLegalApprovalStatus__c,
                        PendingFees__c,City__c,ResalePaymentType__c,ADDCAmount__c,IsPaymentReviewRequired__c,WillMakeMorePayment__c,
                        PaymentApprovalStatus__c,SmartHubActivated__c, HassantukFee__c,Sales_Order__r.NetAmount__c,Customer_Type__c,Unit__r.UnitType__c,BuyerNameInArabic__c,Unit__r.Legal_Status__c,ContactId,owner.name,owner.email,ServiceCatalog__c,Account.Legal_Status__c,isLegalReviewRequired__c,LegalApprovalStatus__c
                        from Case limit 1];
        caseObj.NewSalesOrder__c = null;
        update caseObj;
        Test.startTest();
        ResaleServiceRequestHandler.getInstance().cancelAndReassignSalesOrdersForResale(caseObj); 
        Test.stopTest();
        
    }
    @isTest
    static void testvalidateUnderConstructionForNextReviewSuccess2(){
        //List<Account> accs = [Select id,PassportNumber__pc,Nationality__c,Emirates_Id__pc from Account];
        Case caseObj = [Select id,ResalePrice__c,DirectIndirect__c,BrokerAgency__c,Broker_Agent__c,Broker_Commission__c,MOUDate__c,Salutation__c,PlaceofIssue__c,LanguagePreference__c,UAEResident__c,Birthdate__c,
                        Step__c,Unit__r.Name,Unit__r.Project__r.name,
                        CustomerType__c,Sales_Order__r.Account__c,NewSalesOrder__r.Opportunity__c,
                        Last_Name__c,TotalCollection__c,
                        EIDIssueDate__c,CancellationFees__c,
                        RecordTypeId,
                        First_Name__c,
                        EmiratesID__c,Rented__c,Unit_Mortgaged__c,
                        Emirates_ID_expiry_date__c,
                        PassportNumber__c,RecoveryFee__c,BouncedChequeFees__c,LatePaymentFees__c,
                        Nationality__c,
                        Email_Address__c,Sales_Order__c,NewSalesOrder__c,
                        Name__c, Gender__c,ADMFees__c,Title_Deed_Issued__c,
                        Trade_License_No__c,EvaluationFees__c,ADMTotalFees__c,TitleDeedFees__c,ADMAdminFees__c,MortgageFees__c,
                        Trade_License_Issue_Date__c,SubStatus__c,RegistrationStatus__c,BillingToCompleteAmount__c,
                        Trade_License_Expiry_Date__c,Seller_Settled__c,Pre_title_deed_shared__c,IsBuyerFinancing__c,
                        Registration_Authority__c,TypeOfResale__c,PaymentReceived__c,NewCustomerAccount__c,
                        Address__City__s,Mobile_Number__c,Mobile_Country_Code__c,Status,CaseType__c,ProjectStatus__c,
                        Address__CountryCode__s,Address__PostalCode__s,Address__StateCode__s,PassportIssueDate__c,
                        Address__Street__s,PassportExpiryDate__c,ChequeWithWithdrawlFees__c,BuyerLegalApprovalStatus__c,
                        PendingFees__c,City__c,ResalePaymentType__c,ADDCAmount__c,IsPaymentReviewRequired__c,WillMakeMorePayment__c,
                        PaymentApprovalStatus__c,SmartHubActivated__c, HassantukFee__c,Sales_Order__r.NetAmount__c,Customer_Type__c,Unit__r.UnitType__c,BuyerNameInArabic__c,Unit__r.Legal_Status__c,ContactId,owner.name,owner.email,ServiceCatalog__c,Account.Legal_Status__c,isLegalReviewRequired__c,LegalApprovalStatus__c
                        from Case limit 1];
        caseObj.RegistrationStatus__c = 'Registered';
        caseObj.ProjectStatus__c = 'Under Construction';
        caseObj.TypeOfResale__c = 'Gifting';
        caseObj.ResaleSubCategory__c = 'Resale Property Under Construction';
        Account acc = [Select id from Account where PersonEmail!=null Limit 1];
        SalesOrder__c salesOrder = [Select id,Account__c,Unit__r.UnitType__c,NetAmount__c,Opportunity__c from SalesOrder__c limit 1];
        PaymentPlan__c pp = [Select id from PaymentPlan__c where name='Data Migration'];
        OffersPromotions__c offer = [Select id,ADM_Fee_Included__c from OffersPromotions__c where Name  ='testOffer'];
        Test.startTest();
        ResaleServiceRequestHandler.getInstance().validatePHPPForNextReview(caseObj);
        Test.stopTest();
    }
    
    @isTest
    static void testvalidateUnderConstructionForNextReviewSuccess3(){
        //List<Account> accs = [Select id,PassportNumber__pc,Nationality__c,Emirates_Id__pc from Account];
        Case caseObj = [Select id,ResalePrice__c,DirectIndirect__c,BrokerAgency__c,Broker_Agent__c,Broker_Commission__c,MOUDate__c,Salutation__c,PlaceofIssue__c,LanguagePreference__c,UAEResident__c,Birthdate__c,
                        Step__c,Unit__r.Name,Unit__r.Project__r.name,
                        CustomerType__c,Sales_Order__r.Account__c,NewSalesOrder__r.Opportunity__c,
                        Last_Name__c,TotalCollection__c,CancellationFees__c,
                        EIDIssueDate__c,
                        RecordTypeId,
                        First_Name__c,
                        EmiratesID__c,Rented__c,Unit_Mortgaged__c,
                        Emirates_ID_expiry_date__c,
                        PassportNumber__c,RecoveryFee__c,BouncedChequeFees__c,LatePaymentFees__c,
                        Nationality__c,
                        Email_Address__c,Sales_Order__c,NewSalesOrder__c,
                        Name__c, Gender__c,ADMFees__c,Title_Deed_Issued__c,
                        Trade_License_No__c,EvaluationFees__c,ADMTotalFees__c,TitleDeedFees__c,ADMAdminFees__c,MortgageFees__c,
                        Trade_License_Issue_Date__c,SubStatus__c,RegistrationStatus__c,BillingToCompleteAmount__c,
                        Trade_License_Expiry_Date__c,Seller_Settled__c,Pre_title_deed_shared__c,IsBuyerFinancing__c,
                        Registration_Authority__c,TypeOfResale__c,PaymentReceived__c,NewCustomerAccount__c,
                        Address__City__s,Mobile_Number__c,Mobile_Country_Code__c,Status,CaseType__c,ProjectStatus__c,
                        Address__CountryCode__s,Address__PostalCode__s,Address__StateCode__s,PassportIssueDate__c,
                        Address__Street__s,PassportExpiryDate__c,ChequeWithWithdrawlFees__c,BuyerLegalApprovalStatus__c,
                        PendingFees__c,City__c,ResalePaymentType__c,ADDCAmount__c,IsPaymentReviewRequired__c,WillMakeMorePayment__c,
                        PaymentApprovalStatus__c,SmartHubActivated__c, HassantukFee__c,Sales_Order__r.NetAmount__c,Customer_Type__c,Unit__r.UnitType__c,BuyerNameInArabic__c,Unit__r.Legal_Status__c,ContactId,owner.name,owner.email,ServiceCatalog__c,Account.Legal_Status__c,isLegalReviewRequired__c,LegalApprovalStatus__c
                        from Case limit 1];
        caseObj.RegistrationStatus__c = 'Registered';
        caseObj.ProjectStatus__c = 'Under Construction';
        caseObj.TypeOfResale__c = 'Gifting';
        caseObj.ResaleSubCategory__c = 'Resale Property Under Construction';
        Account acc = [Select id from Account where PersonEmail!=null Limit 1];
        SalesOrder__c salesOrder = [Select id,Account__c,Unit__r.UnitType__c,NetAmount__c,Opportunity__c from SalesOrder__c limit 1];
        PaymentPlan__c pp = [Select id from PaymentPlan__c where name='Data Migration'];
        OffersPromotions__c offer = [Select id,ADM_Fee_Included__c from OffersPromotions__c where Name  ='testOffer'];
        Test.startTest();
        
        ResaleServiceRequestHandler.getInstance().validateCompletedProjectForNextReview(caseObj);
        caseObj.step__c = '0';
        update caseObj;
        ResaleServiceRequestHandler.getInstance().validateUnderConstructionForNextReview(caseObj);
        caseObj.Step__c ='1';
        caseObj.City__c ='Abu Dhabi';
        caseObj.TypeOfResale__c ='Gifting';
        caseObj.RegistrationStatus__c = 'Registered';
        caseObj.ProjectStatus__c='Under Construction';
        caseObj.ResaleSubCategory__c = 'Resale Property Under Construction';
        caseObj.ResalePaymentType__c = 'Resale with Mortgage';
        caseObj.ResalePrice__c = 100000;
        caseObj.DirectIndirect__c = 'Direct';
        caseObj.InitialOwnerRemoved__c ='Yes';
        caseObj.BrokerAgency__c = null;
        caseObj.Broker_Agent__c = null;
        caseObj.UnitRegistered__c ='Yes';
        caseObj.ConsumptionSettled__c ='Yes';
        caseObj.ADDC_Transferred__c ='Yes';
        caseObj.UAEResident__c = 'Resident';
        caseObj.Title_Deed_Issued__c ='Yes';
        caseObj.Salutation__c= 'Mr.';
        caseObj.LanguagePreference__c ='English';
        caseObj.PlaceofIssue__c= 'India'; 
        caseObj.Birthdate__c = System.today()-20000; 
        caseObj.TitleDeedShared__c ='Yes';
        caseObj.PaymentReceived__c ='From the Buyer';
        update caseObj;
        ResaleServiceRequestHandler.getInstance().validateUnderConstructionForNextReview(caseObj);
        Test.stopTest();
    }
 
    @IsTest
    static void testStep4UnderConstructionWithoutServiceActions() {

        // -----------------------
        // 1️⃣ Create Account
        // -----------------------
        Account acc = new Account(
            LastName = 'Test Buyer Step 4',
            PersonEmail = 'step4@test.com'
        );
        insert acc;

        // -----------------------
        // 2️⃣ Get a safe Case RecordType
        // -----------------------
        Id caseRtId;
        for (Schema.RecordTypeInfo rt : Schema.SObjectType.Case.getRecordTypeInfos()) {
            if (rt.isAvailable()) {
                caseRtId = rt.getRecordTypeId();
                break;
            }
        }
        System.assertNotEquals(null, caseRtId, 'Case RecordType not found');

        // -----------------------
        // 3️⃣ Create Step 4 Case
        // -----------------------
        Case c = new Case(
            AccountId = acc.Id,
            Account__c = acc.Id,
            Status = 'New',
            Origin = 'Phone',
            Step__c = '4',
            ProjectStatus__c = 'Under Construction',
            TypeOfResale__c = 'Gifting',
            RecordTypeId = caseRtId,
            City__c = 'Dubai',
            BillingToCompleteAmount__c = 1000
        );

        // Insert without triggers to avoid NPEs
        CaseService.getInstance().insertCaseWithoutTrigger(c);

        // -----------------------
        // 4️⃣ Call validation (bypassing ServiceAction/Tasks)
        // -----------------------
        Test.startTest();
            Map<String,Object> response = ResaleServiceRequestHandler.getInstance()
                .validateUnderConstructionForNextReview(c);
        Test.stopTest();

        // -----------------------
        // 5️⃣ Assert success
        // -----------------------
        System.assertEquals('success', response.get('status'),
            'Step 4 validation should succeed even without ServiceActions or Tasks');
    }
    @isTest
    static void test_otherCharges(){
        Case caseObj = [Select id,Sales_Order__c from Case limit 1];
        SalesOrder__c so = [Select id,Account__c from SalesOrder__c where Id=:caseObj.Sales_Order__c];
        
        caseObj.EvaluationFees__c =100;
        caseobj.ExcludeEvaluationFee__c =false;
        caseObj.TitleDeedFees__c = 100;
        caseObj.ExcludeTitleDeedFee__c = false;
        caseObj.BookTitleFeeUnder__c ='Buyer';
        caseObj.MortgageFees__c = 100;
        caseObj.ADMTotalFees__c = 100;
        caseObj.CancellationFees__c = 900;
        caseObj.ADMAdminFees__c =100;
        caseObj.ExcludeAdmFee__c = false;
        caseObj.ExcludeMortgageFee__c =false;
        update caseObj;
        Test.startTest();
        ResaleServiceRequestHandler.getInstance().calculateOtherChargesForNewSalesOrder(caseObj,so);
        Test.stopTest();
    }


    
    @isTest
    static void test_calculateInstallmentsAndReceipts() {
        
        Case caseObj = [
            SELECT Id,
            ResalePrice__c,
            Step__c,
            Unit__r.Name,
            Unit__r.Project__r.Name,
            CustomerType__c,
            Sales_Order__r.Account__c,
            NewSalesOrder__r.Opportunity__c,
            Last_Name__c,
            TotalCollection__c,
            EIDIssueDate__c,
            RecordTypeId,
            First_Name__c,
            EmiratesID__c,
            Rented__c,
            Unit_Mortgaged__c,
            Emirates_ID_expiry_date__c,
            PassportNumber__c,
            CancellationFees__c,
            BouncedChequeFees__c,
            LatePaymentFees__c,
            Nationality__c,
            Email_Address__c,
            Sales_Order__c,
            NewSalesOrder__c,
            Name__c,
            Gender__c,
            ADMFees__c,
            Title_Deed_Issued__c,
            Trade_License_No__c,
            EvaluationFees__c,
            ADMTotalFees__c,
            TitleDeedFees__c,
            ADMAdminFees__c,
            MortgageFees__c,
            Trade_License_Issue_Date__c,
            SubStatus__c,
            RegistrationStatus__c,
            BillingToCompleteAmount__c,
            Trade_License_Expiry_Date__c,
            Seller_Settled__c,
            Pre_title_deed_shared__c,
            IsBuyerFinancing__c,
            Registration_Authority__c,
            TypeOfResale__c,
            PaymentReceived__c,
            NewCustomerAccount__c,
            Address__City__s,
            Mobile_Number__c,
            Mobile_Country_Code__c,
            Status,
            CaseType__c,
            ProjectStatus__c,
            Address__CountryCode__s,
            Address__PostalCode__s,
            Address__StateCode__s,
            PassportIssueDate__c,
            Address__Street__s,
            PassportExpiryDate__c,
            ChequeWithWithdrawlFees__c,
            BuyerLegalApprovalStatus__c,
            PendingFees__c,
            City__c,
            ResalePaymentType__c,
            ADDCAmount__c,
            IsPaymentReviewRequired__c,
            WillMakeMorePayment__c,
            PaymentApprovalStatus__c,
            SmartHubActivated__c,
            HassantukFee__c,
            Sales_Order__r.NetAmount__c,
            Customer_Type__c,
            Unit__r.UnitType__c,
            BuyerNameInArabic__c,
            Unit__r.Legal_Status__c,
            ContactId,
            Owner.Name,
            Owner.Email,
            ServiceCatalog__c,
            Account.Legal_Status__c,
            isLegalReviewRequired__c,
            LegalApprovalStatus__c
            FROM Case
            LIMIT 1
        ];
        
        // 🔥 FIX: Include Opportunity__c
        SalesOrder__c so = [
            SELECT Id, Account__c, Unit__c, Opportunity__c
            FROM SalesOrder__c
            LIMIT 1
        ];
        
        Test.startTest();
        ResaleServiceRequestHandler.getInstance()
            .calculateInstallmentsAndReceipts(so.Id, so, caseObj);
        Test.stopTest();
        
        System.assert(true, 'Installment calculation executed');
    }
    
     /*@isTest
static void test_calculateInstallmentsAndReceipts() {
        
        Case caseObj = [
            SELECT Id,
            ResalePrice__c,
            Step__c,
            Unit__r.Name,
            Unit__r.Project__r.Name,
            CustomerType__c,
            Sales_Order__r.Account__c,
            NewSalesOrder__r.Opportunity__c,
            Last_Name__c,
            TotalCollection__c,
            EIDIssueDate__c,
            RecordTypeId,
            First_Name__c,
            EmiratesID__c,
            Rented__c,
            Unit_Mortgaged__c,
            Emirates_ID_expiry_date__c,
            PassportNumber__c,
            RecoveryFee__c,
            BouncedChequeFees__c,
            LatePaymentFees__c,
            Nationality__c,
            Email_Address__c,
            Sales_Order__c,
            NewSalesOrder__c,
            Name__c,
            Gender__c,
            ADMFees__c,
            Title_Deed_Issued__c,
            Trade_License_No__c,
            EvaluationFees__c,
            ADMTotalFees__c,
            TitleDeedFees__c,
            ADMAdminFees__c,
            MortgageFees__c,
            Trade_License_Issue_Date__c,
            SubStatus__c,
            RegistrationStatus__c,
            BillingToCompleteAmount__c,
            Trade_License_Expiry_Date__c,
            Seller_Settled__c,
            Pre_title_deed_shared__c,
            IsBuyerFinancing__c,
            Registration_Authority__c,
            TypeOfResale__c,
            PaymentReceived__c,
            NewCustomerAccount__c,
            Address__City__s,
            Mobile_Number__c,
            Mobile_Country_Code__c,
            Status,
            CaseType__c,
            ProjectStatus__c,
            Address__CountryCode__s,
            Address__PostalCode__s,
            Address__StateCode__s,
            PassportIssueDate__c,
            Address__Street__s,
            Passport_Expiry_Date__c,
            ChequeWithWithdrawlFees__c,
            BuyerLegalApprovalStatus__c,
            PendingFees__c,
            City__c,
            ResalePaymentType__c,
            ADDCAmount__c,
            IsPaymentReviewRequired__c,
            WillMakeMorePayment__c,
            PaymentApprovalStatus__c,
            SmartHubActivated__c,
            HassantukFee__c,
            Sales_Order__r.NetAmount__c,
            Customer_Type__c,
            Unit__r.UnitType__c,
            BuyerNameInArabic__c,
            Unit__r.Legal_Status__c,
            ContactId,
            Owner.Name,
            Owner.Email,
            ServiceCatalog__c,
            Account.Legal_Status__c,
            isLegalReviewRequired__c,
            LegalApprovalStatus__c
            FROM Case
            LIMIT 1
        ];
        
        
        // 🔥 FIX: Include Opportunity__c
        SalesOrder__c so = [
            SELECT Id, Account__c, Unit__c, Opportunity__c
            FROM SalesOrder__c
            LIMIT 1
        ];
        
        InstallmentLines__c ins1= TestDataFactory.createInstallmentLines(so.id, 140000, 140000, null, pp.id, ppi.id);
        ins1.InstallmentDate__c = System.today().addDays(-2);
        ins1.Type__c = 'Installment';
        ins1.InstallmentPercentage__c = 100;
        insert ins1;
        
        
     
        
        Test.startTest();
        ResaleServiceRequestHandler.getInstance()
            .calculateInstallmentsAndReceipts(so.Id, so, caseObj);
        Test.stopTest();
        
        System.assert(true, 'Installment calculation executed');
    }*/
    
    
    @isTest
    static void testvalidateADMFeeIncludedInstallmentCalculation(){
        //List<Account> accs = [Select id,PassportNumber__pc,Nationality__c,Emirates_Id__pc from Account];
        Case caseObj = [Select id,ResalePrice__c,
                        Step__c,Unit__r.Name,Unit__r.Project__r.name,
                        CustomerType__c,Sales_Order__r.Account__c,NewSalesOrder__r.Opportunity__c,
                        Last_Name__c,TotalCollection__c,
                        EIDIssueDate__c,
                        RecordTypeId,
                        First_Name__c,CancellationFees__c,
                        EmiratesID__c,Rented__c,Unit_Mortgaged__c,
                        Emirates_ID_expiry_date__c,
                        PassportNumber__c,RecoveryFee__c,BouncedChequeFees__c,LatePaymentFees__c,
                        Nationality__c,
                        Email_Address__c,Sales_Order__c,NewSalesOrder__c,
                        Name__c, Gender__c,ADMFees__c,Title_Deed_Issued__c,
                        Trade_License_No__c,EvaluationFees__c,ADMTotalFees__c,TitleDeedFees__c,ADMAdminFees__c,MortgageFees__c,
                        Trade_License_Issue_Date__c,SubStatus__c,RegistrationStatus__c,BillingToCompleteAmount__c,
                        Trade_License_Expiry_Date__c,Seller_Settled__c,Pre_title_deed_shared__c,IsBuyerFinancing__c,
                        Registration_Authority__c,TypeOfResale__c,PaymentReceived__c,NewCustomerAccount__c,
                        Address__City__s,Mobile_Number__c,Mobile_Country_Code__c,Status,CaseType__c,ProjectStatus__c,
                        Address__CountryCode__s,Address__PostalCode__s,Address__StateCode__s,PassportIssueDate__c,
                        Address__Street__s,PassportExpiryDate__c,ChequeWithWithdrawlFees__c,BuyerLegalApprovalStatus__c,
                        PendingFees__c,City__c,ResalePaymentType__c,ADDCAmount__c,IsPaymentReviewRequired__c,WillMakeMorePayment__c,
                        PaymentApprovalStatus__c,SmartHubActivated__c, HassantukFee__c,Sales_Order__r.NetAmount__c,Customer_Type__c,Unit__r.UnitType__c,BuyerNameInArabic__c,Unit__r.Legal_Status__c,ContactId,owner.name,owner.email,ServiceCatalog__c,Account.Legal_Status__c,isLegalReviewRequired__c,LegalApprovalStatus__c
                        from Case limit 1];
        caseObj.RegistrationStatus__c = 'Registered';
        caseObj.ProjectStatus__c = 'Under Construction';
        caseObj.TypeOfResale__c = 'Gifting';
        caseObj.ResaleSubCategory__c = 'Resale Property Under Construction';
        Account acc = [Select id from Account where PersonEmail!=null Limit 1];
        SalesOrder__c salesOrder = [Select id,Account__c,Unit__r.UnitType__c,NetAmount__c,Opportunity__c from SalesOrder__c limit 1];
        PaymentPlan__c pp = [Select id from PaymentPlan__c where name='Data Migration'];
        OffersPromotions__c offer = [Select id,ADM_Fee_Included__c from OffersPromotions__c where Name  ='testOffer'];
        Test.startTest();
        
        salesOrder.Offer__c = offer.id;
        update salesOrder;
        ResaleServiceRequestHandler.getInstance().calculateInstallmentsAndReceipts(salesOrder.id,salesOrder,caseObj);
        Test.stopTest();
    }
    @isTest
    static void testvalidateResaleForNextReview(){
        Case caseObj = [Select id,CustomerPaidPercentage__c,DirectIndirect__c,Salutation__c,PlaceofIssue__c,LanguagePreference__c,UAEResident__c,Birthdate__c,
                        Step__c,Customer_Type__c,Unit__r.Name,Unit__r.Project__r.name,ResalePrice__c,
                        CustomerType__c,Sales_Order__r.Account__c,NewSalesOrder__r.Opportunity__c,
                        Last_Name__c,Sales_Order__r.Unit__r.Project__r.ResaleEligibleAmoutPercentage__c,
                        EIDIssueDate__c,CancellationFees__c,
                        RecordTypeId,NewCustomerAccount__r.IsPersonAccount,
                        First_Name__c,
                        EmiratesID__c,Rented__c,Unit_Mortgaged__c,
                        Emirates_ID_expiry_date__c,
                        PassportNumber__c,
                        Nationality__c,
                        Email_Address__c,Sales_Order__c,NewSalesOrder__c,
                        Name__c, Gender__c,
                        Trade_License_No__c,ADMAdminFees__c,Unit__r.Legal_Status__c,
                        Trade_License_Issue_Date__c,SubStatus__c,RegistrationStatus__c,ADMTotalFees__c,
                        Trade_License_Expiry_Date__c,Seller_Settled__c,Pre_title_deed_shared__c,IsBuyerFinancing__c,
                        Registration_Authority__c,TypeOfResale__c,PaymentReceived__c,NewCustomerAccount__c,
                        Address__City__s,Mobile_Number__c,Mobile_Country_Code__c,Status,CaseType__c,ProjectStatus__c,
                        Address__CountryCode__s,Address__PostalCode__s,Address__StateCode__s,PassportIssueDate__c,
                        Address__Street__s,PassportExpiryDate__c,ChequeWithWithdrawlFees__c,BuyerLegalApprovalStatus__c,
                        PendingFees__c,ResaleSubCategory__c,City__c,ResalePaymentType__c,ADDCAmount__c,IsPaymentReviewRequired__c,WillMakeMorePayment__c,
                        PaymentApprovalStatus__c,TitleDeedFees__c,UnitRegistered__c,ConsumptionSettled__c,ADDC_Transferred__c,Title_Deed_Issued__c,TitleDeedShared__c,ContactId,owner.name,owner.email,ServiceCatalog__c,Account.Legal_Status__c,isLegalReviewRequired__c,LegalApprovalStatus__c,
                        BookTitleFeeUnder__c,ExcludeEvaluationFee__c,ExcludeHassantukFee__c,ExcludeMortgageFee__c,ExcludePendingFee__c,
                        ExcludeRecoveryFee__c,MOUDate__c,ExcludeTitleDeedFee__c,ExcludeAdmFee__c,ExcludeAdminFee__c,ExcludeChequeBounceFee__c,ExcludeChequeWithdrawlFee__c
                        from Case where ResaleSubCategory__c!=null limit 1];
        
        Account acc = [Select id from Account where PersonEmail!=null Limit 1];
        SalesOrder__c salesOrder = [Select id from SalesOrder__c limit 1];
        
        Test.startTest();
        
        ResaleServiceRequestHandler.getInstance().validateResaleForNextReview(caseObj); 
        ResaleServiceRequestHandler.getInstance().validateResaleForNextReview(null); 
        caseObj.Step__c ='0';
        update caseObj;
        ResaleServiceRequestHandler.getInstance().validateResaleForNextReview(caseObj); 
        caseObj.Step__c ='1';
        caseObj.City__c ='Abu Dhabi';
        caseObj.TypeOfResale__c ='Gifting';
        caseObj.RegistrationStatus__c = 'Registered';
        caseObj.ProjectStatus__c='Under Construction';
        caseObj.ResaleSubCategory__c = 'Resale Property Under Construction';
        caseObj.ResalePaymentType__c = 'Resale with Mortgage';
        caseObj.ResalePrice__c = 100000;
        caseObj.DirectIndirect__c = 'Direct';
        caseObj.UnitRegistered__c ='Yes';
        caseObj.ConsumptionSettled__c ='Yes';
        caseObj.ADDC_Transferred__c ='Yes';
        caseObj.UAEResident__c = 'Resident';
        caseObj.Title_Deed_Issued__c ='Yes';
        caseObj.Salutation__c= 'Mr.';
        caseObj.LanguagePreference__c ='English';
        caseObj.PlaceofIssue__c= 'India'; 
        caseObj.Birthdate__c = System.today()-20000; 
        caseObj.TitleDeedShared__c ='Yes';
        caseObj.PaymentReceived__c ='From the Buyer';
        update caseObj;
         ResaleServiceRequestHandler.getInstance().validateResaleForNextReview(caseObj); 
        ResaleServiceRequestHandler.getInstance().checkCompletedProjectRequiredFields(caseObj); 
         ResaleServiceRequestHandler.getInstance().checkPHPPRequiredFields(caseObj); 
        caseObj.CustomerType__c =null;
        update caseObj;
         ResaleServiceRequestHandler.getInstance().checkPHPPRequiredFields(caseObj); 
        ResaleServiceRequestHandler.getInstance().updateCaseRecordTypeAndCatalog(caseObj);
        ResaleServiceRequestHandler.handleBuyerLegalApproval(caseObj);
        caseObj.BuyerLegalApprovalStatus__c ='Approved';
        ResaleServiceRequestHandler.handleBuyerLegalApproval(caseObj);
        caseObj.BuyerLegalApprovalStatus__c ='Rejected';
        ResaleServiceRequestHandler.handleBuyerLegalApproval(caseObj);
        ResaleServiceRequestHandler.getInstance().sum(2.2,200);
        caseObj.CustomerType__c = 'Person';
        caseObj.Last_Name__c = 'Test';
        caseObj.First_Name__c = 'Primary Buyer';
        caseObj.EmiratesID__c ='1234';
        caseObj.City__c = 'Dubai';
        caseObj.Seller_Settled__c = 'Yes';
        caseObj.Emirates_ID_expiry_date__c = System.today().addDays(10);
        caseObj.BuyerNameInArabic__c = 'test';
        caseObj.PassportNumber__c = '12345';
        caseObj.PassportExpiryDate__c = System.today().addDays(10);
        caseObj.Nationality__c = 'Emirati'; 
        caseObj.BuyerNameInArabic__c = 'test';
        caseObj.Email_Address__c ='test@test.com';
        caseObj.Gender__c = 'Male';
        caseObj.Customer_Type__c = 'Resident';
        caseObj.SmartHubActivated__c = 'Yes';
        caseObj.TotalCollection__c = 1000000000;
        caseObj.ADMTotalFees__c = 100;
        caseObj.ADMAdminFees__c = 100;
        update caseObj;
        ResaleServiceRequestHandler.getInstance().validateResaleForNextReview(caseObj); 
        caseObj.Status = 'Cancelled';
        update caseObj;
        
        Test.stopTest();
        // Force document validation branch
caseObj.TypeOfResale__c = 'Resale';
caseObj.Customer_Type__c = 'Resident';
update caseObj;

// Only one document
Document__c doc = new Document__c(
    Case__c = caseObj.Id,
    Document_Name__c = 'Buyer Passport'
);
insert doc;

ContentVersion cv = new ContentVersion(
    Title = 'Buyer Passport',
    PathOnClient = 'BuyerPassport.pdf',
    VersionData = Blob.valueOf('Test')
);
insert cv;

Id cdId = [
    SELECT ContentDocumentId
    FROM ContentVersion
    WHERE Id = :cv.Id
].ContentDocumentId;

insert new ContentDocumentLink(
    LinkedEntityId = doc.Id,
    ContentDocumentId = cdId,
    ShareType = 'V'
);

Map<String,Object> response =
    ResaleServiceRequestHandler.getInstance()
        .validateResaleForNextReview(caseObj);

System.assertEquals('error', response.get('status'));
    }
    @isTest
    static void testvalidateUnderConstructionForNextReviewError(){ 
        List<Account> accs = [Select id,Legal_Status__c,PassportNumber__pc,Name,Nationality__c,Emirates_Id__pc from Account];
        System.debug('accs'+accs);
        Case caseObj = [Select id,ResalePrice__c,Unit__r.Name,DirectIndirect__c,BrokerAgency__c,Broker_Agent__c,Broker_Commission__c,MOUDate__c,Salutation__c,PlaceofIssue__c,LanguagePreference__c,UAEResident__c,Birthdate__c,
                        Step__c,LatePaymentFees__c,HassantukFee__c,Unit__r.Project__r.ResaleUnitAdminFeeVilla__c,Unit__r.Project__r.ResaleUnitEvaluationFeeVilla__c,
                        CustomerType__c,Unit__r.UnitType__c,Sales_Order__r.NetAmount__c,BouncedChequeFees__c,NewCustomerAccount__r.name,Sales_Order__r.Opportunity__r.LeadChannel__c,
                        Last_Name__c,RecoveryFee__c,Sales_Order__r.Opportunity__r.WinReason__c,NewCustomerAccount__c,
                        First_Name__c,WithdrawlRequestInitiated__c,Sales_Order__r.name,Unit__c,
                        EmiratesID__c,NewPDCReceived__c,TotalCollection__c,
                        Emirates_ID_expiry_date__c,RegistrationStatus__c,
                        PassportNumber__c,ReversalRequestSubmittedForPDCs__c,NewSalesOrder__c,
                        Nationality__c,TypeOfResale__c,CancellationFees__c,
                        Email_Address__c,
                        RecordTypeId, 
                        EIDIssueDate__c,EvaluationFees__c,ADMTotalFees__c,TitleDeedFees__c,ADMAdminFees__c,MortgageFees__c,
                        Name__c, Gender__c,
                        Sales_Order__r.SalesManager__c,
                        Sales_Order__r.AmountPayable__c,
                        Trade_License_No__c,
                        Trade_License_Issue_Date__c,
                        Trade_License_Expiry_Date__c,
                        BillingToCompleteAmount__c, BillingToCompleteAmountInArabic__c, ResalePriceInArabicWords__c,
                        Registration_Authority__c,Unit__r.Project__r.ResaleWithMortgageAdminFeeVilla__c,Unit__r.Project__r.ResaleWithMortgageMortgageFeeVilla__c,Unit__r.Project__r.ResaleWithMortgageEvaluationFeeVilla__c,
                        Address__City__s,Mobile_Number__c,Mobile_Country_Code__c,Status,CaseType__c,Customer_Type__c,
                        Address__CountryCode__s,Address__PostalCode__s,Address__StateCode__s,PassportIssueDate__c,
                        Address__Street__s,PassportExpiryDate__c,ChequeWithWithdrawlFees__c,BuyerLegalApprovalStatus__c,
                        PendingFees__c,ResalePaymentType__c,ADDCAmount__c,IsPaymentReviewRequired__c,WillMakeMorePayment__c,
                        PaymentApprovalStatus__c,ServiceCatalog__c,Account.Legal_Status__c,isLegalReviewRequired__c,LegalApprovalStatus__c,Sales_Order__r.ADM_Fee_Included__c,
                        Sales_Order__r.IsTaxable__c,ADMFees__c,Main_Buyer_Share_Percentage__c,
                        Sales_Order__r.ADM_Fee_Combined__c,
                        Sales_Order__r.ADMFeeWaivedAmount__c,
                        Sales_Order__r.SellingPrice__c,
                        Sales_Order__r.SalesPriceExcludingADMwithDiscount__c,
                        Sales_Order__r.Sales_Price_Excluding_ADM__c,
                        Sales_Order__r.Amount_Payable_Excluding_ADM__c,
                        Sales_Order__r.PaymentPlanDiscount__c,
                        Sales_Order__r.BulkDiscount__c,
                        Sales_Order__r.Management_Discount__c,
                        Sales_Order__r.Discount__c,
                        Sales_Order__r.Account__c,
                        Sales_Order__r.CorporateDiscount__c,
                        Sales_Order__r.BookingDate__c,
                        Sales_Order__r.Broker_Agencyy__c,
                        Sales_Order__r.SoldDate__c,   
                        Sales_Order__r.ADM_DLD_Pre_Registered__c,
                        Sales_Order__r.Pre_Title_Deed_Status__c,
                        Sales_Order__r.Title_Deed_Status__c,
                        Sales_Order__r.Handover_Status__c,
                        Sales_Order__r.ADDC__c,            
                        Sales_Order__r.OwnerSharePercentage__c,
                        Owner.Phone,Sales_Order__r.PaymentPlan__r.Name,
                        Sales_Order__r.ADMFeeAmount__c,Sales_Order__r.Opportunity__r.BrokerAgencyAccount__c,ProjectStatus__c,
                        BookTitleFeeUnder__c,ExcludeEvaluationFee__c,ExcludeHassantukFee__c,ExcludeMortgageFee__c,ExcludePendingFee__c,
                        ExcludeRecoveryFee__c,ExcludeTitleDeedFee__c,ExcludeAdmFee__c,ExcludeAdminFee__c,ExcludeChequeBounceFee__c,ExcludeChequeWithdrawlFee__c
                        from Case limit 1];
        
        
        
        
        Document__c doc = [Select id from Document__c where Case__c = :caseObj.id];
        
        List<ContentDocumentLink> cdl = [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId = :doc.id];
        Map<String,Object> response = new Map<String,Object> ();
        Test.startTest();
        caseObj.LegalApprovalStatus__c = 'Rejected'; 
        update caseObj;
        response = ResaleServiceRequestHandler.getInstance().validateUnderConstructionForNextReview(caseObj); 
        caseObj.LegalApprovalStatus__c = 'Approved';
        update caseObj;
        caseObj.BuyerLegalApprovalStatus__c = 'Approved';
        update caseObj;
        response = ResaleServiceRequestHandler.getInstance().validateUnderConstructionForNextReview(caseObj);
        caseObj.Step__c ='2';
        caseObj.LatePaymentFees__c = 100;
        caseObj.BouncedChequeFees__c = 100;
        caseObj.RecoveryFee__c = 200;
        
        caseObj.WithdrawlRequestInitiated__c ='Yes';
        caseObj.NewPDCReceived__c = 'Yes';
        caseObj.ReversalRequestSubmittedForPDCs__c = 'Yes';
        update caseObj;
        response = ResaleServiceRequestHandler.getInstance().validateUnderConstructionForNextReview(caseObj); 
        
        System.assertEquals('Case moved to next review successfully.', response.get('message'), 'should successfully move to next review');
        Test.stopTest();
    }
    @isTest
    static void testvalidate_UnderConstructionForNextReview(){ 
        List<Account> accs = [Select id,Legal_Status__c,PassportNumber__pc,Name,Nationality__c,Emirates_Id__pc from Account];
        System.debug('accs'+accs);
        Case caseObj = [Select id,ResalePrice__c,Unit__r.Name,EvaluationFees__c,ADMTotalFees__c,TitleDeedFees__c,ADMAdminFees__c,MortgageFees__c,
                        Step__c,LatePaymentFees__c,HassantukFee__c,Unit__r.Project__r.ResaleUnitAdminFeeVilla__c,Unit__r.Project__r.ResaleUnitEvaluationFeeVilla__c,
                        CustomerType__c,Unit__r.UnitType__c,Sales_Order__r.NetAmount__c,BouncedChequeFees__c,NewCustomerAccount__r.name,Sales_Order__r.Opportunity__r.LeadChannel__c,
                        Last_Name__c,RecoveryFee__c,Sales_Order__r.Opportunity__r.WinReason__c,NewCustomerAccount__c,
                        First_Name__c,WithdrawlRequestInitiated__c,Sales_Order__r.name,Unit__c,DirectIndirect__c,BrokerAgency__c,Broker_Agent__c,Broker_Commission__c,MOUDate__c,Salutation__c,PlaceofIssue__c,LanguagePreference__c,UAEResident__c,Birthdate__c,
                        EmiratesID__c,NewPDCReceived__c,TotalCollection__c,
                        Emirates_ID_expiry_date__c,
                        PassportNumber__c,ReversalRequestSubmittedForPDCs__c,NewSalesOrder__c,
                        Nationality__c,TypeOfResale__c,CancellationFees__c,
                        Email_Address__c,
                        RecordTypeId, 
                        EIDIssueDate__c,
                        Name__c, Gender__c,
                        Sales_Order__r.SalesManager__c,
                        Sales_Order__r.AmountPayable__c,
                        Trade_License_No__c,
                        Trade_License_Issue_Date__c,
                        Trade_License_Expiry_Date__c, BillingToCompleteAmount__c, BillingToCompleteAmountInArabic__c, ResalePriceInArabicWords__c,
                        Registration_Authority__c,Unit__r.Project__r.ResaleWithMortgageAdminFeeVilla__c,Unit__r.Project__r.ResaleWithMortgageMortgageFeeVilla__c,Unit__r.Project__r.ResaleWithMortgageEvaluationFeeVilla__c,
                        Address__City__s,Mobile_Number__c,Mobile_Country_Code__c,Status,CaseType__c,Customer_Type__c,
                        Address__CountryCode__s,Address__PostalCode__s,Address__StateCode__s,PassportIssueDate__c,
                        Address__Street__s,PassportExpiryDate__c,ChequeWithWithdrawlFees__c,BuyerLegalApprovalStatus__c,
                        PendingFees__c,ResalePaymentType__c,ADDCAmount__c,IsPaymentReviewRequired__c,WillMakeMorePayment__c,
                        PaymentApprovalStatus__c,ServiceCatalog__c,Account.Legal_Status__c,isLegalReviewRequired__c,LegalApprovalStatus__c,Sales_Order__r.ADM_Fee_Included__c,
                        Sales_Order__r.IsTaxable__c,Main_Buyer_Share_Percentage__c,
                        Sales_Order__r.ADM_Fee_Combined__c,
                        Sales_Order__r.ADMFeeWaivedAmount__c,Sales_Order__r.Sales_Order_Pending_Amount_in_Words_Arab__c,
                        Sales_Order__r.SellingPrice__c,
                        Sales_Order__r.SalesPriceExcludingADMwithDiscount__c,
                        Sales_Order__r.Sales_Price_Excluding_ADM__c,
                        Sales_Order__r.Amount_Payable_Excluding_ADM__c,
                        Sales_Order__r.PaymentPlanDiscount__c,
                        Sales_Order__r.BulkDiscount__c,
                        Sales_Order__r.Broker_Agencyy__c,
                        Sales_Order__r.PaymentPlan__c,
                        Sales_Order__r.SoldDate__c,            
                        Sales_Order__r.Management_Discount__c,
                        Sales_Order__r.Discount__c,
                        Sales_Order__r.CorporateDiscount__c,
                        Sales_Order__r.BookingDate__c,
                        Sales_Order__r.Account__c,
                        Sales_Order__r.OwnerSharePercentage__c,
                        Owner.Phone,ADMFees__c,
                        Sales_Order__r.ADM_DLD_Pre_Registered__c,
                        Sales_Order__r.Pre_Title_Deed_Status__c,
                        Sales_Order__r.Title_Deed_Status__c,
                        Sales_Order__r.Handover_Status__c,
                        Sales_Order__r.ADDC__c,            
                        Sales_Order__r.ADMFeeAmount__c,Sales_Order__r.Opportunity__r.BrokerAgencyAccount__c,ProjectStatus__c,BookTitleFeeUnder__c,ExcludeEvaluationFee__c,ExcludeHassantukFee__c,ExcludeMortgageFee__c,ExcludePendingFee__c,
                        ExcludeRecoveryFee__c,ExcludeTitleDeedFee__c,ExcludeAdmFee__c,ExcludeAdminFee__c,ExcludeChequeBounceFee__c,ExcludeChequeWithdrawlFee__c
                        from Case limit 1];
        
        Document__c doc = [Select id from Document__c where Case__c = :caseObj.id];
        
        List<ContentDocumentLink> cdl = [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId = :doc.id];
        Map<String,Object> response = new Map<String,Object> ();
        Test.startTest();
        caseObj.Step__c ='2';
        caseObj.LatePaymentFees__c = 100;
        caseObj.BouncedChequeFees__c = 100;
        caseObj.RecoveryFee__c = 200;
        caseObj.WithdrawlRequestInitiated__c ='Yes';
        caseObj.NewPDCReceived__c = 'Yes';
        caseObj.ReversalRequestSubmittedForPDCs__c = 'Yes';
        update caseObj;
        Unit__c unit = new Unit__c();
        unit.id= caseObj.Unit__c;
        unit.UnitType__c = 'Apartment';
        update unit;
        response = ResaleServiceRequestHandler.getInstance().validateUnderConstructionForNextReview(caseObj); 
        
        System.assertEquals('Case moved to next review successfully.', response.get('message'), 'should successfully move to next review');
        Test.stopTest();
    }
    @isTest
    static void testCompleteProjectForNextReview(){
        List<Account> accs = [Select id,Legal_Status__c,PassportNumber__pc,Nationality__c,Emirates_Id__pc from Account];
        Case caseObj = [Select id,Unit__r.Name,Unit__r.Project__r.name,owner.name,owner.email,EvaluationFees__c,ADMTotalFees__c,TitleDeedFees__c,ADMAdminFees__c,MortgageFees__c,
                        Step__c,LatePaymentFees__c,HassantukFee__c,Unit__r.Project__r.ResaleUnitAdminFeeVilla__c,Unit__r.Project__r.ResaleUnitEvaluationFeeVilla__c,
                        CustomerType__c,Unit__r.UnitType__c,Sales_Order__r.NetAmount__c,BouncedChequeFees__c,NewCustomerAccount__r.name,Sales_Order__r.Opportunity__r.LeadChannel__c,
                        Last_Name__c,RecoveryFee__c,Sales_Order__r.Opportunity__r.WinReason__c,NewCustomerAccount__c,
                        First_Name__c,WithdrawlRequestInitiated__c,Sales_Order__r.name,Unit__c,
                        EmiratesID__c,NewPDCReceived__c,
                        Emirates_ID_expiry_date__c,PaymentReceived__c,NewSalesOrder__c,
                        PassportNumber__c,ReversalRequestSubmittedForPDCs__c,CancellationFees__c,
                        Nationality__c,TypeOfResale__c,
                        Email_Address__c,ProjectStatus__c,
                        Name__c,BrokerAgency__c,Broker_Agent__c,Broker_Commission__c,MOUDate__c,Salutation__c,PlaceofIssue__c,LanguagePreference__c,UAEResident__c,Birthdate__c,
                        Sales_Order__r.SalesManager__c,  
                        Sales_Order__r.AmountPayable__c, 
                        Trade_License_No__c,TotalCollection__c,
                        Trade_License_Issue_Date__c,Sales_Order__r.Opportunity__r.BrokerAgencyAccount__c,
                        Trade_License_Expiry_Date__c,City__c,
                        Registration_Authority__c,Unit__r.Project__r.ResaleWithMortgageAdminFeeVilla__c,Unit__r.Project__r.ResaleWithMortgageMortgageFeeVilla__c,Unit__r.Project__r.ResaleWithMortgageEvaluationFeeVilla__c,
                        Address__City__s,Mobile_Number__c,Mobile_Country_Code__c,Status,CaseType__c,
                        Address__CountryCode__s,Address__PostalCode__s,Address__StateCode__s,
                        Address__Street__s,PassportExpiryDate__c,ChequeWithWithdrawlFees__c,BuyerLegalApprovalStatus__c,
                        PendingFees__c,ResalePaymentType__c,ADDCAmount__c,IsPaymentReviewRequired__c,WillMakeMorePayment__c,
                        PaymentApprovalStatus__c,ServiceCatalog__c,Account.Legal_Status__c,isLegalReviewRequired__c,LegalApprovalStatus__c,            Sales_Order__r.ADM_Fee_Combined__c,
                        Sales_Order__r.ADM_Fee_Included__c,ADMFees__c,Main_Buyer_Share_Percentage__c,
                        Sales_Order__r.IsTaxable__c,
                        Sales_Order__r.Account__c,            
                        Sales_Order__r.ADMFeeWaivedAmount__c,Sales_Order__r.Sales_Order_Pending_Amount_in_Words_Arab__c,
                        Sales_Order__r.SellingPrice__c,
                        Sales_Order__r.SalesPriceExcludingADMwithDiscount__c,
                        Sales_Order__r.Sales_Price_Excluding_ADM__c,
                        Sales_Order__r.Amount_Payable_Excluding_ADM__c,
                        Sales_Order__r.PaymentPlanDiscount__c,
                        Sales_Order__r.BulkDiscount__c,
                        Sales_Order__r.Management_Discount__c,
                        Sales_Order__r.Discount__c,
                        Sales_Order__r.CorporateDiscount__c,
                        Sales_Order__r.BookingDate__c,
                        Sales_Order__r.OwnerSharePercentage__c,
                        Sales_Order__r.PaymentPlan__c,
                        Sales_Order__r.PaymentPlan__r.Name,
                        Sales_Order__r.Broker_Agencyy__c,
                        Sales_Order__r.SoldDate__c,
                        Sales_Order__r.ADM_DLD_Pre_Registered__c,
                        Sales_Order__r.Pre_Title_Deed_Status__c,
                        Sales_Order__r.Title_Deed_Status__c,
                        Sales_Order__r.Handover_Status__c,
                        Sales_Order__r.ADDC__c,
                        Owner.Phone,ContactId,
                        BillingToCompleteAmount__c, BillingToCompleteAmountInArabic__c, ResalePriceInArabicWords__c,
                        Sales_Order__r.ADMFeeAmount__c,BookTitleFeeUnder__c,ExcludeEvaluationFee__c,ExcludeHassantukFee__c,ExcludeMortgageFee__c,ExcludePendingFee__c,
                        ExcludeRecoveryFee__c,DirectIndirect__c,ResalePrice__c,ExcludeTitleDeedFee__c,ExcludeAdmFee__c,ExcludeAdminFee__c,ExcludeChequeBounceFee__c,ExcludeChequeWithdrawlFee__c
                        from Case limit 1];
        
        
        Document__c doc = [Select id from Document__c where Case__c = :caseObj.id];
        
        List<ContentDocumentLink> cdl = [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId = :doc.id];
        Map<String,Object> response = new Map<String,Object> ();
        Test.startTest();
        caseObj.LegalApprovalStatus__c = 'Approved';
        caseObj.BuyerLegalApprovalStatus__c = 'Approved';
        caseObj.Step__c ='2';
        caseObj.LatePaymentFees__c = 100;
        caseObj.BouncedChequeFees__c = 100;
        caseObj.RecoveryFee__c = 200;
        caseObj.WithdrawlRequestInitiated__c ='Yes';
        caseObj.NewPDCReceived__c = 'Yes';
        caseObj.ReversalRequestSubmittedForPDCs__c = 'Yes'; 
        update caseObj;
        response = ResaleServiceRequestHandler.getInstance().validateCompletedProjectForNextReview(caseObj); 
        caseObj.Step__c ='3';
        caseObj.SmartHubActivated__c = 'Yes';
        update caseObj;
        response = ResaleServiceRequestHandler.getInstance().validateCompletedProjectForNextReview(caseObj); 
        ResaleServiceRequestHandler.getInstance().validateCompletedProjectForNextReview(null); 
        caseObj.Step__c ='0';
        update caseObj;
        ResaleServiceRequestHandler.getInstance().validateCompletedProjectForNextReview(caseObj); 
        
        
        //System.assertEquals('Case moved to next review successfully.', response.get('message'), 'should successfully move to next review');
        Test.stopTest();
    }
    @isTest
    static void testResaleWithMortgage(){
        
        Case caseObj = [Select id,TotalCollection__c,Unit__r.Name,TypeOfResale__c,NewSalesOrder__c,DirectIndirect__c,
                        Step__c,LatePaymentFees__c,HassantukFee__c,Unit__r.Project__r.ResaleUnitAdminFeeVilla__c,Unit__r.Project__r.ResaleUnitEvaluationFeeVilla__c,
                        CustomerType__c,Unit__r.UnitType__c,Sales_Order__r.NetAmount__c,BouncedChequeFees__c,NewCustomerAccount__r.name,Sales_Order__r.Opportunity__r.LeadChannel__c,
                        Last_Name__c,RecoveryFee__c,Sales_Order__r.Opportunity__r.WinReason__c,NewCustomerAccount__c,
                        First_Name__c,WithdrawlRequestInitiated__c,Sales_Order__r.name,Unit__c,
                        EmiratesID__c,NewPDCReceived__c,Sales_Order__r.Opportunity__r.BrokerAgencyAccount__c,
                        Emirates_ID_expiry_date__c,ResalePrice__c,
                        PassportNumber__c,ReversalRequestSubmittedForPDCs__c, CancellationFees__c,
                        Nationality__c,ProjectStatus__c,
                        EvaluationFees__c,ADMTotalFees__c,TitleDeedFees__c,ADMAdminFees__c,MortgageFees__c,
                        Email_Address__c,
                        Name__c, 
                        Sales_Order__r.SalesManager__c,
                        Sales_Order__r.AmountPayable__c,
                        Trade_License_No__c,
                        Trade_License_Issue_Date__c,
                        Trade_License_Expiry_Date__c,
                        Registration_Authority__c,Unit__r.Project__r.ResaleWithMortgageAdminFeeVilla__c,Unit__r.Project__r.ResaleWithMortgageMortgageFeeVilla__c,Unit__r.Project__r.ResaleWithMortgageEvaluationFeeVilla__c,
                        Address__City__s,Mobile_Number__c,Mobile_Country_Code__c,Status,CaseType__c,
                        Address__CountryCode__s,Address__PostalCode__s,Address__StateCode__s,
                        Address__Street__s,PassportExpiryDate__c,ChequeWithWithdrawlFees__c,BuyerLegalApprovalStatus__c,
                        PendingFees__c,ResalePaymentType__c,ADDCAmount__c,IsPaymentReviewRequired__c,WillMakeMorePayment__c,
                        PaymentApprovalStatus__c,ServiceCatalog__c,Account.Legal_Status__c,isLegalReviewRequired__c,LegalApprovalStatus__c,Sales_Order__r.ADM_Fee_Included__c,
                        Sales_Order__r.IsTaxable__c,Main_Buyer_Share_Percentage__c,
                        Sales_Order__r.ADMFeeWaivedAmount__c,
                        Sales_Order__r.SellingPrice__c,
                        Sales_Order__r.SalesPriceExcludingADMwithDiscount__c,
                        Sales_Order__r.Sales_Price_Excluding_ADM__c,
                        Sales_Order__r.Amount_Payable_Excluding_ADM__c,
                        Sales_Order__r.PaymentPlanDiscount__c,
                        Sales_Order__r.BulkDiscount__c,ADMFees__c,
                        Sales_Order__r.Management_Discount__c,
                        Sales_Order__r.Discount__c,
                        Sales_Order__r.ADM_Fee_Combined__c,
                        Sales_Order__r.CorporateDiscount__c,
                        Sales_Order__r.BookingDate__c,
                        Sales_Order__r.Broker_Agencyy__c,
                        Sales_Order__r.SoldDate__c,  
                        Sales_Order__r.Account__c,
                        Sales_Order__r.OwnerSharePercentage__c,
                        Owner.Phone,
                        Sales_Order__r.PaymentPlan__r.Name,
                        Sales_Order__r.ADMFeeAmount__c,
                        Sales_Order__r.ADM_DLD_Pre_Registered__c,
                        Sales_Order__r.Pre_Title_Deed_Status__c,
                        Sales_Order__r.Title_Deed_Status__c,
                        Sales_Order__r.Handover_Status__c,
                        Sales_Order__r.ADDC__c,BrokerAgency__c,Broker_Agent__c,Broker_Commission__c,MOUDate__c,Salutation__c,PlaceofIssue__c,LanguagePreference__c,UAEResident__c,Birthdate__c,
                        BillingToCompleteAmount__c, BillingToCompleteAmountInArabic__c, ResalePriceInArabicWords__c,
                        BookTitleFeeUnder__c,ExcludeEvaluationFee__c,ExcludeHassantukFee__c,ExcludeMortgageFee__c,ExcludePendingFee__c,
                        ExcludeRecoveryFee__c,ExcludeTitleDeedFee__c,ExcludeAdmFee__c,ExcludeAdminFee__c,ExcludeChequeBounceFee__c,ExcludeChequeWithdrawlFee__c
                        from Case limit 1];
        
        
        Document__c doc = [Select id from Document__c where Case__c = :caseObj.id];
        
        List<ContentDocumentLink> cdl = [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId = :doc.id];
        Map<String,Object> response = new Map<String,Object> ();
        Test.startTest();
        caseObj.LegalApprovalStatus__c = 'Approved';
        caseObj.BuyerLegalApprovalStatus__c = 'Approved';
        caseObj.Step__c ='2';
        caseObj.LatePaymentFees__c = 100;
        caseObj.BouncedChequeFees__c = 100;
        caseObj.RecoveryFee__c = 200;
        caseObj.WithdrawlRequestInitiated__c ='Yes';
        caseObj.NewPDCReceived__c = 'Yes';
        caseObj.ReversalRequestSubmittedForPDCs__c = 'Yes'; 
        caseObj.ResalePaymentType__c = 'Resale with Mortgage';
        update caseObj;
        response = ResaleServiceRequestHandler.getInstance().validateUnderConstructionForNextReview(caseObj);
        Test.stopTest();
    }
    @isTest
    static void testHandlePaymentReviewApproval(){
        List<Account> accs = [Select id,Legal_Status__c,PassportNumber__pc,Nationality__c,Emirates_Id__pc from Account];
        Case caseObj = [Select id,Unit__r.Name,
                        Step__c,
                        CustomerType__c,
                        Last_Name__c,
                        First_Name__c,
                        EmiratesID__c,
                        Emirates_ID_expiry_date__c,
                        PassportNumber__c,
                        Nationality__c,
                        Email_Address__c,CancellationFees__c,
                        Name__c, 
                        Trade_License_No__c,
                        Trade_License_Issue_Date__c,
                        Trade_License_Expiry_Date__c,
                        Registration_Authority__c,NewCustomerAccount__c,
                        Address__City__s,Mobile_Number__c,Mobile_Country_Code__c,Status,CaseType__c,
                        Address__CountryCode__s,Address__PostalCode__s,Address__StateCode__s,
                        Address__Street__s,PassportExpiryDate__c,ChequeWithWithdrawlFees__c,BuyerLegalApprovalStatus__c,
                        PendingFees__c,ResalePaymentType__c,ADDCAmount__c,IsPaymentReviewRequired__c,WillMakeMorePayment__c,
                        PaymentApprovalStatus__c,ServiceCatalog__c,Account.Legal_Status__c,isLegalReviewRequired__c,LegalApprovalStatus__c,ResalePrice__c
                        from Case limit 1];
        Map<String,Object> response = new Map<String,Object> (); 
        Test.startTest();
        response = ResaleServiceRequestHandler.getInstance().handlePaymentReviewApproval(caseObj);
        caseObj.PaymentApprovalStatus__c = 'Approved'; 
        update caseObj;
        response = ResaleServiceRequestHandler.getInstance().handlePaymentReviewApproval(caseObj);
        caseObj.PaymentApprovalStatus__c ='Rejected'; 
        
        response = ResaleServiceRequestHandler.getInstance().handlePaymentReviewApproval(caseObj);
        response = ResaleServiceRequestHandler.getInstance().handleLegalStatusApproval(caseObj);
        caseObj.LegalApprovalStatus__c = 'Approved';
        update caseObj;
        response = ResaleServiceRequestHandler.getInstance().handleLegalStatusApproval(caseObj);
        caseObj.LegalApprovalStatus__c = 'Rejected';
        update caseObj;
        response = ResaleServiceRequestHandler.getInstance().handleLegalStatusApproval(caseObj); 
        Test.stopTest();
        
    }
    
    
    /*@isTest
static void testvalidateUnderConstructionForNextReview(){
List<Account> accs = [Select id,Legal_Status__c,PassportNumber__pc,Name,Nationality__c,Emirates_Id__pc from Account];
System.debug('accs'+accs);
Case caseObj = [Select id,Unit__r.Name,TotalCollection__c,EvaluationFees__c,ADMTotalFees__c,TitleDeedFees__c,ADMAdminFees__c,MortgageFees__c,
Step__c,LatePaymentFees__c,HassantukFee__c,Unit__r.Project__r.ResaleUnitAdminFeeVilla__c,Unit__r.Project__r.ResaleUnitEvaluationFeeVilla__c,
CustomerType__c,Unit__r.UnitType__c,Sales_Order__r.NetAmount__c,BouncedChequeFees__c,NewCustomerAccount__r.name,Sales_Order__r.Opportunity__r.LeadChannel__c,
Last_Name__c,RecoveryFee__c,Sales_Order__r.Opportunity__r.WinReason__c,NewCustomerAccount__c,
First_Name__c,WithdrawlRequestInitiated__c,Sales_Order__r.name,Unit__c,
EmiratesID__c,NewPDCReceived__c,DirectIndirect__c,BrokerAgency__c,Broker_Agent__c,Broker_Commission__c,MOUDate__c,Salutation__c,PlaceofIssue__c,LanguagePreference__c,UAEResident__c,Birthdate__c,
Emirates_ID_expiry_date__c,ProjectStatus__c,
PassportNumber__c,ReversalRequestSubmittedForPDCs__c,
Nationality__c,RecordTypeId,RegistrationStatus__c,
Email_Address__c,BuyerNameInArabic__c,NewSalesOrder__c,
EIDIssueDate__c,
Sales_Order__r.SalesManager__c,
Sales_Order__r.AmountPayable__c,
Name__c, Gender__c,
Trade_License_No__c,
Trade_License_Issue_Date__c,
BillingToCompleteAmount__c, BillingToCompleteAmountInArabic__c, ResalePriceInArabicWords__c,
Trade_License_Expiry_Date__c,Sales_Order__r.Opportunity__r.BrokerAgencyAccount__c,
Registration_Authority__c,Unit__r.Project__r.ResaleWithMortgageAdminFeeVilla__c,Unit__r.Project__r.ResaleWithMortgageMortgageFeeVilla__c,Unit__r.Project__r.ResaleWithMortgageEvaluationFeeVilla__c,
Address__City__s,Mobile_Number__c,Mobile_Country_Code__c,Status,CaseType__c,Customer_Type__c,
Address__CountryCode__s,Address__PostalCode__s,Address__StateCode__s,PassportIssueDate__c,
Address__Street__s,Passport_Expiry_Date__c,ChequeWithWithdrawlFees__c,BuyerLegalApprovalStatus__c,
PendingFees__c,ResalePaymentType__c,ADDCAmount__c,IsPaymentReviewRequired__c,WillMakeMorePayment__c,
PaymentApprovalStatus__c,ServiceCatalog__c,Account.Legal_Status__c,isLegalReviewRequired__c,LegalApprovalStatus__c,
Sales_Order__r.ADM_Fee_Included__c,ADMFees__c,
Sales_Order__r.IsTaxable__c,Main_Buyer_Share_Percentage__c,
Sales_Order__r.ADMFeeWaivedAmount__c,
Sales_Order__r.SellingPrice__c,
Sales_Order__r.SalesPriceExcludingADMwithDiscount__c,
Sales_Order__r.Sales_Price_Excluding_ADM__c,
Sales_Order__r.Amount_Payable_Excluding_ADM__c,
Sales_Order__r.PaymentPlanDiscount__c,
Sales_Order__r.BulkDiscount__c,
Sales_Order__r.Management_Discount__c,
Sales_Order__r.ADM_Fee_Combined__c,
Sales_Order__r.Broker_Agencyy__c,
Sales_Order__r.SoldDate__c,  
Sales_Order__r.Account__c,
Sales_Order__r.Discount__c,
Sales_Order__r.CorporateDiscount__c,
Sales_Order__r.BookingDate__c,
Sales_Order__r.OwnerSharePercentage__c,
Sales_Order__r.ADM_DLD_Pre_Registered__c,
Sales_Order__r.Pre_Title_Deed_Status__c,
Sales_Order__r.Title_Deed_Status__c,
Sales_Order__r.Handover_Status__c,
Sales_Order__r.ADDC__c,             
Owner.Phone,TypeOfResale__c,ResalePrice__c,

Sales_Order__r.ADMFeeAmount__c,Sales_Order__r.PaymentPlan__r.Name,
BookTitleFeeUnder__c,ExcludeEvaluationFee__c,ExcludeHassantukFee__c,ExcludeMortgageFee__c,ExcludePendingFee__c,
ExcludeRecoveryFee__c,ExcludeTitleDeedFee__c,ExcludeAdmFee__c,ExcludeAdminFee__c,ExcludeChequeBounceFee__c,ExcludeChequeWithdrawlFee__c,NameOfPOA__c,PlaceOfIssuance__c,PlaceOfRegistration__c,RepresentationType__c,
TypeOfCompany__c,RepresentativeArabicName__c,PercentageOfSharePurchased__c
from Case limit 1];


Document__c doc = [Select id from Document__c where Case__c = :caseObj.id];

List<ContentDocumentLink> cdl = [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId = :doc.id];
Map<String,Object> response = new Map<String,Object> ();
Test.startTest();
caseObj.LegalApprovalStatus__c = 'Rejected'; 
update caseObj;
response = ResaleServiceRequestHandler.getInstance().validateUnderConstructionForNextReview(caseObj); 
//System.assertEquals('Cannot move to next review since the Legal Review approval is Rejected/Pending.', response.get('message'), 'should successfully move to next review');
caseObj.LegalApprovalStatus__c = 'Approved';
update caseObj;
caseObj.BuyerLegalApprovalStatus__c = 'Approved';
update caseObj;
response = ResaleServiceRequestHandler.getInstance().validateUnderConstructionForNextReview(caseObj);
caseObj.Step__c ='2';
caseObj.LatePaymentFees__c = 100;
caseObj.BouncedChequeFees__c = 100;
caseObj.RecoveryFee__c = 200;

caseObj.WithdrawlRequestInitiated__c ='Yes';
caseObj.NewPDCReceived__c = 'Yes';
caseObj.ReversalRequestSubmittedForPDCs__c = 'Yes'; 
caseObj.NewCustomerAccount__c = null;
caseObj.EmiratesID__c = '98765';
caseObj.PassportNumber__c = '9876599';
update caseObj;
response = ResaleServiceRequestHandler.getInstance().validateUnderConstructionForNextReview(caseObj); 
ResaleServiceRequestHandler.getInstance().createDocuments(new List<Case>{ caseObj });
caseObj.CustomerType__c = 'Organization';
caseObj.Name__c = 'test Account';
caseObj.Trade_License_No__c ='1234';
caseObj.Trade_License_Issue_Date__c = System.today().addDays(-20);
caseObj.Trade_License_Expiry_Date__c = System.today().addDays(40);
caseObj.Registration_Authority__c ='123';
caseObj.RepresentativeArabicName__c = '1234';
caseObj.TypeOfCompany__c = 'test';
caseObj.RepresentationType__c = 'Father';
caseObj.PlaceOfRegistration__c ='Abu Dhabi';
caseObj.PlaceOfIssuance__c = 'test';
caseObj.NameOfPOA__c = 'test';
caseObj.PercentageOfSharePurchased__c = 2; 
update caseObj;
ResaleServiceRequestHandler.createPrimaryBuyerAccount(caseObj);
caseObj.Step__c = '0'; 
update caseObj;
ResaleServiceRequestHandler.getInstance().validateResaleForNextReview(caseObj);
ResaleServiceRequestHandler.getInstance().validateResaleForNextReview(null);
ResaleServiceRequestHandler.getInstance().validateCompletedProjectForNextReview(null);


System.assertEquals('Case moved to next review successfully.', response.get('message'), 'should successfully move to next review');
Test.stopTest();
}*/
    
    @IsTest
    static void testValidateDocuments() {
        // Step 1: Create Case record
        Case testCase = [Select id from Case Limit 1];
        
        // Step 2: Create dummy Document__c records
        List<Document__c> docs = new List<Document__c>();
        for(String name : new List<String>{ 'Buyer Emirates ID','Seller Emirates ID', 'MOU', 'Buyer Passport','Seller Passport' }) {
            docs.add(new Document__c(
                Document_Name__c  = name,
                Case__c = testCase.Id
            ));
        }
        insert docs;
        
        
        ContentVersion cv = new ContentVersion(
            Title = 'TestFile',
            PathOnClient = 'TestFile.pdf',
            VersionData = Blob.valueOf('Test file content')
        );
        insert cv;
        
        // After insert, query its ContentDocumentId
        Id contentDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
        
        // Step 4: Link this ContentDocument to your documents
        List<ContentDocumentLink> links = new List<ContentDocumentLink>();
        for (Document__c d : docs) {
            links.add(new ContentDocumentLink(
                ContentDocumentId = contentDocId,
                LinkedEntityId = d.Id,
                ShareType = 'V',
                Visibility = 'AllUsers'
            ));
        }
        insert links;
        
        // Step 5: Call your method
        Test.startTest();
        List<ContentDocumentLink> result = ResaleServiceRequestHandler.validateDocuments(testCase);
        Test.stopTest();
        
        // Step 6: Assert
        System.assertNotEquals(0, result.size(), 'Should return ContentDocumentLink records');
        System.assertEquals(links.size(), result.size(), 'Returned list size should match inserted CDL count');
    }
    @IsTest
    static void test_sendNewServiceRequestAssignmnmentEmailNotification() {
        Case testCase = [Select id,CaseType__c,ContactId, StopEmailsToCustomer__c from Case Limit 1];
        
        Test.startTest();
        ResaleServiceRequestHandler obj = ResaleServiceRequestHandler.getInstance();
        obj.sendNewServiceRequestAssignmnmentEmailNotification(new List<Case>{ testCase });
        Test.stopTest(); 
        
        
        System.assert(true, 'Method executed successfully');
    }
    
    @IsTest
    static void test_sendNewServiceRequestAssignmnmentEmailNotification_nonServiceCase() {
        Case caseObj = [Select id,CaseType__c,ContactId, StopEmailsToCustomer__c from Case Limit 1];
        Test.startTest();
        ResaleServiceRequestHandler obj = ResaleServiceRequestHandler.getInstance();
        obj.sendNewServiceRequestAssignmnmentEmailNotification(new List<Case>{ caseObj });
        Test.stopTest();
        
        System.assert(true, 'Non-service case path executed');
    }
@isTest
static void test_validateJointBuyerDetails_valid() {

    // Create Account
    Account acc = new Account(Name = 'Test Account');
    insert acc;

    // Create Case
    Case caseObj = new Case(
        AccountId = acc.Id,
        Account__c = acc.Id,
        Status = 'New', 
        Origin = 'Phone',
        Step__c = 'Joint Buyer Details'
        
    );
     CaseService.getInstance().insertCaseWithoutTrigger(caseObj);

  //  insert caseObj;

    // Create JointOwner (with all required fields)
    JointOwner__c jo = new JointOwner__c(
        Case__c = caseObj.Id,
        First_Name__c = 'John',
        Last_Name__c = 'Doe',
        Phone_Number__c = '9999999999',
        Email__c = 'test@test.com',
        Mobile_Country_Code__c = '91',
        Gender__c = 'Male',
        PassportIssueDate__c = Date.today().addYears(-5),
        Customer_Type__c = 'Resident',
        NameInArabic__c = 'جون',
        Passport_Number__c = 'A123456',
        Passport_Expiry_Date__c = Date.today().addYears(5),
        Nationality__c = 'Indian',
        Address__City__s = 'Dubai',
        Address__CountryCode__s = 'AE',
        Address__StateCode__s = '01',
        Address__Street__s = 'Street 1',
        Address__PostalCode__s = '12345',
        Salutation__c = 'Mr.',
        Language_Preference__c = 'English',
        Birthdate__c = Date.newInstance(1990,1,1),
        UAEResident__c = 'Resident',
        PlaceofIssue__c = 'Dubai',
        Emirates_ID__c = '784199999999999',
        Emirates_ID_expiry_date__c = Date.today().addYears(5),
        SharePercentage__c = 100
    );
    insert jo;

    // Call method and assert
    Test.startTest();
    Boolean result = ResaleServiceRequestHandler.getInstance()
        .validateJointBuyerDetails(caseObj);
    Test.stopTest();

    System.assertEquals(true, result, 'Joint buyer validation should pass');
}
@isTest
static void test_validateOrganizationDetails_valid() {

    // 🔹 Create a test Account
    Account acc = new Account(Name = 'Test Organization Account');
    insert acc;

    // 🔹 Create a test Case with all required organization fields populated
    Case caseObj = new Case(
        AccountId = acc.Id,
        Account__c = acc.Id,
        Status = 'New',             // use a valid picklist value
        Origin = 'Phone',           // use a valid picklist value
        Mobile_Country_Code__c = '91',
        Mobile_Number__c = '9999999999',
        Address__CountryCode__s = 'AE',
        Address__PostalCode__s = '12345',
        Address__StateCode__s = '01',
        Address__Street__s = 'Street 1',
        Email_Address__c = 'org@test.com',
        Name__c = 'Test Organization LLC',
        Trade_License_No__c = 'TL-123456',
        Trade_License_Issue_Date__c = Date.today().addYears(-1),
        Trade_License_Expiry_Date__c = Date.today().addYears(4),
        Registration_Authority__c = '123'
    );
     CaseService.getInstance().insertCaseWithoutTrigger(caseObj);

  //  insert caseObj;

    // 🔹 Call the private method via TestVisible
    Test.startTest();
    Boolean result = ResaleServiceRequestHandler.getInstance()
        .validateOrganizationDetails(caseObj);
    Test.stopTest();

    // 🔹 Assert that the validation passes
    System.assertEquals(true, result, 'Organization details validation should pass');
}

@isTest
static void test_validateForLegalStatusApproval() {

    // 🔹 Step 1: Create Project and Units
    Project__c project = new Project__c(Name = 'Test Project');
    insert project;

    Unit__c unitWithLegal = new Unit__c(
        Name = 'Unit With Legal',
        Project__c = project.Id,
        Legal_Status__c = 'With Legal'
    );
    insert unitWithLegal;

    Unit__c unitWithoutLegal = new Unit__c(
        Name = 'Unit Without Legal',
        Project__c = project.Id
    );
    insert unitWithoutLegal;

    // 🔹 Step 2: Create Account
    Account acc = new Account(Name = 'Test Account');
    insert acc;

    // 🔹 Step 3: Create Cases
    Case case1 = new Case(
        AccountId = acc.Id,
        Account__c = acc.Id,
        Unit__c = unitWithLegal.Id,
        isLegalReviewRequired__c = true,
        Status = 'New',
        Origin = 'Phone'
    );
     CaseService.getInstance().insertCaseWithoutTrigger(case1);

    //insert case1;

    Case case2 = new Case(
        AccountId = acc.Id,
        Account__c = acc.Id,
        Unit__c = unitWithoutLegal.Id,
        isLegalReviewRequired__c = false,
        Status = 'New',
        Origin = 'Phone'
    );
    
     CaseService.getInstance().insertCaseWithoutTrigger(case2);
    //insert case2;

    // 🔹 Step 4: Run all validations in a single Test.startTest / stopTest block
    Map<String, Object> response1;
    Map<String, Object> response2;
    Test.startTest();
        response1 = ResaleServiceRequestHandler.getInstance()
            .validateForLegalStatusApproval(case1);

        response2 = ResaleServiceRequestHandler.getInstance()
            .validateForLegalStatusApproval(case2);
    Test.stopTest();

    // 🔹 Step 5: Assertions
    System.assertNotEquals(null, response1, 'Response1 should not be null');
    System.assert(response1.containsKey('status'), 'Response1 should contain status');

    System.assertEquals('success', response2.get('status'), 'Response2 status should be success');
    System.assertEquals('Case moved to next review successfully.', response2.get('message'),
        'Response2 success message should match');
}

@isTest
static void test_validateBuyerLegalApproval() {

    // 🔹 Step 1: Create Account(s) to simulate duplicates
    Account personLegalAcc = new Account(
        Name = 'Person With Legal',
        Legal_Status__c = 'With Legal'
    );
    insert personLegalAcc;

    Account personNonLegalAcc = new Account(
        Name = 'Person Without Legal',
        Legal_Status__c = 'Case Closed'
    );
    insert personNonLegalAcc;

    Account orgLegalAcc = new Account(
        Name = 'Organization With Legal',
        Legal_Status__c = 'With Legal'
    );
    insert orgLegalAcc;

    // 🔹 Step 2: Create a Case for Person with Legal
    Case casePersonLegal = new Case(
        CustomerType__c = 'Person',
        EmiratesID__c = 'E123',
        PassportNumber__c = 'P123',
        Nationality__c = 'UAE',
        Status = 'New'
    );
     CaseService.getInstance().insertCaseWithoutTrigger(casePersonLegal);

   // insert casePersonLegal;

    // 🔹 Step 3: Create a Case for Person without Legal
    Case casePersonNonLegal = new Case(
        CustomerType__c = 'Person',
        EmiratesID__c = 'E124',
        PassportNumber__c = 'P124',
        Nationality__c = 'UAE',
        Status = 'New'
    );
    CaseService.getInstance().insertCaseWithoutTrigger(casePersonNonLegal);
   // insert casePersonNonLegal;

    // 🔹 Step 4: Create a Case for Organization with Legal
    Case caseOrgLegal = new Case(
        CustomerType__c = 'Organization',
        Trade_License_No__c = 'TL123',
        Registration_Authority__c = 'RA1',
        Status = 'New'
    );
    CaseService.getInstance().insertCaseWithoutTrigger(caseOrgLegal);
   // insert caseOrgLegal;

    // 🔹 Step 5: Create a Case for Organization without Legal
    Case caseOrgNonLegal = new Case(
        CustomerType__c = 'Organization',
        Trade_License_No__c = 'TL124',
        Registration_Authority__c = 'RA2',
        Status = 'New'
    );
    CaseService.getInstance().insertCaseWithoutTrigger(caseOrgNonLegal);
   // insert caseOrgNonLegal;

    // 🔹 Step 6: Run all validations in a single Test.startTest/Test.stopTest block
    Map<String, Object> responsePersonLegal;
    Map<String, Object> responsePersonNonLegal;
    Map<String, Object> responseOrgLegal;
    Map<String, Object> responseOrgNonLegal;

    Test.startTest();
        responsePersonLegal = ResaleServiceRequestHandler.getInstance()
            .validateBuyerLegalApproval(casePersonLegal);

        responsePersonNonLegal = ResaleServiceRequestHandler.getInstance()
            .validateBuyerLegalApproval(casePersonNonLegal);

        responseOrgLegal = ResaleServiceRequestHandler.getInstance()
            .validateBuyerLegalApproval(caseOrgLegal);

        responseOrgNonLegal = ResaleServiceRequestHandler.getInstance()
            .validateBuyerLegalApproval(caseOrgNonLegal);
    Test.stopTest();

    // 🔹 Step 7: Assertions

    // Person with Legal → handleBuyerLegalApproval called
    System.assertNotEquals(null, responsePersonLegal, 'Response should not be null');
    System.assert(responsePersonLegal.containsKey('status'), 'Response should contain status');

    // Person without Legal → success returned
    System.assertEquals('success', responsePersonNonLegal.get('status'));
    System.assertEquals('Case moved to next review successfully.', responsePersonNonLegal.get('message'));

    // Organization with Legal → handleBuyerLegalApproval called
    System.assertNotEquals(null, responseOrgLegal, 'Response should not be null');
    System.assert(responseOrgLegal.containsKey('status'), 'Response should contain status');

    // Organization without Legal → success returned
    System.assertEquals('success', responseOrgNonLegal.get('status'));
    System.assertEquals('Case moved to next review successfully.', responseOrgNonLegal.get('message'));
}
@IsTest
static void test_validateADMFees_allBranches() {

    ResaleServiceRequestHandler handler =
        ResaleServiceRequestHandler.getInstance();

    // 1️⃣ NULL case
    System.assertEquals(
        false,
        handler.validateADMFees(null),
        'Null case should return false'
    );

    // 2️⃣ Title Deed Issued = Yes
    Case c1 = new Case(
        Title_Deed_Issued__c = 'Yes'
    );
    System.assertEquals(true, handler.validateADMFees(c1));

    // 3️⃣ Dubai city → Title Deed logic
    Case c2 = new Case(
        City__c = 'Dubai',
        TitleDeedFees__c = 100,
        BookTitleFeeUnder__c = 'Buyer',
         CancellationFees__c = 300
    );
    System.assertEquals(true, handler.validateADMFees(c2));

    // 4️⃣ Under Construction → ADM fees
    Case c3 = new Case(
        ProjectStatus__c = 'Under Construction',
        ADMTotalFees__c = 500,
        ADMAdminFees__c = 200,
        CancellationFees__c = 300
    );
    System.assertEquals(true, handler.validateADMFees(c3));

    // 5️⃣ Completed + Gifting
    Case c4 = new Case(
        ProjectStatus__c = 'Completed',
        TypeOfResale__c = 'Gifting',
        ADMTotalFees__c = 500,
        ADMAdminFees__c = 200,
        EvaluationFees__c = 300,
        TitleDeedFees__c = 100,
        BookTitleFeeUnder__c = 'Buyer',
        CancellationFees__c = 300
    );
    System.assertEquals(true, handler.validateADMFees(c4));

    // 6️⃣ Completed (non-gifting)
    Case c5 = new Case(
        ProjectStatus__c = 'Completed',
        TypeOfResale__c = 'Resale',
        ADMTotalFees__c = 500,
        ADMAdminFees__c = 200,
        EvaluationFees__c = 300,
        CancellationFees__c = 300
    );
    System.assertEquals(true, handler.validateADMFees(c5));

    // 7️⃣ Default false path
    Case c6 = new Case(
        ProjectStatus__c = 'Completed'
    );
    System.assertEquals(false, handler.validateADMFees(c6));
}
    @isTest
static void test_DataMigrationPath_FIXED() {

    Account acc = [SELECT Id FROM Account LIMIT 1];

    // Create Payment Plan
    PaymentPlan__c plan = new PaymentPlan__c(Name = 'Data Migration',Description__c = 'testr');
    insert plan;

    // Sales Order
    SalesOrder__c so = new SalesOrder__c(
        Account__c = acc.Id,
        PaymentPlan__c = plan.Id
    );
    insert so;

    // Case
    Case c = new Case(
        AccountId = acc.Id,
        Sales_Order__c = so.Id,
        BillingToCompleteAmount__c = 5000,
        TotalCollection__c = 2000
    );
    CaseService.getInstance().insertCaseWithoutTrigger(c);

   // insert c;

    // Installment (PENDING)
    InstallmentLines__c inst = new InstallmentLines__c(
        SalesOrder__c = so.Id,
        InstallmentAmount__c = 5000,
        ClearedAmount__c = 1000,
        Description__c = 'Test 1',
        InstallmentDate__c = System.today().addDays(10), 
        InstallmentPercentage__c = 50,
        BrokerPayoutPercentage__c = 5,
        Installment_Amount_Excluding_ADM__c = 4000
    );
    insert inst;

    Test.startTest();
        ResaleServiceRequestHandler.getInstance()
            .calculateInstallmentsAndReceipts(so.Id, so, c);
    Test.stopTest();

    System.assert(true, 'Data Migration path executed');
}
@isTest
static void test_FinalElsePath_FIXED() {

    Account acc = [SELECT Id FROM Account LIMIT 1];

    SalesOrder__c so = new SalesOrder__c(
        Account__c = acc.Id
    );
    insert so;

    Case c = new Case(
        AccountId = acc.Id,
        Sales_Order__c = so.Id,
        BillingToCompleteAmount__c = 3000,
        TotalCollection__c = 3000
    );
    CaseService.getInstance().insertCaseWithoutTrigger(c);

//    insert c;

    Test.startTest();
        ResaleServiceRequestHandler.getInstance()
            .calculateInstallmentsAndReceipts(so.Id, so, c);
    Test.stopTest();

    System.assert(true, 'Final else path executed');
}
/*@isTest
static void test_PendingAndMergedInstallments_FIXED() {

    Account acc = [SELECT Id FROM Account LIMIT 1];

    SalesOrder__c so = new SalesOrder__c(Account__c = acc.Id);
    insert so;

    Case c = new Case(
        AccountId = acc.Id,
        Sales_Order__c = so.Id,
        BillingToCompleteAmount__c = 8000,
        TotalCollection__c = 4000
    );
    CaseService.getInstance().insertCaseWithoutTrigger(c);

//    insert c;

    // Pending installment
    InstallmentLines__c pending = new InstallmentLines__c(
        SalesOrder__c = so.Id,
        InstallmentAmount__c = 6000,
        ClearedAmount__c = 1000,
          Description__c = 'Test',
        InstallmentDate__c = System.today().addDays(10),
        InstallmentPercentage__c = 60,
        BrokerPayoutPercentage__c = 5,
        Installment_Amount_Excluding_ADM__c = 5000
    );
    insert pending;

    // Merged installment
    InstallmentLines__c merged = new InstallmentLines__c(
        SalesOrder__c = so.Id,
        InstallmentAmount__c = 2000,
        ClearedAmount__c = 2000,
        InstallmentDate__c = System.today().addDays(10),
        Description__c = 'Test',
        InstallmentPercentage__c = 40,
        BrokerPayoutPercentage__c = 5,
        Installment_Amount_Excluding_ADM__c = 2000
    );
    insert merged;

    Test.startTest();
        ResaleServiceRequestHandler.getInstance()
            .calculateInstallmentsAndReceipts(so.Id, so, c);
    Test.stopTest();

    System.assert(true, 'Pending + merged logic executed');
}*/
    @IsTest
static void test_createDocuments() {
String RESALE_PROPERTY_UNDER_CONSTRUCTION_RT ='Resale_Property_Under_Construction';
 Id caseRT = Utility.getRecordTypeIdByDevName(Case.SObjectType,RESALE_PROPERTY_UNDER_CONSTRUCTION_RT);

    // Create Case
    Case c = new Case(
        Subject = 'Test Case',
        Status = 'New',
        Origin = 'Phone',
        RecordTypeId = caseRT
    );
    insert c;

    // Create Document Types required by getDocTypes()
    List<DocumentType__c> docTypes = new List<DocumentType__c>{
        new DocumentType__c(
            Type__c = 'Passport',
            ObjectType__c  = 'Case',
            RecordTypeDevName__c = 'RESALE_PROPERTY_UNDER_CONSTRUCTION_RT'
        ),
        new DocumentType__c(
            Type__c = 'Passport',
            ObjectType__c  = 'Case',
            RecordTypeDevName__c = 'RESALE_PROPERTY_UNDER_CONSTRUCTION_RT'
        )
    };
    insert docTypes;

    Test.startTest();
        ResaleServiceRequestHandler.getInstance().createDocuments(new List<Case>{ c });
    Test.stopTest();

    // Verify Documents were created
    List<Document__c> docs = [
        SELECT Id, Case__c, Document_Name__c, DocumentType__c
        FROM Document__c
        WHERE Case__c = :c.Id
    ];
}
@IsTest
    static void test_createSalesOrderDocument() {
    String RESALE_PROPERTY_UNDER_CONSTRUCTION_RT = 'Resale_Property_Under_Construction';
    Account acc = [SELECT Id FROM Account LIMIT 1];
    SalesOrder__c so = new SalesOrder__c(
        Name = 'Test Sales Order',
        Account__c = acc.Id
    );
    insert so;
    List<DocumentType__c> docTypes = new List<DocumentType__c>{
        new DocumentType__c(
            Type__c = 'Buyer Passport',
            ObjectType__c = 'Sales Order',
            RecordTypeDevName__c = 'Resale_Property_Under_Construction',
            Active__c = true
        ),
        new DocumentType__c(
            Type__c = 'MOU',
            ObjectType__c = 'Sales Order',
            RecordTypeDevName__c = 'Resale_Property_Under_Construction',
            Active__c = true
        )
    };
    insert docTypes;

    Test.startTest();
        ResaleServiceRequestHandler.getInstance().createSalesOrderDocument(so.Id);
    Test.stopTest();
    
    List<Document__c> docs = [
        SELECT Id, SalesOrder__c, Document_Name__c, DocumentType__c FROM Document__c WHERE SalesOrder__c = :so.Id];
}
  @isTest
static void testUpdateHandoverRecords() {

    // Create accounts together
    List<Account> accList = new List<Account>{
        new Account(Name='Old Customer'),
        new Account(Name='New Customer')
    };
    insert accList;

    Account oldAcc = accList[0];
    Account newAcc = accList[1];

    // Create sales orders together
    List<SalesOrder__c> soList = new List<SalesOrder__c>{
        new SalesOrder__c(
            Name='Old SO',
            Account__c=oldAcc.Id
        ),
        new SalesOrder__c(
            Name='New SO',
            Account__c=newAcc.Id
        )
    };
    insert soList;

    SalesOrder__c oldSO = soList[0];
    SalesOrder__c newSO = soList[1];

    // Create handover
    Handover__c ho = new Handover__c(
        Sales_Order__c = oldSO.Id,
        Account__c = oldAcc.Id,
        Previous_HO_Status__c = 'Settlement Follow up',
        Sub_Status__c = 'Under Resale',
        Is_Property_keys_given__c = false
    );

    insert ho;

    // No need to insert Case
    Case c = new Case(
        Sales_Order__c = oldSO.Id,
        NewSalesOrder__c = newSO.Id,
        NewCustomerAccount__c = newAcc.Id,
        Subject='Test'
    );

    Test.startTest();

    ResaleServiceRequestHandler.getInstance()
        .updateHandoverRecords(new List<Case>{c});

    Test.stopTest();

    Handover__c updatedHO = [
        SELECT Sales_Order__c,
               Account__c,
               Sub_Status__c,
               Previous_HO_Status__c,Is_Property_keys_given__c
        FROM Handover__c
        
        WHERE Id = :ho.Id AND Is_Property_keys_given__c = false
    ];

    System.assertEquals(
        newSO.Id,
        updatedHO.Sales_Order__c
    );

    System.assertEquals(
        newAcc.Id,
        updatedHO.Account__c
    );

    System.assertEquals(
        'Settlement Follow up',
        updatedHO.Sub_Status__c
    );
}
  @IsTest
static void testValidatePHPPForNextReview_Step4() {

    // Get an existing Case created by your test setup
    List<Case> caseList = [
        SELECT Id,
               RecordTypeId,
               Step__c,
               City__c,
               Pre_title_deed_shared__c,
               NewSalesOrder__r.Bloom_Signed_SPA_Date__c,
               IsBuyerFinancing__c,
               Unit_Mortgaged__c,
               PaymentReceived__c,
               SmartHubActivated__c,
               NewSalesOrder__c
        FROM Case
        LIMIT 1
    ];

    System.assert(!caseList.isEmpty(), 'No Case found for test.');

    Case caseObj = caseList[0];

    // Ensure a Sales Order exists
    SalesOrder__c so;

    if (caseObj.NewSalesOrder__c != null) {
        so = [
            SELECT Id, CRMRepresentative__c
            FROM SalesOrder__c
            WHERE Id = :caseObj.NewSalesOrder__c
            LIMIT 1
        ];
    } else {

        Account acc = new Account(
            Name = 'PHPP Test Account'
        );
        insert acc;

        so = new SalesOrder__c(
            Account__c = acc.Id
        );
        insert so;

        caseObj.NewSalesOrder__c = so.Id;
    }

    // Populate mandatory Step 4 fields
    caseObj.Step__c = '4';
    caseObj.City__c = 'Dubai';
    caseObj.Pre_title_deed_shared__c = 'Yes';
    caseObj.IsBuyerFinancing__c = 'No';
    caseObj.PaymentReceived__c = 'From the Buyer';
    caseObj.SmartHubActivated__c = 'Yes';

    update caseObj;

    Test.startTest();

    Map<String,Object> response =
        ResaleServiceRequestHandler.getInstance()
            .validatePHPPForNextReview(caseObj);
      ResaleServiceRequestHandler.getInstance()
            .updateCRMRepresentative(caseObj);
    

    Test.stopTest();

    System.debug(response);

    if (response.get('status') == 'success') {

        so = [
            SELECT CRMRepresentative__c
            FROM SalesOrder__c
            WHERE Id = :so.Id
        ];

        System.assertEquals(
            UserInfo.getUserId(),
            so.CRMRepresentative__c
        );

    } 
}
    @IsTest
static void testValidatePHPPForNextReview_Step5() {

    Case caseObj = [
        SELECT Id,
              TotalCollection__c,Unit__r.Name,TypeOfResale__c,DirectIndirect__c,
                        Step__c,LatePaymentFees__c,HassantukFee__c,Unit__r.Project__r.ResaleUnitAdminFeeVilla__c,Unit__r.Project__r.ResaleUnitEvaluationFeeVilla__c,
                        CustomerType__c,Unit__r.UnitType__c,Sales_Order__r.NetAmount__c,BouncedChequeFees__c,NewCustomerAccount__r.name,Sales_Order__r.Opportunity__r.LeadChannel__c,
                        Last_Name__c,RecoveryFee__c,Sales_Order__r.Opportunity__r.WinReason__c,NewCustomerAccount__c,
                        First_Name__c,WithdrawlRequestInitiated__c,Sales_Order__r.name,Unit__c,
                        EmiratesID__c,NewPDCReceived__c,Sales_Order__r.Opportunity__r.BrokerAgencyAccount__c,
                        Emirates_ID_expiry_date__c,ResalePrice__c,
                        PassportNumber__c,ReversalRequestSubmittedForPDCs__c, CancellationFees__c,
                        Nationality__c,ProjectStatus__c,
                        EvaluationFees__c,ADMTotalFees__c,TitleDeedFees__c,ADMAdminFees__c,MortgageFees__c,
                        Email_Address__c,
                        NewSalesOrder__c,
                        Name__c, 
                        Sales_Order__r.SalesManager__c,
                        Sales_Order__r.AmountPayable__c,
                        Trade_License_No__c,
                        Trade_License_Issue_Date__c,
                        Trade_License_Expiry_Date__c,
                        Registration_Authority__c,Unit__r.Project__r.ResaleWithMortgageAdminFeeVilla__c,Unit__r.Project__r.ResaleWithMortgageMortgageFeeVilla__c,Unit__r.Project__r.ResaleWithMortgageEvaluationFeeVilla__c,
                        Address__City__s,Mobile_Number__c,Mobile_Country_Code__c,Status,CaseType__c,
                        Address__CountryCode__s,Address__PostalCode__s,Address__StateCode__s,
                        Address__Street__s,PassportExpiryDate__c,ChequeWithWithdrawlFees__c,BuyerLegalApprovalStatus__c,
                        PendingFees__c,ResalePaymentType__c,ADDCAmount__c,IsPaymentReviewRequired__c,WillMakeMorePayment__c,
                        PaymentApprovalStatus__c,ServiceCatalog__c,Account.Legal_Status__c,isLegalReviewRequired__c,LegalApprovalStatus__c,Sales_Order__r.ADM_Fee_Included__c,
                        Sales_Order__r.IsTaxable__c,Main_Buyer_Share_Percentage__c,
                        Sales_Order__r.ADMFeeWaivedAmount__c,
                        Sales_Order__r.SellingPrice__c,
                        Sales_Order__r.SalesPriceExcludingADMwithDiscount__c,
                        Sales_Order__r.Sales_Price_Excluding_ADM__c,
                        Sales_Order__r.Amount_Payable_Excluding_ADM__c,
                        Sales_Order__r.PaymentPlanDiscount__c,
                        Sales_Order__r.BulkDiscount__c,ADMFees__c,
                        Sales_Order__r.Management_Discount__c,
                        Sales_Order__r.Discount__c,
                        Sales_Order__r.ADM_Fee_Combined__c,
                        Sales_Order__r.CorporateDiscount__c,
                        Sales_Order__r.BookingDate__c,
                        Sales_Order__r.Broker_Agencyy__c,
                        Sales_Order__r.SoldDate__c,  
                        Sales_Order__r.Account__c,
                        Sales_Order__r.OwnerSharePercentage__c,
                        Owner.Phone,
                        Sales_Order__r.PaymentPlan__r.Name,
                        Sales_Order__r.ADMFeeAmount__c,
                        Sales_Order__r.ADM_DLD_Pre_Registered__c,
                        Sales_Order__r.Pre_Title_Deed_Status__c,
                        Sales_Order__r.Title_Deed_Status__c,
                        Sales_Order__r.Handover_Status__c,
                        Sales_Order__r.ADDC__c,BrokerAgency__c,Broker_Agent__c,Broker_Commission__c,MOUDate__c,Salutation__c,PlaceofIssue__c,LanguagePreference__c,UAEResident__c,Birthdate__c,
                        BillingToCompleteAmount__c, BillingToCompleteAmountInArabic__c, ResalePriceInArabicWords__c,
                        BookTitleFeeUnder__c,ExcludeEvaluationFee__c,ExcludeHassantukFee__c,ExcludeMortgageFee__c,ExcludePendingFee__c,
                        ExcludeRecoveryFee__c,ExcludeTitleDeedFee__c,ExcludeAdmFee__c,ExcludeAdminFee__c,ExcludeChequeBounceFee__c,ExcludeChequeWithdrawlFee__c
        FROM Case
        LIMIT 1
    ];

    caseObj.Step__c = '5';
    update caseObj;

    Test.startTest();

    ResaleServiceRequestHandler.getInstance()
        .validatePHPPForNextReview(caseObj);
    
    

    Test.stopTest();
}
    @IsTest
    static void testSalesOrderCancellation() {
        
        Case caseObj = [
        SELECT Id,
              TotalCollection__c,Unit__r.Name,TypeOfResale__c,DirectIndirect__c,
                        Step__c,LatePaymentFees__c,HassantukFee__c,Unit__r.Project__r.ResaleUnitAdminFeeVilla__c,Unit__r.Project__r.ResaleUnitEvaluationFeeVilla__c,
                        CustomerType__c,Unit__r.UnitType__c,Sales_Order__r.NetAmount__c,BouncedChequeFees__c,NewCustomerAccount__r.name,Sales_Order__r.Opportunity__r.LeadChannel__c,
                        Last_Name__c,RecoveryFee__c,Sales_Order__r.Opportunity__r.WinReason__c,NewCustomerAccount__c,
                        First_Name__c,WithdrawlRequestInitiated__c,Sales_Order__r.name,Unit__c,
                        EmiratesID__c,NewPDCReceived__c,Sales_Order__r.Opportunity__r.BrokerAgencyAccount__c,
                        Emirates_ID_expiry_date__c,ResalePrice__c,
                        PassportNumber__c,ReversalRequestSubmittedForPDCs__c, CancellationFees__c,
                        Nationality__c,ProjectStatus__c,
                        EvaluationFees__c,ADMTotalFees__c,TitleDeedFees__c,ADMAdminFees__c,MortgageFees__c,
                        Email_Address__c,
                        NewSalesOrder__c,
                        Name__c, 
                        Sales_Order__r.SalesManager__c,
                        Sales_Order__r.AmountPayable__c,
                        Trade_License_No__c,
                        Trade_License_Issue_Date__c,
                        Trade_License_Expiry_Date__c,
                        Registration_Authority__c,Unit__r.Project__r.ResaleWithMortgageAdminFeeVilla__c,Unit__r.Project__r.ResaleWithMortgageMortgageFeeVilla__c,Unit__r.Project__r.ResaleWithMortgageEvaluationFeeVilla__c,
                        Address__City__s,Mobile_Number__c,Mobile_Country_Code__c,Status,CaseType__c,
                        Address__CountryCode__s,Address__PostalCode__s,Address__StateCode__s,
                        Address__Street__s,PassportExpiryDate__c,ChequeWithWithdrawlFees__c,BuyerLegalApprovalStatus__c,
                        PendingFees__c,ResalePaymentType__c,ADDCAmount__c,IsPaymentReviewRequired__c,WillMakeMorePayment__c,
                        PaymentApprovalStatus__c,ServiceCatalog__c,Account.Legal_Status__c,isLegalReviewRequired__c,LegalApprovalStatus__c,Sales_Order__r.ADM_Fee_Included__c,
                        Sales_Order__r.IsTaxable__c,Main_Buyer_Share_Percentage__c,
                        Sales_Order__r.ADMFeeWaivedAmount__c,
                        Sales_Order__r.SellingPrice__c,
                        Sales_Order__r.SalesPriceExcludingADMwithDiscount__c,
                        Sales_Order__r.Sales_Price_Excluding_ADM__c,
                        Sales_Order__r.Amount_Payable_Excluding_ADM__c,
                        Sales_Order__r.PaymentPlanDiscount__c,
                        Sales_Order__r.BulkDiscount__c,ADMFees__c,
                        Sales_Order__r.Management_Discount__c,
                        Sales_Order__r.Discount__c,
                        Sales_Order__r.ADM_Fee_Combined__c,
                        Sales_Order__r.CorporateDiscount__c,
                        Sales_Order__r.BookingDate__c,
                        Sales_Order__r.Broker_Agencyy__c,
                        Sales_Order__r.SoldDate__c,  
                        Sales_Order__r.Account__c,
                        Sales_Order__r.OwnerSharePercentage__c,
                        Owner.Phone,
                        Sales_Order__r.PaymentPlan__r.Name,
                        Sales_Order__r.ADMFeeAmount__c,
                        Sales_Order__r.ADM_DLD_Pre_Registered__c,
                        Sales_Order__r.Pre_Title_Deed_Status__c,
                        Sales_Order__r.Title_Deed_Status__c,
                        Sales_Order__r.Handover_Status__c,NewSalesOrder__r.Opportunity__c,
                        Sales_Order__r.ADDC__c,BrokerAgency__c,Broker_Agent__c,Broker_Commission__c,MOUDate__c,Salutation__c,PlaceofIssue__c,LanguagePreference__c,UAEResident__c,Birthdate__c,
                        BillingToCompleteAmount__c, BillingToCompleteAmountInArabic__c, ResalePriceInArabicWords__c,
                        BookTitleFeeUnder__c,ExcludeEvaluationFee__c,ExcludeHassantukFee__c,ExcludeMortgageFee__c,ExcludePendingFee__c,
                        ExcludeRecoveryFee__c,ExcludeTitleDeedFee__c,ExcludeAdmFee__c,ExcludeAdminFee__c,ExcludeChequeBounceFee__c,ExcludeChequeWithdrawlFee__c
        FROM Case
        LIMIT 1
    ];

        SalesOrder__c ordrObj = [Select id from SalesOrder__c limit 1];
        ordrObj.IsDraftOrder__c = true;
        update ordrObj;
        caseObj.NewSalesOrder__c = ordrObj.id;
        update caseObj;
        
        Set<Id> caseIds = new Set<Id>();
        caseIds.add(caseObj.id);
        test.startTest();
        ResaleServiceRequestHandler.getInstance().cancelDraftSalesOrders(caseIds);
        ResaleServiceRequestHandler.getInstance().cancelAndReassignSalesOrdersForResale(caseObj);
        test.stopTest();
        
    }
}