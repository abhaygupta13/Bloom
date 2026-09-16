@isTest
public class LeasingReceiptAutoClearanceBatchTest {
    @testsetup
    static void dataSetup(){  
        
        Id personAccountRecordTypeId = Utility.getRecordTypeIdByDevName(Account.SObjectType, 'PersonAccount');
        
        Account acc = new Account(
            RecordTypeId = personAccountRecordTypeId,
            LastName = 'Test Person Account',
            PersonEmail = 'test@test.com',
            AnnualIncome__pc = '1234'
        );
        insert acc;
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = System.today().addDays(30),
            OpportunityType__c = 'Leasing',
            AccountId = acc.Id
        );
        insert opp;
        
        Document__c doc = new Document__c(Document_Name__c='testDoc', Opportunity__c=opp.Id);
        insert doc;
        Project__c objProject = new Project__c();
        objProject.Name = 'Test Project';
        objProject.IsAvailableforLeasing__c = true;
        objProject.EjariTawtheeqFee__c = 200;
        objProject.AdminFee__c = 20;
        objProject.LeasingServiceCharge__c = 20;
        objProject.SecurityDeposit__c = 20;
        insert objProject;
        
        Building__c building = TestDataFactory.createBuilding('Building 1', objProject.Id);
        insert building;
        
        Unit__c unitRec = new Unit__c(Name='TestU', LeasingAnnualRent__c=10000,
                                      Project__c= objProject.Id, Building__c = building.Id, LeasingUnitStatus__c = 'Available',
                                      IsAvailableforLeasing__c = true, PropertyUsage__c = 'Commercial' );
        insert unitRec;
        
        LeasingOfferPromotion__c objLeasingOfferPromo = new LeasingOfferPromotion__c();
        objLeasingOfferPromo.Name = 'Test Promo';
        insert objLeasingOfferPromo;
        
        LeasingOfferLines__c objOfferLines = new LeasingOfferLines__c();
        objOfferLines.OfferName__c = objLeasingOfferPromo.Id;
        objOfferLines.OfferValueType__c = '%';
        objOfferLines.OfferValue__c = 1;
        objOfferLines.OfferType__c = 'Additional Discount';
        insert objOfferLines;
        
        // Insert Offer + OfferLine (required for getOfferLineDiscountSum)
        LeasingOffer__c offer = new LeasingOffer__c(Name='TestOffer', LeasingOfferPromotion__c=objLeasingOfferPromo.Id);
        insert offer;
        
        LeasingOrder__c lo = new LeasingOrder__c(
            Name = 'Test Contract',
            Opportunity__c = opp.Id,
            Account__c = acc.Id,
            LeasingStartDate__c = System.today(),
            LeasingEndDate__c = System.today().addMonths(12),
            LeasingContractMonths__c = 12,
            PaymentTerm__c = '4 Installments',
            unit__c = unitRec.id
        );
        insert lo;
        
        LeasingReceiptAcknowledgment__c receipt = new LeasingReceiptAcknowledgment__c(
            LeasingOrder__c = lo.Id,
            Amount__c = 10000,
            AppliedAmount__c = 500,
            BeingTowards__c = 'Rent Installment'
        );
        insert receipt;
        
        PaymentPlanSchedule__c schedule = new PaymentPlanSchedule__c(
                Name = 'Schedule ',
                LeasingOrder__c = lo.Id,
                RefDocno__c = '1235',
                Amount__c = 2000,
            	PaymentStartDate__c = Date.today().addDays(-1)
            );
        
        insert schedule;
        
        LeasingOrdersOtherCharges__c chargesList = new LeasingOrdersOtherCharges__c(
                LeasingOrder__c = lo.Id,
                Type__c = 'Admin Fee',
                ChargeAmount__c = 1000 ,
                VATAmount__c = 5,
                isVATApplied__c = true
            	
                
            );
        
        insert chargesList;
    }
    @isTest
    static void testBatchAndScheduler() {
        
       
        
        LeasingOrder__c order = createBasicOrder(false);
        Test.startTest();
        LeasingReceiptAutoClearanceBatch job = new LeasingReceiptAutoClearanceBatch();
        String cronExp = '0 0 13 * * ?'; // Runs daily at 1 PM
		System.schedule('My Job Name', cronExp, new LeasingReceiptAutoClearanceBatch());
        Database.executeBatch(job, 1);
        Test.stopTest();
        
    }
     // Utility to get Account RecordType Id by developer name
    private static Id getAccountRecordTypeId(String developerName) {
        return [SELECT Id FROM RecordType 
                WHERE SObjectType = 'Account' AND DeveloperName = :developerName 
                LIMIT 1].Id;
    }
    private static LeasingOrder__c createBasicOrder(Boolean isPerson) {
        Id recordTypeId = isPerson 
            ? getAccountRecordTypeId('PersonAccount')     // Adjust this to your org's Person Account record type
            : getAccountRecordTypeId('OrganizationAccount'); // Adjust this to your org's Business Account record type
        
        Account acc;
        if (isPerson) {
            acc = new Account(RecordTypeId = recordTypeId, LastName = 'Test Person', PersonEmail = 'areddy.spa@bloomholding.com', PersonMobilePhone = '00971111111111');
        } else {
            acc = new Account(RecordTypeId = recordTypeId, Name = 'Test Business');
        }
        insert acc;
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            AccountId = acc.Id
        );
        insert opp;
        
        //Creating Unit__c
        Unit__c objUnit = new Unit__c();
        objUnit.Name = 'Test unit';
        insert objUnit;
        
        LeasingOrder__c order = new LeasingOrder__c(
            Name = 'Test Leasing Order',
            Opportunity__c = opp.Id,
            Unit__c = objUnit.Id,
            Status__c = 'Leasing Offer',
            OfferValidityDays__c = 0.0 
        );
        insert order;
        
 // Set CreatedDate to 7 days ago
        Test.setCreatedDate(order.Id, DateTime.now().addDays(-7));

        
        return order;
    }
    
    @isTest static void testGetLeasingDetailsAmend() {
        LeasingOrder__c order = createBasicOrder(false);
        LeasingOrderService svc = LeasingOrderService.getInstance();
        LeasingOrder__c result = svc.getLeasingOrderById(order.Id);
        System.assertEquals(order.Id, result.Id);
    }
}