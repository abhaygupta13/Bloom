@isTest
public class SOARequestCaseHandlerTest{

    @TestSetup
    static void makeData(){
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
            Category__c = 'Financial - Payment Service',
            SubCategory__c = 'SOA Request',
            RecordTypeDevName__c = 'SOARequest',
            AvailableForOwner__c = true
        );
        insert testServiceCatalog;
        system.debug('testServiceCatalog----->'+testServiceCatalog);
        
        List<ServiceAction__c> stepList = new list<ServiceAction__c>();
        // Create test ServiceAction record
        ServiceAction__c testServiceAction1 = new ServiceAction__c(
            ServiceCatalog__c = testServiceCatalog.Id,
            TaskType__c = 'Default Unit',
            TaskSubType__c = 'CRM Team Task',
            TaskSubject__c = 'CRM Team Task',
            Due_in_days__c = 2,
            Order__c = 1
        ); 
        stepList.add(testServiceAction1);
        ServiceAction__c testServiceAction2 = new ServiceAction__c(
            ServiceCatalog__c = testServiceCatalog.Id,
            TaskType__c = 'Default Unit',
            TaskSubType__c = 'Finance Team Task',
            TaskSubject__c = 'FInance Team Task',
            Due_in_days__c = 2,
            Order__c = 2,
            FinalTask__c = true
        );
        stepList.add(testServiceAction2);
              
        

        insert stepList;

