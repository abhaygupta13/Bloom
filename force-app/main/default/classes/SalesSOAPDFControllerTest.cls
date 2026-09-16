/***
Class       : SalesSOAPDFControllerTest
Author      : Dhanraj Poojary
Description : Test class for SalesSOAPDFController
****************************************************************************************************************/
@IsTest
public class SalesSOAPDFControllerTest {
    
    @IsTest
    static void testDocumentGenerationPDFHandler() {
        // Project
        Project__c project = new Project__c(Name = 'Test Project');
        insert project;
        
        // Building Section
        BuildingSection__c building = new BuildingSection__c(Name = 'Test Building',BuildingSectionCode__c = 'BL-CAS',Project__c = project.Id);
        insert building;
        
        // Unit
        Unit__c unit = new Unit__c(
            Name = 'Test Unit',
            Status__c = 'Booked',
            UnitType__c = 'Townhouse',
            BuildingSectionName__c = building.Id,
            Project__c = project.Id,
            PropertyUsage__c = 'Residential',
            UnitView__c = 'Beach Side',
            FloorNumber__c = '01',
            NumberOfBedrooms__c = '3',
            UnitModel__c = '1BHK',
            SellingPrice__c = 700000,
            StartDate__c = Date.today().addDays(-10),
            EndDate__c = Date.today().addDays(10),
            LockExpiryTime__c = DateTime.now().addDays(10),
            LockedBy__c = UserInfo.getUserId()
        );
        insert unit;
        
        // Payment Plan
        PaymentPlan__c plan = new PaymentPlan__c(Name = 'July Plan',Unit__c = unit.Id,Description__c = 'Test',BrokerPortalFlag__c = true,CustomerSubType__c = 'CORPORATE',Classification__c = Constants.PAYMENT_PLAN_TYPE_STANDARD);
        insert plan;
        
        // Plan Mapping
        insert new BuildingSectionMapping__c(BuildingSectionName__c = building.Id,PaymentPlan__c = plan.Id);
        
        // Person Account
        Id personRT = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        
        Account person = new Account(RecordTypeId = personRT,LastName = 'Test',PersonEmail = 'test@test.com',CustomerSubType__c = 'CORPORATE');
        insert person;
        
        // Opportunity
        Opportunity opp = new Opportunity(Name = 'Temp Opp',StageName = 'New',CloseDate = Date.today(),LeadChannel__c = 'Walk in',AccountId = person.Id,WinReason__c = 'Loyalty');
        insert opp;
        
        // Payment Installments
        PaymentInstallments__c installmentDef = new PaymentInstallments__c(BrokerPayoutPercentage__c = 100,Description__c = 'Test Installment',InstallmentNumber__c = 1,InstallmentPercentage__c = 100,PaymentPlan__c = plan.Id,Condition_Type__c = 'P012');
        insert installmentDef;
        
        // Offer
        OffersPromotions__c offer = new OffersPromotions__c(Name = 'Test Offer',OfferName__c = 'Test Offer',Project__c = project.Id,StartDate__c = Date.today(),EndDate__c = Date.today().addDays(2),ADM_Fee_Included__c = true);
        insert offer;
        
        // Sales Order
        SalesOrder__c order = new SalesOrder__c(Name = 'Test Order',Status__c = 'Booked',Unit__c = unit.Id,Account__c = person.Id,Opportunity__c = opp.Id,Bloom_Signed_SPA_Date__c = Date.today(),Offer__c = offer.Id);
        insert order;
        
        // Installment Lines
        InstallmentLines__c inst1 = new InstallmentLines__c(
            SalesOrder__c = order.Id,
            PaymentPlan__c = plan.Id,
            PaymentInstallments__c = installmentDef.Id,
            InstallmentAmount__c = 70000,
            InstallmentDate__c = Date.today().addDays(-12),
            InstallmentPercentage__c = 25,
            LPCAmount__c = 500,
            Description__c = 'Test',
            InstallmentNumber__c = 1
        );
        insert inst1;
        
        InstallmentLines__c inst2 = inst1.clone(false, false, false, false);
        inst2.InstallmentNumber__c = 2;
        insert inst2;
        Test.startTest();
        // Receipt Acknowledgments
        ReceiptAcknowledgement__c ackCleared = new ReceiptAcknowledgement__c(
            PaymentType__c = 'Online',
            Opportunity__c = opp.Id,
            Amount__c = 1200000,
            MaturityDate__c = Date.today(),
            SalesOrder__c = order.Id,
            Status__c = 'Cleared'
        );
        insert ackCleared;
        List<ReceiptAcknowledgement__c> lstReceiptAck = new List<ReceiptAcknowledgement__c>();
        ReceiptAcknowledgement__c ackReceived = ackCleared.clone(false, false, false, false);
        ackReceived.Status__c = 'Received';
        lstReceiptAck.add(ackReceived);
        
        ReceiptAcknowledgement__c ackReceived1 = ackCleared.clone(false, false, false, false);
        ackReceived1.Status__c = 'Entered';
        ackReceived1.SAP_Special_GL_Indicator__c = 'X';
        lstReceiptAck.add(ackReceived1);
        
        ReceiptAcknowledgement__c ackReceived2 = ackCleared.clone(false, false, false, false);
        ackReceived2.Status__c = 'Entered';
        ackReceived2.SAP_Special_GL_Indicator__c = 'V';
        lstReceiptAck.add(ackReceived2);
        insert lstReceiptAck;
        // Other Charges
        SalesOrderOtherCharges__c other = new SalesOrderOtherCharges__c(
            SalesOrder__c = order.Id,
            Account__c = person.Id,
            TypeOfCharge__c = 'ADM Fee',
            Amount__c = 10000,
            Due_Date__c = Date.today()
        );
        insert other;
        
        // Receipt Allocations
        insert new ReceiptAllocation__c(
            ReceiptAcknowledgement__c = ackCleared.Id,
            Account__c = person.Id,
            SalesOrder__c = order.Id,
            AmountApplied__c = 12000,
            InstallmentLine__c = inst1.Id
        );
        
        insert new ReceiptAllocation__c(
            ReceiptAcknowledgement__c = ackReceived.Id,
            Account__c = person.Id,
            AmountApplied__c = 12000,
            SalesOrder__c = order.Id,
            InstallmentLine__c = inst1.Id,
            SalesOrderOtherCharges__c = other.Id
        );
        
        insert new ReceiptAllocation__c(
            ReceiptAcknowledgement__c = ackReceived.Id,
            Account__c = person.Id,
            AmountApplied__c = 12000,
            SalesOrder__c = order.Id,
            InstallmentLine__c = inst1.Id
        );
        
        insert new ReceiptAllocation__c(
            ReceiptAcknowledgement__c = ackReceived1.Id,
            Account__c = person.Id,
            AmountApplied__c = 0,
            SalesOrder__c = order.Id
        );
        
        insert new ReceiptAllocation__c(
            ReceiptAcknowledgement__c = ackReceived2.Id,
            Account__c = person.Id,
            AmountApplied__c = 0,
            SalesOrder__c = order.Id
        );
        
        
        // -----------------------------
        // 2. Invoke VF Page
        // -----------------------------
        Test.setCurrentPage(Page.ReceiptAcknowledgementPDF);
        ApexPages.currentPage().getParameters().put('id', order.Id);
        
        
        
        SalesSOAPDFController handler = new SalesSOAPDFController();
        
        String contentId = SalesOrderController.generateSOAAndAttachPdf(order.Id, 'generateReceipt');
        System.assertNotEquals(null, contentId);
        
        Test.stopTest();
    }
    
