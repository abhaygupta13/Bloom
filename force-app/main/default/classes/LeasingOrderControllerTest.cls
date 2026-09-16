@isTest
private class LeasingOrderControllerTest {
    
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
        
        //company
        Company__c com = new Company__c();
        com.Name = 'Leasing Com 101';
        com.LeasingPostingClosureDate__c = Date.Today().addDays(-1200);
        insert com;
        
        //Project__c
        Project__c objProject = new Project__c();
        objProject.Name = 'Test Project';
        objProject.IsAvailableforLeasing__c = true;
        objProject.EjariTawtheeqFee__c = 200;
        objProject.AdminFee__c = 20;
        objProject.LeasingServiceCharge__c = 20;
        objProject.SecurityDeposit__c = 20;
        objProject.Leasing_Company__c = com.Id;
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
            LeaseTerminationRefundType__c = 'Normal Termination without Refund - N',
            AdminFee__c = 100,
            FitOutSecurityDeposit__c  = 300,
            EjariTawtheeqFee__c = 200
            
        );
        insert lo;
        
        LeasingOrder__c lo2 = new LeasingOrder__c(
            Name='Test Contract 2',
            Opportunity__c = opp.Id,
            Account__c = acc.Id,
            Unit__c = unitRec.Id,
            LeasingContractMonths__c=12,
            PaymentTerm__c='4 Installments',
            SecurityDeposit__c = 100,
            ExtraChequeFee__c  = 200,
            LeaseTerminationRefundType__c = 'Normal Termination without Refund - N',
            AdminFee__c = 100,
            FitOutSecurityDeposit__c  = 300,
            EjariTawtheeqFee__c = 200,
            LeasingStartDate__c = System.Today().addDays(-5),
          LeasingEndDate__c = System.Today().addDays(5),
            Project__c = objProject.Id
            
        );
        insert lo2;

        LeasingOrdersOtherCharges__c charges = new LeasingOrdersOtherCharges__c(
              LeasingOrder__c = lo2.Id,
                Type__c = 'Admin Fee',
                ChargeAmount__c = 100,
                VATAmount__c = 5,
                isVATApplied__c = true
        );
        insert charges;
        
        PaymentPlanSchedule__c schedule = new PaymentPlanSchedule__c(Name = 'Schedule 1',LeasingOrder__c = lo2.Id,Amount__c = 1000,
                                                                     PaymentStartDate__c = Date.today(), RefDocno__c = 'INV-001');
        insert schedule;
        
        // Insert sample escalation
        insert new LeasingEscalationSchedule__c(
            LeasingOrder__c = lo.Id, Year__c = 1,
            AfterDiscount__c = 12000
        );
        
    }
    
    @isTest
    static void testInsertEscalationSchedules(){
        LeasingOrder__c lo = [SELECT Id FROM LeasingOrder__c LIMIT 1];
        
        List<LeasingEscalationSchedule__c> splits = new List<LeasingEscalationSchedule__c>{
            new LeasingEscalationSchedule__c(Year__c=1, AfterDiscount__c=12000),
                new LeasingEscalationSchedule__c(Year__c=2, AfterDiscount__c=14000)
                };
                    
                    Test.startTest();
        LeasingOrderController.insertEscalationSchedules(lo.Id, splits);
        Test.stopTest();
        
        System.assertEquals(3, [
            SELECT COUNT() FROM LeasingEscalationSchedule__c WHERE LeasingOrder__c = :lo.Id
        ]);
    }
    
    @isTest
    static void testGetOfferLineDiscountSum(){
        Decimal sum = LeasingOrderController.getOfferLineDiscountSum(null);
        System.assertEquals(0, sum);
        
        LeasingOffer__c objLeasing = [SELECT Id FROM LeasingOffer__c WHERE Name = 'TestOffer' LIMIT 1];
        Decimal res = LeasingOrderController.getOfferLineDiscountSum(objLeasing.Id);
        System.assertEquals(1, res);
        
        List<map<String,string>> mapRes = LeasingOrderController.getAllProjectsForLeasing();
        System.assertEquals(1, mapRes.size());
        
    }
    
    @isTest 
    static void getAllBuildingsTest(){
        Test.startTest();
        
        Project__c objProj = [SELECT Id FROM Project__c WHERE Name = 'Test Project' LIMIT 1];
        
        List<map<String,string>> resMap = LeasingOrderController.getAllBuildings(objProj.Id);
        //System.Assert.areEqual(1, resMap.size());
        Test.stopTest();
    }
    
    @isTest
    static void testupdateLeasingContractWithCleanup(){
        LeasingOrder__c lo = [SELECT Id,name,Opportunity__c,Account__c ,Unit__c ,LeasingStartDate__c ,LeasingEndDate__c ,LeasingContractMonths__c,PaymentTerm__c,RelatedPartyBloomHolding__c FROM LeasingOrder__c WHERE Name = 'Test Contract' LIMIT 1];
        
        List<LeasingEscalationSchedule__c> splits = new List<LeasingEscalationSchedule__c>{
            new LeasingEscalationSchedule__c(Year__c=1, AfterDiscount__c=12000),
                new LeasingEscalationSchedule__c(Year__c=2, AfterDiscount__c=14000)
                };
                    
                    LeasingOrderController.LeasingOrderWrapper wrp = new LeasingOrderController.LeasingOrderWrapper();
        wrp.opportunityId = lo.Opportunity__c;
        wrp.name = lo.name;
        wrp.unitId = lo.unit__c;
        wrp.familyStatus = 'Individual';
        wrp.leasingContractMonths = 11;
        wrp.paymentPlanId = '4 Installments';
        wrp.rentalAfterDiscount = 1;
        wrp.appliedAnnualRent= 1000;
        wrp.leasingStartDate = System.Today();
        wrp.leasingEndDate = lo.LeasingEndDate__c;
        wrp.gracePeriod = 0;
        wrp.relatedPartyBloomHolding = lo.RelatedPartyBloomHolding__c;
        
        Test.startTest();
        LeasingOrderController.updateLeasingContractWithCleanup(lo.Id, Json.serialize(wrp));
        Test.stopTest();
        
        //System.assertEquals(3, [ SELECT COUNT() FROM LeasingEscalationSchedule__c WHERE LeasingOrder__c = :lo.Id]);
    }
    
    @IsTest
    static void getUnitDetailsTest() {
        Test.startTest();
        Building__c buildingSec = [SELECT Id, Name FROM Building__c LIMIT 1];
        Unit__c unit = [SELECT Id FROM Unit__c WHERE Name='TestU' LIMIT 1 ];
        LeasingOrderController.getUnitDetails(buildingSec.Id, 'Test', 'Commercial', 'test', unit.Id);
        Test.stopTest();
    }
    
    @isTest
    static void getActiveLeasingContractTest(){
        Test.startTest();
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name='Test Opp' LIMIT 1];
        LeasingOrder__c objLeasing = LeasingOrderController.getActiveLeasingContract(opp.Id);
        System.Assert.isTrue(objLeasing.Name != null && objLeasing.Name.contains('Test Contract'));
        
        map<String,object> mapRes = LeasingOrderController.getsObjectType(opp.Id);
        map<String,object> mapRes1 = LeasingOrderController.getsObjectType(objLeasing.Id);
        Boolean hasEditPermission = LeasingOrderController.hasEditPermission();
        
        Test.stopTest();
    }
    
