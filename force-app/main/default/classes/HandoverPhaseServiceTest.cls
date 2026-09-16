@isTest
private class HandoverPhaseServiceTest {
    
    @isTest
    static void testGetHandoverPhase() {
        // Create test data
        Project__c project = TestDataFactory.createProject('TEST');
        project.ProjectRegistrationDate__c = Date.today() - 1;
        project.ProjectNameArabic__c = 'Test Arabic name';
        insert project;
        
        // Create HandoverPhase__c record
        HandoverPhase__c phase = new HandoverPhase__c(
            Name = 'Test Phase',
            Project__c = project.Id
        );
        insert phase;
        
        // Test getHandoverPhase method
        Test.startTest();
        HandoverPhaseService service = HandoverPhaseService.getInstance();
        List<HandoverPhase__c> phases = service.getHandoverPhase(project.Id);
        Test.stopTest();
        
        // Verify results
        System.assertNotEquals(0, phases.size(), 'Should return at least one handover phase');
        System.assertEquals(phase.Id, phases[0].Id, 'Should return the created phase');
        System.assertEquals(project.Id, phases[0].Project__c, 'Phase should belong to the project');
    }
    
    @isTest
    static void testGetHandoverPhaseDetails() {
        // Create test data
        Project__c project = TestDataFactory.createProject('TEST');
        project.ProjectRegistrationDate__c = Date.today() - 1;
        insert project;
        
        // Create HandoverPhase__c record with email template IDs
        HandoverPhase__c phase = new HandoverPhase__c(
            Name = 'Test Phase Details',
            Project__c = project.Id,
            FirstHOPaymentReminderEmailTempId__c = 'template1',
            BCCEmailTemplateId__c = 'template2',
            CHOinviteEmailTempId__c = 'template3'
        );
        insert phase;
        
        // Test getHandoverPhaseDetails method
        Test.startTest();
        HandoverPhaseService service = HandoverPhaseService.getInstance();
        HandoverPhase__c phaseDetails = service.getHandoverPhaseDetails(phase.Id);
        Test.stopTest();
        
        // Verify results
        System.assertNotEquals(null, phaseDetails, 'Should return handover phase details');
        System.assertEquals(phase.Id, phaseDetails.Id, 'Should return the correct phase');
        System.assertEquals('Test Phase Details', phaseDetails.Name, 'Name should match');
        System.assertEquals('template1', phaseDetails.FirstHOPaymentReminderEmailTempId__c, 'First email template should match');
    }
    
    @isTest
    static void testGetHandoverPhaseInfo() {
        // Create test data
        Project__c project = TestDataFactory.createProject('TEST');
        project.ProjectRegistrationDate__c = Date.today() - 1;
        insert project;
        
        // Create HandoverPhase__c records
        List<HandoverPhase__c> phases = new List<HandoverPhase__c>();
        for (Integer i = 0; i < 3; i++) {
            phases.add(new HandoverPhase__c(
                Name = 'Test Phase ' + i,
                Project__c = project.Id,
                FirstHOPaymentReminderEmailTempId__c = 'template' + i,
                BCCEmailTemplateId__c = 'bccTemplate' + i
            ));
        }
        insert phases;
        
        Set<Id> phaseIds = new Set<Id>();
        for (HandoverPhase__c p : phases) {
            phaseIds.add(p.Id);
        }
        
        // Test getHandoverPhaseInfo method
        Test.startTest();
        HandoverPhaseService service = HandoverPhaseService.getInstance();
        List<HandoverPhase__c> phaseInfoList = service.getHandoverPhaseInfo(phaseIds);
        Test.stopTest();
        
        // Verify results
        System.assertNotEquals(0, phaseInfoList.size(), 'Should return handover phases');
        System.assertEquals(3, phaseInfoList.size(), 'Should return all 3 phases');
        
        // Verify all phases have required fields populated
        for (HandoverPhase__c p : phaseInfoList) {
            System.assertNotEquals(null, p.Name, 'Name should not be null');
            System.assertNotEquals(null, p.Project__c, 'Project should not be null');
            System.assertNotEquals(null, p.FirstHOPaymentReminderEmailTempId__c, 'Email template should not be null');
        }
    }
    
    @isTest
    static void testGetInstanceSingleton() {
        // Test that getInstance returns the same instance (singleton pattern)
        HandoverPhaseService instance1 = HandoverPhaseService.getInstance();
        HandoverPhaseService instance2 = HandoverPhaseService.getInstance();
        
        System.assertEquals(instance1, instance2, 'getInstance should return the same instance');
    }
    
    @isTest
    static void testGetHandoverPhaseNoRecords() {
        // Create a project without any handover phases
        Project__c project = TestDataFactory.createProject('TEST');
        insert project;
        
        // Test getHandoverPhase with no related records
        Test.startTest();
        HandoverPhaseService service = HandoverPhaseService.getInstance();
        List<HandoverPhase__c> phases = service.getHandoverPhase(project.Id);
        Test.stopTest();
        
        // Verify empty list is returned
        System.assertEquals(0, phases.size(), 'Should return empty list when no phases exist');
    }
}