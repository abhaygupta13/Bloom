@IsTest
private class AsyncActionQueueableTest {
    
    @testSetup
    static void setupTestData() {
        
        Project__c testProject = new Project__c(Name='Test Project');
        insert testProject;
        
        BuildingSection__c testBuilding = new BuildingSection__c(
            Name='Test Building',
            BuildingSectionCode__c='BL-CAS',
            Project__c=testProject.Id
        );
        insert testBuilding;
        
        Unit__c testUnit = new Unit__c(
            Name='Test Unit',
            Status__c='Available',
            UnitType__c='Townhouse',
            BuildingSectionName__c=testBuilding.Id,
            Project__c=testProject.Id,
            PropertyUsage__c='Residential',
            SellingPrice__c=700000
        );
        insert testUnit;
        
        PaymentPlan__c pp = new PaymentPlan__c(
            Name ='July Plan',
            Unit__c= testUnit.Id,
            Description__c ='Test',
            IsActive__c = 'NO',
            BrokerPortalFlag__c = true,
            Classification__c = Constants.PAYMENT_PLAN_TYPE_STANDARD
        );
        insert pp;
        
        insert new BuildingSectionMapping__c(
            BuildingSectionName__c = testBuilding.Id,
            PaymentPlan__c = pp.Id
        );
        
        Id personRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        Account acc = new Account(
            RecordTypeId = personRtId,
            LastName= 'Test',
            PersonEmail='test@test.com'
        );
        insert acc;
        
        Opportunity opp = new Opportunity(
            Name='Test Opp',
            StageName='New',
            CloseDate=System.today(),
            LeadChannel__c='Walk in',
            AccountId=acc.Id,
            WinReason__c='Loyalty'
        );
        insert opp;
        
        PaymentInstallments__c pi = new PaymentInstallments__c(
            BrokerPayoutPercentage__c =100,
            Description__c = 'test description',
            InstallmentNumber__c = 1,
            InstallmentPercentage__c =100,
            PaymentPlan__c = pp.Id,
            Condition_Type__c='P012'
        );
        insert pi;
        
        pp.IsActive__c = 'Yes';
        update pp;
        
        SalesOrder__c so = new SalesOrder__c(
            Name = 'Test Order',
            Status__c = 'Booked',
            Unit__c = testUnit.Id,
            Account__c = acc.Id,
            Opportunity__c = opp.Id
        );
        insert so;
        
        InstallmentLines__c il = new InstallmentLines__c(
            PaymentPlan__c = pp.Id,
            PaymentInstallments__c = pi.Id,
            SalesOrder__c = so.Id,
            Description__c = 'Installment',
            InstallmentAmount__c = 70000,
            InstallmentPercentage__c = 25,
            BrokerPayoutPercentage__c = 20,
            RevisedDate__c = null,
            InstallmentDate__c = Date.today().addDays(-10)
        );
        insert il;
    }
    
    @IsTest
    static void testUpdatePaymentInstallmentWithoutTrigger() {
        List<PaymentInstallments__c> lstPI = new List<PaymentInstallments__c>();
        PaymentInstallments__c pi = [SELECT Id, RevisedDate__c FROM PaymentInstallments__c LIMIT 1];
        pi.RevisedDate__c = Date.today().addDays(5);
        pi.RevisedDateVerified__c = true;
        lstPI.add(pi);
        Test.startTest();
        System.enqueueJob(new AsyncActionQueueable('UPDATE_PAYMENT_INSTALLMENT_WITHOUT_TRIGGER',lstPI));
        Test.stopTest();
    }
    
    @IsTest
    static void testUnknownProcessName() {
        List<sObject> objList = new List<sObject>();
        Test.startTest();
        System.enqueueJob(new AsyncActionQueueable('INVALID_PROCESS',objList));
        Test.stopTest();
    }
}