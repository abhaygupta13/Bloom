/*****************************************************************************************
Class       : BusinessHoursService
Author      : Dhanraj Poojary
Description : BusinessHours service class
Created Date: 26 MAR 2025
*****************************************************************************************/
public inherited sharing class BusinessHoursService {
    private static BusinessHoursService instance;
    private static final Long DEFAULT_BUSINESS_DAY_MS = 9 * 60 * 60 * 1000L; // 9 hours in ms
    
    private BusinessHoursService() {   
    }
    
    public static BusinessHoursService getInstance() { 
        if(instance == null) {
            instance = new BusinessHoursService();
        }
        return instance;
    }
    
    public Date getNextBusinessDate(Id businessHoursId, Datetime startDateTime) {
        // Find the next business start datetime after now
        Datetime startOfCurrentBusinessDay = BusinessHours.nextStartDate(businessHoursId, startDateTime);
        
        if (startOfCurrentBusinessDay == null) {
            throw new AuraHandledException('Could not find the next business start time.');
        }
        
        // Add one full business day worth of ms
        Datetime nextBusinessDateTime = BusinessHours.add(businessHoursId, startOfCurrentBusinessDay, DEFAULT_BUSINESS_DAY_MS);
        return nextBusinessDateTime.date();
    }
    
    public DateTime getPastBusinessDate(Id businessHoursId, Datetime startDateTime, Integer businessDaysToSubtract) {
        if (businessDaysToSubtract <= 0) return startDateTime;
        
        Long totalMsToSubtract = businessDaysToSubtract * DEFAULT_BUSINESS_DAY_MS;
        
        Long stepMs = 60 * 60 * 1000; // 1 hour
        Integer stepSec = (Integer)(stepMs / 1000);
        
        Datetime calculatedDateTime = startDateTime;
        Long businessMsAccumulated = 0L;
        Integer safety = 0;
        
        while (businessMsAccumulated < totalMsToSubtract && safety < 10000) {
            calculatedDateTime = calculatedDateTime.addSeconds(-stepSec);
            businessMsAccumulated = BusinessHours.diff(businessHoursId, calculatedDateTime, startDateTime);
            safety++;
        }
        
        return calculatedDateTime;
    }
    
    public Boolean hasExceededNoOfHours(Id businessHoursId, Datetime targetDateTime, Integer numberOfHours) {
        if (businessHoursId == null || targetDateTime == null || numberOfHours <= 0)
            return false;
        Boolean withinBusinessHours = BusinessHours.isWithin(businessHoursId, targetDateTime);
        Long elapsedMilliseconds = DateTime.now().getTime() - targetDateTime.getTime();
        Long thresholdMilliseconds = numberOfHours * 60L * 60L * 1000L;
        
        return withinBusinessHours && elapsedMilliseconds >= thresholdMilliseconds;
    }
    
    //* Method        : hasExceededNoOfHour
   // * Author        : Prashant Sahu      14/07/2026
    public Boolean hasExceededNoOfHour(Id businessHoursId, Datetime targetDateTime, Integer numberOfHours) {
        
        if (businessHoursId == null || targetDateTime == null || numberOfHours <= 0) {
            return false;
        }
        
        Long thresholdMilliseconds = numberOfHours * 60L * 60L * 1000L;
        
        Long businessMilliseconds = BusinessHours.diff(businessHoursId, targetDateTime, Datetime.now());
        
        System.debug('Business Hours Id: ' + businessHoursId);
        System.debug('Target DateTime: ' + targetDateTime);
        System.debug('Current DateTime: ' + Datetime.now());
        System.debug('Business Milliseconds: ' + businessMilliseconds);
        System.debug('Threshold Milliseconds: ' + thresholdMilliseconds);
        
        return businessMilliseconds >= thresholdMilliseconds;
    }
    //
    
    /**
* Get the list of specific Business hours from Org
* @param name The name of the BusinessHours configuration applicable.
* @return List of matching businesshours records.
*/
    public List<BusinessHours> getBusinessHoursByName(String developerName) {
        Id businessHoursId = MetadataService.getInstance().getAppSettingTextValue(developerName);
        System.debug('businessHoursId >>'+businessHoursId);
        List<BusinessHours> businessHoursList;
        if(String.isNotBlank(developerName)){
            businessHoursList =  [SELECT Id FROM BusinessHours WHERE Id =: businessHoursId LIMIT 1];
        }
        System.debug('businessHoursList >>'+businessHoursList);
        return businessHoursList;
        
    }
    public Map<Id, Datetime> getEndOfDayByBusinessHoursIds(Set<Id> busHourIds) {
        Map<Id, Datetime> busHoursIdToEndOfDayMap = new Map<Id, Datetime>();
        if(BusHourIds.isEmpty()){
            return busHoursIdToEndOfDayMap;
        }
        // Step 1: Get Business Hours records
        List<BusinessHours> BusHoursList = 
            [SELECT Id,
             MondayEndTime, TuesdayEndTime, WednesdayEndTime,
             ThursdayEndTime, FridayEndTime, SaturdayEndTime, SundayEndTime
             FROM BusinessHours
             WHERE Id IN :busHourIds];
        if(BusHoursList.isEmpty()){
            return busHoursIdToEndOfDayMap;
        }
        
        Integer day = Date.today().toStartOfWeek().daysBetween(Date.today()) + 1;
        for(BusinessHours busHour : BusHoursList){
            Time endTime;
            switch on day {
                when 1 { endTime = busHour.SundayEndTime; }
                when 2 { endTime = busHour.MondayEndTime; }
                when 3 { endTime = busHour.TuesdayEndTime; }
                when 4 { endTime = busHour.WednesdayEndTime; }
                when 5 { endTime = busHour.ThursdayEndTime; }
                when 6 { endTime = busHour.FridayEndTime; }
                when 7 { endTime = busHour.SaturdayEndTime; }
            }
            
            if(endTime != null){
                busHoursIdToEndOfDayMap.put(busHour.Id, Datetime.newInstance(Date.today(), endTime));
            }
        }
        
        return busHoursIdToEndOfDayMap;
    }
    public List<BusinessHours> getBusinessHoursByIds(Set<Id> businessHourIds) {
        if(businessHourIds == null || businessHourIds.isEmpty()) {
            return  new List<BusinessHours>(); 
        }
        return [ SELECT Id, Name, TimeZoneSidKey FROM BusinessHours WHERE Id IN :businessHourIds ];
    }
    
     /** 
 * Calculates elapsed business days between two DateTimes.
 * @param businessHoursId Business Hours Id
 * @param startDateTime Start DateTime
 * @param endDateTime End DateTime
 * @return Business days (9 business hours = 1 day)         
 */
    
    public Integer calculateWorkingDaysSpent(Id businessHoursId, Datetime startDateTime, Datetime endDateTime, Integer workingHoursInDay) {
        
        if (businessHoursId == null || startDateTime == null || endDateTime == null) {
            return 0;
        }
        
        Long businessMilliseconds = BusinessHours.diff(businessHoursId, startDateTime, endDateTime);
        Decimal businessHours = Decimal.valueOf(businessMilliseconds) / (1000 * 60 * 60);
        Decimal businessDays = businessHours / workingHoursInDay;
        
        return Integer.valueOf(businessDays.setScale(0));
    }
    
    /*****************************************************************************************
* Method        : getBusinessReminderTime
* Author        : Prashant Sahu      16/07/2026
* @param businessHoursId       Business Hours Id applicable for the Lead/Task.
* @param slaDateTime           Calculated SLA Breach DateTime.
* @param reminderBeforeHours   Number of working hours before SLA breach when
*                              the reminder should be triggered.
* @return Datetime             Reminder DateTime calculated using Business Hours.
*****************************************************************************************/
    
    public Datetime getBusinessReminderTime(Id businessHoursId,Datetime slaDateTime, Decimal reminderHours) {
        
        if (businessHoursId == null || slaDateTime == null || reminderHours == null) {
            return null;
        }
       // Long reminderMillis = Long.valueOf(String.valueOf(reminderHours)) * 60L * 60L * 1000L;
        Long reminderMillis = (Long)(reminderHours * 60 * 60 * 1000);
        
        return BusinessHours.add(businessHoursId,slaDateTime, reminderMillis);
    }
    
}