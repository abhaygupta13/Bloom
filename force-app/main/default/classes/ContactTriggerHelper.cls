/*
* @Author : Biswajeet Samal
* @CreatedDate : 7th AUG 2024
* @Description : ContactTriggerHelper
*/
/*****************************************************************************************************
* Version       Author      Date             Comment                                                                       
* 1.0           Biswajeet   07AUG2024        Initial draft 
* 2.0           Raza         				 Initial draft 
*****************************************************************************************************/
public class ContactTriggerHelper {

    private static final string CONTACT_RT_DEV_NAME_BROKER { get { return 'Broker'; } }
    
    // to create the Document PlaceHolder for Contacts - Updated by Akshay (Role-based logic)
    public static void createDocuments(List<Contact> newList) {
        if (newList.isEmpty()) return;
        
        DocumentService objDocumentService = DocumentService.getInstance();
        
        Id brokerContactRecordTypeId = Utility.getRecordTypeIdByDevName(Contact.SObjectType, CONTACT_RT_DEV_NAME_BROKER);
        
        // Fetch DocumentTypes for Contacts
        List<DocumentType__c> contactDocTypeList = objDocumentService.getDocTypes('Contact');
        
        // Filter to only Broker RecordType
        
        // Collect all Contact Ids
        Set<Id> contactIds = new Set<Id>();
        for (Contact con : newList) {
            if (con.RecordTypeId == brokerContactRecordTypeId) {
                contactIds.add(con.Id);
            }
        }
        
        if (contactIds.isEmpty()) return;
        
        // Query existing documents for these contacts
        Map<String, Document__c> existingDocsMap = new Map<String, Document__c>();
        for (Document__c doc : DocumentService.getInstance().getDocumentByContactIds(contactIds)) {
            String key = doc.Contact__c + '-' + doc.DocumentType__c;
            existingDocsMap.put(key, doc);
        }
        
        
        List<Document__c> documentList = new List<Document__c>();
        
        for (Contact con : newList) {
            if (con.RecordTypeId == brokerContactRecordTypeId){              
                
                if (String.isNotBlank(con.BrokerContactRole__c)) {
                    Set<String> contactRoles = new Set<String>();
                    for (String role : con.BrokerContactRole__c.split(';')) {
                        contactRoles.add(role.trim());
                    }
                    
                    for (DocumentType__c dt : contactDocTypeList) {
                        if (String.isBlank(dt.BrokerContactRole__c)) {
                            continue; // skip doc types that don't define a role
                        }
                        
                        Set<String> docRoles = new Set<String>();
                        for (String role : dt.BrokerContactRole__c.split(';')) {
                            docRoles.add(role.trim());
                        }
                        
                        Set<String> intersection = new Set<String>(contactRoles);
                        intersection.retainAll(docRoles);
                        
                        if (!intersection.isEmpty() &&
                            String.valueOf(dt.TypeOfEstablishment__c) == String.valueOf(con.TypeOfEstablishment__c)) {
                                
                                String key = con.Id + '-' + dt.Id;
                                
                                if (!existingDocsMap.containsKey(key)) { // <-- prevent duplicates
                                    documentList.add(new Document__c(
                                        Contact__c = con.Id,
                                        DocumentType__c = dt.Id,
                                        Document_Name__c = dt.Type__c
                                    ));
                                }
                            }
                    }
                }
            }
        }
        objDocumentService.insertDocuments(documentList);
    }
    
    public static void handleBeforeInsertFieldUpdates(List<Contact> newList) {
        for(Contact objContact :newList){
            objContact.Emirates_Id__c = Utility.formatEmiratesId(objContact.Emirates_Id__c);
            if(objContact.PrimaryMobileCountryCode__c != NULL && objContact.PrimaryMobilePhone__c != NULL ){
                objContact.MobilePhone = Utility.formatPhoneNumber(objContact.PrimaryMobileCountryCode__c, objContact.PrimaryMobilePhone__c);
            }
            if(objContact.SecondaryMobileCountryCode__c != NULL && objContact.SecondaryMobilePhone__c != NULL ){
                objContact.HomePhone = Utility.formatPhoneNumber(objContact.SecondaryMobileCountryCode__c, objContact.SecondaryMobilePhone__c);
            }
            if(objContact.TertiaryMobileCountryCode__c != NULL && objContact.TertiaryMobilePhone__c != NULL ){
                objContact.OtherPhone = Utility.formatPhoneNumber(objContact.TertiaryMobileCountryCode__c, objContact.TertiaryMobilePhone__c);
            }
        }
    }
    
