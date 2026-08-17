@isTest
public class InstallmentLineControllerTest {
    @testSetup
    static void setupData() {
        Id paRtId = Schema.SObjectType.Account
            .getRecordTypeInfosByDeveloperName()
            .get('PersonAccount')
            .getRecordTypeId();
        
        Account acc = new Account(
            RecordTypeId = paRtId,
            FirstName = 'John',
            LastName = 'Doe',
            PersonEmail = 'test@gmail.com',
            Emirates_Id__pc = 'EID123',
            Nationality__pc = 'India',
            PersonBirthdate = Date.newInstance(1990, 1, 1),
            PrimaryMobilePhone__pc = '9999999999',
            PrimaryMobileCountryCode__pc = '91'
        );
        insert acc;
        
        acc = [
            SELECT Id, PersonContactId
            FROM Account
            WHERE Id = :acc.Id
        ];
        
        // Create Project (nested relationship in InstallmentLines__c)
        Project__c project = new Project__c(Name = 'Test Project', EnableLatePaymentFee__c = true);
        insert project;
        
        // Create Building
        Building__c building = TestDataFactory.createBuilding('Building 1', project.Id);
        insert building;
        
        // Create Unit
        Unit__c unit = new Unit__c(Name = 'Test Unit', Project__c = project.Id);
        insert unit;
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            AccountId = acc.Id,
            WinReason__c = 'New Project Launch'
        );
        insert opp;
        
        // Create Sales Order
        SalesOrder__c so = new SalesOrder__c(
            Name = 'SO-001',
            Status__c = 'Sold',
            Account__c = acc.Id,
            Unit__c = unit.Id,
            Opportunity__c = opp.Id,
            SoldDate__c = Date.today()
        );
        insert so;
        
        InstallmentLines__c il1 = new InstallmentLines__c(
            SalesOrder__c = so.Id,
            InstallmentNumber__c = 1,
            InstallmentAmount__c = 10000,
            AmountReceived__c = 5000,
            ClearedAmount__c  = 5000,
            InstallmentPercentage__c = 50,
            Type__c = 'Installment',
            InstallmentDate__c = Date.today(),
            Description__c = 'Installment 1'
        );
        
        InstallmentLines__c il2 = new InstallmentLines__c(
            SalesOrder__c = so.Id,
            InstallmentNumber__c = 2,
            InstallmentAmount__c = 10000,
            AmountReceived__c = 2000,
            ClearedAmount__c  = 2000,
            InstallmentPercentage__c = 50,
            Type__c = 'Post Handover Installment',
            InstallmentDate__c = Date.today(),
            Description__c = 'Installment 2'
        );
        insert new List<InstallmentLines__c>{ il1, il2 };
            
            SalesOrderOtherCharges__c oc = new SalesOrderOtherCharges__c(
                SalesOrder__c = so.Id,
                TypeOfCharge__c = 'Service Charge',
                Amount__c = 2000,
                InvoicedAmount__c = 1000,
                Due_Date__c = Date.today().addDays(5)
            );
        insert oc;
    }
    
    @IsTest
    static void testUseCase1() {
        InstallmentLines__c il = [SELECT Id,SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_Installment__c,SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.Name,SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_ADM_Charges__c,SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_ADM_Charges__r.Name,
                                                            SalesOrder__r.Unit__r.BuildingSectionName__r.HandoverAccountInstallment__c,SalesOrder__r.Unit__r.BuildingSectionName__r.HandoverAccountInstallment__r.Name,SalesOrder__r.Unit__r.BuildingSectionName__r.PHPPAccountInstallment__c,SalesOrder__r.Unit__r.BuildingSectionName__r.PHPPAccountInstallment__r.Name,
                                                            SalesOrder__r.Unit__r.BuildingSectionName__r.BounceChequeAccount__c,SalesOrder__r.Unit__r.BuildingSectionName__r.BounceChequeAccount__r.Name FROM InstallmentLines__c LIMIT 1];
        Test.setCurrentPage(Page.SalesInvoicePDF);
        ApexPages.currentPage().getParameters().put('id', il.Id);
        Test.startTest();
        InstallmentLineController ctrl = new InstallmentLineController();
        Test.stopTest();
    }
    
    @isTest
    static void testUseCase2() {
        InstallmentLines__c il = [SELECT Id FROM InstallmentLines__c LIMIT 1];
        InstallmentLineController ctrl = new InstallmentLineController();
        InstallmentLineController.generateAndAttachPdf(il.Id,'salesProformaPDF');
        InstallmentLineController.generateAndAttachPdf(il.Id,'salesInvoicePDF');
    }
}