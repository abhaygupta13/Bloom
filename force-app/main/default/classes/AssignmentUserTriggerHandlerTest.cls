@isTest
public class AssignmentUserTriggerHandlerTest {
    
    @testSetup
    static void setupData() {
        
        // Existing Business Hours
        BusinessHours bh = [ SELECT Id, Name FROM BusinessHours LIMIT 1 ];
        
        // Profile 
        Profile p = [ SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1 ];
        
        // Test User
        User usr = new User(
            FirstName = 'Test',
            LastName = 'User',
            Alias = 'tuser',
            Email = 'testuser@test.com',
            Username = 'testuser' + System.currentTimeMillis() + '@test.com',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Dubai',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        
        insert usr;
        
        // Assignment Rule
        AssignmentRule__c assr = new AssignmentRule__c();
        assr.RecordType__c = 'Case';
        assr.ProcessName__c = 'BFM Email To Case Assignment';
        assr.IsActive__c = true;
        
        insert assr;
        
        // Assignment User
        AssignmentUser__c assignRec = new AssignmentUser__c(
            User__c = usr.Id,
            AssignmentRule__c = assr.Id,
            BusinessHours__c = bh.Id
        );
        
        insert assignRec;
    }
    
    @isTest
    static void testAfterUpdate() {
        
        AssignmentUser__c assignRec = [ SELECT Id, User__c, BusinessHours__c FROM AssignmentUser__c LIMIT 1 ];
        BusinessHours bh = [ SELECT Id FROM BusinessHours LIMIT 1 ];
        
        Test.startTest();
        assignRec.BusinessHours__c = bh.Id;
        update assignRec;
        Test.stopTest();
        
        User usr = [ SELECT Id, BusinessHour__c FROM User WHERE Id = :assignRec.User__c ];
        System.assertEquals(bh.Id,usr.BusinessHour__c);
    }
    
    @isTest
    static void testDeleteAndUndelete() {
        
        // Fetch test Assignment User record
        AssignmentUser__c assignRec = [
            SELECT Id
            FROM AssignmentUser__c
            LIMIT 1
        ];
        
        Test.startTest();
        
        // Covers beforeDelete and afterDelete
        delete assignRec;
        
        // Covers afterUnDelete
        undelete assignRec;
        
        Test.stopTest();
    }
    
}