    @IsTest
    static void testDocumentGenerationPDFHandler1() {
        // Project
        Project__c project = new Project__c(Name = 'Test Project');
        insert project;
        
        // Building Section
        BuildingSection__c building = new BuildingSection__c(Name = 'Test Building',BuildingSectionCode__c = 'BL-CAS',Project__c = project.Id);
        insert building;
        
        // Unit
        Unit__c unit = new Unit__c(
            Name = 'Test Unit',
            Status__c = 'Booked',
            UnitType__c = 'Townhouse',
            BuildingSectionName__c = building.Id,
            Project__c = project.Id,
            PropertyUsage__c = 'Residential',
            UnitView__c = 'Beach Side',
            FloorNumber__c = '01',
            NumberOfBedrooms__c = '3',
            UnitModel__c = '1BHK',
            SellingPrice__c = 700000,
            StartDate__c = Date.today().addDays(-10),
            EndDate__c = Date.today().addDays(10),
            LockExpiryTime__c = DateTime.now().addDays(10),
            LockedBy__c = UserInfo.getUserId()
        );
        insert unit;
        
        // Payment Plan
        PaymentPlan__c plan = new PaymentPlan__c(Name = 'July Plan',Unit__c = unit.Id,Description__c = 'Test',BrokerPortalFlag__c = true,CustomerSubType__c = 'CORPORATE',Classification__c = Constants.PAYMENT_PLAN_TYPE_STANDARD);
        insert plan;
        
        // Plan Mapping
        insert new BuildingSectionMapping__c(BuildingSectionName__c = building.Id,PaymentPlan__c = plan.Id);
        
        // Person Account
        Id personRT = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        
        Account person = new Account(RecordTypeId = personRT,LastName = 'Test',PersonEmail = 'test@test.com',CustomerSubType__c = 'CORPORATE');
        insert person;
        
        // Opportunity
        Opportunity opp = new Opportunity(Name = 'Temp Opp',StageName = 'New',CloseDate = Date.today(),LeadChannel__c = 'Walk in',AccountId = person.Id,WinReason__c = 'Loyalty');
        insert opp;
        
        // Payment Installments
        PaymentInstallments__c installmentDef = new PaymentInstallments__c(BrokerPayoutPercentage__c = 100,Description__c = 'Test Installment',InstallmentNumber__c = 1,InstallmentPercentage__c = 100,PaymentPlan__c = plan.Id,Condition_Type__c = 'P012');
        insert installmentDef;
        
        // Offer
        OffersPromotions__c offer = new OffersPromotions__c(Name = 'Test Offer',OfferName__c = 'Test Offer',Project__c = project.Id,StartDate__c = Date.today(),EndDate__c = Date.today().addDays(2),ADM_Fee_Included__c = false);
        insert offer;
        
        // Sales Order
        SalesOrder__c order = new SalesOrder__c(Name = 'Test Order',Status__c = 'Booked',Unit__c = unit.Id,Account__c = person.Id,Opportunity__c = opp.Id,Bloom_Signed_SPA_Date__c = Date.today(),Offer__c = offer.Id);
        insert order;
        
        // Installment Lines
        InstallmentLines__c inst1 = new InstallmentLines__c(
            SalesOrder__c = order.Id,
            PaymentPlan__c = plan.Id,
            PaymentInstallments__c = installmentDef.Id,
            InstallmentAmount__c = 70000,
            InstallmentDate__c = Date.today().addDays(-12),
            InstallmentPercentage__c = 25,
            LPCAmount__c = 500,
            Description__c = 'Test',
            InstallmentNumber__c = 1
        );
        insert inst1;
        
        
        Test.startTest();
        // Receipt Acknowledgments
        ReceiptAcknowledgement__c ackCleared = new ReceiptAcknowledgement__c(
            PaymentType__c = 'Online',
            Opportunity__c = opp.Id,
            Amount__c = 1200000,
            MaturityDate__c = Date.today(),
            SalesOrder__c = order.Id,
            Status__c = 'Cleared'
        );
        insert ackCleared;
        List<ReceiptAcknowledgement__c> lstReceiptAck = new List<ReceiptAcknowledgement__c>();
        ReceiptAcknowledgement__c ackReceived = ackCleared.clone(false, false, false, false);
        ackReceived.Status__c = 'Received';
        lstReceiptAck.add(ackReceived);
        
        
        insert lstReceiptAck;
        // Other Charges
        SalesOrderOtherCharges__c other = new SalesOrderOtherCharges__c(
            SalesOrder__c = order.Id,
            Account__c = person.Id,
            TypeOfCharge__c = 'Service Charge',
            Amount__c = 10000,
            Due_Date__c = Date.today()
        );
        insert other;
        
        // Receipt Allocations
        
        insert new ReceiptAllocation__c(
            ReceiptAcknowledgement__c = ackReceived.Id,
            Account__c = person.Id,
            AmountApplied__c = 12000,
            SalesOrder__c = order.Id,
            InstallmentLine__c = inst1.Id,
            SalesOrderOtherCharges__c = other.Id,
            TypeOfInvoice__c = 'SC'
        );
        
        insert new ReceiptAllocation__c(
            ReceiptAcknowledgement__c = ackReceived.Id,
            Account__c = person.Id,
            AmountApplied__c = 12000,
            SalesOrder__c = order.Id,
            InstallmentLine__c = inst1.Id
        );
        
        // -----------------------------
        // 2. Invoke VF Page
        // -----------------------------
        Test.setCurrentPage(Page.ReceiptAcknowledgementPDF);
        ApexPages.currentPage().getParameters().put('id', order.Id);
        
        
        
        SalesSOAPDFController handler = new SalesSOAPDFController();
        
        String contentId = SalesOrderController.generateSOAAndAttachPdf(order.Id, 'generateReceipt');
        System.assertNotEquals(null, contentId);
        
        Test.stopTest();
    }
    @IsTest
    static void testGenerateAndAttachPdf() {
        
        // -------------------------------------------------
        // 1. Create Project
        // -------------------------------------------------
        Project__c project = new Project__c(
            Name = 'Test Project SOA'
        );
        insert project;
        
        
        // -------------------------------------------------
        // 2. Create Building
        // -------------------------------------------------
        BuildingSection__c building =
            new BuildingSection__c(
                Name = 'Test Building SOA',
                BuildingSectionCode__c = 'BL-SOA',
                Project__c = project.Id
            );
        insert building;
        
        
        // -------------------------------------------------
        // 3. Create Unit
        // -------------------------------------------------
        Unit__c unit = new Unit__c(
            Name = 'Test Unit SOA',
            Status__c = 'Booked',
            UnitType__c = 'Townhouse',
            BuildingSectionName__c = building.Id,
            Project__c = project.Id,
            PropertyUsage__c = 'Residential',
            UnitView__c = 'Beach Side',
            FloorNumber__c = '01',
            NumberOfBedrooms__c = '3',
            UnitModel__c = '1BHK',
            SellingPrice__c = 700000,
            StartDate__c = Date.today().addDays(-10),
            EndDate__c = Date.today().addDays(10),
            LockExpiryTime__c =
            DateTime.now().addDays(10),
            LockedBy__c = UserInfo.getUserId()
        );
        insert unit;
        
        
        // -------------------------------------------------
        // 4. Create Payment Plan
        // -------------------------------------------------
        PaymentPlan__c plan =
            new PaymentPlan__c(
                Name = 'SOA Test Plan',
                Unit__c = unit.Id,
                Description__c = 'SOA Test',
                BrokerPortalFlag__c = true,
                CustomerSubType__c = 'CORPORATE',
                Classification__c =
                Constants.PAYMENT_PLAN_TYPE_STANDARD
            );
        insert plan;
        
        insert new BuildingSectionMapping__c(BuildingSectionName__c = building.Id,PaymentPlan__c = plan.Id);
        
        Id personRT = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        
        Account person = new Account(RecordTypeId = personRT,LastName = 'Test SOA',PersonEmail = 'soa@test.com',CustomerSubType__c = 'CORPORATE');
        insert person;
        
        Opportunity opp =
            new Opportunity(
                Name = 'SOA Test Opportunity',
                StageName = 'New',
                CloseDate = Date.today(),
                LeadChannel__c = 'Walk in',
                AccountId = person.Id,
                WinReason__c = 'Loyalty'
            );
        insert opp;
        
        PaymentInstallments__c installmentDef =
            new PaymentInstallments__c(
                BrokerPayoutPercentage__c = 100,
                Description__c = 'SOA Test Installment',
                InstallmentNumber__c = 1,
                InstallmentPercentage__c = 100,
                PaymentPlan__c = plan.Id,
                Condition_Type__c = 'P012'
            );
        insert installmentDef;
        
        OffersPromotions__c offer =
            new OffersPromotions__c(
                Name = 'SOA Test Offer',
                OfferName__c = 'SOA Test Offer',
                Project__c = project.Id,
                StartDate__c = Date.today(),
                EndDate__c = Date.today().addDays(2),
                ADM_Fee_Included__c = false
            );
        insert offer;
        
        SalesOrder__c order =
            new SalesOrder__c(
                Name = 'SOA Test Order',
                Status__c = 'Booked',
                Unit__c = unit.Id,
                Account__c = person.Id,
                Opportunity__c = opp.Id,
                Bloom_Signed_SPA_Date__c = Date.today(),
                Offer__c = offer.Id
            );
        insert order;
        
        InstallmentLines__c inst =
            new InstallmentLines__c(
                SalesOrder__c = order.Id,
                PaymentPlan__c = plan.Id,
                PaymentInstallments__c =
                installmentDef.Id,
                InstallmentAmount__c = 70000,
                InstallmentDate__c =
                Date.today().addDays(-12),
                InstallmentPercentage__c = 25,
                LPCAmount__c = 500,
                Description__c = 'SOA Test',
                InstallmentNumber__c = 1
            );
        insert inst;
        
        Test.setCurrentPage(Page.SalesSOAPDF);
        ApexPages.currentPage().getParameters().put('id', order.Id);
        
        Test.startTest();
        String contentVersionId = SalesSOAPDFController.generateAndAttachPdf(order.Id);
        Test.stopTest();
        ContentVersion cv = [SELECT Id,Title,PathOnClient,ContentDocumentId,VersionData FROM ContentVersion WHERE Id = :contentVersionId LIMIT 1];
        
        ContentDocumentLink cdl = [
            SELECT Id,
            ContentDocumentId,
            LinkedEntityId,
            ShareType,
            Visibility
            FROM ContentDocumentLink
            WHERE ContentDocumentId =
            :cv.ContentDocumentId
            AND LinkedEntityId = :order.Id
            LIMIT 1
        ];
    }
    
