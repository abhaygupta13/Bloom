@isTest
public class DocumentTriggerHandlerTest {
    @isTest
    static void unitTest1() {
        HandoverTriggerHandler.isTriggerDisabled = true;
        // Test data for Project__c and related Units
        Account account = TestDataFactory.createPersonalAccount('Lastname', '01010101', '1234567890', 'test@gmail.com');
        account.CustomerType__c = 'Resident';
        INSERT account;
        
        //Test data for Project__c and related Units
        Project__c project = TestDataFactory.createProject('ProjectTest', Date.today() - 1);
        insert project;
        
        Unit__c u = TestDataFactory.createUnit(project.Id, 'A1-G01', 'Unassigned');
        u.Project__c = project.Id;
        u.RegistrationDate__c = Date.today();
        insert u;
        
        SalesOrder__c salesOrder = TestDataFactory.createSalesOrder(account.Id, null, null, null, u.Id, 100.00);
        salesOrder.DocumentUploadedDate__c = Date.today() - 1; 
        salesOrder.UnitRegistrationDate__c = Date.today();
        insert salesOrder;
        
        u.Active_Sales_Order__c = salesOrder.Id;
        update u;
        
        DocumentType__c dc1 = TestDataFactory.createDocumentType('Sales Order', 'Emirates ID');
        INSERT dc1;
        // Create test Document__c record
        Document__c testDocument = TestDataFactory.createDoc(dc1.Id, salesOrder.Id, null);
        testDocument.Document_Name__c = 'Emirates ID';
        insert testDocument;
        testDocument.ContentDocumentId__c = '001001';
        Update testDocument;
        
        // Create a Handover record
        Handover__c handover1 = new Handover__c(
            Name = 'Test Handover',
            Customer_Email__c = 'test@example.com',
            
            Is_BCC_Announcement_Sent__c = false,
            Unit__c = u.Id,
            Project__c = project.Id,
            Customer_Availability_for_CHO__c = 'Customer Available',
            
            UnitCategory__c='Registered Unit',
            Is_Notice_of_Completion_Sent__c=false
        );
        insert handover1;
        
        Document__c testDocument1 = TestDataFactory.createDoc(dc1.Id, salesOrder.Id, null);
        testDocument1.Document_Name__c = 'SPA';
        insert testDocument1;
        testDocument1.Handover__c = handover1.id;
        testDocument1.ContentDocumentId__c = '001001';
        UPDATE testDocument1;
        
         handover1.CRM_Team_Assigned_User__c = UserInfo.getUserId();
        update handover1;

      /*  DocumentTriggerHelper.changeHandoverOwnerOnSpaUpdate(
            new List<Document__c>{testDocument1}, 
            new Map<Id, Document__c>{testDocument1.Id => testDocument1}
        );*/

        DocumentTriggerHelper helper = new DocumentTriggerHelper();
        helper.sendLeasingFinanceEmail(null, null, new List<String>{'test@test.com'}, null);
        
    }
    
    @isTest
    static void unitTest2() {
        Account acc = new Account(
            LastName = 'Test Person Account', 
            Phone = '971202520',
            PersonEmail='abc@gmail.com',
            Nationality__c = 'Indian',
            
            PrimaryMobilePhone__pc = '1234567890',
            
            SecondaryMobilePhone__pc = '9876543210',
            
            TertiaryMobilePhone__pc = '1122334455'
        );
        insert acc;
        
        Opportunity opp = new Opportunity(
            Name='Test Opp',
            StageName='Prospecting',
            OpportunityType__c = 'Leasing',
            CloseDate=System.today().addDays(30),
            AccountId=acc.Id
        );
        insert opp;
        
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
        
        DocumentType__c dc2 = TestDataFactory.createDocumentType('LeasingOrder__c ', 'Emirates ID');
        INSERT dc2;
        Document__c testDocument2 = new Document__c();
        testDocument2.DocumentType__c = dc2.Id;
        testDocument2.LeasingOrder__c = lo.Id;
        testDocument2.ContentDocumentId__c = '001000';
        testDocument2.Document_Name__c = 'Leasing Contract - Signed';
        insert testDocument2;
        testDocument2.ContentDocumentId__c = '001001';
        Update testDocument2;
        
        Document__c testDocument3 = new Document__c();
        testDocument3.DocumentType__c = dc2.Id;
        testDocument3.LeasingOrder__c = lo.Id;
        testDocument3.ContentDocumentId__c = '001000';
        testDocument3.Document_Name__c = 'Leasing Offer - Signed';
        insert testDocument3;
        testDocument3.ContentDocumentId__c = '001001';
        Update testDocument3;
    }
    
    
}