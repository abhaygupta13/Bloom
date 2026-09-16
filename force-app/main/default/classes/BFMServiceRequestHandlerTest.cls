/*****************************************************************************************
Class       : BFMServiceRequestHandlerTest
Author      : Vikas Baliyan
Description : BFMServiceRequestHandlerTest Class 
Test Class  : 
Created Date: 12 Mar 2025 
*****************************************************************************************/

@IsTest
public class BFMServiceRequestHandlerTest {
    
    @TestSetup
    private static void createTestData() {
        Account acc = TestDataFactory.createBrokerAccount('test', false, '1122334455');
        insert acc;

        Contact con = TestDataFactory.createContact('lname', acc.Id, true, 'test@gmail.com');
        insert con;

        Opportunity opp = TestDataFactory.createOpportunity(null, null,null, acc.Id, null, null, null, null);
        insert opp;

        Project__c project = TestDataFactory.createProject('Project Test', Date.newinstance(2024, 01, 01), Date.newInstance(2025, 01, 01), Date.newInstance(2025, 01, 15), Date.newInstance(2025, 01, 16), Date.newInstance(2025, 01, 30), Date.newInstance(2025, 02, 01));
        project.FMRecipientEmail__c = 'test@gmail.com';
        insert project;

        Unit__c unit = TestDataFactory.createUnit(project.Id, 'Test unit', 'Sold');
        insert unit;

        SalesOrder__c salesOrder = TestDataFactory.createSalesOrder(acc.Id, opp.Id, 'Sold', date.newinstance(2025, 02, 10), unit.Id, 18181818);
        insert salesOrder;

        List<Case> caseList = new List<Case>();
        for(Integer i=0; i<20; i++){
            Case caseObj = TestDataFactory.createBFMCase('Email', 'New', 'Test description', 'Test Subject',null,'test@gmail.com','0123456789');
            caseObj.AccountId = acc.Id;
            caseObj.CommunicationChannel__c = 'Email;SMS;WhatsApp';
            caseObj.RequesterEmail__c = 'test@gmail.com';
            caseList.add(caseObj);
        }
        insert caseList;
        
        ServiceCatalog__c sc = new ServiceCatalog__c(RecordTypeDevName__c = 'BFMServiceRequest', Category__c = 'BFM Service', SubCategory__c = 'BFM Service Request', ProcessType__c = 'Sales', Type__c = 'Service Request');
        insert sc;
        
        ServiceCatalog__c sc2 = new ServiceCatalog__c(RecordTypeDevName__c = 'Common_Area_Request', Category__c = 'Community Service Request', SubCategory__c = 'Common Area Service Request', ProcessType__c = 'Sales', Type__c = 'Service Request');
        insert sc2;
        
        SMSTemplate__c smsTemp = new SMSTemplate__c(Name = 'BFM SR Create Notification',SenderNumber__c = '1234567890',Body__c = 'Hello {0}');
        insert smsTemp;

        WhatsAppTemplate__c waTemp = new WhatsAppTemplate__c( Name = 'BFM SR Create Notification', SenderNumber__c = '1234567890', Body__c = 'Hello {0}', DynamicParams__c = '{0}', TemplateAPIName__c = 'test_template', Language__c = 'en');
        insert waTemp;
    }

    @IsTest
    private static void testValidateEligibility() {
        List<Case> caseList = [SELECT Id,Status,Origin,Subject,Description,AccountId
                                FROM Case LIMIT 1];
        Test.startTest();
            BFMServiceRequestHandler handler = BFMServiceRequestHandler.getInstance();
            String msg = handler.validateEligibility(caseList[0]);
        Test.stopTest();
        Assert.areEqual(true,String.isBlank(msg),'Their should be an error msg');
    }

    @IsTest
    private static void testConvertToBFMServiceRequest() {
        List<Case> caseList = [SELECT Id,AccountId,RequesterEmail__c,RequesterContactNumber__c FROM Case LIMIT 1];
        List<ServiceCatalog__c> scList = [SELECT Id,RecordTypeDevName__c FROM ServiceCatalog__c LIMIT 1];
        Test.startTest();
            BFMServiceRequestHandler handler = BFMServiceRequestHandler.getInstance();
            Map<String, String> outputMap = handler.convertToBFMServiceRequest(caseList[0].Id, scList[0] , caseList[0].AccountId, null,null,null,'Email');
        Test.stopTest();
        Assert.areEqual(false,outputMap.isEmpty(),'Their should be some values in map');
        Assert.areEqual('success',outputMap.get('status'),'Status should be success');
    }

    @IsTest
    private static void testGetDefaultValues(){
        List<SalesOrder__c> soList = [SELECT Id, Account__c, Unit__c, Unit__r.Name,Account__r.Id FROM SalesOrder__c LIMIT 1];
        List<ServiceCatalog__c> scList = [SELECT Id,SubCategory__c,RecordTypeDevName__c FROM ServiceCatalog__c LIMIT 1];
        List<Case> caseList = [SELECT Id,AccountId FROM Case LIMIT 1];
        Test.startTest();
            BFMServiceRequestHandler handler = BFMServiceRequestHandler.getInstance();
            Case caseObj = handler.createCaseRecord(soList[0], scList[0], caseList[0].AccountId, null,null,null,'Email',null,false);
        Test.stopTest();
    }

