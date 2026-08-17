@isTest
public class PaymentPlanOffPromotionServiceTest {
    
     @isTest 
    static void PaymentPlanOffPromotionServiceTestMethod(){
        
        Set<id>projectIds = new Set<id>();
        Map<Id,Set<Id>> buildingToPaymentPlanIds = new  Map<Id,Set<Id>>();
        Set<Id> buidlingIds = new Set<id>();
        Set<id>buildingpaymentplanid = new Set<id>();
        Set<String>offerNameSet = new Set<String>();
        List<PaymentPlan__c>paymentPlanlist = new List<PaymentPlan__c>();
        List<Unit__c>unitList = new List<Unit__c>();
            
         Project__c testProject=new Project__c(
            Name='Test Project'
        );
        insert testProject;
        
        projectIds.add(testProject.id);
        
         Id AccountRecordTypeId = [Select id,Name from RecordType where Name='Organization Account'].id;
        Account tempAcc=new Account(
            RecordTypeId=AccountRecordTypeId,
            Name= 'test'
            
        );
        insert tempAcc;
        
        
        Contact tempContact =new Contact(
            LastName='test',
            AccountId=tempAcc.id,
            Email='test@gmail.com'
        );
        insert tempContact;
        Opportunity tempOpp=new Opportunity(
            Name='tempOpp',
            StageName='New',
            CloseDate=system.today(),
            LeadChannel__c='Call',
          //  LeadSubSource__c='Open House',
            AccountId=tempAcc.Id,
            ContactId=tempContact.id,
            Contact__c=tempContact.id,
            WinReason__c='Loyalty'
        );
        insert tempOpp;
       
        
         OffersPromotions__c  offername = new OffersPromotions__c();
        offerName.OfferName__c = 'test offer';
        offerName.StartDate__c = system.today();
        offerName.EndDate__c=system.today().addDays(10);
        offerName.Project__c = testProject.id;
        insert offername;
        offerNameSet.add(offerName.OfferName__c);
        
         BuildingSection__c testBuilding=new BuildingSection__c(
            Name='Test Building',
            BuildingSectionCode__c='BL-CAS',
            Project__c=testProject.Id
            
        );
        insert testBuilding;
        buidlingIds.add(testBuilding.id);
        
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
        
          
        PaymentPlan__c  pp = new PaymentPlan__c();
        pp.Name ='July Plan';
        pp.Description__c ='Test Description';
        pp.IsActive__c ='No';
        insert pp;
        
         PaymentPlan__c  pp1 = new PaymentPlan__c();
        pp1.Name ='July Plan';
        pp1.Description__c ='Test Description';
        pp1.IsActive__c ='No';
        paymentPlanlist.add(pp1);
        
        BuildingSectionMapping__c bmp = new BuildingSectionMapping__c();
        bmp.BuildingSectionName__c =testBuilding.id;
        bmp.PaymentPlan__c =pp.id;
        insert bmp;
         buildingpaymentplanid.add(bmp.PaymentPlan__c);
        buildingToPaymentPlanIds.put(bmp.BuildingSectionName__c,buildingpaymentplanid);
        
         Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User'];
        User testUser = new User(
            Alias = 'standt',
            Email = 'standarduser@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = profile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'standarduser@testorg9847588474.com'
        );
        insert testUser;
          User testUser1 = [SELECT Id FROM User LIMIT 1];
        
         BookingMemo__c BM = new BookingMemo__c();
        insert BM;
        
        
        
       
       
        
        PaymentPlanOffPromotionService.getPaymentPlanByProjectIds(projectIds);
        PaymentPlanOffPromotionService.getSelectedOffersAndPromotions(offername.id);
        PaymentPlanOffPromotionService.getPaymentPlanIdsByBuidlingIds(buildingToPaymentPlanIds,buidlingIds);
        PaymentPlanOffPromotionService.insertPaymentPlan(paymentPlanlist);
       // PaymentPlanOffPromotionService.getListOfPaymentPlans(tempOpp,unitList,testUser);
        PaymentPlanOffPromotionService.getActiveOffersAndPromotions(buidlingIds,projectIds);
         PaymentPlanOffPromotionService.getSelectedOffersAndPromotions(offername.id);
         PaymentPlanOffPromotionService.getOffersPromotionsByName(offerNameSet);
        PaymentPlanOffPromotionService.getActiveOffersPromotions(tempOpp,unitList,testUser);
         PaymentPlanOffPromotionService.lastCreatedIdOffersPromotions(BM.id,testUnit.id);
        
        
        
    }

}