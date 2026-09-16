/*****************************************************************************************
Class       : AssignmentRuleService
Author      : Biswajeet
Description : Assignment Rule Service
test Class  : AssignmentRuleServiceTest
Created Date: 29 AUG 2024
*****************************************************************************************/
public inherited sharing class AssignmentRuleService {
    
    private static AssignmentRuleService instance;
    
    private AssignmentRuleService() {
        
    }
    
    public static AssignmentRuleService getInstance() { 
        if(instance == null) {
            instance = new AssignmentRuleService();
        }
        return instance;
    }
    
    public AssignmentRule__c getAssignmentRuleAndUsers(String recordType, String processName){
        return [SELECT Id, Name, DefaultQueueID__c, RecordType__c, ProcessName__c, Project__c,
                (SELECT Id, AssignmentDays__c, MaximumCapacity__c, BusinessHours__c,
                 BusinessHours__r.name,BusinessHours__r.IsActive,
                 User__c FROM AssignmentUsers__r WHERE IsActive__c = true
                 AND User__r.IsActive = true AND User__c != NULL), PropertyType__c, DefaultUser__c
                FROM AssignmentRule__c WHERE IsActive__c = true
                AND ProcessName__c = :processName AND RecordType__c = :recordType];
    }
    
    public List<AssignmentRule__c> getAssignmentRulesAndUsers(String recordType, String processType){
        return [SELECT Id, Name, DefaultQueueID__c, RecordType__c, ProcessName__c, Project__c, PropertyType__c,ProcessType__c,DefaultUser__c,
                (SELECT Id, AssignmentDays__c, MaximumCapacity__c, BusinessHours__c,BusinessHours__r.name,
                 BusinessHours__r.IsActive,
                 User__c FROM AssignmentUsers__r WHERE IsActive__c = true
                 AND User__r.IsActive = true AND User__c != NULL)
                FROM AssignmentRule__c WHERE IsActive__c = true
                AND RecordType__c = :recordType AND ProcessType__c = :processType];
    }
    
    public Map<String,AssignmentRule__c> getAssignmentRuleAndUsersByProject(String recordType, String processName, String processType, Set<String> projectNames){
        Map<String,AssignmentRule__c> projectNameToAssignmentRuleMap = new Map<String,AssignmentRule__c>();
        for(AssignmentRule__c assignmentRuleRec : [SELECT Id, Name, DefaultQueueID__c, RecordType__c, ProcessName__c,DefaultUser__c, Project__c,ProcessType__c,
                (SELECT Id,BusinessHours__c,BusinessHours__r.name,BusinessHours__r.IsActive,User__r.Name,
                 User__c FROM AssignmentUsers__r WHERE IsActive__c = true
                 AND User__r.IsActive = true AND User__c != NULL), PropertyType__c
                FROM AssignmentRule__c WHERE IsActive__c = true AND ProcessName__c = :processName 
                AND RecordType__c = :recordType AND ProcessType__c = :processType AND (Project__c IN :projectNames OR Project__c = NULL)]){
                    projectNameToAssignmentRuleMap.put(assignmentRuleRec.Project__c, assignmentRuleRec);
                }

        return projectNameToAssignmentRuleMap;
    }

    public List<AssignmentRule__c> getAssignmentRuleAndUsersByProcessName(String recordType, String processName, String processType){
        return [SELECT Id, Name, DefaultQueueID__c, RecordType__c, ProcessName__c,DefaultUser__c, Project__c,ProcessType__c,
                (SELECT Id,BusinessHours__c,BusinessHours__r.name,BusinessHours__r.IsActive,User__r.Name,
                 User__c FROM AssignmentUsers__r WHERE IsActive__c = true
                 AND User__r.IsActive = true AND User__c != NULL), PropertyType__c
                FROM AssignmentRule__c WHERE IsActive__c = true AND ProcessName__c = :processName 
                AND RecordType__c = :recordType AND ProcessType__c = :processType];
    }

    public AssignmentRule__c getAssignmentRuleAndUsers(String recordType, String processName, String processType){
        return [SELECT Id, Name, DefaultQueueID__c, RecordType__c, ProcessName__c,DefaultUser__c, Project__c,ProcessType__c,
                (SELECT Id,BusinessHours__c,BusinessHours__r.name,BusinessHours__r.IsActive,User__r.Name,
                 User__c FROM AssignmentUsers__r WHERE IsActive__c = true
                 AND User__r.IsActive = true AND User__c != NULL), PropertyType__c
                FROM AssignmentRule__c WHERE IsActive__c = true
                AND ProcessName__c = :processName AND RecordType__c = :recordType And ProcessType__c = :processType];
    }

     public List<AssignmentRule__c> getAssignmentRules(String recordType, String processName, String processType){
        return [SELECT Id, Name, DefaultQueueID__c, RecordType__c, ProcessName__c,DefaultUser__c, Project__c,ProcessType__c,
                (SELECT Id,BusinessHours__c,BusinessHours__r.name,BusinessHours__r.IsActive,User__r.Name,
                 User__c FROM AssignmentUsers__r WHERE IsActive__c = true
                 AND User__r.IsActive = true AND User__c != NULL)
                FROM AssignmentRule__c WHERE IsActive__c = true
                AND ProcessName__c = :processName AND RecordType__c = :recordType And ProcessType__c = :processType];
    }
    
    public List<AssignmentUser__c> getAvailableAssignmentUsers(List<AssignmentUser__c> assignmentUserList){
        List<AssignmentUser__c> availableAssignmentUserList = new List<AssignmentUser__c>(); 
        DateTime currentDateTime = System.now();
        for(AssignmentUser__c objAssignmentUser :assignmentUserList){
            if(objAssignmentUser.BusinessHours__r.IsActive && BusinessHours.isWithin(objAssignmentUser.BusinessHours__c, currentDateTime)){
                availableAssignmentUserList.add(objAssignmentUser); 
            }
        }
        return availableAssignmentUserList;
    }
    
    public Map<Id, AssignmentUser__c> getAvailableAssignmentUserMap(List<AssignmentUser__c> assignmentUserList){
        Map<Id, AssignmentUser__c> availableAssignmentUserMap = new  Map<Id, AssignmentUser__c>(); 
        DateTime currentDateTime = System.now();
        for(AssignmentUser__c objAssignmentUser :assignmentUserList){
            if(objAssignmentUser.BusinessHours__r.IsActive && BusinessHours.isWithin(objAssignmentUser.BusinessHours__c, currentDateTime)){
                availableAssignmentUserMap.put(objAssignmentUser.User__c, objAssignmentUser); 
            }
        }
        return availableAssignmentUserMap;
    }
    
    public List<sObject> assignRecordOwner(List<sObject> sObjectList, AssignmentRule__c assignmentRule, List<AssignmentUser__c> assignmentUserList){
        if(!sObjectList.isEmpty()){
            Integer assignmentAgentIndex = 0;
            Integer roundRobinNumber = 0;
            if(assignmentRule != NULL){
                for(sObject obj :sObjectList){
                    roundRobinNumber = obj.get('RoundRobinNumber__c') != NULL ? Integer.valueOf(obj.get('RoundRobinNumber__c')) : 0;
                    if(assignmentUserList != NULL && !assignmentUserList.isEmpty()){
                        assignmentAgentIndex = Math.MOD(roundRobinNumber, assignmentUserList.size());
                        obj.put('OwnerId', assignmentUserList[assignmentAgentIndex].User__c);
                        /*if(obj.getSObjectType() == Case.SObjectType){obj.put('Status', 'In Progress');}*/
                    }else if(String.isNotBlank(assignmentRule.DefaultQueueID__c)){
                        obj.put('OwnerId', assignmentRule.DefaultQueueID__c);
                    }else if(String.isNotBlank(assignmentRule.DefaultUser__c)){
                        obj.put('OwnerId', assignmentRule.DefaultUser__c);
                        /*if(obj.getSObjectType() == Case.SObjectType){obj.put('Status', 'In Progress');}*/
                    }
                }
            }
        }
        return sObjectList;
    }
    
    public List<Handover__c> assignCRMTeamUserToHandover(List<Handover__c> sObjectList, AssignmentRule__c assignmentRule, List<AssignmentUser__c> assignmentUserList) {
        if (sObjectList == null || sObjectList.isEmpty() || assignmentRule == null) {
            return sObjectList;
        }
        
		Integer roundRobinIndex = 0;
        Boolean hasUsers = (assignmentUserList != null && !assignmentUserList.isEmpty());
        for (Handover__c obj : sObjectList) {
            if (hasUsers) {
                Integer targetIndex = Math.mod(roundRobinIndex, assignmentUserList.size());
                obj.CRM_Team_Assigned_User__c = assignmentUserList[targetIndex].User__c;
                roundRobinIndex++;
            } else if (String.isNotBlank(assignmentRule.DefaultQueueID__c)) {
                obj.CRM_Team_Assigned_User__c = assignmentRule.DefaultQueueID__c;
            } else if (String.isNotBlank(assignmentRule.DefaultUser__c)) {
                obj.CRM_Team_Assigned_User__c = assignmentRule.DefaultUser__c;
            }
        }
    
        return sObjectList;
    }
}