    public static void handleBeforeUpdateFieldUpdates(List<Contact> newList, Map<Id, Contact> oldMap) {
        for(Contact objContact :newList){
            if(objContact.Emirates_Id__c != oldMap.get(objContact.Id).Emirates_Id__c){
                objContact.Emirates_Id__c = Utility.formatEmiratesId(objContact.Emirates_Id__c);
            }
            if((objContact.PrimaryMobileCountryCode__c != oldMap.get(objContact.Id).PrimaryMobileCountryCode__c)
               || (objContact.PrimaryMobilePhone__c != oldMap.get(objContact.Id).PrimaryMobilePhone__c)){
                   objContact.MobilePhone = Utility.formatPhoneNumber(objContact.PrimaryMobileCountryCode__c, objContact.PrimaryMobilePhone__c);
               }
            
            if((objContact.SecondaryMobileCountryCode__c != oldMap.get(objContact.Id).SecondaryMobileCountryCode__c)
               || (objContact.SecondaryMobilePhone__c != oldMap.get(objContact.Id).SecondaryMobilePhone__c)){
                   objContact.HomePhone = Utility.formatPhoneNumber(objContact.SecondaryMobileCountryCode__c, objContact.SecondaryMobilePhone__c);
               }
            
            if((objContact.TertiaryMobileCountryCode__c != oldMap.get(objContact.Id).TertiaryMobileCountryCode__c)
               || (objContact.TertiaryMobilePhone__c != oldMap.get(objContact.Id).TertiaryMobilePhone__c)){
                   objContact.OtherPhone = Utility.formatPhoneNumber(objContact.TertiaryMobileCountryCode__c, objContact.TertiaryMobilePhone__c);
               }
        }
    }
    
   // BAPP : This method is added to update the Azure User on update of contact Record
    public static void handleContactUpdates(List<Contact> newList, Map<Id, Contact> oldMap) {
        List<User__c> usersToUpdate = new List<User__c>();
        for (Contact newCon : newList) {
            Contact oldCon = oldMap.get(newCon.Id);
            if (newCon.User__c != NULL && (newCon.FirstName != oldCon.FirstName ||
                                           newCon.MiddleName != oldCon.MiddleName ||
                                           newCon.LastName != oldCon.LastName ||
                                           newCon.MobilePhone != oldCon.MobilePhone ||
                                           newCon.Email != oldCon.Email ||
                                           newCon.Blacklisted__c != oldCon.Blacklisted__c ||
                                           newCon.IsSuspended__c != oldCon.IsSuspended__c ||
                                           newCon.IsActive__c != oldCon.IsActive__c)
               ) {
                   
                   User__c objUser = new User__c(Id = newCon.User__c, IsSendToAB2C__c = true, Mobile_Number__c = newCon.MobilePhone, Username__c = newCon.Email, Email__c = newCon.Email);
                   List<String> nameParts = new List<String>();
                   if (String.isNotBlank(newCon.FirstName)) nameParts.add(newCon.FirstName);
                   if (String.isNotBlank(newCon.MiddleName)) nameParts.add(newCon.MiddleName);
                   if (String.isNotBlank(newCon.LastName)) nameParts.add(newCon.LastName);
                   objUser.Name = String.join(nameParts, ' ');
                   if (newCon.Blacklisted__c == true || newCon.IsActive__c == false || newCon.IsSuspended__c == true) {
                       objUser.IsActive__c = false;
                   }else{
                       objUser.IsActive__c = true;
                   }
                   usersToUpdate.add(objUser);
               }
        }
        CustomUserService.getInstance().updateUsers(usersToUpdate);
    }
    
    // BAPP When a contact linked with a account Gets inserted the Azure User Record will be Created
    Public static void createAzureUser(List<Contact> newContacts){
        List<User__c> userToInsert = New List<User__c>();
        If(!newContacts.isEmpty()){
            for (Contact con : newContacts){
                // if(con.SendToBL__c == true || con.FinalApprovalStage__c == 'First Approval' && con.SendToBL__c == false){
                if(con.AccountId != null || con.CaseId__c != null){
                    String fullName = '';
                    if (String.isNotBlank(con.FirstName)) {
                        fullName += con.FirstName;
                    }
                    if (String.isNotBlank(con.MiddleName)) {
                        if (!String.isBlank(fullName)) {
                            fullName += ' ';
                        }
                        fullName += con.MiddleName;
                    }
                    if (String.isNotBlank(con.LastName)) {
                        if (!String.isBlank(fullName)) {
                            fullName += ' ';
                        }
                        fullName += con.LastName;
                    }
                    User__c azureUser = New User__c();
                    azureUser.Name = fullName;
                    azureUser.Contact__c = con.Id;
                    azureUser.User_Account__c = con.AccountId;
                    azureUser.CurrencyIsoCode = con.CurrencyIsoCode;
                    azureUser.Email__c = con.Email;
                    azureUser.Is_Azure_Active__c = true;
                    azureUser.isActive__c = true;
                    azureUser.Mobile_Number__c = con.MobilePhone;
                    azureUser.Username__c = con.Email;
                    azureUser.User_Type__c = 'Broker Agent';
                    azureUser.Name__c = fullName;
                    
                    userToInsert.add(azureUser);
                }  
                
            }
            
            // Insert the list if not empty
            if (!userToInsert.isEmpty()) {
                CustomUserService usrService = CustomUserService.getInstance();
                usrService.insertUsers(userToInsert);
            }
            
        }
    }
    
        
        public static void updateCaseWithContactLookup(List<Contact> newList) {
            if (newList == null || newList.isEmpty()) return;
            
            Set<Id> caseIds = new Set<Id>();
            Map<Id, Id> caseIdToContactId = new Map<Id, Id>();
            
            for (Contact con : newList) {
                if (con != null && con.CaseId__c != null) {
                    try {
                        Id caseId = (Id) con.CaseId__c;
                        caseIds.add(caseId);
                        caseIdToContactId.put(caseId, con.Id);
                    } catch (Exception e) {
                        // If casting fails, skip this record
                    }
                }
            }
            
            if (caseIds.isEmpty()) return;
            
            List<Case> casesToUpdate = new List<Case>();
        list<case> caseRecords = CaseService.getInstance().getCaseByIds(caseIds);
            
            for (Case cs :caseRecords) {
                Id contactId = caseIdToContactId.get(cs.Id);
                if (contactId != null && cs.Broker_Agent__c != contactId) {
                    cs.Broker_Agent__c = contactId;
                    casesToUpdate.add(cs);
                }
            }
            
            if (!casesToUpdate.isEmpty()) {
                CaseService csService1 = CaseService.getInstance();
                csService1.updateCasesWithoutTrigger(casesToUpdate);
            }
        }
    
