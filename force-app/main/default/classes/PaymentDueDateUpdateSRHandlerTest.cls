@isTest
public class PaymentDueDateUpdateSRHandlerTest {
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
        
        PaymentPlan__c  pp = new PaymentPlan__c();
        pp.Name ='July Plan';
        pp.Unit__c= testUnit.id;
        pp.Description__c ='Test Description';
        pp.Description__c = 'Test';
        pp.IsActive__c = 'NO';
        pp.BrokerPortalFlag__c = True;
        pp.Classification__c = Constants.PAYMENT_PLAN_TYPE_STANDARD;
        
        insert pp;
        
        PaymentInstallments__c ppi = new PaymentInstallments__c();
        ppi.BrokerPayoutPercentage__c =100;
        ppi.Description__c = 'test description';
        ppi.InstallmentNumber__c = 1;
        ppi.InstallmentPercentage__c=100;
        ppi.PaymentPlan__c = pp.id;
        ppi.InstallmentPercentage__c=100;
        ppi.Condition_Type__c='P012';
        insert ppi;
        
        pp.IsActive__c = 'Yes';
        Update pp;
        
        InstallmentLines__c installmentLines = new InstallmentLines__c();
        installmentLines.PaymentPlan__c = pp.id;
        installmentLines.PaymentInstallments__c =ppi.Id;
        installmentLines.SalesOrder__c = testOrder.id;
        installmentLines.Description__c='4th Installment';
        installmentLines.InstallmentAmount__c = 100000;
        installmentLines.LPCCutOffAmt__c =0;
        installmentLines.MinInvAmtrem__c =100;
        installmentLines.LPCRate__c =12;
        installmentLines.InstallmentPercentage__c = 25;
        installmentLines.BrokerPayoutPercentage__c = 20;
        installmentLines.Description__c = 'Description';
        installmentLines.RevisedDate__c=null;
        installmentLines.GracePeriod__c=1;
        installmentLines.InstallmentAmount__c =70000;
        installmentLines.Inst_inc_tax_in_words__c  = '';
        installmentLines.InstallmentDate__c= Date.today() + 12;
        installmentLines.AmountReceived__c=1500;
        installmentLines.CutOffDate__c=date.today();
        installmentLines.LPCAmount__c=500;
        insert installmentLines;
        Test.startTest();
        
        installmentLines.Send_to_SAP__c = true;
        update installmentLines;
        Test.stopTest();

        // Create test ServiceCatalog record
        ServiceCatalog__c testServiceCatalog = new ServiceCatalog__c(
            Name = 'Test Service Catalog',
            Type__c = 'Service Request',
            Category__c = 'Financial - Payment Service',
            SubCategory__c = 'Payment Due Date Update',
            RecordTypeDevName__c = 'Payment_Due_Date_Update',
            AvailableForOwner__c = true
        );
        insert testServiceCatalog;
        system.debug('testServiceCatalog----->'+testServiceCatalog);
        
        List<ServiceAction__c> stepList = new list<ServiceAction__c>();
        // Create test ServiceAction record
        ServiceAction__c testServiceAction1 = new ServiceAction__c(
            ServiceCatalog__c = testServiceCatalog.Id,
            //TaskType__c = 'Default Unit',
            TaskSubType__c = 'CRM Team Task',
            TaskSubject__c = 'CRM Team Task',
            Order__c = 1,
            FinalTask__c = true
        );
        stepList.add(testServiceAction1);
        insert stepList;

