@IsTest
public class QMSTokenAssignmentTriggerHelperTest {
    @testSetup
    private static void testData() {
        QMSToken__c token = TestDataFactory.createQMSTokenAssignment('C-123','Test Counter Name','test@gmail.com','123-1990-123456-78','test Name','SR-123','TRN-123');
        insert token;

        QMSTokenAssignment__c tokenAssignment = TestDataFactory.createQMSTokenAssignment('testName','test@gmail.com','1234-test',token.Id);
        insert tokenAssignment;
    }

    @isTest
    private static void testPopulateAssignedPerson(){
        QMSTokenAssignment__c assignment = [SELECT Id,Name,AssignedDate__c,AssignedPersonName__c,AssignedPersonEmail__c,AssignedPerson__c FROM QMSTokenAssignment__c LIMIT 1];
        List<QMSTokenAssignment__c> assignmentList = new List<QMSTokenAssignment__c>{ assignment };

        Test.startTest();
            QMSTokenAssignmentTriggerHelper.populateAssignedPerson( assignmentList, null );
        Test.stopTest();

        System.assertEquals( null, assignment.AssignedPerson__c, 'Assigned Person should not be populated.' );
    }

    @IsTest
    static void testPopulateAssignedPerson_Update() {

        Test.startTest();
            User testUser = [ SELECT Id, Email FROM User WHERE IsActive = true LIMIT 1 ];
            QMSTokenAssignment__c assignment = [ SELECT Id, AssignedPersonEmail__c,AssignedPerson__c FROM QMSTokenAssignment__c LIMIT 1 ];
            assignment.AssignedPersonEmail__c = testUser.Email;
            update assignment;
        	delete assignment;
        Test.stopTest();

    }

}