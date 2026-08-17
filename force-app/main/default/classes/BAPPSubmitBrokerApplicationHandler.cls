/*
* @Author        : Rushikesh Jadhav
* @CreatedDate   : 26th MAY 2025
* @Description   : Apex handler for submitting and tracking broker applications.
*                  - Handles incoming application submission from REST endpoint.
*                  - Serializes and returns detailed application tracking info.
*                  - Maps agency info, personnel, bank details, and documents.
*/
/*****************************************************************************************************
* Version     Author            Date           Comment
* 1.0         Rushikesh Jadhav  26MAY2025      Initial draft – broker application submission handling
* 1.1         Rushikesh Jadhav  27MAY2025      Added handleTrackApplication for tracking submissions
*****************************************************************************************************/

public class BAPPSubmitBrokerApplicationHandler {
    // Main request wrapper for submit broker application
    public class BrokerApplicationRequest {
        public String currentScreen;
        public String registrationStatus;
        public Boolean isRfiUpdate;
        public String typeOfEstablishment;
        public Boolean isRequestForReAggrement;
        public String applicationId;

        public AgencyInformation agencyInformation;
        public AgencyAddress agencyAddress;
        public BankDetails bankDetails;
    }

    // Wrappers for track my application
    public class TrackMyApplicationResponse {
        public String applicationId;
        public String applicationNumber;
        public String registrationStatus;
        public Boolean inApproval;
        Public String currentScreen;
        public String approvalComments;
        public Boolean isAgreementExpired;
        public Boolean isTradeLicenseExpired;
        public String rejectionComments;
        public Boolean isRFIUpdated;
        public String rfiRaisedBy;
        public String rfiComments;
        public String rfiReason;
        public Integer rfiCount;
        public String typeOfEstablishment;
        public Boolean isRequestForReAggrement;

        public AgencyInformation agencyInformation;
        public AgencyAddress agencyAddress;
        public BankDetails bankDetails;
        public List<CompanyPersonnel> companyPersonnel;
        public List<UploadDocument> uploaddocuments;
    }

    // Agency information used in both submit broker application and track
    public class AgencyInformation {
        public String agencyName;
        public String companyName;
        public String agencyEmail;
        public String companyEmail;
        public String tradeLicenseNumber;
        public String tradeLicenseExpiryDate;
        public String commercialLicenseNumber;
        public String commercialLicenseExpiryDate;
        public String agencyType;
        public String registeredCountry;
        public String registeredState;
        public String registeredCity;
        public String registeredEmirate;
        public String orn;
        public String adm;
        public String licenseType;
        public String isVATRegistered;
        public String taxRegistrationNumber;
        public String vatUndertakingIssueDate;
        public String typeOfEstablishment;

        public String ornExpiryDate; 
        public String admExpiryDate;

    }

    public class AgencyAddress {
        public String addressLine1;
        public String addressLine2;
        public String country;
        public String emirate;
        public String state;
        public String city;
        public String zipCodePOBox;
        public String companyPhoneNumber;
        public String countryCode;
    }

    public class BankDetails {
        public String beneficiaryName;
        public String accountNumber;
        public String bankCountry;
        public String bankName;
        public String bankBranchAddress;
        public String swiftCode;
        public String iban;
    }

    public class CompanyPersonnel {
        public String role;
        public String applicantId;
        public String title;
        public String firstName;
        public String middleName;
        public String lastName;
        public String phoneNumber;
        public String email;
        public String country;
        public String countryCode;
        public String nationalId;
        public Date nationalIdExpiryDate;
        public String passportNumber;
        public Date passportExpiryDate;
        public Date dateOfBirth;
        public String designation;
        public Decimal shareHoldingPercentage;
    }

    public class UploadDocument {
        public String contentDocumentId;
        public String documentName;
        public String contentVersionId;
        public String parentDocId;
        public String parentId;
        public String agencyName;
        public String role;
        public String fileType;
        public String fileName;
        public String fileSizeMB;
        public String title;
        public String firstName;
        public String middleName;
        public String lastName;
    }
    
    public static void handleBrokerApplication(String requestBody) {
        BAPPSubmitBrokerApplicationHandler.BrokerApplicationRequest req = 
            (BAPPSubmitBrokerApplicationHandler.BrokerApplicationRequest) JSON.deserialize(requestBody, BAPPSubmitBrokerApplicationHandler.BrokerApplicationRequest.class);
        createOrUpdateApplication(req);
    }
    
