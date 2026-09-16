@isTest
public class SurveyServiceTest {
	 @istest
    static void TestMethod1(){

        // Test data for Project__c and related Units
        Account account = TestDataFactory.createPersonalAccount('Lastname', '01010101', '1234567890', 'test@gmail.com');
        account.CustomerType__c = 'Resident';
        INSERT account;

        Account acc = new Account(Name = 'Test Account');
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
        
        Opportunity tempOpp = new Opportunity(
            Name ='tempOpp',
            StageName ='New',
            CloseDate =system.today(),
            LeadChannel__c ='Walk in',
            AccountId = account.Id,
            WinReason__c ='Loyalty',
            BrokerAgencyAccount__c = acc.Id,
            BrokerAgentContact__c = con1.Id
        );
        
        //List<SalesOrder__c> solist = new List<SalesOrder__c>();
        SalesOrder__c soRec = TestDataFactory.createSalesOrder(account.Id, null, null, null, u.Id, 100.00);
        //salesOrder.DocumentUploadedDate__c = Date.today();
        soRec.UnitRegistrationDate__c = Date.today();
        soRec.Status__c= 'Booked';
        soRec.Opportunity__c = tempOpp.Id;
        insert soRec;
        
        test.startTest();
        List<Survey__c> svListToInsert = new List<Survey__c>();
        SurveyService surveyServiceInstance = SurveyService.getInstance();
        
        Survey__c svRec1 = new Survey__c();
        svRec1.SalesOrder__c = soRec.Id;
        svRec1.Account__c = account.Id;
        svRec1.Email__c = account.PersonEmail;
        svRec1.FirstName__c = account.FirstName;
        svRec1.LastName__c = account.LastName;
        /*svRec1.Project__c = soRec.Project__c;
        svRec1.ProjectName__c = soRec.ProjectName__c;
        svRec1.SalesManager__c = soRec.SalesManager__c;*/
        svRec1.Unit__c = u.Id;
        svRec1.UnitNumber__c = u.UnitNumber__c;
        //svRec1.SurveyType__c = SurveyHandler.SALES_CUSTOMER_SURVEY_TYPE;
        svListToInsert.add(svRec1);
        
        surveyServiceInstance.insertSurveys(svListToInsert);
        surveyServiceInstance.updateSurveys(svListToInsert);
        surveyServiceInstance.getSurveyRecordById(svRec1.Id);
        List<Id> surveyIdList = new List<Id>();
        surveyIdList.add(svRec1.Id);
        surveyServiceInstance.getSurveysByIds(surveyIdList);
        test.stoptest();
    }
}