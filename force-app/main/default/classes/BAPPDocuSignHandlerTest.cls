@isTest
public class BAPPDocuSignHandlerTest {
    
    @isTest
    static void BldocusignclsTestMethod() {
        // Test data setup
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Contact con1 = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'john.doe@example.com',
            MobileCountryCode__c = '+1',
            MobilePhone = '1234567890',
            AccountId = acc.Id
        );
        insert con1;
        
        Opportunity tempOpp=new Opportunity(
            Name='tempOpp',
            StageName='New',
            CloseDate=system.today(),
            LeadChannel__c='Walk in',
            AccountId= acc.Id,
            WinReason__c='Loyalty'
            
            
        );
        insert tempOpp;
        
        Project__c testProject=new Project__c(
            Name='Test Project'
        );
        insert testProject;
        
        
        
        BuildingSection__c testBuilding=new BuildingSection__c(
            Name='Test Building',
            BuildingSectionCode__c='BL-CAS',
            Project__c=testProject.Id
            
        );
        insert testBuilding;
        
        Unit__c testUnit=new Unit__c(
            Name='test Unit',
            Status__c='Available',
            UnitType__c='Townhouse',
            BuildingSectionName__c=testBuilding.id,
            Project__c=testProject.Id,
            PropertyUsage__c='Residential',
            UnitView__c  ='Beach Side',
            FloorNumber__c='01',
            NumberOfBedrooms__c='3',
            UnitModel__c='1BHK',
            SellingPrice__c= 700000,
            EndDate__c= date.today()+10,
            StartDate__c=date.today()-10
            
        );
        insert testUnit;
        
        SalesOrder__c testOrder = new SalesOrder__c(
            Name = 'Test Order',
            Status__c = 'Sold',
            Unit__c =testUnit.id,
            Account__c = acc.Id,
            Opportunity__c=tempOpp.Id
            
            
        );
        insert testOrder;
        
        JointOwner__c testJointOwner=new JointOwner__c(
            Account__c=acc.Id,
            SharePercentage__c=0,
            Salesorder__c = testOrder.id
        );
        
        insert testJointOwner;
        dfsle__EnvelopeConfiguration__c dfsub = new dfsle__EnvelopeConfiguration__c(
            dfsle__DocuSignId__c = '1122'
        );
        insert dfsub;
        
        Bloom_Docusign_Submissions__c submission = new Bloom_Docusign_Submissions__c(
            Description__c = 'Test Description',
            // Docusign_Envelope_Template_ID__c = dfsub.Id
            Sales_Order_ID__c = testOrder.Id,
            Document_Output_Name__c = 'Test Document'
        );
        insert submission;
        
        // Create a test User with BBM in name
        Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User bbmUser = new User(
            FirstName = 'Test',
            LastName  = 'BBM User',
            Alias     = 'tuser',
            Email     = 'shruti.kulkarni@infobeans.com',
            Username  = 'tuser' + DateTime.now().getTime() + '@test.com',
            CommunityNickname = 'tuser' + DateTime.now().getTime(),
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = testProfile.Id
        );
        insert bbmUser;
        
        BrokerApplication__c brokerApp = new BrokerApplication__c(
            Name = 'Test Broker App',
            BBMId__c = bbmUser.Id
        );
        insert brokerApp;
        
        BrokerApplicant__c bApplicant = New BrokerApplicant__c();
        bApplicant.BrokerApplication__c = brokerApp.Id;
        bApplicant.FirstName__c = 'Test';
        bApplicant.LastName__c = 'User';
        bApplicant.Email__c = 'shruti.kulkarni@infobeans.com';
        bApplicant.BrokerContactRole__c = '	AuthorizedSignatoryOfficer';
        
        Insert bApplicant;

        Test.startTest();
        BAPPDocuSignHandler.getRecipients(brokerApp.Id, 'Broker Agreement');
        
        Test.stopTest();
        
        
    }
}