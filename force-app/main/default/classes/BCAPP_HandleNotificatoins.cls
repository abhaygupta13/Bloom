//============================ BCAPP_Utility =============================
/*
* @Author : Eagles  
* @CreatedDate : 04 Sept 2024
* @Name : BCAPP_Utility
* @Description : This APEX class used to handle the Events, Newsletters and Notices in the Bloom Community Mobile APP.
*/
/*****************************************************************************************************
* Version       Author                  Date             Comment                                                                       
* 1.0           Eagles               28 OCT 2024        Initial draft 
*****************************************************************************************************/

public class BCAPP_HandleNotificatoins {
    
    public List<NotificationWrapper> getNotifications(Date startDate,Date endDate,List<String> projectIds,String recordType){
        
        String recordTypeName = BCAPP_Constants.notificationRT.get(recordType);       
        String nRecordTypeId =  Utilities.getRecordTypeId('Notifications__c',recordTypeName);//SObjectType.Notifications__c.getRecordTypeInfosByDeveloperName().get(recordTypeName).getRecordTypeId(); 
        
        List<NotificationWrapper> resultWrp = new List<NotificationWrapper>(); 
        Map<Id, List<FileDetails>> linkEntityURLs;
        if(nRecordTypeId!=null){
            String query = 'SELECT Name,Description__c,CreatedDate,Project__r.Name,Publish_Date_Time__c,Event_Venue__c FROM Notifications__c where Project__c IN:projectIds AND recordTypeId=:nRecordTypeId AND Status__c= \'Published\'';
            if (startDate != null) {
                query += ' AND Publish_Date_Time__c >= :startDate';
            } if (endDate != null) {
                query += ' AND Publish_Date_Time__c <= :endDate';
            }
            query += ' Order By Publish_Date_Time__c desc';
            system.debug('query--'+startDate+'--'+endDate);
            system.debug('query--'+query);
            Map<Id, Notifications__c> notificationMap = new Map<Id, Notifications__c>((List<Notifications__c>)Database.query(query));
            
            if(!notificationMap.isEmpty()){
                linkEntityURLs = getContentDownloadUrls(notificationMap.keySet());
            }
            for(String nId:notificationMap.keySet()){
                Notifications__c notification = notificationMap.get(nId);
            	NotificationWrapper wrp = new NotificationWrapper();
                wrp.recId = nId;
                wrp.venue = notification.Event_Venue__c;
                wrp.name = notification.Name;
                wrp.description = notification.Description__c;
                wrp.fileDetails = linkEntityURLs.get(nId);
                wrp.projectName = notification.Project__r.Name;
                if(recordType=='events' && notification.Publish_Date_Time__c!=null){
                    wrp.nDate = notification.Publish_Date_Time__c.date();
                   // wrp.nTime = notification.Publish_Date_Time__c.format('HH:mm:ss');
                    Datetime publishDateTime = notification.Publish_Date_Time__c;
                    wrp.nTime = publishDateTime.format('hh:mm a'); // 12-hour clock with AM/PM
                }
                else{
                    wrp.nDate = notification.Publish_Date_Time__c.date();
                }
                
                resultWrp.add(wrp);
        	}
        }
        return resultWrp;
    }
    
    private Map<Id, List<FileDetails>> getContentDownloadUrls(Set<Id> contentIds) {
        
        Map<Id, List<FileDetails>> downloadUrlMap = new Map<Id, List<FileDetails>>();
        
        List<ContentDocumentLink> cdlList = [
            SELECT ContentDocumentId, ContentDocument.Title, ContentDocument.LatestPublishedVersionId, LinkedEntityId 
            FROM ContentDocumentLink 
            WHERE LinkedEntityId IN :contentIds
        ];
        
        // Create a map to hold ContentDocumentId to ContentDocumentLink
        Map<Id, ContentDocumentLink> cdlMap = new Map<Id, ContentDocumentLink>();
        for (ContentDocumentLink cdl : cdlList) {
            cdlMap.put(cdl.LinkedEntityId, cdl);
        }
        
        // Now get the ContentDistributions for the LatestPublishedVersionIds
        Set<Id> versionIds = new Set<Id>();
        for (ContentDocumentLink cdl : cdlList) {
            versionIds.add(cdl.ContentDocument.LatestPublishedVersionId);
        }
        
        List<ContentDistribution> cdList = [
            SELECT Name, ContentDownloadURL, ContentVersionId,ContentVersion.FileExtension,ContentVersion.Title,DistributionPublicUrl
            FROM ContentDistribution 
            WHERE ContentVersionId IN :versionIds
        ];
        
        // Create a map for quick access to ContentDistribution by ContentVersionId
        Map<Id, ContentDistribution> cdMap = new Map<Id, ContentDistribution>();
        for (ContentDistribution cd : cdList) {
            cdMap.put(cd.ContentVersionId, cd);
        }
        
        List<ContentDistribution> newItems = new List<ContentDistribution>();
        
        // Iterate through the cdlMap and check for existing ContentDistribution
        for (ContentDocumentLink cdl : cdlList) {
            if (cdMap.containsKey(cdl.ContentDocument.LatestPublishedVersionId)) {
                if( !downloadUrlMap.containsKey(cdl.LinkedEntityId)){
                     downloadUrlMap.put(cdl.LinkedEntityId,new List<FileDetails>());
                }
                FileDetails details = new FileDetails();
                details.fileURL = cdMap.get(cdl.ContentDocument.LatestPublishedVersionId).ContentDownloadURL;
                details.fileName = cdMap.get(cdl.ContentDocument.LatestPublishedVersionId).Name;
                details.previewURL = cdMap.get(cdl.ContentDocument.LatestPublishedVersionId).DistributionPublicUrl;
                details.fileType = cdMap.get(cdl.ContentDocument.LatestPublishedVersionId).ContentVersion.FileExtension;
                downloadUrlMap.get(cdl.LinkedEntityId).add(details);
            } 
        }
        
        return downloadUrlMap;
    }
    
