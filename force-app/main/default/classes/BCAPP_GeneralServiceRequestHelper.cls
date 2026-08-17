//============================ BCAPP_GeneralServiceRequestHelper =============================
/*
* @Author : Eagles  
* @CreatedDate : 25 Jun 2025
* @Name : BCAPP_GeneralServiceRequestHelper
* @Description : This APEX class handles the Guest Management API Module
*/
/*****************************************************************************************************
* Version       Author                  Date             Comment                                                                       
* 1.0           Eagles               02 Jul 2025     Initial draft 
*****************************************************************************************************/

public without sharing class BCAPP_GeneralServiceRequestHelper {
    
    
    public static void manageGuestRequest(String requestBody){
        
        Map<String, Object> returnValue = new Map<String, Object>();
        Map<String, Object> response = new Map<String, Object>();
        Map<String,Object> request =(Map<String, Object>) JSON.deserializeUntyped(requestBody.toString());
        List<BCAPP_WrapperUtility.Document> wrapper = new List<BCAPP_WrapperUtility.Document>();
        BCAPP_Utility utility_ref = BCAPP_Utility.getInstance();
        ServiceCatalogService sc_ref = new ServiceCatalogService();
        String userToken = (String)request.get('accountId');
        Set<String> fileTypes = new Set<String>{'.pdf','.png','.jpeg'};
        List<User__c> customer;
        String filter;
        CaseService cService = CaseService.getInstance();
        ServiceCatalogService scService = ServiceCatalogService.getInstance();
        try {
            String unitId = (String)request.get('unitId');
             String srId = (String)request.get('srId');
            Date targetDate = ((String)request.get('type') == 'extension') 
                                ? utility_ref.parseDate((String)request.get('toDate')) 
                                : utility_ref.parseDate((String)request.get('fromDate'));

            List<Service_Catalog__c> sc = ServiceCatalogService.fetchServiceCatalogByName(BCAPP_Constants.GUEST_MGMT);
            String scId = sc[0].Id;
            if(srId!=null){
                Case guestReq = cService.getCaseById(srId);
                unitId = guestReq.Unit__c;
            }
            Unit__c unit = UnitService.fetchUnitDetailsById(unitId)[0];
            if (unit == null || unit.Legal_Status__c == 'With Legal') {
                response.put('errorMessage', 'This unit is legally blocked. Please contact BCM.');
                BCAPP_WebServiceHelper.makeServerErrorResponse(response);
                return;
            }
            
            String query = 'SELECT Move_Out_Date__c, Permit_From_Date__c, Permit_To_Date__c ' +
               'FROM Case ' ;
            if(unitId!=null){
                query+='WHERE Unit__c=:unitId ';
            }
            
            query+='AND Service_Catalog__c=:scId ' +'AND Status IN (\'Submitted\', \'Approved\')';
            List<Case> existingCases = Database.query(query);
            for (Case c : existingCases) {
                if (c.Move_Out_Date__c != null) {
                    // Exclude if targetDate is between Permit_To_Date__c and Move_Out_Date__c
                    if (targetDate >= c.Permit_To_Date__c && targetDate <= c.Move_Out_Date__c) {
                         returnValue.put('errorMessage','Guest Request Already Exist in the same duration.');
                         BCAPP_WebServiceHelper.makeServerErrorResponse(returnValue);
                        return;
                    }
                } else {
                    // Exclude if targetDate is between Permit_From_Date__c and Permit_To_Date__c
                    if (targetDate >= c.Permit_From_Date__c && targetDate <= c.Permit_To_Date__c) {
                         returnValue.put('errorMessage', 'Guest Request Already Exist in the same duration.');
                         BCAPP_WebServiceHelper.makeServerErrorResponse(returnValue);
                        return;
                    }
                }
            }
            if (userToken != null) {
                if (!String.isBlank(userToken)) {
                    customer = utility_ref.getUserbyAccountId(userToken);
                }
            }
            if (customer == null || customer.isEmpty()) {
                response.put('errorMessage', 'Invalid User');
                BCAPP_WebServiceHelper.makeServerErrorResponse(response);
                return;
            }
            Case guestRequest = new Case();
            if(request.containsKey('accountId') && (String)request.get('srId')!=null){
                guestRequest.Id =  (String)request.get('srId');
                if(request.get('toDate')!=null && request.get('type')=='extension'){
                    guestRequest.Permit_To_Date__c =   utility_ref.parseDate((String)request.get('toDate'));
                    Case existingGuestReq = cService.getCaseById(guestRequest.Id);
                    if(existingGuestReq.Case_Sub_Status__c == '1st Extension'){
                        guestRequest.Case_Sub_Status__c = '2nd Extension';
                    }
                    else if(existingGuestReq.Case_Sub_Status__c == '2nd Extension'){
                        returnValue.put('errorMessage', 'You can\'t extend more than 2 times');
                        BCAPP_WebServiceHelper.makeServerErrorResponse(returnValue);
                        return;
                    }
                    else{
                        guestRequest.Case_Sub_Status__c = '1st Extension';
                    }
                    guestRequest.previousToDate__c = existingGuestReq.Permit_To_Date__c;
                    guestRequest = cService.updateCase(guestRequest);
                    response.put('srId', guestRequest.Id);
                   // BCAPP_SendNotificationAction notifyHandler = new BCAPP_SendNotificationAction(new List<Case>{guestRequest},'Extension');
                   // notifyHandler.handleSendEmailActionItems();
                    response.put('message', 'Extension Updated successfully');
                    BCAPP_WebServiceHelper.makeSuccessResponse(response);
                    return;
                }
                else if(request.get('type')=='checkout'){
                    guestRequest.Status = 'Completed';
                    guestRequest.Move_Out_Date__c  =System.today();
                    guestRequest = cService.updateCase(guestRequest);
                    response.put('message', 'CheckOut Completed');
                    BCAPP_WebServiceHelper.makeSuccessResponse(response);
                    return;
                }
            }
            else{
                List<Unit__c> units = UnitService.fetchUnitDetailsById(unitId); 
                if(units.isEmpty() && units[0].Legal_Status__c == BCAPP_Constants.WITH_LEGAL){
                    response.put('errorMessage', 'Not a Valid Unit');
                    BCAPP_WebServiceHelper.makeServerErrorResponse(response);
                    return;
                }
                Map<String,Service_Catalog_Fields__c> fieldMap = utility_ref.getServiceCatalogFieldMapping(sc[0].Id,'Holiday Homes');
                for(String fieldAPIName:fieldMap.keySet()){
                    Service_Catalog_Fields__c fieldDetails = fieldMap.get(fieldAPIName);
                    if(fieldAPIName!='GuestDetails__c'){
                        if(fieldDetails.is_Date__c){
                            if(request.get(fieldDetails.Name) !=null){ 
                                guestRequest.put(fieldAPIName, utility_ref.parseDate((String)request.get(fieldDetails.Name)));  
                            }  
                        }
                        else if(fieldDetails.is_Decimal__c && (request.get(fieldDetails.Name) instanceof String)){
                            guestRequest.put(fieldAPIName,Decimal.valueOf((String)request.get(fieldDetails.Name)));
                        }
                        else{
                            guestRequest.put(fieldAPIName,request.get(fieldDetails.Name));
                        }
                    }
                }
                guestRequest.AccountId = userToken;
                guestRequest.Origin  = 'Community App';
                guestRequest.project__c = units[0].project__c;
                guestRequest.Service_Catalog__c = sc[0].Id;
                guestRequest.Status = 'Submitted';
                guestRequest.Type = 'Guest Management';
                guestRequest.Subject = 'Guest Management';
                guestRequest.User_Type__c = customer[0].user_type__c;
                String guestDetails = '';
                Integer index = 1;
                Integer guestCounter = 0 ;
                List<Object> guestObjects = (List<Object>) request.get('guests');
                List<GuestInfo> guestList = new List<GuestInfo>();
                Map<String,Integer> guestdocNames = new Map<String,Integer>();
                for (Object o : guestObjects) {
                    Map<String, Object> guestMap = (Map<String, Object>) o;
                    String guestJson = JSON.serialize(guestMap);
                    GuestInfo guest = (GuestInfo) JSON.deserialize(guestJson, GuestInfo.class);
                    guestList.add(guest);
                }
                for (GuestInfo guest : guestList) {
                   
                    BCAPP_WrapperUtility.Document doc = new BCAPP_WrapperUtility.Document();
                    String fileName = ((String) guest.name);
                    String docName ;
                    
                    Integer lastIndex = fileName.lastIndexOf('.');
                    if(lastIndex != -1) {
                       
                        docName = fileName.substring(0, lastIndex);
                        if(guestdocNames.containsKey(docName)){
                            docName = docName+'-'+2;
                           
                        }
                        else{
                           guestCounter +=1;  
                           guestdocNames.put(docName,1);
                           guestDetails += guestCounter + '. ' + docName + '\n';
                           docName =docName+'-'+1;
                          
                        }
                        
                        doc.contentType = fileName.substring(lastIndex);
                        if(!fileTypes.contains(doc.contentType)){
                            returnValue.put('errorMessage', 'Invalid file type, allows only pdf,jpg,png.');
                            BCAPP_WebServiceHelper.makeServerErrorResponse(returnValue);
                            return;
                        }
                    }
                    else{
                        docName = fileName;
                    }
                    doc.fileName = docName;
                    doc.fileContent = EncodingUtil.base64Decode(
                        guest.document
                    );
                    
                    wrapper.add(doc);
                    index++;
                }
                
                guestRequest.GuestDetails__c  = guestDetails;
                guestRequest.user__c = customer[0].Id;
                guestRequest.RecordTypeId = Utilities.getRecordTypeId('Case','Community General Service Request'); 
                cService.insertCase(guestRequest);
                
                Customer_Document__c cds = new Customer_Document__c();
                cds.Name = 'Guest Documents';
                cds.Case__c = guestRequest.Id;
                insert cds;
                
                Boolean isFileUpload = utility_ref.uploadFilesToCase(
                    cds.Id,
                    wrapper
                );
                
                Case sr = cService.getCaseById(guestRequest.Id);
                response.put('srId', guestRequest.Id);
                response.put('requestNumber', sr.caseNumber);
                response.put('message', 'Guest Request Submitted successfully');
                BCAPP_WebServiceHelper.makeSuccessResponse(response);
            }
            
        } catch (Exception e) {
            returnValue.put('errorMessage', e.getMessage()+'--'+e.getLineNumber());
            BCAPP_WebServiceHelper.makeServerErrorResponse(returnValue);
        }
        
    }
    
    public static void getAllGuestRequest(String request){
        
        Map<String, Object> returnValue = new Map<String, Object>();
        List<Map<String, Object>> response = new List<Map<String, Object>>();
        BCAPP_Utility util_ref = BCAPP_Utility.getInstance();
        try {
            Map<String,Object> input =(Map<String, Object>) JSON.deserializeUntyped(request.toString());
            CaseService cService = CaseService.getInstance();
            String accountId = (String)input.get('accountId');
            List<Case> lstCases = cService.getrelatedCaseToAccount(accountId);
            for (Case guestReq : lstCases) {
                if(guestReq.Service_Catalog__r.Name == BCAPP_Constants.GUEST_MGMT){
                    Map<String, Object> data = new Map<String, Object>();
                    data.put('Id', guestReq.Id);
                    data.put('requestNumber', guestReq.Request_Number__c);
                    data.put('status', guestReq.Status);
                    data.put('fromDate',guestReq.Permit_From_Date__c);
                    data.put('toDate', guestReq.Permit_To_Date__c);
                    response.add(data);
                }
            }
            returnValue.put('result',response);
            BCAPP_WebServiceHelper.makeSuccessResponse(response);
        } catch (Exception e) {
            returnValue.put('errorMessage', e.getMessage());
            BCAPP_WebServiceHelper.makeServerErrorResponse(returnValue);
        }
    }
    
    public class GuestInfo {
        public String name;
        public String document; // Base64 encoded
    }
    
}