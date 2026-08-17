/*****************************************************************************************
Class       : LeadAssignmentBatchTest
Author      : Prashant Sahu
Description : LeadAssignmentBatch Test Class
Test Class  :
Created Date: 05 AUG 2026
*****************************************************************************************/
@IsTest
public class LeadAssignmentBatchTest {
    
    @TestSetup
    static void setupData(){
        
        Profile salesManager =[SELECT Id FROM Profile WHERE Name='Sales Manager' LIMIT 1];
        String unique =UserInfo.getOrganizationId() +Datetime.now().getTime();
        
        User u = new User(
            Alias='smgr',
            Email='sales@test.com',
            EmailEncodingKey='UTF-8',
            LastName='Manager',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            ProfileId=salesManager.Id,
            TimeZoneSidKey='Asia/Dubai',
            Username='sales'+unique+'@test.com',
            SAP_BP_No__c='0'
        );
        insert u;
        
        // Get Business Hours
        List<BusinessHours> bhs = [ SELECT Id FROM BusinessHours WHERE IsActive = true LIMIT 1 ];
        
        // Get Contact Centre Team User
       User contactCenterUser = [ SELECT Id FROM User WHERE Profile.Name = 'Contact Centre Team' AND IsActive = true LIMIT 1 ];
        
        // Create ADHA Assignment Rule
        AssignmentRule__c adhaRule = new AssignmentRule__c(
            RecordType__c = 'Lead',
            ProcessName__c = 'ADHA Lead Assignment',
            ProcessType__c = 'Sales',
            IsActive__c = true
        );
        insert adhaRule;
        
        // Create Assignment User
        AssignmentUser__c adhaAssignmentUser = new AssignmentUser__c(
            AssignmentRule__c = adhaRule.Id,
            User__c = contactCenterUser.Id,
            BusinessHours__c = bhs[0].Id,
            IsActive__c = true
        );
        
        insert adhaAssignmentUser;
        
        
        Id queueId = MetadataService.getInstance().getAppSettingTextValue('AadhaSalesLeadQueueId');
        
        Lead l = TestDataFactory.createLead(
            'Batch Test',
            '9876543211',
            'batch@test.com'
        );
        
        l.OwnerId = queueId;
        l.Status = 'In Progress';
        l.LeadSource = 'Government Entity';
        l.Lead_Channel__c = 'API Integration';
        l.LeadSubSource__c = 'ADHA';
        l.LeadTeam__c = 'Sales';
        
        insert l;
    }
    
    @IsTest
    static void testLeadAssignmentBatch(){
        
        Test.startTest();
        Database.executeBatch(new LeadAssignmentBatch(),1);
        Test.stopTest();
        
        Lead l = [ SELECT OwnerId, Status, LeadManagerStatus__c, LeadManagerAssignedDate__c, Email FROM Lead WHERE Email = 'batch@test.com' LIMIT 1 ];
        
        System.assertEquals('In Progress',l.Status);
        System.assertEquals('New', l.LeadManagerStatus__c);
        System.assertNotEquals(null,l.LeadManagerAssignedDate__c);
    }
    
    @IsTest
    static void testScheduleBatch(){
        
        Test.startTest();
        System.schedule( 'LeadAssignmentBatch', '0 0 23 * * ?', new LeadAssignmentBatch() );
        Test.stopTest();
        CronTrigger ct = [ SELECT Id FROM CronTrigger LIMIT 1 ];
        System.assertNotEquals(null, ct.Id);
    }
}