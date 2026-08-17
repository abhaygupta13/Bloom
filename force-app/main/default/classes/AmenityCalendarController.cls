//============================ AmenityCalendarController =============================
/*
* @Author : Eagles  
* @CreatedDate : 06 Aug 2025    
* @Name : AmenityCalendarController
* @Description : This APEX Class handles amenityCalendar lwc component
*/
/*****************************************************************************************************
* Version       Author                  Date             Comment                                                                       
* 1.0           Eagles               06 Aug 2025        Initial draft 
*****************************************************************************************************/

public class AmenityCalendarController {
    
	
    public class AmenityCommunityWrapper {
        @AuraEnabled public List<Project__c> communities;
        @AuraEnabled public List<Amenities__c > amenities;
    }
    @AuraEnabled(cacheable=true)
    public static List<Amenities__c> getAmenitiesByProject(Id projectId) {
        AmenityService aService = AmenityService.getInstance();
        return aService.fetchAmenityByProjectId(projectId, null);
    }
    @AuraEnabled(cacheable=true)
    public static AmenityCommunityWrapper getCommunitiesAndAmenities() {
        AmenityService aService = AmenityService.getInstance();
        ProjectService pService = ProjectService.getInstance();
        AmenityCommunityWrapper wrapper = new AmenityCommunityWrapper();
        wrapper.communities = pService.fetchProjects(false);
        wrapper.amenities = aService.fetchAmenityByProjectId(null, null);
        return wrapper;
    }
    
      /**
     * description   this is being called from amneityBookingModal lwc component
     * param         amenityId, selectedDate
     * return        the available slots
   */
    @AuraEnabled
    public static String getSlotsForDateUnapidSF(String jsonString){
         Map<String, Object> reqMap = (Map<String, Object>) JSON.deserializeUntyped(jsonString);
		 return BCAPP_AmenityBookingService.getSlotsForDate(reqMap,true);	
    }
    
    @AuraEnabled
    public static String bookUnpaidAmenitySlot(String jsonString){
         Map<String, Object> reqMap = (Map<String, Object>) JSON.deserializeUntyped(jsonString);
		 return BCAPP_AmenityBookingService.bookAmenitySlot(reqMap,true);	
    }
    
 
    
    @AuraEnabled(cacheable=true)
    public static String getBookingSlots(String startDate, String endDate,String projectId, String amenityId) {
        Date startDt = Date.valueOf(startDate);
        Date endDt = Date.valueOf(endDate);
        CaseService cService = CaseService.getInstance();
        List<Case> bookings = cService.fetchBookedAmenityByDateRange(startDt,endDt,projectId,amenityId);
        
        Map<String, Map<String, Case>> bookedSlotsMap = new Map<String, Map<String, Case>>();
        
        for (Case c : bookings) {
            String dateKey = String.valueOf(c.Permit_From_Date__c);
            system.debug('dateKey--'+dateKey);
            if (!bookedSlotsMap.containsKey(dateKey)) {
                bookedSlotsMap.put(dateKey, new Map<String, Case>());
            }
            bookedSlotsMap.get(dateKey).put(Utility.formatTime(c.startTime__c), c);
        }
        List<Map<String, Object>> results = new List<Map<String, Object>>();
        
        Time startTime = Time.newInstance(8, 0, 0, 0);
        Time endTime = Time.newInstance(20, 0, 0, 0);
        system.debug('endDt--'+endDt);
        system.debug('startDt--'+startDt);
        for (Date d = startDt; d <= endDt; d = d.addDays(1)) {
            for (Integer hr = 8; hr < 24; hr++) {
                String slotStart = Utility.formatTime(Time.newInstance(hr, 0, 0, 0));
                Time slotEnd = Time.newInstance(hr + 1, 0, 0, 0);
                String dateKey = String.valueOf(d);
                String status = 'Available';
                String caseNumber = '';
                if (bookedSlotsMap.containsKey(dateKey)) {
                    if (bookedSlotsMap.get(dateKey).containsKey(slotStart)) {
                        status = bookedSlotsMap.get(dateKey).get(slotStart).status;
                        caseNumber = bookedSlotsMap.get(dateKey).get(slotStart).caseNumber;
                         system.debug('casenumber--'+bookedSlotsMap.get(dateKey).get(slotStart));
                        system.debug('casenumber--'+caseNumber);
                    }
                }
                
                Map<String, Object> slotMap = new Map<String, Object>{
                    'date' => dateKey,
                        'startTime' => slotStart,
                        'endTime' => Utility.formatTime(slotEnd),
                        'status' => status,
                        'bookingNumber' => caseNumber
                        };
               results.add(slotMap);
            }
        }
        
        return JSON.serialize(results);
    }
 
}