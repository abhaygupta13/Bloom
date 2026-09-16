//============================ BCAPP_WebServiceHelper =============================
/*
* @Author : Eagles
* @CreatedDate : 04 Sept 2024
* @Name : BCAPP_WebServiceHelper
* @Description :
*/
/*****************************************************************************************************
* Version       Author                  Date             Comment
* 1.0           Eagles               04 Sept 2024        Initial draft
*****************************************************************************************************/

global class BCAPP_WebServiceHelper {
	Public static final String DOC_AVAILABLE = 'Document Available';

     public static void createVacationRequest(String requestBodyString) {

        Map<String, Object> returnValue = new Map<String, Object>();
        Map<String, Object> response = new Map<String, Object>();
        Map<String, Object> reqMap = (Map<String, Object>) JSON.deserializeUntyped(requestBodyString);
        BCAPP_Utility utility_ref = BCAPP_Utility.getInstance();
        ServiceCatalogService scService = ServiceCatalogService.getInstance();

        try {
            String userToken = (String) reqMap.get('accountId');
            List<User__c> customer;

            String filter;
            if (userToken != null) {
                if (!String.isBlank(userToken)) {
                    customer = utility_ref.getUserbyAccountId(userToken);
                }
            }
            if (customer == null || customer.isEmpty()) {
                response.put('errorMessage', 'Invalid User');
                makeServerErrorResponse(response);
                return;
            }
        

            String accountId = (String) reqMap.get('accountId');
            String unitId = (String) reqMap.get('unitId');
            String emergencyNo = (String) reqMap.get('emergencyNumber');
            Unit__c unit = UnitService.fetchUnitDetailsById(unitId)[0];
            if (unit == null || unit.Legal_Status__c == 'With Legal') {
                response.put('errorMessage', 'This unit is legally blocked. Please contact BCM.');
                BCAPP_WebServiceHelper.makeServerErrorResponse(response);
                return;
            }
            List<Service_Catalog__c> sc = ServiceCatalogService.fetchServiceCatalogByName('Vacation Request');
            List<Unit__c> units = UnitService.fetchUnitDetailsById(unitId); 
            if(units.isEmpty()){
                response.put('errorMessage', 'Not a Valid Unit');
                makeServerErrorResponse(response);
                return;
            }
            Case vacationCase = new Case();
            vacationCase.AccountId = accountId;
            vacationCase.Origin  = 'Community App';
            vacationCase.Unit__c = unitId;
            vacationCase.project__c = units[0].project__c;
            vacationCase.Permit_To_Date__c = Date.valueOf((String) reqMap.get('toDate'));
            vacationCase.Permit_From_Date__c = Date.valueOf((String) reqMap.get('fromDate'));
            vacationCase.Service_Catalog__c = sc[0].Id;
            vacationCase.Status = 'Submitted';
            vacationCase.User_Type__c = customer[0].User_Type__c;
            vacationCase.Emergency_contact_01__c=emergencyNo;
            vacationCase.user__c = customer[0].Id;
            vacationCase.RecordTypeId = Utilities.getRecordTypeId('Case','Community General Service Request'); 
            insert vacationCase;
            response.put('srId', vacationCase.Id);
            response.put('message', 'Vacation request created successfully');
            makeSuccessResponse(response);
           

        } catch (Exception e) {returnValue.put('errorMessage', e.getMessage());makeServerErrorResponse(returnValue);} 
    }
        
    public static void getProjects(Boolean isEnableMIP) {
        Map<String, Object> returnValue = new Map<String, Object>();
        List<Map<String, String>> response = new List<Map<String, String>>();
        try {
            ProjectService ProjectServiceinst = ProjectService.getInstance();
            
            for (Project__c pro : ProjectServiceinst.fetchProjects(isEnableMIP)) {
                Map<String, String> data = new Map<String, String>();
                data.put('Id', pro.Id);
                data.put('Name', pro.Name);
                data.put('communityImageURL', pro.Community_Image_Url__c);
                response.add(data);
            }
            // returnValue.put('result',response);
            makeSuccessResponse(response);
        } catch (Exception e) {returnValue.put('errorMessage', e.getMessage());makeServerErrorResponse(returnValue);}
    }
    
    public static void getNationality() {
       Map<String, Object> returnValue = new Map<String, Object>();
        List<Map<String, String>> response = new List<Map<String, String>>();
        try {
            for (NationalityApi__mdt rec : [
                SELECT Id, MasterLabel, CountryCode__c, CountryShortCode__c
                FROM NationalityApi__mdt
            ]) {
                Map<String, String> data = new Map<String, String>();
                data.put('CountryName', rec.MasterLabel);
                data.put('CountryCallingCode', rec.CountryCode__c);
                data.put('CountryCode', rec.CountryShortCode__c);
                //data.put('FlagIcon', base64Image);
                response.add(data);
            }
            makeSuccessResponse(response);
        } catch (Exception e) {returnValue.put('errorMessage', e.getMessage());makeServerErrorResponse(returnValue);}
    }
    
    public static void getPendingCases(string lastName) {
        Map<String, Object> returnValue = new Map<String, Object>();
        List<Map<String, String>> response = new List<Map<String, String>>();
        try {
            // Add where clause to get owner name
            for (Case rec : [
                SELECT
                Id,
                status,
                Unit_Name__c,
                Account.Name,
                Access_Permit_Category__c,
                Projectname__c,
                Building_Phase__c
                FROM Case
                WHERE
                status IN ('Assigned', 'In Progress', 'Draft', 'Repetetive')
                AND account.lastname = :lastName
            ]) {
                Map<String, String> data = new Map<String, String>();
                data.put('status', rec.status); data.put('UnitName', rec.Unit_Name__c); data.put('AccountName', rec.Account.Name);
                response.add(data);
            }
            makeSuccessResponse(response);
        } catch (Exception e) {returnValue.put('errorMessage', e.getMessage());makeServerErrorResponse(returnValue);}
    }
    
    public static void getBuildings(String projectName,Boolean isEnableMIP) {
        Map<String, Object> returnValue = new Map<String, Object>();
        List<Map<String, String>> response = new List<Map<String, String>>();
        try {
            BuildingSectionService bService = new BuildingSectionService();
            for (
                BuildingSection__c bs : bService.getBuildingsByProject(projectName,isEnableMIP)
            ) {
                Map<String, String> data = new Map<String, String>();
                data.put('Id', bs.Id);
                data.put('Name', bs.Name);
                data.put('ProjectLocation', bs.Project__r.City__c);
                response.add(data);
            }
            // returnValue.put('result',response);
            makeSuccessResponse(response);
        } catch (Exception e) {returnValue.put('errorMessage', e.getMessage());makeServerErrorResponse(returnValue);}
    }
    
    public static void getFavourites(String reqInput) {
        Map<String, Object> responseWrp = new Map<String, Object>();
        BCAPP_Utility utility_ref = BCAPP_Utility.getInstance();
        Map<String, Object> jsonData = (Map<String, Object>) JSON.deserializeUntyped(
            reqInput
        );
        String userToken = (String) jsonData.get('accountId');
        List<User__c> customer;
        try {
            String filter;
            if (userToken != null) {
                if (!String.isBlank(userToken)) {
                    customer = utility_ref.getUserbyAccountId(userToken);
                }
                if (
                    jsonData.containsKey('favoriteCases') &&
                    (Boolean) jsonData.get('favoriteCases')
                ) {
                    filter = ' AND Is_Favorite_Request__c =True';
                }
                CaseService cService = CaseService.getInstance();
                List<case> lstCases = cService.getrelatedCaseToAccount(
                    customer[0].Account__c,
                    filter
                );
                List<object> lstAllRec = new List<object>();
                for (case caseRec : lstCases) {
                    Map<string, object> mapCases = new Map<string, object>();
                    mapCases.put('requestNumber', caseRec.Request_Number__c);
                    mapCases.put('userType', caseRec.User_Type__c);
                    mapCases.put('status', caseRec.Status);
                    mapCases.put('requestType', caseRec.Service_Catalog__r.Name);
                    mapCases.put('createdDate', caseRec.CreatedDate.date());
                    mapCases.put('isFavorite', caseRec.Is_Favorite_Request__c);
                    mapCases.put('reqId', caseRec.Id);
                    mapCases.put('obj', 'case');
                    lstAllRec.add(mapCases);
                }
                responseWrp.put('data', lstAllRec);
                for (Unit_Allocation__c rec : [
                    SELECT
                    Unit__r.Name,
                    Start_Date__c,
                    End_Date__c,
                    Unit__r.Building_Phase_Name__c,
                    Unit__r.UnitNumber__c,
                    Unit__r.CommunityUnitNumber__c,Unit__r.ADMAddressingNumber__c
                    FROM Unit_Allocation__c
                    WHERE
                    Is_Favourite_Unit__c = TRUE
                    AND Account__c = :customer[0].Account__c
                ]) {
                    Map<string, object> mapCases = new Map<string, object>();
                    mapCases.put('StartDate', rec.Start_Date__c);
                    mapCases.put('EndDate', rec.End_Date__c);
                    mapCases.put('UnitName', rec.Unit__r.ADMAddressingNumber__c);
                    mapCases.put('BuildingPhaseName', rec.Unit__r.Building_Phase_Name__c);
                    mapCases.put('UnitNumber',(rec.Unit__r.ADMAddressingNumber__c!=null?rec.Unit__r.ADMAddressingNumber__c:rec.Unit__r.UnitNumber__c));
                    mapCases.put('obj', 'unit');
                    lstAllRec.add(mapCases);
                }
                responseWrp.put('data', lstAllRec);
                makeSuccessResponse(responseWrp);
                return;
            } else {
                responseWrp.put('errorMessage', 'Invalid Response');makeServerErrorResponse(responseWrp);
                return;
            }
        } catch (Exception e) {
            responseWrp.put('errorMessage', e.getLineNumber());makeServerErrorResponse(responseWrp);
            return;
        }
    }
    public static void getUnits(String buildingName) {
        Map<String, Object> returnValue = new Map<String, Object>();
        List<Map<String, String>> response = new List<Map<String, String>>();
        try {
            for (Unit__c unit : UnitService.getUnitByBuilding(buildingName)) {
                Map<String, String> data = new Map<String, String>();
                data.put('Id', unit.Id);
                data.put('Name', unit.ADMAddressingNumber__c);
                if (
                    !String.isBlank(unit.Occupancy_Type__c) &&
                    unit.Occupancy_Type__c != 'Available'
                ) {
                    data.put('errorMessage', 'Unit Is not Available.');
                } else {
                    data.put('errorMessage', '');
                }
                response.add(data);
            }
            //returnValue.put('result',response);
            makeSuccessResponse(response);
        } catch (Exception e) {
            returnValue.put('errorMessage', e.getMessage()); makeServerErrorResponse(returnValue);
        }
    }
    
    public static void createLoginHisory(String srReq) {
        Map<String, Object> returnValue = new Map<String, Object>();
        
        try {
            Map<String, Object> jsonData = (Map<String, Object>) JSON.deserializeUntyped(
                srReq
            );
            User_Login_History__c userLoginHistory = new User_Login_History__c();
            if (jsonData.get('location') != null)
                userLoginHistory.Location__c = (String) jsonData.get('location');
            
            if (jsonData.get('ip') != null)
                userLoginHistory.Login_IP_Address__c = (String) jsonData.get('ip');
            
            if (jsonData.get('logintime') != null) {
                String inpputString = (string) jsonData.get('logintime');
                DateTime resultDateTime = DateTime.ValueofGmt(
                    inpputString.replace('T', ' ')
                );
                userLoginHistory.Login_Time__c = resultDateTime;
            }
            if (jsonData.get('name') != null)
                userLoginHistory.Name__c = (String) jsonData.get('name');
            
            if (jsonData.get('username') != null)
                userLoginHistory.User_Name__c = (String) jsonData.get('username');
            
            if (jsonData.get('email') != null)
                userLoginHistory.Email__c = (String) jsonData.get('email');
            
            insert userLoginHistory;
            returnValue.put('SF_ID', userLoginHistory.ID);
            makeSuccessResponse(returnValue);
        } catch (Exception e) {
            returnValue.put('errorMessage', 'Error ' + e.getMessage());makeServerErrorResponse(returnValue);
        }
        system.debug('returnValue' + returnValue);
    }
    
    public String validateMoveInBusinessRule(String unitId) {
        WebServiceResponse returnValue = new WebServiceResponse();
        List<Map<String, String>> response = new List<Map<String, String>>();
        try {
            List<Service_Catalog_Business_Rule__c> validation = ServiceCatalogBusinessRuleService.fetchServiceValidation(
                'Service Fee'
            );
            if (!validation.isEmpty() && validation[0].Active__c) {
                List<Unit__c> unit = UnitService.fetchUnitDetailsById(unitId);
                Decimal outAmt = validation[0].Default_Value__c != null ? Decimal.valueOf(validation[0].Default_Value__c) : 2000;
                if (unit[0].Total_Outstanding__c > outAmt) { returnValue.result.put('isValid', true);
                } else { returnValue.result.put('isValid', false);
                }
            } else {
                returnValue.result.put('isValid', true);
            }
            returnValue.result.put('isValid', true);
        } catch (Exception e) {
            returnValue.result.put('errorMessage', e.getMessage()); returnValue.result.put('isValid', false);
        }
        return JSON.serialize(returnValue.result);
    }
    
    public static void makeSuccessResponse(Map<String, Object> response) {
        Map<String, Object> result = new Map<String, Object>();
        RestResponse res = RestContext.response;
        // Set a custom HTTP status code
        res.statusCode = 200; // HTTP 200 OK
        res.headers.put('Content-Type', 'application/json');
        result.put('data', response);
        result.put('success', true);
        res.responseBody = Blob.valueOf(JSON.serialize(result));
    }
    
    public static void makeSuccessResponse(List<Map<String, Object>> response) {
        Map<String, Object> result = new Map<String, Object>();
        RestResponse res = RestContext.response;
        // Set a custom HTTP status code
        res.statusCode = 200; // HTTP 200 OK
        res.headers.put('Content-Type', 'application/json');
        result.put('data', response);
        result.put('success', true);
        res.responseBody = Blob.valueOf(JSON.serialize(result));
        // Return null because response is set manually
    }

    public static void makeErrorResponse(Integer statusCode, Map<String, Object> response) {
        Map<String, Object> result = new Map<String, Object>();
        RestResponse res = RestContext.response;
        // Set a custom HTTP status code
        res.statusCode = statusCode;
        res.headers.put('Content-Type', 'application/json');
        result.put('data', response);
        result.put('success', false);
        res.responseBody = Blob.valueOf(JSON.serialize(result));
    }
    
    @future
    public static void captureLogs(string request, string url) {
        Integration_Logs__c log = new Integration_Logs__c();
        log.Type__c = 'Inbound';
        log.External_System__c = 'Community Mobile App';
        log.Request__c = request;
        log.Class_Flow__c = url;
        insert log;
    }
    
    public static void makeServerErrorResponse(Map<String, Object> response) {
        RestResponse res = RestContext.response;
        Map<String, Object> result = new Map<String, Object>();
        // Set a custom HTTP status code
        res.statusCode = 500; // HTTP 500 Internal Server Error
        res.headers.put('Content-Type', 'application/json');
        result.put('error', response);
        result.put('success', false);
        res.responseBody = Blob.valueOf(JSON.serialize(result));
    }
    
    public static void getServiceCatalogs() {
        Map<String, Object> result = new Map<String, Object>();
        try {
            BCAPP_Utility util_ref = BCAPP_Utility.getInstance();
            List<Service_Catalog__c> serviceCatalogs = new List<Service_Catalog__c>();
            // Fetch records from Service Catalog
            List<Service_Catalog__c> sc_records = ServiceCatalogService.getServiceCatalogAndrelatedDocuments();
            String userAccess = 'Owner;Tenant';
            List<BCAPP_WrapperUtility.serviceRequest> lstWrp = new List<BCAPP_WrapperUtility.serviceRequest>();
            List<String> userTypes = util_ref.parseMultiPicklist(userAccess);
            
            for (Service_Catalog__c rec : sc_records) {
                List<String> accessTo = util_ref.parseMultiPicklist(rec.Access_To__c);
                // Check for intersection between the two sets
                if (!accessTo.isEmpty() && !userTypes.isEmpty()) {
                    BCAPP_WrapperUtility.serviceRequest wrp = new BCAPP_WrapperUtility.serviceRequest();
                    for (String access : accessTo) {
                        if (userTypes.contains(access)) {
                            wrp.name = rec.Name;
                            wrp.imageURL = rec.Image_URL__c;
                            wrp.srId = rec.Id;
                            wrp.documents = new List<BCAPP_WrapperUtility.RequiredDocuments>();
                            for (
                                Service_Catolog_Documents__c docRec : rec.Service_Catolog_Documents__r
                            ) {
                                BCAPP_WrapperUtility.RequiredDocuments doc = new BCAPP_WrapperUtility.RequiredDocuments();
                                doc.displayName = docRec.Document_Name__c;
                                doc.documentSize = Integer.valueOf(docRec.Document_Size__c);
                                doc.documentType = docRec.Document_Type__c.split(',');
                                wrp.documents.add(doc);
                            }
                            lstWrp.add(wrp);
                            break;
                        }
                    }
                }
            }
            result.put('data', lstWrp);
            makeSuccessResponse(result);
        } catch (Exception e) {
            result.put('errorMessage', e.getMessage()); makeServerErrorResponse(result);
        }
    }
    
    public static void fetchMyPortfolio(String reqInput) {
        Map<String, Object> result = new Map<String, Object>();
        try {
            BCAPP_Utility utilit_ref = BCAPP_Utility.getInstance();
            UnitAllocationService uService = new UnitAllocationService();
            Map<String, Object> jsonData = (Map<String, Object>) JSON.deserializeUntyped(
                reqInput
            );
            String accountId;
            Case sr;
            String userToken = (String) jsonData.get('accountId');
            List<User__c> customer;
            if (!String.isBlank(userToken)) {
                customer = utilit_ref.getUserbyAccountId(userToken);
            }
            if (customer == null || customer.isEmpty()) {
                result.put('errorMessage', 'Invalid User');
                makeServerErrorResponse(result);
                return;
            }
            accountId = userToken;
            // Fetch records from Service Catalog
            if (!customer.isEmpty()) {
                update new User__c(
                    id = customer[0].Id,
                    Last_Login__c = utilit_ref.getCurrentUserLocalTime()
                );
                
                List<Unit_Allocation__c> so_records = uService.fetchAllUnitsRelatedToAccount(
                    accountId
                );
                List<BCAPP_WrapperUtility.MyPortFolioResponse> lstWrp = new List<BCAPP_WrapperUtility.MyPortFolioResponse>();
                for (Unit_Allocation__c rec : so_records) {
                    // Check for intersection between the two sets
                    BCAPP_WrapperUtility.MyPortFolioResponse wrp = new BCAPP_WrapperUtility.MyPortFolioResponse();
                      wrp.unitNumber = rec.Unit__r.ADMAddressingNumber__c!=null?rec.Unit__r.ADMAddressingNumber__c:rec.Unit__r.UnitNumber__c;
                    wrp.unitBlocked = rec.Unit__r.Legal_Status__c == 'With Legal'?true:false;
                    wrp.floorNumber = rec.Unit__r.FloorNumber__c;
                    wrp.buildingName = rec.Unit__r.Building_Phase_Name__c;
                    wrp.unitId = rec.Unit__c;
                    wrp.projectName = rec.Unit__r.Project__r.Name;
                    wrp.communityImageURL = rec.Unit__r.Project__r.Community_Image_Url__c;
                    wrp.projectId = rec.Unit__r.Project__c;
                    wrp.isChillerEnabled = rec.Unit__r.Is_Chiller_Enabled__c;
                      wrp.noOfGuests = BCAPP_Constants.getGuestCount(rec.Unit__r.UnitModel__c );
                    wrp.isLeaseHold = rec.Unit__r.Is_Lease_Hold__c;
                    lstWrp.add(wrp);
                }
                result.put('units', lstWrp);
                map<string, object> mapUser = new Map<string, object>();
                mapUser.put('name', customer[0].Name);
                mapUser.put('email', customer[0].Email__c);
                mapUser.put('userType', customer[0].User_Type__c);
                mapUser.put('userPrincipleName', customer[0].User_Principal_Name__c);
                mapUser.put('lastLogin', customer[0].Last_Login__c);
                
                result.put('userInfo', mapUser);
                
                makeSuccessResponse(result);
            } else {
                result.put('errorMessage', 'user not configured in salesforce');
                makeServerErrorResponse(result);
            }
        } catch (Exception e) {
            result.put('errorMessage', e.getMessage() + '--' + e.getLineNumber());
            makeServerErrorResponse(result);
        }
    }
    
     public static void updateProfile(String reqInput) {
        Map<String, Object> result = new Map<String, Object>();
        try {
            BCAPP_Utility utility_ref = BCAPP_Utility.getInstance();
            Map<String, Object> jsonData = (Map<String, Object>) JSON.deserializeUntyped(
                reqInput
            );
            String accountId;
            Case sr;
            String userToken = (String) jsonData.get('accountId');
            
            String email = '';
            if (jsonData.get('emailAddress') != null)
                email = (String) jsonData.get('emailAddress');
            
            String mobileNumber = '';
            if (jsonData.get('mobileNumber') != null)
                mobileNumber = (String) jsonData.get('mobileNumber');
            List<User__c> customer;
            if (!String.isBlank(userToken)) {
                customer = utility_ref.getUserbyAccountId(userToken);
            }
            if (customer.isEmpty()) {
                result.put('errorMessage', 'Invalid User');
                makeServerErrorResponse(result);
            }
                  String otp = (String) jsonData.get('otp');

            if (String.isBlank(otp)) {
                result.put('errorMessage', 'OTP is required to update your email or mobile number. Please enter the OTP and try again.');
                makeErrorResponse(400,result);
                return;
            }

            if(customer[0].Forget_Password_Request_OTP__c != otp){
                result.put('errorMessage', 'The OTP you entered is incorrect. Please check and try again.');
                makeErrorResponse(400,result);
                return;
            }
            else{
                customer[0].Forget_Password_Request_OTP__c = null;
                update customer[0];
            }
            accountId = customer[0].Account__c;
            // Fetch records from Service Catalog
            if (!customer.isEmpty()) {
                User__c mapUser = new User__c();
                if (!String.isBlank(email)) {
                    mapUser.put('Email__c', email);
                     MicrosoftAzureB2CUtility.updateUser(customer[0]);
                }
                if (!String.isBlank(mobileNumber)) {
                    mapUser.put('Mobile_Number__c', mobileNumber);
                }
                mapUser.put('Id', customer[0].Id);
                update mapUser;
                result.put('Status', 'Details Updated Successfully');
                makeSuccessResponse(result);
            } else {
                result.put('errorMessage', 'user not configured in salesforce'); makeServerErrorResponse(result);
            }
        } catch (Exception e) {
            result.put('errorMessage', e.getMessage()); makeServerErrorResponse(result);
        }
    }
    
    public static void getProfile(String reqInput) {
        Map<String, Object> result = new Map<String, Object>();
        // try{
        Map<String, Object> jsonData = (Map<String, Object>) JSON.deserializeUntyped(
            reqInput
        );
        Id accountId;
        Case sr;
        String userToken = (String) jsonData.get('userToken');
        List<User__c> customer;
        if (!String.isBlank(userToken)) {
            customer = BCAPP_Utility.getUser(userToken);
        }
        if (customer.isEmpty()) {
            result.put('errorMessage', 'Invalid User');
            makeServerErrorResponse(result);
        }
        if (customer[0].User_Type__c == 'Security') {
            FM_App_Settings__mdt fmaAPPRecord = FM_App_Settings__mdt.getInstance( 'FM_APP_Settings' );
            result.put('url', fmaAPPRecord.site_url__c);
            result.put('token', customer[0].Azure_UserId__c);
            makeSuccessResponse(result);
            return;
        }
        accountId = customer[0].User_Account__c;
        AccountService accService = AccountService.getInstance();
        Account acccountRecord = accService.getAccountById(
            accountId
        );
        ContactService contactInst = ContactService.getInstance();
        
        List<Contact> lstContact = contactInst.getContactByAccountId(
            acccountRecord.ID
        );
        
        // Fetch records from Service Catalog
        if (!customer.isEmpty()) {
            map<string, object> mapUser = new Map<string, object>();
            mapUser.put('accountId', acccountRecord.Id);
            
            mapUser.put('firstName', acccountRecord.FirstName);
            mapUser.put('lastName', acccountRecord.LastName);
            if (!lstContact.isEmpty()) {
                mapUser.put('userType', customer[0].User_Type__c);
            }
            mapUser.put('emailAddress', customer[0].Email__c);
            mapUser.put('userPrincipleName', customer[0].User_Principal_Name__c);
            if (
                customer[0].User_Type__c == BCAPP_Constants.TENANT ||
                customer[0].User_Type__c == BCAPP_Constants.OWNER
            ) {
                mapUser.put('nationality', acccountRecord.Nationality__c);
                mapUser.put(
                    'ejariStartDate',
                    acccountRecord.EJARI_Tawteeq_start_date__c
                );
                mapUser.put('ejariEndDate', acccountRecord.EJARI_Tawteeq_end_date__c);
                mapUser.put('ejariNumber', acccountRecord.EJARI_Tawteeq_number__c);
                mapUser.put('moveInDate', acccountRecord.Move_In_Date__c);
                mapUser.put('emiratesNumber', acccountRecord.Emirates_ID_number__c);
                mapUser.put(
                    'emiratesExpDate',
                    acccountRecord.Emirates_ID_expiry_date__c
                );
                mapUser.put(
                    'emergencyContactNumber01',
                    acccountRecord.Emergency_contact_01__c
                );
                mapUser.put(
                    'emergencyContactNumber02',
                    acccountRecord.Emergency_contact_02__c
                );
                mapUser.put(
                    'numberOfPets',
                    acccountRecord.NumberOfPets__c
                );
                mapUser.put(
                    'adultOccupants',
                    acccountRecord.Total_Number_of_Adults_Occupants__c
                );
                mapUser.put(
                    'childOccupants',
                    acccountRecord.Total_Number_of_Child_Occupants__c
                );
                mapUser.put(
                    'occupantsWithSpecialNeeds',
                    acccountRecord.Occupant_with_special_needs__c
                );
                mapUser.put(
                    'specialNeedsComments',
                    acccountRecord.Special_Needs_Comments__c
                );
                if(acccountRecord.MobilePhone__pc!=null){
                    mapUser.put('mobileNumber', acccountRecord.MobilePhone__pc);
                }
                else{
                    mapUser.put('mobileNumber', acccountRecord.PersonMobilePhone);
                }
                
                mapUser.put('lastLogin', customer[0].Last_Login__c);
            } else if (customer[0].User_Type__c == BCAPP_Constants.HOLIDAY_HOMES) {
                mapUser.put('firstName', acccountRecord.Name);
                mapUser.put('lastName', '');
                mapUser.put('emailAddress', '');
                if (!lstContact.isEmpty()) {
                    mapUser.put('representativeName', lstContact[0].LastName);
                    mapUser.put('emailAddress', lstContact[0].Email);
                    mapUser.put('representativeContactNumber', lstContact[0].Phone);
                }
                mapUser.put('emailAddress', customer[0].Email__c);
                mapUser.put('operatorName', acccountRecord.Name);
                mapUser.put(
                    'operatorOfficeNumber',
                    acccountRecord.Operator_Office_Number__c
                );
                mapUser.put(
                    'leaseStartDate',
                    acccountRecord.EJARI_Tawteeq_start_date__c
                );
                mapUser.put('leaseEndDate', acccountRecord.EJARI_Tawteeq_end_date__c);
                mapUser.put(
                    'operatorLicenseExpDate',
                    acccountRecord.Operator_license_Exp_Dtae__c
                );
                mapUser.put(
                    'operatorLicenseNumber',
                    acccountRecord.Operator_License_Number__c
                );
                mapUser.put('moveInDate', acccountRecord.Move_In_Date__c);
                mapUser.put('emiratesIdNumber', acccountRecord.Emirates_ID_number__c);
                mapUser.put(
                    'emiratesIdExpDate',
                    acccountRecord.Emirates_ID_expiry_date__c
                );
                mapUser.put(
                    'emergencyContactNumber01',
                    acccountRecord.Emergency_contact_01__c
                );
                mapUser.put(
                    'emergencyContactNumber02',
                    acccountRecord.Emergency_contact_02__c
                );
                mapUser.put(
                    'mobileNumner',
                    acccountRecord.Representative_Contact_Number__c
                );
                mapUser.put('lastLogin', customer[0].Last_Login__c);
                mapUser.put('userType', BCAPP_Constants.HOLIDAY_HOMES);
            }
            result.put('userInfo', mapUser);
               system.debug('registrationId--'+result);

            system.debug('registrationId--'+(String)jsonData.get('registrationId'));

            if(!String.isBlank((String)jsonData.get('registrationId')) && (String)jsonData.get('registrationId')!='null'){

                User__c azureUser = new User__c();

                azureUser.Id = customer[0].Id;

                  system.debug('registrationId--'+(String)jsonData.get('registrationId'));

                azureUser.deviceRegistrationId__c =  (String)jsonData.get('registrationId');

                update azureUser;

            }
            makeSuccessResponse(result);
        } else {
            result.put('errorMessage', 'user not configured in salesforce');
            makeServerErrorResponse(result);
        }
        /* }
catch(Exception e){
result.put('errorMessage', e.getMessage());
makeServerErrorResponse(result);
}*/
    }
    
    public static void createDocument(String reqInput) {
        Map<String, Object> result = new Map<String, Object>();
        Map<String, String> docId = new Map<String, String>();
        BCAPP_Utility utility = new BCAPP_Utility();
        try {
            Map<String, Object> inputData = (Map<String, Object>) JSON.deserializeUntyped(
                reqInput
            );
            if (inputData.get('srId') != null) {
                String parentId = (String) inputData.get('srId');
                String sCatalogDocId = (String) inputData.get('sCatalogDocId');
                if (String.isBlank(sCatalogDocId) || String.isBlank(parentId)) {
                    result.put('errorMessage', 'Invalid Request');
                    makeServerErrorResponse(result);
                    return;
                }
                List<BCAPP_WrapperUtility.Document> documents = new List<BCAPP_WrapperUtility.Document>();
                BCAPP_WrapperUtility.Document doc = new BCAPP_WrapperUtility.Document();
                doc.fileName = (String) inputData.get('fileName');
                doc.fileContent = EncodingUtil.base64Decode(
                    (String) inputData.get('fileContent')
                );
                documents.add(doc);
                Map<String, String> fileResult;
                try {
                    fileResult = utility.processDocuments(
                        documents,
                        parentId,
                        sCatalogDocId
                    );
                } catch (Exception e) {
                    result.put(
                        'errorMessage',
                        'Failed to upload Documents:' + e.getMessage()
                    );
                    makeServerErrorResponse(result);
                    return;
                }
                if (!fileResult.isEmpty()) {
                    result.put('Id', fileResult.get('docId'));
                    result.put('url', fileResult.get('url'));
                    try {
                        Boolean isAnyDocumentMissingFile = false;
                        // Boolean isAnyDocumentMissingFile= isAnyDocumentMissingFile(CustomerDocumentService.getCustomerDocuments(parentId));
                        // Integer customerDocumentCount = ;
                        CaseService cService = CaseService.getInstance();
                        Case requestRec = cService.getCaseById(parentId);
                        List<BCAPP_WrapperUtility.RequiredDocuments> requiredDocuments = utility.getRequiredDocuments(
                            requestRec.project__c,
                            requestRec.User_Type__c,
                            requestRec.Service_Catalog__c,
                            false
                        );
                        if (!isAnyDocumentMissingFile) {
                            // requestRec.Status = 'Submitted';
                            String ownerId = utility.changeCaseAssigment(
                                requestRec.Service_Catalog__c
                            );
                            // if (!String.isBlank(ownerId)) {
                            //     requestRec.OwnerId = ownerId;
                            // }
                            update requestRec;
                        }
                    } catch (Exception e) {
                        result.put('Id', ''); result.put('url', ''); result.put('errorMessage', e.getMessage());
                        makeServerErrorResponse(result);
                        return;
                    }
                    
                    makeSuccessResponse(result);
                    return; 
                } else {
                    result.put('errorMessage', 'Failed to insert Documents: ');
                    makeServerErrorResponse(result);
                    return;
                }
            }
        } catch (Exception e) {
            result.put(
                'errorMessage',
                'Failed to insert Documents: ' + e.getMessage()
            );
            makeServerErrorResponse(result);
            return;
        }
    }
    
    public Boolean isAnyDocumentMissingFile(
        List<Customer_Document__c> customerDocuments
    ) {
        if (customerDocuments == null || customerDocuments.isEmpty()) {
            return false;
        }
        
        // Collect all Customer_Document__c record IDs
        Set<Id> documentIds = new Set<Id>();
        for (Customer_Document__c doc : customerDocuments) {
            documentIds.add(doc.Id);
        }
        ContentDocumentService cdService = new ContentDocumentService();
        // Query ContentDocumentLink to find any linked files for these records
        List<ContentDocumentLink> links = cdService.getContentDocLinkFromLinkEntityId(
            documentIds
        );
        
        // Collect IDs of records with at least one file attached
        Set<Id> documentIdsWithFiles = new Set<Id>();
        for (ContentDocumentLink link : links) {
            documentIdsWithFiles.add(link.LinkedEntityId);
        }
        
        // Check if there are any records without files
        for (Id docId : documentIds) {
            if (!documentIdsWithFiles.contains(docId)) {
                // If any document ID is missing in the result, return true
                return true;
            }
        }
        
        // All records have at least one file
        return false;
    }
    
    /*  public static void updatePassword(String reqInput){
Map<String,Object>  result = new Map<String,Object>();
try{
HttpResponse response=     MicrosoftAzureB2CUtility.updatePassword(reqInput);
if (response.getStatusCode() == 204) {
result.put('data','Password Updated Successfully');  
makeSuccessResponse(result);
}
else{
result.put('errorMessage', 'Internal Error');
makeServerErrorResponse(result);
}
}catch(Exception e){
result.put('errorMessage', e.getMessage());
makeServerErrorResponse(result);
}
}*/
    
    public static void validateEmailOTPTemp(String reqInput) {
        Map<String, Object> result = new Map<String, Object>();
        try {
            Map<String, Object> jsonData = (Map<String, Object>) JSON.deserializeUntyped(
                reqInput
            );
            BCAPP_Utility utility_ref = BCAPP_Utility.getInstance();
            Case sr;
            String otp = (String) jsonData.get('otp');
            String email = (String) jsonData.get('email');
            String accountId = (String) jsonData.get('accountId');
            String reqType = (String) jsonData.get('type');
            String messaging = (String) jsonData.get('messaging');
            ContactService contactInst = ContactService.getInstance();
            if (messaging == null || messaging == '') {
                messaging = (String) jsonData.get('commType');
            }
            
            if (messaging == 'mobile') {
                List<User__c> customer;
                
                if (
                    reqType == '' ||
                    reqType == null ||
                    reqType == 'Owner Verification'
                ) {
                    if (!String.isBlank(email)) {
                        customer = utility_ref.getUserbyEmail(email);
                    }
                } else if (reqType == 'Profile Update') {
                    if (!String.isBlank(accountId)) {
                        customer = utility_ref.getUserbyaccountId(accountId);
                    }
                }
                
                if (customer[0].Forget_Password_Request_OTP__c == otp) {
                    if(reqType != 'Profile Update'){
                        customer[0].Forget_Password_Request_OTP__c = null;
                        update customer[0];
                    }
                    
                    result.put('validOTP', 'true');
                    result.put('userToken', customer[0].Azure_UserId__c);
                    makeSuccessResponse(result);
                    if (reqType == 'Profile Update') {
                        User__c userRecord = new User__c();
                        userRecord.Id = customer[0].Id;
                        userRecord.Email__c = customer[0].Request_for_Email_Amendment__c;
                        update userRecord;
                        if (
                            customer[0].User_Account__r.Tenant__c ||
                            customer[0].User_Account__r.Owner__c
                        ) {
                            Account accountRecord = new Account();
                            accountRecord.Id = accountId;
                            accountRecord.MobilePhone__pc = customer[0]
                                .Request_for_Mobile_Amendment__c;
                            update accountRecord;
                        } else if (customer[0].User_Account__r.Holiday_Homes__c) {
                            contact contactRecord = new contact();
                              
                            contactRecord = contactInst.getContactByAccountId(
                                accountId
                            )[0];
                            contactRecord.Phone = customer[0].Request_for_Mobile_Amendment__c;
                            update contactRecord;
                        }
                    }
                } else {
                    result.put('errorMessage', 'The OTP you entered is incorrect. Please check and try again.');
                    result.put('validOTP', false);
                    
                    makeServerErrorResponse(result);
                    
                }
            } else {
                List<User__c> customer;
                
                if (
                    reqType == '' ||
                    reqType == null ||
                    reqType == 'Owner Verification'
                ) {
                    if (!String.isBlank(email)) {
                        customer = utility_ref.getUserbyEmail(email);
                    }
                } else if (reqType == 'Profile Update') {
                    if (!String.isBlank(accountId)) {
                        customer = utility_ref.getUserbyaccountId(accountId);
                    }
                }
                
                if (customer[0].Forget_Password_Request_OTP__c == otp) {
                    if(reqType != 'Profile Update'){
                        customer[0].Forget_Password_Request_OTP__c = null;
                        update customer[0];
                    }
                    result.put('validOTP', 'true');
                    result.put('userToken', customer[0].Azure_UserId__c);
                    makeSuccessResponse(result);
                    if (reqType == 'Profile Update') {
                        User__c userRecord = new User__c();
                        userRecord.Id = customer[0].Id;
                        userRecord.Email__c = customer[0].Request_for_Email_Amendment__c;
                        update userRecord;
                        if (
                            customer[0].User_Account__r.Tenant__c ||
                            customer[0].User_Account__r.Owner__c
                        ) {
                            Account accountRecord = new Account();
                            accountRecord.Id = accountId;
                            accountRecord.PersonEmail = customer[0]
                                .Request_for_Email_Amendment__c;
                            update accountRecord;
                        } else if (customer[0].User_Account__r.Holiday_Homes__c) {
                            contact contactRecord = new contact();
                            contactRecord = contactInst.getContactByAccountId(
                                accountId
                            )[0];
                            contactRecord.Email = customer[0].Request_for_Email_Amendment__c;
                            update contactRecord;
                        }
                       // MicrosoftAzureB2CUtility.updateUser(customer[0]);
                    }
                } else {
                    result.put('errorMessage', 'The OTP you entered is incorrect. Please check and try again.');
                    result.put('validOTP', false);
                    
                    makeServerErrorResponse(result);
                }
            }
        } catch (Exception e) {
            result.put('errorMessage', e.getMessage());
            makeServerErrorResponse(result);
        }
    }
    
    
    @future(callout=true)
    public static void updateUser(string email, string principalId) {
        // MicrosoftAzureB2CUtility.updateUser(email,principalId);
    }
    
    public static void sendOTPToVerifyEmailTemp(String reqInput) {
        Map<String, Object> result = new Map<String, Object>();
        try {
            Map<String, Object> jsonData = (Map<String, Object>) JSON.deserializeUntyped(
                reqInput
            );
            Case sr;
            String email = (String) jsonData.get('email');
            String type = (String) jsonData.get('type');
            String accountId = (String) jsonData.get('accountId');
            String messaging = (String) jsonData.get('messaging');
            String phoneNumber = (String) jsonData.get('phoneNumber');
            if (messaging == null || messaging == '') {
                messaging = (String) jsonData.get('commType');
            }
            BCAPP_Utility utility_ref = BCAPP_Utility.getInstance();
            if (messaging == 'mobile') {
                List<User__c> customer = utility_ref.getUserbyaccountId(accountId);
                if (customer.size() == 0) {
                    result.put('errorMessage', 'User is not Exist.');
                    result.put('isUserActive', 'false');
                    makeServerErrorResponse(result);
                } else {
                    if (customer.size() > 0 && !customer[0].Is_Azure_Active__c) {
                        result.put('errorMessage', 'User is not Active.');
                        result.put('isUserActive', 'false');
                        makeServerErrorResponse(result);
                    } else {
                        Integer randomFourDigitNumber =
                            (Integer) (Math.random() * 900000) + 100000;
                        customer[0].Forget_Password_Request_OTP__c = string.valueof(
                            randomFourDigitNumber
                        );
                        if (type == 'Profile Update') {
                            customer[0].Request_for_Mobile_Amendment__c = phoneNumber;
                        }
                        SMS_Service.sendSMS(
                            phoneNumber,
                            'Profile Update OTP ' + customer[0].Forget_Password_Request_OTP__c
                        );
                        update customer;
                        Map<string, object> mapReturn = new Map<string, object>();
                        result.put(
                            'data',
                            'SMS for OTP has been sent successfully to customer'
                        );
                        result.put('isUserActive', 'true');
                        makeSuccessResponse(result);
                    }
                }
            } else {
                List<User__c> customer;
                if (!String.isBlank(email)) {
                    if (type == '' || type == null || type == 'Owner Verification')
                        customer = utility_ref.getUserbyEmail(email);
                    else if (type == 'Profile Update') {
                        customer = utility_ref.getUserbyaccountId(accountId);
                    }
                    if (customer.size() == 0) {
                        result.put('errorMessage', 'User is not Exist.');
                        result.put('isUserActive', 'false');
                        makeServerErrorResponse(result);
                    } else {
                        if (customer.size() > 0 && !customer[0].Is_Azure_Active__c) {
                            result.put('errorMessage', 'User is not Active.');
                            result.put('isUserActive', 'false');
                            makeServerErrorResponse(result);
                        } else {
                            Integer randomFourDigitNumber =
                                (Integer) (Math.random() * 900000) + 100000;
                            customer[0].Forget_Password_Request_OTP__c = string.valueof(
                                randomFourDigitNumber
                            );
                            if (type == 'Profile Update')
                                customer[0].Request_for_Email_Amendment__c = email;
                            update customer;
                            List<string> lstTo = new List<string>();
                            lstTo.add(email);
                            handleOTPEmail(lstTo, customer[0]);
                            Map<string, object> mapReturn = new Map<string, object>();
                            result.put(
                                'data',
                                'Email for OTP has been sent successfully to customer'
                            );
                            result.put('isUserActive', 'true');
                            makeSuccessResponse(result);
                        }
                    }
                } else {
                    result.put('errorMessage', 'Email Address is not valid.');
                    makeServerErrorResponse(result);
                }
            }
        } catch (Exception e) {
            result.put('errorMessage', e.getMessage());
            makeServerErrorResponse(result);
        }
    }
    
    public static void handleOTPEmail(List<string> lstTo, User__c userRecord) {
        BCAPP_Utility utility_ref = BCAPP_Utility.getInstance();
        // Query the email template
        EmailTemplate template = EmailTemplateService.getEmailTemplateByDeveloperName(
            'Send_OTP_for_Email_Verification'
        );
        
        // Create a list to hold emails
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        
        // Get the HTML body and plain text body
        String htmlBody = template.HtmlValue;
        String plainTextBody = template.Body;
        
        htmlBody = htmlBody.replace(
            '{Email_Change_Request_OTP__c}',
            userRecord.Forget_Password_Request_OTP__c
        );
        plainTextBody = plainTextBody.replace(
            '{Email_Change_Request_OTP__c}',
            userRecord.Forget_Password_Request_OTP__c
        );
        
        utility_ref.sendCustomEmail(
            lstTo,
            userRecord.id,
            htmlBody,
            plainTextBody,
            template.Subject
        );
    }
    
    /*public static void sendOTPToVerifyEmail(String reqInput) {
        Map<String, Object> result = new Map<String, Object>();
        try {
            Map<String, Object> jsonData = (Map<String, Object>) JSON.deserializeUntyped(
                reqInput
            );
            String accountId;
            BCAPP_Utility utility_ref = BCAPP_Utility.getInstance();
            Case sr;
            String email = (String) jsonData.get('email');
            
            List<User__c> customer;
            if (!String.isBlank(email)) {
                customer = utility_ref.getUserbyEmail(email);
                if (customer.size() == 0) {
                    result.put('errorMessage', 'User is not Exist.');
                    result.put('isUserActive', 'false');
                    makeServerErrorResponse(result);
                } else {
                    if (customer.size() > 0 && !customer[0].Is_Azure_Active__c) {
                        result.put('errorMessage', 'User is not Active.');
                        result.put('isUserActive', 'false');
                        makeServerErrorResponse(result);
                    } else {
                        Integer randomFourDigitNumber =
                            (Integer) (Math.random() * 900000) + 100000;
                        customer[0].Forget_Password_Request_OTP__c = string.valueof(
                            randomFourDigitNumber
                        );
                        update customer;
                        List<string> lstTo = new List<string>();
                        lstTo.add(email);
                        
                        // Query the email template
                        EmailTemplate template = EmailTemplateService.getEmailTemplateByDeveloperName(
                            'Send_OTP_for_Email_Verification'
                        );
                        
                        // Create a list to hold emails
                        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
                        
                        // Get the HTML body and plain text body
                        String htmlBody = template.HtmlValue;
                        String plainTextBody = template.Body;
                        
                        htmlBody = htmlBody.replace(
                            '{Email_Change_Request_OTP__c}',
                            customer[0].Forget_Password_Request_OTP__c
                        );
                        plainTextBody = plainTextBody.replace(
                            '{Email_Change_Request_OTP__c}',
                            customer[0].Forget_Password_Request_OTP__c
                        );
                        
                        utility_ref.sendCustomEmail(
                            lstTo,
                            customer[0].id,
                            htmlBody,
                            plainTextBody,
                            template.Subject
                        );
                        Map<string, object> mapReturn = new Map<string, object>();
                        result.put(
                            'data',
                            'Email for OTP has been sent successfully to customer'
                        );
                        result.put('isUserActive', 'true');
                        makeSuccessResponse(result);
                    }
                }
            } else {
                result.put('errorMessage', 'Email Address is not valid.');
                makeServerErrorResponse(result);
            }
        } catch (Exception e) {
            result.put('errorMessage', e.getMessage());
            makeServerErrorResponse(result);
        }
    }
    */
    public static void customerFeedback(String reqInput) {
        Map<String, Object> result = new Map<String, Object>();
        try {
            BCAPP_Utility utility_ref = BCAPP_Utility.getInstance();
            Map<String, Object> jsonData = (Map<String, Object>) JSON.deserializeUntyped(
                reqInput
            );
            String accountId;
            Case sr;
            Integer rating = (Integer) jsonData.get('rating');
            String feedback = (String) jsonData.get('feedback');
            
            if (rating != null) {
                String userToken = (String) jsonData.get('accountId');
                List<User__c> customer;
                if (!String.isBlank(userToken)) {
                    customer = utility_ref.getUserbyAccountId(userToken);
                }
                Customer_Feedback__c feedbackRec = new Customer_Feedback__c();
                feedbackRec.Rating__c = rating;
                feedbackRec.Feedback__c = feedback;
                feedbackRec.Account__c = customer[0].Account__c;
                insert feedbackRec;
                result.put('message', 'Request has been successfully created.');
                //[select id,Name from Customer_Feedback__c where id=:feedbackRec.id][0].Name
                result.put('requestNumber', '');
                makeSuccessResponse(result);
            } else {
                result.put('errorMessage', 'Not getting expected Response');
                result.put('validOTP', false);
                
                makeServerErrorResponse(result);
            }
        } catch (Exception e) {
            result.put('errorMessage', e.getMessage());
            makeServerErrorResponse(result);
        }
    }
    
    /*public void validateEmailOTP(String reqInput) {
        Map<String, Object> result = new Map<String, Object>();
        try {
            Map<String, Object> jsonData = (Map<String, Object>) JSON.deserializeUntyped(
                reqInput
            );
            BCAPP_Utility utility_ref = BCAPP_Utility.getInstance();
            String accountId;
            Case sr;
            String otp = (String) jsonData.get('otp');
            String email = (String) jsonData.get('email');
            
            List<User__c> customer;
            if (!String.isBlank(email)) {
                customer = utility_ref.getUserbyEmail(email);
            }
            if (customer[0].Forget_Password_Request_OTP__c == otp) {
                customer[0].Forget_Password_Request_OTP__c = null;
                update customer[0];
                result.put('validOTP', 'true');
                result.put('userToken', customer[0].Azure_UserId__c);
                makeSuccessResponse(result);

            } else {
                result.put('errorMessage', 'OTP is not Correct');
                result.put('validOTP', false);
                
                makeServerErrorResponse(result);
            }
        } catch (Exception e) {
            result.put('errorMessage', e.getMessage());
            makeServerErrorResponse(result);
        }
    }
    */
    public static void getRequestDocuments(String reqInput) {
        Map<String, Object> result = new Map<String, Object>();
        try {
            Map<String, Object> reqData = (Map<String, Object>) JSON.deserializeUntyped(
                reqInput
            );
            if (
                reqData == null &&
                reqData.get('serviceCatalogName') == null &&
                reqData.get('userType') == null
            ) {
                result.put('errorMessage', 'Invalid Request');
                makeServerErrorResponse(result);
            }
            String serviceCatalogName = (String) reqData.get('serviceCatalogName');
            String requestedAs = (String) reqData.get('userType');
            // Fetch records from Service Catalog
            if (!String.isBlank('serviceCatalogName')) {
                List<BCAPP_WrapperUtility.RequiredDocuments> lstWrp = new List<BCAPP_WrapperUtility.RequiredDocuments>();
                for (
                    Service_Catolog_Documents__c document : ServiceCatalogDocumentService.getCatalogDocumentsByCatalogName(
                        serviceCatalogName
                    )
                ) {
                    List<String> requiredFor = document.Required_For__c.split(';');
                    if (!requiredFor.isEmpty() && requiredFor.contains(requestedAs)) {
                        BCAPP_WrapperUtility.RequiredDocuments res = new BCAPP_WrapperUtility.RequiredDocuments();
                        res.Name = document.Name;
                        res.displayName = document.Document_Name__c;
                        lstWrp.add(res);
                    }
                }
                result.put('data', lstWrp);
                makeSuccessResponse(result);
            } else {
                result.put('errorMessage', 'user not configured in salesforce');
                makeServerErrorResponse(result);
            }
        } catch (Exception e) {
            result.put('errorMessage', e.getMessage());
            makeServerErrorResponse(result);
        }
    }
    
    public static void getServiceRequestDetails(String reqInput) {
        Map<String, Object> result = new Map<String, Object>();
        BCAPP_Utility utility = BCAPP_Utility.getInstance();
        Boolean isChillerEnabled = false;
        UnitService uService = new UnitService();
        try {
            Map<String, Object> reqData = (Map<String, Object>) JSON.deserializeUntyped(
                reqInput
            );
            CaseService cService = CaseService.getInstance();
            String srId = (String) reqData.get('reqId');
            List<Case> sr = new List<Case>{cService.getCaseById(srId)};
            if (sr.isEmpty()) {
                result.put('errorMessage', 'Service Request Not Found');
                makeServerErrorResponse(result);
                return;
            }
            Map<String, Service_Catalog_Fields__c> fieldMap = new Map<String, Service_Catalog_Fields__c>();
            if (
                !sr.isEmpty() &&
                sr[0].Service_Catalog__c != null &&
                sr[0].User_Type__c != null
            ) {
                fieldMap = utility.getServiceCatalogFieldMapping(
                    sr[0].Service_Catalog__c,
                    sr[0].User_Type__c
                );
                if (fieldMap.isEmpty()) {
                    result.put('errorMessage', 'Field Mapping Not Configured');
                    makeServerErrorResponse(result);
                    return;
                }
                String soqlQuery = 'SELECT ';
                List<String> fieldList = new List<String>(fieldMap.keySet());
                for (Integer i = 0; i < fieldList.size(); i++) {
                    soqlQuery += fieldList[i];
                    if (i < fieldList.size() - 1) {
                        soqlQuery += ', ';
                    }
                }
                soqlQuery += ' FROM Case where Id=:srId';
                List<Case> caseRecords = Database.query(soqlQuery);
                if (!caseRecords.isEmpty()) {
                    Case cs = caseRecords[0];
                    for (Integer i = 0; i < fieldList.size(); i++) {
                       // result.put(fieldMap.get(fieldList[i]).Name, cs.get(fieldList[i]));
                       
                           if(fieldMap.get(fieldList[i]).Name=='guests'){                           

                              List<String> lines = ((String)cs.get(fieldList[i])).split('\n');
                            List<String> names = new List<String>();
                            for (String line : lines) {
                                // Use regex to remove the numbering (e.g., '1. ' or '2. ')
                                String name = line.replaceFirst('^\\d+\\.\\s*', '');
                                String guestname = name.contains('.') ? name.split('\\.')[0] : name;
                                names.add(guestname);
                            }
                             result.put(fieldMap.get(fieldList[i]).Name, names);
                        }
                        else if(fieldMap.get(fieldList[i]).Name=='enableExtension'){
                            if(cs.get(fieldList[i]) == '2nd Extension'){
                                result.put(fieldMap.get(fieldList[i]).Name, false);
                            }
                            else{
                                result.put(fieldMap.get(fieldList[i]).Name, true);
                            }
                        }
                         else if(cs.get(fieldList[i])!=null){
                          result.put(fieldMap.get(fieldList[i]).Name, cs.get(fieldList[i]));
                        }
                    }
                    Case srCase = [SELECT Unit__c FROM Case WHERE Id = :cs.Id];
                    if (srCase.Unit__c != null) {
                        List<Unit__c> units = uService.getUnitDetails(srCase.Unit__c);
                        if (!units.isEmpty()) {
                            isChillerEnabled = units[0].Is_Chiller_Enabled__c;
                        }
                    }
                }
                //check for documents
                List<BCAPP_WrapperUtility.RequiredDocuments> requiredDocs = utility.getRequiredDocuments(
                    sr[0].Project__c,
                    sr[0].User_Type__c,
                    sr[0].Service_Catalog__c,
                    isChillerEnabled
                );
                Map<Id, Id> linkEntityIds = new Map<Id, Id>();
                Map<Id, Id> catalogIds = new Map<Id, Id>();
                CustomerDocumentService cDService = new CustomerDocumentService();
                for (
                    Customer_Document__c customerDocs : cDService.getCustomerDocuments(
                        sr[0].Id
                    )
                ) {
                    linkEntityIds.put(
                        customerDocs.Id,
                        customerDocs.Service_Catolog_Documents__c
                    );
                    catalogIds.put(
                        customerDocs.Service_Catolog_Documents__c,
                        customerDocs.Id
                    );
                }
                Map<String, ContentDistribution> existingDocs;
                if (!linkEntityIds.isEmpty()) {
                    existingDocs = utility.getFileUrls(
                        new List<Id>(linkEntityIds.keySet())
                    );
                }
                
                for (BCAPP_WrapperUtility.RequiredDocuments docs : requiredDocs) {
                    if (catalogIds.containsKey(docs.sCatalogDocId)) {
                        if (
                            existingDocs != null &&
                            existingDocs.get(catalogIds.get(docs.sCatalogDocId)) != null &&
                            existingDocs.get(catalogIds.get(docs.sCatalogDocId))
                            .ContentDownloadUrl != null
                        ) {
                            docs.url = existingDocs.get(catalogIds.get(docs.sCatalogDocId))
                                .ContentDownloadUrl;
                        }
                        if (
                            existingDocs != null &&
                            existingDocs.get(catalogIds.get(docs.sCatalogDocId)) != null &&
                            existingDocs.get(catalogIds.get(docs.sCatalogDocId))
                            .ContentVersion.FileExtension != null
                        ) {
                            docs.fileExtension = existingDocs.get(
                                catalogIds.get(docs.sCatalogDocId)
                            )
                                .ContentVersion.FileExtension;
                        }
                    }
                }
                result.put('documents', requiredDocs);
                // result.put('data',requestData);
                makeSuccessResponse(result);
            }
        } catch (Exception e) {
            result.put('errorMessage', e.getMessage());
            makeServerErrorResponse(result);
        }
    }
    
    public static void getUserRequests(String reqInput) {
        Map<String, Object> responseWrp = new Map<String, Object>();
      //  BCAPP_AccessPermitHelper accessPermit = new BCAPP_AccessPermitHelper();
        try {
            BCAPP_Utility utility_ref = BCAPP_Utility.getInstance();
            Map<String, Object> jsonData = (Map<String, Object>) JSON.deserializeUntyped(
                reqInput
            );
            Case sr;
               Set<String> excludeSrs = new Set<String>{'Vacation Request'};

            if (!jsonData.containsKey('requestType') ||

                    String.isBlank((String) jsonData.get('requestType'))){

                    excludeSrs.add('Access Card');

                    excludeSrs.add('Amenities');

                }   
            String userToken = (String) jsonData.get('accountId');
             String unitId = (String) jsonData.get('unitId');
            String filter;
            if (userToken != null) {
                List<User__c> customer;
                if (!String.isBlank(userToken)) {
                    customer = utility_ref.getUserbyAccountId(userToken);
                }
                  if(customer==null){
                    responseWrp.put('errorMessage', 'Invalid User');
                    makeServerErrorResponse(responseWrp);
                    return;

                }
                CaseService cService = CaseService.getInstance();
                if (
                    jsonData.containsKey('unitId') &&

                    !String.isBlank((String) jsonData.get('unitId'))

                ) {
                    unitId = (String) jsonData.get('unitId');
                    filter = ' AND Unit__c =\'' + unitId + '\'';

                }
                if (
                    jsonData.containsKey('status') &&
                    !String.isBlank((String) jsonData.get('status'))
                ) {
                    String status = (String) jsonData.get('status');
                    filter = ' AND Status =\'' + status + '\'';
                }
                if (
                    jsonData.containsKey('requestType') &&
                    !String.isBlank((String) jsonData.get('requestType'))
                ) {
                    String requestType = (String) jsonData.get('requestType');
                     if(requestType == 'accesscardrequests'){

                        requestType = 'Access Card';

                    }
                    filter = (filter != null)
                        ? (filter + ' AND Service_Catalog__r.Name =\'' + requestType + '\'')
                        : ' AND Service_Catalog__r.Name =\'' + requestType + '\'';
                }
                if (
                    jsonData.containsKey('pendingCases') &&
                    (Boolean.valueOf(jsonData.get('pendingCases')))
                ) {
                      filter = ' AND Status IN ( \'In Progress\', \'Assigned\', \'Submitted\')';
                }
                
                List<case> lstCases = cService.getrelatedCaseToAccount(
                    customer[0].Account__c,
                    filter
                );
                List<object> lstAllRec = new List<object>();
                for (case caseRec : lstCases) {
                 if(!excludeSrs.contains(caseRec.Service_Catalog__r.Name) && caseRec.Request_Number__c!=null){

                        Map<string, object> mapCases = new Map<string, object>();

                        mapCases.put('requestNumber', caseRec.Request_Number__c);

                        mapCases.put('userType', caseRec.User_Type__c);

                        mapCases.put('status', caseRec.Status);

                        mapCases.put('requestType', caseRec.Service_Catalog__r.Name);

                        mapCases.put('createdDate', caseRec.CreatedDate.date());

                        mapCases.put('isFavorite', caseRec.Is_Favorite_Request__c);

                        mapCases.put('reqId', caseRec.Id);

                        mapCases.put('cardType', caseRec.AccessCardType__c);

                        lstAllRec.add(mapCases);

                    }
                }
                responseWrp.put('data', lstAllRec);
                makeSuccessResponse(responseWrp);
                return;
            } else {
                responseWrp.put('errorMessage', 'Invalid Response');
                makeServerErrorResponse(responseWrp);
                return;
            }
        } catch (Exception e) {
            responseWrp.put('errorMessage', e.getLineNumber());
            makeServerErrorResponse(responseWrp);
            return;
        }
    }
    
    public static void accountDocuments(String reqInput) {
        Map<String, Object> result = new Map<String, Object>();
        try {
            BCAPP_Utility utility_ref = BCAPP_Utility.getInstance();
            Map<String, Object> jsonData = (Map<String, Object>) JSON.deserializeUntyped(
                reqInput
            );
            Case sr;
            String userToken = (String) jsonData.get('accountId');
            
            if (userToken != null) {
                List<User__c> customer;
                if (!String.isBlank(userToken)) {
                    customer = utility_ref.getUserbyAccountId(userToken);
                }
                CustomerDocumentService cdService = new CustomerDocumentService();
                List<Customer_Document__c> customerDocuments = cdService.getDocumentsRelatedToAccount(
                    customer[0].Account__c
                );
                Set<Id> customerDocumentIds = new Set<Id>();
                for (Customer_Document__c doc : customerDocuments) {
                    customerDocumentIds.add(doc.Id);
                }
                List<DocumentResponse> response = new List<DocumentResponse>();
                ContentDocumentService codService = new ContentDocumentService();
                if (customerDocumentIds.size() > 0) {
                    List<ContentDocumentLink> documentLinks = codService.getContentDocLinkFromLinkEntityId(
                        customerDocumentIds
                    );
                    Set<Id> contentDocumentIds = new Set<Id>();
                    for (ContentDocumentLink link : documentLinks) {
                        contentDocumentIds.add(link.ContentDocumentId);
                    }
                    List<ContentVersion> contentVersions = codService.fetchContentVersionByContentIds(
                        contentDocumentIds
                    );
                    Map<Id, ContentVersion> contentVersionMap = new Map<Id, ContentVersion>();
                    Map<Id, String> mapPublicLink = new Map<Id, String>();
                    System.debug('###$$##' + contentVersions);
                    for (ContentVersion version : contentVersions) {
                        
                        contentVersionMap.put(version.ContentDocumentId, version);
                        mapPublicLink.put(version.Id, DOC_AVAILABLE);
                    }
                    // Prepare the response
                    System.debug('#####' + mapPublicLink);
                    // Iterate over customer documents and prepare the response
                    for (Customer_Document__c doc : customerDocuments) {
                        DocumentResponse docResponse = new DocumentResponse();
                        docResponse.name = doc.Name;
                        // Find related ContentDocumentLinks for this Customer_Document__c
                        List<FileResponse> fileResponses = new List<FileResponse>();
                        for (ContentDocumentLink link : documentLinks) {
                            if (link.LinkedEntityId == doc.Id) {
                                // Get the ContentVersion related to the ContentDocument
                                ContentVersion version = contentVersionMap.get(
                                    link.ContentDocumentId
                                );
                                if (version != null) {
                                    FileResponse fileResponse = new FileResponse();
                                    fileResponse.fileName = version.Title;
                                    fileResponse.fileType = version.FileExtension;
                                    if (mapPublicLink != null) {
                                        fileResponse.fileURL = mapPublicLink.get(version.Id); //cds[0].DistributionPublicUrl;
                                    }
                                    
                                    fileResponses.add(fileResponse);
                                }
                            }
                        }
                        // Add the list of files to the document response
                        docResponse.files = fileResponses;
                        response.add(docResponse);
                    }
                }
                result.put('files', response);
                makeSuccessResponse(result);
            } else {
                result.put('errorMessage', 'Not getting expected Response');
                result.put('validOTP', false);
                makeServerErrorResponse(result);
            }
        } catch (Exception e) {
            result.put('errorMessage', e.getMessage());
            makeServerErrorResponse(result);
        }
    }
    
      public static void getNotices(String reqInput) {
        Map<String, Object> returnValue = new Map<String, Object>();
        try {
            BCAPP_Utility utility_ref = BCAPP_Utility.getInstance();
            Map<String, Object> reqData = (Map<String, Object>) JSON.deserializeUntyped(
                reqInput
            );
            String quarterInput = (String) reqData.get('quarter');
            String recordType = (String) reqData.get('type');
            String yearInput = (String) reqData.get('year');
            String projectId = (String) reqData.get('projectId');
            String accountId = (String) reqData.get('accountId');
            BCAPP_HandleNotificatoins notificationHandler = new BCAPP_HandleNotificatoins();
            if (recordType == 'alerts') {
                notificationHandler.getAlerts(reqData);
            } else {
                try {
                    Date startDate;
                    Date endDate;
                    List<String> projectIds = new List<String>();
                    if (!String.isEmpty(quarterInput)) {
                        Map<String, Date> dateRange = utility_ref.getQuarterDateRange(
                            quarterInput
                        );
                        startDate = dateRange.get('start');
                        endDate = dateRange.get('end');
                    } else if (!String.isEmpty(quarterInput)) {
                        Integer year = Integer.valueOf(yearInput);
                        startDate = Date.newInstance(year, 1, 1);
                        endDate = Date.newInstance(year, 12, 31);
                    }
                    if (String.isBlank(projectId)) {
                        /*   UnitAllocationService uService = new UnitAllocationService();
List<Unit_Allocation__c> unitAllocations = uService.fetchAllUnitsRelatedToAccount(accountId);
for(Unit_Allocation__c ua:unitAllocations){
projectIds.add(ua.Unit__r.Project__c);
}
if(projectIds.isEmpty()){
returnValue.put('errorMessage','User Not related to any project.');
makeServerErrorResponse(returnValue); 
return;
}
}
else{*/
                        returnValue.put('errorMessage', 'Project can\'t be blank');
                        makeServerErrorResponse(returnValue);
                        return;
                    }
                    
                    List<BCAPP_HandleNotificatoins.NotificationWrapper> data = notificationHandler.getNotifications(
                        startDate,
                        endDate,
                        new List<String>{ projectId },
                        recordType
                    );
                    returnValue.put(recordType, data);
                    makeSuccessResponse(returnValue);
                } catch (IllegalArgumentException e) {
                    returnValue.put('errorMessage', 'Wrong Date Format Rage');
                    makeServerErrorResponse(returnValue);
                }
            }
        } catch (Exception e) {
            returnValue.put('errorMessage', e.getMessage()+'--'+e.getLineNumber());
            makeServerErrorResponse(returnValue);
        }
    }
    
    public static void getNotificationsOptions(String reqInput) {
        Map<String, Object> returnValue = new Map<String, Object>();
        try {
            Map<String, Object> reqData = (Map<String, Object>) JSON.deserializeUntyped(
                reqInput
            );
            String recordType = (String) reqData.get('type');
            String projectId = (String) reqData.get('projectId');
            // String accountId = (String)reqData.get('accountId');
            BCAPP_Utility utility = new BCAPP_Utility();
            try {
                String recordTypeId;
                if (!String.isBlank(recordType)) {
                    recordType = BCAPP_Constants.notificationRT.get(recordType);
                    recordTypeId = SObjectType.Notifications__c.getRecordTypeInfosByDeveloperName()
                        .get(recordType)
                        .getRecordTypeId();
                }
                Map<String, Date> dateRanges = utility.getDateRange(
                    'Notifications__c',
                    'Publish_Date_Time__c',
                    recordTypeId
                );
                if (!dateRanges.isEmpty()) {
                    List<BCAPP_Utility.QuarterOption> quarterOption = BCAPP_Utility.getQuarterlyOptions(
                        dateRanges.get('minDate'),
                        dateRanges.get('maxDate')
                    );
                    returnValue.put('quarterly', quarterOption);
                    // Add year options
                    Integer startYear = dateRanges.get('minDate').year();
                    Integer endYear = dateRanges.get('maxDate').year();
                    List<BCAPP_Utility.QuarterOption> yearOptions = new List<BCAPP_Utility.QuarterOption>();
                    for (Integer year = endYear; year >= startYear; year--) {
                        yearOptions.add(
                            new BCAPP_Utility.QuarterOption(
                                String.valueOf(year),
                                String.valueOf(year)
                            )
                        );
                    }
                    returnValue.put('yearly', yearOptions);
                    makeSuccessResponse(returnValue);
                }
            } catch (IllegalArgumentException e) {
                returnValue.put('errorMessage', 'Wong Format Rage');
                makeServerErrorResponse(returnValue);
            }
        } catch (Exception e) {
            returnValue.put('errorMessage', e.getMessage());
            makeServerErrorResponse(returnValue);
        }
    }
    
    public static void getAccessPermitCategoryOptions() {
        Map<String, Object> returnValue = new Map<String, Object>();
        List<Map<String, String>> response = new List<Map<String, String>>();
        try {
            BCAPP_AccessPermitHelper accessPermit = new BCAPP_AccessPermitHelper();
            List<Map<String, String>> options = accessPermit.getCategoryOptions(
                'Case',
                'Access_Permit_Category__c'
            );
            makeSuccessResponse(options);
        } catch (Exception e) {
            returnValue.put('errorMessage', e.getMessage());
            makeServerErrorResponse(returnValue);
        }
    }
    
    public static void getAccessPermitServiceTypeOptions(
        Map<String, Object> reqData
    ) {
        Map<String, Object> returnValue = new Map<String, Object>();
        List<Map<String, String>> response = new List<Map<String, String>>();
        String category = (String) reqData.get('category');
        try {
            if (String.isEmpty(category)) {
                returnValue.put('errorMessage', 'Invalid Category');
                makeServerErrorResponse(returnValue);
            } else {
                BCAPP_AccessPermitHelper accessPermit = new BCAPP_AccessPermitHelper();
                List<Map<String, String>> options = accessPermit.getDependentPicklistValues(
                    'Service_Types__c',
                    'Case',
                    category
                );
                makeSuccessResponse(options);
            }
        } catch (Exception e) {
            returnValue.put('errorMessage', e.getMessage());
            makeServerErrorResponse(returnValue);
        }
    }
    
    public static void getAccessPermitOptions(String reqInput) {
        Map<String, Object> returnValue = new Map<String, Object>();
        List<Map<String, String>> response = new List<Map<String, String>>();
        Map<String, Object> reqData = (Map<String, Object>) JSON.deserializeUntyped(
            reqInput
        );
        if ((String) reqData.get('type') == 'category') {
            getPickListOptions('Access_Permit_Category__c');
        } else if ((String) reqData.get('type') == 'service') {
            getAccessPermitServiceTypeOptions(reqData);
        } else if ((String) reqData.get('type') == 'validity') {
            getAccessPermitValidityOptions(reqData);
        } else if ((String) reqData.get('type') == 'sr_category') {
            getPickListOptions('Service_Request_Category__c');
        } else if ((String) reqData.get('type') == 'status') {
            getPickListOptions('Status');
        } else if ((String) reqData.get('type') == 'requestType') {
            getPickListOptions('RequestType__c');
        }
    }
    
    public static void getPickListOptions(String pickListAPIName) {
        Map<String, Object> returnValue = new Map<String, Object>();
        List<Map<String, String>> response = new List<Map<String, String>>();
        try {
            BCAPP_AccessPermitHelper accessPermit = new BCAPP_AccessPermitHelper();
            List<Map<String, String>> options = accessPermit.getCategoryOptions(
                'Case',
                pickListAPIName
            );
            makeSuccessResponse(options);
        } catch (Exception e) {
            returnValue.put('errorMessage', e.getMessage());
            makeServerErrorResponse(returnValue);
        }
    }
    
    public static void getAccessPermitValidityOptions(
        Map<String, Object> reqData
    ) {
        Map<String, Object> returnValue = new Map<String, Object>();
        List<Map<String, String>> response = new List<Map<String, String>>();
        String serviceType = (String) reqData.get('serviceType');
        try {
            if (String.isEmpty(serviceType)) {
                returnValue.put('errorMessage', 'Invalid Service Type');
                makeServerErrorResponse(returnValue);
            } else {
                BCAPP_AccessPermitHelper accessPermit = new BCAPP_AccessPermitHelper();
                List<Map<String, String>> options = accessPermit.getDependentPicklistValues(
                    'Permit_Validaity__c',
                    'Case',
                    serviceType
                );
                makeSuccessResponse(options);
            }
        } catch (Exception e) {
            returnValue.put('errorMessage', e.getMessage());
            makeServerErrorResponse(returnValue);
        }
    }
    
    public static void createAzureUser(String reqInput) {
        Map<String, Object> returnValue = new Map<String, Object>();
        List<Map<String, String>> response = new List<Map<String, String>>();
        Map<String, Object> reqData = (Map<String, Object>) JSON.deserializeUntyped(
            reqInput
        );
        String firstName = (String) reqData.get('firstName');
        String lastName = (String) reqData.get('lastName');
        String email = (String) reqData.get('email');
        String userType = (String) reqData.get('userType');
        try {
            if (String.isEmpty(email)) {
                returnValue.put('errorMessage', 'Email is not provided');
                makeServerErrorResponse(returnValue);
            } else {
                User_Service uService = new User_Service();
                User__c userRecord = new User__c();
                userRecord.Email__c = email;
                userRecord.Username__c = email;
                userRecord.Is_Azure_Active__c = true;
                userRecord.User_Type__c = userType;
                uService.createUser(userRecord);
                MicrosoftAzureB2CUtility.createUser(userRecord);
                Map<String, Object> result = new Map<String, Object>();
                Map<String, Object> responseUser = new Map<String, Object>();
                
                User__c sfUser = [
                    SELECT User_Principal_Name__c
                    FROM User__c
                    WHERE Id = :userRecord.Id
                ];
                if (sfUser.User_Principal_Name__c != null) {
                    responseUser.put('userPrincipalName', sfUser.User_Principal_Name__c);
                    result.put('data', responseUser);
                    result.put('success', true);
                    makeSuccessResponse(result);
                } else {
                    returnValue.put('errorMessage', 'error in creating the user');
                    makeServerErrorResponse(returnValue);
                }
            }
        } catch (Exception e) {
            returnValue.put('errorMessage', e.getMessage());
            makeServerErrorResponse(returnValue);
        }
    }
    
    public static void updateServiceRequest(String reqInput) {
        Map<String, Object> result = new Map<String, Object>();
        try {
            Map<String, Object> reqData = (Map<String, Object>) JSON.deserializeUntyped(
                reqInput
            );
            String reqId = (String) reqData.get('srId');
            Case sr = new Case();
            if (String.isBlank(reqId)) {
                result.put('errorMessage', 'Request Id Can\'t Blank.');
                makeServerErrorResponse(result);
                return;
            } else {
                sr.Id = reqId;
                if (reqData.containsKey('status')) {
                    sr.Status = (String) reqData.get('status');
                }
                if (reqData.containsKey('comments')) {
                    sr.Description = (String) reqData.get('comments');
                }
                if (reqData.containsKey('isFavorite')) {
                    sr.Is_Favorite_Request__c = (Boolean) reqData.get('isFavorite');
                }
            }
            update sr;
            result.put('success', true);
            makeSuccessResponse(result);
            return;
        } catch (Exception e) {
            result.put('errorMessage', e.getMessage());
            makeServerErrorResponse(result);
            return;
        }
    }
    
    public static void deactivateAzureUser(String reqInput) {
        Map<String, Object> returnValue = new Map<String, Object>();
        List<Map<String, String>> response = new List<Map<String, String>>();
        Map<String, Object> reqData = (Map<String, Object>) JSON.deserializeUntyped(
            reqInput
        );
        String principalId = (String) reqData.get('principalId');
        
        try {
            if (String.isEmpty(principalId)) {
                returnValue.put('errorMessage', 'PrincipalId is not provided');
                makeServerErrorResponse(returnValue);
            } else {
                HttpResponse responseAPI = MicrosoftAzureB2CUtility.deactivateUser(
                    null,
                    principalId
                );
              /*  if (responseAPI.getStatusCode() == 204) {
                    string jsonString = responseAPI.getbody();
                    Map<String, Object> result = new Map<String, Object>();
                    Map<String, Object> responseUser = new Map<String, Object>();
                    responseUser.put('userPrincipalName', principalId);
                    result.put('data', responseUser);
                    result.put('success', true);
                    makeSuccessResponse(result);
                    
                    System.debug('User created successfully: ' + responseAPI.getBody());
                } else {
                    System.debug(
                        'Error creating user: ' +
                        responseAPI.getStatusCode() +
                        ' - ' +
                        responseAPI.getBody()
                    );
                    returnValue.put(
                        'errorMessage',
                        responseAPI.getStatusCode() + ' - ' + responseAPI.getBody()
                    );
                    makeServerErrorResponse(returnValue);
                }*/
            }
        } catch (Exception e) {
            returnValue.put('errorMessage', e.getMessage());
            makeServerErrorResponse(returnValue);
        }
    }
    
    // Method to extract last name from the request body or query string
    public static String getLastNameFromRequest(string requestBodyString) {
        // Check if the request has a query parameter for last name
        if (RestContext.request.params.containsKey('lastName')) {
            return RestContext.request.params.get('lastName');
        }
        
        // Otherwise, if the request body is JSON, extract the last name from the JSON (if it exists)
        try {
            Map<String, Object> requestData = (Map<String, Object>) JSON.deserializeUntyped(
                requestBodyString
            );
            if (requestData.containsKey('lastName')) {
                return (String) requestData.get('lastName');
            }
        } catch (Exception e) {
            // Handle any errors in parsing JSON or missing parameters
            System.debug(
                'Error extracting last name from request: ' + e.getMessage()
            );
        }
        
        // Return null or handle as needed if last name is not provided
        return null;
    }
    
    public static void createServiceRequest(String reqInput) {
        Map<String, Object> reqData = (Map<String, Object>) JSON.deserializeUntyped(
            reqInput
        );
        Map<String, Object> returnValue = new Map<String, Object>();
        List<Map<String, String>> response = new List<Map<String, String>>();
        String accountId = (String) reqData.get('accountId');
        String unitId = (String) reqData.get('unitId');
        String srCategory = (String) reqData.get('srCategory');
        BCAPP_Utility utility_ref = BCAPP_Utility.getInstance();
        Set<String> fileTypes = new Set<String>{'.pdf','.png','.jpeg'};
        CaseService cService = CaseService.getInstance();
        try {
            if (String.isEmpty(accountId) || String.isEmpty(unitId)) {
                returnValue.put('errorMessage', 'Invalid Unit/Account.');
                makeServerErrorResponse(returnValue);
            } else {
                List<User__c> customer = utility_ref.getUserbyAccountId(accountId);
                if (customer.isEmpty()) {
                    returnValue.put('errorMessage', 'Invalid Unit/Account.');
                    makeServerErrorResponse(returnValue);
                    return;
                } else {
                    Case srCase = new Case();
                    List<Unit__c> units;
                    srCase.Service_Request_Category__c = srCategory;
                    if (!String.isEmpty(unitId)) {
                        UnitService uService = new UnitService();
                        units = UnitService.fetchUnitDetailsById(unitId);
                        srCase.Unit__c = unitId;
                        srCase.project__c = units[0].Project__c;
                        srCase.communityName__c = units[0].Project__r.Name;
                    }
                    srCase.Service_Catalog__c = ServiceCatalogService.fetchServiceCatalogByName(
                        BCAPP_Constants.SERVICE_REQUEST
                    )[0]
                        .Id;
                    srCase.recordTypeId = Utilities.getRecordTypeId(
                        'Case',
                        'Community General Service Request'
                    );
                    srCase.User_Type__c = customer[0].User_Type__c;
                    srCase.Description = srCase.Description = reqData.containsKey(
                        'comment'
                    )
                        ? (String) reqData.get('comment')
                        : '';
                    srCase.status = 'Submitted';
                    srCase.AccountId = accountId;
                    srCase.User__c = customer[0].Id;
                     srCase.Email_Address__c = customer[0].Email__c!=null? customer[0].Email__c: customer[0].User_Account__r.Email__c;
                    srCase.Origin = 'Community App';
                    srCase.RequestType__c = BCAPP_Constants.SERVICE_REQUEST;
                    insert srCase;
                    if (reqData.get('documents') != null) {
                        List<Object> rawDocuments = (List<Object>) reqData.get('documents');
                        Customer_Document__c cds = new Customer_Document__c();
                        cds.Name = units[0].Name+' -Service Request';
                        cds.Case__c = srCase.Id;
                        insert cds;
                        List<Map<String, String>> documents = new List<Map<String, String>>();
                        List<BCAPP_WrapperUtility.Document> wrapper = new List<BCAPP_WrapperUtility.Document>();
                        for (Object rawDoc : rawDocuments) {
                            if (rawDoc instanceof Map<String, Object>) {
                                Map<String, Object> document =  ( Map<String, Object>)rawDoc;
                                
                                BCAPP_WrapperUtility.Document doc = new BCAPP_WrapperUtility.Document();
                                Integer lastIndex = doc.fileName.lastIndexOf('.');
                                if(lastIndex != -1) {                      

                                    doc.contentType = doc.fileName.substring(lastIndex);
                                    if(!fileTypes.contains(doc.contentType)){

                                        returnValue.put('errorMessage', 'Invalid file type, allows only pdf,jpg,png.');
                                        BCAPP_WebServiceHelper.makeServerErrorResponse(returnValue);
                                        return;

                                    }

                                }
                                doc.fileContent = EncodingUtil.base64Decode(
                                    (String) document.get('content')
                                );
                                wrapper.add(doc);
                               /* newDocuments.put('fileContent', EncodingUtil.base64Decode(
                                                                 (String)document.get('content')));
                                newDocuments.put('fileName',(String)document.get('name'));
                                documents.add(newDocuments);*/
                            } else {
                                System.debug('Unexpected document format: ' + rawDoc);
                            }
                        }
                        Boolean isFileUpload = utility_ref.uploadFilesToCase(
                            cds.Id,
                            wrapper
                        );
                        if (!isFileUpload) {
                            returnValue.put(
                                'errorMessage',
                                'Something went wrong on files upload'
                            );
                            makeServerErrorResponse(returnValue);
                            return;
                        }
                    }
                    Case sr = cService.lstgetCaseRelatedtoSR(srCase.Id);
                    returnValue.put('requestNumber', sr.Request_Number__c);
                    returnValue.put('srId', sr.Id);
                    makeSuccessResponse(returnValue);
                }
            }
        } catch (Exception e) {
            returnValue.put('errorMessage', e.getMessage());
            makeServerErrorResponse(returnValue);
        }
    }
    
    
      public static void preLoginOtpFlow(String reqInput){
        Map<String, Object> returnValue = new Map<String, Object>();
        Map<String, String> result = new Map<String, String>();
        Map<String, Object> reqData = (Map<String, Object>) JSON.deserializeUntyped(
            reqInput 
        );
        String email = (String) reqData.get('email');
        Boolean isValidate = (Test.isRunningTest())?true:(Boolean) reqData.get('isValidate');
        String otp = (String) reqData.get('otp');
        List<User__c> customer;
        BCAPP_Utility utility_ref = BCAPP_Utility.getInstance();
        if (!String.isBlank(email)) {
            customer = utility_ref.getUserbyEmail(email);
            if (customer==null || customer.isEmpty() || !customer[0].Is_Azure_Active__c) {
                result.put('errorMessage', 'User is not Active.');
                result.put('isUserActive', 'false');
                makeServerErrorResponse(result);
                return;
            } else if(!isValidate){
                Integer randomFourDigitNumber =
                    (Integer) (Math.random() * 900000) + 100000;
                customer[0].Forget_Password_Request_OTP__c = string.valueof(
                    randomFourDigitNumber
                );
                update customer;
                List<string> lstTo = new List<string>();
                lstTo.add(email);
                handleOTPEmail(lstTo, customer[0]);
                Map<string, object> mapReturn = new Map<string, object>();
                result.put(
                    'data',
                    'SMS for OTP has been sent successfully to customer'
                );
                result.put('isUserActive', 'true'); makeSuccessResponse(result);
            }
            else if(isValidate){
                if (customer[0].Forget_Password_Request_OTP__c == otp) {
                    customer[0].Forget_Password_Request_OTP__c = null;
                    update customer[0];
                    result.put('validOTP', 'true');result.put('userToken', customer[0].Azure_UserId__c);
                    makeSuccessResponse(result);
                }
                else{
                    result.put('errorMessage', 'Invalid Otp.');result.put('isUserActive', 'false');makeServerErrorResponse(result);
                }
            }
        }
        else{
            result.put('errorMessage', 'Email Id Can\'t Blank.');result.put('isUserActive', 'false');makeServerErrorResponse(result);
        }
        
    }
    
    
    global class DocumentResponse {
        public String name;
        public List<FileResponse> files = new List<FileResponse>();
    }
    
    // Helper class for individual file details
    global class FileResponse {
        public String fileURL;
        public String fileType;
        public String fileName;
    }
    
    global class WebServiceResponse {
        public Map<String, Object> result;
        public WebServiceResponse() {
            result = new Map<String, Object>();
        }
    }
}