@isTest
static void getLeasingoffersTest() {

    Test.startTest();

    List<LeasingOffer__c> listLeasingOff =
        LeasingOrderController.getLeasingoffers();


    System.assertEquals(
        1,
        listLeasingOff.size(),
        'Expected one Leasing Offer record'
    );

    LeasingOrder__c lo = [
        SELECT Id,
               Name,
               Opportunity__c,
               Account__c,
               Unit__c,
               LeasingStartDate__c,
               LeasingEndDate__c,
               LeasingContractMonths__c,
               PaymentTerm__c
        FROM LeasingOrder__c
        WHERE Name = 'Test Contract'
        LIMIT 1
    ];


    LeasingOrder__c objLeasingOrder =
        LeasingOrderController.getLeasingDetails(lo.Id);

    Test.stopTest();

    System.assertNotEquals(
        null,
        objLeasingOrder,
        'Leasing Order details should be returned'
    );

    System.assertEquals(
        '4 Installments',
        objLeasingOrder.PaymentTerm__c,
        'Payment term should be 4 Installments'
    );
}

@isTest
static void generatePDF_NewRetailTest() {

    // Get the existing Leasing Order created by @testSetup
    LeasingOrder__c lo = [
        SELECT Id,
               Name,
               Unit__c,
               Opportunity__c,
               Account__c,
               LeasingStartDate__c,
               LeasingEndDate__c,
               LeasingContractMonths__c,
               PaymentTerm__c,
               SecurityDeposit__c,
               ExtraChequeFee__c,
               AdminFee__c,
               FitOutSecurityDeposit__c,
               EjariTawtheeqFee__c
        FROM LeasingOrder__c
        WHERE Name = 'Test Contract'
        LIMIT 1
    ];

    System.assertNotEquals(
        null,
        lo.Unit__c,
        'Test Contract must have a Unit'
    );

    // Get Unit
    Unit__c unit = [
        SELECT Id,
               Name,
               PropertyUsage__c,
               Project__c,
               Building__c,
               LeasingAnnualRent__c,
               LeasingUnitStatus__c,
               IsAvailableforLeasing__c
        FROM Unit__c
        WHERE Id = :lo.Unit__c
        LIMIT 1
    ];

    /*
     * Force the Retail branch in generatePDF()
     */
    unit.PropertyUsage__c = 'Retail';
    update unit;

    /*
     * Create Leasing Offer document required by generatePDF().
     *
     * Do not query for an existing one because @testSetup
     * does not create a LeasingOrder__c document.
     */
    Document__c offerDocument = new Document__c(
        Document_Name__c = 'Leasing Offer',
        LeasingOrder__c = lo.Id,
        Opportunity__c = lo.Opportunity__c
    );
    insert offerDocument;

    /*
     * Create ContentVersion as well.
     *
     * Some implementations of generatePDF() / related PDF
     * controllers expect a file to exist against the document.
     */
    ContentVersion cv = new ContentVersion(
        Title = 'Leasing Offer',
        PathOnClient = 'LeasingOffer.pdf',
        VersionData = Blob.valueOf('Test Leasing Offer PDF'),
        FirstPublishLocationId = offerDocument.Id
    );
    insert cv;

    Test.startTest();

    Id resultId;

    try {
        resultId = LeasingOrderController.generatePDF(lo.Id);
    } catch (Exception e) {
        System.debug(
            'generatePDF Exception: ' +
            e.getTypeName() +
            ' - ' +
            e.getMessage()
        );
        System.debug(
            'Stack Trace: ' +
            e.getStackTraceString()
        );

    }

    Test.stopTest();

  
}

    @isTest 
    static void createLeasingOrderTest(){
        
        Test.startTest();
        LeasingOrder__c lo = [SELECT Id,name,Opportunity__c,Account__c ,Unit__c ,LeasingStartDate__c ,LeasingEndDate__c ,LeasingContractMonths__c,PaymentTerm__c,RelatedPartyBloomHolding__c FROM LeasingOrder__c WHERE Name = 'Test Contract' LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name='Test Opp' LIMIT 1];
        Document__c offerDoc = [SELECT ID FROM Document__c WHERE Document_Name__c = 'Leasing Offer' LIMIT 1];
        LeasingOrderController.LeasingOrderWrapper wrp = new LeasingOrderController.LeasingOrderWrapper();
        wrp.opportunityId = opp.Id;
        wrp.name = lo.name;
        wrp.unitId = lo.unit__c;
        wrp.familyStatus = 'Individual';
        wrp.leasingContractMonths = 12;
        wrp.paymentPlanId = '4 Installments';
        wrp.rentalAfterDiscount = 1;
        wrp.appliedAnnualRent= 1000;
        wrp.leasingStartDate = System.Today();
        wrp.leasingEndDate = lo.LeasingEndDate__c;
        wrp.relatedPartyBloomHolding = lo.RelatedPartyBloomHolding__c;
        
        String str = LeasingOrderController.createLeasingOrder(Json.serialize(wrp));
         Blob fileBody = Blob.valueOf('This is a sample file content.');
        ContentVersion cv = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'TestFile.pdf',
            VersionData = fileBody,
                        FirstPublishLocationId = offerDoc.Id

        );
        insert cv;

        // Fetch the related ContentDocument Id
        Id contentDocId = [
            SELECT ContentDocumentId 
            FROM ContentVersion 
            WHERE Id = :cv.Id
            LIMIT 1
        ].ContentDocumentId;

        // 3. Create an EmailMessage
        EmailMessage emailMsg = new EmailMessage(
            Subject = 'Test Email',
            FromAddress = 'sender@example.com',
            ToAddress = 'recipient@example.com',
            Status = '3', // Draft
            Incoming = false,
            RelatedToId = str
        );
        insert emailMsg;

        // 4. Link the ContentDocument to the EmailMessage
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = contentDocId,
            LinkedEntityId = emailMsg.Id,
            ShareType = 'V', // View permission
            Visibility = 'AllUsers'
        );
        insert cdl;

        //LeasingOrderController.sendEmailWithDocument(str);
        
        Test.stopTest();
    }

    @isTest
    static void terminateLOTest(){
        LeasingOrder__c lo = [SELECT Id,name,Opportunity__c,Account__c ,Unit__c ,LeasingStartDate__c ,LeasingEndDate__c ,LeasingContractMonths__c,PaymentTerm__c,LeaseTerminationRefundType__c, TerminationDate__c
                              FROM LeasingOrder__c WHERE Name = 'Test Contract' LIMIT 1];
        LeasingOrderController.terminateLease(lo, new list<LeasingOrdersOtherCharges__c>{});
    }

    @isTest
    static void createFinanceTaskTest(){
        LeasingOrder__c lo = [SELECT Id,name,Opportunity__c,Account__c ,Unit__c ,LeasingStartDate__c ,LeasingEndDate__c ,LeasingContractMonths__c,PaymentTerm__c FROM LeasingOrder__c WHERE Name = 'Test Contract' LIMIT 1];
        LeasingOrderController.LeasingOrderDataWrapper data = new LeasingOrderController.LeasingOrderDataWrapper();
        data.leasingOrderId = lo.id;
        data.ejariReceived = true;
        data.ejariNumber ='123456789';
        data.pdcNumber = 2;
        data.pdcUser = UserInfo.getUserId();
        data.isSyncTaskRequired = true;
        data.pdcDate = String.valueOf(Date.today());
        try{
      LeasingOrderController.createFinanceTask(Json.serialize(data));
        }catch(Exception e){
            
        }
        try{
            LeasingOrderController.LeasingOrderWrapper wrp = new LeasingOrderController.LeasingOrderWrapper();
        wrp.opportunityId = lo.Opportunity__c;
        wrp.name = lo.name;
        wrp.unitId = lo.unit__c;
        wrp.familyStatus = 'Individual';
        wrp.leasingContractMonths = 11;
        wrp.paymentPlanId = '4 Installments';
        wrp.rentalAfterDiscount = 1;
        wrp.appliedAnnualRent= 1000;
        wrp.leasingStartDate = System.Today();
        wrp.leasingEndDate = lo.LeasingEndDate__c;
        wrp.gracePeriod = 0;
        
        Test.startTest();
        LeasingOrderController.createRenewalLeasingOrder(lo.Id, Json.serialize(wrp));
        Test.stopTest();
             
        }catch(Exception e){
            
        }
    }

    @isTest
    static void createlegalTaskTest(){
        LeasingOrder__c lo = [SELECT Id,name,Opportunity__c,Account__c ,Unit__c ,LeasingStartDate__c ,LeasingEndDate__c ,LeasingContractMonths__c,PaymentTerm__c FROM LeasingOrder__c WHERE Name = 'Test Contract' LIMIT 1];
        LeasingOrderController.validateFinancialRecordsEditable(lo.Id);
        try{
            LeasingOrderController.sendEmailWithDocument(lo.Id);
        }catch(Exception e){
            
        }
        LeasingOrderController.LegalTaskWrapper data = new LeasingOrderController.LegalTaskWrapper();
        data.caseType  = 'Legal Case';
        data.legalUserId = UserInfo.getUserId();
        LeasingOrderController.createLegalTask(lo.Id,Json.serialize(data));
    }
    
    @isTest
    static void testGetOtherCharges(){
        Date start = System.Today().addDays(-5);
        Date enddate = System.Today().addDays(5);
        
        Test.startTest();
        LeasingOrderController.getOtherCharges(start, enddate);
        Test.stopTest();
    }
    
    @isTest
    static void testUpdateOtherCharges(){
        List<LeasingOrdersOtherCharges__c> otherCharges = [Select Id from LeasingOrdersOtherCharges__c Limit 1];
        
        Test.startTest();
        if(otherCharges.size() > 0)
            LeasingOrderController.updateOtherCharges(new List<Id>{otherCharges[0].id}, System.today());
        Test.stopTest();
    }

  @isTest
    static void testGetPaymentPlanSummary(){
        List<LeasingOrder__c> order = [Select Id from LeasingOrder__c where name = 'Test Contract 2' Limit 1];
        
        Test.startTest();
            LeasingOrderController.getPaymentPlanSummary(order[0].id);
        Test.stopTest();
    }

  @isTest
    static void testValidationLeasingOrderSyncWarning(){
        List<LeasingOrder__c> order = [Select Id from LeasingOrder__c where name = 'Test Contract 2' Limit 1];
        
        Test.startTest();
        try{
      LeasingOrderController.ValidationLeasingOrderSyncWarning(order[0].id);
        }catch(Exception e){
            System.debug('err '+e.getMessage());
        }
        Test.stopTest();
    }
   @IsTest
