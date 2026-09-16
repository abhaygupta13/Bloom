@isTest
public class TawtheeqEnrollmentSRHandlerTest {

    @TestSetup
    static void setupData(){
        Id AccountRecordTypeId = [Select id,Name from RecordType where Name='Organization Account'].id;
        Account tempAcc=new Account(
            RecordTypeId=AccountRecordTypeId,
            Name= 'test'
            
        );
        insert tempAcc;
        Contact tempContact =new Contact(
            LastName='test',
            AccountId=tempAcc.id,
            Email='test@gmail.com'
        );
        insert tempContact;

        Project__c testProject=new Project__c(
                Name='Test Project'
        );
        insert testProject;
        
        BuildingSection__c testBuilding=new BuildingSection__c(
            Name='Test Building',
            BuildingSectionCode__c='BL-CAS',
            Project__c=testProject.Id
            
        );
        insert testBuilding;
        
        Unit__c testUnit=new Unit__c(
            Name='test Unit',
            Status__c='Booked',
            UnitType__c='Townhouse',
            BuildingSectionName__c=testBuilding.id,
            Project__c=testProject.Id,
            PropertyUsage__c='Residential',
            UnitView__c  ='Beach Side',
            FloorNumber__c='01',
            NumberOfBedrooms__c='3',
            UnitModel__c='1BHK',
            SellingPrice__c= 700000
            
        );
        insert testUnit;

        SalesOrder__c testOrder = new SalesOrder__c(
            Name = 'Test Order',
            Status__c = 'Booked',
            Contact__c=tempContact.id,
            Unit__c =testUnit.id,
            Account__c = tempAcc.Id
            //Opportunity__c=tempOpp.Id            
        );
        insert testOrder;

        // Create test ServiceCatalog record
        ServiceCatalog__c testServiceCatalog = new ServiceCatalog__c(
            Name = 'Test Service Catalog',
            Type__c = 'Service Request',
            Category__c = 'CRM Services',
            SubCategory__c = 'Tawtheeq Enrollment',
            RecordTypeDevName__c = 'TawtheeqEnrollment',
            AvailableForOwner__c = true
        );
        insert testServiceCatalog;
        system.debug('testServiceCatalog----->'+testServiceCatalog);
        
        List<ServiceAction__c> stepList = new list<ServiceAction__c>();
        // Create test ServiceAction record
        ServiceAction__c testServiceAction1 = new ServiceAction__c(
            ServiceCatalog__c = testServiceCatalog.Id,
            TaskType__c = 'Tawtheeq Enrollment',
            TaskSubType__c = 'Finance Team Task 1',
            TaskSubject__c = 'Finance Team Task',
            Due_in_days__c = 2,
            Order__c = 1
        ); 
        stepList.add(testServiceAction1);
        ServiceAction__c testServiceAction2 = new ServiceAction__c(
            ServiceCatalog__c = testServiceCatalog.Id,
            TaskType__c = 'Tawtheeq Enrollment',
            TaskSubType__c = 'Government Relation Team Task 1',
            TaskSubject__c = 'Government Relation Team Task 1',
            Due_in_days__c = 2,
            Order__c = 2,
            FinalTask__c = true
        );
        stepList.add(testServiceAction2);
              
        

        insert stepList;

        List<DocumentType__c> docList = new List<DocumentType__c>();
        DocumentType__c doc1 = new DocumentType__c(ObjectType__c = 'Case',
                                        RecordTypeDevName__c = 'TawtheeqEnrollment',
                                        Type__c = 'Memo',
                                        Active__c = true);
        docList.add(doc1);
        DocumentType__c doc2 = new DocumentType__c(ObjectType__c = 'Case',
                                        RecordTypeDevName__c = 'TawtheeqEnrollment',
                                        Type__c = 'Statement of Account',
                                        Active__c = true);
        docList.add(doc2);
        insert docList;
        
        String RecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Tawtheeq Enrollment').getRecordTypeId();
        Case cs = new Case(Status = 'New', Origin = 'Phone', AccountId = tempAcc.Id, RecordTypeId= RecordTypeCaseId, 
                           ServiceCatalog__c = testServiceCatalog.Id, Sales_Order__c = testOrder.Id, Unit__c= testunit.Id);
        insert cs;
    }
    
