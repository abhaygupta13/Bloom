/*
* @Author : Jayprakash Bharti
* @CreatedDate : 8th Sept 2024
* @Description : 
*/
/*****************************************************************************************************
* Version       Author      Date             Comment       
* 1.0           Jayprakash  8Sept2024        
*****************************************************************************************************/
@isTest
public class LeadConversionControllerTest {
    private static final string ACCOUNT_RT_DEV_NAME_PERSON_ACCOUNT { get { return 'PersonAccount'; } }
    private static final string ACCOUNT_RT_DEV_NAME_ORGANIZATION_ACCOUNT { get { return 'OrganizationAccount'; } }
    
    @TestSetup static void testDataSetup() {
        Profile profileDetail = [SELECT Id FROM Profile WHERE Name='Sales Manager'];
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        
        User userRecord = new User(Alias = 'Zaki', Email='Zakial@gmail.com', 
                                   EmailEncodingKey='UTF-8', LastName='Zaki Al Bakri', LanguageLocaleKey='en_US', 
                                   LocaleSidKey='en_US', ProfileId = profileDetail.id, 
                                   TimeZoneSidKey='Asia/Dubai', UserName= uniqueName+'@mail.com',SAP_BP_No__c='0');
        insert userRecord;
    }
    
    
   @isTest 
    static void TestMethodOne(){
        Test.startTest();
        
        User usrSM= [Select id,name from user where email='Zakial@gmail.com'];
        
        Id personAccountRecordTypeId = Utility.getRecordTypeIdByDevName(Account.SObjectType, ACCOUNT_RT_DEV_NAME_PERSON_ACCOUNT);
        Account testAccount=new Account(
            LastName= 'test',
            Emirates_Id__pc ='1234',
            PassportNumber__pc='5678',
            Nationality__pc='india',
            recordTypeId= personAccountRecordTypeId,
            PersonMobilePhone  = '12345678',
            PersonEmail = 'test@gmail.com'
        );
        insert testAccount;
        
        
        Lead testLead = TestDataFactory.createLead('TestLead', '37829292020','testlead@example.com');
        testLead.recordTypeId =Utility.getRecordTypeIdByDevName(Lead.SObjectType,'IndividualLead');
        testLead.FirstName='one';
        testLead.LastName='TestLead';
        testLead.ResidentStatus__c='Resident'; 
        testLead.CustomerType__c='GCC';
        TestLead.CustomerSubType__c='CORPORATE';
        testLead.Street='street1';
        testLead.LeadTeam__c = 'Sales';
        testLead.NameArabic__c='Arabic';
        testLead.PostalCode='PostalCode';
        testLead.LeasingDocumentsReceived__c = 'No';
        testLead.Passport_Number__c = '123456';
        testLead.Emirates_Id__c='Emirates_Id__c'; 
        testLead.CustomerBudget__c='1M-3M';
        testLead.AreaSqmt__c = '65-110 SQM';
        testLead.OwnerId= usrSM.id;
        insert testLead; 
        try {
            LeadConversionController.vaidateLead(testLead.id);
        } catch (AuraHandledException e) {
        }
        
        LeadConversionController.convertLead(testLead.id, testAccount.id);
        Test.stopTest();
    }
    