    @IsTest
    private static void testCreateCommonAreaCase(){
        Community__c community = new Community__c();
        community.Name = 'Test Community';
        insert community;

        CommonArea__c commonArea = new CommonArea__c();
        commonArea.Community__c = community.Id;
        commonArea.Name = 'Test Common Area';
        insert commonArea;

        List<ServiceCatalog__c> scList = [SELECT Id,SubCategory__c,RecordTypeDevName__c FROM ServiceCatalog__c WHERE RecordTypeDevName__c = 'Common_Area_Request' LIMIT 1];
        List<Case> caseList = [SELECT Id,AccountId FROM Case LIMIT 1];
        Test.startTest();
            BFMServiceRequestHandler handler = BFMServiceRequestHandler.getInstance();
            Case caseObj = handler.createCaseRecord(null, scList[0], caseList[0].AccountId, null,'Service Request','Test Description','Email',commonArea.Id, false);
            handler.sendBFMCaseCreationORClosureEmail(new List<Id>{caseObj.Id});
            handler.sendBFMCaseCreationORClosureNotification(new List<Id>{caseObj.Id});
        Test.stopTest();
        List<Case> casesList = [SELECT Id FROM Case WHERE RecordType.DeveloperName = 'Common_Area_Request'];
        Assert.areEqual(1,casesList.size(),'Their should be one common area record.');
    }

    @IsTest
    private static void testValidateBFMEligibility(){
        List<Case> caseList = [SELECT Id,SubType__c,Unit__c,AccountId,Subject,RequesterRemarks__c,RequesterName__c,RequesterEmail__c,RequesterContactNumber__c,Priority,Type,Category__c,SubCategory__c,Origin,Area__c FROM Case LIMIT 1];
        Test.startTest();
            BFMServiceRequestHandler handler = BFMServiceRequestHandler.getInstance();
            String str = handler.validateBFMEligibility(caseList[0]);
        Test.stopTest();
        Assert.areEqual(true,String.isNotBlank(str),'Their should be some values in error string');
    }

    @IsTest
    private static void testGetIntegrationRecordObj(){
        List<Case> caseList = [SELECT Id FROM Case LIMIT 1];
        Case caseRec = CaseService.getInstance().getCaseById(caseList[0].Id);
        Test.startTest();
            BFMServiceRequestHandler handler = BFMServiceRequestHandler.getInstance();
            IntegrationRecord__c intRecord = handler.getIntegrationRecordObj(caseRec);
        	handler.getPriorityBySubCategory();
        Test.stopTest();
        Assert.areNotEqual(null,intRecord,'Integration Record should not be null');
    }

    @IsTest
    private static void testHandleSubmitCaseComment(){
        List<Case> caseList = [SELECT Id FROM Case LIMIT 1];
        Case caseRec = CaseService.getInstance().getCaseById(caseList[0].Id);
        Test.startTest();
            BFMServiceRequestHandler handler = BFMServiceRequestHandler.getInstance();
            handler.handleSubmitCaseComment(caseRec.Id, 'test');
        Test.stopTest();
        List<IntegrationRecord__c> integrationList = [SELECT Id FROM IntegrationRecord__c];
    }
    
	
	@IsTest
    private static void testHandleSendToBFM(){
        Test.startTest();
        	Unit__c u = [SELECT Id FROM Unit__c LIMIT 1];
        	Project__c project = [SELECT Id,FMRecipientEmail__c FROM Project__c LIMIT 1];
            Case caseBFMObj = TestDataFactory.createBFMCase('Email', 'New', 'Test description', 'Test Subject',null,'testBFM@gmail.com','0123456789');
            caseBFMObj.SubType__c = 'MAINTENANCE';
        	caseBFMObj.Category__c = 'AC Systems';
            caseBFMObj.SubCategory__c = 'Others';
        	caseBFMObj.RequesterRemarks__c = 'Others';
      	 	caseBFMObj.RequesterName__c = 'Others';
        	caseBFMObj.RequesterRemarks__c = 'Others';
        	caseBFMObj.Area__c = 'Others';
        	caseBFMObj.Unit__c = u.Id;caseBFMObj.Project__c = project.Id;caseBFMObj.Type = 'AUDIT';
        	caseBFMObj.RecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType,'BFMServiceRequest');
            insert caseBFMObj;
            BFMServiceRequestHandler handler = BFMServiceRequestHandler.getInstance();
            handler.handleSendToBFM(caseBFMObj.Id);
        Test.stopTest();
        List<Case> caseList = [SELECT Id,Priority FROM Case WHERE RequesterEmail__c = 'testBFM@gmail.com' LIMIT 1];
        Assert.areEqual('P3',caseList[0].Priority,'Priority should be P3');
    }    
    
}