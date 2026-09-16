public with sharing class BAPPUpdateAgentInfoHandler {

    public class UpdateAgentRequest {
        public String accountId;
        public String contactId;
        public String ContactIdToUpdate; // optional
        public String caseId;
        public String caseStatus;
        public String approvalStatus;
        public String countryCode;
        public String category;
        public String subCategory;
        public String caseDescription;
        public String mobileNumber;
        public String nationalIdExpiryDate;
        public String passportExpiryDate;
        public String brnReraExpiryDate;
        public String serviceRequestType;
        public String roleToUpdate; // multi-select picklist
    }

    public static void handleUpdateAgentInfo(String requestBody) {
        try {
            UpdateAgentRequest req = (UpdateAgentRequest) JSON.deserialize(requestBody, UpdateAgentRequest.class);

            if(req == null || String.isBlank(req.accountId) || String.isBlank(req.contactId)) {
                sendError(Label.BAPP_AccountAndContactRequired);
                return;
            }
            // ---- Check record existence ----
            if (!Utility.recordExists(req.accountId)) {
                sendError(Label.BAPP_InvalidAccountId);
                return;
            }
            if (!Utility.recordExists(req.contactId)) {
                sendError(Label.BAPP_InvalidContactId);
                return;
            }
            
            // ---- Check Contact belongs to Account ----
            Contact conCheck = ContactService.getInstance().getContactById(req.contactId);
            if (conCheck.AccountId != req.accountId) {
                sendError(Label.BAPP_InvalidAccountContactRelation);
                return;
            }
            // Validate required fields
            if (String.isBlank(req.caseStatus)) {
                sendError(Label.BAPP_CaseStatusRequired);
                return;
            }
            if (String.isBlank(req.serviceRequestType)) {
                sendError(Label.BAPP_ServiceRequestTypeRequired);
                return;
            } else if (req.serviceRequestType != Label.BAPP_ServiceRequestTypeAgentDetailsUpdate) {
                sendError(Label.BAPP_ServiceRequestTypeInvalid);
                return;
            }
            
            if (String.isBlank(req.category)) {
                sendError(Label.BAPP_CategoryRequired);
                return;
            } else if (req.category != Label.BAPP_CategoryBrokerServiceRequest) {
                sendError(Label.BAPP_CategoryInvalid);
                return;
            }
            
            if (String.isBlank(req.subCategory)) {
                sendError(Label.BAPP_SubCategoryRequired);
                return;
            } else if (req.subCategory != Label.BAPP_SubCategoryBrokerAgentDetailsUpdate) {
                sendError(Label.BAPP_SubCategoryInvalid);
                return;
            }

            // --- Fetch requester contact (to check role) ---
            Contact requester = ContactService.getInstance().getContactById(req.contactId);

            Set<String> allowedAdminRoles = new Set<String>{'Admin','Owner','SuperAdmin'};
            Set<String> allowedOtherRoles = new Set<String>{'CEO','Partner','AuthorizedSignatoryOfficer','FinancialAdmin'};

            Boolean isAdmin = false;
            Boolean isOtherRole = false;
            if(requester.BrokerContactRole__c != null){
                for(String role : requester.BrokerContactRole__c.split(';')){
                    role = role.trim();
                    if(allowedAdminRoles.contains(role)) isAdmin = true;
                    if(allowedOtherRoles.contains(role)) isOtherRole = true;
                }
            }

            // --- Determine target contact (if updating an agent) ---
            String contactIdToUpdateTrimmed = String.isNotBlank(req.ContactIdToUpdate) ? req.ContactIdToUpdate.trim() : null;

            Contact targetContact = String.isNotBlank(contactIdToUpdateTrimmed)
                ? ContactService.getInstance().getContactById(contactIdToUpdateTrimmed)
                : requester;

            Boolean canUpdateTarget = false; // who can update this contact?
            Boolean canCreateCaseForTarget = false;

            // --- Access ---
            if(isAdmin){
                canUpdateTarget = true;   // Admin can update self or agent
                canCreateCaseForTarget = true; // Admin can create case for self or agent
            } else if(isOtherRole){
                // Can only update self and create case for self
                if(targetContact.Id == requester.Id){
                    canUpdateTarget = true;
                    canCreateCaseForTarget = true;
                }
            } else {
                // Agent or other roles: no access
                if(targetContact.Id == requester.Id){
                    canUpdateTarget = false;  // even self cannot update mobile directly
                    canCreateCaseForTarget = false;
                }
            }

            // --- Check if access allowed ---
            if(req.ContactIdToUpdate != null && !canUpdateTarget && !canCreateCaseForTarget){
                sendError(Label.BAPP_NoAccessToUpdate);
                return;
            }

            // --- Update mobile, expiry, role if allowed ---
            Boolean didMobileUpdate = false;
            if(String.isNotBlank(req.mobileNumber) && canUpdateTarget){
                
                    targetContact.PrimaryMobilePhone__c = req.mobileNumber;
                    targetContact.MobileCountryCode__c = req.countryCode;
                    didMobileUpdate = true;
                
            }
            Boolean requesterIsOwner = false;
            if(requester.BrokerContactRole__c != null){
                for(String role : requester.BrokerContactRole__c.split(';')){
                    if(role.trim().equalsIgnoreCase('Owner')){
                        requesterIsOwner = true;
                        break;
                    }
                }
            }
            
            if (!requesterIsOwner && String.isNotBlank(req.roleToUpdate)) {
                List<String> rolesToUpdate = req.roleToUpdate.split(';');
                for (String role : rolesToUpdate) {
                    if (role.trim().equalsIgnoreCase('Owner')) {
                        sendError(Label.BAPP_OwnerRoleAssignmentRestriction);
                        return;
                    }
                }
            }
            
            // Update role if provided and allowed
            if(String.isNotBlank(req.roleToUpdate) && canUpdateTarget){
                targetContact.BrokerContactRole__c = req.roleToUpdate;
            }
            if(didMobileUpdate || String.isNotBlank(req.roleToUpdate) || String.isNotBlank(req.nationalIdExpiryDate)
               || String.isNotBlank(req.passportExpiryDate) || String.isNotBlank(req.brnReraExpiryDate)){
                ContactService.getInstance().updateContacts(new List<Contact>{ targetContact });
            }
        // --- Normalize SubType (remove spaces) ---
        String normalizedSubType = String.isNotBlank(req.subCategory) ? req.subCategory.replaceAll('\\s+', '') : null;
        
        // --- Fetch matching Service Catalog record ---
        ServiceCatalog__c sc;
        if (String.isNotBlank(normalizedSubType)) {
            sc = ServiceCatalogService.getInstance().getBySubCategory(normalizedSubType, req.subCategory);
        }
            // ️ NEW - Only create case if one of the following is filled
            Boolean shouldCreateCase = 
                String.isNotBlank(req.nationalIdExpiryDate) || 
                String.isNotBlank(req.passportExpiryDate) ||
                String.isNotBlank(req.brnReraExpiryDate) ||
                String.isNotBlank(req.roleToUpdate) ||
                String.isNotBlank(req.ContactIdToUpdate);

			// BBM QUEUE LOGIC - Fetch BBM Queue Id
            Id bbmQueueId;
            try {
                bbmQueueId = [
                    SELECT Id
                    FROM Group
                    WHERE Type = 'Queue'
                    AND DeveloperName = 'Bloom_Broker_Management_BBM'
                    LIMIT 1
                ].Id;
            } catch (Exception e) {
                bbmQueueId = null;
            }
            // --- Insert or update Case if allowed ---
            Case c;
            Boolean didCaseCreate = false;
            if(canCreateCaseForTarget){
                if(String.isBlank(req.caseId) && shouldCreateCase ){
                    Id recordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, 'BrokerAgentDetailsUpdate');
                    c = new Case(
                        AccountId = req.accountId,
                        ContactId = req.contactId,
                        TypeofEstablishment__c = targetContact.Account.TypeOfEstablishment__c,
                        Description = req.caseDescription,
                        BrokerContactRole__c = String.isNotBlank(req.roleToUpdate) ? req.roleToUpdate : targetContact.BrokerContactRole__c,
                        ApprovalStatus__c = 'Draft',
                        RecordTypeId = recordTypeId,
                        Type = req.serviceRequestType,
                        Broker_Agent__c = String.isNotBlank(req.contactIdToUpdate) ? req.contactIdToUpdate : null,
                        ServiceCatalog__c = sc != null ? sc.Id : null,
                        NationalIDExpiryDate__c = parseDate(req.nationalIdExpiryDate),
                        PassportExpiryDate__c = parseDate(req.passportExpiryDate),
                        BRN_RERA_Expiry_Date__c = parseDate(req.brnReraExpiryDate),
                        OwnerId = bbmQueueId
                    );
                    Case insertedCase = CaseService.getInstance().insertCase(c);
                    // query to get CaseNumber
                    c = CaseService.getInstance().getCaseById(c.Id);
                    didCaseCreate = true;
                } else if (String.isNotBlank(req.caseId)) {
                        c = CaseService.getInstance().getCaseById(req.caseId);
                   		 // --- Account And Contact check ---
                        if (c.AccountId != req.accountId || c.ContactId != req.contactId) {
                            sendError(Label.BAPP_InvalidAgencyOrAgent);
                            return;
                        }
                    
                        // --- Prevent updates if Case not in Draft
                        if (c.ApprovalStatus__c != 'Draft') {
                            sendError(Label.BAPP_OnlyDraftUpdate);
                            return;
                        }
                    
                        // --- Now safely apply updates
                        if (String.isNotBlank(req.caseDescription))
                            c.Description = req.caseDescription;
                    
                        c.TypeofEstablishment__c = targetContact.Account.TypeOfEstablishment__c;
                    
                        if (String.isNotBlank(req.roleToUpdate))
                            c.BrokerContactRole__c = req.roleToUpdate;
                     
                    	if (String.isNotBlank(req.caseStatus) && req.caseStatus == 'Submitted')
                            c.ApprovalStatus__c = req.caseStatus;
                    	if (bbmQueueId != null && req.caseStatus == 'Submitted') {
                            c.OwnerId = bbmQueueId;
                        }
                        if (String.isNotBlank(req.serviceRequestType))
                            c.Type = req.serviceRequestType;
                    
                        if (sc != null)
                            c.ServiceCatalog__c = sc.Id;
                    
                        if (String.isNotBlank(req.nationalIdExpiryDate))
                            c.NationalIDExpiryDate__c = parseDate(req.nationalIdExpiryDate);
                    
                        if (String.isNotBlank(req.passportExpiryDate))
                            c.PassportExpiryDate__c = parseDate(req.passportExpiryDate);
                    
                        if (String.isNotBlank(req.brnReraExpiryDate))
                            c.BRN_RERA_Expiry_Date__c = parseDate(req.brnReraExpiryDate);
                    
                       Case updatedCase = CaseService.getInstance().updateCase(c);
                    }
            }

            // --- Fetch related documents ---
            List<Map<String,String>> agentDocs = new List<Map<String,String>>();
            if(c != null){
                Set<Id> caseIds = new Set<Id>{c.Id};
                List<Document__c> relatedDocs = DocumentService.getInstance().getExistingDocuments(caseIds);
                for(Document__c doc : relatedDocs){
                    agentDocs.add(new Map<String,String>{
                        'id' => doc.Id,
                        'type' => doc.DocumentType__r != null ? doc.DocumentType__r.Type__c : null
                    });
                }
            }

            // --- Build JSON Response ---
            JSONGenerator gen = JSON.createGenerator(true);
            gen.writeStartObject();

            writeStringOrNull(gen, 'status', 'success');
            writeStringOrNull(gen, 'AccountId', req.accountId);
            writeStringOrNull(gen, 'AccountName', targetContact.Account != null ? targetContact.Account.Name : null);
            writeStringOrNull(gen, 'ContactId', req.contactId);
            writeStringOrNull(gen, 'ContactName', targetContact.FirstName+' '+targetContact.LastName);
            writeStringOrNull(gen, 'description', req.caseDescription);
            writeStringOrNull(gen, 'category', req.category);
            writeStringOrNull(gen, 'subCategory', req.subCategory);
            if (c != null) {
         		writeStringOrNull(gen, 'caseStatus', c.status);
                writeStringOrNull(gen, 'approvalStatus', c.ApprovalStatus__c);
                writeStringOrNull(gen, 'approvalComments', c.ApprovalComments__c);
                writeStringOrNull(gen, 'rejectionComments', c.RejectionComments__c);
                writeStringOrNull(gen, 'serviceRequestType', c.Type);
            } else {
                writeStringOrNull(gen, 'caseStatus', null);
                writeStringOrNull(gen, 'approvalStatus', null);
                writeStringOrNull(gen, 'approvalComments', null);
                writeStringOrNull(gen, 'rejectionComments', null);
                writeStringOrNull(gen, 'serviceRequestType', null);
            }
            

            // Mobile update message
            if(String.isNotBlank(req.mobileNumber) && didMobileUpdate) {
                gen.writeStringField('MobileUpdate',Label.BAPP_MobileUpdateSuccess);
            }  else if(!canUpdateTarget && String.isNotBlank(req.mobileNumber)){
                gen.writeStringField('MobileUpdate',Label.BAPP_MobileUpdateNotAllowed);
            }

            if(didCaseCreate){
                gen.writeStringField('CaseMessage',Label.BAPP_CaseCreatedSuccess);
            } else if(c != null && !didCaseCreate){
                gen.writeStringField('CaseMessage',Label.BAPP_CaseUpdatedSuccess);
            }

            // --- AgentDetails ---
            gen.writeFieldName('AgentDetails');
            gen.writeStartObject();
            if(c != null){
                writeStringOrNull(gen, 'caseId', c.Id);
                writeStringOrNull(gen, 'caseNumber', c.CaseNumber);
                writeStringOrNull(gen, 'updatedMobileNumber', didMobileUpdate ? req.mobileNumber : null);
                writeStringOrNull(gen, 'updatedCountryCode', didMobileUpdate ? req.countryCode : null);
                writeStringOrNull(gen, 'updatedRole', String.isNotBlank(req.roleToUpdate) ? req.roleToUpdate : targetContact.BrokerContactRole__c);
                writeStringOrNull(gen, 'updatedNationalIDExpiryDate', c.NationalIDExpiryDate__c != null ? String.valueOf(c.NationalIDExpiryDate__c) : null);
                writeStringOrNull(gen, 'updatedPassportExpiryDate', c.PassportExpiryDate__c != null ? String.valueOf(c.PassportExpiryDate__c) : null);
                writeStringOrNull(gen, 'updatedBRNRERAExpiryDate', c.BRN_RERA_Expiry_Date__c != null ? String.valueOf(c.BRN_RERA_Expiry_Date__c) : null);
            } else {
                // Write minimal info if case not created
                writeStringOrNull(gen, 'caseId', null);
                writeStringOrNull(gen, 'caseNumber', null);
                writeStringOrNull(gen, 'updatedMobileNumber', didMobileUpdate ? req.mobileNumber : null);
                writeStringOrNull(gen, 'updatedCountryCode', didMobileUpdate ? req.countryCode : null);
                writeStringOrNull(gen, 'updatedRole', String.isNotBlank(req.roleToUpdate) ? req.roleToUpdate : targetContact.BrokerContactRole__c);
                writeStringOrNull(gen, 'updatedNationalIDExpiryDate', null);
                writeStringOrNull(gen, 'updatedPassportExpiryDate', null);
                writeStringOrNull(gen, 'updatedBRNRERAExpiryDate', null);
            }
			
            // Documents
            gen.writeFieldName('Documents');
            gen.writeStartArray();
            for(Map<String,String> docMap : agentDocs){
                gen.writeStartObject();
                writeStringOrNull(gen, 'id', docMap.get('id'));
                writeStringOrNull(gen, 'type', docMap.get('type'));
                gen.writeEndObject();
            }
            gen.writeEndArray();
            gen.writeEndObject(); // AgentDetails

            gen.writeEndObject(); // main object

            RestContext.response.addHeader('Content-Type','application/json;charset=UTF-8');
            RestContext.response.responseBody = Blob.valueOf(gen.getAsString());
            RestContext.response.statusCode = 200;

        } catch(Exception ex){
            sendError(ex.getMessage());
        }
    }

    private static void writeStringOrNull(JSONGenerator gen, String field, String val) {
        if(val != null) gen.writeStringField(field,val); else gen.writeNullField(field);
    }
    
    private static Date parseDate(String strDate){
        if(String.isBlank(strDate)) return null;
        try { return Date.valueOf(strDate);} catch(Exception e){ return null;}
    }
    
    private static void sendError(String message){
        Map<String,Object> res = new Map<String,Object>{'status'=>'error','message'=>message};
        RestContext.response.addHeader('Content-Type','application/json;charset=UTF-8');
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(res));
        RestContext.response.statusCode = 400;
    }
}