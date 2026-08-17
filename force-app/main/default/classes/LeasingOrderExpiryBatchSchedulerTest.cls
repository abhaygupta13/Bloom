@isTest
private class LeasingOrderExpiryBatchSchedulerTest {
    @isTest
    static void testBatchAndScheduler() {
        
       
        
        LeasingOrder__c order = createBasicOrder(false);
        Test.startTest();
        LeasingOrderExpiryBatchScheduler job = new LeasingOrderExpiryBatchScheduler();
        Database.executeBatch(job, 1);
        Test.stopTest();
        
    }
     // Utility to get Account RecordType Id by developer name
    private static Id getAccountRecordTypeId(String developerName) {
        return [SELECT Id FROM RecordType 
                WHERE SObjectType = 'Account' AND DeveloperName = :developerName 
                LIMIT 1].Id;
    }
    private static LeasingOrder__c createBasicOrder(Boolean isPerson) {
        Id recordTypeId = isPerson 
            ? getAccountRecordTypeId('PersonAccount')     // Adjust this to your org's Person Account record type
            : getAccountRecordTypeId('OrganizationAccount'); // Adjust this to your org's Business Account record type
        
        Account acc;
        if (isPerson) {
            acc = new Account(RecordTypeId = recordTypeId, LastName = 'Test Person', PersonEmail = 'areddy.spa@bloomholding.com', PersonMobilePhone = '00971111111111');
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
            Unit__c = objUnit.Id,
            Status__c = 'Leasing Offer',
            OfferValidityDays__c = 0.0 
        );
        insert order;
        
 // Set CreatedDate to 7 days ago
        Test.setCreatedDate(order.Id, DateTime.now().addDays(-7));

        
        return order;
    }
    
    @isTest static void testGetLeasingDetailsAmend() {
        LeasingOrder__c order = createBasicOrder(false);
        LeasingOrderService svc = LeasingOrderService.getInstance();
        LeasingOrder__c result = svc.getLeasingOrderById(order.Id);
        System.assertEquals(order.Id, result.Id);
    }
}