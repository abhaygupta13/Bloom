@isTest
public class reUsableSubStatusControllerTest {
    @isTest static void reUsableSubStatusControllerTestMethod(){
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
        OffersPromotions__c testOffer=new OffersPromotions__c(
            Name='testOffer',
            Unit__c=testUnit.id,
            OfferName__c='testOffer',
            Project__c=testProject.id,
            StartDate__c=system.today(),
            EndDate__c=system.today().addDays(2),
            BuildingSectionName__c=testBuilding.id
            
            
            
        );
        insert testOffer;
        
         OfferLines__c tempOffer=new OfferLines__c(
        	OfferType__c='Voucher',
            LowerBound__c=60,
            UpperBound__c=90,
            OfferName__c=testOffer.Id,
            OfferOn__c = 'Selling Price',
            BudgetTaskName__c ='ADM Fee',
           
             DiscountType__c = 'Additional Discount',
             OfferValue__c = 10,
             Nationality__c=null
             
        );
        insert tempOffer;
        
        
        
        
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
            Main_Buyer_Share_Percentage__c=40,
            Case_Sub_Status__c='In Progress'
        );
        insert tempCase;
        
        list<Sub_Status_Object_Fields_Config__mdt> sobjectConfigInfo=new list<Sub_Status_Object_Fields_Config__mdt>();
		sobjectConfigInfo=[select id,Backup_Remarks_API_Name__c,MasterLabel,Sub_Status_API_Name__c from Sub_Status_Object_Fields_Config__mdt where MasterLabel='SalesOrder__c'];        
        
        reUsableSubStatusController.getSubStatusValues(testOrder.id);
        reUsableSubStatusController.getSalesOrderStatus(testOrder.id);
        reUsableSubStatusController.getSubStatusValues(tempCase.id);
        reUsableSubStatusController.getSalesOrderStatus(tempCase.id);
        reUsableSubStatusController.getSalesOrderStatus('123');
		reUsableSubStatusController.getSobjectFieldInfo(testOrder.id);
        reUsableSubStatusController.updateSobjectRec(testOrder,sobjectConfigInfo);
    }
}