@isTest
public class ServiceTerritoryServiceTest {
    
    @isTest
    static void testGetServiceTerritorysByIds() {
        OperatingHours testOperatingHours = new OperatingHours(Name = 'Test Operating Hours');
        insert testOperatingHours;
        
        ServiceTerritory testTerritory = new ServiceTerritory(Name = 'Test Territory',  OperatingHoursId = testOperatingHours.Id);
        insert testTerritory;
        
        Set<Id> territoryIds = new Set<Id>{testTerritory.Id};
            
            Test.startTest();
        List<ServiceTerritory> result = ServiceTerritoryService.getInstance().getServiceTerritorysByIds(territoryIds);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'The method should return a list of ServiceTerritories.');
        System.assertEquals(1, result.size(), 'The result should contain one ServiceTerritory.');
        System.assertEquals(testTerritory.Id, result[0].Id, 'The returned ServiceTerritory ID should match the test data.');
    }
    
    @isTest
    static void testGetServiceTerritorysByProjectIds() {
        OperatingHours testOperatingHours = new OperatingHours(Name = 'Test Operating Hours2');
        insert testOperatingHours; 
        
        Project__c testProject = new Project__c(Name = 'Test Project');
        insert testProject;
        
        ServiceTerritory testTerritory = new ServiceTerritory(
            Name = 'Test Territory',
            OperatingHoursId = testOperatingHours.Id,
            Project__c = testProject.Id
        );
        insert testTerritory;
        
        Set<Id> projectIds = new Set<Id>{testProject.Id};
            
            Test.startTest();
        List<ServiceTerritory> result = ServiceTerritoryService.getInstance().getServiceTerritorysByProjectIds(projectIds);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'The method should return a list of ServiceTerritories.');
        System.assertEquals(1, result.size(), 'The result should contain one ServiceTerritory.');
        System.assertEquals(testProject.Id, result[0].Project__c, 'The Project__c field should match the test Project ID.');
    }
    
    @isTest
    static void testEmptyInputs() {
        Set<Id> emptyIds = new Set<Id>();
        
        Test.startTest();
        List<ServiceTerritory> resultByIds = ServiceTerritoryService.getInstance().getServiceTerritorysByIds(emptyIds);
        System.assertEquals(null, resultByIds, 'The method should return null for an empty ID set.');
        
        List<ServiceTerritory> resultByProjectIds = ServiceTerritoryService.getInstance().getServiceTerritorysByProjectIds(emptyIds);
        Test.stopTest();
        System.assertEquals(null, resultByProjectIds, 'The method should return null for an empty Project ID set.');
    }
    
}