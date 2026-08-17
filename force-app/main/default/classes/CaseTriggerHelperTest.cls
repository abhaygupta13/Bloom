@isTest
public class CaseTriggerHelperTest {
    @testSetup static void setup() {
        
        Service_Catalog__c testServiceCatalog =BCAPP_TestDataFactory.createServiceCatalog();
        insert testServiceCatalog;
        
        Account accountRecord =BCAPP_TestDataFactory.createAccount('Test Account');
        accountRecord.Azure_UserPrincipal_Id__c='testttt';
        insert accountRecord;
        
        
        
        Contact cntRecord= BCAPP_TestDataFactory.createContact(accountRecord.id,'ewew@dasds.com');
        cntRecord.PrimaryContact__c=true;
        insert cntRecord;
        Service_Contract__c Service_Contract=  BCAPP_TestDataFactory.createServiceContract();
        Service_Contract.Customer_Name__c=accountRecord.id;
        insert Service_Contract;
        
        Service_Catolog_Documents__c testService_Catolog_Documents =BCAPP_TestDataFactory.createServiceCatalogDocuments();
        testService_Catolog_Documents.Service_Catalog__c=testServiceCatalog.id;
        insert testService_Catolog_Documents;
        
        Case testCase =BCAPP_TestDataFactory.createCase();
        String RecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Move In').getRecordTypeId();
        testCase.RecordTypeId=RecordTypeCaseId;
        testCase.AccountId= accountRecord.id;
        testCase.Move_Out_Date__c=system.today();
        testCase.Email_Address__c='testuser@fff.com';
        testCase.MIP_Number__c='1-1';
        testCase.type='Deletion Joint Owner';
        testCase.Service_Catalog__c=testServiceCatalog.id;
        insert testCase;
        
              
    }    
    
    @isTest static void CaseTriggerHandlerTest(){
        
        Round_Robins__c rr=new Round_Robins__c(
            Name='Service/Case Request',
            Assigned_To__c = String.valueof(1),
            Sobject__c='Case'
        );
        insert rr;
        
        Round_Robins__c Reseller=new Round_Robins__c(
            Name='Service/Resale Case Request',
            Assigned_To__c = String.valueof(1),
            Sobject__c='Case'
            
        );
        insert Reseller;
        
        Profile profileDetail = [SELECT Id FROM Profile WHERE Name='CRM Operations'];
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        
        User userRecord = new User(Alias = 'Zaki', Email='Zakial@gmail.com', 
                                   EmailEncodingKey='UTF-8', LastName='Zaki Al Bakri', LanguageLocaleKey='en_US', 
                                   LocaleSidKey='en_US', ProfileId = profileDetail.id, 
                                   TimeZoneSidKey='Asia/Dubai', UserName= uniqueName+'@mail.com');
        insert userRecord;
        User userRecord2 = new User(Alias = 'Zaki2', Email='Zakial2@gmail.com', 
                                    EmailEncodingKey='UTF-8', LastName='Zaki A2l Bakri', LanguageLocaleKey='en_US', 
                                    LocaleSidKey='en_US', ProfileId = profileDetail.id, 
                                    TimeZoneSidKey='Asia/Dubai', UserName= uniqueName+'3232'+'@mail.com');
        insert userRecord2;
        Round_Robin_User__c rrUser=new Round_Robin_User__c(
            Name='Hani Zaki Al Bakri -  SM',
            Round_Robin__c=rr.Id,
            Total_Open_Count__c=0,
            User__c=userRecord.id
            
        );
        insert rrUser;
        
        Round_Robin_User__c rrUser1=new Round_Robin_User__c(
            Name='Zaki Al Bakri -  SM',
            Round_Robin__c=rr.Id,
            Total_Open_Count__c=10,
            User__c=userRecord2.id
        );
        insert rrUser1;
        
        Id personRecId =Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        
        Account Acc = new Account();
        Acc.LastName__pc = 'Test class Account';
        Acc.LastName = 'Test class Account';
        Acc.PersonEmail='aaa@abc.com';
        Acc.PersonMobilePhone='123456789';
        //Address or Mobile Numbe
        Acc.RecordTypeId = personRecId;
        insert Acc;
        
        Opportunity opp = new Opportunity();
        opp.Name = 'Test class name';
        opp.AccountId = Acc.id;
        opp.CloseDate = system.today();
        opp.StageName = 'New';
        opp.ForecastCategoryName = 'Omitted';
        opp.LeadChannel__c = 'Call';
        opp.WinReason__c = 'Won - Special Discount';
        insert opp;
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
            Status__c='Available',
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
            // Contact__c=tempContact.id,
            Unit__c =testUnit.id,
            Account__c = Acc.Id,
            Opportunity__c=Opp.Id            
        );
        insert testOrder;
        
        
        //    Id caseRecor= Schema.SObjectType.case.getRecordTypeInfosByName().get('General_Service_Request').getRecordTypeId();
        String RecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('General Service Request').getRecordTypeId();
        Case tempCase=new Case(
            CurrencyIsoCode='AED',
            Status='Draft',
            Origin='Email',
            Main_Buyer_Share_Percentage__c=40,
            // Case_Sub_Status__c= 'Created',
            RecordTypeId=RecordTypeCaseId,
            Sales_Order__c= testOrder.id
        );
        insert tempCase;
        
        
        Account tempAcc=new Account(
            Name='test'
        );
        insert tempAcc;
        JointOwner__c tempJointOwner=new JointOwner__c(
            Account__c=tempAcc.id,
            SharePercentage__c=40,
            Case__c=tempCase.id
        );
        insert tempJointOwner;
        
