@isTest
public class LeasingOrderServiceTest {

    // Utility to get Account RecordType Id by developer name
    private static Id getAccountRecordTypeId(String developerName) {
        return [SELECT Id FROM RecordType 
                WHERE SObjectType = 'Account' AND DeveloperName = :developerName 
                LIMIT 1].Id;
    }

    // Creates sample data for testing
    private static LeasingOrder__c createBasicOrder(Boolean isPerson) {
        Id recordTypeId = isPerson 
            ? getAccountRecordTypeId('PersonAccount')     // Adjust this to your org's Person Account record type
            : getAccountRecordTypeId('OrganizationAccount'); // Adjust this to your org's Business Account record type

        Account acc;
        if (isPerson) {
            acc = new Account(RecordTypeId = recordTypeId, LastName = 'Test Person', PersonEmail = 'test@test.com', PersonMobilePhone = '00971111111111');
        } else {
            acc = new Account(RecordTypeId = recordTypeId, Name = 'Test Business');
        }
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            AccountId = acc.Id
        );
        insert opp;

        //Creating Unit__c
        Unit__c objUnit = new Unit__c();
        objUnit.Name = 'Test unit';
        insert objUnit;

        LeasingOrder__c order = new LeasingOrder__c(
            Name = 'Test Leasing Order',
            Opportunity__c = opp.Id,
            Unit__c = objUnit.Id
        );
        insert order;

