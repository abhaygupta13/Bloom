/*****************************************************************************************
Class       : LeasingReceiptAcknowledgementServiceTest
Author      : 
Description : 
Test Class  : 
Created Date: 
*****************************************************************************************/
@isTest
private class LeasingReceiptAcknowledgementServiceTest {
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
        
        // Insert sample escalation
        insert new LeasingEscalationSchedule__c(
            LeasingOrder__c = lo.Id, Year__c = 1,
            AfterDiscount__c = 12000
        );

        LeasingReceiptAcknowledgment__c receipt = new LeasingReceiptAcknowledgment__c(
            LeasingOrder__c = lo.Id,
            Amount__c = 10000
        );
        insert receipt;
        
    }
    @isTest
    static void getReceiptTest(){
       LeasingReceiptAcknowledgment__c receipt = [SELECT Id,LeasingOrder__c,Amount__c FROM LeasingReceiptAcknowledgment__c LIMIT 1];
       LeasingReceiptAcknowledgementService.getLeasingReceiptAcknowledgementByIds(new Set<Id>{receipt.Id}); 
    }

    @isTest
    static void updateLRATest(){
       LeasingReceiptAcknowledgment__c receipt = [SELECT Id,LeasingOrder__c,Amount__c FROM LeasingReceiptAcknowledgment__c LIMIT 1];
       receipt.Amount__c = 2000;
       LeasingReceiptAcknowledgementService service = LeasingReceiptAcknowledgementService.getInstance();
       service.updateOtherCharge(receipt); 
        service.createReceiptAckIntegrationRecord('C',new Set<Id>{receipt.Id},'LEASINGRECEIPT_SAP_INTEGRATION');
    }
    
    @isTest
    static void sendEmailAlertToFinanceOwnerOnDocumentUpdateTest(){
        LeasingReceiptAcknowledgment__c receipt = [SELECT Id, LeasingOrder__c, LeasingOrder__r.OwnerId FROM LeasingReceiptAcknowledgment__c LIMIT 1];
    
        User owner = [SELECT Id, Email FROM User WHERE Id = :receipt.LeasingOrder__r.OwnerId];
        owner.Email = 'testowner@example.com';
        update owner;
    
        insert new Task(
            Subject = 'Finance Task - Review',
            WhatId = receipt.LeasingOrder__c,
            OwnerId = UserInfo.getUserId(),
            Status = 'Open'
        );
    
        EmailTemplate validTemplate = [SELECT Id FROM EmailTemplate WHERE IsActive = true LIMIT 1];
        OrgWideEmailAddress owa = [SELECT Id FROM OrgWideEmailAddress LIMIT 1];
    
        ContentVersion cv = new ContentVersion(Title = 'TestDoc', PathOnClient = 'Test.pdf', VersionData = Blob.valueOf('Test'), IsMajorVersion = true);
        insert cv;
        Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
        insert new ContentDocumentLink(LinkedEntityId = receipt.Id, ContentDocumentId = conDocId, ShareType = 'V');
    
        Test.startTest();
        LeasingReceiptAcknowledgementService.sendEmailAlertToFinanceOwnerOnDocumentUpdate(new Set<Id>{receipt.Id});
        Test.stopTest();
    }
    
     @isTest
     static void TestDuplicateReceipt(){
        LeasingReceiptAcknowledgment__c receipt = [SELECT Id, ReferenceNumber__c, ChequeNumber__c, BankName__c  FROM LeasingReceiptAcknowledgment__c LIMIT 1];
    	
        receipt.ReferenceNumber__c = '1234';
        receipt.BankName__c = 'Bank of Sharjah';
        Test.startTest();
        LeasingReceiptAcknowledgementService.getDuplicateReceipt(receipt);
        Test.stopTest();
    }
}