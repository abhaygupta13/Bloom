@isTest
private class RefundFormControllerTest {
    
    @testSetup
    static void setupData() {
        
        Id personAccountRT = Utility.getRecordTypeIdByDevName(
            Account.SObjectType,
            'PersonAccount'
        );
        
        Account acc = new Account(
            RecordTypeId = personAccountRT,
            LastName = 'Refund Test Customer',
            PersonEmail='refund@test.com',
            Phone='123456789'
        );
        insert acc;
        
        Company__c company = new Company__c(
            Name='Refund Company'
        );
        insert company;
        
        Project__c project = new Project__c(
            Name='Refund Project',
            Leasing_Company__c=company.Id,
            IsAvailableforLeasing__c=true
        );
        insert project;
        
        Building__c building =
            TestDataFactory.createBuilding('Refund Building',project.Id);
        insert building;
        
        Unit__c unitRec = new Unit__c(
            Name='Unit-101',
            Project__c=project.Id,
            Building__c=building.Id,
            LeasingAnnualRent__c=120000,
            LeasingUnitStatus__c='Available',
            PropertyUsage__c='Commercial',
            IsAvailableforLeasing__c=true
        );
        insert unitRec;
        
        Opportunity opp = new Opportunity(
            Name='Refund Opportunity',
            StageName='Prospecting',
            CloseDate=Date.today().addDays(30),
            OpportunityType__c='Leasing',
            AccountId=acc.Id
        );
        insert opp;
        
        LeasingOrder__c order = new LeasingOrder__c(
            Name='Refund Contract',
            Opportunity__c=opp.Id,
            Account__c=acc.Id,
            Unit__c=unitRec.Id,
            Project__c=project.Id,
            LeasingStartDate__c=Date.newInstance(2026,1,1),
            LeasingEndDate__c=Date.newInstance(2026,12,31),
            TerminationDate__c=Date.newInstance(2026,10,31),
            SecurityDeposit__c=5000,
            SAPCompanyCode__c='1000',
            LeasingSAPContractId__c='SAP-1001'
        );
        insert order;
        
        insert new LeasingOrdersOtherCharges__c(
            LeasingOrder__c = order.Id,
            Type__c = 'Admin Fee',
            ChargeAmount__c = 100,
            VATAmount__c = 5,
            isVATApplied__c = true
        );
        
        insert new LeasingReceiptAcknowledgment__c(
            LeasingOrder__c=order.Id,
            Amount__c=2000,
            ChequeNumber__c='CHK-001',
            ChequeDate__c=Date.newInstance(2026,11,15)
        );
        
        insert new LeasingReceiptAcknowledgment__c(
            LeasingOrder__c=order.Id,
            Amount__c=1000,
            ChequeNumber__c='CHK-002',
            ChequeDate__c=Date.newInstance(2026,9,15)
        );
        
        insert new Document__c(
            LeasingOrder__c=order.Id,
            Document_Name__c='Refund form'
        );
        
        insert new Document__c(
            LeasingOrder__c=order.Id,
            Document_Name__c='Last tenancy contract',
            ContentDocumentId__c='069000000000001AAA'
        );
        
        insert new Document__c(
            LeasingOrder__c=order.Id,
            Document_Name__c='Water & Electricity Clearance Certificate',
            ContentDocumentId__c='069000000000002AAA'
        );
        
        insert new Document__c(
            LeasingOrder__c=order.Id,
            Document_Name__c='Maintenance Checkout Report',
            ContentDocumentId__c='069000000000003AAA'
        );
        
        insert new Document__c(
            LeasingOrder__c=order.Id,
            Document_Name__c='Tenant Letter for Break Lease',
            ContentDocumentId__c='069000000000004AAA'
        );
        
        insert new Document__c(
            LeasingOrder__c=order.Id,
            Document_Name__c='Break Lease Forms Signed by Tenant',
            ContentDocumentId__c='069000000000005AAA'
        );
    }
    
    
    
