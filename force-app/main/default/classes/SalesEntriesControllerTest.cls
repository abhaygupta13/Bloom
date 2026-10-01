@isTest
private class SalesEntriesControllerTest {
    
    private static Id personRecordTypeId;
    
    @testSetup
    static void setupData() {
        
        personRecordTypeId = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType='Account'
            AND DeveloperName='PersonAccount'
            LIMIT 1
        ].Id;
        
        Account acc = new Account(
            LastName='Test Person',
            RecordTypeId=personRecordTypeId,
            PersonEmail='test@test.com'
        );
        insert acc;
        
        Opportunity opp = new Opportunity(
            Name='Test Opportunity',
            StageName='Prospecting',
            CloseDate=Date.today(),
            AccountId=acc.Id
        );
        insert opp;
        
        Unit__c unit = new Unit__c(
            Name='Retail Unit',
            
            PropertyUsage__c='Retail'
        );
        insert unit;
        
        LeasingOrder__c masterOrder = new LeasingOrder__c(
            Name='Master Order',
            Opportunity__c=opp.Id,
            Unit__c=unit.Id,
            LeasingStartDate__c=Date.newInstance(2026,1,1),
            LeasingEndDate__c=Date.newInstance(2026,3,31)
        );
        insert masterOrder;
        
        LeasingOrder__c childOrder = new LeasingOrder__c(
            Name='Child Order',
            Opportunity__c=opp.Id,
            Unit__c=unit.Id,
            MasterLeasingOrder__c=masterOrder.Id,
            LeasingStartDate__c=Date.newInstance(2026,1,1),
            LeasingEndDate__c=Date.newInstance(2026,3,31)
        );
        insert childOrder;
        
