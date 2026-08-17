@isTest
Private class SandboxPostRefreshActivitiesTest {
    @isTest
    static void testMySandbox() {
        
        Test.startTest();
        Test.testSandboxPostCopyScript(
            new SandboxPostRefreshActivities(), UserInfo.getOrganizationId(),
            UserInfo.getOrganizationId(), UserInfo.getOrganizationName(), true);
        
        Test.stopTest();
        
    }
    
}