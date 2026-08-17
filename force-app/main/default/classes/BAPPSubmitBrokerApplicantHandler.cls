/*
* @Author        : Rushikesh Jadhav
* @CreatedDate   : 26th MAY 2025
* @Description   : Handles creation and update of Broker Applicant records via REST API. 
*                  Performs validation, role processing, and updates associated Broker Application metadata.
*/
/*****************************************************************************************************
* Version       Author        Date             Comment                                                                       
* 1.0           Rushikesh     26-MAY-2025      Initial draft to handle applicant submission for broker applications
*****************************************************************************************************/
public class BAPPSubmitBrokerApplicantHandler {
    
    public class ApplicantRequest {
        public String applicationId;
        public String registrationStatus;
        public String currentScreen;
        public Boolean isRfiUpdate; 
        public String typeOfEstablishment;
        public List<BrokerApplicantData> companyPersonnel;
    }

    public class BrokerApplicantData {
        public String applicantId;
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
    }
	 /**
     * Entry point to handle applicant submission.
     * Deserializes the request, delegates to business logic, and prepares response.
     */
    public static void handleBrokerApplicant(String requestBody) {
        try {
            BAPPSubmitBrokerApplicantHandler.ApplicantRequest req = 
                (BAPPSubmitBrokerApplicantHandler.ApplicantRequest)
                JSON.deserialize(requestBody, BAPPSubmitBrokerApplicantHandler.ApplicantRequest.class);

            Map<String, Object> finalResponse = createOrUpdateApplicants(req);

            if (String.valueOf(finalResponse.get('status')) == 'success') {
                makeSuccessResponse(finalResponse);
            } else {
                makeErrorResponse(finalResponse);
            }

        } catch (Exception e) {
            System.debug('Exception in handleBrokerApplicant: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());

           /*makeServerErrorResponse(new Map<String, Object>{
                'status' => 'error',
                    'message' => e.getMessage()
                    });*/
            Map<String, Object> errorMap = new Map<String, Object>();
            makeServerErrorResponse(e);
        }
    }
    /**
     * Creates or updates broker applicants based on the request.
     * Handles validations, DML, and response structuring.
     */
    public static Map<String, Object> createOrUpdateApplicants(ApplicantRequest req) {
        List<Map<String, Object>> successResponses = new List<Map<String, Object>>();
        List<Map<String, Object>> errorResponses = new List<Map<String, Object>>();
        List<BrokerApplicant__c> toInsert = new List<BrokerApplicant__c>();
        List<BrokerApplicant__c> toUpdate = new List<BrokerApplicant__c>();

        Boolean hasErrors = false;
        Boolean isSuperAdminSet = false;
        String typeOfEstablishments = req.typeOfEstablishment != null ? req.typeOfEstablishment.toLowerCase() : '';
        
		  
         // Check existing SuperAdmin
        if (String.isNotBlank(req.applicationId)) {
            List<BrokerApplicant__c> existingApplicants = 
                BrokerApplicantService.getInstance().getExistingApplicantsByApplicationId(req.applicationId);
            for (BrokerApplicant__c existing : existingApplicants) {
                if (existing.IsSuperAdmin__c) {
                    isSuperAdminSet = true;
                    break;
                }
            }
        }
        if (String.isBlank(req.applicationId)) {
            return new Map<String, Object>{
                'status' => 'error',
                'message' => 'Application Id is required.'
            };
        }
        // NEW: Collect emails from request & query existing applicants by email
        // ------------------------------
        Set<String> requestEmails = new Set<String>();
        for (BrokerApplicantData applicant : req.companyPersonnel) {
            if (String.isNotBlank(applicant.email)) {
                requestEmails.add(applicant.email.trim().toLowerCase());
            }
        }
    
        Map<String, Id> existingEmailToId = new Map<String, Id>();
        if (!requestEmails.isEmpty()) {
            List<BrokerApplicant__c> existingByEmail =
                BrokerApplicantService.getInstance().getApplicantsByEmails(req.applicationId, requestEmails);
            for (BrokerApplicant__c existing : existingByEmail) {
                if (String.isNotBlank(existing.Email__c)) {
                    existingEmailToId.put(existing.Email__c.toLowerCase(), existing.Id);
                }
            }
        }

        // Process each applicant from the request
        for (BrokerApplicantData applicant : req.companyPersonnel) {
            // Validate fields
            List<Map<String, String>> fieldErrors = validateApplicant(applicant,typeOfEstablishments);

            Map<String, Object> res = new Map<String, Object>{
                'fullName' => (applicant.firstName != null ? applicant.firstName : '') + ' ' + (applicant.lastName != null ? applicant.lastName : ''),
                'role' => applicant.role,
                'applicantId' => applicant.applicantId
            };
                // --- NEW: Application & Applicant validation ---
            if (String.isNotBlank(applicant.applicantId)) {
                BrokerApplicant__c existingApplicant = BrokerApplicantService.getInstance()
                    .getApplicantById(applicant.applicantId);
        
                if (existingApplicant == null || existingApplicant.BrokerApplication__c != req.applicationId) {
                    fieldErrors.add(new Map<String, String>{
                        'field' => 'applicantId/applicationId',
                        'error' => Label.BAPP_InvalidAgencyOrAgent
                    });
        
                    res.put('fieldErrors', fieldErrors);
                    res.put('status', 'error');
                    res.put('message', 'Validation failed for applicant');
                    errorResponses.add(res);
                    hasErrors = true;
                    continue;
                }
            }
                
                // NEW: Duplicate email validation
            // ------------------------------
            if (String.isNotBlank(applicant.email) &&
                existingEmailToId.containsKey(applicant.email.trim().toLowerCase()) &&
                String.isBlank(applicant.applicantId)) {
    
                fieldErrors.add(new Map<String, String>{
                    'field' => 'email',
                    'error' => 'User with same mail id already exist , please try with another mail id'
                });
    
                res.put('fieldErrors', fieldErrors);
                res.put('status', 'error');
                res.put('message', 'Validation failed for applicant');
                errorResponses.add(res);
                hasErrors = true;
                continue;
            }
            // Extract and normalize roles  
            Set<String> roleSet = new Set<String>();
                if (String.isNotBlank(applicant.role)) {
                    for (String ro : applicant.role.split(';')) {
                        roleSet.add(ro.trim().toLowerCase());
                    }
                }
            //clean roles (comma to semicolon separated)
            String cleanedRoles = '';
            if (!roleSet.isEmpty()) {
                cleanedRoles = String.join(new List<String>(roleSet), ';');
            }

            // If validation errors, add to error list
            if (!fieldErrors.isEmpty()) {
                res.put('fieldErrors', fieldErrors);
                res.put('status', 'error');
                res.put('message', 'Validation failed for ' + (applicant.role != null ? applicant.role : 'applicant'));
                errorResponses.add(res);
                hasErrors = true;
                continue;
            }

            // Create new record or update existing
            BrokerApplicant__c record = new BrokerApplicant__c(
                Email__c = applicant.email,
                PhoneNumber__c = applicant.phoneNumber,
                Title__c = applicant.title,
                FirstName__c = applicant.firstName,
                MiddleName__c = applicant.middleName,
                LastName__c = applicant.lastName,
                NationalID__c = applicant.nationalId,
                NationalIDExpiryDate__c = String.isNotBlank(applicant.nationalIdExpiryDate) ? Date.valueOf(applicant.nationalIdExpiryDate) : null,
                DateOfBirth__c = String.isNotBlank(applicant.dateOfBirth) ? Date.valueOf(applicant.dateOfBirth) : null,
                ShareHoldingPercentage__c = applicant.shareHoldingPercentage,
                Designation__c = applicant.designation,
                BrokerContactRole__c = cleanedRoles,
                Country__c = applicant.country,
                CountryCode__c = applicant.countryCode,
                BrokerApplication__c = req.applicationId,
                 // Role-based checkboxes
                isAdmin__c = roleSet.contains('admin'),
                IsAuthorizedSignatory__c = roleSet.contains('authorizedsignatoryofficer'),
                IsCEO__c = roleSet.contains('ceo'),
                IsPartner__c = roleSet.contains('partner'),
                IsOwner__c = roleSet.contains('owner'),
                IsFinancialAdmin__c = roleSet.contains('financialadmin'),
                IsAgent__c = roleSet.contains('agent'),
                //International
                TypeofEstablishment__c = typeOfEstablishments,
                PassportNumber__c = applicant.passportNumber,
                PassportExpiryDate__c = String.isNotBlank(applicant.passportExpiryDate) ? Date.valueOf(applicant.passportExpiryDate) : null
                
            );

            // Mark first isAdmin as SuperAdmin
            if (!isSuperAdminSet && applicant.role != null && applicant.role.toLowerCase().contains('admin')) {
                record.IsSuperAdmin__c = true;
                isSuperAdminSet = true;
            }
			// Add record to insert or update list
            if (String.isNotBlank(applicant.applicantId)) {
                
                record.Id = applicant.applicantId;
                toUpdate.add(record);
            } else {
                toInsert.add(record);
            }

            // Success response for this applicant (Id to be assigned after insert)
            res.put('status', 'success');
            res.put('message', 'Applicant registered successfully.');
            successResponses.add(res);
        }
        // Upsert records
            BrokerApplicantService.getInstance().insertApplicants(toInsert);
            BrokerApplicantService.getInstance().updateApplicants(toUpdate);
		
        // Broker Applicant Documents 
        Set<Id> parentIds = new Set<Id>();
        for (BrokerApplicant__c ba : toInsert) {
            parentIds.add(ba.Id);
        }
        for (BrokerApplicant__c ba : toUpdate) {
            parentIds.add(ba.Id);
        }
        Map<Id, List<Map<String, String>>> docsByApplicant = new Map<Id, List<Map<String, String>>>();
        List<Document__c> existingDocs = DocumentService.getInstance().getExistingDocumentsForApplicant(parentIds);
        for (Document__c doc : existingDocs) {
            if (doc.BrokerApplicant__c == null) continue;

            if (!docsByApplicant.containsKey(doc.BrokerApplicant__c)) {
                docsByApplicant.put(doc.BrokerApplicant__c, new List<Map<String, String>>());
            }

            docsByApplicant.get(doc.BrokerApplicant__c).add(new Map<String, String>{
                'id' => doc.Id,
                'type' => doc.DocumentType__r != null ? doc.DocumentType__r.Type__c : null
            });
        }
        //Broker application Documents

        Set<Id> parentId = new Set<Id>{ req.applicationId};
        List<Document__c> existDocs = DocumentService.getInstance().getExistingDocuments(parentId);
        List<Map<String, String>> documents = new List<Map<String, String>>();
            for (Document__c doc : existDocs) {
                documents.add(new Map<String, String>{
                    'id' => doc.Id,
                    'type' => doc.DocumentType__r != null ? doc.DocumentType__r.Type__c : null
                });
            }
        // Assign newly generated Ids to success responses
        Integer insertIndex = 0;
        for (Map<String, Object> res : successResponses) {
            Id applicantId;
            // Assign applicant Id for inserted records
            if (!res.containsKey('applicantId') || String.isBlank(String.valueOf(res.get('applicantId')))) {
                if (insertIndex < toInsert.size()) {
                    applicantId = toInsert[insertIndex].Id;
           			res.put('applicantId', applicantId);
                    insertIndex++;
                }
            } else {
                applicantId = (Id)res.get('applicantId');
            }
            // Attach applicant documents
            if (applicantId != null && docsByApplicant.containsKey(applicantId)) {
                res.put('documents', docsByApplicant.get(applicantId));
            } else {
                res.put('documents', new List<Map<String, String>>());
            }
        }

        // Update BrokerApplication with isRfiUpdate flag & registrationStatus
        if (String.isNotBlank(req.applicationId)) {
            BrokerApplication__c appUpdate = new BrokerApplication__c(
                Id = req.applicationId,
                IsRFIUpdated__c = req.isRfiUpdate,
                ApprovalStatus__c = req.registrationStatus
            );
            BrokerApplicationService.getInstance().updateBrokerApplications(new List<BrokerApplication__c>{ appUpdate });
        }
        BrokerApplication__c app = BrokerApplicantService.getInstance().getApplicationDetails(req.applicationId);
        String applicationNumber = app.ApplicationNumber__c;
        String typeOfEstablishment = app.TypeofEstablishment__c;
        
        if (!successResponses.isEmpty() && !errorResponses.isEmpty()) {
            return new Map<String, Object>{
                'data' => successResponses,
                'errors' => errorResponses,
                'applicationId' => req.applicationId,
                'applicationNumber' => applicationNumber,
                'applicationDocuments' => documents,
                'message' => 'One or more personnel records failed validation.',
                'status' => 'partial_success'
            };
        } else if (!successResponses.isEmpty()) {
            return new Map<String, Object>{
                
                'data' => successResponses,
                'applicationId' => req.applicationId,
                'applicationNumber' => applicationNumber,
                'applicationDocuments' => documents,
                'message' => 'All personnel created successfully.',
                'status' => 'success'
            };
        } else {
            return new Map<String, Object>{
                'errors' => errorResponses,
                'applicationId' => req.applicationId,    
                'applicationDocuments' => documents,
                'message' => 'All personnel records failed validation.',    
                'status' => 'error'
            };
        }
    }

    // Validation method
    private static List<Map<String, String>> validateApplicant(BrokerApplicantData applicant,String typeOfEstablishment) {
        List<Map<String, String>> errors = new List<Map<String, String>>();
        checkRequired(applicant.role, 'role', Label.BAAP_ApplicantRoleRequired, errors);
        checkRequired(applicant.title, 'title', Label.BAAP_ApplicantTitleRequired, errors);
        checkRequired(applicant.firstName, 'firstName', Label.BAAP_ApplicantFirstNameRequired, errors);
        checkRequired(applicant.lastName, 'lastName', Label.BAAP_ApplicantLastNameRequired, errors);
        checkRequired(applicant.phoneNumber, 'phoneNumber', Label.BAAP_ApplicantPhoneNumberRequired, errors);
        checkRequired(applicant.email, 'email', Label.BAAP_ApplicantEmailRequired, errors);
        checkRequired(typeOfEstablishment, 'typeOfEstablishment', 'typeOfEstablishment is required', errors);
        if (!String.isBlank(applicant.role) &&( applicant.role.contains('Admin'))){
            checkRequired(applicant.dateOfBirth, 'dateOfBirth', Label.BAAP_ApplicantDOBRequired, errors);
        }
        checkRequired(applicant.countryCode, 'countryCode', Label.BAAP_CountryCodeRequired, errors);
        if (!String.isBlank(applicant.role) &&(applicant.role.contains('Partner') || applicant.role.contains('Owner'))) {
        	checkRequired(applicant.shareHoldingPercentage, 'shareHoldingPercentage', Label.BAAP_ApplicantShareHoldingRequired, errors);
            checkRequired(applicant.country, 'country', Label.BAAP_CountryRequired, errors);
        }
        if (!String.isBlank(applicant.role) &&(applicant.role.contains('AuthorizedSignatoryOfficer'))) {
        	checkRequired(applicant.country, 'country', Label.BAAP_CountryRequired, errors);
            checkRequired(applicant.designation, 'designation', Label.BAPP_DesignationRequired, errors);
        }
        if (typeOfEstablishment == 'international') {
            checkRequired(applicant.passportNumber, 'passportNumber', 'Passport Number is required for international applicants.', errors);
    		checkRequired(applicant.passportExpiryDate, 'passportExpiryDate', 'Passport Expiry Date is required for international applicants.', errors);
        }else if (typeOfEstablishment == 'domestic') {
            checkRequired(applicant.nationalId, 'nationalId', Label.BAAP_ApplicantNationalIdRequired, errors);
        	checkRequired(applicant.nationalIdExpiryDate, 'nationalIdExpiryDate', Label.BAAP_ApplicantNationalIdExpiryRequired, errors);
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
        //Success Response
    public static void makeSuccessResponse(Map<String, Object> response) { 
        RestContext.response.addHeader('Content-Type', 'application/json;charset=UTF-8');
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(response));
        RestContext.response.statusCode = 200;
    }
	//Error Response
    public static void makeErrorResponse(Map<String, Object> error) {
        RestContext.response.addHeader('Content-Type', 'application/json;charset=UTF-8');
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(error));
        RestContext.response.statusCode = 400;
    }
    // Server Error Response
    /*public static void makeServerErrorResponse(Map<String, Object> error) {
        error.put('status', 'error');
        error.put('message', 'Server Error');
        RestContext.response.addHeader('Content-Type', 'application/json;charset=UTF-8');
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(error));
        RestContext.response.statusCode = 500;
    }*/
    public static void makeServerErrorResponse(Exception ex) {
        Map<String, Object> error = new Map<String, Object>();
        String message = 'Unexpected server error';
        if (ex != null && String.isNotBlank(ex.getMessage())) {
            message = ex.getMessage();
            if (message.contains('first error:')) {
                message = message.substringAfter('first error:').trim();
            }
            if (message.contains(',')) {
                message = message.substringAfter(',').trim();
            }
            if (message.contains(': []')) {
                message = message.replace(': []', '');
            }
        }
        error.put('status', 'error');
        error.put('message', message);
        RestContext.response.addHeader('Content-Type', 'application/json;charset=UTF-8');
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(error));
        RestContext.response.statusCode = 500;
    }
}