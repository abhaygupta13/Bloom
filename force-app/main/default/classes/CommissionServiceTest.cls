@isTest
public class CommissionServiceTest {
 @isTest static void CommissionServiceTestMethod(){
     List<Unit__c>unitList = new List<Unit__c>();
     List<BrokerCommission__c> applicableCommissions=new List<BrokerCommission__c>();
     Map<Id,OffersPromotions__c> unitToOfferMap = new Map<Id,OffersPromotions__c>();
     Set<id>projectIds = new Set<id>();
        Set<id>buildingIds = new Set<id>();
     
    
        Account tempAcc=new Account(
            
            Name= 'test'
            
        );
        
        insert tempAcc;
       
        
        
        Contact tempContact =new Contact(
            LastName='test',
            AccountId= tempAcc.id,
            Email='test@gmail.com'
        );
        insert tempContact;
        Opportunity tempOpp=new Opportunity(
            Name='tempOpp',
            StageName='New',
            CloseDate=system.today(),
            LeadChannel__c='Walk in',
            AccountId=tempAcc.Id,
            ContactId=tempContact.id,
            Contact__c=tempContact.id,
            WinReason__c='Loyalty'
        );
        insert tempOpp;
     
        
        Project__c testProject=new Project__c(
            Name='Test Project'
        );
        insert testProject;
        projectIds.add(testProject.id);
        
        BuildingSection__c testBuilding=new BuildingSection__c(
            Name='Test Building',
            BuildingSectionCode__c='BL-CAS',
            Project__c=testProject.Id
            
        );
        insert testBuilding;
       buildingIds.add(testBuilding.id);
        
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
     unitList.add(testUnit);
         OffersPromotions__c  offername = new OffersPromotions__c();
        offerName.OfferName__c = 'test offer';
        offerName.Unit__c = testUnit.id;
        offerName.StartDate__c = system.today();
        offerName.EndDate__c=system.today().addDays(10);
        offerName.Project__c = testProject.id;
        
        
        insert offername;
     
       unitToOfferMap.put(testUnit.id,offername);
        
        OfferLines__c offerLine = new OfferLines__c();
        offerLine.OfferName__c = offername.Id;
        offerLine.OfferType__c='Additional Discount';
        offerLine.OfferOn__c= 'Selling Price';
        offerLine.OfferValue__c =20000;
        
        insert offerLine;
        
        String testQuery = 'SELECT Id, Name FROM OfferLines__c WHERE Name = \'test offer\''; 
       
        
        
        SalesOrder__c testOrder = new SalesOrder__c(
            Name = 'Test Order',
            Status__c = 'Booked',
            Contact__c=tempContact.id,
            Unit__c =testUnit.id,
            Account__c = tempAcc.Id,
            Opportunity__c=tempOpp.Id
            
            
        );
        insert testOrder;
     
     InternalCommission__c internalCommission = new InternalCommission__c();
        internalCommission.DirectCommission__c = 2.5;
        internalCommission.IndirectCommission__c = 1.5;
        internalCommission.StaffReferral__c = 2.5;
        internalCommission.UserRole__c = 'Sales Manager';
        internalCommission.InventoryLaunchCategory__c = 'Launch';
        internalCommission.StartDate__c = Date.today();
        internalCommission.EndDate__c = Date.today().addDays(30);
        internalCommission.SalesValueFrom__c = 5;
        internalCommission.SaleValueTo__c = 1000000000;
        internalCommission.Project__c = testProject.id;
        insert internalCommission;
     
      BrokerCommission__c brokerCommission = new BrokerCommission__c();
        brokerCommission.Project__c = testProject.id;
        brokerCommission.CommissionPercentage__c = 2.5;
        brokerCommission.UnitView__c = 'Sea View';
        brokerCommission.UnitCategory__c = 'S-4';
        brokerCommission.StartDate__c = Date.today();
        brokerCommission.EndDate__c = Date.today().addDays(30);
        brokerCommission.BuildingSection__c=testBuilding.id;
        brokerCommission.OfferPromotion__c =offername.id;
        insert brokerCommission;
        applicableCommissions.add(brokerCommission);
     
     CommissionService.getActiveInternalCommissions();
     CommissionService.getInternalCommissionsByProject();
     CommissionService.getInternalCommissions(tempOpp,unitList,unitToOfferMap);
     CommissionService.getActiveBrokerCommissions(projectIds,buildingIds);
      CommissionService.getExternalCommissions(tempOpp,unitList,unitToOfferMap);
     CommissionService.getBrokerCommissions(tempOpp,unitList,unitToOfferMap);
     CommissionService.getExternalCommissionRecord(tempOpp,testUnit,applicableCommissions,offername);
 }
}