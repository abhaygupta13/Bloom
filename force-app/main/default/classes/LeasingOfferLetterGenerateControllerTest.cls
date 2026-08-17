@isTest
private class LeasingOfferLetterGenerateControllerTest {
   

    @isTest
    static void test_EndToEnd_WithUnitLinkedToLeasingOrder_UnitHasProject() {
         RecordType personAccountRecordType = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'PersonAccount' LIMIT 1];
 
        
        Account personAccount = new Account(
            RecordTypeId = personAccountRecordType.Id,
            LastName = 'Test Person Account', 
            Phone = '971202520',
            PersonEmail='abc@gmail.com',
            Nationality__c = 'Indian',
            
            PrimaryMobilePhone__pc = '1234567890',
           
            SecondaryMobilePhone__pc = '9876543210',
            
            TertiaryMobilePhone__pc = '1122334455'
        );
        insert personAccount;

        // SINGLE Contact for the Account (the helper queries one Contact without LIMIT)
        Contact con = new Contact(
            FirstName = 'Jane',
            LastName  = 'Doe',
            //AccountId = personAccount.Id,
            Email     = 'jane.doe@acme.tld'
            // TODO: add org-required fields if any
        );
        insert con;

        // ------------------------------
        // 2) PROJECT TREE (LeasingCompany -> Project -> Unit)
        // ------------------------------
        // Leasing Company (helper reads VAT__c and Name via Unit__r.Project__r.LeasingCompany__r)
        Company__c leasingCo = new Company__c(
            Name  = 'Bloom Leasing Co.',
            LeasingVAT__c = 5 // 5% VAT
            // TODO: add org-required fields if any
        );
        insert leasingCo;

        // Project (helper reads SecurityDeposit__c, Leasing_Municipality_Area__c, City__c, LeasingCompany__r fields)
        Project__c project = new Project__c(
            Name                          = 'Bloom Gardens',
            Leasing_Company__c             = leasingCo.Id,           // associate project -> leasing company
           LeasingMunicipalityArea__c  = 'Dubai',                // -> rentSystem should be "Ejari"
            SecurityDeposit__c            = 10,                     // 10%
            City__c                       = 'Dubai'
            // TODO: add org-required fields if any (e.g., Status__c, Code__c, etc.)
        );
        insert project;

        // Unit under the Project (helper reads Unit fields and traverses to Project)
        Unit__c unit = new Unit__c(
            Name                    = 'A-1204',
            Project__c              = project.Id,           // associate Unit -> Project (REQUIRED FOR TEST)
            PropertyUsage__c        = 'Residential',        // drives Residential branch in service charges
            NumberOfCarParks__c     = 2,
            LeasingUnitSizesqm__c   = 100
            // TODO: add org-required fields if any (e.g., Status__c)
        );
        insert unit;

        // ------------------------------
        // 3) OPPORTUNITY (linked to Account & used by helper)
        // ------------------------------
        Opportunity opp = new Opportunity(
            Name       = 'Lease A-1204',
            StageName  = 'Prospecting',
            CloseDate  = Date.today().addDays(30),
            AccountId  = personAccount.Id/*,
            UnitType__c    = 'Apartment'*/
           
        );
        insert opp;