static void testGetUserIdByName() {

    User testUser = [
        SELECT Id, Name
        FROM User
        WHERE Id = :UserInfo.getUserId()
        LIMIT 1
    ];

    Test.startTest();

    Id resultUserId =
        LeasingOrderController.getUserIdByName(testUser.Name);

    Test.stopTest();

    System.assertNotEquals(
        null,
        resultUserId,
        'User Id should be returned.'
    );

    System.assertEquals(
        testUser.Id,
        resultUserId,
        'Returned User Id should match the requested user.'
    );
}


@IsTest
static void testHandleFinanceFileUpload_PDC() {

    // Use Leasing Order created in @testSetup
    LeasingOrder__c leasingOrder = [
        SELECT Id, Name
        FROM LeasingOrder__c
        WHERE Name = 'Test Contract'
        LIMIT 1
    ];

    // Create Document record expected by handleFinanceFileUpload()
    Document__c pdcDocument = new Document__c(
        LeasingOrder__c = leasingOrder.Id,
        Document_Name__c = 'PDCs'
    );
    insert pdcDocument;

    String fileName = 'PDC.pdf';

    Blob fileBody = Blob.valueOf('Test PDC File');
    String base64Data = EncodingUtil.base64Encode(fileBody);

    Test.startTest();

    String result = LeasingOrderController.handleFinanceFileUpload(
        leasingOrder.Id,
        fileName,
        base64Data
    );

    Test.stopTest();

    System.assertEquals(
        'File uploaded successfully.',
        result,
        'PDC file should be uploaded successfully.'
    );

    // Verify ContentDocumentLink was created
    List<ContentDocumentLink> links = [
        SELECT Id,
               ContentDocumentId,
               LinkedEntityId,
               ShareType,
               Visibility
        FROM ContentDocumentLink
        WHERE LinkedEntityId = :pdcDocument.Id
    ];

    System.assertEquals(
        1,
        links.size(),
        'One ContentDocumentLink should be created for PDC.'
    );

    System.assertEquals(
        pdcDocument.Id,
        links[0].LinkedEntityId,
        'PDC file should be linked to the PDC Document record.'
    );

    System.assertEquals(
        'V',
        links[0].ShareType,
        'File should have Viewer sharing permission.'
    );

    System.assertEquals(
        'AllUsers',
        links[0].Visibility,
        'File visibility should be AllUsers.'
    );
}


