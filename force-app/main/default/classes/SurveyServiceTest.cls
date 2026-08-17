@isTest
public class SurveyServiceTest {
	 @istest
    static void TestMethod1(){
        
        User u1 = new User();
        System.runAs ( new User(Id = UserInfo.getUserId()) ) {
            Profile p = [SELECT Id FROM Profile WHERE Name='HO Agent'];
            PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Handover_HO_Agent'];
            
            u1 = new User(FirstName = 'Ho Agent', LastName='User', Alias = 'op', Email='hoagent@bloom.com', EmailEncodingKey='UTF-8',ProfileId = p.Id, 
                         LocaleSidKey = 'en_US', LanguageLocaleKey='en_US', TimeZoneSidKey='America/Los_Angeles', UserName='hoagent@bloom.com.u1');
            insert u1;
            
            insert new PermissionSetAssignment(AssigneeId = u1.Id,PermissionSetId = ps.Id);
        }
        
         User crmUser = new User();
        System.runAs ( new User(Id = UserInfo.getUserId()) ) {
            Profile p = [SELECT Id FROM Profile WHERE Name='CRM Operations'];
            PermissionSet ps = [SELECT Id,Name FROM PermissionSet WHERE Name = 'Handover_CRM_Team'];
            system.debug('permission'+ps.Name);
            
            crmUser = new User(FirstName = 'CRM', LastName='User', Alias = 'op', Email='crmUser@bloom.com', EmailEncodingKey='UTF-8',ProfileId = p.Id, 
                               LocaleSidKey = 'en_US', LanguageLocaleKey='en_US', TimeZoneSidKey='America/Los_Angeles', UserName='crmUser@bloom.com.u1');
            insert crmUser;
            
            insert new PermissionSetAssignment(AssigneeId = crmUser.Id,PermissionSetId = ps.Id);
        }
        

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
        
           ServiceCatalog__c  servicecatalog = new ServiceCatalog__c();
        servicecatalog.ProcessFlowType__c= 'Handover';
        servicecatalog.ProcessType__c = 'Sales';
        servicecatalog.Active__c= true;
        servicecatalog.RecordTypeDevName__c = 'Handover';
        insert servicecatalog;
        
        
       
        
        // Create a Handover record
        Handover__c handover1 = new Handover__c(
            Name = 'Test Handover',
            Customer_Email__c = 'test@example.com',
            OwnerId = crmUser.id,
            ServiceCatalog__c = servicecatalog.Id,
            Is_Orientation_Letter_Sent__c = false,
            Is_BCC_Announcement_Sent__c =false,
            Unit__c = u.Id,
            CRM_Team_Assigned_User__c= crmUser.id,
            HO_Agent_Assigned_User__c= u1.id,
            Project__c = project.Id,
            Customer_Availability_for_CHO__c = 'Customer Available',
            Unit_is_Ready__c=false,
            UnitCategory__c='Registered Unit',
            Is_Notice_of_Completion_Sent__c=false,
            
            Sub_Status__c= 'QA Snagging'
        );
        insert handover1;
        
           Survey__c survey = new Survey__c();
        survey.Handover__c = handover1.id;
        survey.SurveyType__c = 'Handover Survey';
        survey.Link__c ='';
        insert survey;
        
      
        
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
        surveyServiceInstance.getSurveysByRelatedRecordId(handover1.id);
        surveyServiceInstance.getSingleSurveyByParentIdAndSurveyType(handover1.id,'Handover Survey');
        surveyServiceInstance.getServeysByParentIdandSurveyType(handover1.id,'Handover Survey');
        List<Id> surveyIdList = new List<Id>();
        surveyIdList.add(svRec1.Id);
        surveyServiceInstance.getSurveysByIds(surveyIdList);
        test.stoptest();
    }
}