    public void getEventDetails(String reqInput){
        Map<String,Object> returnValue = new Map<String,Object>();
 		Map<String, Object> reqData = (Map<String, Object>) JSON.deserializeUntyped(reqInput);
        String eventId = (String)reqData.get('eventId');
        try {        
            List<Notifications__c> lstNotify = [select Description__c,Publish_Date_Time__c,Event_Venue__c,Name from Notifications__c where Id=:eventId ];
            if(!lstNotify.isEmpty()){
                Map<Id, List<FileDetails>> fileUrls = getContentDownloadUrls(new Set<Id>{lstNotify[0].Id});
                NotificationWrapper wrp = new NotificationWrapper();
                wrp.name = lstNotify[0].Name;
                wrp.recId = lstNotify[0].Id;
                wrp.description = lstNotify[0].Description__c;
                wrp.venue = lstNotify[0].Event_Venue__c;
                if(!fileUrls.isEmpty()){
                    wrp.fileDetails = fileUrls.get(lstNotify[0].Id);
                }
                if(lstNotify[0].Publish_Date_Time__c!=null){
                    wrp.nDate = lstNotify[0].Publish_Date_Time__c.date();
                    //wrp.nTime = lstNotify[0].Publish_Date_Time__c.format('HH:mm:ss');
                    Datetime publishDateTime = lstNotify[0].Publish_Date_Time__c;
                    wrp.nTime = publishDateTime.format('hh:mm:ss a'); // 12-hour clock with AM/PM
                }
                returnValue.put('event-detail',wrp);
                BCAPP_WebServiceHelper.makeSuccessResponse(returnValue);
            }
            
        }
        catch(Exception e){ 
            returnValue.put('errorMessage',e.getMessage());
            BCAPP_WebServiceHelper.makeServerErrorResponse(returnValue);
        }
    }
    
       
   public void getAlerts(Map<String, Object> reqData){
       
       system.debug('Inside Alerts method');
        Map<String,Object> returnValue = new Map<String,Object>();
        String accountId = (String)reqData.get('accountId');
       system.debug('Inside Alerts method--'+accountId);
        String nRecordTypeId =  Utilities.getRecordTypeId('Notifications__c','Alerts');
       system.debug('Inside Alerts method--'+nRecordTypeId);
        try {        
            List<Notifications__c> lstNotify = [select Description__c,Publish_Date_Time__c,Name from Notifications__c where Account__c=:accountId AND recordTypeId=:nRecordTypeId ];
            List<Map<String,String>> lstWrp = new List<Map<String,String>>();
             DateTime now = System.now();
            for(Notifications__c rec: lstNotify){
                Map<String,String> wrp = new Map<String,String>();
                wrp.put('name',rec.Name);
                wrp.put('description',rec.Description__c);
                if(rec.Publish_Date_Time__c!=null){
                    DateTime dt = rec.Publish_Date_Time__c;
                    Long diffInMillis = now.getTime() - dt.getTime();
        			Long diffInHours = diffInMillis / (1000 * 60 * 60);
                    if (diffInHours < 1) {
                        wrp.put('time','1 day ago');
        			}
                    else{
                        wrp.put('time', dt.format('dd MMM yyyy'));
                    }
                }
                lstWrp.add(wrp);
               
            }
             returnValue.put('alerts',lstWrp);
             BCAPP_WebServiceHelper.makeSuccessResponse(returnValue);
            
        }
        catch(Exception e){ 
            returnValue.put('errorMessage',e.getMessage());
            BCAPP_WebServiceHelper.makeServerErrorResponse(returnValue);
        }
    }
    
    public class FileDetails { 
        public String fileURL { get; set; }
        public String previewURL { get; set; } 
        public String fileType { get; set; }
        public String fileName { get; set; }
    }
    public class NotificationWrapper {
        public String recId { get; set; }
        public String projectName { get; set; }
        public String name { get; set; }
        public String description { get; set; }
        public Date nDate  { get; set; }
        public List<FileDetails> fileDetails  { get; set; }
        public String nTime { get; set; }
        public String venue { get; set; }
    }
    
    
}