    @isTest
    static void testLeaseDuration() {
        
        Integer days =
            RefundCalculationService.getLeaseDuration(
                Date.newInstance(2026,1,1),
                Date.newInstance(2026,12,31)
            );
    }
    
    @isTest
    static void testDailyRent() {
        
        Decimal daily =
            RefundCalculationService.calculateDailyRent(
                36500,
                Date.newInstance(2026,1,1),
                Date.newInstance(2026,12,31)
            );
        
       
    }
    
    @isTest
    static void testValueOfDays() {
        
        Decimal value =
            RefundCalculationService.calculateValueOfDays(
                36500,
                Date.newInstance(2026,1,1),
                Date.newInstance(2026,12,31),
                10
            );
        
       
    }
    
    @isTest
    static void testBreakLeaseCharges() {
        
        LeasingOrder__c order=[
            SELECT Id
            FROM LeasingOrder__c
            LIMIT 1
        ];
        
        List<LeasingOrdersOtherCharges__c> charges=[
            SELECT Type__c,TotalAmount__c
            FROM LeasingOrdersOtherCharges__c
            WHERE LeasingOrder__c=:order.Id
        ];
        
        Decimal total=
            RefundCalculationService.calculateBreakLeaseCharges(charges);
    }
    
    @isTest
    static void testMaintenanceCharges() {
        
        LeasingOrder__c order=[
            SELECT Id
            FROM LeasingOrder__c
            LIMIT 1
        ];
        
        List<LeasingOrdersOtherCharges__c> charges=[
            SELECT Type__c,TotalAmount__c
            FROM LeasingOrdersOtherCharges__c
            WHERE LeasingOrder__c=:order.Id
        ];
        
        Decimal total=
            RefundCalculationService.calculateMaintenanceCharges(charges);
    }
    
    @isTest
    static void testCalculateDueAmount() {
        
        Decimal total = RefundCalculationService.calculateDueAmount(
            100,
            200,
            300,
            400,
            500,
            600
        );
        
        total = RefundCalculationService.calculateDueAmount(
            null,
            null,
            null,
            null,
            null,
            null
        );
    }
    
    @isTest
    static void testCalculatePDCTotal() {
        
        LeasingOrder__c order = [
            SELECT Id,TerminationDate__c
            FROM LeasingOrder__c
            LIMIT 1
        ];
        
        List<LeasingReceiptAcknowledgment__c> receipts = [
            SELECT Amount__c,
            ChequeDate__c
            FROM LeasingReceiptAcknowledgment__c
            WHERE LeasingOrder__c=:order.Id
        ];
        
        Decimal total =
            RefundCalculationService.calculatePDCTotal(
                receipts,
                order.TerminationDate__c
            );
    }
    
    @isTest
    static void testDueAmountAfterPOCAdj(){
        
        Decimal result =
            RefundCalculationService.calculateDueAmountAfterPOCAdj(
                5000,
                1200
            );
        
        result =
            RefundCalculationService.calculateDueAmountAfterPOCAdj(
                null,
                null
            );
    }
    
    @isTest
    static void testWrapper(){
        
        RefundFormWrapper wrapper = new RefundFormWrapper();
        
        RefundFormWrapper.PDCRow row =
            new RefundFormWrapper.PDCRow();
        
        row.serialNo = 1;
        row.chequeNo = 'CHK001';
        row.amount = 500;
        row.dueDate = Date.today();
        
        wrapper.pdcRows.add(row);
        
        RefundFormWrapper.AttachmentRow att =
            new RefundFormWrapper.AttachmentRow();
        
        att.documentName='Agreement';
        att.available=true;
        att.documentDate=Date.today();
        att.corDate=Date.today();
        
        att.available=false;
    }
    