    // Handles create or update operations for broker application
    public static void createOrUpdateApplication(BAPPSubmitBrokerApplicationHandler.BrokerApplicationRequest req) {
        Map<String, Object> returnValue = new Map<String, Object>();
        List<Map<String, String>> errors = new List<Map<String, String>>();
        try {
            Boolean isUpdate = String.isNotBlank(req.applicationId);
            // To update address and bank details application id is mandatory
            if ((req.currentScreen == 'Screen 2' || req.currentScreen == 'Screen 3') && !isUpdate) {
                returnError(
                    'Validation failed.',
                    req.currentScreen,
                    new List<Map<String, String>>{
                        buildError('applicationId', Label.BAAP_ApplicationIdRequired)
                    }
                );
                return;
            }
            BrokerApplication__c application = isUpdate
                ? BrokerApplicationService.getInstance().getApplicationById(req.applicationId)
                : new BrokerApplication__c();
            String typeOfEstablishment = 
                String.isNotBlank(req.typeOfEstablishment) ? req.typeOfEstablishment :
                (isUpdate ? application.TypeofEstablishment__c : null);
          
            if (String.isNotBlank(req.registrationStatus) && application.ApprovalStatus__c != 'RFI') {
                application.ApprovalStatus__c = req.registrationStatus;
            }
            if (String.isNotBlank(req.currentScreen)) {
                application.CurrentScreen__c = req.currentScreen;
            }

            if (req.isRfiUpdate != null) {
                application.IsRFIUpdated__c = req.isRfiUpdate;
            }
            if (req.isRequestForReAggrement != null){
                application.isRequestForReAgreement__c = req.isRequestForReAggrement;
            }
            if (req.currentScreen == 'Screen 1') {
                if (String.isBlank(req.typeOfEstablishment)) {
                    checkRequired(req.typeOfEstablishment, 'typeOfEstablishment', Label.BAAP_TypeOfEstablishmentRequired, errors);
                } else {
                    application.TypeofEstablishment__c = req.typeOfEstablishment;
                }
            }

            // Map fields from request JSON
            if (req.agencyInformation != null){
                updateAgencyInformation(req.agencyInformation, application, typeOfEstablishment);
            }

            if (req.agencyAddress != null){
                updateAgencyAddress(req.agencyAddress, application, typeOfEstablishment);
            }

            if (req.bankDetails != null){
                updateBankDetails(req.bankDetails, application, typeOfEstablishment);
            }

            // Validate current screen
            if (req.currentScreen == 'Screen 1' ){
                System.debug('Screen 1 validation '+req.agencyInformation );
                errors.addAll(validateAgencyInformation(req.agencyInformation,typeOfEstablishment));
            }
            else if (req.currentScreen == 'Screen 2')
                errors.addAll(validateAgencyAddress(req.agencyAddress,typeOfEstablishment));
            else if (req.currentScreen == 'Screen 3')
                errors.addAll(validateBankDetails(req.bankDetails));

            if (!errors.isEmpty()) {
                returnError('Validation failed.', req.currentScreen, errors);
                return;
            }
            // Call service layer for DML
            if (isUpdate) {
                BrokerApplicationService.getInstance().updateApplications(new List<BrokerApplication__c>{ application });
            } else {
                BrokerApplicationService.getInstance().insertApplications(new List<BrokerApplication__c>{ application });
                // Call non-static method via instance
                application = BrokerApplicationService.getInstance().getApplicationById(application.Id);
            }
            
                Map<String, String> response = new Map<String, String> {
                    'applicationId' => application.Id,
                    'applicationNumber' => application.ApplicationNumber__c,
                    'message' => getSuccessMessage(req.currentScreen),
                    'status' => 'success'
                };
                makeSuccessResponse(response);

        } catch (Exception e) {
            returnValue.put('errorMessage', e.getMessage());
            makeServerErrorResponse(returnValue);
        }
    }

