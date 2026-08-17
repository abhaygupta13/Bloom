/*****************************************************************************************
Class       : SalesOrderRebateServiceTest
Author      : Dhanraj Poojary
Description : SalesOrderRebateService Test Class 
Created Date: 16 JUL 2026
*****************************************************************************************/

@IsTest
private class SalesOrderRebateServiceTest {
    
    @TestSetup
    static void setupData() {
        Project__c testProject=new Project__c(Name='Test Project');
        insert testProject;
        
        BuildingSection__c testBuilding=new BuildingSection__c(Name='Test Building',BuildingSectionCode__c='BL-CAS',Project__c=testProject.Id);
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
            SellingPrice__c= 700000,
            EndDate__c= date.today()+10,
            StartDate__c=date.today()-10
            
        );
        insert testUnit;
        
        PaymentPlan__c  pp = new PaymentPlan__c();
        pp.Name ='July Plan';
        pp.Unit__c= testUnit.id;
        pp.Description__c ='Test Description';
        pp.Description__c = 'Test';
        pp.IsActive__c = 'NO';
        pp.BrokerPortalFlag__c = True;
        pp.Classification__c = Constants.PAYMENT_PLAN_TYPE_STANDARD;      
        insert pp;
        
        BuildingSectionMapping__c mappingRecord = new BuildingSectionMapping__c();
        mappingRecord.BuildingSectionName__c = testBuilding.id;
        mappingRecord.PaymentPlan__c = pp.id;
        insert mappingRecord;
        
        Id AccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        Account tempAcc=new Account(RecordTypeId=AccountRecordTypeId,LastName= 'test',personEmail='Jana@tesrt.com');
        insert tempAcc;
        
        Opportunity tempOpp=new Opportunity(Name='tempOpp',StageName='New',CloseDate=system.today(),LeadChannel__c='Walk in',AccountId=tempAcc.Id,WinReason__c='Loyalty');
        insert tempOpp;
        
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
        
        SalesOrder__c so = new SalesOrder__c(Name = 'Test Order',Status__c = 'Booked',Unit__c =testUnit.id,Account__c = tempAcc.Id,Opportunity__c=tempOpp.Id);
        insert so;
        
        Set<Id> salesOrderSet = new Set<Id>();
        salesOrderSet.add(so.Id);
        
        InstallmentLines__c installmentLines = new InstallmentLines__c();
        installmentLines.PaymentPlan__c = pp.id;
        installmentLines.PaymentInstallments__c =ppi.Id;
        installmentLines.SalesOrder__c = so.id;
        installmentLines.Description__c='4th Installment';
        installmentLines.InstallmentAmount__c = 100000;
        installmentLines.LPCCutOffAmt__c =0;
        installmentLines.MinInvAmtrem__c =100;
        installmentLines.LPCRate__c =12;
        installmentLines.InstallmentPercentage__c = 25;
        installmentLines.BrokerPayoutPercentage__c = 20;
        installmentLines.Description__c = 'Description';
        installmentLines.RevisedDate__c=null;
        installmentLines.Send_to_SAP__c = true;
        installmentLines.GracePeriod__c=1;
        installmentLines.InstallmentAmount__c =70000;
        installmentLines.Inst_inc_tax_in_words__c  = '';
        installmentLines.InstallmentDate__c= Date.today() - 12;
        installmentLines.AmountReceived__c=1500;
        installmentLines.CutOffDate__c=date.today();
        installmentLines.LPCAmount__c=500;
        insert installmentLines;
        
        // Create Rebate Records
        List<SalesOrderRebate__c> rebates = new List<SalesOrderRebate__c>();
        rebates.add(new SalesOrderRebate__c(
            SalesOrder__c = so.Id,
            InstallmentLine__c = installmentLines.Id,
            Amount__c = 100,
            Date__c = Date.today(),
            ConditionType__c = 'ZREB',
            SendtoSAP__c = true,
            SAP_Document_No__c = 'INV/123456/2026'
        ));
        
        rebates.add(new SalesOrderRebate__c(
            SalesOrder__c = so.Id,
            InstallmentLine__c = installmentLines.Id,
            Amount__c = 200,
            Date__c = Date.today(),
            ConditionType__c = 'ZREB',
            SendtoSAP__c = false
        ));
        insert rebates;
    }
    
    @IsTest
    static void testGetSalesOrderRebatesByIds() {
        Set<Id> rebateIds = new Set<Id>();
        for(SalesOrderRebate__c rebate : [SELECT Id FROM SalesOrderRebate__c]){
            rebateIds.add(rebate.Id);
        }
        Test.startTest();
        List<SalesOrderRebate__c> result = SalesOrderRebateService.getInstance().getSalesOrderRebatesByIds(rebateIds);
        Test.stopTest();
    }
    
    @IsTest
    static void testGetTotalRebateByInstallments() {
        Id installmentId = [SELECT InstallmentLine__c FROM SalesOrderRebate__c LIMIT 1].InstallmentLine__c;
        Test.startTest();
        List<AggregateResult> results = SalesOrderRebateService.getInstance().getTotalRebateByInstallments(new Set<Id>{installmentId});
        Test.stopTest();
    }
    
    @IsTest
    static void testCreateRebateIntegrationRecord_Insert() {
        SalesOrderRebate__c rebate = [
            SELECT Id,
            SalesOrder__c,
            SalesOrder__r.Company_Code__c,
            SalesOrder__r.SAP_Contract_No__c,
            ConditionType__c,
            Date__c,
            Amount__c,
            SAP_Document_No__c
            FROM SalesOrderRebate__c
            WHERE SAP_Document_No__c != NULL
            LIMIT 1
        ];
        Test.startTest();
        IntegrationRecord__c integrationRecord = SalesOrderRebateService.getInstance().createRebateIntegrationRecord(rebate, 'Insert');
        Test.stopTest();
    }
    
    @IsTest
    static void testCreateRebateIntegrationRecord_Update() {
        SalesOrderRebate__c rebate = [
            SELECT Id,
            SalesOrder__c,
            SalesOrder__r.Company_Code__c,
            SalesOrder__r.SAP_Contract_No__c,
            ConditionType__c,
            Date__c,
            Amount__c
            FROM SalesOrderRebate__c
            LIMIT 1
        ];
        rebate.SAP_Document_No__c = null;
        Test.startTest();
        IntegrationRecord__c integrationRecord = SalesOrderRebateService.getInstance().createRebateIntegrationRecord(rebate, 'Update');
        Test.stopTest();
    }
}