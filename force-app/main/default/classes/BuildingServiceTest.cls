@IsTest
public class BuildingServiceTest {
  @IsTest
    static void testgetBuildings() {
        Project__c testProject =BCAPP_TestDataFactory.createProject();
        testProject.isEnabledMIP__c=true;
        insert testProject;
        
        Building__c building = TestDataFactory.createBuilding('Building 1', testProject.Id);
        insert building;
        
        BuildingService instac = BuildingService.getInstance();
        instac.getBuildingsForLeasing(testProject.id);
    }
}