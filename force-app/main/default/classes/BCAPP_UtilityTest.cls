@IsTest
public class BCAPP_UtilityTest {

        @IsTest
    static void testgetInstance() {
        
        BCAPP_Utility.getInstance();
        
    }
    
        @IsTest
    static void testgetRecords() {
        try{
        BCAPP_Utility.getInstance().getRecords('Case',new List<String>{'Name'},'');
        }catch(exception e){}
    }
    
    @testSetup static void setup() {

        Account accountRecord =BCAPP_TestDataFactory.createAccount('Test Account');
        accountRecord.Azure_UserPrincipal_Id__c='testttt';
        insert accountRecord;
        
        Contact cntRecord= BCAPP_TestDataFactory.createContact(accountRecord.id,'ewew@dasds.com');
        insert cntRecord;
        Service_Contract__c Service_Contract=  BCAPP_TestDataFactory.createServiceContract();
        Service_Contract.Customer_Name__c=accountRecord.id;
        insert Service_Contract;
        
        Service_Catalog__c testServiceCatalog =BCAPP_TestDataFactory.createServiceCatalog();
        insert testServiceCatalog;
        
        Service_Catalog_Fields__c testServiceCatalogFields =BCAPP_TestDataFactory.createserviceCatalogFields();
        testServiceCatalogFields.Service_Catalog__c=testServiceCatalog.id;
        testServiceCatalogFields.User_Type__c  ='Tenant';
        insert testServiceCatalogFields;
        
        Case testCase =BCAPP_TestDataFactory.createCase();
        String RecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Move In Holiday Homes').getRecordTypeId();
        testCase.RecordTypeId=RecordTypeCaseId;
        testCase.AccountId= accountRecord.id;
        testCase.Move_Out_Date__c=system.today();
        testCase.Service_Catalog__c=testServiceCatalog.id;
        testCase.Email_Address__c='testuser@fff.com';
        insert testCase;
        
        Service_Catolog_Documents__c testService_Catolog_Documents =BCAPP_TestDataFactory.createServiceCatalogDocuments();
        testService_Catolog_Documents.Service_Catalog__c=testServiceCatalog.id;
        insert testService_Catolog_Documents;
        
        Customer_Document__c custDocs=BCAPP_TestDataFactory.createCustomerDocument();
        custDocs.Service_Catolog_Documents__c = testService_Catolog_Documents.Id;
        insert custDocs;
        User__c userRecord= BCAPP_TestDataFactory.createUser('testttt');
        userRecord.Email__c=testCase.Email_Address__c;
        userRecord.Account__c=accountRecord.id;
        userRecorD.User_Type__c=BCAPP_Constants.TENANT;
        userRecord.User_Account__c=accountRecord.id;
        userRecord.Azure_UserId__c='test';
        insert userRecord;
        
        Project__c testProject=new Project__c(
            Name='Test Project'
        );
        insert testProject;
        
        Service_Availability_Community__c inst=new Service_Availability_Community__c();
        inst.Service_Catalog__c=testServiceCatalog.id;
        inst.Required_For__c='Tenant';
        inst.Service_Catolog_Documents__c=testService_Catolog_Documents.Id;
        inst.Project__c=testProject.id;
        insert inst;
        
        Unit__c unit= BCAPP_TestDataFactory.createUnit();
        insert unit;
}
    
      @IsTest
    static void testgetCurrentUserLocalTime() {
            BCAPP_Utility.getInstance().getCurrentUserLocalTime();
    }  
    
         @IsTest
    static void testparseMultiPicklist() {
            BCAPP_Utility.getInstance().parseMultiPicklist('test;yrdyd');
    }  
    
        
    @IsTest
    static void testprocessDocuments() {
      
         BCAPP_WrapperUtility.Document instance=new BCAPP_WrapperUtility.Document();
        instance.fileName = 'TestDoc1.pdf';
        instance.fileContent = Blob.valueOf('Test Content 1');
        
        List<BCAPP_WrapperUtility.Document> wrapper = new List<BCAPP_WrapperUtility.Document>{instance};
            BCAPP_Utility.getInstance().processDocuments(wrapper,[select id from case limit 1].id,[select id from Service_Catolog_Documents__c limit 1].Id);
    }
     @IsTest
    static void testgetUserbyAccountId() {
            BCAPP_Utility.getInstance().getUserbyAccountId([select id from Account limit 1].id);
    }
     @IsTest
    static void testgetUser() {
        BCAPP_Utility.getUser('test');
    }
    
