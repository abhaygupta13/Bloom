global class HandoverSLABatch implements Database.Batchable<SObject>{
    private static final String STATUS_IN_PROGRESS = 'In Progress';
    private static Set<String> TERMINAL_STATUSES;
    private static final String STATUS_FIELD = 'Sub_Status__c';
    
    static {
        TERMINAL_STATUSES = new Set<String>();
        List<AppSetting__mdt> appSettings = [SELECT SLA_Terminal_Status__c FROM AppSetting__mdt LIMIT 50];
        for (AppSetting__mdt setting : appSettings) {
            if (setting.SLA_Terminal_Status__c != null) {
                TERMINAL_STATUSES.addAll(setting.SLA_Terminal_Status__c.split(';'));
                break;
            }
        }
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            [SELECT Id, Sub_Status__c, CreatedDate
             FROM Handover__c
             WHERE Sub_Status__c NOT IN :TERMINAL_STATUSES]
        );
    } 
    
    global void execute(Database.BatchableContext bc, List<Handover__c> handoverList) {
        System.debug('handoverList'+handoverList);
        Set<Id> handoverIds = new Set<Id>();
        for (Handover__c handover : handoverList) {
            handoverIds.add(handover.Id);
        }
        
        Map<Id, Handover_SLA__c> latestSLAMap = new Map<Id, Handover_SLA__c>();
        for (Handover__c ho : [SELECT Id, (SELECT Id, Last_Updated_Date__c, Days_Spent__c, Hours_Spent__c, Days_Spent_Business__c, Hours_Spent_Business__c, Status__c FROM Handover_SLAs__r ORDER BY Last_Updated_Date__c DESC LIMIT 1) FROM Handover__c WHERE Id IN :handoverIds]) {
            if (!ho.Handover_SLAs__r.isEmpty()) {
                latestSLAMap.put(ho.Id, ho.Handover_SLAs__r[0]);
                System.debug('latestSLAMap'+latestSLAMap);
            }
        }
        
        Map<Id, Handover__History> latestHistoryMap = new Map<Id, Handover__History>();
        for (Handover__History history : [SELECT ParentId, CreatedDate, Field 
                                          FROM Handover__History 
                                          WHERE ParentId IN :handoverIds 
                                          ORDER BY CreatedDate DESC]) {
                                              if (!latestHistoryMap.containsKey(history.ParentId)) {
                                                  latestHistoryMap.put(history.ParentId, history);
                                              }
                                          }
        Map<String, Decimal> goalCheckerMap = new Map<String, Decimal>();
        List<Goal_Checker__mdt> goalMetadataRecords = [SELECT MasterLabel, Goal__c FROM Goal_Checker__mdt];
        for (Goal_Checker__mdt goal : goalMetadataRecords) {
            goalCheckerMap.put(goal.MasterLabel, goal.Goal__c);
        }

        List<Handover_SLA__c> slaRecordsToUpdate = new List<Handover_SLA__c>();
        List<Handover_SLA__c> slaRecordsToInsert = new List<Handover_SLA__c>();
        
        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1];
        DateTime now = DateTime.now();
        
        for (Handover__c handover : handoverList) {
            Handover_SLA__c latestSLA = (latestSLAMap != null) ? latestSLAMap.get(handover.Id) : null; //latestSLAMap.get(handover.Id);
            
            if (latestSLA != null) {
                processSLAUpdate(latestSLA, bh, now, slaRecordsToUpdate);
            }else {
                Handover__History latestHistory = (latestHistoryMap != null) ? latestHistoryMap.get(handover.Id) : null;
                createNewSLA(handover, latestHistory, bh, now, slaRecordsToInsert, goalCheckerMap);
            }
        }
        
        if (!slaRecordsToUpdate.isEmpty()) {
            system.debug('slaRecordsToUpdate'+slaRecordsToUpdate.size());
            system.debug('slaRecordsToUpdate'+slaRecordsToUpdate);
            update slaRecordsToUpdate;
            //Database.update(slaRecordsToUpdate, false);
        }
        
        if (!slaRecordsToInsert.isEmpty()) {
            insert slaRecordsToInsert;
            //Database.insert(slaRecordsToInsert, false);
        }  
    }
    
    private void processSLAUpdate(Handover_SLA__c latestSLA, BusinessHours bh, DateTime now, List<Handover_SLA__c> slaRecordsToUpdate) {
        Integer totalDays = latestSLA.Last_Updated_Date__c.date().daysBetween(now.date());
        Long businessMilliseconds = BusinessHours.diff(bh.Id, latestSLA.Last_Updated_Date__c, now);
        Double businessHours = (Double) businessMilliseconds / (1000 * 60 * 60);
        Double totalHours = (Double)(now.getTime() - latestSLA.Last_Updated_Date__c.getTime()) / (1000 * 60 * 60);
        Long businessDays = businessMilliseconds / (1000 * 60 * 60 * 24);
        
        latestSLA.Days_Spent__c += totalDays;
        latestSLA.Hours_Spent__c += totalHours;
        latestSLA.Days_Spent_Business__c += businessDays;
        latestSLA.Hours_Spent_Business__c += businessHours;
        latestSLA.Last_Updated_Date__c = now;
        latestSLA.Status__c = STATUS_IN_PROGRESS;
        
        slaRecordsToUpdate.add(latestSLA);
    }
    
    private void createNewSLA(Handover__c handover, Handover__History latestHistory, BusinessHours bh, DateTime now, List<Handover_SLA__c> slaRecordsToInsert, Map<String, Decimal> goalCheckerMap) {
        DateTime referenceDate = (latestHistory != null && latestHistory.Field == STATUS_FIELD) ? latestHistory.CreatedDate : handover.CreatedDate;
        
        Integer totalDays = referenceDate.date().daysBetween(now.date());
        Long businessMilliseconds = BusinessHours.diff(bh.Id, referenceDate, now);
        Double businessHours = (Double) businessMilliseconds / (1000 * 60 * 60);
        Long businessDays = businessMilliseconds / (1000 * 60 * 60 * 24);
        Double totalHours = (Double)(now.getTime() - referenceDate.getTime()) / (1000 * 60 * 60);
        
        Handover_SLA__c newSLA = new Handover_SLA__c(
            Name = handover.Sub_Status__c,
            Status_API_Name__c = STATUS_FIELD,
            Handover__c = handover.Id,
            Days_Spent__c = totalDays,
            Hours_Spent__c = totalHours,
            Days_Spent_Business__c = businessDays,
            Hours_Spent_Business__c = businessHours,
            Last_Updated_Date__c = now,
            Status__c = STATUS_IN_PROGRESS
        );
        if (goalCheckerMap.containsKey(newSLA.Name)){
            newSLA.Goal_Days__c = goalCheckerMap.get(newSLA.Name);
        }

        slaRecordsToInsert.add(newSLA);
    }
    
    global void finish(Database.BatchableContext bc) {
        
    }
    
}