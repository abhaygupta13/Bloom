/*
* @Author        : Rushikesh Jadhav
* @CreatedDate   : 08th Sep 2025
* @Description   : Handles Get Lead records via REST API.                 
*/
/*****************************************************************************************************
* Version       Author        Date             Comment                                                                       
* 1.0           Rushikesh     08-SEP-2025      Initial draft to handle Get lead functionality
*                                            
*****************************************************************************************************/
public class BAPPGetLeadsHandler {
    
    private static final List<String> DEFAULT_STATUSES = new List<String>{ 'New', 'In Progress', 'Closed','Converted' };
        
        // ===== Request =====
        public class LeadFilterRequest {
            public String accountId;
            public String contactId;
            public String scenario;
            public String leadType; // OrganizationLead or IndividualLead
            public FilterCriteria filterCriteria;
        }
    
    public class FilterCriteria {
        public String status;           // e.g., "New;In Progress;Closed"
        public String salesManagerId;
        public Date updatedOnFrom;
        public Date updatedOnTo;
    }
    
    // ===== Response DTO =====
    public class GetLeadsResponse {
        public String status;
        public List<LeadRecord> leads;
    }
    
    public class LeadStatusRequest {
        public String accountId;
        public String contactId;
        public Date updatedOnFrom;
        public Date updatedOnTo;
    }
    
    public class LeadStatusResponse {
        public String accountId;
        public String contactId;
        public Map<String, Integer> status;
        public String message { get; set; } 
    }
    
    public class LeadRecord {
        public String leadId;
        public String leadNumber;
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
        public String profileName;
        public String salesManagerEmail;
        public Boolean isConverted;
        public String convertedOpportunityId;
        public String country;
        public String countryCode; 
        public String state;
        public String city;
        public String street;
        public String postalCode;
        public String preferredLanguage;
        public String passportNumber;
        public Date   passportExpiryDate;
        public String nationalId;
        public Date   nationalIdExpiryDate;
        public String preferredCommunication;
        public Datetime createdDate;
        public Datetime lastModifiedDate;
        public String leadType;
        public String brokerAgentName;
        public String brokerAgentId;
        public String title;
        public String unitNumberId; // Added by Ashish Rana
        public String unitNumber; // Added by Ashish Rana

    }
    
    public class BrokerSummaryResponse {
        public Integer LeadCreated = 0;
        public Decimal ConversionRate = 0;
        public Integer SalesOrder = 0;
        public Decimal TotalCommission = 0;
        public Integer NewLead = 0;
        public Integer InProgressLead = 0;
        public Integer ClosedLead = 0;
        public Integer LeadConverted = 0;
        public String message = Label.BAPP_BrokerSummaryFetchSuccess;
    }
    
    public class BrokerContactWrapper {
        public String BrokerAgentName;
        public String BrokerContactId;
        public BrokerSummaryResponse BrokerSummary;
    }
    
