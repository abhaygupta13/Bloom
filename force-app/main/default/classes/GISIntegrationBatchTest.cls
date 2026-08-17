/*****************************************************************************************
Class       : GISIntegrationBatchTest
Author      : Biswajeet
Description : Test class for GISIntegrationBatch
Created Date: 24 JUL 2025 
*****************************************************************************************/

@isTest
public class GISIntegrationBatchTest {
    @TestSetup
    static void setupTestData(){
        // Test data for Project__c and related Units
        Account acc = TestDataFactory.createBrokerAccount('test', false, '1122334455');
        insert acc;
        
        Contact con = TestDataFactory.createContact('test', acc.Id, true, 'test@gmail.com');
        insert con;
        
        Opportunity opp = TestDataFactory.createOpportunity(null, null,null, acc.Id, null, null, null, null);
        insert opp;
        
        //Test data for Project__c and related Units
        Project__c project = TestDataFactory.createProject('ProjectTest', Date.today() - 1);
        project.GIS_Service_URL__c = 'https://bloomholding.lightning.force.com/';
        insert project;
        
        Unit__c u = TestDataFactory.createUnit(project.Id, 'A1-G01', 'Unassigned');
        u.Project__c = project.Id;
        u.RegistrationDate__c = Date.today();
        insert u;
        
        SalesOrder__c salesOrder = TestDataFactory.createSalesOrder(acc.Id, opp.Id, 'Booked', date.newinstance(2025, 7, 7), u.Id, 18181818);
        insert salesOrder;
    }
    
    @istest
    public static void testmethod1(){
        
        Unit__c objUnit = [SELECT Id,GIS_Object_Id__c FROM Unit__c LIMIT 1];
        objUnit.GIS_Object_Id__c = 'test1123';
        update objUnit;
        Test.startTest();
        Database.executeBatch(new GISIntegrationBatch(), 1);
        Test.stopTest();
    }
    
    @isTest
    private static void testSchedule() {
        Test.startTest();
        String sch = '0 0 23 * * ?';
        GISIntegrationBatch batchJob = new GISIntegrationBatch();
        System.schedule('GISIntegrationBatch',sch,batchJob);
        Test.stopTest();
    }
}