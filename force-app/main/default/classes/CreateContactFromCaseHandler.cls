public with sharing class CreateContactFromCaseHandler {

    // Input wrapper for Flow
    public class Request {
        @InvocableVariable(required=true label='Case Id')
        public Id caseId;
    }

    // Output wrapper for Flow
    public class Response {
        @InvocableVariable(label='Created Contact Id')
        public Id contactId;
    }

    @InvocableMethod(label='Create Contact from Case')
    public static List<Response> createContacts(List<Request> requests) {
        system.debug('Invocable Create Contact Method Called');
        //List<Id> caseIds = new List<Id>(); old
        Set<Id> caseIds = new Set<Id>();
        for (Request req : requests) {
            caseIds.add(req.caseId);
        }

        // Query required case fields
        Map<Id, Case> caseMap = CaseService.getInstance().getCaseMapByIds(caseIds);

        List<Contact> contactsToInsert = new List<Contact>();
        List<Response> results = new List<Response>();

        for (Request req : requests) {
            Case cs = caseMap.get(req.caseId);
            if (cs == null) continue;

            Contact con = new Contact();
            con.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Broker').getRecordTypeId();
            con.IsActive__c = true;
            con.BrokerContactRole__c = cs.BrokerContactRole__c;
            con.Title = cs.Title__c;
            con.FirstName = cs.First_Name__c;
            con.MiddleName = cs.MiddleName__c;
            con.LastName = cs.Last_Name__c;
            con.PrimaryMobilePhone__c = cs.PhoneNumber__c;
            con.Email = cs.Email_Address__c;
            con.NationalIdNumber__c = cs.NationalID__c;
            con.NationalIdExpiryDate__c = cs.NationalIDExpiryDate__c;
            con.PassportNumber__c = cs.PassportNumber__c;
            con.PassportExpiryDate__c = cs.PassportExpiryDate__c;
            con.Birthdate = cs.DateOfBirth__c;
            con.CountryOfResidence__c = cs.Country__c;
            con.TypeofEstablishment__c = cs.TypeofEstablishment__c;
            con.CaseId__c = cs.Id;
            con.BRN_RERA_Number__c = cs.BRN_RERA_Number__c;
            con.BRN_RERA_Expiry_Date__c = cs.BRN_RERA_Expiry_Date__c;
            con.AccountId = cs.AccountId;
            con.ShareHoldingPercentage__c = cs.ShareHoldingPercentage__c;
            con.Designation__c = cs.Designation__c;
            con.PrimaryMobileCountryCode__c = cs.Mobile_Country_Code__c;
            contactsToInsert.add(con);
        }

        ContactService.getInstance().insertContacts(contactsToInsert);

        for (Contact c : contactsToInsert) {
            Response res = new Response();
            res.contactId = c.Id;
            results.add(res);
        }

        return results;
    }
}