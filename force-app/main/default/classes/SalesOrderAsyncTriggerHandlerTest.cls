@isTest
public class SalesOrderAsyncTriggerHandlerTest {
    @istest
    static void TestMethod1(){
        Test.enableChangeDataCapture();

        // Test data for Project__c and related Units
        Account account = TestDataFactory.createPersonalAccount('Lastname', '01010101', '1234567890', 'test@gmail.com');
        account.CustomerType__c = 'Resident';
        INSERT account;

        Id accRecordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Broker Agency').getRecordTypeId();
        Account acc = new Account(Name = 'Test Account', RecordTypeId= accRecordTypeId);
        insert acc;
        
        //Test data for Project__c and related Units
        Project__c project = TestDataFactory.createProject('ProjectTest', Date.today() - 1);
        insert project;
        
        Unit__c u = TestDataFactory.createUnit(project.Id, 'A1-G01', 'Unassigned');
        u.Project__c = project.Id;
        u.RegistrationDate__c = Date.today();
        insert u;
        
        Contact con1 = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'john.doe@example.com',
            MobileCountryCode__c = '+1',
            MobilePhone = '1234567890',
            AccountId = acc.Id
        );
        insert con1;
        
        Opportunity tempOpp = new Opportunity(
            Name ='tempOpp',
            StageName ='New',
            CloseDate =system.today(),
            LeadChannel__c ='Walk in',
            AccountId = account.Id,
            WinReason__c ='Loyalty',
            BrokerAgencyAccount__c = acc.Id,
            BrokerAgentContact__c = con1.Id
        );
        insert tempOpp;
        
        //List<SalesOrder__c> solist = new List<SalesOrder__c>();
        SalesOrder__c soRec = TestDataFactory.createSalesOrder(account.Id, null, null, null, u.Id, 100.00);
        //salesOrder.DocumentUploadedDate__c = Date.today();
        soRec.UnitRegistrationDate__c = Date.today();
        soRec.Status__c= 'Booked';
        soRec.Opportunity__c = tempOpp.Id;
        insert soRec;
        Test.getEventBus().deliver();
        
        SalesOrder__c soRec2 = new SalesOrder__c(Id= soRec.Id);
        soRec.Bloom_Signed_SPA_Date__c = System.today();
        Update soRec;
        Test.getEventBus().deliver();
        
        //Delete the record
        Test.enableChangeDataCapture();
        DELETE soRec;
        Test.getEventBus().deliver();
        //UnDelete the record
        Test.enableChangeDataCapture();
        UNDELETE soRec;
        Test.getEventBus().deliver();
        
        SalesOrder__ChangeEvent event = new SalesOrder__ChangeEvent();
        
        // Set the ChangeEventHeader
        EventBus.ChangeEventHeader header = new EventBus.ChangeEventHeader();
        header.changeType = 'CREATE'; // Change to 'UPDATE', 'DELETE', or 'UNDELETE' to test other scenarios
        event.ChangeEventHeader = header;
        //  EventBus.Publish(event);
        
        
        // Set the ChangeEventHeader
        EventBus.ChangeEventHeader header2 = new EventBus.ChangeEventHeader();
        header2.changeType = 'UPDATE'; // Change to 'UPDATE', 'DELETE', or 'UNDELETE' to test other scenarios
        event.ChangeEventHeader = header2;
        EventBus.ChangeEventHeader header3 = new EventBus.ChangeEventHeader();
        header3.changeType = 'DELETE'; // Change to 'UPDATE', 'DELETE', or 'UNDELETE' to test other scenarios
        event.ChangeEventHeader = header3;
        EventBus.ChangeEventHeader header4 = new EventBus.ChangeEventHeader();
        header4.changeType = 'UNDELETE'; // Change to 'UPDATE', 'DELETE', or 'UNDELETE' to test other scenarios
        event.ChangeEventHeader = header4;
        test.starttest();
        
        
        SalesOrderAsyncTriggerHandler soAsyncHandler = new SalesOrderAsyncTriggerHandler(); 
        //ias.changeTypeCreate(new List<Id>{Llist[0].Id});
        //ias.changeTypeDelete(new List<Id>{Llist[0].Id});
       // ias.changeTypeUndelete(new List<Id>{Llist[0].Id});
       // ias.changeTypeUpdate(new List<Id>{Llist[0].Id});
        
