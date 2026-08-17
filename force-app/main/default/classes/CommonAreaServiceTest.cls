/*****************************************************************************************
Class       : CommonAreaServiceTest
Author      : Aman Bharti
Description : CommonAreaService Test
Test Class  : 
Created Date: 17 JUN 2026 
*****************************************************************************************/
@isTest
public class CommonAreaServiceTest {
    @testSetup
    private static void testData() {

        Project__c project = TestDataFactory.createProject('Project Test', Date.newinstance(2024, 01, 01), Date.newInstance(2025, 01, 01), Date.newInstance(2025, 01, 15), Date.newInstance(2025, 01, 16), Date.newInstance(2025, 01, 30), Date.newInstance(2025, 02, 01));
        insert project;

        Building__c  building = TestDataFactory.createBuilding('test building', project.Id);
        insert building;

        Community__c community = new Community__c();
        community.Name = 'Test Community';
        insert community;

        CommonArea__c commonArea = TestDataFactory.createCommonArea('BC-GF-RREC','Real Estate Group', building.Id, project.Id, community.Id);
        insert commonArea;

    }



    @isTest
    private static void testGetCommonAreaByIds(){
        List<CommonArea__c> commonAreaList = [SELECT Id,Name FROM CommonArea__c];
        Test.StartTest();
            List<CommonArea__c> commonAreasList = CommonAreaService.getInstance().getCommonAreaByIds(new Set<Id>{commonAreaList[0].Id});
        Test.StopTest();
        Assert.areEqual(1,commonAreasList.size(),'Their should be 1 records');
    }
}