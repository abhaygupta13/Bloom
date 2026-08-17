/*****************************************************************************************
Class       : LeasingOfficerCommissionServiceTest
Author      : 
Description : 
Test Class  : 
Created Date: 
*****************************************************************************************/
@isTest
private class LeasingOfficerCommissionServiceTest {
    @testSetup
    static void dataSetup(){ 
        Id personAccountRecordTypeId = Utility.getRecordTypeIdByDevName(Account.SObjectType, 'PersonAccount');
        
        Account acc = new Account(
            RecordTypeId = personAccountRecordTypeId,
            LastName = 'Test Person Account', 
            Phone = '971202520',
            PersonEmail='abc@gmail.com',
            Nationality__c = 'Indian',
            
            PrimaryMobilePhone__pc = '1234567890',
            
            SecondaryMobilePhone__pc = '9876543210',
            
            TertiaryMobilePhone__pc = '1122334455'
        );
        insert acc;
        
        DocumentType__c dc1 = TestDataFactory.createDocumentType('Opportunity', 'Emirates ID');
        dc1.Customer_Type__c = 'Individual';
        insert dc1;
        
        DocumentType__c dc2 = TestDataFactory.createDocumentType('Opportunity', 'Visa');
        dc2.Customer_Type__c = 'Individual';
        insert dc2;
        
        DocumentType__c dc3 = TestDataFactory.createDocumentType('LeasingOrder__c', 'Emirates ID');
        dc3.Customer_Type__c = 'Individual';
        insert dc3;
        
        DocumentType__c dc4 = TestDataFactory.createDocumentType('LeasingOrder__c', 'Visa');
        dc4.Customer_Type__c = 'Individual';
        insert dc4;
        
        DocumentType__c dc5 = TestDataFactory.createDocumentType('LeasingOrder__c', 'Leasing Offer');
        dc5.Customer_Type__c = 'Individual';
        insert dc5;
        
        DocumentType__c dc6 = TestDataFactory.createDocumentType('Opportunity', 'Leasing Offer');
        dc6.Customer_Type__c = 'Individual';
        insert dc6;
        
        
        Opportunity opp = new Opportunity(
            Name='Test Opp',
            StageName='Prospecting',
            OpportunityType__c = 'Leasing',
            CloseDate=System.today().addDays(30),
            AccountId=acc.Id
        );
        insert opp;
        
        Document__c doc = new Document__c(Document_Name__c='testDoc', Opportunity__c=opp.Id);
        insert doc;
        
        //Project__c
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
        
        // Insert minimal LeasingOrder
        LeasingOrder__c lo = new LeasingOrder__c(
            Name='Test Contract',
            Opportunity__c = opp.Id,
            Account__c = acc.Id,
            Unit__c = unitRec.Id,
            LeasingStartDate__c = System.today(),
            LeasingEndDate__c = System.today().addYears(1),
            LeasingContractMonths__c=12,
            PaymentTerm__c='4 Installments',
            SecurityDeposit__c = 100,
            ExtraChequeFee__c  = 200,
            AdminFee__c = 100,
            FitOutSecurityDeposit__c  = 300,
            EjariTawtheeqFee__c = 200
            
        );
        insert lo;
    } 
    
    @isTest
    static void insertPaymentAllocationTest(){
        LeasingOrder__c order = [Select Id,OwnerId from LeasingOrder__c limit 1];
        LeasingOfficerCommission__c loc = new LeasingOfficerCommission__c();
        loc.Name = ' Leasing Commission' ;
        loc.LeasingOrder__c = order.id ;
        loc.SAPConditionTypeCode__c = 'R057';
        loc.Commission_Amount__c = 100.00;
        loc.LeasingOfficer__c = order.OwnerId;
        LeasingOfficerCommissionService service = LeasingOfficerCommissionService.getInstance();
        service.insertLOC(loc); 
        loc.Commission_Amount__c = 150.00;
        service.updateLOC(loc);   
    }
}