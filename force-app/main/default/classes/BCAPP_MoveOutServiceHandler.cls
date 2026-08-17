//============================ BCAPP_MoveOutServiceHandler =============================
/*
* @Author : Eagles
* @CreatedDate : 23rd OCT 2023
* @Name : BCAPP_MoveOutServiceHandler
* @Description : Handles Moveout requests api 
*/
/*****************************************************************************************************
* Version       Author                  Date             Comment                                                                       
* 1.0           Eagles               11NOV2023        Initial draft 
*****************************************************************************************************/

public class BCAPP_MoveOutServiceHandler {   
    
    
    public void MoveOutRequest(String srReq){
        
        CaseService cService = CaseService.getInstance(); 
        BCAPP_WrapperUtility.MoveOutWrapper inputData = (BCAPP_WrapperUtility.MoveOutWrapper) JSON.deserialize(srReq, BCAPP_WrapperUtility.MoveOutWrapper.class);
        BCAPP_Utility utility_ref = BCAPP_Utility.getInstance();
        unitAllocationService uService = new unitAllocationService();
        Map<String,Object>  returnValue = new Map<String,Object>();
        String accountId ;
        Case sr;
        Boolean isChillerEnabled = false;
        String userToken = inputData.accountId;
        List<User__c> customer;
        if(!String.isBlank(userToken)){
            customer = utility_ref.getUserbyAccountId(userToken);
        }
        if(customer==null){
            returnValue.put('errorMessage','Invalid User');
            BCAPP_WebServiceHelper.makeServerErrorResponse(returnValue);
            return;
        }
        accountId = userToken;
        
        if(!String.isBlank(accountId)){
            Case renewalReq = new Case();
            try{
                if(inputData.moveOutDate == null){
                    returnValue.put('errorMessage','move out date shouldn\'t be blank');
                    BCAPP_WebServiceHelper.makeServerErrorResponse(returnValue);
                    return;
                }
                if(inputData.hasAgreedTerms!=null && inputData.hasAgreedTerms && !String.isBlank(inputData.srId)){
                    renewalReq.Status  = 'Submitted'; renewalReq.Id = inputData.srId; renewalReq.Case_Sub_Status__c=null;
                    upsert renewalReq;
                    CaseService service = CaseService.getInstance(); 
                    Case srCase = service.lstgetCaseRelatedtoSR(renewalReq.Id); 
                    //List<BCAPP_WrapperUtility.RequiredDocuments> documents = utility_ref.getRequiredDocuments(srCase.project__c,'Tenant',srCase.Service_Catalog__c);
                    returnValue.put('requestNumber',srCase.Request_Number__c); returnValue.put('srId',srCase.Id );
                    //returnValue.put('documents',documents );    
                    BCAPP_WebServiceHelper.makeSuccessResponse(returnValue);
                    return;            
                }
                renewalReq.Move_Out_Date__c  =  utility_ref.parseDate(inputData.moveOutDate);
                renewalReq.AccountId = accountId;
                renewalReq.Email_Address__c = customer[0].Email__c!=null?customer[0].Email__c:customer[0].User_Account__r.Email__c;
                renewalReq.Representative_Email__c = customer[0].Email__c;
                renewalReq.Unit__c = inputData.unitId;
                List<Unit_Allocation__c> unitAllocation = uService.fetchUnitAllocationDetails(inputData.unitId,accountId);
                if(!unitAllocation.isEmpty()){
                }
                else{
                    returnValue.put('errorMessage','The Unit is not active for this user.' );
                    BCAPP_WebServiceHelper.makeServerErrorResponse(returnValue);
                }
                
                if(customer[0].User_Account__r.Tenant__c){
                    renewalReq.User_Type__c = 'Tenant';
                }
                else if(customer[0].User_Account__r.Owner__c){
                    renewalReq.User_Type__c = 'Owner';
                }
                 
                else{
                    ContactService contactInst=ContactService.getInstance();
                    List<Contact> con =  contactInst.getContactByAccountId(accountId);
                    renewalReq.User_Type__c = 'Holiday Homes'; renewalReq.Representative_Contact_Number__c = con[0].Phone; renewalReq.Representative_Name__c =  con[0].Name;
                }
                renewalReq.Mobile_Number__c = customer[0].User_Account__r.MobilePhone__pc;
                renewalReq.First_Name__c = customer[0].User_Account__r.FirstName;
                renewalReq.Last_Name__c = customer[0].User_Account__r.LastName;
                renewalReq.subject = 'Move Out Request';
                // renewalReq.User_Type__c = BCAPP_Constants.HOLIDAY_HOMES;
                renewalReq.Origin = BCAPP_Constants.COMMUNITY_APP;
                renewalReq.RequestType__c = BCAPP_Constants.MOVE_OUT;
                if(inputData.hasAgreedTerms!=null && inputData.hasAgreedTerms){
                    renewalReq.Status = 'Submitted';
                }
                else{
                    renewalReq.Status = 'Draft';
                }
                renewalReq.recordTypeId = Utilities.getRecordTypeId('Case', 'Move Out');
                if(renewalReq.Unit__c!=null){
                    List<Unit__c> units = UnitService.fetchUnitDetailsById(renewalReq.Unit__c);
                    if(!units.isEmpty()){
                        renewalReq.Project_Name__c = units[0].Project__r.Name;
                        renewalReq.Project__c =  units[0].BuildingSectionName__r.Project__c;
                        isChillerEnabled =  units[0].Is_Chiller_Enabled__c ;
                    }
                }
                List<Service_Catalog__c> sc =  ServiceCatalogService.fetchServiceCatalogByName(BCAPP_Constants.MOVE_OUT);
                if(!sc.isEmpty()){
                    renewalReq.Service_Catalog__c  = sc[0].Id;
                    // String ownerId = utility_ref.changeCaseAssigment(sc[0].Id);
                    // if(!String.isBlank(ownerId)){
                    //     renewalReq.OwnerId = ownerId;
                    // }
                }
                String caseNumber =  utility_ref.checkDuplicateRequest(renewalReq.Email_Address__c,renewalReq.Unit__c,'Move Out',BCAPP_Constants.eligibleStatus);
                if(!String.isEmpty(caseNumber)){
                    returnValue.put('errorMessage','Move Out Request already Exist.'); returnValue.put('Number',caseNumber);
                    BCAPP_WebServiceHelper.makeServerErrorResponse(returnValue);
                    return;
                }
                cService.insertCase(renewalReq);
                sr =  cService.getCaseById(renewalReq.Id);
                List<BCAPP_WrapperUtility.RequiredDocuments> documents = utility_ref.getRequiredDocuments(sr.project__c,renewalReq.User_Type__c,sr.Service_Catalog__c,isChillerEnabled);
                returnValue.put('documents',documents); returnValue.put('requestNumber',sr.Request_Number__c); returnValue.put('srId',sr.Id ); returnValue.put('errorMessage','');
                BCAPP_WebServiceHelper.makeSuccessResponse(returnValue);
            }
            catch(Exception e){
                returnValue.put('errorMessage','Failed to Create Request: ' + e.getLineNumber());
                BCAPP_WebServiceHelper.makeServerErrorResponse(returnValue);
                return;
            } 
        }
        else{
            returnValue.put('errorMessage','Account Id can\'t be blank'); BCAPP_WebServiceHelper.makeServerErrorResponse(returnValue);
            return;
        }
    }
    
