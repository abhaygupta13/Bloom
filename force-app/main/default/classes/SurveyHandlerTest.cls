@isTest
public class SurveyHandlerTest {
	 @istest
    static void TestMethod1(){
        Test.enableChangeDataCapture();

        // Test data for Project__c and related Units
        Account account = TestDataFactory.createPersonalAccount('Lastname', '01010101', '1234567890', 'test@gmail.com');
        account.CustomerType__c = 'Resident';
        INSERT account;

        Id accRecordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Broker Agency').getRecordTypeId();
        Account acc = new Account(Name = 'Test Account', RecordTypeId= accRecordTypeId);
        insert acc;
        
        //Test data for Project__c and related Units
        Project__c project = TestDataFactory.createProject('ProjectTest', Date.today() - 1);
        insert project;
        
        Unit__c u = TestDataFactory.createUnit(project.Id, 'A1-G01', 'Unassigned');
        u.Project__c = project.Id;
        u.RegistrationDate__c = Date.today();
        insert u;
        
        Contact con1 = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'john.doe@example.com',
            MobileCountryCode__c = '+1',
            MobilePhone = '1234567890',
            AccountId = acc.Id
        );
        insert con1;
        
        Opportunity tempOpp1 = new Opportunity(
            Name ='tempOpp',
            StageName ='New',
            CloseDate =system.today(),
            LeadChannel__c ='Walk in',
            AccountId = account.Id,
            WinReason__c ='Loyalty',
            BrokerAgencyAccount__c = acc.Id,
            BrokerAgentContact__c = con1.Id
        );
        insert tempOpp1;
        
        Opportunity tempOpp2 = new Opportunity(
            Name ='tempOpp',
            StageName ='New',
            CloseDate =system.today(),
            LeadChannel__c ='Walk in',
            AccountId = account.Id,
            WinReason__c ='Loyalty',
            Sale_Type__c = 'Resale'
        );
        insert tempOpp2;
        
        //List<SalesOrder__c> solist = new List<SalesOrder__c>();
        SalesOrder__c soRec1 = TestDataFactory.createSalesOrder(account.Id, null, null, null, u.Id, 100.00);
        //salesOrder.DocumentUploadedDate__c = Date.today();
        soRec1.UnitRegistrationDate__c = Date.today();
        soRec1.Status__c= 'Sold';
        soRec1.Opportunity__c = tempOpp1.Id;
        insert soRec1;
        
        SalesOrder__c soRec2 = TestDataFactory.createSalesOrder(account.Id, null, null, null, u.Id, 100.00);
        //salesOrder.DocumentUploadedDate__c = Date.today();
        soRec2.UnitRegistrationDate__c = Date.today();
        soRec2.Status__c= 'Sold';
        soRec2.Opportunity__c = tempOpp2.Id;
        soRec2.Resale__c = true;
        soRec2.ResaleBrokerAgency__c = acc.Id;
        soRec2.ResaleBrokerAgent__c = con1.Id;
        insert soRec2;
        System.debug('soRec2 ::::: '+ soRec2);
        Set<Id> soRecIdSet = new Set<Id>();
        soRecIdSet.add(soRec1.Id);
        soRecIdSet.add(soRec2.Id);
        
        test.startTest();
        SurveyHandler.sendSalesCustomerSurvey(soRecIdSet);
        SurveyHandler.sendHandoverSurvey(soRecIdSet);
        test.stoptest();
    }
}