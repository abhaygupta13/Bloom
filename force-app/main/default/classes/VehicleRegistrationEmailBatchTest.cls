/*****************************************************************************************
Class       : VehicleRegistrationEmailBatchTest
Author      : Aman Bharti
Description : VehicleRegistrationEmailBatchTest
Test Class  : 
Created Date: 26 Aug 2025 
*****************************************************************************************/
@isTest
public class VehicleRegistrationEmailBatchTest {
    @testSetup
    static void testData() {
        Account acc = TestDataFactory.createPersonalAccount('lname',null, '1234567890', 'test1221@gmail.com');
        insert acc;

        Project__c project = TestDataFactory.createProject('test project');
        insert project;

        Unit__c unit = TestDataFactory.createUnit(project.Id, 'Test unit', 'Sold');
        unit.ActiveTenant__c = acc.Id;
        insert unit;

        Unit_Allocation__c ua = TestDataFactory.createUnitAllocation(true, acc.Id, unit.Id);
        ua.User_Type__c = 'Owner';
        insert ua;     
    }

    @IsTest
    private static void testBatchable(){
        Test.startTest();
            VehicleRegistrationEmailBatch batch = new VehicleRegistrationEmailBatch();
            Database.executeBatch(batch);
        Test.stopTest();
    }
        
    @isTest
    private static void testSchedule() {
        Test.startTest();
            String sch = '0 0 23 * * ?';
            VehicleRegistrationEmailBatch batchJob = new VehicleRegistrationEmailBatch();
            System.schedule('VehicleRegistrationEmailBatch',sch,batchJob);
        Test.stopTest();
        List<AsyncApexJob> batchJobs = [SELECT Id, Status FROM AsyncApexJob WHERE ApexClass.Name = 'VehicleRegistrationEmailBatch' AND JobType = 'BatchApex'];        
        Assert.areEqual(1, batchJobs.size(), 'Unexpected number of batch jobs ran: ' + batchJobs);
    }

}