@IsTest
static void testHandleFinanceFileUpload_Ejari() {

    // Use Leasing Order created in @testSetup
    LeasingOrder__c leasingOrder = [
        SELECT Id, Name
        FROM LeasingOrder__c
        WHERE Name = 'Test Contract'
        LIMIT 1
    ];

    // Create Document record expected by handleFinanceFileUpload()
    Document__c ejariDocument = new Document__c(
        LeasingOrder__c = leasingOrder.Id,
        Document_Name__c = 'Tawtheeq /Ejari Document'
    );
    insert ejariDocument;

    String fileName = 'Ejari.pdf';

    Blob fileBody = Blob.valueOf('Test Ejari File');
    String base64Data = EncodingUtil.base64Encode(fileBody);

    Test.startTest();

    String result = LeasingOrderController.handleFinanceFileUpload(
        leasingOrder.Id,
        fileName,
        base64Data
    );

    Test.stopTest();

    System.assertEquals(
        'File uploaded successfully.',
        result,
        'Ejari file should be uploaded successfully.'
    );

    // Verify ContentDocumentLink was created
    List<ContentDocumentLink> links = [
        SELECT Id,
               ContentDocumentId,
               LinkedEntityId,
               ShareType,
               Visibility
        FROM ContentDocumentLink
        WHERE LinkedEntityId = :ejariDocument.Id
    ];

    System.assertEquals(
        1,
        links.size(),
        'One ContentDocumentLink should be created for Ejari.'
    );

    System.assertEquals(
        ejariDocument.Id,
        links[0].LinkedEntityId,
        'Ejari file should be linked to the Ejari Document record.'
    );
}


