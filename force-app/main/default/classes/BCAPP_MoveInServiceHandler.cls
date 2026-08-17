//============================ BCAPP_Utility =============================
/*
* @Author : Eagles  
* @CreatedDate : 04 Sept 2024
* @Name : BCAPP_MoveInServiceHandler
* @Description : This APEX class used to handle the Move In Serivice 
*/
/*****************************************************************************************************
* Version       Author                  Date             Comment                                                                       
* 1.0           Eagles               28 OCT 2024        Initial draft 
*****************************************************************************************************/


public class BCAPP_MoveInServiceHandler {   
    
   public  void createMoveInRequest(String srReq){
        Map<String, Object> wrapper;
        Map<String, Object> request;
        Case sRequest = new Case();
        BCAPP_Utility utility_ref = BCAPP_Utility.getInstance();
        Boolean isChillerEnabled=false;
        Map<String,Object> returnValue = new Map<String,Object>(); 
        try {
            wrapper = (Map<String, Object>) JSON.deserializeUntyped(srReq.toString());
            request = (Map<String, Object>) wrapper.get('request');
        } catch (Exception e) {
            returnValue.put('errorMessage','Invalid JSON format.'+e.getMessage()+'-'+e.getLineNumber());
            returnValue.put('success','false');
            BCAPP_WebServiceHelper.makeServerErrorResponse(returnValue);
            return;
        }
        // Convert date fields from String to Date
        try {
            List<Service_Catalog__c> sc = ServiceCatalogService.fetchServiceCatalogByName(BCAPP_Constants.MOVE_IN);
            Map<String,Service_Catalog_Fields__c> fieldMap ;
            if(request.containsKey('srId') && !String.isBlank((String)request.get('srId'))){
                    sRequest.Id = (String)request.get('srId');
                }
                if(request.containsKey('hasAgreedTerms') &&(Boolean)request.get('hasAgreedTerms')){
                    sRequest.Status = 'Submitted'; upsert sRequest;
                      
                   // CaseService service = new CaseService();
                   CaseService service = CaseService.getInstance();
                    Case sr = service.lstgetCaseRelatedtoSR(sRequest.Id); 
                    List<BCAPP_WrapperUtility.RequiredDocuments> documents = new List<BCAPP_WrapperUtility.RequiredDocuments>();
                    system.debug('@@##$$$'+sr.project__c+'**&&&'+sr.User_Type__c+'((***'+sr.Service_Catalog__c+'&&&^^^'+isChillerEnabled);
                    if(utility_ref !=null && utility_ref.getRequiredDocuments(sr.project__c,sr.User_Type__c,sr.Service_Catalog__c,isChillerEnabled) !=null){
                        documents = utility_ref.getRequiredDocuments(sr.project__c,sr.User_Type__c,sr.Service_Catalog__c,isChillerEnabled);
                         returnValue.put('documents',documents ); 
                    }
                    returnValue.put('requestNumber',sr.Request_Number__c); returnValue.put('srId',sr.Id );
                    
                    BCAPP_WebServiceHelper.makeSuccessResponse(returnValue);
                    return;            
                }
                else{
                    sRequest.Status = 'Draft';
            }
            if(!String.isEmpty((String)request.get('requestAs'))){
                String userType = ((String)request.get('requestAs')=='Holiday Home')?'Holiday Homes':(String)request.get('requestAs');
                fieldMap = utility_ref.getServiceCatalogFieldMapping(sc[0].Id,userType);
                for(String fieldAPIName:fieldMap.keySet()){
                    Service_Catalog_Fields__c fieldDetails = fieldMap.get(fieldAPIName);
                    if(fieldDetails.is_Date__c){
                        if(request.get(fieldDetails.Name) !=null){ 
                            sRequest.put(fieldAPIName, utility_ref.parseDate((String)request.get(fieldDetails.Name)));  
                        }  
                    }
                    else if(fieldDetails.is_Decimal__c && (request.get(fieldDetails.Name) instanceof String)){
                        sRequest.put(fieldAPIName,Decimal.valueOf((String)request.get(fieldDetails.Name)));
                    }
                    else{
                        sRequest.put(fieldAPIName,request.get(fieldDetails.Name));
                    }
                }
                
                 sRequest.User_Type__c = userType;
                 sRequest.Subject = 'Move In Request';
                if(sRequest.User_Type__c == 'Holiday Homes'){
                    sRequest.Email_Address__c = sRequest.Representative_Email__c;
                }
                if(sRequest.Unit__c!=null){
                    List<Unit__c> units = UnitService.fetchUnitDetailsById(sRequest.Unit__c); 
                    if(!units.isEmpty()){
                        sRequest.Project__c =  units[0].Project__c;
                        sRequest.Project_Name__c = units[0].Project__r.Name;
                        isChillerEnabled = units[0].Is_Chiller_Enabled__c ;
                    }
                }
                sRequest.Service_Catalog__c  = sc[0].Id;
                system.debug('registrtionid--'+(String)request.get('registrationId'));
                sRequest.deviceRegistrationId__c  = (String)request.get('registrationId');
                sRequest.Origin = BCAPP_Constants.COMMUNITY_APP;
                sRequest.RecordTypeId  = Utilities.getRecordTypeId('Case', BCAPP_Constants.MoveInRecrdTypes.get((String)request.get('requestAs')));
                sRequest.RequestType__c  = BCAPP_Constants.MOVE_IN;
                sRequest.SuppliedCompany = (String)request.get('companyName');

                if(sRequest.User_Type__c == BCAPP_Constants.OWNER){
                    List<user__c> customUser;
                    String accountId = (String)request.get('accountId');
                    if(!String.isBlank(accountId)){
                        customUser = utility_ref.getUserbyAccountId(accountId);
                        Account acc = customUser[0].user_account__r;
                         sRequest.Status = 'Submitted';
                        sRequest.Email_Address__c  = customUser[0].Email__c;
                        sRequest.First_Name__c  = acc.FirstName;
                        sRequest.Last_Name__c = acc.LastName;
                        sRequest.PhoneNumber__c = acc.MobilePhone__pc;
                        sRequest.Nationality__c = acc.Nationality__c;
                        sRequest.Emergency_contact_01__c = acc.Emergency_contact_01__c;
                        sRequest.Emergency_contact_02__c = acc.Emergency_contact_02__c;
                        if(acc.Emirates_ID_expiry_date__c!=null && acc.Emirates_ID_expiry_date__c > System.now()){
                            sRequest.Emirates_ID_expiry_date__c = customUser[0].User_Account__r.Emirates_ID_expiry_date__c;
                        }
                        sRequest.Emirates_ID_number__c = customUser[0].User_Account__r.Emirates_ID_number__c;
                        String ownerId = utility_ref.changeCaseAssigment(sc[0].Id);
                        // if(!String.isBlank(ownerId)){
                        //     sRequest.OwnerId = ownerId;
                        // }
                    }
                    /*if(customUser==null || customUser.isEmpty()){
                        returnValue.put('errorMessage','Invalid User');
                        BCAPP_WebServiceHelper.makeServerErrorResponse(returnValue);
                        return  ;
                    }*/
                }
            }
            upsert sRequest;
            //CaseService cService = new CaseService();
            CaseService cService = CaseService.getInstance();
            Case sr = cService.getCaseById(sRequest.Id);
            List<BCAPP_WrapperUtility.RequiredDocuments> documents = utility_ref.getRequiredDocuments(sr.project__c,sRequest.User_Type__c,sr.Service_Catalog__c,isChillerEnabled);
            returnValue.put('requestNumber',sr.Request_Number__c);
            returnValue.put('srId',sr.Id );
            if(documents!=null){
                returnValue.put('documents',documents );
            }
            BCAPP_WebServiceHelper.makeSuccessResponse(returnValue);
        }
        catch (Exception e) { returnValue.put('errorMessage','Something went wrong-'+e.getmessage()+'--'+e.getLineNumber()); BCAPP_WebServiceHelper.makeServerErrorResponse(returnValue); return;
        }
    }
    
    
}