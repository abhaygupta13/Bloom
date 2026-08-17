@isTest
public class UnitAllocationServiceTest {
    
@TestSetup
static void testData(){

    Account acc = TestDataFactory.createPersonalAccount('lname',null, '1234567890', 'test1221@gmail.com');
    insert acc;

    Project__c project = TestDataFactory.createProject('test project');
    insert project;

    Unit__c unit = TestDataFactory.createUnit(project.Id, 'Test unit', 'Sold');
    insert unit;

    Unit_Allocation__c unitAllo = TestDataFactory.createUnitAllocation(true,acc.Id,Unit.Id);
    insert unitAllo;
}

@isTest
    static void testfetchUnitAllocationDetails() {
        Test.startTest(); 
        UnitAllocationService instance=new UnitAllocationService();
        instance.fetchUnitAllocationDetails('','');
        Test.stopTest();
        
    }
    
    @isTest
    static void testfetchUnitAllocationDetailsbyUnit() {
        Test.startTest();
        UnitAllocationService instance=new UnitAllocationService();
        instance.fetchUnitAllocationDetailsbyUnit(null,null);
        Test.stopTest();
        
    }
    
    
    @isTest
    static void testfetchAllUnitsRelatedToAccount() {
        Test.startTest();
        UnitAllocationService instance=new UnitAllocationService();
        instance.fetchAllUnitsRelatedToAccount('');
        Test.stopTest();
    }
    
    @isTest
    static void testcreateUnitAllocation() {
        Test.startTest();
        UnitAllocationService instance=new UnitAllocationService();
        try{
        instance.createUnitAllocation(new Unit_Allocation__c());
        }catch(exception e){
            
        }
        Test.stopTest();
    }

    @isTest
    static void testUpdateUnitAllocation() {
        Test.startTest();
        UnitAllocationService instance=new UnitAllocationService();
        try{
        instance.updateUnitAllocation(new Unit_Allocation__c());
        }catch(exception e){
            
        }
        Test.stopTest();
    }

    @isTest
    static void testFetchUnitAllocationByUnitIds() {
        Test.startTest();
            Unit__c unit = [SELECT Id FROM Unit__c LIMIT 1];
        	Account acc = [SELECT Id FROM Account LIMIT 1];
            UnitAllocationService instance=new UnitAllocationService();
            instance.fetchUnitAllocationByUnitIds(new Set<Id>{unit.Id});
        	UnitAllocationService.getInstance().fetchUnitAllocationByUnitId(unit.id);
        	UnitAllocationService.getInstance().getActiveAllocation(unit.Id,acc.Id,Date.today());
        	UnitAllocationService.getInstance().hasActiveResidents(unit.id,Date.today());
        	UnitAllocationService.getInstance().hasActiveAllocationFlag(unit.Id,acc.id);
        Test.stopTest();
    }
    @isTest
    static void testFetchUnitAllocationByAccIds() {
        Test.startTest();
            Account acc = [SELECT Id FROM Account LIMIT 1];
            UnitAllocationService instance=new UnitAllocationService();
            instance.fetchUnitAllocationByAccIds(new Set<String>{'Owner','Tenant'},new Set<Id>{acc.Id}, true, true);
        Test.stopTest();
    }
}