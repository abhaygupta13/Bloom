/*****************************************************************************************
    Class       : AppointmentSlotService
    Author      : Rajat Rastogi
    Description : Appointment Slot Service
    Created Date: 07 AUG 2026
*****************************************************************************************/
public inherited sharing class AppointmentSlotService {
    
    private static AppointmentSlotService instance;
    
    private AppointmentSlotService() {
        
    }
    
    public static AppointmentSlotService getInstance() {
        if(instance == null) {
            instance = new AppointmentSlotService();
        }
        return instance;
    }
    
    public List<AppointmentSlot__c> getAppointmentSlotsByIds(Set<Id> appointmentSlotsId){
        return [SELECT Name, StartDateTime__c, EndDateTime__c FROM AppointmentSlot__c WHERE Id IN : appointmentSlotsId];
    }
    
    public List<AppointmentSlot__c> updateAppointmentSlots(List<AppointmentSlot__c> appointmentSlotList){
        if(appointmentSlotList != NULL && !appointmentSlotList.isEmpty()){
            update appointmentSlotList;
        }
        return appointmentSlotList;
    }
    
    public List<AppointmentSlot__c> getAppointmentSlotsByUserAndDate(Id userId, Date selectedDate, String status) {
        return [ SELECT Id, Status__c, StartDateTime__c, EndDateTime__c, Mode__c FROM AppointmentSlot__c WHERE User__c = :userId AND Status__c = :status AND DAY_ONLY(StartDateTime__c) = :selectedDate AND StartDateTime__c > :System.now()];
    }
}