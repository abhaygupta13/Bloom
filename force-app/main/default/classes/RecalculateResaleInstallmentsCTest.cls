@isTest
public class RecalculateResaleInstallmentsCTest {

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

        Unit__c unit = TestDataFactory.createUnit(project.Id, 'Test unit', 'Sold');
        unit.BFMUnitNumber__c = 'APT 1';
        unit.UnitType__c = 'Townhouse';
        insert unit;

        SalesOrder__c salesOrder = TestDataFactory.createSalesOrder(acc.Id, opp.Id, 'Sold', date.newinstance(2025, 01, 10), unit.Id, 18181818);
        salesOrder.NetAmount__c = 10000;
        insert salesOrder;

        SalesOrder__c newSalesOrder = TestDataFactory.createSalesOrder(acc.Id, opp.Id, 'Booked', date.newinstance(2025, 01, 10), unit.Id, 18181818);
        newSalesOrder.NetAmount__c = 1000;
        newSalesOrder.PreviousSalesOrder__c = salesOrder.Id;
        insert newSalesOrder;

        PaymentPlan__c  pp = TestDataFactory.createPaymentPlan('Test Plan');
        insert pp;
        
        PaymentInstallments__c ppi = TestDataFactory.createPaymentInstallment(pp.id, 1, 100);
        insert ppi;
        
        InstallmentLines__c ins = TestDataFactory.createInstallmentLines(salesOrder.id, 120000, null, null, pp.id, ppi.id);
        ins.InstallmentDate__c = System.today().addDays(-3);
        ins.InstallmentPercentage__c = 20;
        insert ins;

        SalesOrderOtherCharges__c soc = TestDataFactory.createOtherCharge(salesOrder.id, acc.id, 'ADM Fee', false, null, null, null, null, null, 12000);
        insert soc;

        ReceiptAcknowledgement__c testData1 = TestDataFactory.createReceiptAcknowledgement(opp.id, 'Online', 12000, acc.Id, 'Cleared', null, salesOrder.id);
        ReceiptAcknowledgementService receiptServiceObj = ReceiptAcknowledgementService.getInstance();
        receiptServiceObj.insertReceiptAcknowledgementWithoutTrigger( new List<ReceiptAcknowledgement__c>{ testData1 });

        ReceiptAllocation__c rec = TestDataFactory.createReceiptAllocation(testData1.id, acc.id, ins.id, 12000, soc.id);
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

        Case caseObj = TestDataFactory.createCase('Resale_Property_Under_Construction', 'Email', 'In Progress', 'Test case', null, acc.Id, unit.Id, con.Id);
        caseObj.ServiceCatalog__c = catalog.id;
        caseObj.TypeOfResale__c = 'Resale';
        caseObj.InitialOwnerRemoved__c = 'Yes';
        caseObj.Sales_Order__c = salesOrder.id;
        caseObj.NewSalesOrder__c = newSalesOrder.id;
        insert caseObj;

