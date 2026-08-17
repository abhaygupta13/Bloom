@IsTest
public class BuildingSectionServiceTest {

    @TestSetup
    static void setupData() {
        Project__c project = BCAPP_TestDataFactory.createProject();
        project.isEnabledMIP__c = true;
        insert project;

        BuildingSection__c enabledSection = BCAPP_TestDataFactory.createBuildingSection('Enabled Section');
        enabledSection.Project__c = project.Id;
        enabledSection.isEnabledMIP__c = true;
        insert enabledSection;

        BuildingSection__c disabledSection = BCAPP_TestDataFactory.createBuildingSection('Disabled Section');
        disabledSection.Project__c = project.Id;
        disabledSection.isEnabledMIP__c = false;
        insert disabledSection;
    }

    @IsTest
    static void testBuildingsQueries() {
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];
        BuildingSectionService service = BuildingSectionService.getInstance();

        Test.startTest();
        List<BuildingSection__c> enabledOnly = service.getBuildingsByProject(project.Id);
        List<BuildingSection__c> leasingResults = service.getBuildingsForLeasing(project.Id);
        List<BuildingSection__c> filteredEnabled = service.getBuildingsByProject(project.Id, true);
        List<BuildingSection__c> allBuildings = service.getBuildingsByProject(project.Id, false);
        Test.stopTest();

        System.assertEquals(1, enabledOnly.size(), 'Only enabled sections should be returned.');
        System.assertEquals(2, leasingResults.size(), 'Leasing query should return all sections for the project.');
        System.assertEquals(1, filteredEnabled.size(), 'Boolean filter should enforce enabled flag.');
        System.assertEquals(2, allBuildings.size(), 'Passing false should skip the enabled filter.');
    }
}