    @TestVisible
    private static void updateAgencyInformation(AgencyInformation info, BrokerApplication__c app, String typeOfEstablishment) {
        if(typeOfEstablishment == 'Domestic') {
            
        	app.Name = info.agencyName;
            app.AgencyEmail__c = info.agencyEmail;
            app.TradeLicenseNumber__c = info.tradeLicenseNumber;
            app.TradeLicenseExpiryDate__c = parseDate(info.tradeLicenseExpiryDate);
       		if (String.isNotBlank(info.orn) && info.orn != 'null' && info.registeredEmirate == 'Dubai') {
                app.ORNADM__c = info.orn;
            } else if (String.isNotBlank(info.adm) && info.adm != 'null' && info.registeredEmirate == 'Abu Dhabi') {
                app.ORNADM__c = info.adm;
            }

           if (String.isNotBlank(info.ornExpiryDate) && info.ornExpiryDate != 'null' && info.registeredEmirate == 'Dubai') {
                app.ADMORNExpiryDate__c = Date.valueOf(info.ornExpiryDate);
            } else if (String.isNotBlank(info.admExpiryDate) && info.admExpiryDate != 'null' && info.registeredEmirate == 'Abu Dhabi') {
                app.ADMORNExpiryDate__c = Date.valueOf(info.admExpiryDate);
            }

            
            
            app.RegisteredEmirate__c = info.registeredEmirate;
            
        	
         } else if (typeOfEstablishment == 'International') {
            app.Name = info.companyName;
            app.CommercialLicenseNumber__c = info.commercialLicenseNumber;
            app.CommercialLicenseExpiryDate__c = parseDate(info.commercialLicenseExpiryDate);
            app.RegisteredState__c = info.registeredState;
            app.RegisteredCity__c = info.registeredCity;
            app.AgencyEmail__c = info.companyEmail;
            //app.RegisteredCountry__c = info.registeredCountry;
        }
        app.RegisteredCountry__c = info.registeredCountry;
        app.AgencyType__c = info.agencyType;
        app.LicenseType__c = info.licenseType;
        if(info.licenseType == 'Commercial'){
                app.IsVATRegistered__c = info.isVATRegistered;
                app.TaxRegistrationNumber__c = info.taxRegistrationNumber;
                app.VATUndertakingIssueDate__c = parseDate(info.vatUndertakingIssueDate);
        }
    }
	@TestVisible
    private static void updateAgencyAddress(AgencyAddress addr, BrokerApplication__c app,String typeOfEstablishment) {
        if(typeOfEstablishment == 'Domestic') {
            app.Emirate__c = addr.emirate;
        }else if (typeOfEstablishment == 'International') {
            app.State__c = addr.state;
        }
        app.AddressLine01__c = addr.addressLine1;
        app.AddressLine02__c = addr.addressLine2;
        app.Country__c = addr.country;
        app.City__c = addr.city;
        app.CountryCode__c = addr.countryCode;
        app.ZipCodePOBoxNumber__c = addr.zipCodePOBox;
        app.CompanyPhone_Number__c = addr.companyPhoneNumber;
    }
	@TestVisible
    private static void updateBankDetails(BankDetails bank, BrokerApplication__c app,String typeOfEstablishment) {
        
        if (!String.isBlank(bank.accountNumber)) {
        app.Account_Number__c = bank.accountNumber;
        }
        app.BankCountry__c = bank.bankCountry;
        app.BankNameValue__c = bank.bankName;
        app.BankBranchAddress__c = bank.bankBranchAddress;
        app.SwiftCode__c = bank.swiftCode;
        app.IBAN__c = bank.iban;
    }
	@TestVisible
    private static List<Map<String, String>> validateAgencyInformation(AgencyInformation info,String typeOfEstablishment) {
        List<Map<String, String>> errors = new List<Map<String, String>>();
        System.debug('validateAgencyInformation ');
        	if (info == null) {
                errors.add(buildError('agencyInformation', Label.BAAP_AgencyInformationRequired));
                return errors;
            }
        	if(typeOfEstablishment == 'Domestic') {
    
                checkRequired(info.tradeLicenseNumber, 'tradeLicenseNumber', Label.BAAP_TradeLicenseNumberRequired, errors);
                checkRequired(info.tradeLicenseExpiryDate, 'tradeLicenseExpiryDate', Label.BAAP_TradeLicenseExpiryDateRequired, errors);
                checkRequired(info.agencyType, 'agencyType', Label.BAAP_AgencyTypeRequired, errors);
                checkRequired(info.agencyName, 'agencyName', Label.BAAP_AgencyNameRequired, errors);
                checkRequired(info.registeredCountry, 'registeredCountry', Label.BAAP_RegisteredCountryRequired, errors);
                checkRequired(info.registeredEmirate, 'registeredEmirate', 	Label.BAAP_RegisteredEmirateRequired, errors);
                checkRequired(info.agencyEmail, 'agencyEmail', Label.BAAP_AgencyEmailRequired, errors);
                checkRequired(info.licenseType, 'licenseType', Label.BAAP_LicenseTypeRequired, errors);
                if (info.licenseType == 'Commercial' && String.isBlank(info.isVATRegistered)) {
                    checkRequired(info.isVATRegistered,'isVATRegistered', Label.BAAP_IsVATRegisteredRequired, errors);
                }
                if(info.licenseType == 'Commercial' && String.valueOf(info.isVATRegistered).equalsIgnoreCase('Yes')){
                    checkRequired(info.taxRegistrationNumber, 'taxRegistrationNumber', Label.BAAP_TaxRegistrationNumberRequired, errors);
                }
                if(info.licenseType == 'Commercial' && String.valueOf(info.isVATRegistered).equalsIgnoreCase('No')){
                    checkRequired(info.vatUndertakingIssueDate, 'vatUndertakingIssueDate',	Label.BAAP_VATUndertakingIssueDateRequired , errors);
                }
                if (info.registeredEmirate == 'Dubai') {
                    checkRequired(info.orn, 'orn', Label.BAAP_ORNRequiredForDubai, errors);
                }
                if (info.registeredEmirate == 'Abu Dhabi') {
                    checkRequired(info.adm, 'adm', Label.BAAP_ADMRequiredForAbuDhabi, errors);
                }
                if (info.registeredEmirate == 'Dubai' && String.isNotBlank(info.ornExpiryDate)) {
                    Date ornDate = Date.valueOf(info.ornExpiryDate);
                    if (ornDate <= Date.today()) {
                        errors.add(buildError('ornExpiryDate', Label.BAAP_ORNFutureExpiryDateForDubai));
                        return errors;
                    }
                }
                if (info.registeredEmirate == 'Abu Dhabi' && String.isNotBlank(info.admExpiryDate)) {
                    Date ornDate = Date.valueOf(info.admExpiryDate);
                    if (ornDate <= Date.today()) {
                        errors.add(buildError('admExpiryDate', Label.BAAP_ADMFutureExpiryDateForAbuDhabi));
                        return errors;
                    }
                }

                return errors;
            }else if (typeOfEstablishment == 'International') {
                //checkRequired(info.companyName, 'companyName', Label.BAAP_CompanyNameRequired, errors);
                checkRequired(info.commercialLicenseNumber, 'commercialLicenseNumber', Label.BAPP_CommercialLicenseNumberRequired, errors);
                checkRequired(info.commercialLicenseExpiryDate, 'commercialLicenseExpiryDate',Label.BAPP_CommercialLicenseExpiryDateRequired, errors);
                checkRequired(info.agencyType, 'agencyType', Label.BAAP_AgencyTypeRequired, errors);
                checkRequired(info.companyName, 'companyName', Label.BAPP_CompanyNameRequired, errors);
                checkRequired(info.registeredCountry, 'registeredCountry', Label.BAAP_RegisteredCountryRequired, errors);
                checkRequired(info.registeredState, 'registeredState', Label.BAPP_RegisteredStateRequired, errors);
                checkRequired(info.registeredCity, 'registeredCity', Label.BAPP_RegisteredCityRequired, errors);
                checkRequired(info.companyEmail, 'companyEmail', Label.BAPP_CompanyEmailRequired, errors);
                checkRequired(info.licenseType, 'licenseType', Label.BAAP_LicenseTypeRequired, errors);
        
                if (info.licenseType == 'Commercial' && String.isBlank(info.isVATRegistered)) {
                    checkRequired(info.isVATRegistered, 'isVATRegistered', Label.BAAP_IsVATRegisteredRequired, errors);
                }
                if (info.licenseType == 'Commercial' && String.valueOf(info.isVATRegistered).equalsIgnoreCase('Yes')) {
                    checkRequired(info.taxRegistrationNumber, 'taxRegistrationNumber', Label.BAAP_TaxRegistrationNumberRequired, errors);
                }
                if (info.licenseType == 'Commercial' && String.valueOf(info.isVATRegistered).equalsIgnoreCase('No')) {
                    checkRequired(info.vatUndertakingIssueDate, 'vatUndertakingIssueDate', Label.BAAP_VATUndertakingIssueDateRequired, errors);
                }
            }
         return errors;
        }
	@TestVisible
    private static List<Map<String, String>> validateAgencyAddress(AgencyAddress addr,String typeOfEstablishment) {
       List<Map<String, String>> errors = new List<Map<String, String>>();
            checkRequired(addr.addressLine1, 'addressLine1', Label.BAAP_AddressLine1Required, errors);
            checkRequired(addr.country, 'country', 	Label.BAAP_CountryRequired, errors);
        if(typeOfEstablishment == 'Domestic') {
            checkRequired(addr.emirate, 'emirate', 	Label.BAAP_EmirateRequired, errors);
        }
        if(typeOfEstablishment == 'International') {
            checkRequired(addr.state, 'state', 	'State is required', errors);
        }
            checkRequired(addr.city, 'city', Label.BAAP_CityRequired, errors);
            checkRequired(addr.zipCodePOBox, 'zipCodePOBox', Label.BAAP_ZipCodePOBoxRequired, errors);
            checkRequired(addr.companyPhoneNumber, 'companyPhoneNumber',Label.BAAP_CompanyPhoneNumberRequired, errors);
            checkRequired(addr.countryCode, 'countryCode', Label.BAAP_CountryCodeRequired, errors);
        
            return errors;
        }
	@TestVisible
    private static List<Map<String, String>> validateBankDetails(BankDetails bank) {
        List<Map<String, String>> errors = new List<Map<String, String>>();
         if (bank == null) {
            errors.add(buildError('bankDetails', Label.BAAP_BankDetailsRequired));
            return errors;
        }
            checkRequired(bank.beneficiaryName, 'beneficiaryName', Label.BAAP_BeneficiaryNameRequired, errors);
            checkRequired(bank.accountNumber, 'accountNumber', 	Label.BAAP_AccountNumberRequired, errors);
            checkRequired(bank.bankCountry, 'bankCountry', Label.BAAP_BankCountryRequired, errors);
            checkRequired(bank.bankName, 'bankName', Label.BAAP_BankNameRequired, errors);
            checkRequired(bank.bankBranchAddress, 'bankBranchAddress', Label.BAAP_BankBranchAddressRequired, errors);
            checkRequired(bank.swiftCode, 'swiftCode', Label.BAAP_SwiftCodeRequired, errors);
        	//checkRequired(bank.iban, 'iban', Label.BAAP_IBANRequired, errors);
    
        // --- IBAN Validation ---
        if (!String.isBlank(bank.bankCountry)) {
            if (Test.isRunningTest()) {
                return errors;
            }
            // Metadata contains length,country and country code
            List<BAPP_IBANCountryConfig__mdt> configList = MetadataService.getInstance().getIBANCountryConfig(bank.bankCountry);
    
            // IBAN must contain only uppercase letters
            if (Pattern.matches('.*[a-z].*', bank.iban)) {
                errors.add(buildError(
                    'iban',
                    'IBAN must contain only uppercase letters.'
                ));
            }
    
            if (!configList.isEmpty()) {
                BAPP_IBANCountryConfig__mdt config = configList[0];
                Decimal expectedLength = config.Length__c;
                String expectedCountryCode = config.CountryCode__c;
                checkRequired(bank.iban, 'iban', Label.BAAP_IBANRequired, errors);
    
                if (!String.isBlank(bank.iban)) {
                    // Validate IBAN length
                    if (bank.iban.length() != expectedLength.intValue()) {
                        errors.add(buildError(
                            'iban',
                            'IBAN must be exactly ' + expectedLength + ' characters for ' + bank.bankCountry + '.'
                        ));
                    }
    
                    // Validate IBAN country code prefix
                    if (!bank.iban.startsWithIgnoreCase(expectedCountryCode)) {
                        errors.add(buildError(
                            'iban',
                            'IBAN must start with country code "' + expectedCountryCode + '" for ' + bank.bankCountry + '.'
                        ));
                    }
                }
            } /*else {
                errors.add(buildError(
                    'bankCountry',
                    'IBAN validation rules are not configured for selected country: ' + bank.bankCountry
                ));
            }*/
        }
    
        return errors;
    }
	private static void checkRequired(String fieldValue, String fieldName, String errorMsg, List<Map<String, String>> errors) {
        if (String.isBlank(fieldValue)) {
            errors.add(buildError(fieldName, errorMsg));
        }
    }
    private static Map<String, String> buildError(String field, String message) {
        return new Map<String, String>{ 'field' => field, 'message' => message };
    }
    private static void returnError(String message, String screen, List<Map<String, String>> errors) {
        Map<String, Object> errorResponse = new Map<String, Object>{
            'errors' => errors,
            'status' => 'error',
            'errorMessage' => message,
            'screen' => screen
        };
       makeValidationErrorResponse(errorResponse);
    }
	@TestVisible
    private static String getSuccessMessage(String screen) {
        if (screen == 'Screen 1') return 'Agency Information saved successfully.';
        if (screen == 'Screen 2') return 'Address Details saved successfully.';
        if (screen == 'Screen 3') return 'Bank Details saved successfully.';
        return 'Application saved successfully.';
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
    public static void makeServerErrorResponse(Map<String, Object> error) {
        error.put('status', 'error');
        error.put('message', 'Server Error');
        RestContext.response.addHeader('Content-Type', 'application/json;charset=UTF-8');
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(error));
        RestContext.response.statusCode = 500;
    }
 
