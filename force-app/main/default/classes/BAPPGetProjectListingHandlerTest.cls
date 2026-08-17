/*
* @Author        : Rushikesh Jadhav
* @CreatedDate  : 20th SEP 2025
* @Description  : Test class for BAPPGetProjectListingHandler.
*/
/*****************************************************************************************************
* Version     Author             Date           Comment
* 1.0         Rushikesh Jadhav   20SEP2025      Initial draft – unit tests for project listing handler
*****************************************************************************************************/
@IsTest
private class BAPPGetProjectListingHandlerTest {
    
    @IsTest
    static void test_handleGetProjects_HighLevelContact() {
        Date today = System.today();
        
        Account acc = createAccount('Test Agency Account');
        Contact con = createContact(acc, 'Admin', true, 'Admin Contact');
        
        // === Project ===
        Project__c proj1 = new Project__c(
            Name = 'Project Alpha',
            IsPublic__c = false,
            IsAvailableForBroker__c = true,
            StartDate__c = today.addDays(-1),
            EndDate__c = today.addDays(5)
        );
        insert proj1;
        
        ProjectAgencyAllocation__c paa1 = new ProjectAgencyAllocation__c(
            Account__c = acc.Id,
            Project__c = proj1.Id,
            IsActive__c = true
        );
        insert paa1;
        
        Unit__c unit1 = new Unit__c(
            Name = 'Unit-1',
            Project__c = proj1.Id,
            UnitType__c = 'Apartment',
            IsExclusive__c = true,
            Direct_Indirect__c = 'Indirect',
            Status__c = 'Available',
            StartDate__c = today.addDays(-1),
            EndDate__c = today.addDays(5)
        );
        insert unit1;
        
        BrokerUnitAllocations__c bua1 = new BrokerUnitAllocations__c(
            Account__c = acc.Id,
            Unit__c = unit1.Id
        );
        insert bua1;
        
        // === Public Project ===
        Project__c pubProj = new Project__c(
            Name = 'Public Project',
            IsPublic__c = true,
            IsAvailableForBroker__c = true,
            StartDate__c = today.addDays(-1),
            EndDate__c = today.addDays(10)
        );
        insert pubProj;
        
        // === Public Unit (added flags for new methods) ===
        Unit__c pubUnit = new Unit__c(
            Name = 'Public Unit',
            Project__c = pubProj.Id,
            UnitType__c = 'Apartment',
            Status__c = 'Available',
            StartDate__c = today.addDays(-1),
            EndDate__c = today.addDays(10),
            IsExclusive__c = false,
            Direct_Indirect__c = 'Indirect',
            IsPublic__c = true
        );
        insert pubUnit;
        
        Test.startTest();
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        
        BAPPGetProjectListingHandler.handleGetProjects(acc.Id, con.Id);
        Test.stopTest();
        
    }
    
    @IsTest
    static void test_handleGetProjects_NormalContact() {
        Date today = System.today();
        
        Account acc = createAccount('Test Agency Account');
        Contact con = createContact(acc, 'Agent', true, 'Agent Contact');
        
        Project__c proj2 = new Project__c(
            Name = 'Project Beta',
            IsPublic__c = false,
            IsAvailableForBroker__c = true,
            StartDate__c = today.addDays(-1),
            EndDate__c = today.addDays(5)
        );
        insert proj2;
        
        ProjectAgencyAllocation__c paa2 = new ProjectAgencyAllocation__c(
            Account__c = acc.Id,
            Project__c = proj2.Id,
            IsActive__c = true
        );
        insert paa2;
        
        Unit__c unit2 = new Unit__c(
            Name = 'Unit-2',
            Project__c = proj2.Id,
            UnitType__c = 'Apartment',
            Status__c = 'Available',
            StartDate__c = today.addDays(-1),
            EndDate__c = today.addDays(5),
            IsExclusive__c = true,
            Direct_Indirect__c = 'Indirect'
        );
        insert unit2;
        
        BrokerUnitAllocations__c bua2 = new BrokerUnitAllocations__c(
            Account__c = acc.Id,
            Unit__c = unit2.Id
        );
        insert bua2;
        
        BrokerUnitAssignment__c assign = new BrokerUnitAssignment__c(
            Contact__c = con.Id,
            BrokerUnitAllocation__c = bua2.Id,
            Active__c = true
        );
        insert assign;
        
        Project__c pubProj2 = new Project__c(
            Name = 'Public Beta',
            IsPublic__c = true,
            IsAvailableForBroker__c = true,
            StartDate__c = today.addDays(-1),
            EndDate__c = today.addDays(8)
        );
        insert pubProj2;
        
        Unit__c pubUnit2 = new Unit__c(
            Name = 'Public Unit 2',
            Project__c = pubProj2.Id,
            UnitType__c = 'Apartment',
            Status__c = 'Available',
            StartDate__c = today.addDays(-1),
            EndDate__c = today.addDays(8),
            IsExclusive__c = false,
            Direct_Indirect__c = 'Indirect',
            IsPublic__c = true
        );
        insert pubUnit2;
        
        Test.startTest();
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        
        BAPPGetProjectListingHandler.handleGetProjects(acc.Id, con.Id);
        Test.stopTest();
        
    }
    
    @IsTest
    static void test_handleGetProjects_ErrorScenarios() {
        Test.startTest();
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        
        // === Missing Account/Contact ===
        BAPPGetProjectListingHandler.handleGetProjects(null, null);
        
        // === Invalid Contact Id (does not exist) ===
        BAPPGetProjectListingHandler.handleGetProjects('001000000000001', '003000000000001');
        
        // === Contact not belonging to Account ===
        Account acc1 = createAccount('Account One');
        Account acc2 = createAccount('Account Two');
        Contact conWrong = createContact(acc2, 'Agent', true, 'Wrong Contact');
        BAPPGetProjectListingHandler.handleGetProjects(acc1.Id, conWrong.Id);

        Test.stopTest();
    }
    
    private static Account createAccount(String name) {
        Account acc = new Account(
            Name = name,
            AddressLine01__c = 'Address Line 1',
            AddressLine02__c = 'Address Line 2',
            RecordTypeId = Utility.getRecordTypeIdByDevName(Account.SObjectType, 'Broker_Agency')
        );
        insert acc;
        return acc;
    }
    
    private static Contact createContact(Account acc, String role, Boolean isActive, String lastName) {
        Contact con = new Contact(
            LastName = lastName,
            AccountId = acc.Id,
            BrokerContactRole__c = role,
            IsActive__c = isActive,
            Email ='test@example.com',
            RecordTypeId = Utility.getRecordTypeIdByDevName(Contact.SObjectType, 'Broker')
        );
        insert con;
        return con;
    }
}