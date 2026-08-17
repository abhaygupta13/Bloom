/*****************************************************************************************
Class       : SalesOrderRebateTriggerHandlerTest
Author      : Dhanraj Poojary
Description : SalesOrderRebateTriggerHandler Test Class 
Created Date: 16 JUL 2026
*****************************************************************************************/

@IsTest
private class SalesOrderRebateTriggerHandlerTest {

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
    }
    
    @IsTest
    static void testInsertRebate_SendToSAPTrue() {
        SalesOrder__c so = [SELECT Id FROM SalesOrder__c LIMIT 1];
        InstallmentLines__c line = [SELECT Id FROM InstallmentLines__c LIMIT 1];
        Test.startTest();
        insert new SalesOrderRebate__c(SalesOrder__c = so.Id,InstallmentLine__c = line.Id,Amount__c = 100,Date__c = Date.today());
        Test.stopTest();
    }
    
    @IsTest
    static void testInsertRebate_SendToSAPFalse() {
        SalesOrder__c so = [SELECT Id FROM SalesOrder__c LIMIT 1];
        InstallmentLines__c line = [SELECT Id FROM InstallmentLines__c LIMIT 1];
        Test.startTest();
        insert new SalesOrderRebate__c(SalesOrder__c = so.Id,InstallmentLine__c = line.Id,Amount__c = 100,Date__c = Date.today(),SendtoSAP__c = false);
        Test.stopTest();
    }

    @IsTest
    static void testUpdateSendToSAP() {
        SalesOrder__c so = [SELECT Id FROM SalesOrder__c LIMIT 1];
        InstallmentLines__c line = [SELECT Id FROM InstallmentLines__c LIMIT 1];
        SalesOrderRebate__c rebate = new SalesOrderRebate__c(SalesOrder__c = so.Id,InstallmentLine__c = line.Id,Amount__c = 100,Date__c = Date.today(),SendtoSAP__c = false);
        insert rebate;
        Test.startTest();
        rebate.SendtoSAP__c = true;
        update rebate;
        Test.stopTest();
    }

    @IsTest
    static void testUpdateAmount() {
        SalesOrder__c so = [SELECT Id FROM SalesOrder__c LIMIT 1];
        InstallmentLines__c line = [SELECT Id FROM InstallmentLines__c LIMIT 1];
        SalesOrderRebate__c rebate = new SalesOrderRebate__c(SalesOrder__c = so.Id,InstallmentLine__c = line.Id,Amount__c = 100,Date__c = Date.today(),SendtoSAP__c = false);
        insert rebate;
        Test.startTest();
        rebate.Amount__c = 999;
        update rebate;
        Test.stopTest();
        delete rebate;
    }
}