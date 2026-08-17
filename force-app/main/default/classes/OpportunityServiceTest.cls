@isTest
public class OpportunityServiceTest {
    @isTest static void OpportunityServiceTestMethod(){
        
        Set<id>accountIds = new Set<id>();
        Set<id>opportunityIds = new Set<id>();
        Set<id>projectBudgetIds = new Set<id>();
        Set<id>salesorderIds = new Set<id>();
        Set<String>StringsalesorderIds = new Set<String>();
        Set<String>StringOpportunityIds = new Set<String>();
        List<Account>accList = new List<Account>();
        List<Id>soList = new List<Id>();
        List<SalesOrder__c>SalesOrderList = new List<SalesOrder__c>();
        Map<id,Account>accMap = new Map<id,Account>();
        Map<String, String> mapFieldApiFieldValues = new Map<String, String>();
        
        Map<id,opportunity> oppMap = new Map<id,opportunity>();
        
        List<MemoLines__c> memoLinesList = new List<MemoLines__c>();
        List<user> ulist = [select id from user where Profile.Name ='System Administrator' AND IsActive = true limit 1];
        Id AccountRecordTypeId = [Select id,Name from RecordType where Name='Organization Account'].id;
        Account tempAcc=new Account(
            RecordTypeId=AccountRecordTypeId,
            Name= 'test'
            
        );
        
        insert tempAcc;
        accountIds.add(tempAcc.id);
        accList.add(tempAcc);
        accMap.put(tempAcc.id,tempAcc);
        
        
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
            LeadChannel__c='Walk in',
            AccountId=tempAcc.Id,
            ContactId=tempContact.id,
            Contact__c=tempContact.id,
            WinReason__c='Loyalty'
        );
        insert tempOpp;
        opportunityIds.add(tempOpp.id);
        StringOpportunityIds.add(tempOpp.id);
        oppMap.put(tempOpp.id,tempOpp);
        
        Lead testLead = new Lead();
        testLead.LastName = 'Test Lead';
        testLead.MobileCountryCode__c = '971';
        testLead.Status = 'New';
        testLead.MobilePhone = '37829292020';
        testLead.Email = 'testlead@example.com';
        testLead.Lead_Channel__c = 'Call';
        testLead.OwnerId = ulist[0].id;
        testLead.BrokerAgency__c = tempAcc.id;
        testLead.BrokerAgent__c = tempContact.id;
        // Insert the test lead
        try{
            insert testLead;
        }catch(Exception E){
            
        }
        
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
        
        
        
        Project__c testProject=new Project__c(
            Name='Test Project'
        );
        insert testProject;
        
        OffersPromotions__c  offername = new OffersPromotions__c();
        offerName.OfferName__c = 'test offer';
        offerName.StartDate__c = system.today();
        offerName.EndDate__c=system.today().addDays(10);
        offerName.Project__c = testProject.id;
        
        
        insert offername;
        
        OfferLines__c offerLine = new OfferLines__c();
        offerLine.OfferName__c = offername.Id;
        offerLine.OfferType__c='Additional Discount';
        offerLine.OfferOn__c= 'Selling Price';
        offerLine.OfferValue__c =20000;
        
        insert offerLine;
        
        String testQuery = 'SELECT Id, Name FROM OfferLines__c WHERE Name = \'test offer\''; 
        
        BookingMemo__c BM = new BookingMemo__c();
        insert BM;
        
        
        MemoLines__c memo = new MemoLines__c();
        memo.BookingMemo__c = BM.id;
        //memo.AdditionalDiscountPercentage__c=10;
        if(memo.AdditionalDiscountPercentage__c>0){
            memo.AdditionalDiscountPercentage__c = 1;
        }
        
        
        insert memo;
        
        memoLinesList.add(memo);
        
        BuildingSection__c testBuilding=new BuildingSection__c(
            Name='Test Building',
            BuildingSectionCode__c='BL-CAS',
            Project__c=testProject.Id
            
        );
        insert testBuilding;
        
