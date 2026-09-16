/*****************************************************************************************
Class       : AppointmentSlotServiceTest
Author      : Aman Bharti
Description : AppointmentSlotServiceTest
Test Class  : 
Created Date: 01 SEP 2026 
*****************************************************************************************/
@isTest
public class AppointmentSlotServiceTest {
	@testSetup
    private static void testData() {
    	List<AppointmentSlot__c> slots = TestDataFactory.createAppointmentSlots(3, 'Available', UserInfo.getUserId(), Date.today().addDays(1));
    }
    
    @isTest
    static void testGetAppointmentSlotsByIds() {
        List<AppointmentSlot__c> slots = [ SELECT Id, Name, StartDateTime__c, EndDateTime__c FROM AppointmentSlot__c WHERE User__c = :UserInfo.getUserId() ];
        Set<Id> slotIds = new Set<Id>();
        for (AppointmentSlot__c slot : slots) {
            slotIds.add(slot.Id);
        }
        Test.startTest();
        List<AppointmentSlot__c> result = AppointmentSlotService.getInstance().getAppointmentSlotsByIds(slotIds);
        Test.stopTest();
    }


    @isTest
    static void testUpdateAppointmentSlots() {
        List<AppointmentSlot__c> slots = [ SELECT Id, Status__c FROM AppointmentSlot__c WHERE User__c = :UserInfo.getUserId() ];
        for (AppointmentSlot__c slot : slots) {
            slot.Status__c = 'Scheduled';
        }
        Test.startTest();
            List<AppointmentSlot__c> result = AppointmentSlotService.getInstance().updateAppointmentSlots(slots);
        Test.stopTest();
    }


    @isTest
    static void testGetAppointmentSlotsByUserAndDate() {
        Test.startTest();
        List<AppointmentSlot__c> result = AppointmentSlotService.getInstance() .getAppointmentSlotsByUserAndDate( UserInfo.getUserId(), Date.today(), 'Available' );
        Test.stopTest();
    }
    
      
}