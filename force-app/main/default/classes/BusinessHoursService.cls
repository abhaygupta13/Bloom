/*****************************************************************************************
Class       : BusinessHoursService
Author      : Dhanraj Poojary
Description : BusinessHours service class
Created Date: 26 MAR 2025
*****************************************************************************************/
public class BusinessHoursService {
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
    public List<BusinessHours> getBusinessHoursByIds(Set<id> businessHourIds) {
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
    
}