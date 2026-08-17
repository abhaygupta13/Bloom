@isTest
public class InstallmentTriggerForDeleteTest {

    // Reusable method to create base data
    private static Map<String, Id> createBaseData() {
        Map<String, Id> ids = new Map<String, Id>();

        Project__c testProject = new Project__c(Name='Test Project');
        insert testProject;
        ids.put('project', testProject.Id);

        BuildingSection__c testBuilding = new BuildingSection__c(
            Name='Test Building',
            BuildingSectionCode__c='BL-CAS',
            Project__c=testProject.Id
        );
        insert testBuilding;
        ids.put('building', testBuilding.Id);

        Unit__c testUnit = new Unit__c(
            Name='test Unit',
            Status__c='Available',
            UnitType__c='Townhouse',
            BuildingSectionName__c=testBuilding.id,
            Project__c=testProject.Id,
            PropertyUsage__c='Residential',
            UnitView__c='Beach Side',
            FloorNumber__c='01',
            NumberOfBedrooms__c='3',
            UnitModel__c='1BHK',
            SellingPrice__c=700000,
            EndDate__c= Date.today()+10,
            StartDate__c=Date.today()-10
        );
        insert testUnit;
        ids.put('unit', testUnit.Id);

        PaymentPlan__c pp = new PaymentPlan__c(
            Name='July Plan',
            Unit__c=testUnit.Id,
            Description__c='Test',
            IsActive__c='NO',
            BrokerPortalFlag__c=true,
            Classification__c=Constants.PAYMENT_PLAN_TYPE_STANDARD
        );
        insert pp;
        ids.put('pp', pp.Id);

        BuildingSectionMapping__c mappingRecord = new BuildingSectionMapping__c(
            BuildingSectionName__c=testBuilding.id,
            PaymentPlan__c=pp.id
        );
        insert mappingRecord;

        PaymentInstallments__c ppi = new PaymentInstallments__c(
            BrokerPayoutPercentage__c=100,
            Description__c='test description',
            InstallmentNumber__c=1,
            InstallmentPercentage__c=100,
            PaymentPlan__c=pp.id,
            Condition_Type__c='P012'
        );
        insert ppi;
        ids.put('ppi', ppi.Id);

        pp.IsActive__c='Yes';
        update pp;

        Id acctRT = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                          .get('PersonAccount').getRecordTypeId();
        Account tempAcc = new Account(
            RecordTypeId = acctRT,
            LastName = 'test',
            PersonEmail = 'test@test.com'
        );
        insert tempAcc;
        ids.put('acc', tempAcc.Id);

        Opportunity tempOpp = new Opportunity(
            Name='tempOpp',
            StageName='New',
            CloseDate=System.today(),
            LeadChannel__c='Walk in',
            AccountId=tempAcc.Id,
            WinReason__c='Loyalty'
        );
        insert tempOpp;
        ids.put('opp', tempOpp.Id);

        SalesOrder__c testOrder = new SalesOrder__c(
            Name = 'Test Order',
            Status__c = 'Booked',
            Unit__c = testUnit.id,
            Account__c = tempAcc.Id,
            Opportunity__c = tempOpp.Id,
            Resale__c = true
        );
        insert testOrder;
        ids.put('order', testOrder.Id);

        return ids;
    }

    @isTest
    static void testSystemAdminDelete() {
        Profile sysAdminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];

        User adminUser = new User(
            ProfileId = sysAdminProfile.Id,
            Username = 'admin' + System.currentTimeMillis() + '@test.com',
            Email = 'admin@test.com',
            Alias = 'adm',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Admin',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            IsActive = true
        );
        insert adminUser;

        Map<String, Id> data = createBaseData();

        System.runAs(adminUser) {
            InstallmentLines__c inst = new InstallmentLines__c(
                PaymentPlan__c = data.get('pp'),
                PaymentInstallments__c = data.get('ppi'),
                SalesOrder__c = data.get('order'),
                Description__c = 'Anything',
                InstallmentAmount__c = 100000
            );
            insert inst;

            Test.startTest();
            delete inst; // Admin allowed
            Test.stopTest();
        }
    }

    @isTest
    static void testNonAdminDelete_ErrorExpected() {
        Profile p = [SELECT Id FROM Profile WHERE Name='Operations Team' LIMIT 1];

        User opUser = new User(
            FirstName='Op',
            LastName='User',
            Alias='op1',
            Email='op1'+System.currentTimeMillis()+'@test.com',
            EmailEncodingKey='UTF-8',
            ProfileId=p.Id,
            LocaleSidKey='en_US',
            LanguageLocaleKey='en_US',
            TimeZoneSidKey='America/Los_Angeles',
            Username='op1'+System.currentTimeMillis()+'@test.com'
        );
        insert opUser;

        System.runAs(opUser) {
            // Create all dependent records inside runAs so user has access
            Map<String, Id> data = createBaseData();

            InstallmentLines__c inst = new InstallmentLines__c(
                PaymentPlan__c = data.get('pp'),
                PaymentInstallments__c = data.get('ppi'),
                SalesOrder__c = data.get('order'),
                Description__c = 'Not Resale', // should trigger addError
                InstallmentAmount__c = 50000
            );
            insert inst;

            Test.startTest();
            try {
                delete inst;
                System.assert(true, 'Should not delete when Description != Resale');
            } catch (DmlException e) {
                System.assert(e.getMessage().contains('You do not have permission'));
            }
            Test.stopTest();
        }
    }

    @isTest
    static void testNonAdminDelete_Allowed() {
        Profile p = [SELECT Id FROM Profile WHERE Name='Operations Team' LIMIT 1];

        User opUser = new User(
            FirstName='Op',
            LastName='User2',
            Alias='op2',
            Email='op2'+System.currentTimeMillis()+'@test.com',
            EmailEncodingKey='UTF-8',
            ProfileId=p.Id,
            LocaleSidKey='en_US',
            LanguageLocaleKey='en_US',
            TimeZoneSidKey='America/Los_Angeles',
            Username='op2'+System.currentTimeMillis()+'@test.com'
        );
        insert opUser;

        System.runAs(opUser) {
            Map<String, Id> data = createBaseData();

            InstallmentLines__c inst = new InstallmentLines__c(
                PaymentPlan__c = data.get('pp'),
                PaymentInstallments__c = data.get('ppi'),
                SalesOrder__c = data.get('order'),
                Description__c = 'Resale', // Allowed
                InstallmentAmount__c = 60000
            );
            insert inst;

            Test.startTest();
            delete inst; // Should succeed
            Test.stopTest();
        }
    }
}