    // ===== Entry Point =====
    public static void handleLeadFilters() {
        try {
            String body = RestContext.request.requestBody == null ? null : RestContext.request.requestBody.toString();
            LeadFilterRequest input = (LeadFilterRequest) JSON.deserialize(body, LeadFilterRequest.class);
            
            if (input == null || String.isBlank(input.accountId) || String.isBlank(input.contactId)) {
                returnError(Label.BAPP_AccountAndContactRequired, 400);
                return;
            }
            Contact con = validateAccountAndContact(input.accountId, input.contactId);
            if (con == null) return; // error already sent
            Boolean hasAccessRole = hasAdminAccess(con.BrokerContactRole__c);
            
            // Normalize type(s) to RecordType DeveloperName(s)
            List<String> recordTypeDevNames = new List<String>();
            if (String.isNotBlank(input.leadType)) {
                for (String t : input.leadType.split(';')) {
                    String normalized = t.trim().toLowerCase();
                    if (normalized == 'organizationlead' || normalized == 'organization') {
                        recordTypeDevNames.add('OrganizationLead');
                    } else if (normalized == 'individuallead' || normalized == 'individual') {
                        recordTypeDevNames.add('IndividualLead');
                    }
                }
            }
            // Ensure updatedOnFrom/updatedOnTo are used together
            if (input.filterCriteria != null) {
                if ((input.filterCriteria.updatedOnFrom != null && input.filterCriteria.updatedOnTo == null) ||
                    (input.filterCriteria.updatedOnTo != null && input.filterCriteria.updatedOnFrom == null)) {
                        returnError(Label.BAPP_FromAndToDatesRequired, 400);
                        return;
                    }
            }
            // === Validate updatedOnFrom/To are not future dates and within 3 months ===
            if (input.filterCriteria != null && input.filterCriteria.updatedOnFrom != null && input.filterCriteria.updatedOnTo != null) {
                Date today = Date.today();
                
                if (input.filterCriteria.updatedOnFrom > today) {
                    returnError(Label.BAPP_FromDateCannotFuture, 400);
                    return;
                }
                
                if (input.filterCriteria.updatedOnTo > today) {
                    returnError(Label.BAPP_ToDateCannotFuture, 400);
                    return;
                }
               
                Integer daysDiff = input.filterCriteria.updatedOnFrom.daysBetween(input.filterCriteria.updatedOnTo);
                if (daysDiff > 90) {
                    returnError(Label.BAPP_90DaysDateRangeExceed, 400);
                    return;
                }
            }
            
            // === Scenario Validation ===
            if (String.isBlank(input.scenario)) {
                returnError(Label.BAPP_ScenarioRequired, 400);
                return;
            }
            
            String scenarioNormalized = input.scenario.trim().toUpperCase();
            if (scenarioNormalized == 'ALL') {
                if (input.filterCriteria != null) {
                    returnError(Label.BAPP_FilterCriteriaMustBeNullForAll, 400);
                    return;
                }
            } else if (scenarioNormalized == 'FILTER') {
                if (input.filterCriteria == null) {
                    returnError(Label.BAPP_FilterCriteriaRequiredForFilter, 400);
                    return;
                }
                // Check at least one field has value
                BAPPGetLeadsHandler.FilterCriteria fc = input.filterCriteria;
                Boolean hasValue = 
                    (String.isNotBlank(fc.status)) ||
                    (String.isNotBlank(fc.salesManagerId)) ||
                    (fc.updatedOnFrom != null) ||
                    (fc.updatedOnTo != null);
                
                if (!hasValue) {
                    returnError(Label.BAPP_FilterCriteriaValueRequired, 400);
                    return;
                }
            } else {
                returnError(Label.BAPP_InvalidScenario, 400);
                return;
            }
            // Default status if none provided
            if (input.filterCriteria == null) {
                input.filterCriteria = new FilterCriteria();
            }
            
            if (String.isBlank(input.filterCriteria.status)) {
                input.filterCriteria.status = String.join(DEFAULT_STATUSES, ';'); // Stored as "New;In Progress;Closed"
            }
            
            // Call LeadService with filters
            List<Lead> leads = LeadService.getInstance().getLeadsByFilters(input.accountId, input.contactId, recordTypeDevNames, input.filterCriteria,hasAccessRole);

            // Transform to response
            List<LeadRecord> result = new List<LeadRecord>();
            for (Lead l : leads) {
                result.add(toRecord(l,hasAccessRole));
            }
            
            GetLeadsResponse resp = new GetLeadsResponse();
            resp.status = 'success';
            resp.leads  = result;
            
            RestContext.response.statusCode = 200;
            RestContext.response.addHeader('Content-Type', 'application/json;charset=UTF-8');
            RestContext.response.responseBody = Blob.valueOf(serializeGetLeadsResponse(resp));
            
        } catch (Exception e) {
            returnError('Unexpected error: ' + e.getMessage(), 500);
        }
    }
    
