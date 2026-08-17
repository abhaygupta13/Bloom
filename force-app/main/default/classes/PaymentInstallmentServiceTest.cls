/***
Class       : PaymentInstallmentServiceTest
Author      : Dhanraj
Description : Test class of PaymentInstallmentService class
----------------------------------------------------------------------------------------------------------------
****************************************************************************************************************/

@IsTest
private class PaymentInstallmentServiceTest {
    
    @TestSetup
    static void setupData() {
        Account acc = new Account(FirstName = 'Jane', LastName = 'Doe', PersonEmail = 'test@test.com');
        insert acc;
        
        Contact con = new Contact(FirstName = 'John', LastName = 'Doe');
        insert con;
        
        Project__c project = TestDataFactory.createProject('ProjectTest', Date.today() - 1);
        insert project;
        
        BuildingSection__c testBuilding=new BuildingSection__c(
            Name='Test Building',
            BuildingSectionCode__c='BL-CAS',
            Project__c=project.Id
        );
        insert testBuilding;
        
        Unit__c testUnit=new Unit__c(
            Name='test Unit',
            Status__c='Available',
            UnitType__c='Townhouse',
            BuildingSectionName__c=testBuilding.id,
            Project__c=project.Id,
            PropertyUsage__c='Residential',
            UnitView__c  ='Beach Side',
            FloorNumber__c='01',
            NumberOfBedrooms__c='3',
            UnitModel__c='1BHK',
            SellingPrice__c= 700000,
            EndDate__c= date.today()+10,
            StartDate__c=date.today()-10
            
        );
        insert testUnit;
        
        List<PaymentPlan__c> plans = new List<PaymentPlan__c>();
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
        
        SalesOrder__c so = new SalesOrder__c(
            Name = 'SO-001',
            Status__c = 'Active',
            Account__c = acc.Id,
            Contact__c = con.Id,
            Unit__c = testUnit.Id,
            SoldDate__c = Date.today()
        );
        insert so;
        
        List<InstallmentLines__c> installments = new List<InstallmentLines__c>{
            new InstallmentLines__c(
                SalesOrder__c = so.Id,
                InstallmentNumber__c = 1,
                PaymentInstallments__c = ppi.Id,
                InstallmentAmount__c = 10000,
                ClearedAmount__c = 5000,
                InstallmentDate__c = Date.today().addDays(3),
                InstallmentPercentage__c = 40,
                BrokerCommissionCreated__c = false,
                Type__c = 'Handover',
                Description__c = 'test description'
            )
        };
        insert installments;
    }

    @IsTest
    static void testGetPaymentInstallmentsById() {
        PaymentPlan__c plan = [SELECT Id FROM PaymentPlan__c LIMIT 1];
        Test.startTest();
        List<PaymentInstallments__c> results = PaymentInstallmentService.getInstance().getPaymentInstallmentsById(new Set<Id>{ plan.Id });
        Test.stopTest();
    }

    @IsTest
    static void testGetPaymentInstallmentsByPaymentPlanId() {
        PaymentPlan__c plan = [SELECT Id FROM PaymentPlan__c LIMIT 1];
        Test.startTest();
        List<PaymentInstallments__c> results = PaymentInstallmentService.getInstance().getPaymentInstallmentsByPaymentPlanId(plan.Id);
        Test.stopTest();
    }

    @IsTest
    static void testInsertPaymentInstallments() {
        PaymentPlan__c plan = [SELECT Id FROM PaymentPlan__c LIMIT 1];
        List<PaymentInstallments__c> installments = new List<PaymentInstallments__c>();
        PaymentInstallments__c ppi = new PaymentInstallments__c();
        ppi.BrokerPayoutPercentage__c =100;
        ppi.Description__c = 'test description';
        ppi.InstallmentNumber__c = 1;
        ppi.InstallmentPercentage__c=100;
        ppi.PaymentPlan__c = plan.id;
        ppi.InstallmentPercentage__c=100;
        ppi.Condition_Type__c='P012';
        installments.add(ppi);
        Test.startTest();
        List<PaymentInstallments__c> result = PaymentInstallmentService.getInstance().insertPaymentInstallments(installments);
        Test.stopTest();
    }

    @IsTest
    static void testInsertPaymentInstallmentsWithNull() {
        Test.startTest();
        List<PaymentInstallments__c> result = PaymentInstallmentService.getInstance().insertPaymentInstallments(null);
        Test.stopTest();
    }

    @IsTest
    static void testInsertPaymentInstallmentsWithEmptyList() {
        List<PaymentInstallments__c> installments = new List<PaymentInstallments__c>();
        Test.startTest();
        List<PaymentInstallments__c> result = PaymentInstallmentService.getInstance().insertPaymentInstallments(installments);
        Test.stopTest();
    }

    @IsTest
    static void testUpdatePaymentInstallmentLists() {
        PaymentInstallments__c installment = [SELECT Id, Description__c FROM PaymentInstallments__c LIMIT 1];
        installment.Description__c = 'Updated Description';
        Test.startTest();
        PaymentInstallmentService.getInstance().updatepaymentInstallmentLists(new List<PaymentInstallments__c>{installment});
        Test.stopTest();
    }
    
    @IsTest
    static void testUpdatePaymentInstallmentListsWT() {
        PaymentInstallments__c installment = [SELECT Id, Description__c FROM PaymentInstallments__c LIMIT 1];
        installment.Description__c = 'Updated Description';
        Test.startTest();
        PaymentInstallmentService.getInstance().updatePaymentInstallmentWithoutTrigger(new List<PaymentInstallments__c>{installment});
        Test.stopTest();
    }

    @IsTest
    static void testUpdatePaymentInstallmentListsWithNull() {
        Test.startTest();
        List<PaymentInstallments__c> result = PaymentInstallmentService.getInstance().updatepaymentInstallmentLists(null);
        Test.stopTest();
    }

    @IsTest
    static void testUpdatePaymentInstallmentListsWithEmptyList() {
        List<PaymentInstallments__c> installments = new List<PaymentInstallments__c>();
        Test.startTest();
        List<PaymentInstallments__c> result = PaymentInstallmentService.getInstance().updatepaymentInstallmentLists(installments);
        Test.stopTest();
    }
}