        // ------------------------------
        // 4) LEASING ORDER (LeasingOrder__c)
        // Associate the Unit to the Leasing Order (Unit__c) – as requested
        // ------------------------------
        LeasingOrder__c leasingOrder = new LeasingOrder__c(
            Name                         = 'LC-A-1204',
            Unit__c                      = unit.Id,               // <== UNIT ASSOCIATED TO LEASING ORDER
            Opportunity__c               = opp.Id,                // helper loads Opportunity fields
            OfferValidityDays__c         = 7,
            AnnualRent__c                = 120000,
            AppliedAnnualRent__c         = 115000,
            RentalAmountAfterDiscount__c = 115000,
           // AnnualRentVATAmount__c       = 5750,                  // 5% of 115,000
           // TotalAnnualRentwithVAT__c    = 120750,                // 115,000 + 5,750
           // TotalRentAfterDiscount__c    = 241500,                // multi-year total, to cover that branch
            SecurityDeposit__c           = 12000,
            PaymentTerm__c               = '4 Installments',          // helper parses "4"
            LeasingContractMonths__c     = 24,                    // > 12 => multi-year true
            PropertyName__c              = 'Abu Dhabi',
            AdminFee__c                  = 500,
            ContractTerm__c              = '24 months',
            TermofPayment__c             = 'Quarterly',
            GracePeriod__c               = 0,
            LeasingStartDate__c          =System.today()+30,
            LeasingEndDate__c            =System.today()+365,
            Remarks__c                   = 'Key handover upon first payment.',
            BloomTeamApprovalStatus__c   = 'Approved',
            CustomerApprovalStatus__c    = 'Approved',
            HandoverCondition__c         = 'Fitted',
            CurrentCondition__c          = 'Fitted'
            // TODO: add org-required fields if any (e.g., CurrencyIsoCode for multi-currency orgs)
        );
        insert leasingOrder;

        // ------------------------------
        // 5) CHILD DATA USED BY THE HELPER
        // ------------------------------
        // Payment plan schedules (constructor builds PaymentWrapper list and groups by Year)
        PaymentPlanSchedule__c p1 = new PaymentPlanSchedule__c(
            Name                        = 'Installment 1',
            LeasingOrder__c             = leasingOrder.Id,
            Year__c                     = 2025,
            Amount__c                   = 28750,
          //  Escalation__c               = 0,
            PaymentStartDate__c       = System.today()
            //VATAmount__c               = 1437.5,
           // Total_Installment_Amount__c = 30187.5
        );
        PaymentPlanSchedule__c p2 = new PaymentPlanSchedule__c(
            Name                        = 'Installment 2',
            LeasingOrder__c             = leasingOrder.Id,
            Year__c                     = 2025,
            Amount__c                   = 28750,
           // Escalation__c               = 0,
            PaymentStartDate__c       = System.today()
            //VATAmount__c               = 1437.5,
            //Total_Installment_Amount__c = 30187.5
        );
        insert new List<PaymentPlanSchedule__c>{ p1, p2 };

        // Escalation splits (returned by getSplits)
        LeasingEscalationSchedule__c s1 = new LeasingEscalationSchedule__c(
            LeasingOrder__c = leasingOrder.Id,
            Year__c         = 2025,
            AnnualRent__c   = 115000,
            Escalation__c   = 0,
            TotalRent__c    = 115000,
            AfterDiscount__c= 115000
        );
        LeasingEscalationSchedule__c s2 = new LeasingEscalationSchedule__c(
            LeasingOrder__c = leasingOrder.Id,
            Year__c         = 2026,
            AnnualRent__c   = 117300,
            Escalation__c   = 2,
            TotalRent__c    = 117300,
            AfterDiscount__c= 117300
        );
        insert new List<LeasingEscalationSchedule__c>{ s1, s2 };