        List<DocumentType__c> docList = new List<DocumentType__c>();
        DocumentType__c doc1 = new DocumentType__c(ObjectType__c = 'Case',
                                        RecordTypeDevName__c = 'Payment_Due_Date_Update',
                                        Type__c = 'SOA',
                                        Active__c = true);
        docList.add(doc1);
        insert docList;
    }

    @isTest
    static void validatyTest(){
        SalesOrder__c so = [Select id,Status__c,IsDefaulted__c from Salesorder__c limit 1];
        PaymentDueDateUpdateSRHandler.getInstance().validateEligibility(so);
    }
    @isTest
    static void createCaseTest(){
        SalesOrder__c so = [Select id,Account__c,Unit__c from Salesorder__c limit 1];
        ServiceRequestController.createCaseRecord(so.id,'Service Request','Financial - Payment Service','Payment Due Date Update',so.Account__c,so.Unit__c,'test','Email',false);
    }
    @isTest
    static void validateCaseTest(){
        SalesOrder__c so = [Select id,Account__c,Unit__c from Salesorder__c limit 1];
        test.StartTest();
        Map<String,String> caseData = ServiceRequestController.createCaseRecord(so.id,'Service Request','Financial - Payment Service','Payment Due Date Update',so.Account__c,so.Unit__c,'test','Email',false);
        test.stopTest();
        ReviewStepValidatorController.validateForNextReview(caseData.get('caseId'));
        PaymentDueDateUpdateSRHandler i = PaymentDueDateUpdateSRHandler.getInstance();
        i.validateCaseForNextReview(null);
    }
    @isTest
    static void validateCaseTest1(){
        SalesOrder__c so = [Select id,Account__c,Unit__c from Salesorder__c limit 1];
        test.StartTest();
        Map<String,String> caseData = ServiceRequestController.createCaseRecord(so.id,'Service Request','Financial - Payment Service','Payment Due Date Update',so.Account__c,so.Unit__c,'test','Email',false);
        Case cs = [Select id, Step__c, Payment_Booked__c, Finance_Document_Verified__c, 
                   FinanceDocumentsUploadedManually__c, ServiceCatalog__c, Status,
                   CaseType__c, SubType__c, RecordTypeId, AccountId, StopEmailsToCustomer__c,
                   Sales_Order__c, TPFType__c, DocumentsVerifiedUploaded__c, POPUploaded__c,
                   Payment_Due_Date__c
                   from case where id =: caseData.get('caseId')];
        cs.step__c = '1';
        cs.Payment_Booked__c = 'Yes';
        update cs;
        test.stopTest();
        ReviewStepValidatorController.validateForNextReview(caseData.get('caseId'));
        PaymentDueDateUpdateSRHandler i = PaymentDueDateUpdateSRHandler.getInstance();
        i.validateCaseForNextReview(cs);
        cs.Step__c = '3';
        cs.TPFType__c = 'Individual';
        cs.Finance_Document_Verified__c = 'Yes';
        update cs;
        i.validateCaseForNextReview(cs);
        //cs.FinanceDocumentsUploadedManually__c = 'Yes';
        cs.Step__c = 'Final';
        cs.POPUploaded__c = 'Yes';
        cs.FinanceDocumentsUploadedManually__c = 'Yes';
        update cs;
        i.validateCaseForNextReview(cs);
    }

    @isTest
    static void validateCaseTest2(){
        SalesOrder__c so = [Select id,Account__c,Unit__c from Salesorder__c limit 1];
        test.StartTest();
        Map<String,String> caseData = ServiceRequestController.createCaseRecord(so.id,'Service Request','Financial - Payment Service','Payment Due Date Update',so.Account__c,so.Unit__c,'test','Email',false);
        Case cs = [Select id, Step__c from case where id =: caseData.get('caseId')];
        cs.step__c = 'Final';
        cs.Payment_Due_Date__c = Date.valueof(System.today()+1);
        cs.Finance_Document_Verified__c = 'Yes';
		cs.FinanceDocumentsUploadedManually__c = 'Yes';
        update cs;
        test.stopTest();
        ReviewStepValidatorController.validateForNextReview(caseData.get('caseId'));
    }
    
    @isTest
    static void validateCaseTest3(){
        SalesOrder__c so = [Select id,Account__c,Unit__c from Salesorder__c limit 1];
        test.StartTest();
        Map<String,String> caseData = ServiceRequestController.createCaseRecord(so.id,'Service Request','Financial - Payment Service','Payment Due Date Update',so.Account__c,so.Unit__c,'test','Email',false);
        Case cs = [Select id, Step__c, Payment_Booked__c, Finance_Document_Verified__c, 
                   FinanceDocumentsUploadedManually__c, ServiceCatalog__c, Status,
                   CaseType__c, SubType__c, RecordTypeId, AccountId, StopEmailsToCustomer__c,
                   Sales_Order__c, TPFType__c, DocumentsVerifiedUploaded__c, POPUploaded__c
                   from case where id =: caseData.get('caseId')];
        cs.step__c = 'Final';
        cs.Payment_Due_Date__c = Date.valueof(System.today()+1);
        cs.Finance_Document_Verified__c  = 'Yes';
        cs.FinanceDocumentsUploadedManually__c = 'Yes';
        update cs;
        test.stopTest();
        ReviewStepValidatorController.validateForNextReview(caseData.get('caseId'));
    }
    
    @isTest
    static void validateCaseTest4(){
        SalesOrder__c so = [Select id,Account__c,Unit__c from Salesorder__c limit 1];
        test.StartTest();
        Map<String,String> caseData = ServiceRequestController.createCaseRecord(so.id,'Service Request','Financial - Payment Service','Payment Due Date Update',so.Account__c,so.Unit__c,'test','Email',false);
        Case cs = [Select id, Step__c from case where id =: caseData.get('caseId')];
        cs.step__c = 'Final';
        cs.Payment_Due_Date__c = Date.valueof(System.today()+1);
        cs.Finance_Document_Verified__c = 'No';
        cs.FinanceDocumentsUploadedManually__c = 'Yes';
        update cs;
        test.stopTest();
        ReviewStepValidatorController.validateForNextReview(caseData.get('caseId'));
    }
    
    @isTest
    static void validateCaseTest5(){
        SalesOrder__c so = [Select id,Account__c,Unit__c from Salesorder__c limit 1];
        test.StartTest();
        Map<String,String> caseData = ServiceRequestController.createCaseRecord(so.id,'Service Request','Financial - Payment Service','Payment Due Date Update',so.Account__c,so.Unit__c,'test','Email',false);
        Case cs = [Select id, Step__c from case where id =: caseData.get('caseId')];
        cs.step__c = '1';
        cs.Payment_Due_Date__c = Date.valueof(System.today()+1);
        cs.Finance_Document_Verified__c = 'Yes';
		cs.FinanceDocumentsUploadedManually__c = 'No';
        update cs;
        test.stopTest();
        ReviewStepValidatorController.validateForNextReview(caseData.get('caseId'));
    }
    
     @isTest
    static void SendEmailTest() {
        // Arrange
        SalesOrder__c so = [Select id,Account__c,Unit__c from Salesorder__c limit 1];
        Map<String,String> caseData = ServiceRequestController.createCaseRecord(so.id,'Service Request','Financial - Payment Service','Payment Due Date Update',so.Account__c,so.Unit__c,'test','Email',false);
        Case caseRec = [Select Id, Step__c, Payment_Due_Date__c, AccountId from case where id =: caseData.get('caseId')];
        
        caseRec.Step__c = 'Final';
        //caseRec.PDCSentToCustomer__c = 'Yes';
        //caseRec.FinanceDocumentsUploadedManually__c= 'Yes';
        caseRec.Payment_Due_Date__c = System.today();
        update caseRec;
        PaymentDueDateUpdateSRHandler handler = PaymentDueDateUpdateSRHandler.getInstance();
        MetadataService objMetadataService = MetadataService.getInstance();
        Id emailTempId = objMetadataService.getAppSettingTextValue('NewServiceRequestClosureID');
        Id noReplyOWDId = objMetadataService.getAppSettingTextValue('BloomNoReplySalesOWEmailId');
        AccountService accService = AccountService.getInstance();
        String customerEmail = accService.getRelatedContactEmail(caseRec.AccountId);
        List<String> toAddress = new List<String>{customerEmail};
        Messaging.SingleEmailMessage email =  handler.sendClosureEmail(noReplyOWDId, caseRec.Id, toAddress, null, null,null);
        // Assert
        //System.assertEquals('success', response.get('status'), 'Status should be success');
    }
}