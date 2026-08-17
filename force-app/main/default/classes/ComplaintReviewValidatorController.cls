/***
Class       : ComplaintReviewValidatorController
Author      : Samiksha
Description : 
TestClass   : ComplaintReviewValidatorControllerTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.     version              Date                Details
1.          V1.0                       Initial Version 
****************************************************************************************************************/

public without sharing class ComplaintReviewValidatorController {
 
    private static final string COMPLAINT_REQUEST_RT { get { return 'ComplaintRequest'; } }
       
    @AuraEnabled
    public static Map<String, Object> validateForNextReview(Id recordId){
        
        Map<String, Object> response = new Map<String, Object>();
        try {
            if (recordId == null) {
                response.put('status', 'error');
                response.put('message', 'Unable to move to next step: Invalid record Id provided.');
                return response;
            }
            
            if(recordId.getSobjectType() == Case.getSobjectType()){
                
                CaseService serviceObj = CaseService.getInstance();   
                Case caseRecord = serviceObj.getCaseById(recordId);
                
                response  = validateForCaseReview((caseRecord));
              
            } else {
                response.put('status', 'error');
                response.put('message', 'Unable to move to next step: Provided Id is not a Case record.');
            }
        } catch (Exception ex) {
            response.put('status', 'error');
            response.put('message', 'Unable to move to next step: ' + ex.getMessage());
            System.debug('error message'+ ex.getStackTraceString());
        }
        return response;
    }
     
    public static Map<String, Object> validateForCaseReview(Case caseRec){ 
        Map<String, Object> response = new Map<String, Object>();
      
            if (caseRec == null) {
                response.put('status', 'error');
                response.put('message', 'Unable to move to next step: Case record is null.');
                return response;
            }
       
            CRMComplaintRequestHandler objComplaintRequestHandler = CRMComplaintRequestHandler.getInstance();
                  
            Id complaintRequestRTID = Utility.getRecordTypeIdByDevName(Case.SObjectType,COMPLAINT_REQUEST_RT);
                    
             if(caseRec.RecordTypeId == complaintRequestRTID){
                response = objComplaintRequestHandler.validateCaseForNextReview(caseRec);
            }            
        	else {
                // Fallback if no matching record type found
                response.put('status', 'error');
                response.put('message', 'Unable to move to next step: No validation logic found for this record type.');
            }
       
        return response; 
    }
      @AuraEnabled(cacheable=true)
    public static Map<String,String> getTeamValues() {
        return Utility.getPicklistValues(ServiceAction__c.SObjectType, 'Department__c');
    }    
  @AuraEnabled(cacheable=true)
public static List<Map<String, String>> getUsersByTeam(String team) {

    List<Map<String, String>> usersList = new List<Map<String, String>>();

    Map<String, String> deptToQueue = new Map<String, String>{
        'CRM' => 'CRM_Queue',
        'Finance' => 'Finance_Team_Queue',
        'Operations' => 'Operation_Team_Queue'
    };

    String queueDevName = deptToQueue.get(team);
    if (String.isBlank(queueDevName)) {
        return usersList;
    }

    QueueService queueService = QueueService.getInstance();

    Group queue = queueService.getGroupByDeveloperNameAndType(queueDevName,'Queue');

    if (queue == null) {
        return usersList;
    }

    Set<Id> userIds = new Set<Id>();

    for (GroupMember gm : queueService.getGroupMembersByGroupId(queue.Id)) {
        if (gm.UserOrGroupId.getSObjectType() == User.SObjectType) {
            userIds.add(gm.UserOrGroupId);
        }
    }

    if (userIds.isEmpty()) {
        return usersList;
    }

   UserService userService = UserService.getInstance();

    for (User u : userService.getUsersByIds(userIds)) {
    
             usersList.add(new Map<String, String>{
            'label' => u.Name,
            'value' => u.Id
        });
    
}

      return usersList;
}
   @AuraEnabled
   public static void createSelectedTeamTask(Id caseId,String team,Id userId,String comments) {
   
       Case caseRec = CaseService.getInstance().getCaseById(caseId);
 
   ServiceAction__c selectedAction = ServiceCatalogService.getInstance().getServiceActionByCatalogAndDepartment(caseRec.ServiceCatalog__c,team);

    ActivityService activityService = ActivityService.getInstance();
       List<Task> prevTask = activityService.fetchOpenTaskForCase(caseRec);
       System.debug('task>>>>'+prevTask);
       activityService.closeTasks(prevTask);
       
    Task task = activityService.createTaskFromServiceAction(selectedAction);

    task.WhatId = caseRec.Id;
    task.Type = 'Other';
    task.Department__c = team;
    task.OwnerId = userId;

    if (selectedAction.Due_in_days__c != null) {
        task.ActivityDate = System.today().addDays(Integer.valueOf(selectedAction.Due_in_days__c));
    }

   activityService.insertTasks(new List<Task>{task});

   Case caseToUpdate = new Case(Id = caseRec.Id,Status = 'In Progress',SubStatus__c = null,PendingWith__c = team,OwnerId = userId,Comments = comments,
                               Step__c = selectedAction.FinalTask__c? 'Final': String.valueOf(Integer.valueOf(selectedAction.Order__c)));

    CaseService.getInstance().updateCases(new List<Case>{caseToUpdate});
    }
    
 @AuraEnabled
public static Boolean shouldShowTeamSection(Id caseId) {
    Case c = CaseService.getInstance().getCaseById(caseId);

    if (c.SubStatus__c == 'Resolved') {
        return false;
    }

    return QueueService.getInstance().isUserMemberOfQueue('CRM_Queue', c.OwnerId);
}
}