    @isTest
    static void validatyTest(){
        SalesOrder__c so = [SELECT Id, Account__c, Unit__c FROM Salesorder__c LIMIT 1];
        ServiceRequestController.validateEligibility(so.id,'Tawtheeq Enrollment', so.Account__c, so.Unit__c, false);
    }
    
    @isTest
    static void createCaseTest(){
        SalesOrder__c so = [SELECT Id, Account__c, Unit__c FROM Salesorder__c LIMIT 1];
        ServiceRequestController.createCaseRecord(so.id,'Service Request','CRM Services','Tawtheeq Enrollment',so.Account__c,so.Unit__c,'test','Email', false);
    }
    
    @isTest
    static void validateCaseTest(){
        SalesOrder__c so = [SELECT Id, Account__c, Unit__c FROM Salesorder__c LIMIT 1];
        test.StartTest();
        Map<String,String> caseData = ServiceRequestController.createCaseRecord(so.id,'Service Request','CRM Services','Tawtheeq Enrollment',so.Account__c,so.Unit__c,'test','Email',false);
        test.stopTest();
        ReviewStepValidatorController.validateForNextReview(caseData.get('caseId'));
        TawtheeqEnrollmentSRHandler objTawtheeqEnrollmentSRHandler = TawtheeqEnrollmentSRHandler.getInstance();
        objTawtheeqEnrollmentSRHandler.validateCaseForNextReview(null);
    }
    
    @isTest
    static void validateCaseTest1(){
        SalesOrder__c so = [SELECT Id, Account__c, Unit__c FROM Salesorder__c LIMIT 1];
        test.StartTest();
        Map<String,String> caseData = ServiceRequestController.createCaseRecord(so.id,'Service Request','CRM Services','Tawtheeq Enrollment',so.Account__c,so.Unit__c,'test','Email',false);
        test.stopTest();
        ReviewStepValidatorController.validateForNextReview(caseData.get('caseId'));
        caseservice service = caseservice.getInstance();
        Case cs = [SELECT Id, AccountId, ContactId, Unit__c, Step__c, Unit__r.Project__r.Name, Unit__r.Name, Unit__r.Project__r.ProjectNameArabic__c,
                   Account.Name, Account.NameinArabic__c, Project__c, Account.IsPersonAccount, Account.PersonContactId, ServiceCatalog__c, Status, CaseType__c,
                   Sales_Order__c, RecordTypeId, StopEmailsToCustomer__c
                   FROM Case LIMIT 1];
        cs.step__c = '1';
        update cs;
        TawtheeqEnrollmentSRHandler objTawtheeqEnrollmentSRHandler = TawtheeqEnrollmentSRHandler.getInstance();
        objTawtheeqEnrollmentSRHandler.validateCaseForNextReview(cs);
    }
    
    @isTest
    static void validateEligibilityTest() {
        SalesOrder__c so = [SELECT Id, Account__c, Unit__c FROM Salesorder__c LIMIT 1];
        test.StartTest();
        Map<String,String> caseData = ServiceRequestController.createCaseRecord(so.id,'Service Request','CRM Services','Tawtheeq Enrollment',so.Account__c,so.Unit__c,'test','Email',false);
        test.stopTest();
        ReviewStepValidatorController.validateForNextReview(caseData.get('caseId'));
        caseservice service = caseservice.getInstance();
        Case cs = [SELECT Id, AccountId, ContactId, Unit__c, Step__c, Unit__r.Project__r.Name, Unit__r.Name, Unit__r.Project__r.ProjectNameArabic__c,
                   Account.Name, Account.NameinArabic__c, Project__c, Account.IsPersonAccount, Account.PersonContactId, ServiceCatalog__c, Status, CaseType__c,
                   Sales_Order__c, RecordTypeId, StopEmailsToCustomer__c, Handover__c
                   FROM Case LIMIT 1];
        cs.step__c = 'Final';
        update cs;
        Document__c tawtheeqRegConfDoc = new Document__c(Case__c = cs.Id, Document_Name__c = 'Tawtheeq Registration Confirmation', ContentDocumentId__c = '069000000000001AAA', Content_Version_Id__c = '068000000000001AAA');
        insert tawtheeqRegConfDoc;
        TawtheeqEnrollmentSRHandler objTawtheeqEnrollmentSRHandler = TawtheeqEnrollmentSRHandler.getInstance();
        objTawtheeqEnrollmentSRHandler.validateCaseForNextReview(cs);
    }
}