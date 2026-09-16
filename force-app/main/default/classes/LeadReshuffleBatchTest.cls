/*****************************************************************************************
Class       : LeadReshuffleBatchTest
Author      : Dhanraj Poojary
Description : LeadReshuffleBatch Test Class
Test Class  : 
Created Date: 23 JUL 2025  
*****************************************************************************************/

@isTest
public class LeadReshuffleBatchTest {
    
    @TestSetup
    static void setupTestData(){
        Profile profileDetail = [SELECT Id FROM Profile WHERE Name='Sales Manager'];
        Profile profileDetail1 = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        List<User> userList = new List<User>();
        User userRecord = new User(Alias = 'Zaki', Email='Zakial@gmail.com', 
                                   EmailEncodingKey='UTF-8', LastName='Zaki Al Bakri', LanguageLocaleKey='en_US', 
                                   LocaleSidKey='en_US', ProfileId = profileDetail.id, 
                                   TimeZoneSidKey='Asia/Dubai', UserName= uniqueName+'@mail.com',SAP_BP_No__c='0');
        userList.add(userRecord);
        User userRecord1 = new User(Alias = 'Taki', Email='Takial@gmail.com', 
                                   EmailEncodingKey='UTF-8', LastName='Taki Al Bakri', LanguageLocaleKey='en_US', 
                                   LocaleSidKey='en_US', ProfileId = profileDetail1.id, 
                                   TimeZoneSidKey='Asia/Dubai', UserName= 'T'+uniqueName+'@mail.com',SAP_BP_No__c='0');
        userList.add(userRecord1);
        insert userList;
        // Test data for Project__c and related Units
        Account acc = TestDataFactory.createBrokerAccount('test', false, '1122334455');
        insert acc;
        
        Contact con = TestDataFactory.createContact('test', acc.Id, true, 'test@gmail.com');
        insert con;
        
        System.runAs(userRecord1){
            List<Lead> leadList = new List<Lead>();
            Lead objLead = TestDataFactory.createLead('TestLead', '9988776655', 'test@bloomholding.com');
            objLead.Project__c = 'Bloom Living';
            objLead.LeadManagerStatus__c = 'New';
            objLead.LeadTeam__c = 'Sales';
            objLead.Status = 'In Progress';
            objLead.IsDraftLead__c = false;
            objLead.LeadManagerAssignedDate__c = DateTime.now().addDays(-5);
            objLead.OwnerId = userRecord.Id;
            leadList.add(objLead);
            
            Lead objLead1 = TestDataFactory.createLead('TestLead2', '9988776655', 'test@bloomholding.com');
            objLead1.Project__c = 'Bloom Living';
            objLead1.LeadManagerStatus__c = 'New';
            objLead1.LeadTeam__c = 'Sales';
            objLead1.Status = 'In Progress';
            objLead1.IsDraftLead__c = false;
            objLead1.LeadManagerAssignedDate__c = DateTime.now().addDays(-5);
            objLead1.OwnerId = userRecord.Id;
            leadList.add(objLead1);
            insert leadList;
        }
    }
    
    @istest
    public static void testmethod1(){
        User objUser = [SELECT Id,Email FROM User WHERE Email ='Zakial@gmail.com' AND IsActive = TRUE LIMIT 1];
        
        System.runAs(objUser){
            Test.startTest();      
            String sch = '0 0 23 * * ?';
            LeadReshuffleBatch batchJob = new LeadReshuffleBatch();
            System.schedule('LeadReshuffleBatch',sch,batchJob);
            Test.stopTest();
        }
    }
}