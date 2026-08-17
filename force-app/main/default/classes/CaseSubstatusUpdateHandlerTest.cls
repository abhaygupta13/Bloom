@isTest
public class CaseSubstatusUpdateHandlerTest {
    
    @isTest static void CaseSubstatusUpdateHandlerTestMethod(){
        
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
            SellingPrice__c= 700000,
            EndDate__c= date.today()+10,
            StartDate__c=date.today()-10
            
        );
        insert testUnit;
        
        Unit__c testUnit1=new Unit__c(
            Name='test Unit1',
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
        insert testUnit1;
        
        
        
        
        PaymentPlan__c  pp = new PaymentPlan__c();
        pp.Name ='July Plan';
        pp.Unit__c= testUnit.id;
        pp.Description__c ='Test Description';
        pp.Description__c = 'Test';
        pp.IsActive__c = 'NO';
        pp.BrokerPortalFlag__c = True;
        pp.CustomerSubType__c ='CORPORATE';
        pp.Classification__c = Constants.PAYMENT_PLAN_TYPE_STANDARD;
        
        insert pp;
        
        BuildingSectionMapping__c mappingRecord = new BuildingSectionMapping__c();
        mappingRecord.BuildingSectionName__c = testBuilding.id;
        mappingRecord.PaymentPlan__c = pp.id;
        insert mappingRecord;
        
        
        
        
        Id AccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        Account tempAcc=new Account(
            RecordTypeId=AccountRecordTypeId,
            LastName= 'test',
            personEmail='Jana@tesrt.com',
            CustomerSubType__c ='CORPORATE'
            
        );
        insert tempAcc;
        
        
        Opportunity tempOpp=new Opportunity(
            Name='tempOpp',
            StageName='New',
            CloseDate=system.today(),
            LeadChannel__c='Walk in',
            AccountId=tempAcc.Id,
            WinReason__c='Loyalty'
        );
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
        
        testUnit.Status__c ='Booked';
        testUnit.LockedBy__c = Userinfo.getUserId();
        update testUnit;
        
        SalesOrder__c testOrder = new SalesOrder__c(
            Name = 'Test Order',
            Status__c = 'Booked',
            Unit__c =testUnit.id,
            Account__c = tempAcc.Id,
            Opportunity__c=tempOpp.Id
            
            
        );
        insert testOrder;
        
        
        Case tempCase=new Case(
            CurrencyIsoCode='AED',
            Status='In Progress',
            Origin='Email',
            type='Transfer of Right',
            Main_Buyer_Share_Percentage__c=40,
            Case_Sub_Status__c= 'Transfer Completed'
        );
        insert tempCase;
        
        Case tempCase1=new Case(
            CurrencyIsoCode='AED',
            Status='In Progress',
            Origin='Email',
            type='Transfer of Right',
            Main_Buyer_Share_Percentage__c=40,
            Case_Sub_Status__c= 'Full Requirements Received'
        );
        
        Sales_Validation__c testSalesValidation = new Sales_Validation__c(
            Case__c = tempCase.Id,
            Approver_Validated_Flag__c = '',
            Validation_Sub_Type__c = 'Deposit Cleared',
            Sales_Order__c=testOrder.id
            
        );
        insert testSalesValidation;
        
        
        CaseSubstatusUpdateHandler.getSubStatusValues(tempCase.id);
         CaseSubstatusUpdateHandler.getCaseStatus(tempCase.id);
        CaseSubstatusUpdateHandler.getNextApplicableStatus('In-Progress',tempCase.id);
        CaseSubstatusUpdateHandler.updateCase(tempCase);
        
        CaseSubstatusUpdateHandler.checkRequiredFlag(tempCase.id,'Transfer Completed');
        
        case ca= new case();
        ca.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Resale').getRecordTypeId();
        ca.Type = 'Transfer of Right';
        ca.Status = 'New';
        ca.Case_Sub_Status__c = 'Created';
        ca.Sales_Order__c = testOrder.id;
        insert ca;
    }
     @isTest static void ExcepitonTestMethod(){
         case ca= new case();
         try{
             CaseSubstatusUpdateHandler.updateCase(ca);
         }Catch(Exception E){
             
         }
     }
    
    
    
}