        Unit__c testUnit=new Unit__c(
            Name='test Unit',
            Status__c='Booked',
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
        
    
        
        
        SalesOrder__c testOrder = new SalesOrder__c(
            Name = 'Test Order',
            Status__c = 'Booked',
            Contact__c=tempContact.id,
            Unit__c =testUnit.id,
            Account__c = tempAcc.Id,
            Opportunity__c=tempOpp.Id
            
            
        );
        insert testOrder;
        salesorderIds.add(testOrder.id);
        soList.add(testOrder.Id);
        SalesOrderList.add(testOrder);
        StringsalesorderIds.add(testOrder.Id);
        mapFieldApiFieldValues.put(testOrder.SalesManager__c,testUser.id);
        
        
        
        OpportunityService.updateOpportunityStage(tempOpp.id,'Proposal');
        OpportunityService.updateOpportunityStage(tempOpp.id,'Meeting');
        OpportunityService.updateOpportunityStage(tempOpp.id,'closedWon');
        OpportunityService.fetchOpportunityForAPIByUser(testUser.Id);
        OpportunityService.getAllOpportunitys(accountIds,accList);
        OpportunityService.getOpportunityForAccount(accMap);
        OpportunityService.getOpportunityDetailsbyId(tempOpp.Id);
        OpportunityService.getOpportunityDetailsMapbyId(tempOpp.Id);
        OpportunityService.opportunityFieldsValidation(tempOpp.Id);
        OpportunityService.fetchOpportunityNumber(opportunityIds);
        OpportunityService.fetchOpportunityById(tempOpp.Id);
        OpportunityService.getLeadDetailsMapbyId(testLead.Id);
        OpportunityService.getOfferLinesQuery(testQuery);
        OpportunityService.insertOfferLines(memoLinesList,offername.Id);
        OpportunityService.getMandatoryDocsStatus(testOrder);
        OpportunityService.getSalesOrderByAccountId(accountIds);
        OpportunityService.getSalesOrderRec(testOrder.Id);
        OpportunityService.getAccountOpportunityUnitMap(accountIds);
        OpportunityService.getOpportunitySalesOrderMap(opportunityIds);
       
        
        OpportunityService.getAllSalesOrdersAccountIds(salesorderIds);
        OpportunityService.getSalesOrdersAccountIds(testOrder.Id);
        OpportunityService.getSalesOrderByAccountId(accountIds);
        OpportunityService.fetchSalesOrderByAccountId(tempAcc.Id);
        OpportunityService.fetchSalesOrderForAPIByUser(testUser.Id);
        OpportunityService.queryAllFieldsWithExtraFields(soList);
        OpportunityService.getAccountWithJointOwners(testOrder.Id);
        OpportunityService.newOpportunityUnitRecord(SalesOrderList);
        OpportunityService.cancelSalesOrderReservation(StringsalesorderIds);
        OpportunityService.getOpportunityUnitByAccountId(accountIds);
        OpportunityService.getSalesOrderByOpportunityId(tempOpp.Id);
        OpportunityService.getSalesOrderByOpportunityIdSet(opportunityIds);
        OpportunityService.getSalesOrderByUnitId(testUnit.id);
        OpportunityService.fetchOpportunitiesByAccountId(tempAcc.id);
        OpportunityService.getValidationFields();
       
        OpportunityService.fetchOpportunities(null);
        OpportunityService.fetchSalesOrders(null);
        
        OpportunityService oppServiceInstance= OpportunityService.getInstance();
        oppServiceInstance.updateOpportunitiesWithoutTrigger(oppMap.values());
        oppServiceInstance.updateOpportunityWithoutTrigger(oppMap.values()[0]);
        /*
        Map<String,OfferLinesService__mdt> OfferLineServiceMap = Utilities.getOfferLineService();
        OfferLinesService__mdt mtd = new OfferLinesService__mdt();
        mtd.DiscountType__c = 'additional';
        mtd.OfferValueType__c='Additional';
        OfferLineServiceMap.put('AdditionalDiscountPercentage__c',mtd);
        
        //OpportunityService.getOfferLinesService(memo, 'AdditionalDiscountPercentage__c', offername.id,OfferLineServiceMap);
        // Map<String,OfferLinesService__mdt> OfferLineServiceMap
       */
        
        
        
        
        
        
        
        
        
        
        
    }
}