        RecalculatePaymentsController.performRecalculation(caseObj.Id);
    }

    // ----------------------------------------------------------------------
    // MAIN TEST (your existing method)
    // ----------------------------------------------------------------------
    @isTest
    static void testValidateEligibility() {
        SalesOrder__c newSalesOrder = [
            SELECT Id FROM SalesOrder__c WHERE NetAmount__c = 1000 LIMIT 1
        ];
        Test.startTest();
        RecalculateResaleInstallmentsController.createInstallmentsReceipts(newSalesOrder.Id);  
        Test.stopTest();
    }

    // ----------------------------------------------------------------------
    // 1️⃣ Null SO Id
    // ----------------------------------------------------------------------
    @isTest
    static void testNullSalesOrderId() {
        Test.startTest();
        String result = RecalculateResaleInstallmentsController.createInstallmentsReceipts(null);
        Test.stopTest();
        System.assertEquals('Invalid Sales Order Id', result);
    }

    // ----------------------------------------------------------------------
    // 2️⃣ SO without PreviousSalesOrder__c
    // ----------------------------------------------------------------------
    @isTest
    static void testNoPreviousSalesOrder() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Unit__c unit = [SELECT Id FROM Unit__c LIMIT 1];

        SalesOrder__c so = TestDataFactory.createSalesOrder(
            acc.Id, opp.Id, 'Booked', System.today(), unit.Id, 999
        );
        insert so;

        Test.startTest();
        String result = RecalculateResaleInstallmentsController.createInstallmentsReceipts(so.Id);
        Test.stopTest();

        System.assertEquals('Installments and Receipts created successfully.', result);
    }

    // ----------------------------------------------------------------------
    // 3️⃣ Branch: No handover/posthandover → calculateInstallmentsAndReceipts()
    // ----------------------------------------------------------------------
    /*@isTest
    static void testCalculateInstallmentsAndReceiptsCall() {
        SalesOrder__c newSO = [
            SELECT Id,PreviousSalesOrder__c FROM SalesOrder__c WHERE NetAmount__c = 1000 LIMIT 1
        ];

        delete [SELECT Id FROM InstallmentLines__c WHERE SalesOrder__c = :newSO.PreviousSalesOrder__c];

        Test.startTest();
        String response = RecalculateResaleInstallmentsController.createInstallmentsReceipts(newSO.Id);
        Test.stopTest();

        System.assertEquals('Installments and Receipts created successfully.', response);
    }*/

    // ----------------------------------------------------------------------
    // 4️⃣ Branch: Both handover + posthandover → calculateInstallmentsAndReceiptsForPHPP()
    // ----------------------------------------------------------------------
    @isTest
    static void testCalculateInstallmentsAndReceiptsForPHPP() {

        SalesOrder__c existingSO = [
            SELECT Id FROM SalesOrder__c WHERE Status__c = 'Sold' LIMIT 1
        ];
        SalesOrder__c newSO = [
            SELECT Id, PreviousSalesOrder__c FROM SalesOrder__c WHERE  Status__c = 'Booked' LIMIT 1
        ];

        InstallmentLines__c i1 = new InstallmentLines__c(
            SalesOrder__c = existingSO.Id,
            Type__c = 'Handover',
            InstallmentPercentage__c = 10,
            InstallmentAmount__c = 100,
            Description__c = 'Resale'
        );
        InstallmentLines__c i2 = new InstallmentLines__c(
            SalesOrder__c = existingSO.Id,
            Type__c = 'Post Handover Installment',
            InstallmentPercentage__c = 10,
            InstallmentAmount__c = 100,
            Description__c = 'Resale'
        );
        insert new List<InstallmentLines__c>{ i1, i2 };

        Case c = [SELECT Id,InitialOwnerRemoved__c FROM Case WHERE Sales_Order__c = :existingSO.Id LIMIT 1];
        c.TypeOfResale__c = 'Addition/Deletion';
        c.ProjectStatus__c = 'Under Construction';
        c.InitialOwnerRemoved__c = 'Yes';
        update c;

        Test.startTest();
        String response = RecalculateResaleInstallmentsController.createInstallmentsReceipts(newSO.Id);
        Test.stopTest();

        //System.assertEquals('Installments and Receipts created successfully.', response);
    }
    @isTest
static void testNoCaseFound() {
    SalesOrder__c newSO = [
        SELECT Id FROM SalesOrder__c WHERE NetAmount__c = 1000 LIMIT 1
    ];

    // Delete case to simulate no case
    delete [SELECT Id FROM Case WHERE NewSalesOrder__c = :newSO.Id];

    Test.startTest();
    String result = RecalculateResaleInstallmentsController.createInstallmentsReceipts(newSO.Id);
    Test.stopTest();

    System.assertEquals('Installments and Receipts created successfully.', result);
}

}