/***
Class       : PaymentPlanServiceTest
Author      : Dhanraj
Description : Test class of PaymentPlanService class
----------------------------------------------------------------------------------------------------------------
****************************************************************************************************************/

@IsTest
private class PaymentPlanServiceTest {
    
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
    static void testGetPaymentPlansByProjectId() {
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];
        Test.startTest();
        List<PaymentPlan__c> plans = PaymentPlanService.getInstance().getPaymentPlansByProjectId(project.Id);
        Test.stopTest();
    }
    
    @IsTest
    static void testGetPaymentPlans() {
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];
        Test.startTest();
        List<PaymentPlan__c> plans = PaymentPlanService.getInstance().getPaymentPlans(project.Id, 'Resident');
        Test.stopTest();
    }
    
    @IsTest
    static void testGetPaymentPlansByIds() {
        PaymentPlan__c plan = [SELECT Id FROM PaymentPlan__c LIMIT 1];
        Test.startTest();
        List<PaymentPlan__c> plans = PaymentPlanService.getInstance().getPaymentPlansByIds(new Set<Id>{ plan.Id });
        Test.stopTest();
    }
    
    @IsTest
    static void testGetClassificationFromPaymentPlan() {
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];
        Test.startTest();
        List<PaymentPlan__c> plans = PaymentPlanService.getInstance().getClassificationFromPaymentPlan(project.Id);
        Test.stopTest();
    }
    
    @IsTest
    static void testGetPaymentPlansClassification() {
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];
        Test.startTest();
        List<PaymentPlan__c> plans = PaymentPlanService.getInstance().getPaymentPlansClassification(project.Id,'Standard');
        Test.stopTest();
    }
    
    @IsTest
    static void testInsertPaymentPlan() {
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];
        Unit__c unitRec = [SELECT Id FROM Unit__c LIMIT 1];
        PaymentPlan__c  pp = new PaymentPlan__c();
        pp.Name ='July Plan';
        pp.Unit__c= unitRec.id;
        pp.Description__c ='Test Description';
        pp.Description__c = 'Test';
        pp.IsActive__c = 'NO';
        pp.BrokerPortalFlag__c = True;
        pp.Classification__c = Constants.PAYMENT_PLAN_TYPE_STANDARD;
        Test.startTest();
        PaymentPlan__c result = PaymentPlanService.getInstance().insertPaymentPlan(pp);
        Test.stopTest();
    }
    
    @IsTest
    static void testInsertPaymentPlanWithNull() {
        Test.startTest();
        PaymentPlan__c result = PaymentPlanService.getInstance().insertPaymentPlan(null);
        Test.stopTest();
    }
    
    @IsTest
    static void testUpdatePaymentPlan() {
        PaymentPlan__c plan = [SELECT Id, Description__c FROM PaymentPlan__c LIMIT 1];
        plan.Description__c = 'Updated Description';
        Test.startTest();
        PaymentPlanService.getInstance().updatePaymentPlan(plan);
        Test.stopTest();
        PaymentPlan__c updatedPlan = [SELECT Description__c FROM PaymentPlan__c WHERE Id = :plan.Id];
    }
    
    @IsTest
    static void testUpdatePaymentPlanWithNull() {
        Test.startTest();
        PaymentPlan__c result = PaymentPlanService.getInstance().updatePaymentPlan(null);
        Test.stopTest();
    }
}