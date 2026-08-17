/**
* Class       : ApprovalRequestHandler
* Author      : Akshay Khairnar
* Description : Automating approve/reject of the approval process
* TestClass   : 
* ----------------------------------------------------------------------------------------------------------------
* -- History --
* ----------------------------------------------------------------------------------------------------------------
* Sr.No.     version              Date                Details
* 1.          V1.0              17/08/25           Initial Version 
* ****************************************************************************************************************/
public class ApprovalRequestHandler {
    
    @InvocableMethod
    public static List<Results> execute(List<Requests> requests) {
        
        List<Case> casesToSetBLTrue = new List<Case>();
        List<Case> rollbackCases = new List<Case>();
        List<Results> responseWrapper = new List<Results>();
        
        // STEP 1: Collect all SendToBL__c updates
        for (Requests r : requests) {
            casesToSetBLTrue.add(new Case(
                Id = r.recordId,
                SendToBL__c = true
            ));
        }
        
        // Single bulk update
        if (!casesToSetBLTrue.isEmpty()) {
            caseService.getInstance().updateUnits(casesToSetBLTrue);
        }
        
        // STEP 2: Process approvals
        for (Requests curRequest : requests) {
            Results response = new Results();
            
            try {
                Approval.ProcessWorkitemRequest approvalWorkItem = new Approval.ProcessWorkitemRequest();
                approvalWorkItem.setComments(curRequest.comments);
                approvalWorkItem.setAction(curRequest.action);
                approvalWorkItem.setNextApproverIds(curRequest.nextApproverIds);
                
                if (String.isBlank(curRequest.approvalRequestId)) {
                    ProcessInstanceWorkitem workItem =
                        getApprovalRequestId(curRequest.recordId, curRequest.objName);
                    if (workItem != null) {
                        curRequest.approvalRequestId = workItem.Id;
                    }
                }
                approvalWorkItem.setWorkitemId(curRequest.approvalRequestId);
                
                Approval.ProcessResult approvalResult = Approval.process(approvalWorkItem);
                
                response.isSuccess = approvalResult.isSuccess();
                response.errorString = getErrorInfo(approvalResult.getErrors());
                response.currentApprovalProcessStatus = approvalResult.getInstanceStatus();
                
                // Mark rollback if approval failed
                if (!approvalResult.isSuccess()) {
                    rollbackCases.add(new Case(
                        Id = curRequest.recordId,
                        SendToBL__c = false
                    ));
                }
                
            } catch (Exception ex) {
                response.isSuccess = false;
                response.errorString = ex.getMessage();
                response.currentApprovalProcessStatus = 'Error';
                
                rollbackCases.add(new Case(
                    Id = curRequest.recordId,
                    SendToBL__c = false
                ));
            }
            
            responseWrapper.add(response);
        }
        
        // STEP 3: Bulk rollback
        if (!rollbackCases.isEmpty()) {
            caseService.getInstance().updateUnits(rollbackCases);
        }
        
        return responseWrapper;
    }
    
    
    public static String getErrorInfo(Database.Error[] errors) {
        String errorStrings = '';
        if (errors != null) {
            for(Database.Error error : errors) {
                errorStrings += ' ' + error.getMessage();
            }
        }
        return errorStrings;
    }
    
    public static ProcessInstanceWorkitem getApprovalRequestId(String recordId, String objName){
        List<ProcessInstanceWorkitem> workItems = [
            SELECT Id, ActorId, CreatedDate, OriginalActorId, OriginalActor.Name,
            ProcessInstanceId, ProcessInstance.Status, ProcessInstance.SubmittedById, 
            ProcessInstance.ProcessDefinition.TableEnumOrId,
            ProcessInstance.ProcessDefinition.Type  
            FROM ProcessInstanceWorkitem 
            WHERE ProcessInstance.TargetObjectId = :recordId
            AND ProcessInstance.ProcessDefinition.Type = 'Approval' 
            AND ProcessInstance.ProcessDefinition.TableEnumOrId = :objName
            AND ProcessInstance.Status = 'Pending'  
            LIMIT 1
        ];
        return workItems.isEmpty() ? null : workItems[0];
    }
    
    public class Requests {
        @InvocableVariable public String recordId;
        @InvocableVariable public String objName;
        @InvocableVariable public String approvalRequestId;
        @InvocableVariable public String comments;
        @InvocableVariable public String action; // 'Approve', 'Reject'
        @InvocableVariable public List<String> nextApproverIds;
    }
    
    public class Results {
        @InvocableVariable public Boolean isSuccess;
        @InvocableVariable public String errorString;
        @InvocableVariable public String currentApprovalProcessStatus;  // Approved, Rejected, Removed, Pending, Error
    }
}