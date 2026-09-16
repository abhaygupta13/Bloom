/*****************************************************************************************
Class       : BusinessHoursServiceTest
Author      : Dhanraj Poojary
Description : Test class for BusinessHoursService
Created Date: 26 MAR 2025
*****************************************************************************************/
@isTest
private class BusinessHoursServiceTest {
    @isTest
    static void testGetNextBusinessDate() {
        // Query an existing Business Hours record
        BusinessHours testBusinessHours = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1];
        
        // Call method under test
        BusinessHoursService service = BusinessHoursService.getInstance();
        Test.startTest();
        Date nextBusinessDate = service.getNextBusinessDate(testBusinessHours.Id,System.now());
        List<BusinessHours> bHours = service.getBusinessHoursByIds(new Set<Id>{testBusinessHours.Id});
        Test.stopTest();
    }
    //Shruti
    @isTest
    static void testPastBusinessDate() {
        // Query an existing Business Hours record
        BusinessHours testBusinessHours = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1];
        // Call method under test
        BusinessHoursService service = BusinessHoursService.getInstance();
        Test.startTest();
        DateTime checkDate = service.getPastBusinessDate(testBusinessHours.Id, System.Now(), 2);
        Test.stopTest();
    }
    //Shruti
    @isTest
    static void testBusinessHoursByName() {
        
        // Call method under test
        BusinessHoursService service = BusinessHoursService.getInstance();
        Test.startTest();
        List<BusinessHours> bHours = service.getBusinessHoursByName('BloomBrokerBusinessHours');
        Test.stopTest();
    }
    //prashant
     @isTest
    static void testCalculateWorkingDaysSpent() {
        
        BusinessHours testBusinessHours = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1];
        BusinessHoursService service = BusinessHoursService.getInstance();
        
        Datetime startDT = Datetime.now();
        Datetime endDT = BusinessHours.add(testBusinessHours.Id, startDT, 9 * 60 * 60 * 1000L);
        
        Test.startTest();
        Integer workingDays = service.calculateWorkingDaysSpent(testBusinessHours.Id, startDT, endDT, 9);
        Integer nullResult = service.calculateWorkingDaysSpent(null, null, null, 9);
        Test.stopTest();
        
        System.assertEquals(1, workingDays);
        System.assertEquals(0, nullResult);
    }
}