@IsTest
static void testHandleFinanceFileUpload_InvalidBase64() {

    LeasingOrder__c leasingOrder = [
        SELECT Id, Name
        FROM LeasingOrder__c
        WHERE Name = 'Test Contract'
        LIMIT 1
    ];

    Document__c pdcDocument = new Document__c(
        LeasingOrder__c = leasingOrder.Id,
        Document_Name__c = 'PDCs'
    );
    insert pdcDocument;

    Test.startTest();

    try {

        LeasingOrderController.handleFinanceFileUpload(
            leasingOrder.Id,
            'PDC.pdf',
            'INVALID_BASE64_DATA'
        );

        System.assert(
            false,
            'Expected AuraHandledException for invalid base64.'
        );

    } catch (AuraHandledException ex) {

    }

    Test.stopTest();
}
    
    @isTest
static void generatePDF_RenewalRetailTest() {

    LeasingOrder__c lo = [
        SELECT Id,
               Unit__c,
               Opportunity__c,
               LeaseType__c
        FROM LeasingOrder__c
        WHERE Name = 'Test Contract'
        LIMIT 1
    ];
    
     LeasingOrdersOtherCharges__c chilledCharges = new LeasingOrdersOtherCharges__c(
            	LeasingOrder__c = lo.Id,
                Type__c = 'Chilled Water Charge',
                ChargeAmount__c = 100,
                VATAmount__c = 5,
         PostingDate__c = Date.today(),
                isVATApplied__c = true
        );
        insert chilledCharges;
    Unit__c unit = [
        SELECT Id, PropertyUsage__c
        FROM Unit__c
        WHERE Id = :lo.Unit__c
    ];
    unit.PropertyUsage__c = 'Retail';
    update unit;
    lo.LeaseType__c = 'Renewal';
    update lo;
    Document__c renewalDoc = new Document__c(
        Document_Name__c = 'Renewal Offer Letter',
        LeasingOrder__c = lo.Id,
        Opportunity__c = lo.Opportunity__c
    );
    insert renewalDoc;

    Test.setCurrentPage(Page.RenewalOfferPDF);
    ApexPages.currentPage().getParameters().put('id', lo.Id);

    Test.startTest();
    Id resultId = LeasingOrderController.generatePDF(lo.Id);
    RenewalOfferPDFController controller =
        new RenewalOfferPDFController();

    Test.stopTest();
    
}
}