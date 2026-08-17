@isTest
public class HandoverPhaseServiceTest {
    @isTest
    static void HandoverPhaseServiceTestMethod() {
        Project__c project = TestDataFactory.createProject('TEST');
        project.ProjectRegistrationDate__c = Date.today() - 1;
        project.ProjectNameArabic__c = 'Test Arabic name';
        insert project;
        HandoverPhaseService service = HandoverPhaseService.getInstance();
        service.getHandoverPhase(project.id);
    }
}