    public void renewalRequest(String data){
        
        CaseService cService = CaseService.getInstance(); 
        Map<String, Object>  request = (Map<String, Object>) JSON.deserializeUntyped(data.toString());
        String userToken = (String)request.get('accountId');
        BCAPP_Utility utility_ref = BCAPP_Utility.getInstance();
        List<User__c> customer;
        Map<String,Object>  returnValue = new Map<String,Object>();
        if(!String.isBlank(userToken)){
            customer = utility_ref.getUserbyAccountId(userToken);
        }
        if(customer==null && customer.isEmpty()){
            returnValue.put('errorMessage','Invalid User'); BCAPP_WebServiceHelper.makeServerErrorResponse(returnValue);
            return;
        }
        String accountId = customer[0].Account__c;
        Boolean isChillerEnabled=false;
        Case sr;
        if(!String.isBlank(accountId)){
            Case sRequest = new Case();
            try{
                List<Service_Catalog__c> sc = ServiceCatalogService.fetchServiceCatalogByName(BCAPP_Constants.RENEWAL);
                String userType = ((String)request.get('requestAs')=='Holiday Home')?'Holiday Homes':(String)request.get('requestAs');
                if(request.containsKey('srId') && !String.isBlank((String)request.get('srId'))){
                    sRequest.Id = (String)request.get('srId');
                } 
                if(request.containsKey('hasAgreedTerms') &&(Boolean)request.get('hasAgreedTerms')){
                    sRequest.Status = 'Submitted';
                    upsert sRequest;
                    
                    CaseService service = CaseService.getInstance(); 
                    sr = service.lstgetCaseRelatedtoSR(sRequest.Id); 
                    List<BCAPP_WrapperUtility.RequiredDocuments> documents = new List<BCAPP_WrapperUtility.RequiredDocuments>();
                    if(utility_ref !=null && utility_ref.getRequiredDocuments(sr.project__c,sr.User_Type__c,sr.Service_Catalog__c,isChillerEnabled) !=null){
                        documents = utility_ref.getRequiredDocuments(sr.project__c,sr.User_Type__c,sr.Service_Catalog__c,isChillerEnabled);
                        returnValue.put('documents',documents ); 
                    }
                    returnValue.put('requestNumber',sr.Request_Number__c);
                    returnValue.put('srId',sr.Id );
                    BCAPP_WebServiceHelper.makeSuccessResponse(returnValue);
                    return;       
                }
                
                Map<String,Service_Catalog_Fields__c> fieldMap ;
                fieldMap = utility_ref.getServiceCatalogFieldMapping(sc[0].Id,userType);
                for(String fieldAPIName:fieldMap.keySet()){
                    Service_Catalog_Fields__c fieldDetails = fieldMap.get(fieldAPIName);
                    if(fieldDetails.is_Date__c){
                        if(request.get(fieldDetails.Name) !=null){ 
                            sRequest.put(fieldAPIName, utility_ref.parseDate((String)request.get(fieldDetails.Name)));  
                        }  
                    }
                    else if(request.get(fieldDetails.Name) instanceof  Boolean){
                         sRequest.put(fieldAPIName,(Boolean)request.get(fieldDetails.Name));
                    }
                    else if(fieldDetails.is_Decimal__c ){
                        
                        if(request.get(fieldDetails.Name) instanceof  String){
                            sRequest.put(fieldAPIName,Decimal.valueOf((String)request.get(fieldDetails.Name)));
                        }
                        else{
                            sRequest.put(fieldAPIName,Decimal.valueOf((Integer)request.get(fieldDetails.Name)));
                        }
                        
                    }
                    else if(request.get(fieldDetails.Name) !=null){
                        sRequest.put(fieldAPIName,request.get(fieldDetails.Name));
                    }
                    
                }
                sRequest.User_Type__c = userType;
                sRequest.subject = 'Renewal Request';
                sRequest.recordTypeId = Utilities.getRecordTypeId('Case', BCAPP_Constants.RENEWAL);  
                sRequest.Origin = BCAPP_Constants.COMMUNITY_APP;
                sRequest.Email_Address__c = customer[0].Email__c;
                sRequest.AccountId = (String)request.get('accountId');
                sRequest.RequestType__c = BCAPP_Constants.RENEWAL;
                if(!String.isBlank(accountId)){
                    List<user__c> customUser = utility_ref.getUserbyAccountId(accountId);
                    Account acc = customUser[0].user_account__r;
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
                }
                if(sRequest.Unit__c!=null){
                    List<Unit__c> units = UnitService.fetchUnitDetailsById(sRequest.Unit__c);
                    if(!units.isEmpty()){
                        sRequest.Project__c =  units[0].BuildingSectionName__r.Project__c;
                        sRequest.Project_Name__c = units[0].Project__r.Name;
                        isChillerEnabled = units[0].Is_Chiller_Enabled__c ; 
                    }
                }
                if(!sc.isEmpty()){
                    sRequest.Service_Catalog__c  = sc[0].Id;
                }
                if(sRequest.Email_Address__c!=null){
                    String caseNumber =  utility_ref.checkDuplicateRequest(sRequest.Email_Address__c,sRequest.Unit__c,BCAPP_Constants.RENEWAL,BCAPP_Constants.eligibleStatus);
                    if(!String.isEmpty(caseNumber)){
                        returnValue.put('errorMessage','Renewal Request already Exist.'); returnValue.put('Number',caseNumber);
                        BCAPP_WebServiceHelper.makeServerErrorResponse(returnValue);
                        return;
                    }
                    
                }
                cService.insertCase(sRequest);
                sr = cService.getCaseById(sRequest.Id);
                returnValue.put('requestNumber',sr.Request_Number__c);
                List<BCAPP_WrapperUtility.RequiredDocuments> documents = utility_ref.getRequiredDocuments(sr.project__c,BCAPP_Constants.TENANT,sr.Service_Catalog__c,false);
                returnValue.put('documents',documents);
                returnValue.put('srId',sr.Id );
                BCAPP_WebServiceHelper.makeSuccessResponse(returnValue);
                
            }
            catch(Exception e){ returnValue.put('errorMessage','Failed to Create Request: ' + e.getLineNumber()+'--'+e.getMessage()); BCAPP_WebServiceHelper.makeServerErrorResponse(returnValue);
            }
        }
        else{
            returnValue.put('errorMessage','Account Id can\'t be blank'); BCAPP_WebServiceHelper.makeServerErrorResponse(returnValue);
        }
    }
}