/*
* @Author      : Akshay Khairnar 
* @CreatedDate : 19th SEP 2025
* @Description : Class contains the logic to retrieve broker-assigned and public units based on filters and user role through API
*/
/*****************************************************************************************************
* Version       Author      	   Date             Comment                                                                       
* 1.1           Akshay Khairnar    19th SEP 2025    Initial Draft
*****************************************************************************************************/
public inherited sharing class BAPPGetUnitListHandler {
    
    // -----------------------------
    // Request wrapper
    // -----------------------------
    private class UnitAssignmentRequest {
        public Id contactId;
        public Id accountId;
        public Id projectId;
        public String unitSearchKey;
        public Decimal minimumBudget;
        public Decimal maximumBudget;
        public Decimal minimumArea;
        public Decimal maximumArea;
        public String unitModel;
        public String unitType;
    }
    
    // -----------------------------
    // Unified API Response
    // -----------------------------
    private class UnitApiResponse {
        public String status;
        public String message;
        public List<UnitResponse> allocations;
    }
    
    private class UnitResponse {
        public String projectName;
        public Id unitId;
        public Id projectId;
        public String unitName;
        public String unitNumber;
        public String unitType;
        public String unitModel;
        public Decimal areaSqFt;
        public Decimal priceAED;
        public Boolean publicUnit;
        public Id brokerUnitAllocationId;
        public Id contactId;
        public String floorPlanDownloadLink;
        public List<ContactResponse> contacts = new List<ContactResponse>();
    }
    
    private class ContactResponse {
        public String contactName;
        public Id contactId;
        public Id brokerUnitAssignmentId;
        public String brokerContactRole;
    }
    
    // -----------------------------
    // Main handler
    // -----------------------------
    public static void handleGetUnitList(String requestBody) {
        try {
            UnitAssignmentRequest input = 
                (UnitAssignmentRequest) JSON.deserialize(requestBody, UnitAssignmentRequest.class);
            
            if (input == null) {
                returnError(Label.BAPP_Invalid_Request_Body);
                return;
            }
            if (input.accountId == null) {
                returnError(Label.BAPP_AccountId_Required);
                return;
            }
            if (input.contactId == null) {
                returnError(Label.BAPP_ContactId_Required);
                return;
            }
            
            if (input.minimumBudget != null && input.maximumBudget != null && input.minimumBudget > input.maximumBudget) {
                returnError(Label.BAPP_MinBudget_Greater_Than_MaxBudget);
                return;
            }
            if (input.minimumArea != null && input.maximumArea != null && input.minimumArea > input.maximumArea) {
                returnError(Label.BAPP_MinArea_Greater_Than_MaxArea);
                return;
            }
            
            // Clean input projectId
            if (String.isBlank(input.projectId)) input.projectId = null;
            
            // Parse lists
            List<String> unitTypeList = splitMultiValue(input.unitType);
            List<String> unitModelList = splitMultiValue(input.unitModel);
            
            
            // Validate contact
            Contact currentContact = ContactService.getInstance().getContactById(input.contactId); //optimize
            
            if (currentContact.AccountId != input.accountId) {
                returnError(Label.BAPP_Contact_Not_Belong_To_Account);
                return;
            }
            
            String roles = currentContact.BrokerContactRole__c != null ? currentContact.BrokerContactRole__c.toLowerCase() : '';
            Boolean isPrivileged = roles.contains('admin') || roles.contains('superadmin') || roles.contains('ceo');
            
            // Prepare response
            UnitApiResponse apiResp = new UnitApiResponse();
            apiResp.allocations = new List<UnitResponse>();
            apiResp.status = 'success';
            apiResp.message = Label.BAPP_Units_Fetched_Successfully;
            
            Set<Id> addedUnitIds = new Set<Id>();
            
            Datetime currentDateTime = System.now();
            // FETCH ASSIGNED UNITS
            String assignedQuery =
                'SELECT Id, BrokerUnitAllocation__c, Contact__c, ' +
                'BrokerUnitAllocation__r.Unit__c, BrokerUnitAllocation__r.Unit__r.Name, ' +
                'BrokerUnitAllocation__r.Unit__r.UnitNumber__c, ' +
                'BrokerUnitAllocation__r.Unit__r.Project__r.Name, ' +
                'BrokerUnitAllocation__r.Unit__r.Project__c, ' +
                'BrokerUnitAllocation__r.Unit__r.SellingPrice__c, ' +
                'BrokerUnitAllocation__r.Unit__r.SaleableArea__c, ' +
                'BrokerUnitAllocation__r.Unit__r.UnitModel__c, ' +
                'BrokerUnitAllocation__r.Unit__r.UnitType__c, ' +
                'BrokerUnitAllocation__r.Unit__r.IsPublic__c, ' +
                'BrokerUnitAllocation__r.Unit__r.WebFloorPlan__c ' +
                'FROM BrokerUnitAssignment__c ' +
                'WHERE Active__c = true ' +
                'AND UnitStatus__c = \'Available\' ' +
                'AND BrokerUnitAllocation__r.EndDate__c >= :currentDateTime ';
            
            if (input.contactId != null)
                assignedQuery += 'AND Contact__c = \'' + String.escapeSingleQuotes(input.contactId) + '\' ';
            if (input.accountId != null)
                assignedQuery += 'AND BrokerUnitAllocation__r.Account__c = \'' + String.escapeSingleQuotes(input.accountId) + '\' ';
            if (input.projectId != null)
                assignedQuery += 'AND BrokerUnitAllocation__r.Unit__r.Project__c = \'' + String.escapeSingleQuotes(input.projectId) + '\' ';
            
            String likeSearchKey;
            if (!String.isBlank(input.unitSearchKey)) {
                likeSearchKey = '%' + input.unitSearchKey + '%';
                assignedQuery += 'AND BrokerUnitAllocation__r.Unit__r.Name LIKE :likeSearchKey ';
            }
            
            
            if (!unitModelList.isEmpty())
                assignedQuery += 'AND BrokerUnitAllocation__r.Unit__r.UnitModel__c IN :unitModelList ';
            
            if (!unitTypeList.isEmpty())
                assignedQuery += 'AND BrokerUnitAllocation__r.Unit__r.UnitType__c IN :unitTypeList ';
            
            if (input.minimumBudget != null)
                assignedQuery += 'AND BrokerUnitAllocation__r.Unit__r.SellingPrice__c >= ' + input.minimumBudget + ' ';
            if (input.maximumBudget != null)
                assignedQuery += 'AND BrokerUnitAllocation__r.Unit__r.SellingPrice__c <= ' + input.maximumBudget + ' ';
            if (input.minimumArea != null)
                assignedQuery += 'AND BrokerUnitAllocation__r.Unit__r.SaleableArea__c >= ' + input.minimumArea + ' ';
            if (input.maximumArea != null)
                assignedQuery += 'AND BrokerUnitAllocation__r.Unit__r.SaleableArea__c <= ' + input.maximumArea + ' ';
            
            List<BrokerUnitAssignment__c> assignedUnits = Database.query(assignedQuery);
            
            // Collect allocationIds
            Set<Id> allocationIds = new Set<Id>();
            for (BrokerUnitAssignment__c bua : assignedUnits) {
                if (bua.BrokerUnitAllocation__c != null)
                    allocationIds.add(bua.BrokerUnitAllocation__c);
            }
            
            // FETCH ALL CONTACTS FOR EACH ALLOCATION
            Map<Id, List<ContactResponse>> allocToContacts = new Map<Id, List<ContactResponse>>();
            if (!allocationIds.isEmpty()) {
                
                List<BrokerUnitAssignment__c> assignments = isPrivileged ? getPrivilegedAssignments(allocationIds) : getRestrictedAssignments(allocationIds, input.contactId); // optmize
                
                for (BrokerUnitAssignment__c bua : assignments) {
                    if (!allocToContacts.containsKey(bua.BrokerUnitAllocation__c)) {
                        allocToContacts.put(bua.BrokerUnitAllocation__c, new List<ContactResponse>());
                    }
                    ContactResponse cr = new ContactResponse();
                    cr.contactId = bua.Contact__c;
                    cr.contactName = bua.Contact__r != null ? bua.Contact__r.Name : null;
                    cr.brokerUnitAssignmentId = bua.Id;
                    cr.brokerContactRole = bua.Contact__r.BrokerContactRole__c;
                    allocToContacts.get(bua.BrokerUnitAllocation__c).add(cr);
                }
            }
            
            // MAP ASSIGNMENTS TO UNIT RESPONSES
            for (BrokerUnitAssignment__c bua : assignedUnits) {
                UnitResponse ur = new UnitResponse();
                ur.projectName = bua.BrokerUnitAllocation__r.Unit__r.Project__r.Name;
                ur.projectId = bua.BrokerUnitAllocation__r.Unit__r.Project__c;
                ur.unitId = bua.BrokerUnitAllocation__r.Unit__c;
                ur.unitName = bua.BrokerUnitAllocation__r.Unit__r.Name;
                ur.unitNumber = bua.BrokerUnitAllocation__r.Unit__r.UnitNumber__c;
                ur.priceAED = bua.BrokerUnitAllocation__r.Unit__r.SellingPrice__c;
                ur.areaSqFt = bua.BrokerUnitAllocation__r.Unit__r.SaleableArea__c;
                ur.unitModel = bua.BrokerUnitAllocation__r.Unit__r.UnitModel__c;
                ur.unitType = bua.BrokerUnitAllocation__r.Unit__r.UnitType__c;
                ur.floorPlanDownloadLink = bua.BrokerUnitAllocation__r.Unit__r.WebFloorPlan__c;
                ur.publicUnit = bua.BrokerUnitAllocation__r.Unit__r.IsPublic__c;
                ur.brokerUnitAllocationId = bua.BrokerUnitAllocation__c;
                ur.contactId = bua.Contact__c;
                
                // Populate contacts list if privileged
                if (isPrivileged && allocToContacts.containsKey(bua.BrokerUnitAllocation__c)) {
                    for (ContactResponse cr : allocToContacts.get(bua.BrokerUnitAllocation__c)) {
                        if (cr.contactId != input.contactId) {
                            ur.contacts.add(cr);
                        }
                    }
                }
                
                apiResp.allocations.add(ur);
                addedUnitIds.add(ur.unitId);
            }
            
            
            // FETCH PUBLIC UNITS
            String publicQuery =
                'SELECT Id, Name, UnitNumber__c, Project__r.Name, Project__c, IsPublic__c, ' +
                'SellingPrice__c, SaleableArea__c, UnitModel__c, UnitType__c, WebFloorPlan__c ' +
                'FROM Unit__c ' +
                'WHERE IsActive__c = true ' +
                'AND Status__c = \'Available\' ' +
                'AND IsPublic__c = true ' +
                'AND Direct_Indirect__c != \'Direct\' ';
            
            
            if (input.projectId != null)
                publicQuery += 'AND Project__c = \'' + String.escapeSingleQuotes(input.projectId) + '\' ';
            
            if (!String.isBlank(input.unitSearchKey)) {
                likeSearchKey = '%' + input.unitSearchKey + '%';
                publicQuery += 'AND Name LIKE :likeSearchKey ';
            }
            
            if (!String.isBlank(input.unitSearchKey)) {
                likeSearchKey = '%' + String.escapeSingleQuotes(input.unitSearchKey) + '%';
                assignedQuery += 'AND BrokerUnitAllocation__r.Unit__r.Name LIKE \'' + likeSearchKey + '\' ';
            }
            
            if (!unitModelList.isEmpty())
                publicQuery += 'AND UnitModel__c IN :unitModelList ';
            if (!unitTypeList.isEmpty())
                publicQuery += 'AND UnitType__c IN :unitTypeList ';
            if (input.minimumBudget != null)
                publicQuery += 'AND SellingPrice__c >= ' + input.minimumBudget + ' ';
            if (input.maximumBudget != null)
                publicQuery += 'AND SellingPrice__c <= ' + input.maximumBudget + ' ';
            if (input.minimumArea != null)
                publicQuery += 'AND SaleableArea__c >= ' + input.minimumArea + ' ';
            if (input.maximumArea != null)
                publicQuery += 'AND SaleableArea__c <= ' + input.maximumArea + ' ';
            
            List<Unit__c> publicUnits = Database.query(publicQuery);
            
            for (Unit__c u : publicUnits) {
                if (!addedUnitIds.contains(u.Id)) {
                    UnitResponse ur = new UnitResponse();
                    ur.projectName = (u.Project__r != null) ? u.Project__r.Name : null;
                    ur.projectId = u.Project__c;
                    ur.unitId = u.Id;
                    ur.unitName = u.Name;
                    ur.unitNumber = u.UnitNumber__c;
                    ur.priceAED = u.SellingPrice__c;
                    ur.areaSqFt = u.SaleableArea__c;
                    ur.unitModel = u.UnitModel__c;
                    ur.unitType = u.UnitType__c;
                    ur.floorPlanDownloadLink = u.WebFloorPlan__c;
                    ur.publicUnit = u.IsPublic__c;
                    apiResp.allocations.add(ur);
                }
            }
            
            if (apiResp.allocations.isEmpty()) {
                apiResp.message = Label.BAPP_No_Units_Found;
            }
            
            sendResponse(apiResp, 200);
            
        } catch (Exception e) {
            sendResponse(
                new Map<String, Object>{'status' => 'error', 'message' => e.getMessage()},
                500
            );
        }
    }
    
    
    // Helper methods
    private static List<String> splitMultiValue(String value) {
        List<String> lst = new List<String>();
        if (!String.isBlank(value)) {
            for (String v : value.split(';')) {
                if (!String.isBlank(v)) lst.add(v.trim());
            }
        }
        return lst;
    }
    
    private static void returnError(String msg) {
        sendResponse(new Map<String, Object>{'status' => 'error', 'message' => msg}, 400);
    }
    
    private static void sendResponse(Object body, Integer code) {
        RestContext.response.addHeader('Content-Type', 'application/json;charset=UTF-8');
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(body));
        RestContext.response.statusCode = code;
    }
    
    // Get ALL assignments (Privileged users) // optmize
    private static List<BrokerUnitAssignment__c> getPrivilegedAssignments(Set<Id> allocationIds){
        if(allocationIds == null || allocationIds.isEmpty()){
            return new List<BrokerUnitAssignment__c>();
        }
        
        return [SELECT Id, BrokerUnitAllocation__c, Contact__c, Contact__r.Name, Contact__r.BrokerContactRole__c FROM BrokerUnitAssignment__c WHERE BrokerUnitAllocation__c IN :allocationIds AND Active__c = true AND UnitStatus__c = 'Available' AND BrokerUnitAllocation__r.EndDate__c >= :System.now()];
    }
    
    // Get ONLY the logged-in contact's assignments (Non-Privileged users) // optmize
    private static List<BrokerUnitAssignment__c> getRestrictedAssignments(Set<Id> allocationIds, Id contactId){
        if(allocationIds == null || allocationIds.isEmpty() || contactId == null){
            return new List<BrokerUnitAssignment__c>();
        }
        
        return [SELECT Id, BrokerUnitAllocation__c, Contact__c, Contact__r.Name, Contact__r.BrokerContactRole__c FROM BrokerUnitAssignment__c WHERE BrokerUnitAllocation__c IN :allocationIds AND Contact__c = :contactId AND Active__c = true AND UnitStatus__c = 'Available' AND BrokerUnitAllocation__r.EndDate__c >= :System.now()];
    }
    
}