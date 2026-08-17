public class BAPPSubmitCaseApplicantHandler {

    public class ApplicantRequest {
        public String accountId;
        public String contactId;
        public String registrationStatus;
        public String typeOfEstablishment;
        public List<BrokerApplicantData> companyPersonnel;
    }

    public class BrokerApplicantData {
        public String caseId;
        public String role;
        public String isSuperAdmin;
        public String title;
        public String firstName;
        public String middleName;
        public String lastName;
        public String phoneNumber;
        public String email;
        public String nationality;
        public String country;
        public String countryCode;
        public String nationalId;
        public String nationalIdExpiryDate;
        public String passportNumber;
        public String passportExpiryDate;
        public String dateOfBirth;
        public Decimal shareHoldingPercentage;
        public String designation;
        public String typeOfEstablishment;
        public String reraNumber;
        public String reraNumberExpiryDate;
    }

    public static void handleCaseBrokerApplicant(String requestBody) {
        try {
            ApplicantRequest req = (ApplicantRequest)JSON.deserialize(requestBody, ApplicantRequest.class);
             // --- Step 1: Validate required fields ---
            if (req == null || String.isBlank(req.accountId) || String.isBlank(req.contactId)) {
                makeErrorResponse(new Map<String, Object>{
                    'status' => 'error',
                    'message' => 'Both accountId and contactId are required.'
                });
                return;
            }

             // --- Step 2: Verify that contact belongs to the account and is Admin ---
            Contact contactRec = [SELECT Id, AccountId, BrokerContactRole__c, Name FROM Contact WHERE Id = :req.contactId LIMIT 1];

            if (contactRec.AccountId != req.accountId) {
                makeErrorResponse(new Map<String, Object>{
                    'status' => 'error',
                    'message' => 'The provided contactId does not belong to the specified accountId.'
                }); 
                return;
            }

   
            // Split multipicklist and normalize
            Set<String> roles = new Set<String>();
            for (String r : contactRec.BrokerContactRole__c.split(';')) {
                roles.add(r.trim().toLowerCase());
            }

            // Deny access if none of the allowed roles exist
            if (!(roles.contains('admin') || roles.contains('owner') || roles.contains('superadmin'))) {
                makeErrorResponse(new Map<String, Object>{
                    'status' => 'error',
                    'message' => 'Access denied. Only contacts with Admin, Owner or SuperAdmin roles can submit applicants.'
                });
                return;
            }

                
            Map<String, Object> finalResponse = createOrUpdateApplicants(req);

            if (String.valueOf(finalResponse.get('status')) == 'success') {
                makeSuccessResponse(finalResponse);
            } else if (String.valueOf(finalResponse.get('status')) == 'partial_success') {
                makeSuccessResponse(finalResponse); // still 200 but partial
            } else {
                makeErrorResponse(finalResponse);
            }

        } catch (Exception e) {
            makeServerErrorResponse(new Map<String, Object>{
                'status' => 'error',
                'message' => e.getMessage()
            });
        }
    }

    public static Map<String, Object> createOrUpdateApplicants(ApplicantRequest req) {
        List<Map<String, Object>> successResponses = new List<Map<String, Object>>();
        List<Map<String, Object>> errorResponses = new List<Map<String, Object>>();
        List<Case> toInsert = new List<Case>();
        List<Case> toUpdate = new List<Case>();
        
        Id bloomQueueId;
            try {
                bloomQueueId = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Bloom_Broker_Management_BBM' LIMIT 1].Id;
            } catch (Exception e) {
                bloomQueueId = null;
            }
        
        Map<Integer, Case> responseIndexToCase = new Map<Integer, Case>();

        Boolean hasErrors = false;
        String typeOfEstablishments = req.typeOfEstablishment != null ? req.typeOfEstablishment.toLowerCase() : '';
        // Capitalize first letter for restricted picklist field (e.g. 'domestic' -> 'Domestic')
        String typeOfEstablishmentsForField = String.isNotBlank(typeOfEstablishments)
            ? typeOfEstablishments.substring(0, 1).toUpperCase() + typeOfEstablishments.substring(1)
            : null;
        
        
        List<ServiceCatalog__c> scList = [SELECT Id, Name, RecordTypeDevName__c FROM ServiceCatalog__c WHERE SubCategory__c = 'Broker New Agent Registration' LIMIT 1];

        for (BrokerApplicantData applicant : req.companyPersonnel) {
            String caseStatus;
            Boolean caseDraft;
            
            // Check if CaseId is provided — then validate ApprovalStatus__c
           if (String.isNotBlank(applicant.caseId)) {
            try {
                Case existingCase = [
                    SELECT Id, ApprovalStatus__c,Status,Draft__c, AccountId, ContactId 
                    FROM Case 
                    WHERE Id = :applicant.caseId 
                    LIMIT 1
                ];
                caseStatus = existingCase.Status;
                caseDraft = existingCase.Draft__c;

                // Check if Account and Contact match the request
                if (existingCase.AccountId != req.accountId || existingCase.ContactId != req.contactId) {
                    Map<String, Object> res = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(applicant));
                    res.put('status', 'error');
                    res.put('message', 'Access Denied. You can update members only of your Agency.');
                    errorResponses.add(res);
                    hasErrors = true;
                    continue; 
                }

                // Check if Case is in Draft stage
                if (caseDraft == false) { // Draft == false; caseStatus != 'New'
                    Map<String, Object> res = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(applicant));
                    res.put('status', 'error');
                    res.put('message', 'You cannot update the Service Request once Submitted.');
                    errorResponses.add(res);
                    hasErrors = true;
                    continue; // Skip further processing for this applicant
                }

            } catch (Exception e) {
                Map<String, Object> res = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(applicant));
                res.put('status', 'error');
                res.put('message', 'Invalid CaseId or Case not found.');
                errorResponses.add(res);
                hasErrors = true;
                continue;
            }
        }
            List<Map<String, String>> fieldErrors = validateApplicant(applicant, typeOfEstablishments);

            // Copy all applicant fields into response map
            Map<String, Object> res = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(applicant));

            // Add fullName convenience field
            res.put('fullName',
                (applicant.firstName != null ? applicant.firstName : '') + ' ' +
                (applicant.lastName != null ? applicant.lastName : '')
            );

            // Role cleanup 
            Set<String> roleSet = new Set<String>();
            if (String.isNotBlank(applicant.role)) {
                for (String ro : applicant.role.split(',')) {
                    roleSet.add(ro.trim()); 
                }
            }
            String cleanedRoles = roleSet.isEmpty() ? '' : String.join(new List<String>(roleSet), ';');
    
            // Validation errors
            if (!fieldErrors.isEmpty()) {
                res.put('fieldErrors', fieldErrors);
                res.put('status', 'error');
                res.put('message', 'Validation failed for ' + (applicant.role != null ? applicant.role : 'applicant'));
                errorResponses.add(res);
                hasErrors = true;
                continue;
            }

            // Create Case record
            Id brokerRegistrationRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, 'BrokerAgentRegistrationAndUpdate'); 
            Case record = new Case(
                RecordTypeId = brokerRegistrationRecordTypeId,
                Status = 'New',
                Draft__c = true,
                Email_Address__c = applicant.email,
                PhoneNumber__c = applicant.phoneNumber,
                Title__c = applicant.title,
                First_Name__c  = applicant.firstName,
                MiddleName__c = applicant.middleName,
                Last_Name__c  = applicant.lastName,
                NationalID__c  = applicant.nationalId,
                NationalIDExpiryDate__c  = String.isNotBlank(applicant.nationalIdExpiryDate) ? Date.valueOf(applicant.nationalIdExpiryDate) : null,
                DateOfBirth__c  = String.isNotBlank(applicant.dateOfBirth) ? Date.valueOf(applicant.dateOfBirth) : null,
                ShareHoldingPercentage__c  = applicant.shareHoldingPercentage,
                Designation__c = applicant.designation,
                BrokerContactRole__c = cleanedRoles,
                Country__c = applicant.country,
                Mobile_Country_Code__c  = applicant.countryCode,
                AccountId = req.accountId,
                ContactId = req.contactId,
                PassportNumber__c  = applicant.passportNumber,
                PassportExpiryDate__c = String.isNotBlank(applicant.passportExpiryDate) ? Date.valueOf(applicant.passportExpiryDate) : null,
                BRN_RERA_Expiry_Date__c = String.isNotBlank(applicant.reraNumberExpiryDate) ? Date.valueOf(applicant.reraNumberExpiryDate) : null,
                BRN_RERA_Number__c = applicant.reraNumber,
                TypeofEstablishment__c = typeOfEstablishmentsForField,
                ApprovalStatus__c = 'Not Approved',
                Origin = 'Portal',
                FinalApprovalStage__c = 'First Approval',
                ServiceCatalog__c = scList.isEmpty() ? null : scList[0].Id,
                Type = 'Broker Service Request',
                SubType__c = 'Broker New Agent Registration',
                Subject = 'Broker New Agent Registration',
                OwnerId = bloomQueueId
            );

            if (String.isNotBlank(applicant.caseId)) {
                record.Id = applicant.caseId;
                toUpdate.add(record);
            } else {
                toInsert.add(record);
                responseIndexToCase.put(successResponses.size(), record);
            }

            res.put('status', 'success');
            res.put('message', 'Applicant registered successfully.');
            successResponses.add(res);
        }

        if (!toInsert.isEmpty()) insert toInsert;
        
        for (Integer index : responseIndexToCase.keySet()) {
            Case insertedCase = responseIndexToCase.get(index);
            successResponses[index].put('caseId', insertedCase.Id);
        }
        Boolean isSubmitted =
            String.isNotBlank(req.registrationStatus) &&
            req.registrationStatus == 'Submitted';
        
        if (!toUpdate.isEmpty()) {
            update toUpdate;
        
            if (isSubmitted) {

                Set<Id> updatedCaseIds = new Map<Id, Case>(toUpdate).keySet();
                
                List<Case> requeriedCases = CaseService.getInstance().getCaseByIds(updatedCaseIds);
            
                List<Case> approvalUpdateList = new List<Case>();
                for (Case c : requeriedCases) {
                    approvalUpdateList.add(new Case(
                        Id = c.Id,
                        ApprovalStatus__c = 'Pending',
                        Draft__c = false
                    ));
                }
                update approvalUpdateList;
            }
        }
        // Collect related documents
        Set<Id> caseIds = new Set<Id>();
        caseIds.addAll(new Map<Id, Case>(toInsert).keySet());
        caseIds.addAll(new Map<Id, Case>(toUpdate).keySet());

        List<Map<String, String>> caseDocuments = new List<Map<String, String>>();
        List<Document__c> relatedDocs = DocumentService.getInstance().getExistingDocuments(caseIds);
        for (Document__c doc : relatedDocs) {
            caseDocuments.add(new Map<String, String>{
                'id' => doc.Id,
                'type' => doc.DocumentType__r != null ? doc.DocumentType__r.Type__c : null
            });
            system.debug('relatedDocs ' + relatedDocs);
        }

        if (!successResponses.isEmpty() && !errorResponses.isEmpty()) {
            return new Map<String, Object>{
                'data' => successResponses,
                'errors' => errorResponses,
                'accountId' => req.accountId,
                'caseDocuments' => caseDocuments,
                'message' => 'One or more personnel records failed validation.',
                'status' => 'partial_success'
            };
        } else if (!successResponses.isEmpty()) {
            return new Map<String, Object>{
                'data' => successResponses,
                'accountId' => req.accountId,
                'caseDocuments' => caseDocuments,
                'message' => 'All personnel created successfully.',
                'status' => 'success'
            };
        } else {
            return new Map<String, Object>{
                'errors' => errorResponses,
                'accountId' => req.accountId,
                'caseDocuments' => caseDocuments,
                'message' => 'All personnel records failed validation.',
                'status' => 'error'
            };
        }
    }

    private static List<Map<String, String>> validateApplicant(BrokerApplicantData applicant, String typeOfEstablishment) {
        List<Map<String, String>> errors = new List<Map<String, String>>();
        checkRequired(applicant.role, 'role', 'Role is required.', errors);
        checkRequired(applicant.title, 'title', 'Title is required.', errors);
        checkRequired(applicant.firstName, 'firstName', 'First Name is required.', errors);
        checkRequired(applicant.lastName, 'lastName', 'Last Name is required.', errors);
        checkRequired(applicant.phoneNumber, 'phoneNumber', 'Phone Number is required.', errors);
        checkRequired(applicant.email, 'email', 'Email is required.', errors);
        checkRequired(applicant.country, 'country', 'Country is required', errors);

        if (!String.isBlank(applicant.role) && applicant.role == 'Admin'){
            checkRequired(applicant.dateOfBirth, 'dateOfBirth', 'Date of Birth is required.', errors);
        }
       // checkRequired(applicant.countryCode, 'countryCode', 'Country Code is required', errors);

        if (!String.isBlank(applicant.role) && (applicant.role.contains('Partner') || applicant.role.contains('Owner'))) {
            checkRequired(applicant.shareHoldingPercentage, 'shareHoldingPercentage', 'Shareholding Percentage is required.', errors);
        }
        if (!String.isBlank(applicant.role) && (applicant.role.contains('AuthorizedSignatoryOfficer'))) {
           // checkRequired(applicant.country, 'country', 'Country is required.', errors);
            checkRequired(applicant.designation, 'designation', 'Designation is required.', errors);
        }
        if (typeOfEstablishment == 'international') {
            checkRequired(applicant.passportNumber, 'passportNumber', 'Passport Number is required for international applicants.', errors);
            checkRequired(applicant.passportExpiryDate, 'passportExpiryDate', 'Passport Expiry Date is required for international applicants.', errors);
        } else if (typeOfEstablishment == 'domestic') {
            checkRequired(applicant.nationalId, 'nationalId', 'National ID is required.', errors);
            checkRequired(applicant.nationalIdExpiryDate, 'nationalIdExpiryDate', 'National ID Expiry is required.', errors);
        }
        if (!String.isBlank(applicant.role) && applicant.role.contains('Agent')) {
            checkRequired(applicant.reraNumber, 'reraNumber', 'BRN RERA Number is required for Agent applicants.', errors);
            checkRequired(applicant.reraNumberExpiryDate, 'reraNumberExpiryDate', 'BRN Expiry Date is required for Agent applicants.', errors);
        }

        return errors;
    }

    public static void checkRequired(String fieldValue, String fieldName, String errorMsg, List<Map<String, String>> errors) {
        if (String.isBlank(fieldValue)) {
            errors.add(buildError(fieldName, errorMsg));
        }
    }
    public static void checkRequired(Date fieldValue, String fieldAPI, String fieldLabel, List<Map<String, String>> errors) {
        if (fieldValue == null) {
            errors.add(buildError(fieldAPI, fieldLabel));
        }
    }
    public static void checkRequired(Decimal val, String fieldAPI, String fieldLabel, List<Map<String, String>> errors) {
        if (val == null) {
            errors.add(buildError(fieldAPI, fieldLabel));
        }
    }

    private static Map<String, String> buildError(String field, String message) {
        return new Map<String, String>{'field' => field, 'message' => message};
    }

    public static void makeSuccessResponse(Map<String, Object> response) { 
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
        error.put('message', 'Server Error');
        RestContext.response.addHeader('Content-Type', 'application/json;charset=UTF-8');
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(error));
        RestContext.response.statusCode = 500;
    }
}