        //soAsyncHandler.isDisabled();
        //AsyncTriggerDispatcher.disableAllAsyncTriggers();
        //AsyncTriggerDispatcher.enableAllAsyncTriggers();
        //AsyncTriggerDispatcher.run(null);
        
        test.stoptest();
    }
     @istest
    static void salesOrderADAHTesting(){
        Test.enableChangeDataCapture();

        // Test data for Project__c and related Units
        Account account = TestDataFactory.createPersonalAccount('Lastname', '01010101', '1234567890', 'test@gmail.com');
        account.CustomerType__c = 'Resident';
        INSERT account;

        Id accRecordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Broker Agency').getRecordTypeId();
        Account acc = new Account(Name = 'Test Account', RecordTypeId= accRecordTypeId);
        insert acc;
        
        //Test data for Project__c and related Units
        Project__c project = TestDataFactory.createProject('ProjectTest', Date.today() - 1);
        insert project;
        
        Unit__c u = TestDataFactory.createUnit(project.Id, 'A1-G01', 'Unassigned');
        u.Project__c = project.Id;
        u.RegistrationDate__c = Date.today();
        insert u;
        
        Contact con1 = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'john.doe@example.com',
            MobileCountryCode__c = '+1',
            MobilePhone = '1234567890',
            AccountId = acc.Id
        );
        insert con1;
        
        Opportunity tempOpp = new Opportunity(
            Name ='tempOpp',
            StageName ='New',
            CloseDate =system.today(),
            LeadChannel__c ='Walk in',
            AccountId = account.Id,
            WinReason__c ='Loyalty',
            BrokerAgencyAccount__c = acc.Id,
            BrokerAgentContact__c = con1.Id,
            ADHAApplicationNumber__c = 'A1234567'
        );
        insert tempOpp;
        
        //List<SalesOrder__c> solist = new List<SalesOrder__c>();
        SalesOrder__c soRec = TestDataFactory.createSalesOrder(account.Id, null, null, null, u.Id, 100.00);
        //salesOrder.DocumentUploadedDate__c = Date.today();
        soRec.UnitRegistrationDate__c = Date.today();
        soRec.Status__c= 'Booked';
        soRec.Opportunity__c = tempOpp.Id;
        insert soRec;
        Test.getEventBus().deliver();
        
        SalesOrder__c soRec2 = new SalesOrder__c(Id= soRec.Id);
       // soRec.Bloom_Signed_SPA_Date__c = System.today();
        soRec.Status__c = 'Reserved';
       // soRec.ADHAApplicationNumber__c = 'A1234567' ;
        Update soRec;
        Test.getEventBus().deliver();
        
        //Delete the record
        Test.enableChangeDataCapture();
        DELETE soRec;
        Test.getEventBus().deliver();
        //UnDelete the record
        Test.enableChangeDataCapture();
        UNDELETE soRec;
        Test.getEventBus().deliver();
        
        SalesOrder__ChangeEvent event = new SalesOrder__ChangeEvent();
        
        // Set the ChangeEventHeader
        EventBus.ChangeEventHeader header = new EventBus.ChangeEventHeader();
        header.changeType = 'CREATE'; // Change to 'UPDATE', 'DELETE', or 'UNDELETE' to test other scenarios
        event.ChangeEventHeader = header;
        //  EventBus.Publish(event);
        
        
        // Set the ChangeEventHeader
        EventBus.ChangeEventHeader header2 = new EventBus.ChangeEventHeader();
        header2.changeType = 'UPDATE'; // Change to 'UPDATE', 'DELETE', or 'UNDELETE' to test other scenarios
        event.ChangeEventHeader = header2;
        EventBus.ChangeEventHeader header3 = new EventBus.ChangeEventHeader();
        header3.changeType = 'DELETE'; // Change to 'UPDATE', 'DELETE', or 'UNDELETE' to test other scenarios
        event.ChangeEventHeader = header3;
        EventBus.ChangeEventHeader header4 = new EventBus.ChangeEventHeader();
        header4.changeType = 'UNDELETE'; // Change to 'UPDATE', 'DELETE', or 'UNDELETE' to test other scenarios
        event.ChangeEventHeader = header4;
        test.starttest();
        
        
        SalesOrderAsyncTriggerHandler soAsyncHandler = new SalesOrderAsyncTriggerHandler(); 
        
        
        test.stoptest();
    }
}