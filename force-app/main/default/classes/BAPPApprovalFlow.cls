/*
* @Author : Akshay Khairnar
* @CreatedDate : 11 June 2025
* @Description : It is used to get the Approval comments and store in BrokerApplication or Case
*/
/*****************************************************************************************************
* Version       Author      Date             Comment                                                                       
* 1.0           Akshay      11JUN2025        Initial draft 
* 2.0           Akshay      04SEP2025        Enhanced to support Case records also
* 2.1           Akshay      09OCT2025        Modified to not return any value for Flow invocation
*****************************************************************************************************/
public class BAPPApprovalFlow {

    public class InputWrapper {
        @InvocableVariable(required=true)
        public Id recordId;
    }

    @TestVisible public static List<ProcessInstanceStep> testSteps;
    
    @InvocableMethod(label='Fetch and Store Approval Comments')
    public static void updateApprovalComments(List<InputWrapper> inputs) {

        Set<Id> recordIds = new Set<Id>();
        for (InputWrapper input : inputs) {
            if (input.recordId != null) {
                recordIds.add(input.recordId);
            }
        }

        if (recordIds.isEmpty()) {
            return;
        }

        // Query approval history
        List<ProcessInstanceStep> steps = getApprovalSteps(recordIds);

        // Separate comments per record
        Map<Id, String> approvedComments = new Map<Id, String>();
        Map<Id, String> rejectedComments = new Map<Id, String>();

        for (ProcessInstanceStep step : steps) {
            Id targetId = step.ProcessInstance.TargetObjectId;

            if (step.StepStatus == 'Approved' && !approvedComments.containsKey(targetId)) {
                approvedComments.put(targetId, step.Comments);
            } else if (step.StepStatus == 'Rejected' && !rejectedComments.containsKey(targetId)) {
                rejectedComments.put(targetId, step.Comments);
            }
        }

        // Separate Ids by SObject type
        Set<Id> brokerAppIds = new Set<Id>();
        Set<Id> caseIds = new Set<Id>();

        for (Id recId : recordIds) {
            if (recId.getSObjectType() == BrokerApplication__c.SObjectType) {
                brokerAppIds.add(recId);
            } else if (recId.getSObjectType() == Case.SObjectType) {
                caseIds.add(recId);
            }
        }

        List<BrokerApplication__c> brokerUpdates = new List<BrokerApplication__c>();
        List<Case> caseUpdates = new List<Case>();

        // Prepare BrokerApplication updates
        for (Id recId : brokerAppIds) {
            BrokerApplication__c app = new BrokerApplication__c(Id = recId);
            Boolean toUpdate = false;

            if (approvedComments.containsKey(recId)) {
                app.ApprovalComments__c = approvedComments.get(recId);
                toUpdate = true;
            }
            if (rejectedComments.containsKey(recId)) {
                app.RejectionComments__c = rejectedComments.get(recId);
                toUpdate = true;
            }

            if (toUpdate) {
                brokerUpdates.add(app);
            }
        }

        // Prepare Case updates
        for (Id recId : caseIds) {
            Case c = new Case(Id = recId);
            Boolean toUpdate = false;

            if (approvedComments.containsKey(recId)) {
                c.ApprovalComments__c = approvedComments.get(recId);
                toUpdate = true;
            }
            if (rejectedComments.containsKey(recId)) {
                c.RejectionComments__c = rejectedComments.get(recId);
                toUpdate = true;
            }

            if (toUpdate) {
                caseUpdates.add(c);
            }
        }

        // Perform updates
        if (!brokerUpdates.isEmpty()) {
            BrokerApplicationService.getInstance().updateApplications(brokerUpdates);
        }
        if (!caseUpdates.isEmpty()) {
            CaseService.getInstance().updateCasesWithoutTrigger(caseUpdates);
        }
    }

    @TestVisible
    private static List<ProcessInstanceStep> getApprovalSteps(Set<Id> recordIds) {
        if (Test.isRunningTest() && testSteps != null) {
            return testSteps;
        }

        return [
            SELECT Comments, StepStatus, CreatedDate, ProcessInstance.TargetObjectId
            FROM ProcessInstanceStep
            WHERE ProcessInstance.TargetObjectId IN :recordIds
            AND Comments != null
            ORDER BY CreatedDate DESC
        ];
    }
}