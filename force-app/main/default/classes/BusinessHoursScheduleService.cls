/*****************************************************************************************
Class       : BusinessHoursSchedule
Author      : Prashant Sahu
Description : BusinessHours service class
Created Date: 26 MAR 2025
*****************************************************************************************/
public inherited sharing class BusinessHoursScheduleService {
    private static BusinessHoursScheduleService instance;
    private static final Long DEFAULT_BUSINESS_DAY_MS = 9 * 60 * 60 * 1000L; // 9 hours in ms
    
    private BusinessHoursScheduleService() {   
    }
    
    public static BusinessHoursScheduleService getInstance() { 
        if(instance == null) {
            instance = new BusinessHoursScheduleService();
        }
        return instance;
    }
    public List<BusinessHoursSchedule__c> getBusinessHoursScheduleByUserIdStartDTs( Set<Id> userIds, DateTime startDT) {
        if(userIds == null || userIds.isEmpty()) {
            return new List<BusinessHoursSchedule__c>();
        }
        
        return [
            SELECT Id,
            Name,
            User__c,
            StartDateTime__c,
            EndDateTime__c,
            User__r.BusinessHour__c
            FROM BusinessHoursSchedule__c
            WHERE User__c IN :userIds
            AND StartDateTime__c >= :startDT
            AND StartDateTime__c != NULL
            AND User__r.BusinessHour__c != NULL
            ORDER BY User__c ASC,
            StartDateTime__c ASC
        ];
    }
    
    public List<BusinessHoursSchedule__c> getBusinessHoursScheduleByUserIdStartDTEndDTs( Set<Id> userIds, DateTime startDT,  DateTime endDT) {
        if(userIds == null || userIds.isEmpty()) {
            return new List<BusinessHoursSchedule__c>();
        }
        
        return [
            SELECT Id,
            Name,
            User__c,
            StartDateTime__c,
            EndDateTime__c,
            User__r.BusinessHour__c
            FROM BusinessHoursSchedule__c
            WHERE User__c IN :userIds
            AND StartDateTime__c >= :startDT
            AND StartDateTime__c <= :endDT
            AND StartDateTime__c != NULL
            AND EndDateTime__c != NULL
            AND User__r.BusinessHour__c != NULL
            ORDER BY User__c ASC,
            StartDateTime__c ASC
        ];
    }
}