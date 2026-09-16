/*
* @Author        : Rushikesh Jadhav
* @CreatedDate  : 22th SEP 2025
* @Description  : Test class for BAPPGetTeamMembersHandler
*                 covering success, validation, and
*                 no-data scenarios.
*/
/*****************************************************************************************************
* Version       Author           Date             Comment                                                                       
* 1.0           Rushikesh        22-SEP-2025      Initial test implementation for team member handler
*****************************************************************************************************
*/
@isTest
public class BAPPGetTeamMembersHandlerTest {

    @testSetup
    static void setupTestData() {
        // Create Account
        Account acc = new Account(Name = 'Test Broker Account');
        insert acc;

        Contact con = createContact(acc, 'Admin', true, 'Admin Contact');

        // Create Case linked to Account
        Case cs = new Case(
            AccountId = acc.Id,
            Subject = 'Test Case Subject',
            Type = 'Question',
            Status = 'New',
            Case_Sub_Status__c = 'In Progress',
            RecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, 'Broker_Registration')
        );
        insert cs;

        // Create Document__c for Contact
        Document__c docCon = new Document__c(
            FileName__c = 'ContactDoc.pdf',
            Contact__c = con.Id,
            ContentDocumentId__c = '069000000000001AAA',
            Content_Version_Id__c = '068000000000001AAA'
        );
        insert docCon;

        // Create Document__c for Case
        Document__c docCase = new Document__c(
            FileName__c = 'CaseDoc.pdf',
            Case__c = cs.Id,
            ContentDocumentId__c = '069000000000002AAA',
            Content_Version_Id__c = '068000000000002AAA'
        );
        insert docCase;
    }

    @isTest
    static void testHandleGetTeamMember_Success() {
        Account acc = [SELECT Id FROM Account WHERE Name='Test Broker Account' LIMIT 1];

        // Set RestContext for the handler to write response
        RestRequest req = new RestRequest();
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        BAPPGetTeamMembersHandler.handleGetTeamMember(acc.Id);
        Test.stopTest();
    }

    @isTest
    static void testHandleGetTeamMember_MissingAccountId() {
        RestRequest req = new RestRequest();
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        BAPPGetTeamMembersHandler.handleGetTeamMember(null);
        Test.stopTest();
    }

    @isTest
    static void testHandleGetTeamMember_NoContactsOrCases() {
        // Create an account without contacts/cases
        Account accEmpty = new Account(Name = 'Empty Account');
        insert accEmpty;

        RestRequest req = new RestRequest();
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        BAPPGetTeamMembersHandler.handleGetTeamMember(accEmpty.Id);
        Test.stopTest();
    }
    
    private static Contact createContact(Account acc, String role, Boolean isActive, String lastName) {
        Contact con = new Contact(
            LastName = lastName,
            AccountId = acc.Id,
            BrokerContactRole__c = role,
            IsActive__c = isActive,
            Email = 'Test@email.com',
            RecordTypeId = Utility.getRecordTypeIdByDevName(Contact.SObjectType, 'Broker')
        );
        insert con;
        return con;
    }
}