    public static void updateContactDocuments(
        List<sObject> newList, Map<Id, sObject> newMap,
        List<sObject> oldList, Map<Id, sObject> oldMap
    ) {
        List<Contact> updatedContacts = new List<Contact>();
        
        for (Contact newRec : (List<Contact>) newList) {
            Contact oldRec = (Contact) oldMap.get(newRec.Id);
            
            String newRole = String.isBlank(newRec.BrokerContactRole__c) ? '' : newRec.BrokerContactRole__c.trim();
            String oldRole = String.isBlank(oldRec.BrokerContactRole__c) ? '' : oldRec.BrokerContactRole__c.trim();
            
            String newType = String.valueOf(newRec.TypeofEstablishment__c);
            String oldType = String.valueOf(oldRec.TypeofEstablishment__c);
            
            // If either Role or Type of Establishment changed, re-process
            if (newRole != oldRole || newType != oldType) {
                updatedContacts.add(newRec);
            }
        }
        
        if (!updatedContacts.isEmpty()) {
            createDocuments(updatedContacts);
        }
    }
    // Rushikesh: Reset IsSendEmail__c flag at the end of the day
    public static void resetIsSendMail() {
        List<Contact> contactsToReset = [SELECT Id, IsSendEmail__c 
                                         FROM Contact 
                                         WHERE IsSendEmail__c = true];
        for (Contact c : contactsToReset) {
            c.IsSendEmail__c = false;
        }
        if (!contactsToReset.isEmpty()) update contactsToReset;
    }

    public static void syncCaseDocumentsToContact(List<Contact> newList, Map<Id, Contact> oldMap, Set<Id> validCaseIds) {
        Set<Id> contactIds = new Set<Id>();
        DocumentService objDocService = DocumentService.getInstance();
        
        for (Contact con : newList) {
            if (con.CaseId__c != null && validCaseIds.contains(con.CaseId__c)) {
                contactIds.add(con.Id);
            }
        }
        
        if (contactIds.isEmpty()) return;
        
        Map<Id, Map<String, Document__c>> contactDocsMap = new Map<Id, Map<String, Document__c>>();
        for (Document__c doc : objDocService.getDocumentByContactIds(contactIds)) {
            
            if (!contactDocsMap.containsKey(doc.Contact__c)) {
                contactDocsMap.put(doc.Contact__c, new Map<String, Document__c>());
            }
            contactDocsMap.get(doc.Contact__c).put(doc.Document_Name__c, doc);
        }
        
        Map<Id, Map<String, Document__c>> caseDocsMap = new Map<Id, Map<String, Document__c>>();
        for (Document__c doc : objDocService.getCaseDocuments(validCaseIds)) {
            
            if (doc.Case__c == null) continue;
            if (!caseDocsMap.containsKey(doc.Case__c)) {
                caseDocsMap.put(doc.Case__c, new Map<String, Document__c>());
            }
            caseDocsMap.get(doc.Case__c).put(doc.Document_Name__c, doc);
        }
        
        List<Document__c> docsToUpdate = new List<Document__c>();
        
        for (Contact con : newList) {
            if (!validCaseIds.contains(con.CaseId__c)) continue;
            Map<String, Document__c> contactDocs = contactDocsMap.get(con.Id);
            Map<String, Document__c> caseDocs = caseDocsMap.get(con.CaseId__c);
            
            if (contactDocs == null || caseDocs == null) continue;
            
            for (String docName : caseDocs.keySet()) {
                
                Document__c contactDoc = contactDocs.get(docName);
                if (contactDoc == null) continue;
                
                Document__c caseDoc = caseDocs.get(docName);
                
                if (contactDoc.Content_Version_Id__c != caseDoc.Content_Version_Id__c) {
                    contactDoc.ContentDocumentId__c = caseDoc.ContentDocumentId__c;
                    contactDoc.Content_Version_Id__c = caseDoc.Content_Version_Id__c;
                    docsToUpdate.add(contactDoc);
                }
            }
        }
        objDocService.updateDocuments(docsToUpdate);
    }
}