   	@isTest static void TestMethodTwo(){
        Test.startTest();
        Id organizationAccountRecordTypeId = Utility.getRecordTypeIdByDevName(Account.SObjectType, ACCOUNT_RT_DEV_NAME_ORGANIZATION_ACCOUNT);
        
        Account tempAccOrg=new Account(
            Name= 'test11',
            recordTypeId= organizationAccountRecordTypeId,
            Trade_License_No__c='trandeno',
            Registration_Authority__c ='athority'
        );
        insert tempAccOrg;
        
        contact cc = new contact();
        cc.AccountId= tempAccOrg.id;
        cc.LastName ='Test';
        cc.FirstName='1';
        cc.Email= 'test@testemailtest.com';
        insert cc;
        
        
        Opportunity tempOpp=new Opportunity(
            Name='tempOpp',
            StageName='New',
            CloseDate=system.today(),
            LeadChannel__c='Walk in',
            AccountId=tempAccOrg.Id,
            WinReason__c='Loyalty'
        );
        insert tempOpp;
        
        
        Lead testLead1 = TestDataFactory.createLead('TestLead2', '372920202','tes345ad@example.com2');
        testLead1.recordTypeId =Utility.getRecordTypeIdByDevName(Lead.SObjectType,'OrganizationLead');
        testLead1.Company='Vodafone';
        testLead1.FirstName='two';
        testLead1.LastName='TestLead2';
        testLead1.NameArabic__c='Arabic2';
        testLead1.Emirates_Id__c='Emirates_Id__c2'; 
        testLead1.CustomerBudget__c='1M-3M';
        testLead1.AreaSqmt__c = '65-110 SQM';
        testLead1.LeasingDocumentsReceived__c = 'No';
        testLead1.LeadTeam__c = 'Sales';
        testLead1.TradeLicenseNumber__c='trandeno1';
        testLead1.RegistrationAuthority__c ='Department of Economic Development - Sharjah (SEDD)';
        insert testLead1; 
        LeadConversionController.vaidateLead(testLead1.id);
        try {
            LeadConversionController.convertLead(testLead1.id, tempAccOrg.id);
        } catch (AuraHandledException e) {
        }
        
        // LeadConversionController.updateOpportunity(testLead1, cc.id,tempOpp.id);
        Test.stopTest();
    }
    
