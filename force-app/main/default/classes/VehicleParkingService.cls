/*****************************************************************************************
Class       : VehicleParkingService
Author      : Aman Bharti
Description : VehicleParkingService
Test Class  : VehicleParkingServiceTest
Created Date: 07 MAY 2025 
*****************************************************************************************/
public inherited sharing class VehicleParkingService {
    private static VehicleParkingService instance;
    
    private VehicleParkingService() {
        
    }
    
    public static VehicleParkingService getInstance() { 
        if(instance == null) {
            instance = new VehicleParkingService();
        }
        return instance;
    }

    public void insertVehicleParkingRecord(List<VehicleParking__c> vehiclesList) {
        if(vehiclesList != NULL && !vehiclesList.isEmpty()){
            insert vehiclesList;
        }
    }

    public void updateVehicleParkingRecord(List<VehicleParking__c> vehiclesList) {
        if(vehiclesList != NULL && !vehiclesList.isEmpty()){
            update vehiclesList;
        }
    }

    public void createVehicleParkingDetailRecord(List<VehicleParkingDetails__c> vehiclesDetailList) {
        if(vehiclesDetailList != NULL && !vehiclesDetailList.isEmpty()){
            insert vehiclesDetailList;
        }
    }

    public List<VehicleParking__c> getVehicleParkingByUnitIds(Set<Id> unitIds, String status){
        return [SELECT Id,Status__c,EndDate__c FROM VehicleParking__c WHERE Unit__c IN :unitIds AND Status__c = :status];
    }
}