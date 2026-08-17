public without sharing class AssignBackServiceRequestController {
    @AuraEnabled(cacheable=true)
    public static List<String> getAssignBackReasons() {
        List<String> picklistValues = new List<String>();
        
        Schema.DescribeFieldResult fieldResult = Case.Assign_Back_Reason__c.getDescribe();
        List<Schema.PicklistEntry> values = fieldResult.getPicklistValues();
        
        for (Schema.PicklistEntry entry : values) {
            picklistValues.add(entry.getLabel());
        }
        
        return picklistValues;
    }
    
    @AuraEnabled
    public static void handleAssignBack(Id caseId, String commentBody,String reason,Id userId,String team) {
        Case caseRec = CaseService.getInstance().getCaseById(caseId);
        Id complaintRT = Utility.getRecordTypeIdByDevName(Case.SObjectType,'ComplaintRequest');
        if(caseRec.RecordTypeId == complaintRT){
            if (caseRec.SubStatus__c == 'Completed') {
                ActivityService activityService = ActivityService.getInstance();
                List<Task> tasksToClose = activityService.fetchOpenTaskForCase(caseRec);
                activityService.closeTasks(tasksToClose);
                ServiceRequestTaskHandler.getInstance().createNewAndCloseCurrentTask(new List<Case>{caseRec}); 
                List<Task> tasksOpened = activityService.fetchOpenTaskForCase(caseRec);
                for(Task tsk:tasksOpened){
                    tsk.OwnerId = userId;
                }
                activityService.updateTasks(tasksOpened);
                Case caseToUpdate = new Case(
                    Id = caseRec.Id,
                    OwnerId=userId);
                CaseService.getInstance().updateCases(new List<Case>{caseToUpdate});
            }
            else{
                createComplaintTask(caseRec, team, userId, commentBody);
            }
        }
        else{
            ServiceRequestTaskHandler objTaskHandler = ServiceRequestTaskHandler.getInstance();
            if (objTaskHandler.isSameDepartment(caseId, team)) {
                objTaskHandler.reassignCurrentTask(caseId, commentBody, reason, userId);
            } else {
                objTaskHandler.openOldAndCloseCurrentTask(caseId, commentBody, reason, userId);
            }
        }
        
    }
    @AuraEnabled(cacheable=true)
    public static Map<String, List<Map<String, String>>> getTeamUsers(Id caseId) {
        
        Map<String, List<Map<String, String>>> result = new Map<String, List<Map<String, String>>>();
        
        List<Case> caseList = CaseService.getInstance().getCaseByIds(new Set<Id>{caseId});
        if (caseList.isEmpty()) {
            return result;
        }
        
        ServiceCatalogService service = ServiceCatalogService.getInstance();
        
        Map<Id, ServiceAction__c> prevMap = service.getPreviousCaseServiceAction(caseList);
        Map<Id, ServiceAction__c> currMap = service.getCurrentCaseServiceAction(caseList);
        
        Set<String> requiredDepts = new Set<String>();
        
        Case caseRec = caseList[0];
        
        Id complaintRT = Utility.getRecordTypeIdByDevName(
            Case.SObjectType,
            'ComplaintRequest'
        );
        
        if (caseRec.RecordTypeId == complaintRT) {
            
            Map<String, String> departmentMap =
                Utility.getPicklistValues(ServiceAction__c.SObjectType,'Department__c');
            
            requiredDepts.addAll(departmentMap.keySet());
            
        } else {
            
            if (!prevMap.isEmpty()) {
                requiredDepts.add(prevMap.values()[0].Department__c);
            }
            
            if (!currMap.isEmpty()) {
                requiredDepts.add(currMap.values()[0].Department__c);
            }
        }
        
        if (requiredDepts.isEmpty()) {
            return result;
        }
        
        // Initialize result map
        for (String dept : requiredDepts) {
            result.put(dept, new List<Map<String, String>>());
        }
        
        // Fetch active users whose Department matches
        for (User u : [
            SELECT Id, Name, Department
            FROM User
            WHERE IsActive = true
            AND Department IN :requiredDepts
            ORDER BY Department, Name
        ]) {
            
            result.get(u.Department).add(new Map<String, String>{
                'label' => u.Name,
                    'value' => u.Id
                    });
        }
        
        
        return result;
    }
    private static void createComplaintTask(Case caseRec,String team,Id userId,String comments){
        //  ServiceAction__c selectedAction = ServiceCatalogService.getInstance().getServiceActionByCatalogAndDepartment(caseRec.ServiceCatalog__c,team);
        
        ActivityService activityService = ActivityService.getInstance();
        
        List<Task> prevTask = activityService.fetchOpenTaskForCase(caseRec);
        
        activityService.closeTasks(prevTask);
        
        //Task task = activityService.createTaskFromServiceAction(selectedAction);
        Task task = new Task(); 
        task.Subject = team + ' Team Task 1';
        task.Type__c = caseRec.SubType__c;
        
        task.WhatId = caseRec.Id;
        task.Type = 'Other';
        task.Department__c = team;
        task.OwnerId = userId;  
        //  task.ActivityDate = System.today().addDays(Integer.valueOf(selectedAction.Due_in_days__c));
        
        activityService.insertTasks(new List<Task>{task});
        CRMComplaintRequestHandler.getInstance().sendComplaintAssignmentEmails(new List<Task>{task});
        Case caseToUpdate = new Case(
            Id = caseRec.Id,
            Status='In Progress',
            SubStatus__c=null,
            PendingWith__c=team,
            OwnerId=userId,
            Comments=comments,
            Step__c = '2'
        );
        
        CaseService.getInstance().updateCases(new List<Case>{caseToUpdate});
    }
}