    @IsTest
    static void testRefundsAndRebates() {
        Project__c project = new Project__c(Name = 'Test Project RR');
        insert project;
        
        BuildingSection__c building = new BuildingSection__c(Name = 'Test Building RR', BuildingSectionCode__c = 'BL-RR', Project__c = project.Id);
        insert building;
        
        Unit__c unit = new Unit__c(
            Name = 'Test Unit RR', Status__c = 'Booked', UnitType__c = 'Townhouse',
            BuildingSectionName__c = building.Id, Project__c = project.Id,
            PropertyUsage__c = 'Residential', UnitView__c = 'Beach Side', FloorNumber__c = '01',
            NumberOfBedrooms__c = '3', UnitModel__c = '1BHK', SellingPrice__c = 700000,
            StartDate__c = Date.today().addDays(-10), EndDate__c = Date.today().addDays(10),
            LockExpiryTime__c = DateTime.now().addDays(10), LockedBy__c = UserInfo.getUserId());
        insert unit;
        
        PaymentPlan__c plan = new PaymentPlan__c(Name = 'RR Plan', Unit__c = unit.Id, Description__c = 'Test', BrokerPortalFlag__c = true,
            CustomerSubType__c = 'CORPORATE', Classification__c = Constants.PAYMENT_PLAN_TYPE_STANDARD);
        insert plan;
        
        insert new BuildingSectionMapping__c(BuildingSectionName__c = building.Id, PaymentPlan__c = plan.Id);
        
        Id personRT = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        Account person = new Account(RecordTypeId = personRT, LastName = 'Test RR', PersonEmail = 'rr@test.com', CustomerSubType__c = 'CORPORATE');
        insert person;
        
        Opportunity opp = new Opportunity(Name = 'RR Opp', StageName = 'New', CloseDate = Date.today(),LeadChannel__c = 'Walk in', AccountId = person.Id, WinReason__c = 'Loyalty');
        insert opp;
        
        PaymentInstallments__c installmentDef = new PaymentInstallments__c(BrokerPayoutPercentage__c = 100, Description__c = 'Test Installment', InstallmentNumber__c = 1,
            InstallmentPercentage__c = 100, PaymentPlan__c = plan.Id, Condition_Type__c = 'P012');
        insert installmentDef;
        
        OffersPromotions__c offer = new OffersPromotions__c(Name = 'RR Offer', OfferName__c = 'RR Offer', Project__c = project.Id,
            StartDate__c = Date.today(), EndDate__c = Date.today().addDays(2), ADM_Fee_Included__c = false);
        insert offer;
        
        SalesOrder__c order = new SalesOrder__c(Name = 'RR Order', Status__c = 'Booked', Unit__c = unit.Id, Account__c = person.Id,
            Opportunity__c = opp.Id, Bloom_Signed_SPA_Date__c = Date.today(), Offer__c = offer.Id);
        insert order;
        
        InstallmentLines__c inst1 = new InstallmentLines__c(SalesOrder__c = order.Id, PaymentPlan__c = plan.Id, PaymentInstallments__c = installmentDef.Id,
            InstallmentAmount__c = 100000, InstallmentDate__c = Date.today().addDays(-12),
            InstallmentPercentage__c = 100, LPCAmount__c = 500, Description__c = 'Test', InstallmentNumber__c = 1);
        insert inst1;
        Test.startTest();
        
        ReceiptAcknowledgement__c receipt = new ReceiptAcknowledgement__c(PaymentType__c = 'Online', Opportunity__c = opp.Id, Amount__c = 100000,MaturityDate__c = Date.today(), SalesOrder__c = order.Id, Status__c = 'Cleared');
        insert receipt;
        insert new ReceiptAllocation__c(ReceiptAcknowledgement__c = receipt.Id, Account__c = person.Id, SalesOrder__c = order.Id,AmountApplied__c = 50000, InstallmentLine__c = inst1.Id);    
        insert new SalesOrderRefund__c(SalesOrder__c = order.Id, Receipt__c = receipt.Id, Amount__c = 50000,Status__c = 'Processed', Remarks__c = 'Test refund');
        insert new SalesOrderRebate__c(SalesOrder__c = order.Id, InstallmentLine__c = inst1.Id, Date__c = Date.today(),Percentage__c = 5, Amount__c = 5000);
        Test.setCurrentPage(Page.SalesSOAPDF);
        ApexPages.currentPage().getParameters().put('id', order.Id);
        SalesSOAPDFController handler = new SalesSOAPDFController();
        Test.stopTest();
    }
}