    @IsTest
    static void testgetUserbyEmail() {
        BCAPP_Utility.getInstance().getUserbyEmail('testuser@fff.com');
    }  
        @IsTest
    static void testgetRequiredDocuments() {
        BCAPP_Utility.getInstance().getRequiredDocuments([select id from Project__c limit 1].id,'Tenant',[select id from Service_Catalog__c limit 1].Id,true);
    } 
    
       @IsTest
    static void testgetFileUrls() {
        BCAPP_Utility.getInstance().getFileUrls(new List<Id>{[select id from Case limit 1].id});
    }
    
    
     @IsTest
    static void testsendEmail() {
        BCAPP_Utility.getInstance().sendEmail('Reject_Moveout_request_to_Applicant',new List<string>{'rerer@sadd.com'}, [select id from Case limit 1].id);
    } 



     @IsTest
    static void testsendCustomEmail() {
        BCAPP_Utility.getInstance().sendCustomEmail(new List<string>{'rerer@sadd.com'}, [select id from Case limit 1].id,'Reject_Moveout_request_to_Applicant','Reject_Moveout_request_to_Applicant','Reject_Moveout_request_to_Applicant');
    } 
    
    
    @IsTest
    static void testcheckDuplicateRequest() {
        BCAPP_Utility.getInstance().checkDuplicateRequest('test@ddd.com', [select id from Unit__c limit 1].id,'Move In', new List<string>{'Draft'});
    } 
    
      @IsTest
    static void testgetServiceCatalogActionItems() {
        BCAPP_Utility.getInstance().getServiceCatalogActionItems([select id from Service_Catalog__c limit 1].id);
    } 
       @IsTest
    static void testchangeCaseAssigment() {
        BCAPP_Utility.getInstance().changeCaseAssigment([select id from Service_Catalog__c limit 1].id);
    } 
    
      @IsTest
    static void testgetServiceCatalogFieldMapping() {
        BCAPP_Utility.getInstance().getServiceCatalogFieldMapping([select id from Service_Catalog__c limit 1].id,'Tenant');
    } 
    
    

    @isTest
    static void testGetQuarterDateRange_ValidInputs() {
        
        BCAPP_Utility.getInstance().getQuarterDateRange('Quarter1 2023');
        BCAPP_Utility.getInstance().getQuarterDateRange('Quarter2 2023');
        BCAPP_Utility.getInstance().getQuarterDateRange('Quarter3 2023');
        BCAPP_Utility.getInstance().getQuarterDateRange('Quarter4 2023');
    }

    
    
     @IsTest
    static void testsendEmail1() {
        try{
        BCAPP_Utility.sendEmail('Reject_Moveout_request_to_Applicant', [select id from Contact limit 1].id,'rerer@sadd.com',new List<string>{'rerer@sadd.com'}, [select id from Case limit 1].id,[select id from OrgWideEmailAddress limit 1 ].id);
        }catch(exception e){}
        }
        
    
     @IsTest
    static void testsendEmail1Wrapper() {
        
        BCAPP_Utility.EmailRequest emailRequst=new BCAPP_Utility.EmailRequest('Reject_Moveout_request_to_Applicant',null,new List<string>{'rerer@sadd.com'},new List<string>{'rerer@sadd.com'}, [select id from Case limit 1].id,[select id from OrgWideEmailAddress limit 1 ].id);
        BCAPP_Utility.sendEmail(new List<BCAPP_Utility.EmailRequest>{emailRequst});
    } 
    
    
      @IsTest
    static void testgetDateRange() {
        try{
     BCAPP_Utility.getInstance().getDateRange('Case','CreatedDate', Schema.SObjectType.Case.getRecordTypeInfosByName().get('Move In').getRecordTypeId());    
        }catch(exception e){}
    } 
    
    @IsTest
    static void testgetQuarterlyOptions() {
     BCAPP_Utility.getQuarterlyOptions(system.today(),system.today().adddays(23));    

    } 
        @IsTest
    static void testparseDate() {
      BCAPP_Utility.getInstance().parseDate('01-Jan-2026');    

    }
    
    @IsTest
    static void testEncryptId() {
        Test.startTest();
            Account acc = [select id from Account limit 1];
            String encryptedId = BCAPP_Utility.encryptId(acc.Id);
            String decryptedId = BCAPP_Utility.decryptId(encryptedId);
        Test.stopTest();
        Assert.areEqual(decryptedId, acc.id, 'Decryption not working');
    }
    
    @IsTest
    static void testGenerateRandomPassword() {
        Test.startTest();
            BCAPP_Utility util = new BCAPP_Utility();
            String password = util.generateRandomPassword();
        Test.stopTest();
        Assert.areNotEqual(null, password, 'Password should not be null');
    }
    
    
    
    
    
    
    
    
        
    
    
     
    
    
    
}