/*****************************************************************************************
Class       : VehicleParkingServiceTest
Author      : Aman Bharti
Description : VehicleParkingServiceTest
Test Class  : 
Created Date: 13 AUG 2025 
*****************************************************************************************/
@isTest
public class VehicleParkingServiceTest {
    @testSetup
    private static void testData() {
        Project__c project = TestDataFactory.createProject('test project');
        insert project;

        Unit__c unit = TestDataFactory.createUnit(project.Id, 'Test unit', 'Sold');
        insert unit;
        
        VehicleParking__c vp = TestDataFactory.createVehicleParking('Audi', '1122', 'Active', unit.Id, null, Date.today().addDays(-20), Date.today());
        insert vp;
    }

    @isTest
    private static void insertVehicleParkingRecord(){
        VehicleParking__c vp = TestDataFactory.createVehicleParking('Audi', '1122', 'Active', null, null, Date.today().addDays(-20), Date.today());
        Test.StartTest();
            VehicleParkingService objVehicleParkingService = VehicleParkingService.getInstance();
            objVehicleParkingService.insertVehicleParkingRecord(new List<VehicleParking__c>{vp});
        Test.StopTest();
        List<VehicleParking__c> vpList = [SELECT VehiclePlateNumber__c, Status__c FROM VehicleParking__c];
        Assert.areEqual(2, vpList.size(), 'Vehicle parking records should be inserted.');
    }

    @isTest
    private static void updateVehicleParkingRecord(){
        Test.StartTest();
            VehicleParking__c vp = [SELECT VehiclePlateNumber__c, Status__c FROM VehicleParking__c WHERE VehiclePlateNumber__c = '1122' LIMIT 1];
            vp.Status__c = 'Inactive';
        	VehicleParkingService objVehicleParkingService = VehicleParkingService.getInstance();
            objVehicleParkingService.updateVehicleParkingRecord(new List<VehicleParking__c>{vp});
        Test.StopTest();
        VehicleParking__c updatedVP = [SELECT VehiclePlateNumber__c, Status__c FROM VehicleParking__c WHERE VehiclePlateNumber__c = '1122' LIMIT 1];
        Assert.areEqual('Inactive', updatedVP.Status__c, 'VehicleParking status should be Inactive.');
    }

    @isTest
    private static void createVehicleParkingDetailRecord(){
        Test.StartTest();
            VehicleParkingDetails__c vpd = TestDataFactory.createVehicleParkingDetails('Audi', '1122',null,null);
            VehicleParkingService objVehicleParkingService = VehicleParkingService.getInstance();
            objVehicleParkingService.createVehicleParkingDetailRecord(new List<VehicleParkingDetails__c>{vpd});
        Test.StopTest();
        List<VehicleParkingDetails__c> vpdList = [SELECT Id FROM VehicleParkingDetails__c];
        Assert.areEqual(false, vpdList.isEmpty(), 'Vehicle Parking Details record should be created.');
    }

    @isTest
    private static void getVehicleParkingByUnitIds(){
        Test.StartTest();
            Unit__c unit = [SELECT Id FROM Unit__c LIMIT 1];
            VehicleParkingService objVehicleParkingService = VehicleParkingService.getInstance();
            List<VehicleParking__c> vpList = objVehicleParkingService.getVehicleParkingByUnitIds(new Set<Id>{unit.Id}, 'Active');
        Test.StopTest();
        Assert.areEqual(false, vpList.isEmpty(), 'Vehicle parking list can not be empty.');
    }
}