        List<DocumentType__c> docList = new List<DocumentType__c>();
        DocumentType__c doc1 = new DocumentType__c(ObjectType__c = 'Case',
                                        RecordTypeDevName__c = 'SOARequest',
                                        Type__c = 'Statement of Account',
                                        Active__c = true);
        docList.add(doc1);
                insert docList;
    }
    
      @isTest
    static void validatyTest(){
        SalesOrder__c so = [Select Id,Account__c,Unit__c from Salesorder__c limit 1];
        ServiceRequestController.validateEligibility(so.id,'SOA Request',so.Account__c,so.Unit__c,false);
    }
    
    @isTest
    static void createCaseTest(){
        SalesOrder__c so = [Select id,Account__c,Unit__c from Salesorder__c limit 1];
        ServiceRequestController.createCaseRecord(so.id,'Service Request','Financial - Payment Service','SOA Request',so.Account__c,so.Unit__c,'test','Email',false);
    }
    
    @isTest
    static void validateCaseTest(){
        SalesOrder__c so = [Select id,Account__c,Unit__c from Salesorder__c limit 1];
        test.StartTest();
        Map<String,String> caseData = ServiceRequestController.createCaseRecord(so.id,'Service Request','Financial - Payment Service','SOA Request',so.Account__c,so.Unit__c,'test','Email',false);
        test.stopTest();
        ReviewStepValidatorController.validateForNextReview(caseData.get('caseId'));
        SOARequestCaseHandler i = SOARequestCaseHandler.getInstance();
        i.validateCaseForNextReview(null);
    }
    
    @isTest
    static void validateCaseTest1(){
        SalesOrder__c so = [Select id,Account__c,Unit__c from Salesorder__c limit 1];
        test.StartTest();
        Map<String,String> caseData = ServiceRequestController.createCaseRecord(so.id,'Service Request','Financial - Payment Service','SOA Request',so.Account__c,so.Unit__c,'test','Email',false);
        test.stopTest();
        ReviewStepValidatorController.validateForNextReview(caseData.get('caseId'));
        Case cs = [Select id, Step__c from case where id =: caseData.get('caseId')];
        cs.step__c = '0';
        update cs;
        SOARequestCaseHandler i = SOARequestCaseHandler.getInstance();
        i.validateCaseForNextReview(cs);
    }
    @isTest
    static void validateCaseTest2(){
        SalesOrder__c so = [Select id,Account__c,Unit__c from Salesorder__c limit 1];
        test.StartTest();
        Map<String,String> caseData = ServiceRequestController.createCaseRecord(so.id,'Service Request','Financial - Payment Service','SOA Request',so.Account__c,so.Unit__c,'test','Email',false);
        test.stopTest();
        ReviewStepValidatorController.validateForNextReview(caseData.get('caseId'));
        Case cs = [Select id, Step__c from case where id =: caseData.get('caseId')];
        SOARequestCaseHandler i = SOARequestCaseHandler.getInstance();
        i.validateCaseForNextReview(cs);
    }
    @isTest
    static void validateCaseTest3(){
        SalesOrder__c so = [Select id,Account__c,Unit__c from Salesorder__c limit 1];
        test.StartTest();
        Map<String,String> caseData = ServiceRequestController.createCaseRecord(so.id,'Service Request','Financial - Payment Service','SOA Request',so.Account__c,so.Unit__c,'test','Email',false);
        test.stopTest();
        ReviewStepValidatorController.validateForNextReview(caseData.get('caseId'));
        CaseService service = CaseService.getInstance();
        case cs = service.getCaseById(caseData.get('caseId'));
        cs.step__c = '1';
        SOARequestCaseHandler i = SOARequestCaseHandler.getInstance();
        i.validateCaseForNextReview(cs);
    }
    
    @isTest
    static void validateCaseTest4(){
        SalesOrder__c so = [Select id,Account__c,Unit__c from Salesorder__c limit 1];
        test.StartTest();
        Map<String,String> caseData = ServiceRequestController.createCaseRecord(so.id,'Service Request','Financial - Payment Service','SOA Request',so.Account__c,so.Unit__c,'test','Email',false);
        test.stopTest();
        ReviewStepValidatorController.validateForNextReview(caseData.get('caseId'));
        CaseService service = CaseService.getInstance();
        case cs = service.getCaseById(caseData.get('caseId'));
        cs.step__c = 'Final';
        SOARequestCaseHandler i = SOARequestCaseHandler.getInstance();
        i.validateCaseForNextReview(cs);
    }
    
    @isTest
    static void validateCaseTest5(){
        SalesOrder__c so = [Select id,Account__c,Unit__c from Salesorder__c limit 1];
        test.StartTest();
        Map<String,String> caseData = ServiceRequestController.createCaseRecord(so.id,'Service Request','Financial - Payment Service','SOA Request',so.Account__c,so.Unit__c,'test','Email',false);
        test.stopTest();
        ReviewStepValidatorController.validateForNextReview(caseData.get('caseId'));
        CaseService service = CaseService.getInstance();
        case cs = service.getCaseById(caseData.get('caseId'));
        cs.step__c = 'Final';
        cs.IssuesWithFinancialDocument__c = 'No';
        SOARequestCaseHandler i = SOARequestCaseHandler.getInstance();
        i.validateCaseForNextReview(cs);
    }
    
    @isTest
    static void validateCaseTest6(){
        SalesOrder__c so = [Select id,Account__c,Unit__c from Salesorder__c limit 1];
        test.StartTest();
        Map<String,String> caseData = ServiceRequestController.createCaseRecord(so.id,'Service Request','Financial - Payment Service','SOA Request',so.Account__c,so.Unit__c,'test','Email',false);
        test.stopTest();
        ReviewStepValidatorController.validateForNextReview(caseData.get('caseId'));
        CaseService service = CaseService.getInstance();
        case cs = service.getCaseById(caseData.get('caseId'));
        cs.step__c = 'Final';
        cs.IssuesWithFinancialDocument__c = 'No';
        cs.FinancialDocumentAvailableInSF__c = 'Yes';
        SOARequestCaseHandler i = SOARequestCaseHandler.getInstance();
        i.validateCaseForNextReview(cs);
    }
    
    @isTest
    static void validateCaseTest7(){
        SalesOrder__c so = [Select id,Account__c,Unit__c from Salesorder__c limit 1];
        test.StartTest();
        Map<String,String> caseData = ServiceRequestController.createCaseRecord(so.id,'Service Request','Financial - Payment Service','SOA Request',so.Account__c,so.Unit__c,'test','Email',false);
        test.stopTest();
        ReviewStepValidatorController.validateForNextReview(caseData.get('caseId'));
        CaseService service = CaseService.getInstance();
        case cs = service.getCaseById(caseData.get('caseId'));
        cs.step__c = 'Final';
        cs.IssuesWithFinancialDocument__c = 'No';
        cs.FinancialDocumentAvailableInSF__c = 'No';
        SOARequestCaseHandler i = SOARequestCaseHandler.getInstance();
        i.validateCaseForNextReview(cs);
    }
    @isTest
    static void validateCaseTest8(){
        SalesOrder__c so = [Select id,Account__c,Unit__c from Salesorder__c limit 1];
        test.StartTest();
        Map<String,String> caseData = ServiceRequestController.createCaseRecord(so.id,'Service Request','Financial - Payment Service','SOA Request',so.Account__c,so.Unit__c,'test','Email',false);
        test.stopTest();
        ReviewStepValidatorController.validateForNextReview(caseData.get('caseId'));
        CaseService service = CaseService.getInstance();
        case cs = service.getCaseById(caseData.get('caseId'));
        cs.step__c = 'Final';
        cs.IssuesWithFinancialDocument__c = 'No';
        cs.FinancialDocumentAvailableInSF__c = 'No';
        cs.DocumentUploadedFromSAP__c = 'Yes';
        SOARequestCaseHandler i = SOARequestCaseHandler.getInstance();
        i.validateCaseForNextReview(cs);
    }
}