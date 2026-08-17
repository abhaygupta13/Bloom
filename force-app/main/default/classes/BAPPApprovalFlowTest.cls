@isTest
private class BAPPApprovalFlowTest {

    @isTest
    static void test_updateApprovalComments_emptyRecordId() {
        // Input with null recordId
        BAPPApprovalFlow.InputWrapper input = new BAPPApprovalFlow.InputWrapper();
        input.recordId = null;

        Test.startTest();
        BAPPApprovalFlow.updateApprovalComments(new List<BAPPApprovalFlow.InputWrapper>{ input });
        Test.stopTest();

        System.assert(true, 'Executed successfully with empty recordId.');
    }

    @isTest
    static void test_updateApprovalComments_noCommentsScenario() {
        // Create app with no comments or mock steps
        BrokerApplication__c app = new BrokerApplication__c(Name = 'Test App');
        insert app;

        // No approval steps
        BAPPApprovalFlow.testSteps = new List<ProcessInstanceStep>();

        BAPPApprovalFlow.InputWrapper input = new BAPPApprovalFlow.InputWrapper();
        input.recordId = app.Id;

        Test.startTest();
        BAPPApprovalFlow.updateApprovalComments(new List<BAPPApprovalFlow.InputWrapper>{ input });
        Test.stopTest();

        // Verify no fields updated
        app = [SELECT ApprovalComments__c, RejectionComments__c FROM BrokerApplication__c WHERE Id = :app.Id];
        System.assertEquals(null, app.ApprovalComments__c, 'Approval comment should remain null');
        System.assertEquals(null, app.RejectionComments__c, 'Rejection comment should remain null');
    }

    @isTest
    static void test_updateApprovalComments_withApprovedAndRejectedSteps() {
        // Create a BrokerApplication
        BrokerApplication__c app = new BrokerApplication__c(Name = 'Step Coverage App');
        insert app;
    
        // Mock ProcessInstanceStep with nested ProcessInstance
        BAPPApprovalFlow.testSteps = new List<ProcessInstanceStep>{
            new ProcessInstanceStep(
                Comments = 'Approved by Approver',
                StepStatus = 'Approved',
                ProcessInstance = new ProcessInstance(TargetObjectId = app.Id)
            ),
            new ProcessInstanceStep(
                Comments = 'Rejected by Reviewer',
                StepStatus = 'Rejected',
                ProcessInstance = new ProcessInstance(TargetObjectId = app.Id)
            )
        };
    
        // Call method
        BAPPApprovalFlow.InputWrapper input = new BAPPApprovalFlow.InputWrapper();
        input.recordId = app.Id;
    
        Test.startTest();
        BAPPApprovalFlow.updateApprovalComments(new List<BAPPApprovalFlow.InputWrapper>{ input });
        Test.stopTest();
    
        // Verify database updates
        app = [SELECT ApprovalComments__c, RejectionComments__c FROM BrokerApplication__c WHERE Id = :app.Id];
        System.assertEquals('Approved by Approver', app.ApprovalComments__c, 'Approved comment should be updated');
        System.assertEquals('Rejected by Reviewer', app.RejectionComments__c, 'Rejected comment should be updated');
    }

    @isTest
    static void test_updateApprovalComments_forCaseRecord() {
        // Get RecordTypeId for "Broker_Registration"
        Id  caseRecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'Broker_Registration' LIMIT 1].Id;

        // Create Case record with Broker_Registration record type
        Case caseRec = new Case(
            Subject = 'Approval Test Case',
            RecordTypeId = caseRecordTypeId
        );
        insert caseRec;
        
        // Mock ProcessInstanceStep for Case
        BAPPApprovalFlow.testSteps = new List<ProcessInstanceStep>{
            new ProcessInstanceStep(
                Comments = 'Case Approved Comment',
                StepStatus = 'Approved',
                ProcessInstance = new ProcessInstance(TargetObjectId = caseRec.Id)
            ),
            new ProcessInstanceStep(
                Comments = 'Case Rejected Comment',
                StepStatus = 'Rejected',
                ProcessInstance = new ProcessInstance(TargetObjectId = caseRec.Id)
            )
        };

        // Prepare InputWrapper for Case
        BAPPApprovalFlow.InputWrapper input = new BAPPApprovalFlow.InputWrapper();
        input.recordId = caseRec.Id;

        Test.startTest();
        BAPPApprovalFlow.updateApprovalComments(new List<BAPPApprovalFlow.InputWrapper>{ input });
        Test.stopTest();

        // Verify Case updates
        caseRec = [SELECT ApprovalComments__c, RejectionComments__c, RecordType.DeveloperName FROM Case WHERE Id = :caseRec.Id];
        System.assertEquals('Case Approved Comment', caseRec.ApprovalComments__c, 'Case approval comment should be updated');
        System.assertEquals('Case Rejected Comment', caseRec.RejectionComments__c, 'Case rejection comment should be updated');
        System.assertEquals('Broker_Registration', caseRec.RecordType.DeveloperName, 'Case record should have correct record type');
    }
}