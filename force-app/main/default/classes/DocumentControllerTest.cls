@isTest
public class DocumentControllerTest {

    @TestSetup
    static void creatingData() {
        Account account = TestDataFactory.createPersonalAccount('Lastname', '01010101', '1234567890', 'test@gmail.com');
        INSERT account;
        
        Account brAcc = TestDataFactory.createBrokerAccount('Test Account2', false, '1234567890');
        insert brAcc;
        
       
        
        Opportunity tempOpp=new Opportunity(
            Name='tempOpp',
            StageName='New',
            CloseDate=system.today(),
            LeadChannel__c='Walk in',
            AccountId=account.Id
            
        );
        insert tempOpp;

        //Test data for Project__c and related Units
        Project__c project = new Project__c();
        project.Name = 'TEST';
        project.ProjectRegistrationDate__c = Date.today() - 1;
        insert project;

        List<Unit__c> unitLst = new List<Unit__c>();
        for (Integer i = 0; i < 1; i++) {
            Unit__c u = TestDataFactory.createUnit(project.Id, 'A1-G01' + i, 'Unassigned');
            u.RegistrationDate__c = Date.today();
            unitLst.add(u);
        }
        insert unitLst;

        SalesOrder__c salesOrder = new SalesOrder__c();
        salesOrder.Unit__c = unitLst[0].Id;
        salesOrder.Account__c = account.Id;
        salesOrder.DocumentUploadedDate__c = Date.today() - 1;
        insert salesOrder;

        unitLst[0].Active_Sales_Order__c = salesOrder.Id;
        update unitLst;
                
        DocumentType__c documentType = TestDataFactory.createDocumentType('Account', 'Emirates ID');
        insert documentType;
        
        
        // Create Document
        Document__c document = TestDataFactory.createDocument(null, documentType.Id, 'test');
        insert document;

        Date startDate = System.today();       
        BrokerCommission__c brokerCommission = TestDataFactory.createBrokerCommission(100, 5,null, startDate, '', project.Id, salesOrder.Id, account.Id, null, null);
        insert brokerCommission;
        
        Contact con = TestDataFactory.createContact('Saud', brAcc.id, true ,'test@gmail.com');
        insert con;
        
        BrokerApplication__c brApp = TestDataFactory.createBrokerApplication('Test BrokerApp', 'Domestic');
        
        BrokerApplicant__c brApl = TestDataFactory.createBrokerApplicant(brApp.Id);
        
        LeasingOrder__c leasingOrder = new LeasingOrder__c(
            Name                         = 'LC-A-1204',
            Unit__c                      =  unitLst[0].Id,               // <== UNIT ASSOCIATED TO LEASING ORDER
            Opportunity__c               = tempOpp.Id,                // helper loads Opportunity fields
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
        );
        insert leasingOrder;
    }
    
    @isTest
    static void testMethods() {
        Project__c proj = [SELECT Id FROM Project__c WHERE Name = 'TEST' Limit 1];
        Document__c doc = [SELECT Id FROM Document__c WHERE Document_Name__c = 'test' LIMIT 1];
        Account acc = [SELECT Id FROM Account WHERE lastName = 'Lastname' LIMIT 1];
        SalesOrder__c so = [SELECT Id FROM SalesOrder__c];
        BrokerCommission__c brkrCommission = [SELECT Id FROM BrokerCommission__c ];
        Document__c document = [SELECT Id FROM Document__c LIMIT 1]; 
        Unit__c u = [SELECT Id FROM Unit__c LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        BrokerApplication__c brApp = [SELECT Id FROM BrokerApplication__c LIMIT 1];
        BrokerApplicant__c brApl = [SELECT Id FROM BrokerApplicant__c LIMIT 1];
                Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
LeasingOrder__c lsOrder = [SELECT Id FROM LeasingOrder__c LIMIT 1];
        
        String base64 = 'dGVzdCBkYXRh'; // Base64 for 'test data'
        String fileName = 'TestFile.pdf';
        
        Test.startTest();
        DocumentController.getDocuments(doc.Id);
        DocumentController.getDocuments(proj.Id);
        DocumentController.getDocuments(acc.Id);
        DocumentController.getDocuments(so.Id);   
        DocumentController.getDocuments(brkrCommission.Id);
        DocumentController.getDocuments(u.Id);
        DocumentController.getDocuments(con.Id);
		DocumentController.getDocuments(brApp.Id);
		DocumentController.getDocuments(brApl.Id);
        DocumentController.getDocuments(opp.Id);
        DocumentController.getDocuments(lsOrder.Id);
        
        DocumentController.addFile(base64, fileName, document.Id); 
        DocumentController.deleteFile(document.Id);
        DocumentController.shareDocument(document.Id);
        //added by Ranjan
        DocumentController.getArchiveDocuments(document.Id);
        
        Test.stopTest();

    }
}