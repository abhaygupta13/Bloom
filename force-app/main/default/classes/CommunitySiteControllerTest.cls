/*****************************************************************************************
Class       : CommunitySiteControllerTest
Author      : Aman Bharti
Description : CommunitySiteControllerTest
Test Class  : 
Created Date: 13 AUG 2025 
*****************************************************************************************/
@isTest
public class CommunitySiteControllerTest {
    @testSetup
    private static void testData() {

        Account acc = TestDataFactory.createPersonalAccount('lname',null, '1234567890', 'test1221@gmail.com');
        insert acc;

        Project__c project = TestDataFactory.createProject('test project');
        project.EnableVehicleParking__c = true;
        insert project;

        Unit__c unit = TestDataFactory.createUnit(project.Id, 'Test unit', 'Sold');
        insert unit;
        
        VehicleParking__c vp = TestDataFactory.createVehicleParking('Audi', '1122', 'Active', unit.Id, null, Date.today().addDays(-20), Date.today());
        insert vp;

        Unit_Allocation__c ua = TestDataFactory.createUnitAllocation(true, acc.Id, unit.Id);
        ua.User_Type__c = 'Owner';
        insert ua;

        DocumentType__c docforTenant = TestDataFactory.createDocumentType('Case','Tawtheeq /Ejari Document');
        docForTenant.RecordTypeDevName__c = 'VehicleParkingRequest';
        insert docforTenant;
        DocumentType__c docforOwner = TestDataFactory.createDocumentType('Case','Title Deed Document');
        docForTenant.RecordTypeDevName__c = 'VehicleParkingRequest';
        insert docforOwner;
    }


    @isTest
    private static void testGetUnitsForCustomer(){
        Test.StartTest();
            Account acc = [SELECT Id FROM Account LIMIT 1];
            List<Unit_Allocation__c> uaList = CommunitySiteController.getUnitsForCustomer(acc.Id);
        Test.StopTest();
        Assert.areEqual(false, uaList.isEmpty(), 'No record found');
    }
    
    @isTest
    private static void testHasActiveVehicleRequest(){
        Test.StartTest();
            Account acc = [SELECT Id FROM Account LIMIT 1];
        	Unit__c unit = [SELECT Id FROM Unit__c LIMIT 1];
        	Boolean hasActiveRecords = CommunitySiteController.hasActiveVehicleRequest(acc.Id, unit.Id);
        Test.StopTest();
        Assert.areEqual(false, hasActiveRecords, 'No record found');
    }

    @isTest
    private static void testCreateVehicleDetails(){
        Unit__c unit = [SELECT Id FROM Unit__c LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        VehicleParkingDetails__c vpd = TestDataFactory.createVehicleParkingDetails('BMW', '3333', unit.Id, null);
        Map<String, Object> fileMap = new Map<String, Object>();
        fileMap.put('filename', 'test file');
        fileMap.put('base64', EncodingUtil.base64Encode(Blob.valueOf('Test file content')));

        Map<String, Object> allDetails = new Map<String,Object>();
        allDetails.put('files', fileMap);
        allDetails.put('vehicles', new List<VehicleParkingDetails__c>{vpd});
        allDetails.put('isTenant', true);
        allDetails.put('accId', acc.Id);
        
        Test.StartTest();
            CommunitySiteController.createVehicleDetails(JSON.serialize(allDetails));
        Test.StopTest();
        List<Case> caseList = [SELECT Id,AccountId FROM Case];
        List<VehicleParkingDetails__c> vpdList = [SELECT Id FROM VehicleParkingDetails__c];
        Assert.areEqual(1, caseList.size(), 'No record found');
        Assert.areEqual(1, vpdList.size(), 'No record found');
    }

    @isTest
    private static void testInactiveVehicleParkingByUnitIds(){
        Test.StartTest();
            Unit__c unit = [SELECT Id FROM Unit__c LIMIT 1];
            CommunitySiteController.inactiveVehicleParkingByUnitIds(new Set<Id>{unit.Id});
        Test.StopTest();
        List<VehicleParking__c> vpList = [SELECT Id,Status__c FROM VehicleParking__c];
        Assert.areEqual('Inactive', vpList[0].Status__c, 'Status should be Inactive');
    }

    @isTest
    private static void testInvokeApprovedNRejectedEmail(){
        Unit__c unit = [SELECT Id FROM Unit__c LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        VehicleParkingDetails__c vpd = TestDataFactory.createVehicleParkingDetails('BMW', '3333', unit.Id, null);
        Map<String, Object> fileMap = new Map<String, Object>();
        fileMap.put('filename', 'test file');
        fileMap.put('accId', acc.Id);
        fileMap.put('base64', EncodingUtil.base64Encode(Blob.valueOf('Test file content')));

        Map<String, Object> allDetails = new Map<String,Object>();
        allDetails.put('files', fileMap);
        allDetails.put('vehicles', new List<VehicleParkingDetails__c>{vpd});
        allDetails.put('isTenant', true);
        allDetails.put('accId', acc.Id);
        
        Test.StartTest();
            CommunitySiteController.createVehicleDetails(JSON.serialize(allDetails));
        Test.StopTest();        
        Case c = [SELECT Id,AccountId, VehicleRegistrationStatus__c FROM Case LIMIT 1];
        c.VehicleRegistrationStatus__c = 'Approved';
        update c;
        Assert.areEqual(1, Limits.getEmailInvocations(), 'Email should be sent');
    }
    @isTest
    private static void testGetUnitNVehicleParkingsByUnitIds(){
        Test.StartTest();
        	Unit__c unit = [SELECT Id FROM Unit__c LIMIT 1];
        	Unit__c unitRec = CommunitySiteController.getUnitNVehicleParkingsByUnitIds(unit.Id);
        Test.StopTest();
        Assert.areEqual(true, unitRec != null, 'There must be one unit record');
    }
}