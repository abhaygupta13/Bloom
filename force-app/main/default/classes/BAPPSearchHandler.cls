/*
* @Author        : Rushikesh Jadhav
* @CreatedDate   : 08th Sep 2025
* @Description   : Handles searching of Lead records via REST API.
*                  Performs parameter validation, deduplication logic,
*                  and returns a structured JSON response with lead details.
*/
/*****************************************************************************************************
* Version       Author        Date             Comment                                                                       
* 1.0           Rushikesh     08-SEP-2025      Initial draft to handle lead search functionality including
*                                             deduplication and structured response generation.
*****************************************************************************************************/
public class BAPPSearchHandler {

    // ---------- Wrapper Classes ----------
    public class GetLeadsResponse {
        public String status;
        public String searchKey;
        public List<LeadRecord> leads;
    }

    public class LeadRecord {
        public String leadId;
        public String leadNumber;
        public String title;
        public String firstName;
        public String middleName;
        public String lastName;
        public String name;
        public String email;
        public String phoneNumber;
        public String brokerAgency;
        public String brokerAgent;
        public String organizationName;
        public String project;
        public String unitType;
        public String numberOfBedrooms;
        public String leadStatus;
        public String salesManagerId;
        public String salesManagerName;
        public String salesManagerEmail;
        public String profileName;
        public String brokerAgentName;
        public Boolean isConverted;
        public String convertedOpportunityId;
        public String country;
        public String state;
        public String city;
        public String street;
        public String countryCode;
        public String postalCode;
        public String preferredLanguage;
        public String passportNumber;
        public Date passportExpiryDate;
        public String nationalId;
        public Date nationalIdExpiryDate;
        public String preferredCommunication;
        public Datetime createdDate;
        public Datetime lastModifiedDate;
        public String leadType;
    }

    // ----------Handler Method----------
    public static void handleGetLeads(String searchKey, String accountId, String contactId, Boolean duplicateSearch) {
    try {
        // Collect validation errors first
        List<Map<String, String>> errors = validateGetLeadsParams(searchKey, accountId, contactId, duplicateSearch);
        if (!errors.isEmpty()) {
            sendErrorResponse(Label.BAPP_ValidationFailed, errors, 400);
            return;
        }
        // ---- Check record existence ----
        if (!Utility.recordExists(accountId)) {
            sendErrorResponse(Label.BAPP_InvalidAccountId, null, 404);
            return;
        }
        if (!Utility.recordExists(contactId)) {
            sendErrorResponse(Label.BAPP_InvalidContactId, null, 404);
            return;
        }

        // ---- Check Contact belongs to Account ----
        Contact con = ContactService.getInstance().getContactById(contactId);
        if (con.AccountId != accountId) {
            sendErrorResponse(Label.BAPP_InvalidAccountContactRelation, null, 400);
            return;
        }

            //Integer limitSize = duplicateSearch ? 5 : 100;
            Integer limitSize = Integer.valueOf(Label.BAPP_DefaultLeadFetchLimit); // default
            if (String.isBlank(searchKey)) {
                duplicateSearch = true;   // force deduplication
                limitSize = Integer.valueOf(Label.BAPP_DuplicateSearchFetchLimit);            // only last 5 modified
            }  
            //Check admin role logic
        Boolean hasAccessRole = false;
        Set<String> accessRoles = new Set<String>{'admin','superadmin','ceo','partner','owner','authorizedsignatoryofficer'};

        Contact c = ContactService.getInstance().getContactById(contactId);
        
        if (c.BrokerContactRole__c != null) {
            for (String role : c.BrokerContactRole__c.split(';')) {
                if (accessRoles.contains(role.trim().toLowerCase())) {
                    hasAccessRole = true;
                    break;
                }
            }
        }
           
            List<Lead> leads = LeadService.getInstance().getLeadsBySearch(searchKey, accountId, contactId, limitSize,duplicateSearch);
            if (leads.isEmpty()) {
                sendStandardResponse(new Map<String, Object>{
                    'leads' => new List<Object>(),
                    'searchKey' => searchKey,
                    'message' => Label.BAPP_NoResultsFound,
                    'status' => 'success'
                }, 200);
                return;
            }
            GetLeadsResponse responseWrapper = buildResponse(leads, duplicateSearch, searchKey, hasAccessRole);
            sendStandardResponse(JSON.deserializeUntyped(serializeGetLeadsResponse(responseWrapper)), 200);
        } catch (Exception ex) {
            sendErrorResponse('An unexpected error occurred: ' + ex.getMessage(), null, 500);
        }
    }