    @isTest 
    static void TestMethodThree(){
        Test.startTest();
        User usrSM= [Select id,name from user where email='Zakial@gmail.com'];
        
        Id personAccountRecordTypeId = Utility.getRecordTypeIdByDevName(Account.SObjectType, ACCOUNT_RT_DEV_NAME_PERSON_ACCOUNT);
        Account testAccount1=new Account(
            LastName= 'test',
            Emirates_Id__pc ='1234',
            PassportNumber__pc='5678',
            Nationality__pc='india',
            recordTypeId= personAccountRecordTypeId,
            PersonMobilePhone  = '12345678',
            PersonEmail = 'test@gmail.com'
        );
        insert testAccount1;
        id recordTypeIdoflead =Utility.getRecordTypeIdByDevName(Lead.SObjectType,'IndividualLead');
        Lead testLead = TestDataFactory.createLead('TestLead', '37829292020','testlead@example.com');
        testLead.recordTypeId =Utility.getRecordTypeIdByDevName(Lead.SObjectType,'IndividualLead');
        insert testLead; 
        try {
            LeadConversionController.vaidateLead(testLead.id);
        } catch (AuraHandledException e) {
        }
        
        Test.stopTest();
    }
    @isTest static void TestMethodfour(){
        Test.startTest();
        Id organizationAccountRecordTypeId = Utility.getRecordTypeIdByDevName(Account.SObjectType, ACCOUNT_RT_DEV_NAME_ORGANIZATION_ACCOUNT);
        
        Account tempAccOrg1=new Account(
            Name= 'test11',
            recordTypeId= organizationAccountRecordTypeId,
            Trade_License_No__c='trandeno',
            Registration_Authority__c ='athority'
        );
        insert tempAccOrg1;
        
        Lead testLead1 = TestDataFactory.createLead('TestLead2', '372920202','tes345ad@example.com2');
        testLead1.recordTypeId =Utility.getRecordTypeIdByDevName(Lead.SObjectType,'OrganizationLead');
        insert testLead1; 
        LeadConversionController.vaidateLead(testLead1.id);    
        Test.stopTest();
    }
    @isTest static void testMethodsix(){
        Test.startTest();
        // Create a basic HTML Email Template
        
        
        
        User usrSM= [Select id,name from user where email='Zakial@gmail.com'];
        System.runAs(usrSM) {
            
            EmailTemplate et = new EmailTemplate();
            et.isActive = true;
            et.Name = 'LeasingDocumentsUpload';
            et.DeveloperName = 'LeasingDocumentsUpload' ;
            et.TemplateType = 'text';
            et.FolderId = UserInfo.getUserId();
            et.HtmlValue = '<p>Hi uploadhere </p>' ;
            
            insert et;  
        }
        Id personAccountRecordTypeId = Utility.getRecordTypeIdByDevName(Account.SObjectType, ACCOUNT_RT_DEV_NAME_PERSON_ACCOUNT);
        Account testAccount=new Account(
            LastName= 'test',
            Emirates_Id__pc ='1234',
            PassportNumber__pc='5678',
            Nationality__pc='india',
            recordTypeId= personAccountRecordTypeId,
            PersonMobilePhone  = '12345678',
            PersonEmail = 'test@gmail.com'
        );
        insert testAccount;
        
        
        Lead testLead = TestDataFactory.createLead('TestLead', '37829292020','testlead@example.com');
        testLead.recordTypeId =Utility.getRecordTypeIdByDevName(Lead.SObjectType,'IndividualLead');
        testLead.FirstName='one';
        testLead.LastName='TestLead';
        testLead.ResidentStatus__c='Resident'; 
        testLead.CustomerType__c='GCC';
        TestLead.CustomerSubType__c='CORPORATE';
        testLead.Street='street1';
        testLead.NameArabic__c='Arabic';
        testLead.PostalCode='PostalCode';
        testLead.Emirates_Id__c='Emirates_Id__c'; 
        testLead.CustomerBudget__c='1M-3M';
        testLead.LeasingDocumentsReceived__c = 'No';
        testLead.AreaSqmt__c = '65-110 SQM';
        testLead.OwnerId= usrSM.id;
        testLead.LeadTeam__c = 'Leasing';
        insert testLead; 
        
        Opportunity tempOpp=new Opportunity(
            Name='tempOpp',
            StageName='New',
            CloseDate=system.today(),
            LeadChannel__c='Walk in',
            AccountId=testAccount.Id,
            WinReason__c='Loyalty'
        );
        insert tempOpp;
        try {
            // LeadConversionController.vaidateLead(testLead.id);
            LeadConversionController.sendDocUploadLinkToCustomer(tempOpp.id);
        } catch (AuraHandledException e) {
        }
        Test.stopTest();
    }
    
    @isTest static void testMethodfive(){
        Test.startTest();
        // Create a basic HTML Email Template
        
        
        
        User usrSM= [Select id,name from user where email='Zakial@gmail.com'];
        System.runAs(usrSM) {
            
            EmailTemplate et = new EmailTemplate();
            et.isActive = true;
            et.Name = 'LeasingDocumentsUpload';
            et.DeveloperName = 'LeasingDocumentsUpload' ;
            et.TemplateType = 'text';
            et.FolderId = UserInfo.getUserId();
            et.HtmlValue = '<p>Hi uploadhere </p>' ;
            
            insert et;  
        }
        Id personAccountRecordTypeId = Utility.getRecordTypeIdByDevName(Account.SObjectType, ACCOUNT_RT_DEV_NAME_PERSON_ACCOUNT);
        Account testAccount=new Account(
            LastName= 'test',
            Emirates_Id__pc ='1234',
            PassportNumber__pc='5678',
            Nationality__pc='india',
            recordTypeId= personAccountRecordTypeId,
            PersonMobilePhone  = '12345678',
            PersonEmail = 'test@gmail.com'
        );
        insert testAccount;
        
        
        Lead testLead = TestDataFactory.createLead('TestLead', '37829292020','testlead@example.com');
        testLead.recordTypeId =Utility.getRecordTypeIdByDevName(Lead.SObjectType,'IndividualLead');
        testLead.FirstName='one';
        testLead.LastName='TestLead';
        testLead.ResidentStatus__c='Resident'; 
        testLead.CustomerType__c='GCC';
        TestLead.CustomerSubType__c='CORPORATE';
        testLead.Street='street1';
        testLead.NameArabic__c='Arabic';
        testLead.PostalCode='PostalCode';
        testLead.Emirates_Id__c='Emirates_Id__c'; 
        testLead.CustomerBudget__c='1M-3M';
        testLead.LeasingDocumentsReceived__c = 'No';
        testLead.AreaSqmt__c = '65-110 SQM';
        testLead.OwnerId= usrSM.id;
        testLead.LeadTeam__c = 'Leasing';
        insert testLead; 
        
        
        try {
            // LeadConversionController.vaidateLead(testLead.id);
            LeadConversionController.getDuplicateAccount(testLead, testLead.recordTypeId, testLead.recordTypeId);
        } catch (AuraHandledException e) {
        }
        Test.stopTest();
    }
    