    @isTest
    static void testGetRefundForm(){
        
        LeasingOrder__c order = [
            SELECT Id
            FROM LeasingOrder__c
            LIMIT 1
        ];
        
        Test.startTest();
        
        RefundFormWrapper wrapper =
            RefundFormService.getRefundForm(
                order.Id,
                'Refund Notes',
                Date.today(),
                Date.today().addDays(2)
            );
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetRefundFormWithoutDates(){
        
        LeasingOrder__c order = [
            SELECT Id
            FROM LeasingOrder__c
            LIMIT 1
        ];
        
        RefundFormWrapper wrapper =
            RefundFormService.getRefundForm(
                order.Id,
                null,
                null,
                null
            );
    }
    
    @isTest
    static void testGetRefundFormException(){
        
        try{
            
            RefundFormService.getRefundForm(
                null,
                null,
                null,
                null
            );
            
        }catch(Exception e){
            
        }
        
    }
    
    @isTest
    static void testGenerateRefundForm(){
        
        LeasingOrder__c order = [
            SELECT Id
            FROM LeasingOrder__c
            LIMIT 1
        ];
        
        Test.startTest();
        
        String result =
            RefundFormController.generateRefundForm(
                order.Id,
                'Refund Test',
                Date.today(),
                Date.today().addDays(1)
            );
        
        Test.stopTest();
        
        List<ContentVersion> versions = [
            SELECT Id, Title
            FROM ContentVersion
            WHERE Title='Refund Form'
        ];
        
        Document__c refundDoc = [
            SELECT Id
            FROM Document__c
            WHERE Document_Name__c = 'Refund form'
            LIMIT 1
        ];
        
        List<ContentDocumentLink> links = [
            SELECT Id, ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :refundDoc.Id
        ];
    }
    
    @isTest
    static void testGenerateRefundFormWithoutDates(){
        
        LeasingOrder__c order = [
            SELECT Id
            FROM LeasingOrder__c
            LIMIT 1
        ];
        
        Test.startTest();
        
        String result =
            RefundFormController.generateRefundForm(
                order.Id,
                null,
                null,
                null
            );
        
        Test.stopTest();
    }
    
    @isTest
    static void testGenerateRefundFormException(){
        
        try{
            
            RefundFormController.generateRefundForm(
                null,
                null,
                null,
                null
            );
            
        }catch(Exception e){
            
        }
        
    }
    
    @isTest
    static void testPDFController(){
        
        LeasingOrder__c order = [
            SELECT Id
            FROM LeasingOrder__c
            LIMIT 1
        ];
        
        PageReference pageRef = Page.RefundFormPDF;
        
        pageRef.getParameters().put('id', order.Id);
        pageRef.getParameters().put('notes', 'PDF Notes');
        pageRef.getParameters().put(
            'waterDate',
            String.valueOf(Date.today())
        );
        pageRef.getParameters().put(
            'maintenanceDate',
            String.valueOf(Date.today().addDays(1))
        );
        
        Test.setCurrentPage(pageRef);
        
        Test.startTest();
        
        RefundFormPDFController controller =
            new RefundFormPDFController();
        
        Test.stopTest();
        
       
    }
    
    @isTest
    static void testPDFControllerWithoutDates(){
        
        LeasingOrder__c order = [
            SELECT Id
            FROM LeasingOrder__c
            LIMIT 1
        ];
        
        PageReference pageRef = Page.RefundFormPDF;
        
        pageRef.getParameters().put('id', order.Id);
        
        Test.setCurrentPage(pageRef);
        
        Test.startTest();
        
        RefundFormPDFController controller =
            new RefundFormPDFController();
        
        Test.stopTest();
        
        
    }
    
    @isTest
    static void testPDFControllerException(){
        
        PageReference pageRef = Page.RefundFormPDF;
        
        Test.setCurrentPage(pageRef);
        
        try{
            
            new RefundFormPDFController();
            
        }catch(Exception e){
            
           
            
        }
        
    }
    
}