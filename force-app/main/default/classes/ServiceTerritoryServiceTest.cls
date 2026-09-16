@isTest
public class ServiceTerritoryServiceTest {
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
        List<ServiceTerritory> resultByProjectIds = ServiceTerritoryService.getInstance().getServiceTerritorysByProjectIds(emptyIds);
        Test.stopTest();
    }
    
}