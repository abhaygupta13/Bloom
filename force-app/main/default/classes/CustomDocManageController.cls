/***
Class       : CustomDocManageController
Author      : Smaartt
Description : 
TestClass   : CustomDocManageControllerTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.          V1.0              27/04/23           Initial Version 
****************************************************************************************************************/
public without sharing class CustomDocManageController {
    
    //public static List<String> governmentRelationsDocList = new List<String>{'Title Deed'};
    //public static List<String> CollectionTeamDocList = new List<String>{''};
    //public static List<String> FinanceTeamDocList = new List<String>{'SOA'};
    //public static List<String> CRMTeamDocList = new List<String>{'ADDC NOC','KHO' };   
    //public static List<String> leasingTeamDocList = new List<String>{'Lease Agreement Attachment'};     
    // public static List<String> HOAgentDocList = new List<String>{'QA Snagging Report','QA Desnagging Report','CHO Desnagging Report','CHO Snagging Report'};   
    //public static List<String> SystemAdminDocList = new List<String>{'SOA','Title Deed','Payment Receipt','ADDC NOC','KHO','QA Snagging Report','QA Desnagging Report','CHO Desnagging Report','CHO Snagging Report','SPA','Passport','Emirates Id','Lease Agreement','Leasing ADDC NOC'};
    
    @AuraEnabled(cacheable=false)
    public static List<Document_Set_Up_Config__mdt> getDocMetaDataInfo(Id recordId) {
        String sObjectName = recordId.getSObjectType().getDescribe().getName();
        System.debug('sObjectName: ' + sObjectName);   
        system.debug('result'+[SELECT Id, MasterLabel,Related_Field__c,RelatedFiledRequired__c,Show_Create_Btn__c,Sobject__c,Sobject_lkup_Api_Name__c   
                               FROM Document_Set_Up_Config__mdt WHERE Sobject__c = :sObjectName]);
        return [SELECT Id, MasterLabel,Related_Field__c,RelatedFiledRequired__c,Show_Create_Btn__c,Sobject__c,Sobject_lkup_Api_Name__c   
                FROM Document_Set_Up_Config__mdt WHERE Sobject__c = :sObjectName];
    }
    
    @AuraEnabled(cacheable=false)
    public static List<Document__c> getDocumentList(string recordId, string sObjectLookupApiname) {
        string queryVal = 'Select id,Name,Document_Name__c,ContentDocumentId__c,Uploaded_By__c,Handover__c From Document__c Where '+sObjectLookupApiname+'=:recordId' ;
        system.debug(database.query(queryVal));  
        system.debug(sObjectLookupApiname);  
        return database.query(queryVal);
    } 
    
    @AuraEnabled(cacheable=false)
    public static String getHandoverLeasingDocName(string recordId) {
        String documentPattern = 'Lease Agreement%'; // Pattern to match
        Document__c documentList = [SELECT Id, Document_Name__c,CreatedDate FROM Document__c WHERE Document_Name__c LIKE :documentPattern
                                    AND Handover__c =:recordId ORDER BY CreatedDate DESC LIMIT 1];
        if(documentList!=null){
            return documentList.Document_Name__c;
        }
        return null;
    }  
    
    /*
* Method - getHandoverTeamUsersList
* Description - this method is used for download document 
*/
    
    @AuraEnabled(cacheable=false)
    public static List<Map<String, String>> downloadDocument(String recordId) {
        List<String> contentDocId = new List<String>();
        List<String> docList = new List<String>{HandoverConstants.SPA,HandoverConstants.Passport,HandoverConstants.BankNOC,HandoverConstants.Emirates_Id};
            List<Document__c> documentList = [SELECT Id, Document_Name__c, ContentDocumentId__c FROM Document__c WHERE Document_Name__c IN :docList AND Handover__c = :recordId];
        
        for (Document__c doc : documentList) {
            contentDocId.add(doc.ContentDocumentId__c);
        }
        
        List<ContentVersion> contentVersions = [SELECT Id, Title, VersionData, ContentDocumentId FROM ContentVersion WHERE ContentDocumentId IN :contentDocId];
        
        List<Map<String, String>> result = new List<Map<String, String>>();
     /*   for (ContentVersion version : contentVersions) {
            Map<String, String> fileMap = new Map<String, String>();
            fileMap.put('Title', version.Title);
            fileMap.put('VersionData', EncodingUtil.base64Encode(version.VersionData)); // Base64-encode the binary data
            result.add(fileMap);
        }*/
        
        // Prepare the list of files with their IDs and base64 data
        List<Map<String, String>> pdfFilesWithIds = new List<Map<String, String>>();
        for (ContentVersion version : contentVersions) {
            Map<String, String> pdfData = new Map<String, String>();
            pdfData.put('ContentDocumentId', version.ContentDocumentId);
            pdfData.put('Base64Data', EncodingUtil.base64Encode(version.VersionData));
            pdfFilesWithIds.add(pdfData);
        }
        
        return pdfFilesWithIds;
        
       // return result;
    }
    
    /*
* Method - getHandoverTeamUsersList
* Description - this method is used if the document section is being used on Handover record 
*/
    @AuraEnabled(cacheable=false)
    public static List<UserListWrapper> getHandoverTeamUsersList(String recordId){
        try{
            DocumentService DocumentService = DocumentService.getInstance();
            MetadataService handoverMetadataService = MetadataService.getInstance();
            Id financeQueueId = handoverMetadataService.getAppSettingTextValue(HandoverConstants.FINANCE_QUEUE);
            Id treasuryTeamQueueId = handoverMetadataService.getAppSettingTextValue(HandoverConstants.Handover_Treasury_Queue);
            Id operationQueueId = handoverMetadataService.getAppSettingTextValue(HandoverConstants.HO_OPERATION_QUEUE);
            Id leasingQueueId = handoverMetadataService.getAppSettingTextValue(HandoverConstants.Handover_Leasing_Team_Queue);
            Id governmentRelationsQueueId = handoverMetadataService.getAppSettingTextValue(HandoverConstants.Handover_Government_Relations_Queue);
            
            List<String> governmentRelationsUserOrGroupIds = new List<String>();
            List<String> OperationUserOrGroupIds = new List<String>();
            List<String> financeUserOrGroupIds = new List<String>();
            List<String> leasingUserOrGroupIds = new List<String>();
            List<String> treasuryTeamUserOrGroupIds = new List<String>();
            List<String> leasingTeamDocList = new List<String>();
            List<UserListWrapper> usersListToDicList = new List<UserListWrapper>();
            
            String documentPattern = 'Lease Agreement%'; // Pattern to match
            List<Document__c> documentList = [SELECT Id, Document_Name__c FROM Document__c WHERE Document_Name__c LIKE :documentPattern AND Handover__c =:recordId];
            for(Document__c doc : documentList){
                leasingTeamDocList.add(doc.Document_Name__c);
            }
            //Get all user of Treasury Team
           // Group treasuryTeamQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name =: HandoverConstants.Handover_Treasury_Queue LIMIT 1];
            List<GroupMember> treasuryTeamQueueMembers = [SELECT UserOrGroupId FROM GroupMember WHERE GroupId = :treasuryTeamQueueId];
            
            for(GroupMember operationMember : treasuryTeamQueueMembers) {
                treasuryTeamUserOrGroupIds.add(String.valueOf(operationMember.UserOrGroupId));
            }
            if(!treasuryTeamUserOrGroupIds.IsEmpty()){
                UserListWrapper ULWrap = new UserListWrapper();
                ULWrap.userList = treasuryTeamUserOrGroupIds;
                ULWrap.docList =  DocumentService.getDocWithProfileAccess(HandoverConstants.Profile_Treasury);
                usersListToDicList.add(ULWrap);
            }
            
            //Get all user of government Relations Team
           // Group governmentRelationsQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name =: HandoverConstants.Handover_Government_Relations_Queue LIMIT 1];
            List<GroupMember> governmentRelationsQueueMembers = [SELECT UserOrGroupId FROM GroupMember WHERE GroupId = :governmentRelationsQueueId];
            
            for(GroupMember operationMember : governmentRelationsQueueMembers) {
                governmentRelationsUserOrGroupIds.add(String.valueOf(operationMember.UserOrGroupId));
            }
            if(!governmentRelationsUserOrGroupIds.IsEmpty()){
                UserListWrapper ULWrap = new UserListWrapper();
                ULWrap.userList = governmentRelationsUserOrGroupIds;
                ULWrap.docList =  DocumentService.getDocWithProfileAccess(HandoverConstants.Profile_Government_relations_Team);
                usersListToDicList.add(ULWrap);
            }
            //Get all user of collection Team
           // Group operationQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name =: HandoverConstants.HO_OPERATION_QUEUE LIMIT 1];
            List<GroupMember> operationQueueMembers = [SELECT UserOrGroupId FROM GroupMember WHERE GroupId = :operationQueueId];
            
            for(GroupMember OperationMember : operationQueueMembers) {
                OperationUserOrGroupIds.add(String.valueOf(OperationMember.UserOrGroupId));
            }
            if(!OperationUserOrGroupIds.IsEmpty()){
                UserListWrapper ULWrap = new UserListWrapper();
                ULWrap.userList = OperationUserOrGroupIds;
                ULWrap.docList =  DocumentService.getDocWithProfileAccess(HandoverConstants.Profile_Operations_Team);
                usersListToDicList.add(ULWrap);
            }
            //Get all user of finance Team
            //Group financeQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name =: HandoverConstants.FINANCE_QUEUE LIMIT 1];
            List<GroupMember> financeQueueMembers = [SELECT UserOrGroupId FROM GroupMember WHERE GroupId = :financeQueueId];
            
            for(GroupMember financeMember : financeQueueMembers) {
                financeUserOrGroupIds.add(String.valueOf(financeMember.UserOrGroupId));
            }
            if(!financeUserOrGroupIds.IsEmpty()){
                UserListWrapper ULWrap = new UserListWrapper();
                ULWrap.userList = financeUserOrGroupIds;
                ULWrap.docList =  DocumentService.getDocWithProfileAccess(HandoverConstants.Profile_Finance_Team);
                usersListToDicList.add(ULWrap);
            }
            //Get all user of Leasing Team
           // Group leasingQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name =: HandoverConstants.Handover_Leasing_Team_Queue LIMIT 1];
            List<GroupMember> leasingQueueMembers = [SELECT UserOrGroupId FROM GroupMember WHERE GroupId = :leasingQueueId];
            
            for(GroupMember financeMember : leasingQueueMembers) {
                leasingUserOrGroupIds.add(String.valueOf(financeMember.UserOrGroupId));
            }
            if(!leasingUserOrGroupIds.IsEmpty()){
                UserListWrapper ULWrap = new UserListWrapper();
                ULWrap.userList = leasingUserOrGroupIds;
                ULWrap.docList = leasingTeamDocList;
                usersListToDicList.add(ULWrap);
            }
            //Get all user of CRM Team
            List<Round_Robins__c> rrList = [SELECT Id,Name,Assigned_To__c,
                                            (SELECT Id,User__c FROM Round_Robin_Users__r WHERE IsActive__c = TRUE AND Sobject__c=: HandoverConstants.HANDOVER_SOBJECT)
                                            FROM Round_Robins__c WHERE Sobject__c=: HandoverConstants.HANDOVER_SOBJECT AND Team__c =: HandoverConstants.TEAM_CRM];
            if(!rrList.isEmpty()){
                List<Id> rrUserIds = new List<Id>();
                for(Round_Robins__c rr : rrList){
                    for (Round_Robin_User__c rrUser : rr.Round_Robin_Users__r) {
                        rrUserIds.add(rrUser.User__c);
                    }
                }
                UserListWrapper ULWrap = new UserListWrapper();
                ULWrap.userList = rrUserIds;
                ULWrap.docList = DocumentService.getDocWithProfileAccess(HandoverConstants.Profile_CRM_Team);
                usersListToDicList.add(ULWrap);
            }
            
            //Get all user of HO Agent Team
            Map<Id,User> userLists = new Map<Id,User>([SELECT Id FROM User WHERE IsActive = true AND Profile.Name = 'HO Agent']);
            if(userLists.size()>0){
                UserListWrapper ULWrap = new UserListWrapper();
                ULWrap.userList = new List<String>(userLists.keySet().size());
                for (Id userId : userLists.keySet()) {
                    ULWrap.userList.add((String) userId);
                }
                //ULWrap.userList = new List<String>(userLists.keySet());
                ULWrap.docList = DocumentService.getDocWithProfileAccess(HandoverConstants.Profile_HO_Agent);
                usersListToDicList.add(ULWrap);
            }
            
            // Set the admin user for all document delete access
            String profileName = [SELECT Id,Name FROM Profile WHERE Id=: UserInfo.getProfileId() LIMIT 1].Name;
            if(profileName == 'System Administrator'){
                UserListWrapper ULWrap = new UserListWrapper();
                ULWrap.userList = new List<String>{UserInfo.getUserId()};
                    ULWrap.docList = DocumentService.getDocWithProfileAccess(HandoverConstants.Profile_System_Administrator);
                usersListToDicList.add(ULWrap);
            }
            
            return usersListToDicList;
        }catch(Exception ex){
            ErrorLogHandler.logError('CustomDocManageController','getHandoverTeamUsersList',ex,'');
            return null;
        }
    }    
    
    @AuraEnabled
    public static Document__c addFilesonRecord(String base64, String filename,Document__c documentObj){       
        try {
            system.debug('documentObj.Id'+documentObj.Id);
            ContentVersion cv = createContentVersion(base64, filename);            
            ContentDocumentLink cdl = createContentLink(cv.Id, documentObj.Id);
            documentObj.Content_Version_Id__c= cv.id;
            documentObj.ContentDocumentId__c = cdl.ContentDocumentId;
            documentObj.Uploaded_By__c = UserInfo.getUserId();
            update documentObj;
            if(documentObj.Id != null){
                Document__c doc = [SELECT Id, Document_Name__c,Handover__r.Id FROM Document__c WHERE Id = :documentObj.Id];
                if(doc.Document_Name__c == 'Tawtheeq Registration Confirmation'){
                    String result = HandoverEmailHelper.sendEmailProcess(HandoverConstants.ADDC_Registration_Email, doc.Handover__r.Id,new List<String>(),new List<String>(),new List<String>());
                    system.debug('result'+result);
                }
            }
            System.debug('documentObj - ' + documentObj);
            
            return documentObj;   
        } catch (Exception exp) {
            ErrorLogHandler.logError('CustomDocManageController','addFilesonRecord',exp,'');
            throw new AuraHandledException(exp.getMessage());
        }
    }
    
    @AuraEnabled
    public static String addFilesonRecordCreate(String base64, String filename,Document__c documentObj){
        try {  
            String str='ERROR';
            
            ContentVersion cv = createContentVersion(base64, filename);            
            ContentDocumentLink cdl = createContentLink(cv.Id, documentObj.Id);
            documentObj.Content_Version_Id__c= cv.id;
            documentObj.ContentDocumentId__c = cdl.ContentDocumentId;
            
            update documentObj;
            str='SUCCESS';
            //return documentObj;            
            return str;
        } catch (Exception exp) {
            //throw new AuraHandledException(exp.getMessage());
            ErrorLogHandler.logError('CustomDocManageController','addFilesonRecordCreate',exp,'');
            list<string> sfs = exp.getMessage().split(',');
            sfs.remove(0);
            String errorMessage = String.join(sfs, ', ');
            errorMessage = errorMessage.removeEnd(': []');
            throw new Auraexception(errorMessage);
        }
        //return str;
    }
    
    
    // Required for file upload
    public static ContentVersion createContentVersion(String base64, String filename) {
         try {
           
            String finalFilename = filename;
        if (!finalFilename.toLowerCase().endsWith('.pdf')) {
            finalFilename += '.pdf';
        }

        ContentVersion cv = new ContentVersion();
        cv.VersionData = EncodingUtil.base64Decode(base64);
        cv.Title = finalFilename.replace('.pdf', ''); // Title should not have extension
        cv.Origin = 'H';
        cv.PathOnClient = '/' + finalFilename;
            insert cv;
            return cv;
         } catch(DMLException e) {
            System.debug(e);
            ErrorLogHandler.logError('CustomDocManageController','createContentVersion',e,'');
            return null;
        }
    }
    
    // used in file upload
    public static ContentDocumentLink createContentLink(String contentVersionId, String recordId) {
        try {
            if (contentVersionId == null || recordId == null) { return null; }
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =: contentVersionId].ContentDocumentId;
            cdl.LinkedEntityId = recordId;       
            cdl.ShareType = 'V';
            
            insert cdl;
            return cdl;
        } catch(DMLException e) {
            System.debug(e);     
            ErrorLogHandler.logError('CustomDocManageController','createContentLink',e,'');
            return null;
        }
    }
    @AuraEnabled
    public static void deleteFile(String documentId) {
        try{
            List<Document__c> docRecords = [SELECT Id, ContentDocumentId__c FROM Document__c WHERE Id = :documentId];
            
            Id contentDocumentId = docRecords[0].ContentDocumentId__c;
            
            delete new ContentDocument(Id = contentDocumentId);
            for(Document__c doc:docRecords){
                doc.ContentDocumentId__c='';
                doc.Content_Version_Id__c='';
                update doc;
            }               
        } catch (Exception exp) {
            ErrorLogHandler.logError('CustomDocManageController','deleteFile',exp,'');
            throw new Auraexception(exp.getMessage());
        }
    }   
    
    @AuraEnabled
    public static List<Map<String, String>> getPdfFilesWithIdsAsBase64(Id handoverId) {
                 
        // Find all document related to the given handover
        List<Document__c> docList = [SELECT Id, Document_Name__c, ContentDocumentId__c, Handover__c, Content_Version_Id__c
                					FROM Document__c WHERE Handover__c =: handoverId];
        List<Id> contentDocumentIds = new List<Id>();
        for(Document__c doc: docList){
            contentDocumentIds.add(doc.ContentDocumentId__c);
        }
        
        // Find all content versions based on the content document IDs
        List<ContentVersion> contentVersions = [
            SELECT ContentDocumentId, VersionData, CreatedDate
            FROM ContentVersion
            WHERE ContentDocumentId IN :contentDocumentIds
            ORDER BY CreatedDate DESC
        ];
        
        // Map content document ID to its content versions
        Map<Id, List<ContentVersion>> documentVersionsMap = new Map<Id, List<ContentVersion>>();
        for (ContentVersion version : contentVersions) {
            if (!documentVersionsMap.containsKey(version.ContentDocumentId)) {
                documentVersionsMap.put(version.ContentDocumentId, new List<ContentVersion>());
            }
            documentVersionsMap.get(version.ContentDocumentId).add(version);
        }
        
        // Prepare the list of files with their IDs and base64 data
        List<Map<String, String>> pdfFilesWithIds = new List<Map<String, String>>();
        
        for (ContentVersion version : contentVersions) {
            Map<String, String> pdfData = new Map<String, String>();
            pdfData.put('ContentDocumentId', version.ContentDocumentId);
            pdfData.put('Base64Data', EncodingUtil.base64Encode(version.VersionData));
            pdfFilesWithIds.add(pdfData);
        }
        
        return pdfFilesWithIds;
    }
    
    public class UserListWrapper
    {
        @AuraEnabled public List<String> userList;
        @AuraEnabled public List<String> docList;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<FileWrapper> getFiles(Id recordId) {
List<String> docListName = new List<String>{HandoverConstants.SPA,HandoverConstants.Passport,HandoverConstants.BankNOC,HandoverConstants.Emirates_Id};
List<Document__c> docList = [SELECT Id, Document_Name__c, ContentDocumentId__c, Handover__c, Content_Version_Id__c
                					FROM Document__c WHERE Document_Name__c IN:docListName AND Handover__c =: recordId];
        Set<Id> documentIds = new Set<Id>();
        for (Document__c link : docList) {
            documentIds.add(link.ContentDocumentId__c);
        }

        List<FileWrapper> files = new List<FileWrapper>();
        for (ContentVersion version : [
            SELECT Id, Title, FileType, VersionData 
            FROM ContentVersion 
            WHERE ContentDocumentId IN :documentIds
            ORDER BY CreatedDate DESC
        ]) {
            FileWrapper file = new FileWrapper();
            file.id = version.Id;
            file.title = version.Title;
            file.fileType = version.FileType;
            file.base64Data = EncodingUtil.base64Encode(version.VersionData);
            files.add(file);
        }
        return files;
    }

    public class FileWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public String title;
        @AuraEnabled public String fileType;
        @AuraEnabled public String base64Data;
    }
    
}