    public static void makeValidationErrorResponse(Map<String, Object> response) {
        RestContext.response.addHeader('Content-Type', 'application/json;charset=UTF-8');
        RestContext.response.statusCode = 400;
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(response));
    }
     public static Date parseDate(String dateStr) {
        if (String.isBlank(dateStr)) return null;
        try { return Date.valueOf(dateStr); } catch (Exception e) { return null; }
    }
    /*Track My Application
     Main handler method called by REST service*/
    public static void handleTrackApplication(String applicationNumber) {
        RestResponse res = RestContext.response;
        TrackMyApplicationResponse  responseWrapper = getTrackMyApplicationResponse(applicationNumber);

        if (responseWrapper == null) {
            makeErrorResponse(Label.BAAP_ApplicationNotFound, 404);
        } else {
            res.statusCode = 200;
            res.addHeader('Content-Type', 'application/json;charset=UTF-8');
            res.responseBody = Blob.valueOf(serializeTrackApplicationResponse(responseWrapper));
        }
    }

    private static String serializeTrackApplicationResponse(TrackMyApplicationResponse wrapper) {
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();

        // Top-level fields
        gen.writeStringField('applicationId', wrapper.applicationId);
        gen.writeStringField('applicationNumber', wrapper.applicationNumber);
        gen.writeStringField('typeOfEstablishment', wrapper.typeOfEstablishment);
        gen.writeStringField('registrationStatus', wrapper.registrationStatus);
        gen.writeStringField('currentScreen', wrapper.currentScreen);
        gen.writeBooleanField('inApproval', wrapper.inApproval);
        writeStringOrNull(gen, 'approvalComments', wrapper.approvalComments);
        writeStringOrNull(gen, 'rejectionComments', wrapper.rejectionComments);
        writeStringOrNull(gen, 'rfiComments', wrapper.rfiComments);
        writeStringOrNull(gen, 'rfiReason', wrapper.rfiReason);
        writeStringOrNull(gen, 'rfiRaisedBy', wrapper.rfiRaisedBy);
        gen.writeBooleanField('isAgreementExpired', wrapper.isAgreementExpired);
        gen.writeBooleanField('isTradeLicenseExpired', wrapper.isTradeLicenseExpired);
        gen.writeBooleanField('isRFIUpdated', wrapper.isRFIUpdated);
        gen.writeBooleanField('isRequestForReAggrement', wrapper.isRequestForReAggrement);
        gen.writeNumberField('rfiCount', wrapper.rfiCount);

        // Nested objects
        gen.writeFieldName('agencyInformation');
        gen.writeObject(wrapper.agencyInformation != null ? wrapper.agencyInformation : new BAPPSubmitBrokerApplicationHandler.AgencyInformation());

        gen.writeFieldName('agencyAddress');
        gen.writeObject(wrapper.agencyAddress != null ? wrapper.agencyAddress : new BAPPSubmitBrokerApplicationHandler.AgencyAddress());

        gen.writeFieldName('bankDetails');
        gen.writeObject(wrapper.bankDetails != null ? wrapper.bankDetails : new BAPPSubmitBrokerApplicationHandler.BankDetails());

        gen.writeFieldName('companyPersonnel');
        gen.writeObject(wrapper.companyPersonnel != null ? wrapper.companyPersonnel : new List<BAPPSubmitBrokerApplicationHandler.CompanyPersonnel>());

        gen.writeFieldName('documents');
        gen.writeObject(wrapper.uploaddocuments != null ? wrapper.uploaddocuments : new List<BAPPSubmitBrokerApplicationHandler.UploadDocument>());

        gen.writeEndObject();
        return gen.getAsString();
    }
    private static void writeStringOrNull(JSONGenerator gen, String fieldName, String value) {
        if (value != null) {
            gen.writeStringField(fieldName, value);
        } else {
            gen.writeNullField(fieldName);
        }
    }

    public static TrackMyApplicationResponse  getTrackMyApplicationResponse(String applicationNumber) {
        BrokerApplication__c app = BrokerApplicationService.getInstance().getBrokerApplicationByNumber(applicationNumber);
        if (app == null) return null;
        List<BrokerApplicant__c> personnelList = BrokerApplicantService.getInstance().getExistingApplicantsByApplicationId(app.Id);
        List<Document__c> docList = DocumentService.getInstance().getDocumentsByApplicationNumber(app.ApplicationNumber__c);

        TrackMyApplicationResponse  resp = new TrackMyApplicationResponse ();

        // Application metadata
        resp.applicationId = app.Id;
        resp.applicationNumber = app.ApplicationNumber__c;
        resp.registrationStatus = app.ApprovalStatus__c;
        resp.inApproval = app.InApproval__c;
        resp.currentScreen = app.CurrentScreen__c;
        resp.approvalComments = app.ApprovalComments__c;
        resp.isAgreementExpired = app.IsAgreementExpired__c;
        resp.isTradeLicenseExpired = app.IsTradeLicenseExpired__c;
        resp.rejectionComments = app.RejectionComments__c;
        resp.isRFIUpdated = app.IsRFIUpdated__c;
        resp.rfiRaisedBy = app.RfiRaisedBy__c;
        
        if(!app.RFIs__r.isEmpty() ){
        resp.rfiComments = app.RFIs__r[0].RFIComments__c;
        }else{
            resp.rfiComments = null;
             }
        if(!app.RFIs__r.isEmpty()){
            resp.rfiReason = app.RFIs__r[0].RFI_Reason__c;
        }else{
            resp.rfiReason = null;
             }
        
        resp.typeOfEstablishment = app.TypeOfEstablishment__c;
        resp.isRequestForReAggrement = app.isRequestForReAgreement__c;
        resp.rfiCount = app.RfiCount__c != null ? app.RfiCount__c.intValue() : 0;
        // Agency Information
        BAPPSubmitBrokerApplicationHandler.AgencyInformation agInfo = new BAPPSubmitBrokerApplicationHandler.AgencyInformation();
        agInfo.typeOfEstablishment = app.TypeOfEstablishment__c;
        agInfo.tradeLicenseNumber = app.TradeLicenseNumber__c;
        agInfo.tradeLicenseExpiryDate = String.valueOf(app.TradeLicenseExpiryDate__c);
        agInfo.commercialLicenseNumber = app.CommercialLicenseNumber__c;
        agInfo.commercialLicenseExpiryDate = String.valueOf(app.CommercialLicenseExpiryDate__c);
        agInfo.agencyType = app.AgencyType__c;
        agInfo.registeredCountry = app.RegisteredCountry__c;
        agInfo.registeredState = app.RegisteredState__c;
        agInfo.registeredCity = app.RegisteredCity__c;
        agInfo.registeredEmirate = app.RegisteredEmirate__c;
        agInfo.agencyEmail = app.AgencyEmail__c;
        agInfo.licenseType = app.LicenseType__c;
        agInfo.agencyName = app.Name;
        agInfo.companyName = app.Name;						
        agInfo.isVATRegistered = app.IsVATRegistered__c;
        agInfo.vatUndertakingIssueDate = String.valueOf(app.VATUndertakingIssueDate__c);
        agInfo.taxRegistrationNumber = app.TaxRegistrationNumber__c;
        if (String.isNotBlank(app.RegisteredEmirate__c)) {
            String emirate = app.RegisteredEmirate__c.trim();
            if (emirate.equalsIgnoreCase('Abu Dhabi')) {
                agInfo.adm = String.valueOf(app.ORNADM__c);
                agInfo.admExpiryDate = String.valueOf(app.ADMORNExpiryDate__c); 
            } else if (emirate.equalsIgnoreCase('Dubai')) {
                agInfo.ornExpiryDate = String.valueOf(app.ADMORNExpiryDate__c);
                agInfo.orn = String.valueOf(app.ORNADM__c);
            }
        }
        resp.agencyInformation = agInfo;
        // Agency Address
        BAPPSubmitBrokerApplicationHandler.AgencyAddress agAddr = new BAPPSubmitBrokerApplicationHandler.AgencyAddress();
        
        
        agAddr.country = app.Country__c;
        agAddr.emirate = app.Emirate__c;
        agAddr.city = app.City__c;
        agAddr.zipCodePOBox = app.ZipCodePOBoxNumber__c;
        agAddr.countryCode = app.CountryCode__c;
        agAddr.companyPhoneNumber = app.CompanyPhone_Number__c;
        agAddr.addressLine1 = app.AddressLine01__c;
        agAddr.addressLine2 = app.AddressLine02__c;
        resp.agencyAddress = agAddr;

        // Bank Details
        BAPPSubmitBrokerApplicationHandler.BankDetails bank = new BAPPSubmitBrokerApplicationHandler.BankDetails();
        bank.beneficiaryName = app.BeneficiaryName__c;
        bank.bankCountry = app.BankCountry__c;
        bank.bankName = app.BankNameValue__c;
        bank.bankBranchAddress = app.BankBranchAddress__c;
        bank.iban = app.IBAN__c;
        bank.swiftCode = app.SwiftCode__c;
        bank.accountNumber = app.Account_Number__c;
        resp.bankDetails = bank;
        // Company Personnel
        resp.companyPersonnel = new List<BAPPSubmitBrokerApplicationHandler.CompanyPersonnel>();
        for (BrokerApplicant__c p : personnelList) {
            BAPPSubmitBrokerApplicationHandler.CompanyPersonnel cp = new BAPPSubmitBrokerApplicationHandler.CompanyPersonnel();
            cp.applicantId = p.Id;
            cp.role = p.BrokerContactRole__c;
            cp.title = p.Title__c;
            cp.firstName = p.FirstName__c;
            cp.middleName = p.MiddleName__c;
            cp.lastName = p.LastName__c;
            cp.phoneNumber = p.PhoneNumber__c;
            cp.email = p.Email__c;
            cp.country = p.Country__c;
            cp.countryCode = p.CountryCode__c;
            cp.nationalId = p.NationalId__c;			
            cp.nationalIdExpiryDate = p.NationalIDExpiryDate__c;
            cp.passportNumber = p.PassportNumber__c;
            cp.passportExpiryDate = p.PassportExpiryDate__c;
            cp.dateOfBirth = p.DateOfBirth__c;
            cp.designation = p.Designation__c;
            cp.shareHoldingPercentage = p.ShareHoldingPercentage__c != null ? Integer.valueOf(p.ShareHoldingPercentage__c) : null;
            resp.companyPersonnel.add(cp);
        }

        // Uploaded Documents
        resp.uploaddocuments = new List<BAPPSubmitBrokerApplicationHandler.UploadDocument>();
        for (Document__c doc : docList) {
            BAPPSubmitBrokerApplicationHandler.UploadDocument d = new BAPPSubmitBrokerApplicationHandler.UploadDocument();
            
          // Distinguish between agency-level and personnel-level documents
          if (doc.DocumentType__r != null && doc.DocumentType__r.ObjectType__c == 'Broker Applicant' && doc.BrokerApplicant__r != null) {
                d.parentId = doc.BrokerApplicant__r.Id;
              	d.parentDocId = doc.Id;
                d.title = doc.BrokerApplicant__r.Title__c;
                d.firstName = doc.BrokerApplicant__r.FirstName__c;
                d.middleName = doc.BrokerApplicant__r.MiddleName__c;
                d.lastName = doc.BrokerApplicant__r.LastName__c;
                d.role = doc.BrokerApplicant__r.BrokerContactRole__c;
            } else if (doc.BrokerApplication__r != null) {
                d.parentId = doc.BrokerApplication__r.Id;
                d.agencyName = doc.BrokerApplication__r.Name;
                d.parentDocId = doc.Id;
            }
            d.fileName = doc.FileName__c;
            d.fileType = doc.FileType__c;
            d.fileSizeMB = doc.FileSizeMB__c;
            d.contentDocumentId = doc.ContentDocumentId__c;
            d.documentName = doc.Document_Name__c;
            d.contentVersionId = doc.Content_Version_Id__c;
            resp.uploaddocuments.add(d);
        }

        return resp;
    }
    Public static void makeErrorResponse(String message, Integer statusCode) {
        RestContext.response.statusCode = statusCode;
        RestContext.response.addHeader('Content-Type', 'application/json;charset=UTF-8');
        RestContext.response.responseBody = Blob.valueOf(
            JSON.serialize(new Map<String, String>{ 'error' => message })
        );
    }
    
}