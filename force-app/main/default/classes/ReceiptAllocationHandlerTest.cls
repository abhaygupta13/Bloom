@IsTest
public class ReceiptAllocationHandlerTest {
    
    @testSetup
    static void setupData() {
        
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            AccountId = acc.Id,
            CloseDate = Date.today(),
            StageName = 'New',
            ForecastCategoryName = 'Omitted',
            LeadChannel__c = 'Call',
            WinReason__c = 'Won - Special Discount'
        );
        insert opp;
        
        Project__c project = new Project__c(Name = 'Test Project');
        insert project;
        
        BuildingSection__c building = new BuildingSection__c(
            Name = 'Building',
            BuildingSectionCode__c = 'B1',
            Project__c = project.Id
        );
        insert building;
        
        Unit__c unitRec = new Unit__c(
            Name = 'Unit-1',
            Status__c = 'Available',
            UnitType__c = 'Townhouse',
            BuildingSectionName__c = building.Id,
            Project__c = project.Id,
            PropertyUsage__c = 'Residential',
            UnitView__c = 'Sea',
            FloorNumber__c = '01',
            NumberOfBedrooms__c = '3',
            UnitModel__c = '1BHK',
            SellingPrice__c = 700000
        );
        insert unitRec;
        
        SalesOrder__c so = new SalesOrder__c(
            Name = 'SO-001',
            Status__c = 'Booked',
            Unit__c = unitRec.Id,
            Account__c = acc.Id,
            Opportunity__c = opp.Id
        );
        insert so;
        
        PaymentPlan__c plan = new PaymentPlan__c(Name = 'Plan', IsActive__c = 'No', Description__c = 'Test');
        insert plan;
        
        PaymentInstallments__c pi = new PaymentInstallments__c(
            InstallmentNumber__c = 1,
            InstallmentPercentage__c = 100,
            BrokerPayoutPercentage__c = 100,
            Condition_Type__c = 'P012',
            PaymentPlan__c = plan.Id,
            Description__c = 'Test'
        );
        insert pi;
        
        InstallmentLines__c inst = new InstallmentLines__c(
            SalesOrder__c = so.Id,
            PaymentPlan__c = plan.Id,
            PaymentInstallments__c = pi.Id,
            InstallmentAmount__c = 120000,
            Description__c = 'Test'
        );
        insert inst;
        
        SalesOrderOtherCharges__c charge = new SalesOrderOtherCharges__c(
            SalesOrder__c = so.Id,
            Account__c = acc.Id,
            Amount__c = 10000,
            TypeOfCharge__c = Constants.BUDGET_LINE_ADMFEE
        );
        insert charge;
        
        ReceiptAcknowledgement__c receipt = new ReceiptAcknowledgement__c(
            PaymentType__c = 'Online',
            Opportunity__c = opp.Id,
            SalesOrder__c = so.Id,
            Account__c = acc.Id,
            Amount__c = 20000
        );
        insert receipt;
    }
    
    /* ---------------- WITH EXISTING ALLOCATIONS ---------------- */
    
    @IsTest
    static void testFetchReceipt_WithAllocations() {
        Account objAccount = [SELECT Id FROM Account LIMIT 1];
        ReceiptAcknowledgement__c receipt = [SELECT Id FROM ReceiptAcknowledgement__c LIMIT 1];
        InstallmentLines__c inst = [SELECT Id FROM InstallmentLines__c LIMIT 1];
        
        ReceiptAllocation__c ra = new ReceiptAllocation__c(
            ReceiptAcknowledgement__c = receipt.Id,
            InstallmentLine__c = inst.Id,
            AmountApplied__c = 5000,
            Account__c = objAccount.Id
        );
        insert ra;
        
        Test.startTest();
        // Dummy allocation to flip hasUserStartedAllocation = true
        ReceiptAllocation__c dummyRA = new ReceiptAllocation__c(
            ReceiptAcknowledgement__c = receipt.Id,
            AmountApplied__c = 0,
            Account__c = objAccount.Id
        );
        insert dummyRA;
        
        String result = ReceiptAllocationHandler.fetchReceiptAlocationByReceiptId(receipt.Id);
        Test.stopTest();
    }
    
    /* ---------------- VIRTUAL ALLOCATION PATH ---------------- */
    
    @IsTest
    static void testFetchReceipt_VirtualAllocations() {
        ReceiptAcknowledgement__c receipt = [SELECT Id FROM ReceiptAcknowledgement__c WHERE Id NOT IN (SELECT ReceiptAcknowledgement__c FROM ReceiptAllocation__c) LIMIT 1];
        Test.startTest();
        String result = ReceiptAllocationHandler.fetchReceiptAlocationByReceiptId(receipt.Id);
        Test.stopTest();
    }
    
    @IsTest
    static void testUpdateReceiptAllocation_AllBranches() {
        ReceiptAcknowledgement__c receipt = [SELECT Id, Account__c, SalesOrder__c FROM ReceiptAcknowledgement__c LIMIT 1];
        InstallmentLines__c inst = [SELECT Id FROM InstallmentLines__c LIMIT 1];
        SalesOrderOtherCharges__c charge = [SELECT Id FROM SalesOrderOtherCharges__c LIMIT 1];
        
        String payload =
            '[' +
            '{"Id":"","isInstallment":true,"installmentOtherChargeId":"' + inst.Id +
            '","amountApplied":3000,"accountId":"' + receipt.Account__c +
            '","salesOrderId":"' + receipt.SalesOrder__c + '"},' +
            '{"Id":"","isInstallment":false,"chargeType":"Other Charge","installmentOtherChargeId":"' + charge.Id +
            '","amountApplied":2000,"accountId":"' + receipt.Account__c +
            '","salesOrderId":"' + receipt.SalesOrder__c + '"}' +
            ']';
        
        Test.startTest();
        String res = ReceiptAllocationHandler.UpdateReceiptAllocation(payload, receipt.Id);
        Test.stopTest();
    }
    
    @IsTest
    static void testFetchInvoiceForSalesOrder() {
        SalesOrder__c so = [SELECT Id FROM SalesOrder__c LIMIT 1];
        Test.startTest();
        String result = ReceiptAllocationHandler.fetchInvoiceForSalesorder(so.Id);
        Test.stopTest();
    }
    
    @IsTest
    static void testBuildVirtualAllocationsCoverage() {
        Account objAccount = [SELECT Id FROM Account LIMIT 1];
        ReceiptAcknowledgement__c receipt = [SELECT Id, Account__c, SalesOrder__c FROM ReceiptAcknowledgement__c LIMIT 1];
        
        ReceiptAllocation__c dummyRA = new ReceiptAllocation__c(
            ReceiptAcknowledgement__c = receipt.Id,
            AmountApplied__c = 0,
            Account__c = objAccount.Id
        );
        insert dummyRA;
        
        Test.startTest();
        String response = ReceiptAllocationHandler.fetchReceiptAlocationByReceiptId(receipt.Id);
        ReceiptAllocationHandler.buildVirtualAllocations(objAccount.Id,receipt.SalesOrder__c);
        Test.stopTest();
    }
}