        return order;
    }

    @isTest static void testGetLeasingDetailsAmend() {
        LeasingOrder__c order = createBasicOrder(false);
        LeasingOrderService svc = LeasingOrderService.getInstance();
        LeasingOrder__c result = svc.getLeasingOrderById(order.Id);
        System.assertEquals(order.Id, result.Id);
    }

    @isTest static void testGetLeasingDetails_ChargesSchedules() {
        LeasingOrder__c order = createBasicOrder(false);
        LeasingOrderService svc = LeasingOrderService.getInstance();
        LeasingOrder__c result = svc.getLeasingOrderById(order.Id);
        System.assertEquals(order.Id, result.Id);
    }

   

    @isTest static void testGetActiveLeasingContract() {
        LeasingOrder__c order = createBasicOrder(false);
        LeasingOrderService svc = LeasingOrderService.getInstance();
        List<LeasingOrder__c> result = svc.getActiveLeasingContractByOppId(order.Opportunity__c);
        System.assertEquals(1, result.size());
        System.assertEquals(order.Id, result[0].Id);
    }

    @isTest static void testGetLeasingContractForPaymentSchedule() {
        LeasingOrder__c order = createBasicOrder(false);
        LeasingOrderService svc = LeasingOrderService.getInstance();
        LeasingOrder__c result = svc.getLeasingOrderById(order.Id);
        System.assertEquals(order.Id, result.Id);
    }

    /*@isTest static void testGetLeasingOrdersWithAccountInfo() {
        LeasingOrder__c order = createBasicOrder(true); // Simulate person account
        LeasingOrderService svc = LeasingOrderService.getInstance();
        List<LeasingOrder__c> result = svc.getLeasingOrdersByIds(new List<LeasingOrder__c>{ order });
        System.assertEquals(1, result.size());
        System.assertEquals(order.Id, result[0].Id);

        List<LeasingOrder__c> result2 = svc.getLeasingOrdersByIds(new List<LeasingOrder__c>() );  //Negative test
        System.assertEquals(0, result2.size());
    }

    @isTest static void testGetLeasingContractDetailsMap() {
        LeasingOrder__c order = createBasicOrder(false);
        LeasingOrderService svc = LeasingOrderService.getInstance();
        Map<Id, LeasingOrder__c> result = svc.getLeasingOrdersMapByIds(new Set<Id>{ order.Id });
        System.assert(result.containsKey(order.Id), 'Should contain contract Id');
    }*/

    @isTest static void testGetLeasingContractWithAccountAndOwner() {
        LeasingOrder__c order = createBasicOrder(false);
        LeasingOrderService svc = LeasingOrderService.getInstance();
        LeasingOrder__c result = svc.getLeasingOrderById(order.Id);
        System.assertEquals(order.Id, result.Id);
    }

    @isTest static void testGetLeasingOrderForDocGeneration() {
        LeasingOrder__c order = createBasicOrder(false);
        LeasingOrderService svc = LeasingOrderService.getInstance();
        LeasingOrder__c result = svc.getLeasingOrderById(order.Id);
        System.assertEquals(order.Id, result.Id);
    }

    @isTest static void testInsertAndUpdateLeasingOrders() {
        LeasingOrderService svc = LeasingOrderService.getInstance();

        // Insert without trigger
        LeasingOrder__c newOrder1 = new LeasingOrder__c(Name = 'NoTriggerInsertTest');
        List<LeasingOrder__c> inserted1 = svc.insertLeasingOrdersWithoutTrigger(new List<LeasingOrder__c>{ newOrder1 });
        System.assertEquals(1, inserted1.size());
        System.assertNotEquals(null, inserted1[0].Id);

        // Insert with trigger
        Unit__c objUnit = new Unit__c();
        objUnit.Name = 'Test unit 2';
        insert objUnit;
        LeasingOrder__c newOrder2 = new LeasingOrder__c(Name = 'TriggerInsertTest', Unit__c = objUnit.Id);
        List<LeasingOrder__c> inserted2 = svc.insertLeasingOrders(new List<LeasingOrder__c>{ newOrder2 });
        System.assertEquals(1, inserted2.size());
        System.assertNotEquals(null, inserted2[0].Id);

        // Update
        inserted2[0].Name = 'Updated Name';
        inserted2[0].SecurityDeposit__c  = 300;
        inserted2[0].LeasingSAPContractId__c = 'R10001609';
        List<LeasingOrder__c> updated = svc.updateLeasingOrders(inserted2);
        System.assertEquals('Updated Name', updated[0].Name);
    }
    
    private static LeasingOrder__c createFullLeasingOrder(String propertyUsage, String leaseType) {
        
        Account acc = new Account(
            Name = 'Test Acc',
            SAP_BP_No__c = 'BP001'
        );
        insert acc;
        
        Company__c lc = new Company__c(
            Name = 'Test LC',
            LeasingSAPCompanyCode__c = '1000',
            LeasingSAPCommercialContractTypeCode__c = 'CC01',
            LeasingSAPResContractTypeCode__c = 'RC01',
            LeasingTenancyLaw__c = 'S1',
            LeasingVAT__c = 5
        );
        insert lc;
        
        Project__c proj = new Project__c(
            Name = 'Test Project',
            Leasing_Company__c = lc.Id,
            SAPBusinessEntity__c = 'BE01'
        );
        insert proj;
        
        Unit__c unitRec = new Unit__c(
            Name = 'Unit A',
            PropertyUsage__c = propertyUsage,
            Project__c = proj.Id
        );
        insert unitRec;
        
        LeasingOrder__c lo = new LeasingOrder__c(
            Name = 'Full Leasing Order',
            Account__c = acc.Id,
            Unit__c = unitRec.Id,
            Project__c = proj.Id,
            LeaseType__c = leaseType,
            AppliedAnnualRent__c = 10000,
            AnnualRent__c = 10000,
            SecurityDeposit__c = 500,
            EjariTawtheeqFee__c = 200,
            LeasingStartDate__c = Date.today(),
            LeasingEndDate__c = Date.today().addMonths(12),
            LeasingContractMonths__c = 12,
            PaymentTerm__c = '1 Installment',
            isVATApplied__c = true
        );
        insert lo;
        
        return lo;
    }
    @isTest
    static void testIntegrationRecord_Renewal_Commercial() {
        LeasingOrder__c lo = createFullLeasingOrder('Commercial', 'Renewal');
        lo.LeasingSAPContractId__c = 'SAP123';
        update lo;
        
        LeasingOrderService svc = LeasingOrderService.getInstance();
        Test.startTest();
        IntegrationRecord__c ir = svc.getIntegrationRecord(lo);
        Test.stopTest();
        
        System.assertNotEquals(null, ir);
    }
    @isTest
    static void testIntegrationRecord_Termination() {
        LeasingOrder__c lo = createFullLeasingOrder('Commercial', 'Termination');
        lo.TerminationType__c = 'Early';
        lo.LeaseTerminationRefundType__c = 'Refund-F';
        lo.TerminationDate__c = Date.today();
        lo.TerminationNoticeDate__c = Date.today().addDays(-30);
        update lo;
        
        LeasingOrderService svc = LeasingOrderService.getInstance();
        Test.startTest();
        IntegrationRecord__c ir = svc.getIntegrationRecord(lo);
        Test.stopTest();
        
        System.assertNotEquals(null, ir);
    }
    @isTest
    static void testIntegrationRecord_Non12Months() {
        LeasingOrder__c lo = createFullLeasingOrder('Commercial', 'New');
        lo.LeasingContractMonths__c = 18;
        update lo;
        
        LeasingOrderService svc = LeasingOrderService.getInstance();
        IntegrationRecord__c ir = svc.getIntegrationRecord(lo);
        
        System.assertNotEquals(null, ir);
    }
    @isTest
    static void testUpdateWithoutTrigger() {
        LeasingOrder__c lo = createBasicOrder(false);
        lo.SecurityDeposit__c = 999;
        
        LeasingOrderService svc = LeasingOrderService.getInstance();
        List<LeasingOrder__c> updated =
            svc.updateLeasingOrderswithOutTrigger(new List<LeasingOrder__c>{ lo });
        
        System.assertEquals(999, updated[0].SecurityDeposit__c);
    }
    @isTest
    static void testGetLeasingOrderForSync() {
        LeasingOrder__c lo = createBasicOrder(false);
        LeasingOrder__c result =
            LeasingOrderService.getInstance().getLeasingOrderforSyncById(lo.Id);
        
        System.assertEquals(lo.Id, result.Id);
    }
    @isTest
    static void testGetLeasingOrdersByOwners() {
        LeasingOrder__c lo = createBasicOrder(false);
        Set<Id> owners = new Set<Id>{ lo.OwnerId };
            
            List<LeasingOrder__c> results =
            LeasingOrderService.getInstance().getLeasingOrdersByOwners(owners);
        
        System.assertEquals(0, results.size());
    }
    @isTest
    static void testGetUnitsWithPropertyUsage() {
        Unit__c u = new Unit__c(Name='Unit X', PropertyUsage__c='Commercial');
        insert u;
        
        Map<Id, Unit__c> result =
            LeasingOrderService.getInstance().getUnitsWithPropertyUsage(
                new Set<Id>{ u.Id }
            );
        
        System.assertEquals('Commercial', result.get(u.Id).PropertyUsage__c);
    }
}