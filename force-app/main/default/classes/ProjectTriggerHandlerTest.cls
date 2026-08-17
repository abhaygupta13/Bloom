@isTest
public class ProjectTriggerHandlerTest {
    
    @isTest
    static void Testmethod1(){
        Test.startTest();
        Project__c objProject = TestDataFactory.createProject('Test Project');
        objProject.GIS_Service_URL__c='URL';
        insert objProject;
        objProject.GIS_Service_URL__c='URL1';
        update objProject;
        delete objProject;
        undelete objProject;
    }

}