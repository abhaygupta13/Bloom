/*****************************************************************************************
* @Author        : Prashant Sahu
* @CreatedDate   : 12 May 2026
* @Description   : Batch + Scheduler class to update Contact Center Schedule
*                  Business Hours using BusinessHoursSchedule__c records.
*
*                  Features:
*                  - Reads latest BusinessHoursSchedule__c record
*                  - Converts DateTime into Business Hours time format
*                  - Updates Business Hours using Salesforce REST API
*                  - Supports Manual Execution
*                  - Supports Scheduled Execution every Sunday
*                  - Supports Callouts using Database.AllowsCallouts
*
*****************************************************************************************/

public without sharing  class ContactCenterScheduleBatch implements Database.Batchable<SObject>, Database.AllowsCallouts, Schedulable {
    private static final string CONTACT_CENTER_PROFILE_ID { get { return 'ContactCentreProfileId'; } }
    
    // Default Constructor
    public ContactCenterScheduleBatch() { 
    }
    // START METHOD
    public Database.QueryLocator start(Database.BatchableContext bc) {
        MetadataService objMetadataService = MetadataService.getInstance();
        String contactCentreProfileIds = objMetadataService.getAppSettingTextValue(CONTACT_CENTER_PROFILE_ID);
        return Database.getQueryLocator([
            SELECT Id, Name, BusinessHour__c 
            FROM User 
            WHERE ProfileId =: contactCentreProfileIds AND isActive = True AND BusinessHour__c != null
        ]);
    }
    // EXECUTE METHOD      
    public void execute(Database.BatchableContext bc, List<User> userList ) {
        
        
        BusinessHoursScheduleService objBusiHoursScheduleService =  BusinessHoursScheduleService.getInstance();
        // Initialize all days as NULL
        List<String> allDays = new List<String>{ 'Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'};
            if(userList.isEmpty()) {
                return;
            }
        Map<Id, Map<String, Object>> businessHourPayloadMap = new Map<Id, Map<String, Object>>();
        
        Date TodayDate = Date.today();
        Date endDate = Date.today().addDays(6);
        
        DateTime startDT = DateTime.newInstance(TodayDate, Time.newInstance(0, 0, 0, 0));
        DateTime endDT = DateTime.newInstance(endDate, Time.newInstance(23, 59, 59, 999));
        Set<Id> userIdSet = new Set<Id>();
        for(User usr : userList) {
            userIdSet.add(usr.Id);
        }
        List<BusinessHoursSchedule__c> allUserSchedules = new   List<BusinessHoursSchedule__c>();            
        allUserSchedules = objBusiHoursScheduleService.getBusinessHoursScheduleByUserIdStartDTEndDTs( userIdSet, startDT, endDT ); 
        
        Map<Id, List<BusinessHoursSchedule__c>> userScheduleMap = new Map<Id, List<BusinessHoursSchedule__c>>();
        
        for (BusinessHoursSchedule__c schedule : allUserSchedules) {
            if (!userScheduleMap.containsKey(schedule.User__c)) {
                userScheduleMap.put(schedule.User__c, new List<BusinessHoursSchedule__c>());
            }
            userScheduleMap.get(schedule.User__c).add(schedule);
        }
        
        for(User usr : userList) {
            if(usr.BusinessHour__c == null) {
                continue;
            }
            
            List<BusinessHoursSchedule__c> userSchedules = new   List<BusinessHoursSchedule__c>();
            userSchedules = userScheduleMap.get(usr.Id);
            if(userSchedules != null && userSchedules.size() > 0 ){
                Map<String, Map<String, String>> daysBusinessHourPayloadMap = new Map<String, Map<String, String>>();
                
                for(BusinessHoursSchedule__c sch : userSchedules) {
                    
                    if(sch.StartDateTime__c == null || sch.EndDateTime__c == null) {
                        continue;
                    }
                    if(sch.StartDateTime__c >= sch.EndDateTime__c) {
                        continue;
                    }
                    DateTime startDTInBH = sch.StartDateTime__c;
                    DateTime endDTInBH   = sch.EndDateTime__c;
                    
                    startDTInBH = startDTInBH.addHours(4);
                    endDTInBH = endDTInBH.addHours(4);
                    
                    String dayName = startDTInBH.format('EEEE');
                    String startTimeStr =  startDTInBH.formatGMT('HH:mm:ss.SSS\'Z\'');
                    String endTimeStr =  endDTInBH.formatGMT('HH:mm:ss.SSS\'Z\'');
                    
                    Map<String, String> tempPayload = new Map<String, String>();
                    
                    tempPayload.put(dayName + 'StartTime', startTimeStr);
                    tempPayload.put(dayName + 'EndTime', endTimeStr);
                    daysBusinessHourPayloadMap.put(dayName, tempPayload);
                }
                Map<String, Object> mainPayload = new Map<String, Object>();
                for(String day : allDays) {
                    if(daysBusinessHourPayloadMap.containsKey(day)) {
                        Map<String, String> tempPayload = daysBusinessHourPayloadMap.get(day);
                        if (tempPayload != null) {
                            for (String key : tempPayload.keySet()) {
                                mainPayload.put(key, tempPayload.get(key));
                            }
                        }
                    }
                    else{
                        Map<String, Object> payload = new Map<String, Object>();
                        mainPayload.put(day + 'StartTime', null);
                        mainPayload.put(day + 'EndTime', null);
                    }
                }
                businessHourPayloadMap.put(usr.BusinessHour__c , mainPayload);
            }
            else{
                if(!businessHourPayloadMap.containsKey(usr.BusinessHour__c )) {
                    Map<String, Object> payload = new Map<String, Object>();
                    DateTime nextStDayDate = DateTime.newInstance(TodayDate, Time.newInstance(0, 0, 0, 0));
                    nextStDayDate  = nextStDayDate.addDays(2);
                    Datetime nextEnDayDate = nextStDayDate.addMinutes(1);
                    String nextDayName = nextStDayDate.format('EEEE');
                    for(String day : allDays) {
                        if(day == nextDayName){
                            String nextStartTimeStr =  nextStDayDate.formatGMT('HH:mm:ss.SSS\'Z\'');
                            String nextendTimeStr =  nextEnDayDate.formatGMT('HH:mm:ss.SSS\'Z\'');
                            payload.put(day + 'StartTime', nextStartTimeStr);
                            payload.put(day + 'EndTime', nextendTimeStr);
                            
                        }
                        else{
                            payload.put(day + 'StartTime', null);
                            payload.put(day + 'EndTime', null);
                        }
                    }
                    businessHourPayloadMap.put(usr.BusinessHour__c, payload);
                }
            }
        }  
        for(Id businessHourId : businessHourPayloadMap.keySet()) {
            String body =  JSON.serialize(businessHourPayloadMap.get(businessHourId));
            HttpRequest req = new HttpRequest();
            req.setEndpoint( URL.getOrgDomainUrl().toExternalForm() + '/services/data/v60.0/sobjects/BusinessHours/'+ businessHourId);
            req.setMethod('PATCH');
            req.setHeader('Authorization','Bearer ' + UserInfo.getSessionId());
            req.setHeader('Content-Type', 'application/json');
            req.setBody(body);
            
            Http http = new Http();
            HttpResponse res = http.send(req);
        }
    }
    
    // SCHEDULER METHOD
    public void execute( SchedulableContext sc ) {
        Database.executeBatch( new ContactCenterScheduleBatch(), 1);
    }
    // FINISH METHOD
    public void finish( Database.BatchableContext bc) {
        
    }
    
}