  /*  @isTest static void TestMethodSeven(){
        Test.startTest();
        Id organizationAccountRecordTypeId = Utility.getRecordTypeIdByDevName(Account.SObjectType, ACCOUNT_RT_DEV_NAME_ORGANIZATION_ACCOUNT);
        
        Account tempAccOrg=new Account(
            Name= 'test11',
            recordTypeId= organizationAccountRecordTypeId,
            Trade_License_No__c='trandeno',
            Registration_Authority__c ='athority'
        );
        insert tempAccOrg;
        
        contact cc = new contact();
        cc.AccountId= tempAccOrg.id;
        cc.LastName ='Test';
        cc.FirstName='1';
        insert cc;
        
        
        Opportunity tempOpp=new Opportunity(
            Name='tempOpp',
            StageName='New',
            CloseDate=system.today(),
            LeadChannel__c='Walk in',
            AccountId=tempAccOrg.Id,
            WinReason__c='Loyalty'
        );
        insert tempOpp;
        
        
        Lead testLead1 = TestDataFactory.createLead('TestLead2', '372920202','tes345ad@example.com2');
        testLead1.recordTypeId =Utility.getRecordTypeIdByDevName(Lead.SObjectType,'IndividualLead');
        testLead1.RegistrationAuthority__c ='Department of Economic Development - Sharjah (SEDD)';
        insert testLead1; 
        try {
            LeadConversionController.vaidateLead(testLead1.id);
        } catch (AuraHandledException e) {
        }
        
        // LeadConversionController.updateOpportunity(testLead1, cc.id,tempOpp.id);
        Test.stopTest();
    }*/
    
    @isTest static void testMethodvalid(){
        Test.startTest();
        // Create a basic HTML Email Template
        
        
        
        User usrSM= [Select id,name from user where email='Zakial@gmail.com'];
        System.runAs(usrSM) {
            
            EmailTemplate et = new EmailTemplate();
            et.isActive = true;
            et.Name = 'LeasingDocumentsUpload';
            et.DeveloperName = 'LeasingDocumentsUpload' ;
            et.TemplateType = 'text';
            et.FolderId = UserInfo.getUserId();
            et.HtmlValue = '<p>Hi uploadhere </p>' ;
            
            insert et;  
        }
        Id personAccountRecordTypeId = Utility.getRecordTypeIdByDevName(Account.SObjectType, ACCOUNT_RT_DEV_NAME_PERSON_ACCOUNT);
        Account testAccount=new Account(
            LastName= 'test',
            Emirates_Id__pc ='1234',
            PassportNumber__pc='5678',
            Nationality__pc='india',
            recordTypeId= personAccountRecordTypeId,
            PersonMobilePhone  = '12345678',
            PersonEmail = 'test@gmail.com'
        );
        insert testAccount;
        
        
        Lead testLead = TestDataFactory.createLead('TestLead34', '37829292000','testlead@example.com');
        testLead.recordTypeId =Utility.getRecordTypeIdByDevName(Lead.SObjectType,'IndividualLead');
        testLead.FirstName='one';
        testLead.LastName='TestLead';
        testLead.ResidentStatus__c='Resident'; 
        testLead.CustomerType__c='GCC';
        TestLead.CustomerSubType__c='CORPORATE';
        testLead.Street='street1';
        testLead.NameArabic__c='Arabic';
        testLead.PostalCode='PostalCode';
        testLead.Emirates_Id__c='Emirates_Id__c'; 
        testLead.CustomerBudget__c='1M-3M';
        testLead.AreaSqmt__c = '65-110 SQM';
        testLead.OwnerId= usrSM.id;
        testLead.LeasingDocumentsReceived__c = 'Yes';
        testLead.LeadTeam__c = 'Leasing';
        insert testLead; 
        try {
            LeadConversionController.vaidateLead(testLead.id);
        } catch (AuraHandledException e) {
        }
        
        
    }
    