        list<Case> trgNewList=new list<Case>();
        trgNewList.add(tempCase);        
        //CaseTriggerHelper.caseandJointOwnerSharePercentage(trgNewList);
        
        tempCase.Contacts_Case_Email__c='abc@xyz.com';
        update  tempCase;
        delete  tempCase;
    }
    
    
    @IsTest
    static void testhandleAssignment() {
        Service_Catalog__c testServiceCatalog =BCAPP_TestDataFactory.createServiceCatalog();
        
        Case testCase =BCAPP_TestDataFactory.createCase();
        String RecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Resale').getRecordTypeId();
        testCase.RecordTypeId=RecordTypeCaseId;
        testCase.AccountId= [select id from Account limit 1].id;
        testCase.Move_Out_Date__c=system.today();
        testCase.Email_Address__c='testuser@fff.com';
        testCase.type='Deletion Joint Owner';
        testCase.Service_Catalog__c=[select id from Service_Catalog__c limit 1].id;
        insert testCase;
        testCase.Status='Submitted';
        
        case testCaseold=new case();
        testCaseold.id=testCase.id;
        testCaseold.Status='Draft';
        
        map<id,case> caseOld=new  map<id,case>();
        caseOld.put(testCaseold.id,testCaseold);
        CaseTriggerHelper.handleAssignment(new List<Case> {testCase},caseOld);
        CaseTriggerHelper.handleSubmittedCases(new List<Case> {testCase});
        String recTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Vehicle Parking Request').getRecordTypeId();
        testCase.RecordTypeId=recTypeId;
        testCase.VehicleRegistrationStatus__c = 'Rejected';
        update testCase;
        testCase.VehicleRegistrationStatus__c = 'Approved';
        update testCase;
        //CaseTriggerHelper.handleVehicleParkingRegistrationReqAfterUpdate(new List<Case> {testCase},caseOld);
        
    }
    @IsTest
    static void testPostSaleDeferralCaseProcess() {
        // Create Contact with Email
        Contact testContact = [Select id,LastName,Email from Contact limit 1];
        Id caseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Post_Sale_Payment_Deferral').getRecordTypeId();
        Case testCase = new Case(
            CurrencyIsoCode = 'AED',
            Origin = 'Walk-In',
            RecordTypeId = caseRecordTypeId,
            CaseType__c = 'Service Request',
            ContactId = testContact.Id
        );
        test.startTest();
        insert testCase;
        test.stopTest();
    }
    @IsTest
    static void testPostSaleDeferralUpdateCaseProcess() {
        // Create Contact with Email
        Contact testContact = [Select id,LastName,Email from Contact limit 1];
        Id caseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Post_Sale_Payment_Deferral').getRecordTypeId();
        Case testCase = new Case(
            CurrencyIsoCode = 'AED',
            Origin = 'Walk-In',
            RecordTypeId = caseRecordTypeId,
            CaseType__c = 'Service Request',
            ContactId = testContact.Id
        );
        
        insert testCase;
        testCase.SubStatus__c = 'No Reply';
        test.startTest();
        update testCase;
        test.stopTest();
        
        
    }
    
    
    // Bapp   
    @isTest
    static void testCreateDocuments_AllScenarios() {
        Map<String, Id> rtMap = new Map<String, Id>();
        for (RecordType rt : [
            SELECT Id, DeveloperName 
            FROM RecordType 
            WHERE SObjectType = 'Case' 
            AND DeveloperName IN (
                'Broker_Registration',
                'Broker_Agency_Details_Update',
                'BrokerAgentDetailsUpdate',
                'DelayedCommissionPayment',
                'IncorrectCommissionAmount',
                'OtherServiceRequest'
            )
        ]) {
            rtMap.put(rt.DeveloperName, rt.Id);
        }
        
        List<DocumentType__c> docTypes = new List<DocumentType__c>{
            new DocumentType__c(
                Type__c = 'Trade License',
                ObjectType__c = 'Case',
                RecordTypeDevName__c = 'Broker_Registration',
                BrokerContactRole__c = 'Admin;SuperAdmin',
                TypeOfEstablishment__c = 'Domestic'
            ),
                new DocumentType__c(
                    Type__c = 'Trade License',
                    ObjectType__c = 'Case',
                    RecordTypeDevName__c = 'Broker_Agency_Details_Update',
                    TypeOfEstablishment__c = 'Domestic'
                ),
                new DocumentType__c(
                    Type__c = 'Trade License',
                    ObjectType__c = 'Case',
                    RecordTypeDevName__c = 'DelayedCommissionPayment'
                ),
                new DocumentType__c(
                    Type__c = 'Trade License',
                    ObjectType__c = 'Case',
                    RecordTypeDevName__c = 'IncorrectCommissionAmount'
                ),
                new DocumentType__c(
                    Type__c = 'Trade License',
                    ObjectType__c = 'Case',
                    RecordTypeDevName__c = 'OtherServiceRequest'
                )};
                    insert docTypes;
        
        List<Case> caseList = new List<Case>();
        
        if (rtMap.containsKey('Broker_Registration')) {
            caseList.add(new Case(
                RecordTypeId = rtMap.get('Broker_Registration'),
                BrokerContactRole__c = 'Admin',
                TypeOfEstablishment__c = 'Domestic',
                Status = 'New',
                Origin = 'Phone'
            ));
        }
        
        if (rtMap.containsKey('Broker_Agency_Details_Update')) {
            caseList.add(new Case(
                RecordTypeId = rtMap.get('Broker_Agency_Details_Update'),
                TypeOfEstablishment__c = 'Domestic',
                Status = 'New',
                Origin = 'Phone'
            ));
        }
        
        if (rtMap.containsKey('BrokerAgentDetailsUpdate')) {
            caseList.add(new Case(
                RecordTypeId = rtMap.get('BrokerAgentDetailsUpdate'),
                BrokerContactRole__c = 'Admin',
                TypeOfEstablishment__c = 'Domestic',
                Status = 'New',
                Origin = 'Phone'
            ));
        }
        
        if (rtMap.containsKey('DelayedCommissionPayment')) {
            caseList.add(new Case(
                RecordTypeId = rtMap.get('DelayedCommissionPayment'),
                Status = 'New',
                Origin = 'Phone'
            ));
        }
        
        if (rtMap.containsKey('IncorrectCommissionAmount')) {
            caseList.add(new Case(
                RecordTypeId = rtMap.get('IncorrectCommissionAmount'),
                Status = 'New',
                Origin = 'Phone'
            ));
        }
        
        if (rtMap.containsKey('OtherServiceRequest')) {
            caseList.add(new Case(
                RecordTypeId = rtMap.get('OtherServiceRequest'),
                Status = 'New',
                Origin = 'Phone'
            ));
        }
        
        insert caseList;
        
        Test.startTest();
        CaseTriggerHelper.createDocuments(caseList);
        Test.stopTest();
        
        List<Document__c> insertedDocs = [
            SELECT Id, Case__c, DocumentType__c, Document_Name__c 
            FROM Document__c
        ];
        
        System.assert(insertedDocs.size() > 0, 'Documents should be created for valid Cases');
        
        Set<Id> caseIds = new Set<Id>();
        for (Document__c doc : insertedDocs) caseIds.add(doc.Case__c);
        
        //System.assert(caseIds.containsAll(new Map<Id, Case>(caseList).keySet()),'Each case should have corresponding document(s)');
    }
    
    @isTest
    static void testCreateDocuments_NoMatchingRecordType() {
        Id unrelatedRtId;
        List<RecordType> rts = [
            SELECT Id 
            FROM RecordType 
            WHERE SObjectType = 'Case' 
            AND DeveloperName = 'UnrelatedType' 
            LIMIT 1
        ];
        if (!rts.isEmpty()) {
            unrelatedRtId = rts[0].Id;
        } else {
            unrelatedRtId = [SELECT Id FROM RecordType WHERE SObjectType = 'Case' LIMIT 1].Id;
        }
        
        Case c = new Case(
            RecordTypeId = unrelatedRtId,
            Status = 'New',
            Origin = 'Email'
        );
        insert c;
        
        Test.startTest();
        CaseTriggerHelper.createDocuments(new List<Case>{ c });
        Test.stopTest();
        
        System.assertEquals(0, [SELECT COUNT() FROM Document__c WHERE Case__c = :c.Id],
                            'No documents should be created for unrelated Record Type');
    }
    
    
    @isTest
    static void testCreateBrokerContacts() {
        Id caseRTId = Utilities.getRecordTypeId('Case', 'Broker Registration');
        Account acc = new Account(
            Name = 'Test Broker Account'
        );
        insert acc;
        
        Case cs = new Case(
            First_Name__c = 'John',
            MiddleName__c = 'K',
            Last_Name__c = 'Doe',
            Title__c = 'Mr.',
            PhoneNumber__c = '9876543210',
            Email_Address__c = 'john.doe@test.com',
            NationalID__c = 'N12345',
            NationalIDExpiryDate__c = Date.today().addYears(2),
            PassportNumber__c = 'P12345',
            PassportExpiryDate__c = Date.today().addYears(5),
            DateOfBirth__c = Date.newInstance(1990, 5, 10),
            Country__c = 'India',
            TypeofEstablishment__c = 'Domestic',
            BrokerContactRole__c = 'Admin',
            BRN_RERA_Number__c = 'BRN123',
            BRN_RERA_Expiry_Date__c = Date.today().addYears(1),
            ShareHoldingPercentage__c = 25,
            Designation__c = 'Manager',
            Mobile_Country_Code__c = '91',
            AccountId = acc.Id,
            RecordTypeId = caseRTId
        );
        
        insert cs;
        Test.startTest();
        CaseTriggerHelper.createBrokerContacts(new List<Case>{ cs });
        Test.stopTest();
    }
    
    
    @isTest
    private static void testCreateBrokerAccounts() {
        BankAccount__c bankAcc = new BankAccount__c(
            Name = 'Test Bank Account',
            AccountNumberCorporate__c = '123456789',
            BankNameCorporate__c = 'Test Bank',
            BankAddress__c = 'Bank Street',
            IBANNoCorporate__c = 'AE123456789012345678901',
            SwiftCodeCorporate__c = 'SWFTCODE'
        );
        insert bankAcc;
        
        String recordTypeAccountId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Broker Agency').getRecordTypeId();
        
        List<Account> accList = new List<Account>();
        for (Integer i = 0; i < 6; i++) {
            accList.add(new Account(
                Name = 'Test Broker Account ' + i,
                BankAccount__c = bankAcc.Id,
                RecordTypeId = recordTypeAccountId,
                Trade_License_Expiry_Date__c = Date.today(),
                VATUndertakingIssueDate__c = Date.today(),
                CommercialLicenseExpiryDate__c = Date.today(),
                TaxRegistrationNumber__c = 'TAX1234',
                Phone__c = '1234567890'
            ));
        }
        insert accList;
        
        String recordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Broker Registration').getRecordTypeId();
        
        
        List<Case> cases = new List<Case>{
            new Case(
                AccountId = accList[0].Id,
                RecordTypeId = recordTypeCaseId,
                Type = 'Trade License Expiry Update',
                TradeLicenseExpiryDate__c = Date.today().addYears(1),
                Status = 'New',
                Origin = 'Web'
            ),
                new Case(
                    AccountId = accList[1].Id,
                    RecordTypeId = recordTypeCaseId,
                    Type = 'VAT Details Update',
                    VATUndertakingIssue_Date__c = Date.today().addMonths(6),
                    TaxRegistrationNumber__c = 'TAX9999',
                    Status = 'New',
                    Origin = 'Web'
                ),
                new Case(
                    AccountId = accList[2].Id,
                    RecordTypeId = recordTypeCaseId,
                    Type = 'Agency Address Update',
                    PhoneNumber__c = '9876543210',
                    Address1__c = 'Street 1',
                    Address2__c = 'Street 2',
                    Status = 'New',
                    Origin = 'Web'
                ),
                new Case(
                    AccountId = accList[3].Id,
                    RecordTypeId = recordTypeCaseId,
                    Type = 'Commercial License Expiry Update',
                    CommercialLicenseExpiryDate__c = Date.today().addYears(2),
                    Status = 'New',
                    Origin = 'Web'
                ),
                new Case(
                    AccountId = accList[4].Id,
                    RecordTypeId = recordTypeCaseId,
                    Type = 'Legal Documents Update',
                    Status = 'New',
                    Origin = 'Web'
                ),
                new Case(
                    AccountId = accList[5].Id,
                    RecordTypeId = recordTypeCaseId,
                    Type = 'Bank Details Update',
                    AccountNumber__c = 'ACC12345',
                    BankName__c = 'New Bank',
                    BankAddress__c = 'Downtown Branch',
                    IBANNumber__c = 'AE987654321098765432109',
                    SwiftCode__c = 'NEWCODE',
                    Status = 'New',
                    Origin = 'Web'
                )
                };
                    insert cases;
        
        
        Test.startTest();
        //  CaseTriggerHelper.updateBrokerAccounts(cases);
        CaseTriggerHelper.updateBrokerAccounts(cases,false);
        Test.stopTest();
        
        
        Account updatedAcc = [
            SELECT Trade_License_Expiry_Date__c,
            VATUndertakingIssueDate__c,
            CommercialLicenseExpiryDate__c,
            TaxRegistrationNumber__c,
            BillingStreet,
            Phone__c
            FROM Account
            WHERE Id = :accList[0].Id
        ];
        
        System.assertNotEquals(null, updatedAcc.Trade_License_Expiry_Date__c, 'Trade License should be updated');
        
        
        BankAccount__c updatedBank = [
            SELECT AccountNumberCorporate__c, BankNameCorporate__c, BankAddress__c, IBANNoCorporate__c, SwiftCodeCorporate__c
            FROM BankAccount__c
            WHERE Id = :bankAcc.Id
        ];
        
        //System.assertEquals('ACC12345', updatedBank.AccountNumberCorporate__c, 'AccountNumber should update');
        
    }
    
    @isTest
    private static void testCreateBrokerContactSR() {
        
        Id accountRTId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('Broker_Agency').getRecordTypeId();
        Id contactRTId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName()
            .get('Broker').getRecordTypeId();
        Id caseRTId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
            .get('Broker_Registration').getRecordTypeId();
        
        
        Account acc = new Account(
            Name = 'Test Broker Agency',
            RecordTypeId = accountRTId
        );
        insert acc;
        
        /*Contact con = new Contact(
FirstName = 'Test',
LastName = 'User',
AccountId = acc.Id,
RecordTypeId = contactRTId,
BrokerContactRole__c = 'Agent',
NationalIdExpiryDate__c = Date.today(),
PassportExpiryDate__c = Date.today(),
BRN_RERA_Expiry_Date__c = Date.today(),
Email = 'test1233@test.com'
);
insert con;

Case agentUpdateCase = new Case(
Subject = 'Agent Details Update Case',
AccountId = acc.Id,
ContactId = con.Id,
RecordTypeId = caseRTId,
Type = 'Agent Details Update',
BrokerContactRole__c = 'Agent',
NationalIDExpiryDate__c = Date.today().addYears(1),
PassportExpiryDate__c = Date.today().addYears(2),
BRN_RERA_Expiry_Date__c = Date.today().addMonths(6),
Status = 'New',
Origin = 'Web'
);
insert agentUpdateCase;

Test.startTest();
CaseTriggerHelper.updateBrokerContactSR(new List<Case>{ agentUpdateCase });
Test.stopTest();

Contact updatedCon = [
SELECT CaseId__c,
BrokerContactRole__c,
NationalIdExpiryDate__c,
PassportExpiryDate__c,
BRN_RERA_Expiry_Date__c,
AccountId,
RecordType.DeveloperName
FROM Contact
WHERE Id = :con.Id
];

System.assertEquals(agentUpdateCase.Id, updatedCon.CaseId__c, 'CaseId__c should update on Contact');
System.assertEquals('Agent', updatedCon.BrokerContactRole__c, 'BrokerContactRole__c should update');
System.assertEquals(Date.today().addYears(1), updatedCon.NationalIdExpiryDate__c, 'National ID Expiry should update');
System.assertEquals(Date.today().addYears(2), updatedCon.PassportExpiryDate__c, 'Passport Expiry should update');
System.assertEquals(Date.today().addMonths(6), updatedCon.BRN_RERA_Expiry_Date__c, 'BRN/RERA Expiry should update');
System.assertEquals(acc.Id, updatedCon.AccountId, 'AccountId should remain linked');
System.assertEquals('Broker', updatedCon.RecordType.DeveloperName, 'Contact RecordType should remain Broker');*/
    }
    
    @isTest
    static void testCreateDocuments_BAPPNewRecordTypesCoverage() {
        Id brokerAgentRTId = Schema.SObjectType.Case
            .getRecordTypeInfosByDeveloperName()
            .get('BrokerAgentRegistrationAndUpdate')
            .getRecordTypeId();
        
        Id brokerAgencyRTId = Schema.SObjectType.Case
            .getRecordTypeInfosByDeveloperName()
            .get('BrokerAgencyDetailsUpdate')
            .getRecordTypeId();
        
        Id brokerCommissionRTId = Schema.SObjectType.Case
            .getRecordTypeInfosByDeveloperName()
            .get('BrokerCommissionIssue')
            .getRecordTypeId();
        
        Id otherServiceRequestRTId = Schema.SObjectType.Case
            .getRecordTypeInfosByDeveloperName()
            .get('BrokerGeneralServiceRequest')
            .getRecordTypeId();
        
        List<DocumentType__c> docTypes = new List<DocumentType__c>{
            // Agent detail update - normal matching document
            new DocumentType__c(
                Type__c = 'Trade License',
                ObjectType__c = 'Case',
                RecordTypeDevName__c = 'BrokerAgentRegistrationAndUpdate',
                BrokerContactRole__c = 'Admin;Agent',
                TypeOfEstablishment__c = 'Domestic'
            ),
                
                // Agent detail update - passport doc, should be skipped for Domestic + Broker Agent Details Update
                new DocumentType__c(
                    Type__c = 'Passport Front',
                    ObjectType__c = 'Case',
                    RecordTypeDevName__c = 'BrokerAgentRegistrationAndUpdate',
                    BrokerContactRole__c = 'Admin',
                    TypeOfEstablishment__c = 'Domestic'
                ),
                
                // Agency details update
                new DocumentType__c(
                    Type__c = 'Broker Agreement',
                    ObjectType__c = 'Case',
                    RecordTypeDevName__c = 'BrokerAgencyDetailsUpdate',
                    TypeOfEstablishment__c = 'Domestic'
                ),
                
                // Broker commission issue
                new DocumentType__c(
                    Type__c = 'Supporting Document 1',
                    ObjectType__c = 'Case',
                    RecordTypeDevName__c = 'BrokerCommissionIssue'
                ),
                
                // Other service request
                new DocumentType__c(
                    Type__c = 'Supporting Document 1',
                    ObjectType__c = 'Case',
                    RecordTypeDevName__c = 'BrokerGeneralServiceRequest'
                )
                };
                    insert docTypes;
        
        Account acc = new Account(Name = 'BAPP Test Account');
        insert acc;
        
        List<Case> caseList = new List<Case>{
            new Case(
                RecordTypeId = brokerAgentRTId,
                Status = 'New',
                Origin = 'Phone',
                AccountId = acc.Id,
                Subject = 'Broker Agent Details Update',
                SubType__c = 'Broker Agent Details Update',
                BrokerContactRole__c = 'Admin',
                TypeOfEstablishment__c = 'Domestic'
            ),
                new Case(
                    RecordTypeId = brokerAgencyRTId,
                    Status = 'New',
                    Origin = 'Phone',
                    AccountId = acc.Id,
                    Subject = 'Broker Agency Details Update',
                    SubType__c = 'Broker Agency Details Update',
                    TypeOfEstablishment__c = 'Domestic'
                ),
                new Case(
                    RecordTypeId = brokerCommissionRTId,
                    Status = 'New',
                    Origin = 'Phone',
                    AccountId = acc.Id,
                    Subject = 'Delayed Commission Payment',
                    SubType__c = 'Delayed Commission Payment'
                ),
                new Case(
                    RecordTypeId = otherServiceRequestRTId,
                    Status = 'New',
                    Origin = 'Phone',
                    AccountId = acc.Id,
                    Subject = 'Other Service Request',
                    SubType__c = 'Other Service Request'
                )
                };
                    insert caseList;
        
        Test.startTest();
        CaseTriggerHelper.createDocuments(caseList);
        Test.stopTest();
        
        List<Document__c> createdDocs = [
            SELECT Id, Case__c, DocumentType__c, Document_Name__c
            FROM Document__c
            WHERE Case__c IN :caseList
        ];
        
        System.assert(
            createdDocs.size() >= 4,
            'Documents should be created for Broker Agent, Agency, Commission, and Other SR cases'
        );
        
        Set<String> createdDocNames = new Set<String>();
        for (Document__c doc : createdDocs) {
            createdDocNames.add(doc.Document_Name__c);
        }
        
        System.assert(
            createdDocNames.contains('Trade License'),
            'Agent detail update document should be created'
        );
        //System.assert(createdDocNames.contains('Agency Trade License'),'Agency details update document should be created');
        //System.assert(createdDocNames.contains('Commission Proof'),'Broker commission document should be created');
        //System.assert(createdDocNames.contains('Other Supporting Document'),'Other service request document should be created');
    }
    
    @isTest
    static void testUpdateBrokerContactSR_CoversBrokerAgentAndContactId() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        Id brokerContactRTId = Schema.SObjectType.Contact
            .getRecordTypeInfosByDeveloperName()
            .get('Broker')
            .getRecordTypeId();
        
        Id brokerAgentCaseRTId = Schema.SObjectType.Case
            .getRecordTypeInfosByDeveloperName()
            .get('BrokerAgentRegistrationAndUpdate')
            .getRecordTypeId();
        
        String brokerRole = 'Agent';
        for (Schema.PicklistEntry pe : Case.BrokerContactRole__c.getDescribe().getPicklistValues()) {
            if (pe.isActive()) {
                brokerRole = pe.getValue();
                break;
            }
        }
        
        Contact conForBrokerAgent = new Contact(
            FirstName = 'Broker',
            LastName = 'Agent Contact',
            Email = 'brokeragent@test.com',
            AccountId = acc.Id,
            RecordTypeId = brokerContactRTId
        );
        
        Contact conForContactId = new Contact(
            FirstName = 'Case',
            LastName = 'Contact',
            Email = 'casecontact@test.com',
            AccountId = acc.Id,
            RecordTypeId = brokerContactRTId
        );
        
        insert new List<Contact>{ conForBrokerAgent, conForContactId };
            
            Case caseUsingBrokerAgent = new Case(
                RecordTypeId = brokerAgentCaseRTId,
                AccountId = acc.Id,
                Status = 'New',
                Origin = 'Web',
                Type = 'Broker Service Request',
                SubType__c = 'Broker Agent Details Update',
                Broker_Agent__c = conForBrokerAgent.Id,
                BrokerContactRole__c = brokerRole,
                NationalIDExpiryDate__c = Date.today().addYears(1),
                PassportExpiryDate__c = Date.today().addYears(2),
                BRN_RERA_Expiry_Date__c = Date.today().addYears(3)
            );
        
        Case caseUsingContactId = new Case(
            RecordTypeId = brokerAgentCaseRTId,
            AccountId = acc.Id,
            Status = 'New',
            Origin = 'Web',
            Type = 'Other Type',
            SubType__c = 'Broker Agent Details Update',
            ContactId = conForContactId.Id,
            BrokerContactRole__c = brokerRole,
            NationalIDExpiryDate__c = Date.today().addYears(1),
            PassportExpiryDate__c = Date.today().addYears(2),
            BRN_RERA_Expiry_Date__c = Date.today().addYears(3)
        );
        
        insert new List<Case>{ caseUsingBrokerAgent, caseUsingContactId };
            
            CaseTriggerHelper.updateBrokerContactSR(
                new List<Case>{ caseUsingBrokerAgent, caseUsingContactId }
            );
        
        Map<Id, Contact> updatedContacts = new Map<Id, Contact>([
            SELECT Id,
            CaseId__c,
            BrokerContactRole__c,
            EID_Expiry_Date__c,
            PassportExpiryDate__c,
            BRN_RERA_Expiry_Date__c,
            AccountId
            FROM Contact
            WHERE Id IN :new Set<Id>{ conForBrokerAgent.Id, conForContactId.Id }
        ]);
        
        System.assertEquals(
            caseUsingBrokerAgent.Id,
            updatedContacts.get(conForBrokerAgent.Id).CaseId__c,
            'Broker_Agent__c contact should be updated with Case Id'
        );
        
        System.assertEquals(
            caseUsingContactId.Id,
            updatedContacts.get(conForContactId.Id).CaseId__c,
            'ContactId contact should be updated with Case Id'
        );
        
        System.assertEquals(
            brokerRole,
            updatedContacts.get(conForBrokerAgent.Id).BrokerContactRole__c,
            'Broker role should be updated'
        );
        
        System.assertEquals(
            acc.Id,
            updatedContacts.get(conForContactId.Id).AccountId,
            'Contact AccountId should be updated from Case'
        );
    }
    
    @isTest
    static void testCompleteRelatedTasks_StatusAndApprovalCoverage() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        Id brokerCommissionRTId = Schema.SObjectType.Case
            .getRecordTypeInfosByDeveloperName()
            .get('BrokerCommissionIssue')
            .getRecordTypeId();
        
        Id otherServiceRTId = Schema.SObjectType.Case
            .getRecordTypeInfosByDeveloperName()
            .get('BrokerGeneralServiceRequest')
            .getRecordTypeId();
        
        Id agencyUpdateRTId = Schema.SObjectType.Case
            .getRecordTypeInfosByDeveloperName()
            .get('BrokerAgencyDetailsUpdate')
            .getRecordTypeId();
        
        Id agentUpdateRTId = Schema.SObjectType.Case
            .getRecordTypeInfosByDeveloperName()
            .get('BrokerAgentRegistrationAndUpdate')
            .getRecordTypeId();
        
        List<Case> brokerCases = new List<Case>{
            new Case(
                RecordTypeId = brokerCommissionRTId,
                AccountId = acc.Id,
                Status = 'New',
                Origin = 'Web',
                Subject = 'Closed Broker Commission'
            ),
                new Case(
                    RecordTypeId = otherServiceRTId,
                    AccountId = acc.Id,
                    Status = 'New',
                    Origin = 'Web',
                    Subject = 'Cancelled Other Service'
                ),
                new Case(
                    RecordTypeId = agencyUpdateRTId,
                    AccountId = acc.Id,
                    Status = 'New',
                    Origin = 'Web',
                    Subject = 'Rejected Agency Update',
                    ApprovalStatus__c = 'Pending'
                ),
                new Case(
                    RecordTypeId = agentUpdateRTId,
                    AccountId = acc.Id,
                    Status = 'New',
                    Origin = 'Web',
                    Subject = 'Rejected Agent Update',
                    ApprovalStatus__c = 'Pending'
                )
                };
                    
                    insert brokerCases;
        
        List<Task> taskList = new List<Task>();
        for (Case c : brokerCases) {
            taskList.add(new Task(
                WhatId = c.Id,
                Subject = 'Open Broker Task',
                Status = 'Not Started',
                Priority = 'Normal'
            ));
        }
        insert taskList;
        
        Map<Id, Case> oldMap = new Map<Id, Case>();
        
        for (Case c : brokerCases) {
            oldMap.put(
                c.Id,
                new Case(
                    Id = c.Id,
                    Status = 'New',
                    ApprovalStatus__c = 'Pending'
                )
            );
        }
        
        brokerCases[0].Status = 'Closed';
        brokerCases[1].Status = 'Cancelled';
        brokerCases[2].ApprovalStatus__c = 'Rejected';
        brokerCases[3].ApprovalStatus__c = 'Rejected';
        
        Test.startTest();
        CaseTriggerHelper.completeRelatedTasks(brokerCases, oldMap);
        Test.stopTest();
        
        System.assertEquals(
            4,
            [
                SELECT COUNT()
                FROM Task
                WHERE WhatId IN :brokerCases
            ],
            'Tasks should exist for broker cases'
        );
    }
    
   
    
}