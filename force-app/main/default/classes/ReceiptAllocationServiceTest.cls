@isTest
private class ReceiptAllocationServiceTest {
    @TestSetup
    static void testSetup(){
        Account acc = TestDataFactory.createPersonalAccount('Test class Account', null, '123456789', 'aaa@abc.com');
        insert acc;

        Opportunity opp = TestDataFactory.createOpportunity(acc.id, 'Won - Special Discount', null, null, null, 'New', String.valueOf(system.today()), null);
        insert opp;

        Project__c testProject = TestDataFactory.createProject('Test Project', Date.newinstance(2024, 01, 01), Date.newInstance(2025, 01, 01), Date.newInstance(2025, 01, 15), Date.newInstance(2025, 01, 16), Date.newInstance(2025, 01, 30), Date.newInstance(2025, 02, 01));
        testProject.ProjectNameArabic__c = 'مشروع الاختبار';
        insert testProject;   

        Unit__c testUnit = TestDataFactory.createUnit(testProject.Id, 'test Unit', 'Available');
        insert testUnit;

        SalesOrder__c testOrder = TestDataFactory.createSalesOrder(Acc.Id, Opp.Id, 'Booked', null, testUnit.id, null);
        insert testOrder;

        PaymentPlan__c  pp = TestDataFactory.createPaymentPlan('Test Plan');
        insert pp;
        
        PaymentInstallments__c ppi = TestDataFactory.createPaymentInstallment(pp.id, 1, 100);
        insert ppi;

        InstallmentLines__c ins = TestDataFactory.createInstallmentLines(testOrder.id, 120000, null, null, pp.id, ppi.id);
        insert ins;
        
        SalesOrderOtherCharges__c soc = TestDataFactory.createOtherCharge(testOrder.id, acc.id, 'ADM Fee', false, null, null, null, null, null, 12000);
        insert soc;

        ReceiptAcknowledgement__c testData1 = TestDataFactory.createReceiptAcknowledgement(opp.id, 'Online', 12000, acc.Id, 'Received', null, testOrder.id);
        insert testData1;

        ReceiptAllocation__c rec = TestDataFactory.createReceiptAllocation(testData1.id, acc.id, ins.id, 12000, soc.id);
        insert rec;
    }

    
    @isTest
    static void testGetInstance() {
        // Test Singleton behavior
        ReceiptAllocationService service1 = ReceiptAllocationService.getInstance();
        ReceiptAllocationService service2 = ReceiptAllocationService.getInstance();
        System.assertEquals(service1, service2, 'Instance should be the same (singleton pattern)');
    }

    @isTest
    static void testInsertReceiptAllocations() {
        Account acc = [Select id from Account limit 1];
        ReceiptAcknowledgement__c testData1 = [Select id from ReceiptAcknowledgement__c limit 1];
        List<ReceiptAllocation__c> receiptList = new List<ReceiptAllocation__c>();
        
        ReceiptAllocation__c receipt = new ReceiptAllocation__c(
            Account__c = acc.id,
            InstallmentLine__c = null, // Set valid Id if needed
            ReceiptAcknowledgement__c = testData1.id // Set valid Id if needed
        );
        receiptList.add(receipt);

        Test.startTest();
        List<ReceiptAllocation__c> insertedReceipts = ReceiptAllocationService.getInstance().insertReceiptAllocations(receiptList);
        Test.stopTest();
        
        System.assertEquals(1, insertedReceipts.size(), 'One receipt allocation should have been inserted.');
        System.assertNotEquals(null, insertedReceipts[0].Id, 'Inserted record should have an Id.');
    }

   

    @isTest
    static void testGetReceiptAllocationByInstallment() {

        SalesOrderOtherCharges__c soc = [Select id from SalesOrderOtherCharges__c limit 1];
        
        // Create test data
        Id testInstallmentId = createInstallmentLine(); // helper method below
        ReceiptAcknowledgement__c acknowledgement = [Select id from ReceiptAcknowledgement__c];
        Account acc = [Select id from Account];

        ReceiptAllocation__c receipt = new ReceiptAllocation__c(
          
            InstallmentLine__c = testInstallmentId,
            ReceiptAcknowledgement__c = acknowledgement.Id,
            Account__c = acc.id,
            SalesOrderOtherCharges__c = soc.id,
            AmountApplied__c = 100
        );
        insert receipt;

        Set<Id> installmentIds = new Set<Id>{ testInstallmentId };

        Test.startTest();
        List<ReceiptAllocation__c> results = ReceiptAllocationService.getInstance().getReceiptAllocationByInstallment(installmentIds);
        ReceiptAllocationService.getInstance().getReceiptAllocationBySO(null);
        ReceiptAllocationService.getInstance().getAllReceiptAllocationBySO(null);
        ReceiptAllocationService.getInstance().insertReceiptAllocationsWithoutTrigger(null);
        ReceiptAllocationService.getInstance().deleteReceiptAllocationsWithoutTrigger(null);
        ReceiptAllocationService.getInstance().updateReceiptAllocationsWithoutTrigger(null);
        ReceiptAllocationService.getInstance().createReceiptAllocationObj(1000, null, null ,null, null);
        Test.stopTest();

        System.assert(!results.isEmpty(), 'Should return matching receipt allocation.');
        System.assertEquals(testInstallmentId, results[0].InstallmentLine__c, 'Installment Id should match.');
    }

    // Helper method to create dummy InstallmentLine record
    private static Id createInstallmentLine() {
        // Replace with your actual InstallmentLine__c setup if it is a custom object
        // Here's a mock setup assuming it's a custom object
        SalesOrder__c testOrder = [Select id from SalesOrder__c limit 1];
        PaymentPlan__c  pp = [Select id from PaymentPlan__c limit 1];
        PaymentInstallments__c ppi = [Select id from PaymentInstallments__c limit 1];
        InstallmentLines__c  installment = new InstallmentLines__c ();
        installment.PaymentPlan__c =   pp.id;
        installment.PaymentInstallments__c = ppi.id;
        installment.Description__c = 'test';
        installment.SalesOrder__c = testOrder.id;

        insert installment;
        return installment.Id;
    }
}