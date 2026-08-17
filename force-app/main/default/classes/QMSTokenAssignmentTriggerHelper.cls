/*****************************************************************************************
Class       : QMSTokenAssignmentTriggerHelper
Author      : Aman Bharti
Description : QMSTokenAssignmentTriggerHelper
Test Class  : 
Created Date: 11 MAY 2026 
*****************************************************************************************/
public without sharing class QMSTokenAssignmentTriggerHelper {

    public static void populateAssignedPerson(List<QMSTokenAssignment__c> newList, Map<Id, QMSTokenAssignment__c> oldMap){
        Set<String> emailSet = new Set<String>();
        Map<String, Id> emailVsUserId = new Map<String, Id>();
        UserService objUserService = UserService.getInstance();

        for(QMSTokenAssignment__c assignmentRecord : newList){
            if(String.isNotBlank(assignmentRecord.AssignedPersonEmail__c) && (oldMap == null || oldMap.get(assignmentRecord.Id).AssignedPersonEmail__c != assignmentRecord.AssignedPersonEmail__c)){
                emailSet.add(assignmentRecord.AssignedPersonEmail__c);
            }
        }

        if(emailSet.isEmpty()){
            return;
        }
        for(User usr : objUserService.getUsersByEmails(emailSet)){
            emailVsUserId.put(usr.Email,usr.Id);
        }

        for(QMSTokenAssignment__c assignmentRecord : newList){
            if(String.isNotBlank(assignmentRecord.AssignedPersonEmail__c)){
                if(emailVsUserId.containsKey(assignmentRecord.AssignedPersonEmail__c)){
                    assignmentRecord.AssignedPerson__c = emailVsUserId.get(assignmentRecord.AssignedPersonEmail__c);
                }
            }
        }
    }
}