        // Other charges (returned by getServiceCharges)
        // 1) Admin Fee (Residential -> Admin Fee + VAT)
        LeasingOrdersOtherCharges__c chAdmin = new LeasingOrdersOtherCharges__c(
            LeasingOrder__c = leasingOrder.Id,
            Type__c         = 'Admin Fee',
            ChargeAmount__c = 500,
            VATAmount__c   = 25,
           // TotalAmount__c  = 525,
            isVATApplied__c = true
        );
        // 2) Extra Cheque Fee (Residential -> shows VAT)
        LeasingOrdersOtherCharges__c chExtra = new LeasingOrdersOtherCharges__c(
            LeasingOrder__c = leasingOrder.Id,
            Type__c         = 'Extra Cheque Fee',
            ChargeAmount__c = 100,
            VATAmount__c   = 5,
           // TotalAmount__c  = 105,
            isVATApplied__c = true
        );
        // 3) Ejari/Tawtheeq Fee (Dubai -> "Ejari Fee" label in wrapper)
        LeasingOrdersOtherCharges__c chEjari = new LeasingOrdersOtherCharges__c(
            LeasingOrder__c = leasingOrder.Id,
            Type__c         = 'Ejari/Tawtheeq Fee',
            ChargeAmount__c = 225,
            VATAmount__c   = 0,
           // TotalAmount__c  = 225,
            isVATApplied__c = false
        );
        // 4) Generic fee (falls to default branch)
        LeasingOrdersOtherCharges__c chOther = new LeasingOrdersOtherCharges__c(
            LeasingOrder__c = leasingOrder.Id,
            Type__c         = 'Service Charge Fee',
            ChargeAmount__c = 150,
            VATAmount__c   = 0,
            //TotalAmount__c  = 150,
            isVATApplied__c = false
        );
        insert new List<LeasingOrdersOtherCharges__c>{ chAdmin, chExtra, chEjari, chOther };

        // ------------------------------
        // 6) EXERCISE SUT
        // ------------------------------
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(leasingOrder);
        LeasingOfferLetterGenerateController helper = new LeasingOfferLetterGenerateController(sc);

        // Constructor: object graph & computed fields
        System.assertNotEquals(null, helper.leaseContract, 'leaseContract should be set.');
        System.assertEquals(leasingOrder.Id, helper.leaseContract.Id, 'leaseContract.Id must match the record under test.');
        System.assertEquals(unit.Name, helper.unitNumber, 'Unit number should be from Unit__r.Name.');
        System.assertEquals(true, helper.isMultiyearContract, '24 months => multi-year should be true.');
        System.assert(helper.offerLetterTitle.contains('Offer Letter'),
            'Both approvals = "Offer Letter".');
        System.assertEquals('ejari', helper.rentSystem.toLowerCase(), 'Dubai municipality should map to Ejari.');

      
        // Payments grouped by year
        System.assertNotEquals(null, helper.paymentsByYear, 'paymentsByYear should be initialized.');
        System.assert(helper.paymentsByYear.containsKey('2025'), 'Should contain 2025 key.');
        System.assertEquals(2, helper.paymentsByYear.get('2025').size(), 'Two installments expected for 2025.');

        // @AuraEnabled: getSplits
        List<LeasingEscalationSchedule__c> splits = helper.getSplits();
        System.assertEquals(2, splits.size(), 'Two escalation split rows expected.');
        System.assertEquals(2025, splits[0].Year__c, 'First split should be 2025.');

        // @AuraEnabled: getPaymentSchedules
        List<PaymentPlanSchedule__c> schedules = helper.getPaymentSchedules();
        System.assertEquals(2, schedules.size(), 'Two payment schedules expected.');
        System.assertEquals('Installment 1', schedules[0].Name, 'Should be ordered by Year and then Name/Id order.');

        // @AuraEnabled: getServiceCharges
        //List<LeasingOfferLetterGenerateController.ServiceChargesWrapper> serviceCharges = helper.getServiceCharges();
        List<LeasingOfferLetterGenerateController.LeasingOtherChargesWrapper> serviceCharges = helper.getServiceCharges();
        System.assertEquals(4, serviceCharges.size(), 'Should return four rows.');
        

        // Utility formatter
        System.assertEquals('1,234.57', LeasingOfferLetterGenerateController.formatDecimalWithCommas(1234.567));
        System.assertEquals('12.30',    LeasingOfferLetterGenerateController.formatDecimalWithCommas(12.3));
        System.assertEquals('9,999,999.99', LeasingOfferLetterGenerateController.formatDecimalWithCommas(9999999.99));

        Test.stopTest();
    } 
}