    // ====== VALIDATION ======
    private static List<Map<String, String>> validateGetLeadsParams(String searchKey,String accountId,String contactId,Boolean duplicateSearch) {
        List<Map<String, String>> errors = new List<Map<String, String>>();
    
        checkRequired(accountId, 'accountId', Label.BAPP_AccountIdRequired, errors);
        checkRequired(contactId, 'contactId', Label.BAPP_ContactIdRequired, errors);
        
        if (duplicateSearch == null) {
            errors.add(buildError('duplicateSearch', Label.BAPP_DuplicateSearchRequired));
        } else if (duplicateSearch == true && String.isNotBlank(searchKey) ) {
            // If dedup search is true, search key must be alphabetic only
            if (String.isBlank(searchKey) || !Pattern.matches('^[A-Za-z ]+$', searchKey)) {
                errors.add(buildError('searchKey', Label.BAPP_SearchLettersOnly));
            }
        } else if (duplicateSearch == false) {
            // If dedup search is false, search key is mandatory (any format allowed)
            if (String.isBlank(searchKey)) {
                errors.add(buildError('searchKey', Label.BAPP_SearchKeyRequired));
            }
        }
        
        return errors;
    }
    
    private static void checkRequired(String val, String field, String msg, List<Map<String, String>> errors) {
        if (String.isBlank(val)) {
            errors.add(buildError(field, msg));
        }
    }
    
    private static Map<String, String> buildError(String field, String msg) {
        return new Map<String, String>{ 'field' => field, 'message' => msg };
    }
    
    // ---------- Build Response (dedup/non-dedup) ----------
    private static GetLeadsResponse buildResponse(List<Lead> leads, Boolean dedup, String searchKey, Boolean hasAccessRole) {
        GetLeadsResponse resp = new GetLeadsResponse();
        resp.leads = new List<LeadRecord>();
        resp.status = 'success';
        resp.searchKey = searchKey;
        

        if (dedup) {
            Map<String, LeadRecord> uniqueLeads = new Map<String, LeadRecord>();
            for (Lead l : leads) {
                String key = (l.Name != null ? l.Name.trim() : '') + '|' +
                             (l.Email != null ? l.Email.trim().toLowerCase() : '') + '|' +
                             (l.MobilePhoneNumber__c != null ? l.MobilePhoneNumber__c.replaceAll('[^0-9]', '') : '');
                if (!uniqueLeads.containsKey(key)) {
                    uniqueLeads.put(key, populateLeadRecord(l , hasAccessRole));
                }
            }
            resp.leads.addAll(uniqueLeads.values());
        } else {
            for (Lead l : leads) {
                resp.leads.add(populateLeadRecord(l , hasAccessRole));
            }
        }
        return resp;
    }

    // ---------- Mapping LeadRecord ----------
    private static LeadRecord populateLeadRecord(Lead l, Boolean hasAccessRole) {
        LeadRecord rec = new LeadRecord();
        // ---- Owner fields with profile check ----
        if (l.Owner != null && l.Owner.Profile != null) {
            rec.salesManagerId = l.OwnerId;
            rec.salesManagerName = l.Owner.Name;
            rec.profileName = l.Owner.Profile.Name;
            rec.salesManagerEmail = l.Owner.Email;
        } else {
            rec.salesManagerId = null;
            rec.salesManagerName = null;
            rec.profileName = null;
            rec.salesManagerEmail = null;
        }
        rec.leadId = l.Id;
        rec.leadNumber = l.LeadNumber__c;
        rec.title = l.Salutation;
        rec.firstName = l.FirstName;
        rec.middleName = l.MiddleName;
        rec.lastName = l.LastName;
        rec.name = l.Name;
        rec.email = l.Email;
        rec.phoneNumber = l.MobilePhoneNumber__c;
        rec.brokerAgency = l.BrokerAgency__c;
        if (hasAccessRole) {
            rec.brokerAgent = l.BrokerAgent__c;
            rec.brokerAgentName = l.Broker_Agent_Name__c;
        } else {
            rec.brokerAgent = null;
            rec.brokerAgentName = null;
        }
        rec.organizationName = l.Company;
        rec.project = l.Project__c;
        rec.unitType = l.UnitType__c;
        rec.numberOfBedrooms = l.NumberOfBedrooms__c;
        rec.leadStatus = l.Status;
        
        rec.isConverted = l.IsConverted;
        rec.convertedOpportunityId = l.ConvertedOpportunityId;
        rec.country = l.Country;
        rec.countryCode = l.MobileCountryCode__c;
        rec.state = l.State;
        rec.city = l.City;
        rec.street =l.Street;
        rec.postalCode = l.PostalCode;
        rec.preferredLanguage = l.LanguagePreference__c;
        rec.passportNumber = l.Passport_Number__c;
        rec.passportExpiryDate = l.PassportExpiryDate__c;
        rec.nationalId = l.NationalID__c;
        rec.nationalIdExpiryDate = l.NationalIDExpiryDate__c;
        rec.preferredCommunication = l.PreferredCommunicationMethodology__c;
        rec.createdDate = l.CreatedDate;
        rec.lastModifiedDate = l.LastModifiedDate;
        rec.leadType = (l.RecordType != null) ? l.RecordType.DeveloperName : null;
        
        return rec;
    }