    // ===== Mapper =====
    private static LeadRecord toRecord(Lead l, Boolean hasAccessRole ) {
        LeadRecord r = new LeadRecord();
        r.leadId = l.Id;
        r.title = l.Salutation;
        r.leadNumber = l.LeadNumber__c;
        r.firstName = l.FirstName;
        r.middleName = l.MiddleName;
        r.lastName = l.LastName;
        r.name = l.Name;
        r.email = l.Email;
        r.phoneNumber = l.MobilePhoneNumber__c;
        r.brokerAgency = l.BrokerAgency__c;
        r.organizationName = l.Company;
        r.project = l.Project__c;
        r.unitType = l.UnitType__c;
        r.numberOfBedrooms = l.NumberOfBedrooms__c;
        r.leadStatus = l.Status;
        system.debug('l.Owner>>>>'+l.Owner);
        system.debug('l.Owner.getSObjectType().getDescribe().getName()>>>>'+l.Owner.getSObjectType().getDescribe().getName());
        if (l.Owner != null && String.valueOf(l.Owner.Name) == 'Broker Unassigned Leads') {
            r.salesManagerId = null;
            r.salesManagerName = null;
            r.profileName = null;
            r.salesManagerEmail = null;
        } else if (l.Owner != null && l.Owner.getSObjectType().getDescribe().getName() == 'User') {
            r.salesManagerId = l.OwnerId;
            r.salesManagerName = l.Owner.Name;
            r.profileName = ((User)l.Owner).Profile.Name;
            r.salesManagerEmail = l.owner.Email;
        } else {
            r.salesManagerId = l.OwnerId;
            r.salesManagerName = l.Owner.Name;
            r.profileName = null;
            r.salesManagerEmail = l.Owner.Email;
        }
        r.isConverted = l.IsConverted;
        r.convertedOpportunityId = l.ConvertedOpportunityId;
        r.country = l.Country;
        r.countryCode = l.MobileCountryCode__c ;
        r.state = l.State;
        r.city = l.City;
        r.street = l.Street;
        r.postalCode = l.PostalCode;
        r.preferredLanguage = l.LanguagePreference__c;
        r.passportNumber = l.Passport_Number__c;
        r.passportExpiryDate = l.PassportExpiryDate__c;
        r.nationalId = l.NationalID__c;
        r.nationalIdExpiryDate = l.NationalIDExpiryDate__c;
        r.preferredCommunication = l.PreferredCommunicationMethodology__c;
        r.createdDate = l.CreatedDate;
        r.lastModifiedDate = l.LastModifiedDate;
        r.leadType = (l.RecordType != null) ? l.RecordType.DeveloperName : null;
        // Only include brokerAgentName and brokerAgentId if user has privileged
        if (hasAccessRole) {
            r.brokerAgentName = l.Broker_Agent_Name__c;
            r.brokerAgentId = l.BrokerAgent__c;
        }
        r.unitNumberId = l.Unit__c;  // Added by Ashish Rana
        r.unitNumber = l.Unit__r.Name;  // Added by Ashish Rana
        return r;
    }
    
