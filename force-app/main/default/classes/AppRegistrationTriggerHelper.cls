/*
* @Author : Biswajeet Samal
* @CreatedDate : 7th AUG 2024
* @Description : AppRegistrationTriggerHelper
*/
/*****************************************************************************************************
* Version       Author      Date             Comment                                                                       
* 1.0           Biswajeet   07AUG2024        Initial draft 
*****************************************************************************************************/
public class AppRegistrationTriggerHelper {

    public static void createDocuments(List<AppRegistration__c> newList){
        DocumentService objDocumentService = DocumentService.getInstance();
        List<DocumentType__c> accountDocTypeList = objDocumentService.getDocTypes('App Registration');
        List<Document__c> documentList = new List<Document__c>();
        for(AppRegistration__c objAppRegistration :newList){
            for(DocumentType__c objDocumentType :accountDocTypeList){
                documentList.add(new Document__c(AppRegistration__c = objAppRegistration.Id, DocumentType__c = objDocumentType.Id, Document_Name__c = objDocumentType.Type__c));
            }
        }
        objDocumentService.insertDocuments(documentList);   
    }
    
    public static void beforeInsert(List<AppRegistration__c> newList){
        ContactService objContactService = ContactService.getInstance();
        Set<Id> contactIds = new Set<Id>();
        Map<Id, Contact> conMap = new Map<Id, Contact>();
        
        for(AppRegistration__c objAppRegistration :newList){
            if(objAppRegistration.Contact__c != NULL){
                contactIds.add(objAppRegistration.Contact__c);
            }
        }
        
        if(!contactIds.isEmpty()){
            conMap = new Map<Id, Contact>(objContactService.getContactsByIds(contactIds));
        }
        
        if(!conMap.isEmpty()){
            for(AppRegistration__c objAppRegistration :newList){
                if(objAppRegistration.Contact__c != NULL && conMap != NULL){
                    
                    Contact objCon = conMap.get(objAppRegistration.Contact__c);
                    if(objCon == null){
                        continue;
                    }
                    String mobilePhone = objAppRegistration.MobileCountryCode__c + objAppRegistration.MobilePhone__c;
                    objAppRegistration.Account__c = objCon.AccountId;
                    
                    Boolean isEmailMatched = false;
                    Boolean isPhoneMatched = false;
                    if(objCon.Email == objAppRegistration.Email__c || objCon.SecondaryEmail__c == objAppRegistration.Email__c || objCon.TertiaryEmail__c == objAppRegistration.Email__c){
                        isEmailMatched = true;
                    }

                    String cleanMobilePhone = cleanPhoneNumber(objCon.MobilePhone);
                    String cleanHomePhone   = cleanPhoneNumber(objCon.HomePhone);
                    String cleanOtherPhone  = cleanPhoneNumber(objCon.OtherPhone);

                    if(cleanMobilePhone == mobilePhone || cleanHomePhone == mobilePhone || cleanOtherPhone == mobilePhone){
                        isPhoneMatched = true;
                    }
                    
                    if(isEmailMatched && isPhoneMatched){
                        objAppRegistration.Status__c = 'Approved';
                        objAppRegistration.ApprovedDate__c = Date.today();
                    }
                }
            }
        }
    }

    private static String cleanPhoneNumber(String phoneNumber){

        if(phoneNumber == null){
            return '';
        }
        phoneNumber = phoneNumber.replaceAll('[^0-9]', '');
        return phoneNumber;
    }

    public static void beforeUpdate(List<AppRegistration__c> newList, Map<Id, AppRegistration__c> oldMap){
        for(AppRegistration__c objAppRegistration : newList){
            if(objAppRegistration.Status__c == 'Approved' && oldMap.get(objAppRegistration.Id).Status__c != 'Approved'){
                objAppRegistration.ApprovedDate__c = Date.today();
            }
        }
    }
    
    public static void afterInsert(List<AppRegistration__c> newList){
        List<User__c> userList = new List<User__c>();
        CustomUserService objCustomUserService = CustomUserService.getInstance();
        AppRegistrationService objAppRegistrationService = AppRegistrationService.getInstance();

        for(AppRegistration__c objAppRegistration :newList){
            if(objAppRegistration.Status__c == 'Approved' && objAppRegistration.Contact__c != NULL){
                User__c objUser = objCustomUserService.getAppRegistrationUser(objAppRegistration);
                userList.add(objUser);
            }
            if(objAppRegistration.Status__c == 'Under Review'){
                ServiceCatalogService servObj = ServiceCatalogService.getInstance();
                KYCUpdateRequestSRHandler objKYCUpdateRequestSRHandler = KYCUpdateRequestSRHandler.getInstance();
                List<ServiceCatalog__c> scs = servObj.getServiceCatalogForBloomApp('Service Request', 'Customer Service Request', 'KYC Update Request');
                Case newCase = objKYCUpdateRequestSRHandler.createCaseRecordFromAppRegistrationTrigger(objAppRegistration, scs[0], objAppRegistration.Account__c, 'Service Request','', 'Super App');
            }
        }
        objCustomUserService.insertUsers(userList);
        objAppRegistrationService.sendBloomAppEmail(newList);
    }
    
    public static void afterUpdate(List<AppRegistration__c> newList, Map<Id, AppRegistration__c> oldMap){
        List<User__c> userList = new List<User__c>();
        CustomUserService objCustomUserService = CustomUserService.getInstance();
        AppRegistrationService objAppRegistrationService = AppRegistrationService.getInstance();
        List<AppRegistration__c> rejectedAppRegistraionList = new List<AppRegistration__c>();
        for(AppRegistration__c objAppRegistration :newList){
            if(objAppRegistration.Status__c == 'Approved' && objAppRegistration.Contact__c != NULL && oldMap.get(objAppRegistration.Id).Status__c != objAppRegistration.Status__c){
                User__c objUser = objCustomUserService.getAppRegistrationUser(objAppRegistration);
                userList.add(objUser);
            }
            else if(objAppRegistration.Status__c == 'Rejected' && oldMap.get(objAppRegistration.Id).Status__c != 'Rejected'){
                rejectedAppRegistraionList.add(objAppRegistration);
            }
        }
        
        objCustomUserService.insertUsers(userList);
        objAppRegistrationService.sendBloomAppEmail(rejectedAppRegistraionList);
    }
}