    // ---------- JSON Serialization ----------
    private static String serializeGetLeadsResponse(GetLeadsResponse wrapper) {
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
        writeStringOrNull(gen, 'status', wrapper.status);
        writeStringOrNull(gen, 'searchKey', wrapper.searchKey);
        gen.writeFieldName('leads');
        gen.writeStartArray();
        for (LeadRecord l : wrapper.leads) {
            gen.writeStartObject();
            writeStringOrNull(gen, 'leadId', l.leadId);
            writeStringOrNull(gen, 'leadNumber', l.leadNumber);
            writeStringOrNull(gen, 'title', l.title);
            writeStringOrNull(gen, 'firstName', l.firstName);
            writeStringOrNull(gen, 'middleName', l.middleName);
            writeStringOrNull(gen, 'lastName', l.lastName);
            writeStringOrNull(gen, 'name', l.name);
            writeStringOrNull(gen, 'email', l.email);
            writeStringOrNull(gen, 'phoneNumber', l.phoneNumber);
            writeStringOrNull(gen, 'brokerAgency', l.brokerAgency);
            writeStringOrNull(gen, 'brokerAgent', l.brokerAgent);
            writeStringOrNull(gen, 'brokerAgentName', l.brokerAgentName);
            writeStringOrNull(gen, 'organizationName', l.organizationName);
            writeStringOrNull(gen, 'project', l.project);
            writeStringOrNull(gen, 'unitType', l.unitType);
            writeStringOrNull(gen, 'numberOfBedrooms', l.numberOfBedrooms);
            writeStringOrNull(gen, 'leadStatus', l.leadStatus);
            writeStringOrNull(gen, 'salesManagerId', l.salesManagerId);
            writeStringOrNull(gen, 'salesManagerName', l.salesManagerName);
            writeStringOrNull(gen, 'salesManagerEmail', l.salesManagerEmail);
            writeStringOrNull(gen, 'profileName', l.profileName);
            if (l.isConverted != null) gen.writeBooleanField('isConverted', l.isConverted); else gen.writeNullField('isConverted');
            writeStringOrNull(gen, 'convertedOpportunityId', l.convertedOpportunityId);
            writeStringOrNull(gen, 'country', l.country);
            writeStringOrNull(gen, 'countryCode', l.countryCode);
            writeStringOrNull(gen, 'state', l.state);
            writeStringOrNull(gen, 'city', l.city);
            writeStringOrNull(gen, 'street', l.street);
            writeStringOrNull(gen, 'postalCode', l.postalCode);
            writeStringOrNull(gen, 'preferredLanguage', l.preferredLanguage);
            writeStringOrNull(gen, 'passportNumber', l.passportNumber);
            if (l.passportExpiryDate != null) gen.writeStringField('passportExpiryDate', String.valueOf(l.passportExpiryDate)); else gen.writeNullField('passportExpiryDate');
            writeStringOrNull(gen, 'nationalId', l.nationalId);
            if (l.nationalIdExpiryDate != null) gen.writeStringField('nationalIdExpiryDate', String.valueOf(l.nationalIdExpiryDate)); else gen.writeNullField('nationalIdExpiryDate');
            writeStringOrNull(gen, 'preferredCommunication', l.preferredCommunication);
            if (l.createdDate != null) gen.writeStringField('createdDate', String.valueOf(l.createdDate)); else gen.writeNullField('createdDate');
            if (l.lastModifiedDate != null) gen.writeStringField('lastModifiedDate', String.valueOf(l.lastModifiedDate)); else gen.writeNullField('lastModifiedDate');
            writeStringOrNull(gen, 'leadType', l.leadType);
            gen.writeEndObject();
        }
        gen.writeEndArray();
        gen.writeEndObject();
        return gen.getAsString();
    }

    private static void writeStringOrNull(JSONGenerator gen, String fieldName, String value) {
        if (value != null) gen.writeStringField(fieldName, value);
        else gen.writeNullField(fieldName);
    }
    // ----- Success Response ------
    private static void sendStandardResponse(Object body, Integer statusCode) {
        RestContext.response.statusCode = statusCode;
        RestContext.response.addHeader('Content-Type', 'application/json;charset=UTF-8');
        RestContext.response.responseBody = Blob.valueOf(JSON.serializePretty(body));
    }

    private static void sendErrorResponse(String message, List<Map<String, String>> errors, Integer statusCode) {
        Map<String, Object> resp = new Map<String, Object>{
            'status'  => 'error',
            'message' => message
        };
        if (errors != null) {
            resp.put('errors', errors);
        }
        sendStandardResponse(resp, statusCode);
    }
}