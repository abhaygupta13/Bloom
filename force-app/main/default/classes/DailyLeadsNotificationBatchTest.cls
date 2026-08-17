/*****************************************************************************************
Class       : DailyLeadsNotificationBatchTest
Author      : Dhanraj Poojary
Description : DailyLeadsNotificationBatch Test Class
Test Class  : 
Created Date: 9 JUN 2025 
*****************************************************************************************/

@istest
public class DailyLeadsNotificationBatchTest {
    
    @TestSetup
    static void setupTestData(){
        Profile profileDetail = [SELECT Id FROM Profile WHERE Name='Leasing'];
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        
        User userRecord = new User(Alias = 'Zaki', Email='Zakial@gmail.com', 
                                   EmailEncodingKey='UTF-8', LastName='Zaki Al Bakri', LanguageLocaleKey='en_US', 
                                   LocaleSidKey='en_US', ProfileId = profileDetail.id, 
                                   TimeZoneSidKey='Asia/Dubai', UserName= uniqueName+'@mail.com',SAP_BP_No__c='0');
        insert userRecord;
        // Test data for Project__c and related Units
        Account acc = TestDataFactory.createBrokerAccount('test', false, '1122334455');
        insert acc;
        
        Contact con = TestDataFactory.createContact('test', acc.Id, true, 'test@gmail.com');
        insert con;
        
        Opportunity opp = TestDataFactory.createOpportunity(null, null,null, acc.Id, null, null, null, null);
        insert opp;
        
        //Test data for Project__c and related Units
        Project__c project = TestDataFactory.createProject('Bloom Living', Date.today() - 1);
        insert project;
        
        Unit__c u = TestDataFactory.createUnit(project.Id, 'A1-G01', 'Unassigned');
        u.Project__c = project.Id;
        u.RegistrationDate__c = Date.today();
        insert u;
        
        List<Lead> leadList = new List<Lead>();
        Lead objLead = TestDataFactory.createLead('TestLead', '9988776655', 'test@bloomholding.com');
        objLead.Project__c = 'Bloom Living';
        objLead.LeadManagerStatus__c = 'Follow Up';
        objLead.OwnerId = userRecord.Id;
        leadList.add(objLead);
        
        Lead objLead1 = TestDataFactory.createLead('TestLead2', '9988776655', 'test@bloomholding.com');
        objLead1.Project__c = 'Bloom Living';
        objLead1.LeadManagerStatus__c = 'Waiting List';
        objLead1.OwnerId = userRecord.Id;
        leadList.add(objLead1);
        insert leadList;
    }
    
    @istest
    public static void testmethod1(){
        User objUser = [SELECT Id,Email FROM User WHERE Email ='Zakial@gmail.com' AND IsActive = TRUE LIMIT 1];
        System.runAs(objUser){
            Test.startTest();
            Database.executeBatch(new DailyLeadsNotificationBatch(), 100);
            Test.stopTest();
        }
    }
}