    // ===== JSON Serialization =====
    private static String serializeGetLeadsResponse(GetLeadsResponse wrapper) {
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
        writeStringOrNull(gen, 'status', wrapper.status);
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
            writeStringOrNull(gen, 'organizationName', l.organizationName);
            writeStringOrNull(gen, 'project', l.project);
            writeStringOrNull(gen, 'unitType', l.unitType);
            writeStringOrNull(gen, 'numberOfBedrooms', l.numberOfBedrooms);
            writeStringOrNull(gen, 'leadStatus', l.leadStatus);
            writeStringOrNull(gen, 'salesManagerId', l.salesManagerId);
            writeStringOrNull(gen, 'salesManagerName', l.salesManagerName);
            writeStringOrNull(gen, 'salesManagerEmail', l.salesManagerEmail);
            writeStringOrNull(gen, 'profileName', l.profileName);
            writeBooleanOrNull(gen, 'isConverted', l.isConverted);
            writeStringOrNull(gen, 'convertedOpportunityId', l.convertedOpportunityId);
            writeStringOrNull(gen, 'country', l.country);
            writeStringOrNull(gen, 'countryCode', l.countryCode);
            writeStringOrNull(gen, 'state', l.state);
            writeStringOrNull(gen, 'city', l.city);
            writeStringOrNull(gen, 'street', l.street);
            writeStringOrNull(gen, 'postalCode', l.postalCode);
            writeStringOrNull(gen, 'preferredLanguage', l.preferredLanguage);
            writeStringOrNull(gen, 'passportNumber', l.passportNumber);
            writeDateOrNull(gen, 'passportExpiryDate', l.passportExpiryDate);
            writeStringOrNull(gen, 'nationalId', l.nationalId);
            writeDateOrNull(gen, 'nationalIdExpiryDate', l.nationalIdExpiryDate);
            writeStringOrNull(gen, 'preferredCommunication', l.preferredCommunication);
            writeDatetimeOrNull(gen, 'createdDate', l.createdDate);
            writeDatetimeOrNull(gen, 'lastModifiedDate', l.lastModifiedDate);
            writeStringOrNull(gen, 'leadType', l.leadType);
            writeStringOrNull(gen, 'brokerAgentName', l.brokerAgentName);
            writeStringOrNull(gen, 'brokerAgentId', l.brokerAgentId);
            writeStringOrNull(gen, 'unitNumberId', l.unitNumberId); // Added by Ashish Rana
            writeStringOrNull(gen, 'unitNumber', l.unitNumber); // Added by Ashish Rana
            gen.writeEndObject();
        }
        gen.writeEndArray();
        gen.writeEndObject();
        return gen.getAsString();
    }
    
    // ===== JSON Helper Methods =====
    private static void writeStringOrNull(JSONGenerator gen, String field, String val) {
        if (val != null) gen.writeStringField(field, val); else gen.writeNullField(field);
    }
    
    private static void writeBooleanOrNull(JSONGenerator gen, String field, Boolean val) {
        if (val != null) gen.writeBooleanField(field, val); else gen.writeNullField(field);
    }
    
    private static void writeDateOrNull(JSONGenerator gen, String field, Date val) {
        if (val != null) gen.writeStringField(field, String.valueOf(val)); else gen.writeNullField(field);
    }
    
    private static void writeDatetimeOrNull(JSONGenerator gen, String field, Datetime val) {
        if (val != null) gen.writeStringField(field, String.valueOf(val)); else gen.writeNullField(field);
    }
    
    
    // === Get Lead Status Counts ===
    public static void getLeadStatusCounts() {
        try {
            // === Parse request body ===
            String body = RestContext.request.requestBody == null ? null : RestContext.request.requestBody.toString();
            LeadStatusRequest input = String.isNotBlank(body) ? (LeadStatusRequest) JSON.deserialize(body, LeadStatusRequest.class) : new LeadStatusRequest();
            
            Contact c = validateAccountAndContact(input.accountId, input.contactId);
            if (c == null) return; // error already returned inside helper
            
            
            // === Validate updatedOn date range rules ===
            if (!validateUpdatedOnDates(input.updatedOnFrom, input.updatedOnTo)) {
                return;
            }
            
            // === Safe Role Access ===
            String roles = c.BrokerContactRole__c;            
            Boolean isAdmin = hasAdminAccess(roles);
            Boolean isAgent = false;
            
            // Guard against null or blank roles
            if (String.isNotBlank(roles)) {
                for (String r : roles.split(';')) {
                    if (String.isBlank(r)) continue;
                    if (r.trim().equalsIgnoreCase('agent')) {
                        isAgent = true;
                        break;
                    }
                }
            }
            
            if (!isAdmin && !isAgent) {
                returnError(Label.BAPP_UnauthorizedRole, 403);
                return;
            }

            // === Fetch leads based on filters ===
            List<Lead> leads = LeadService.getInstance().getLeadsForStatusCount(input.accountId, input.contactId, input.updatedOnFrom, input.updatedOnTo, isAdmin, isAgent);
            
            // === Handle no-lead case ===
            if (leads == null || leads.isEmpty()) {
                LeadStatusResponse resp = new LeadStatusResponse();
                resp.accountId = input.accountId;
                resp.contactId = input.contactId;
                resp.message = 'No leads found.';
                
                RestContext.response.statusCode = 200;
                RestContext.response.addHeader('Content-Type', 'application/json;charset=UTF-8');
                RestContext.response.responseBody = Blob.valueOf(JSON.serializePretty(resp));
                return;
            }
            
            // === Count leads by status ===
            Map<String, Integer> counts = new Map<String, Integer>();
            
            // Pre-populate with required statuses at 0
            List<String> requiredStatuses = new List<String>{ 'New', 'In Progress', 'Converted', 'Closed' };
                for (String st : requiredStatuses) {
                    counts.put(st, 0);
                }
            
            // Count actual leads
            for (Lead l : leads) {
                String st;
                if (l.IsConverted) {
                    st = 'Converted';
                } else {
                    st = String.isBlank(l.Status) ? 'Unknown' : l.Status;
                }
                
                if (counts.containsKey(st)) {
                    counts.put(st, counts.get(st) + 1);
                }
            }
            
            // === Build success response ===
            LeadStatusResponse resp = new LeadStatusResponse();
            resp.accountId = input.accountId;
            resp.contactId = input.contactId;
            resp.status = counts;
            resp.message = Label.BAPP_LeadStatusCountsFetchSuccess;
            
            RestContext.response.statusCode = 200;
            RestContext.response.addHeader('Content-Type', 'application/json;charset=UTF-8');
            RestContext.response.responseBody = Blob.valueOf(JSON.serializePretty(resp));
            
        } catch (Exception e) {
            // === Handle unexpected errors ===
            returnError('Unexpected error: ' + e.getMessage(), 500);
        }
    }
    
    // === Broker summary counts ===
    public static void getBrokerSummaryCounts() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json;charset=UTF-8');
        
        try {
            if (req.requestBody == null || String.isBlank(req.requestBody.toString())) {
                returnError(Label.BAPP_MissingRequestBody, 400);
                return;
            }
            
            Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(req.requestBody.toString());
            String accountId = (String) body.get('accountId');
            String contactId = (String) body.get('contactId');
            Date updatedOnFrom = body.containsKey('updatedOnFrom') ? Date.valueOf((String) body.get('updatedOnFrom')) : null;
            Date updatedOnTo   = body.containsKey('updatedOnTo') ? Date.valueOf((String) body.get('updatedOnTo')) : null;
            
            Contact c = validateAccountAndContact(accountId, contactId);
            if (c == null) return;
            
            // Role check
            if (!hasAdminAccess(c.BrokerContactRole__c)) {
                returnError(Label.BAPP_AccessDeniedRole, 403);
                return;
            }
            
            if (!validateUpdatedOnDates(updatedOnFrom, updatedOnTo)) {
                return;
            }
            
            // Fetch active contacts
            List<Contact> contacts = ContactService.getInstance().getActiveContactsByAccount(accountId);
            
            if (contacts.isEmpty()) {
                res.statusCode = 404;
                res.responseBody = Blob.valueOf(JSON.serializePretty(
                    new Map<String, Object>{
                        'status' => 'error',
                            'message' => Label.BAPP_NoActiveAgentForAgency,
                            'data' => null
                            }
                ));
                return;
            }
            
            Set<Id> contactIds = new Set<Id>();
            for (Contact cont : contacts) {
                contactIds.add(cont.Id);
            }
            // Bulk fetch related data
            Map<Id, Map<String, Object>> leadSummaryMap = LeadService.getLeadSummaryData(contactIds, updatedOnFrom, updatedOnTo);
            Map<Id, Integer> salesOrderMap = SalesOrderService.getSalesOrderCounts(accountId, contactIds, updatedOnFrom, updatedOnTo);
            Map<Id, Decimal> commissionMap = BrokerCommissionService.getTotalCommissions(accountId, contactIds, updatedOnFrom, updatedOnTo);
            
            List<Object> responseData = new List<Object>();
            
            for (Contact cont : contacts) {
                BrokerSummaryResponse summary = new BrokerSummaryResponse();
                
                Map<String, Object> leadData = leadSummaryMap.get(cont.Id);
                if (leadData != null) {
                    summary.LeadCreated = leadData.get('LeadCreated') != null ? (Integer) leadData.get('LeadCreated') : 0;
                    summary.LeadConverted = leadData.get('LeadConverted') != null ? (Integer) leadData.get('LeadConverted') : 0;
                    
                    Map<String, Integer> statusCounts = (Map<String, Integer>) leadData.get('StatusCounts');
                    if (statusCounts != null) {
                        summary.NewLead = statusCounts.get('New') != null ? statusCounts.get('New') : 0;
                        summary.InProgressLead = statusCounts.get('In Progress') != null ? statusCounts.get('In Progress') : 0;
                        summary.ClosedLead = statusCounts.get('Closed') != null ? statusCounts.get('Closed') : 0;
                    }
                    
                    summary.ConversionRate = summary.LeadCreated > 0
                        ? ((Decimal.valueOf(summary.LeadConverted) / summary.LeadCreated) * 100).setScale(2)
                        : 0;
                }
                
                summary.SalesOrder = salesOrderMap.containsKey(cont.Id) && salesOrderMap.get(cont.Id) != null
                    ? salesOrderMap.get(cont.Id)
                    : 0;
                
                summary.TotalCommission = commissionMap.containsKey(cont.Id) && commissionMap.get(cont.Id) != null
                    ? commissionMap.get(cont.Id)
                    : 0;
                
                responseData.add(new Map<String, Object>{
                    'BrokerAgentName' => cont.Name,
                        'BrokerContactId' => cont.Id,
                        'BrokerSummary'   => summary
                        });
            }
            
            RestContext.response.statusCode = 200;
            RestContext.response.responseBody = Blob.valueOf(JSON.serializePretty(responseData));
            
        } catch (Exception e) {
            returnError('Unexpected error: ' + e.getMessage(), 500);
        }
    }

    // === Helpers ===
    private static Boolean hasAdminAccess(String rolesStr) {
        if (String.isBlank(rolesStr)) return false;
        
        // Expanded admin roles (all lowercase)
        Set<String> adminRoles = new Set<String>{'admin', 'superadmin', 'ceo', 'owner', 'partner', 'authorizedsignatoryofficer', 'sponsor'};
            
            for (String role : rolesStr.split(';')) {
                if (role != null && adminRoles.contains(role.trim().toLowerCase())) {
                    return true;
                }
            }
        return false;
    }

    
    private static Contact validateAccountAndContact(String accountId, String contactId) {
        // Validate required parameters
        if (String.isBlank(accountId) || String.isBlank(contactId)) {
            returnError(Label.BAPP_AccountAndContactRequired, 400);
            return null;
        }
        
        // Check if Account exists dynamically
        if (!Utility.recordExists(accountId)) {
            returnError(Label.BAPP_InvalidAccountId, 400);
            return null;
        }
        
        // Check if Contact exists dynamically
        if (!Utility.recordExists(contactId)) {
            returnError(Label.BAPP_InvalidContactId, 400);
            return null;
        }
        
        // Fetch contact
        Contact c = ContactService.getInstance().getContactById(contactId);
        if (c == null || c.AccountId != accountId) {
            returnError(Label.BAPP_InvalidAccountContactRelation, 403);
            return null;
        }
        
        return c; // validated contact
    }
    
    // === Private Helper: Validate UpdatedOn Date Range ===
    private static Boolean validateUpdatedOnDates(Date fromDate, Date toDate) {
        // From provided, To missing
        if (fromDate != null && toDate == null) {
            returnError(Label.BAPP_ToDateMissing, 400);
            return false;
        }
        
        // To provided, From missing
        if (fromDate == null && toDate != null) {
            returnError(Label.BAPP_FromDateMissing, 400);
            return false;
        }
        
        // Future dates not allowed
        if ((fromDate != null && fromDate > Date.today()) || (toDate != null && toDate > Date.today())) {
            returnError(Label.BAPP_UpdatedOnDatesCannotFuture, 400);
            return false;
        }
        
        // From must be <= To
        if (fromDate != null && toDate != null && fromDate > toDate) {
            returnError(Label.BAPP_FromDateGreaterThanToDate, 400);
            return false;
        }
        
        return true;
    }
    
    // ===== Error Response =====
    private static void returnError(String msg, Integer code) {
        RestContext.response.statusCode = code;
        RestContext.response.addHeader('Content-Type', 'application/json;charset=UTF-8');
        RestContext.response.responseBody = Blob.valueOf(
            JSON.serializePretty(new Map<String, Object>{
                	'status' => 'error',
                    'message' => msg
            })
        );
    }
}