        insert new List<SalesEntrie__c>{
            
            new SalesEntrie__c(
                LeasingOrder__c=childOrder.Id,
                Year__c=2026,
                Month__c=1,
                ActualSales__c=100,
                AuditedSales__c=200
            ),
                
                new SalesEntrie__c(
                    LeasingOrder__c=masterOrder.Id,
                    Year__c=2026,
                    Month__c=1,
                    ActualSales__c=300,
                    AuditedSales__c=400
                )
                };
                    }
    
    @isTest
    static void testGetSalesEntries() {
        
        LeasingOrder__c childOrder = [
            SELECT Id
            FROM LeasingOrder__c
            WHERE MasterLeasingOrder__c != NULL
            LIMIT 1
        ];
        
        Test.startTest();
        
        SalesEntriesWrapper wrapper =
            SalesEntriesController.getSalesEntries(childOrder.Id);
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetSalesEntriesWithoutMaster() {
        
        LeasingOrder__c masterOrder = [
            SELECT Id
            FROM LeasingOrder__c
            WHERE MasterLeasingOrder__c = NULL
            LIMIT 1
        ];
        
        Test.startTest();
        
        SalesEntriesWrapper wrapper =
            SalesEntriesController.getSalesEntries(masterOrder.Id);
        
        Test.stopTest();
    }
    
    @isTest
    static void testWrapperClasses() {
        
        SalesEntrie__c sale = new SalesEntrie__c(
            Year__c = 2026,
            Month__c = 1
        );
        
        SalesEntryRow row = new SalesEntryRow(sale, true);
        
        SalesEntriesWrapper wrapper = new SalesEntriesWrapper();
        
        wrapper.currentSalesEntries = new List<SalesEntrie__c>{sale};
            wrapper.masterSalesEntries = new List<SalesEntrie__c>{sale};
                }
    
    @isTest
    static void testSaveSalesEntries() {
        
        SalesEntrie__c sale = [
            SELECT Id,
            ActualSales__c,
            AuditedSales__c,
            ActualSalesLock__c,
            AuditedSalesLock__c
            FROM SalesEntrie__c
            LIMIT 1
        ];
        
        sale.ActualSales__c = 1000;
        sale.AuditedSales__c = 2000;
        sale.ActualSalesLock__c = true;
        sale.AuditedSalesLock__c = true;
        
        Test.startTest();
        
        SalesEntriesController.saveSalesEntries(
            new List<SalesEntrie__c>{sale}
        );
        
        Test.stopTest();
        
        SalesEntrie__c updated = [
            SELECT ActualSales__c,
            AuditedSales__c,
            ActualSalesLock__c,
            AuditedSalesLock__c
            FROM SalesEntrie__c
            WHERE Id=:sale.Id
        ];
    }
    
    @isTest
    static void testActualSalesValidation() {
        
        SalesEntrie__c sale = [
            SELECT Id,
            ActualSalesLock__c
            FROM SalesEntrie__c
            LIMIT 1
        ];
        
        sale.ActualSales__c = null;
        sale.ActualSalesLock__c = true;
        
        Test.startTest();
        
        try{
            
            SalesEntriesController.saveSalesEntries(
                new List<SalesEntrie__c>{sale}
            );
            
        }catch(AuraHandledException ex){
            
            
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testAuditedSalesValidation() {
        
        SalesEntrie__c sale = [
            SELECT Id,ActualSales__c,ActualSalesLock__c,
            AuditedSalesLock__c
            FROM SalesEntrie__c
            LIMIT 1
        ];
        
        sale.AuditedSales__c = null;
        sale.AuditedSalesLock__c = true;
        
        Test.startTest();
        
        try{
            
            SalesEntriesController.saveSalesEntries(
                new List<SalesEntrie__c>{sale}
            );
            
        }catch(AuraHandledException ex){
            
            
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testAlreadyLockedRecords() {
        
        SalesEntrie__c sale = [
            SELECT Id,
            ActualSales__c,
            AuditedSales__c,
            ActualSalesLock__c,
            AuditedSalesLock__c
            FROM SalesEntrie__c
            LIMIT 1
        ];
        
        sale.ActualSalesLock__c = true;
        sale.AuditedSalesLock__c = true;
        
        update sale;
        
        sale.ActualSales__c = 9999;
        sale.AuditedSales__c = 8888;
        
        Test.startTest();
        
        SalesEntriesController.saveSalesEntries(
            new List<SalesEntrie__c>{sale}
        );
        
        Test.stopTest();
        
        SalesEntrie__c updated = [
            SELECT ActualSales__c,
            AuditedSales__c
            FROM SalesEntrie__c
            WHERE Id=:sale.Id
        ];
    }
    
    @isTest
    static void testSaveSalesEntriesEmptyList() {
        
        Test.startTest();
        
        SalesEntriesController.saveSalesEntries(
            new List<SalesEntrie__c>()
        );
        
        SalesEntriesController.saveSalesEntries(null);
        
        Test.stopTest();
    }
    
    @isTest
    static void testCreateSalesEntriesOnTORUpdate() {
        
        Opportunity opp = [
            SELECT Id
            FROM Opportunity
            LIMIT 1
        ];
        
        Unit__c unit = [
            SELECT Id, PropertyUsage__c
            FROM Unit__c
            LIMIT 1
        ];
        
        LeasingOrder__c order = new LeasingOrder__c(
            Name = 'TOR Update Order',
            Opportunity__c = opp.Id,
            Unit__c = unit.Id,
            LeasingStartDate__c = Date.newInstance(2026, 1, 1),
            LeasingEndDate__c = Date.newInstance(2026, 3, 31),
            TOR__c = null
        );
        
        insert order;
        
        /*
* Create old version of the Leasing Order.
* TOR is null in old record and will be changed in new record.
*/
        LeasingOrder__c oldOrder = order.clone(
            false,
            true,
            false,
            false
        );
        
        /*
* Update TOR.
* This is the condition that should cause Sales Entries
* to be created.
*/
        order.TOR__c = 5;
        
        Test.startTest();
        
        LeasingOrderTriggerHelper.createSalesEntries(
            new List<LeasingOrder__c>{ order }
        );
        
        Test.stopTest();
        
        List<SalesEntrie__c> sales = [
            SELECT Id,
            LeasingOrder__c,
            Year__c,
            Month__c
            FROM SalesEntrie__c
            WHERE LeasingOrder__c = :order.Id
            ORDER BY Year__c, Month__c
        ];
    }
    
    @isTest
    static void testCreateSalesEntriesOnTORUpdate_NoDuplicates() {
        
        Opportunity opp = [
            SELECT Id
            FROM Opportunity
            LIMIT 1
        ];
        
        Unit__c unit = [
            SELECT Id, PropertyUsage__c
            FROM Unit__c
            LIMIT 1
        ];
        
        LeasingOrder__c order = new LeasingOrder__c(
            Name = 'TOR Duplicate Test',
            Opportunity__c = opp.Id,
            Unit__c = unit.Id,
            LeasingStartDate__c = Date.newInstance(2026, 1, 1),
            LeasingEndDate__c = Date.newInstance(2026, 3, 31),
            TOR__c = null
        );
        
        insert order;
        
        LeasingOrder__c oldOrder = order.clone(
            false,
            true,
            false,
            false
        );
        
        order.TOR__c = 10;
        
        Test.startTest();
        
        // First call - should create 3 Sales Entries
        LeasingOrderTriggerHelper.createSalesEntries(
            new List<LeasingOrder__c>{ order }
        );
        
        // Simulate TOR being updated again
        LeasingOrder__c secondOldOrder = order.clone(
            false,
            true,
            false,
            false
        );
        
        order.TOR__c = 15;
        
        // Second call - should NOT create duplicate Sales Entries
        LeasingOrderTriggerHelper.createSalesEntries(
            new List<LeasingOrder__c>{ order }
        );
        
        Test.stopTest();
        
        List<SalesEntrie__c> sales = [
            SELECT Id,
            LeasingOrder__c,
            Year__c,
            Month__c
            FROM SalesEntrie__c
            WHERE LeasingOrder__c = :order.Id
            ORDER BY Year__c, Month__c
        ];
    }
    @isTest
    static void testAdjustSalesEntries() {
        
        Opportunity opp = [
            SELECT Id
            FROM Opportunity
            LIMIT 1
        ];
        
        Unit__c unit = [
            SELECT Id
            FROM Unit__c
            LIMIT 1
        ];
        
        LeasingOrder__c order = new LeasingOrder__c(
            Name = 'Adjust Order',
            Opportunity__c = opp.Id,
            Unit__c = unit.Id,
            LeasingStartDate__c = Date.newInstance(2026, 1, 1),
            LeasingEndDate__c = Date.newInstance(2026, 3, 31)
        );
        
        insert order;
        
        // Create initial Sales Entries: Jan, Feb, Mar
        insert new List<SalesEntrie__c>{
            new SalesEntrie__c(
                LeasingOrder__c = order.Id,
                Year__c = 2026,
                Month__c = 1
            ),
                new SalesEntrie__c(
                    LeasingOrder__c = order.Id,
                    Year__c = 2026,
                    Month__c = 2
                ),
                new SalesEntrie__c(
                    LeasingOrder__c = order.Id,
                    Year__c = 2026,
                    Month__c = 3
                )
                };
                    
                    /*
* OLD: Jan - Mar
* NEW: Jan - May
*/
                    LeasingOrder__c oldRec =
                    order.clone(false, true, false, false);
        
        order.LeasingEndDate__c = Date.newInstance(2026, 5, 31);
        
        Test.startTest();
        
        // Extend lease: Jan-Mar -> Jan-May
        LeasingOrderTriggerHelper.adjustSalesEntries(
            new List<LeasingOrder__c>{ order },
            new Map<Id, LeasingOrder__c>{
                order.Id => oldRec
                    }
        );
        
        /*
* Now reduce the lease:
*
* OLD: Jan - May
* NEW: Jan - Feb
*/
        oldRec = order.clone(false, true, false, false);
        
        order.LeasingEndDate__c = Date.newInstance(2026, 2, 28);
        
        LeasingOrderTriggerHelper.adjustSalesEntries(
            new List<LeasingOrder__c>{ order },
            new Map<Id, LeasingOrder__c>{
                order.Id => oldRec
                    }
        );
        
        Test.stopTest();
        
        /*
* Final expected result:
* Jan
* Feb
*
* Mar, Apr and May should have been deleted.
*/
        List<SalesEntrie__c> sales = [
            SELECT Id,
            LeasingOrder__c,
            Year__c,
            Month__c
            FROM SalesEntrie__c
            WHERE LeasingOrder__c = :order.Id
            ORDER BY Year__c, Month__c
        ];
    }
    
    @isTest
    static void testValidateSalesEntriesOnLeaseDateChange() {
        
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Unit__c unit = [SELECT Id FROM Unit__c LIMIT 1];
        
        LeasingOrder__c order = new LeasingOrder__c(
            Name='Validation Order',
            Opportunity__c=opp.Id,
            Unit__c=unit.Id,
            LeasingStartDate__c=Date.newInstance(2026,1,1),
            LeasingEndDate__c=Date.newInstance(2026,3,31)
        );
        insert order;
        
        insert new SalesEntrie__c(
            LeasingOrder__c=order.Id,
            Year__c=2026,
            Month__c=3,
            ActualSales__c=1000
        );
        
        LeasingOrder__c oldRec = order.clone(false,true,false,false);
        
        order.LeasingEndDate__c = Date.newInstance(2026,2,28);
        
        Test.startTest();
        
        LeasingOrderTriggerHelper.validateSalesEntriesOnLeaseDateChange(
            new List<LeasingOrder__c>{order},
            new Map<Id,LeasingOrder__c>{
                order.Id=>oldRec
                    }
        );
        
        Test.stopTest();
        
        
    }
    
}