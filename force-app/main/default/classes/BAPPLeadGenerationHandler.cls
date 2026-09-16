/*
* @Author        : Rushikesh Jadhav
* @CreatedDate   : 08th Sep 2025
* @Description   : Handles Lead records creation via REST API.                 
*/
/*****************************************************************************************************
* Version       Author        Date             Comment                                                                       
* 1.0           Rushikesh     08-SEP-2025      Initial draft to handle lead creation functionality
*                                            
*****************************************************************************************************/
public with sharing class BAPPLeadGenerationHandler {

    // ====== REQUEST WRAPPERS ======
    public class LeadGenerationRequest {
        public String contactId;    // Required for create
        public String accountId;
        public String leadId;       // Required for update 
        public String salesManagerId;

        public String leadType; // IndividualLead | OrganizationalLead
        public String title; 
        public String firstName;
        public String middleName;
        public String lastName;
        public String email;
        public String countryCode;
        public String phoneNumber;
        public String country;
        public String state;
        public String city;
        public String street;
        public String postalCode;
        public String organizationName;
        public String passportNumber;
        public String passportExpiryDate;
        public String nationalId;
        public String nationalIdExpiryDate;
        public String leadStatus;
        public String preferredCommunication; 
        public String preferredLanguage; 

        public OrganizationLeadDetails organizationDetails;

        public String project;
        public String unitType;
        public String numberOfBedrooms;
    }

    public class OrganizationLeadDetails {
        public String organizationName;
        public String title;
        public String contactFirstName;
        public String contactMiddleName;
        public String contactLastName;
        public String contactEmail;
        public String contactPhoneCountryCode;
        public String contactPhoneNumber;
        public String organizationAddress; 
    }

    // ====== ENTRY POINT ======
    public static void handleLeadGeneration(String requestBody) {
        try {
            LeadGenerationRequest req = 
                (LeadGenerationRequest)JSON.deserialize(requestBody, LeadGenerationRequest.class);
    			// Check for blank accountId and contactId before recordExists check
            if (String.isBlank(req.accountId)) {
                makeErrorResponse(new Map<String, Object>{
                    'status' => 'error',
                    'message' => Label.BAPP_AccountIdRequired
                });
                return;
            }
    
            if (String.isBlank(req.contactId)) {
                makeErrorResponse(new Map<String, Object>{
                    'status' => 'error',
                    'message' => Label.BAPP_ContactIdRequired
                });
                return;
            }
            // ---- Check record existence ----
            if (!Utility.recordExists(req.accountId)) {
                makeErrorResponse(new Map<String, Object>{
                    'status' => 'error',
                    'message' => Label.BAPP_InvalidAccountId
                });
                return;
            }
    
            if (!Utility.recordExists(req.contactId)) {
                makeErrorResponse(new Map<String, Object>{
                    'status' => 'error',
                    'message' => Label.BAPP_InvalidContactId
                });
                return;
            }
    
            // ---- Check Contact belongs to Account ----
            Contact con = ContactService.getInstance().getContactById(req.contactId);
            if (con.AccountId != req.accountId) {
                 makeErrorResponse(new Map<String, Object>{
                    'status' => 'error',
                    'message' => Label.BAPP_InvalidAccountContactRelation
                });
                return;
            }
            // === Check if Contact has Agent role ===
            Boolean isAgent = false;
            if (con.BrokerContactRole__c != null) {
                List<String> roles = con.BrokerContactRole__c.split(';');
                for (String role : roles) {
                    String trimmed = role != null ? role.trim().toLowerCase() : '';
                    if (trimmed == 'agent') {
                        isAgent = true;
                        break;
                    }
                }
            }
            if (!isAgent) {
                makeErrorResponse(new Map<String, Object>{
                    'status' => 'error',
                    'message' => 'Access Denied or no access'
                });
                return;
            }
            
            Map<String, Object> finalResponse = processLead(req); 

            if (String.valueOf(finalResponse.get('status')) == 'success') {
                makeSuccessResponse(finalResponse);
            } else if (String.valueOf(finalResponse.get('status')) == 'partial_success') {
                makePartialSuccessResponse(finalResponse); 
            } else {
                makeErrorResponse(finalResponse);
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e); 
            makeServerErrorResponse(new Map<String, Object>{
                'status' => 'error',
                'message' => 'Server Error: ' + e.getMessage() 
            });
        }
    }

    // ====== MAIN PROCESSING ======
    private static Map<String, Object> processLead(LeadGenerationRequest req) {
        Map<String, Object> response = new Map<String, Object>();
        List<Map<String, String>> validationErrors = validateLead(req);

        if (!validationErrors.isEmpty()) {
            response.put('status', 'error');
            response.put('message', Label.BAPP_ValidationFailed);
            response.put('errors', validationErrors);
            return response;
        }
        try {
            if (String.isNotBlank(req.leadId)) {
                response = processUpdateLead(req); 
            } else if (String.isNotBlank(req.contactId)) {
                response = processCreateLead(req); 
            } else {
                response.put('status', 'error');
                response.put('message', Label.BAPP_LeadIdOrContactIdRequired);
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e); 
            response.put('status', 'error');
            response.put('message', 'Server Error: ' + e.getMessage());
        }

        return response;
    }

    // ====== CREATE LEAD ======
    private static Map<String, Object> processCreateLead(LeadGenerationRequest req) {
        Map<String, Object> response = new Map<String, Object>();

        List<Lead> existingDupes = LeadService.getInstance().findDuplicateLead(req);
        if (!existingDupes.isEmpty()) {
            response.put('status', 'error');
            response.put('message', Label.BAPP_DuplicateLeadDetected);
            return response;
        }

        Lead newLead = new Lead();
        newLead.BrokerAgent__c = req.contactId;
        newLead.BrokerAgency__c = req.accountId;
        mapRequestToLead(newLead, req);

        // Assign default owner
        newLead.OwnerId = getBrokerQueueId(); 

        List<Lead> leadsToInsert = new List<Lead>{ newLead };
        List<Database.SaveResult> insertResults = LeadService.getInstance().insertLeadsWithoutDuplicateRule(leadsToInsert);

        if (!insertResults[0].isSuccess()) {
            response.put('status', 'error');
            response.put('message', insertResults[0].getErrors()[0].getMessage());
            return response;
        }

        Id newLeadId = leadsToInsert[0].Id;
        Lead insertedLead = LeadService.getInstance().getLeadById(newLeadId);

        response.put('status', 'success');
        response.put('message', Label.BAPP_LeadCreatedSuccess);
        response.put('leadId', insertedLead.Id);
        response.put('accountId', insertedLead.BrokerAgency__c);
        response.put('contactId', insertedLead.BrokerAgent__c);
        response.put('leadNumber', insertedLead.LeadNumber__c);

        return response;
    }

    // ====== UPDATE LEAD ======
    private static Map<String, Object> processUpdateLead(LeadGenerationRequest req) {
        Map<String, Object> response = new Map<String, Object>();
        // Perform duplicate check only if salesManagerId is not provided
            if (String.isBlank(req.salesManagerId) && req.leadStatus != 'Closed') {
                List<Lead> existingDupes = LeadService.getInstance().findDuplicateLead(req);
                if (!existingDupes.isEmpty()) {
                    response.put('status', 'error');
                    response.put('message', Label.BAPP_DuplicateLeadDetected);
                    return response;
                }
            }

        Lead existingLead = LeadService.getInstance().getLeadById(req.leadId);
        // --- Account And Contact check ---
        if (existingLead.BrokerAgency__c != req.accountId || existingLead.BrokerAgent__c != req.contactId) {
            response.put('status', 'error');
            response.put('message', Label.BAPP_InvalidAgencyOrAgent);
            return response;
        }
        if (existingLead.Status == 'New') {
        mapRequestToLead(existingLead, req);
         

                if (String.isNotBlank(req.salesManagerId)) {
                    existingLead.OwnerId = req.salesManagerId;
                    existingLead.Status = 'In Progress';
                    existingLead.LeadManagerStatus__c = 'New';
                }
        
                List<Lead> leadsToUpdate = new List<Lead>{ existingLead };
                List<Database.SaveResult> updateResults = LeadService.getInstance().updateLeadsWithoutDuplicateRule(leadsToUpdate);
        
                if (!updateResults[0].isSuccess()) {
                    response.put('status', 'error');
                    response.put('message', updateResults[0].getErrors()[0].getMessage());
                    return response;
                }
        
                response.put('status', 'success');
                response.put('message', Label.BAPP_LeadUpdatedSuccess);
                response.put('leadId', existingLead.Id);
        
            } else {
                // Condition not met — skip update
                response.put('status', 'error');
                response.put('message', 'Lead cannot be updated once the sales manager is assigned or status is closed');
            }
        
            return response;
        }
    // ====== FIELD MAPPING ======
    private static void mapRequestToLead(Lead leadRec, LeadGenerationRequest req) {
        leadRec.RecordTypeId = getRecordTypeId(req.leadType);
        leadRec.Salutation = req.title;
        leadRec.FirstName = req.firstName;
        leadRec.MiddleName = req.middleName;
        leadRec.LastName = req.lastName;
        leadRec.Email = req.email;
        leadRec.MobilePhoneNumber__c = req.phoneNumber;
        leadRec.LeadSource = 'Broker';
        leadRec.leadsubsource__c = 'Broker Portal';
        leadRec.lead_channel__c = 'Broker Portal';
        leadRec.MobileCountryCode__c = req.countryCode;
        leadRec.Company = req.organizationName;
        leadRec.Passport_Number__c = req.passportNumber;
        leadRec.PassportExpiryDate__c = String.isNotBlank(req.passportExpiryDate) ? Date.valueOf(req.passportExpiryDate) : null;
        leadRec.NationalID__c = req.nationalId;
        leadRec.NationalIDExpiryDate__c = String.isNotBlank(req.nationalIdExpiryDate) ? Date.valueOf(req.nationalIdExpiryDate) : null;

        if (String.isNotBlank(req.leadStatus) && req.leadStatus.equalsIgnoreCase('Closed')) {
            leadRec.Status = req.leadStatus;
        }

        leadRec.LanguagePreference__c = req.preferredLanguage;
        leadRec.PreferredCommunicationMethodology__c = req.preferredCommunication;
        leadRec.Project__c = req.project;
        leadRec.UnitType__c = req.unitType;
        leadRec.NumberOfBedrooms__c = req.numberOfBedrooms;

        if ('OrganizationLead'.equalsIgnoreCase(req.leadType) && req.organizationDetails != null) {
            leadRec.Company = req.organizationDetails.organizationName;
        }
    }

    // ====== VALIDATION ======
    private static List<Map<String, String>> validateLead(LeadGenerationRequest req) {
        List<Map<String, String>> errors = new List<Map<String, String>>();

        //  adjusted validation for create/update logic
        if(String.isBlank(req.leadId) && String.isBlank(req.contactId)){
            errors.add(buildError('contactId', Label.BAPP_ContactIdRequiredForCreate));
        }

        checkRequired(req.accountId, 'accountId', Label.BAPP_AccountIdRequired, errors);
        checkRequired(req.leadType, 'leadType', Label.BAPP_LeadTypeRequired, errors);
        checkRequired(req.title, 'title', Label.BAPP_TitleRequired, errors);
        checkRequired(req.firstName, 'firstName', Label.BAPP_FirstNameRequired, errors);
        checkRequired(req.lastName, 'lastName', Label.BAPP_LastNameRequired, errors);
        checkRequired(req.countryCode, 'countryCode', Label.BAPP_CountryCodeIsRequired, errors);
        checkRequired(req.email, 'email', Label.BAPP_EmailRequired, errors);
        checkRequired(req.phoneNumber, 'phoneNumber', Label.BAPP_PhoneNumberRequired, errors);
        checkRequired(req.preferredLanguage, 'preferredLanguage', Label.BAPP_PreferredLanguageRequired, errors);

        if ('OrganizationLead'.equalsIgnoreCase(req.leadType)) {
            checkRequired(req.organizationName, 'organizationName', Label.BAPP_OrgNameRequired, errors);
        }

        return errors;
    }

    private static void checkRequired(String fieldVal, String fieldName, String msg, List<Map<String, String>> errors) {
        if (String.isBlank(fieldVal)) errors.add(buildError(fieldName, msg));
    }

    private static Map<String, String> buildError(String field, String msg) {
        return new Map<String, String>{ 'field' => field, 'message' => msg };
    }

    // ====== HELPERS ======
    private static Id getRecordTypeId(String leadType) {
        Map<String, Schema.RecordTypeInfo> rtMap = Lead.SObjectType.getDescribe().getRecordTypeInfosByName();
        if ('IndividualLead'.equalsIgnoreCase(leadType) && rtMap.containsKey('Individual Lead')) {
            return rtMap.get('Individual Lead').getRecordTypeId();
        } else if ('OrganizationLead'.equalsIgnoreCase(leadType) && rtMap.containsKey('Organization Lead')) {
            return rtMap.get('Organization Lead').getRecordTypeId();
        }
        return null;
    }

    private static Id getBrokerQueueId() {
        QueueService qs = new QueueService();
        Group queue = qs.getGroupByDeveloperNameAndType('Broker_Unassigned_Leads', 'Queue');
        return queue != null ? queue.Id : null;
    }

    // ====== RESPONSE HANDLERS ======
    public static void makeSuccessResponse(Map<String, Object> response) {  
        RestContext.response.addHeader('Content-Type', 'application/json;charset=UTF-8');
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(response));
        RestContext.response.statusCode = 200;
    }

    public static void makePartialSuccessResponse(Map<String, Object> response) {
        response.put('status', 'partial_success');
        RestContext.response.addHeader('Content-Type', 'application/json;charset=UTF-8');
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(response));
        RestContext.response.statusCode = 200;
    }

    public static void makeErrorResponse(Map<String, Object> error) {
        RestContext.response.addHeader('Content-Type', 'application/json;charset=UTF-8');
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(error));
        RestContext.response.statusCode = 400;
    }

    public static void makeServerErrorResponse(Map<String, Object> error) {
        error.put('status', 'error');
        RestContext.response.addHeader('Content-Type', 'application/json;charset=UTF-8');
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(error));
        RestContext.response.statusCode = 500;
    }
}