public class AssignToSelfTaskAssignmentController {
    @AuraEnabled
    public static Boolean updateCaseOwner(Id recordId) {
        
        try {
            if(recordId != null && recordId.getSobjectType() == Task.getSobjectType()){
                
                CaseAssignmentHistoryService assignObj = CaseAssignmentHistoryService.getInstance();
                List<CaseAssignmentHistory__c> caseAssignHistoryToLog = new List<CaseAssignmentHistory__c>();
                
                ActivityService serviceObj = ActivityService.getInstance();
                Task taskObj = serviceObj.getTasksById(recordId);
                
                Task tsk = new Task();
                tsk.Id = recordId;
                tsk.OwnerId = UserInfo.getUserId();
                
                if(taskObj.WhatId != null 
                   && taskObj.WhatId.getSobjectType() == Case.getSobjectType()){
                       CaseAssignmentHistory__c historyObj = new CaseAssignmentHistory__c();
                       historyObj.Case__c = taskObj.WhatId;
                       historyObj.AssignedBy__c = UserInfo.getUserId();
                       historyObj.OwnerId = UserInfo.getUserId();
                       historyObj.AssignmentDate__c = system.now();
                       historyObj.Reason__c = 'Assigned from Queue to User';
                       caseAssignHistoryToLog.add(historyObj); 
                   }
                serviceObj.updateTask(tsk);
                if(!caseAssignHistoryToLog.isEmpty()){
                    assignObj.insertCaseAssignmentHistory(caseAssignHistoryToLog);    
                }  
            }
            return true;  
            
        } catch (Exception e) {
            throw new AuraHandledException(
                'Failed to update owner: ' + e.getMessage()
            );
        }
    }
}