    @IsTest
    static void testBrokerAgentEmailCondition() {
        Test.startTest();
        User usrSM = [SELECT Id, Name FROM User WHERE Email = 'Zakial@gmail.com' LIMIT 1];
        
        // ===== Create Broker Agency Account =====
        Id brokerAgencyRT = Utility.getRecordTypeIdByDevName(Account.SObjectType, 'Broker_Agency');
        Account brokerAgency = new Account(
            Name = 'Broker Agency Account',
            RecordTypeId = brokerAgencyRT
        );
        insert brokerAgency;
        
        // ===== Create Broker Agent Contact =====
        Id brokerContactRT = Utility.getRecordTypeIdByDevName(Contact.SObjectType, 'Broker');
        Contact brokerAgent = new Contact(
            LastName = 'Broker Agent',
            Email = 'brokeragent@test.com',
            RecordTypeId = brokerContactRT,
            AccountId = brokerAgency.Id
        );
        insert brokerAgent;
        
        // ===== Create Person Account =====
        Id personAccountRecordTypeId = Utility.getRecordTypeIdByDevName(Account.SObjectType, 'PersonAccount');
        Account testAccount = new Account(
            LastName = 'Test Person',
            Emirates_Id__pc = '1234',
            PassportNumber__pc = '5678',
            Nationality__pc = 'India',
            RecordTypeId = personAccountRecordTypeId,
            PersonMobilePhone = '12345678',
            PersonEmail = 'test@gmail.com'
        );
        insert testAccount;
        
        // ===== Create Lead for Conversion =====
        Id individualLeadRT = Utility.getRecordTypeIdByDevName(Lead.SObjectType, 'IndividualLead');
        Lead testLead = new Lead(
            RecordTypeId = individualLeadRT,
            FirstName = 'Broker',
            LastName = 'Lead',
            Company = 'Test Company',
            ResidentStatus__c = 'Resident',
            CustomerType__c = 'GCC',
            CustomerSubType__c = 'CORPORATE',
            Street = 'Street1',
            NameArabic__c = 'Arabic Name',
            PostalCode = 'PostalCode',
            Emirates_Id__c = '7841987654321111',
            CustomerBudget__c = '1M-3M',
            AreaSqmt__c = '65-110 SQM',
            OwnerId = usrSM.Id,
            LeasingDocumentsReceived__c = 'No',
            LeadSource = 'Social Media',
            LeadTeam__c = 'Sales',                 
            lead_channel__c = 'Broker Portal',      
            BrokerAgency__c = brokerAgency.Id,     
            BrokerAgent__c = brokerAgent.Id,        
            Status = 'Qualified',                   
            Project__c = 'Abu Dhabi',
            UnitType__c = 'Apartment',
            NumberOfBedrooms__c = '5BHK',
            ApplicationNumber__c = '112233'
        );
        insert testLead;
        
        LeadConversionController.vaidateLead(testLead.Id);
        LeadConversionController.convertLead(testLead.Id, testAccount.Id);
        Test.stopTest();
    }
    
}