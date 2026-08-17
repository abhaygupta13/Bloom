@isTest
public class ReceiptAcknowledgeTriggerforDeleteTest {

   
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
            UnitView__c  ='Beach Side',
            FloorNumber__c='01',
            NumberOfBedrooms__c='3',
            UnitModel__c='1BHK',
            SellingPrice__c=700000,
            EndDate__c=Date.today()+10,
            StartDate__c=Date.today()-10
        );
        insert testUnit;
        ids.put('unit', testUnit.Id);

        PaymentPlan__c pp = new PaymentPlan__c(
            Name='July Plan',
            Unit__c=testUnit.id,
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

        pp.IsActive__c='Yes';
        update pp;

        Id acctRT = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                         .get('PersonAccount').getRecordTypeId();
        Account acc = new Account(
            RecordTypeId=acctRT,
            LastName='Test Person',
            PersonEmail='test@test.com'
        );
        insert acc;
        ids.put('acc', acc.Id);

        Opportunity opp = new Opportunity(
            Name='tempOpp',
            StageName='New',
            CloseDate=System.today(),
            LeadChannel__c='Walk in',
            AccountId=acc.Id,
            WinReason__c='Loyalty'
        );
        insert opp;
        ids.put('opp', opp.Id);

        SalesOrder__c order = new SalesOrder__c(
            Name='Test Order',
            Status__c='Booked',
            Unit__c=testUnit.id,
            Account__c=acc.Id,
            Opportunity__c=opp.Id
        );
        insert order;
        ids.put('order', order.Id);

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
            ReceiptAcknowledgement__c ra = new ReceiptAcknowledgement__c(
                Opportunity__c=data.get('opp'),
                PaymentType__c='Cash',
                Amount__c=100,
                SalesOrder__c=data.get('order'),
                Account__c=data.get('acc')
            );
            insert ra;

            Test.startTest();
            delete ra; 
            Test.stopTest();
        }
    }

    @isTest
    static void testNonSystemAdminDelete_ErrorExpected() {
      
        Profile p = [SELECT Id FROM Profile WHERE Name='Operations Team' LIMIT 1];
        User normalUser = new User(
            FirstName='Operation',
            LastName='User',
            Alias='op',
            Email='op' + System.currentTimeMillis() + '@test.com',
            EmailEncodingKey='UTF-8',
            ProfileId=p.Id, 
            LocaleSidKey='en_US',
            LanguageLocaleKey='en_US',
            TimeZoneSidKey='America/Los_Angeles',
            Username='op' + System.currentTimeMillis() + '@test.com'
        );
        insert normalUser;

        Map<String, Id> data = createBaseData();

        System.runAs(normalUser) {
            // PaymentType ≠ 'Transfer of rights - Resale' → should error
            ReceiptAcknowledgement__c ra = new ReceiptAcknowledgement__c(
                Opportunity__c=data.get('opp'),
                PaymentType__c='Cash',
                Amount__c=100,
                SalesOrder__c=data.get('order'),
                Account__c=data.get('acc')
            );
            insert ra;

            Test.startTest();
            try {
                delete ra;
                System.assert(true, 'Expected delete to fail for non-admin');
            } catch (DmlException e) {
                System.assert(e.getMessage().contains('You do not have permission'));
            }
            Test.stopTest();
        }
    }

   
}