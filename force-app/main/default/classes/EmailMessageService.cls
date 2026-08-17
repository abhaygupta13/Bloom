/**
* Class       : EmailMessageService
* Description : Service class to handle queries related to EmailMessage.
* Created By  : Kalpana
* Created Date: 01/08/2025
*/
public inherited sharing class EmailMessageService {
    
    private static EmailMessageService instance;
    
    private EmailMessageService() {
        
    }
    
    public static EmailMessageService getInstance() {
        if (instance == null) {
            instance = new EmailMessageService();
        }
        return instance;
    }
    
    public EmailMessage getLatestEmailMessageByRelatedToId(Id relatedToId) {
        
        List<EmailMessage> messages = [
            SELECT Id, RelatedToId, CreatedDate
            FROM EmailMessage
            WHERE RelatedToId = :relatedToId
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        
        return messages.isEmpty() ? null : messages[0];
    }
     public Map<Id,EmailMessage> getLatestEmailMessageByRelatedIds(Set<Id> relatedIds) {
        Map<Id, EmailMessage> objEmailMessageMap = new Map<Id,EmailMessage>();
        for(EmailMessage objEmailMessage : [SELECT Id, RelatedToId, CreatedDate FROM EmailMessage WHERE RelatedToId IN :relatedIds AND CreatedDate = TODAY ORDER BY CreatedDate DESC]){
            if(!objEmailMessageMap.containsKey(objEmailMessage.RelatedToId)){
                objEmailMessageMap.put(objEmailMessage.RelatedToId, objEmailMessage);
            }
        }
        return objEmailMessageMap;
    }
     public List<Attachment> insertEmailAttachment(List<Attachment> attachmentList){
        if(attachmentList != NULL && !attachmentList.isEmpty()){
            insert attachmentList;
        }
        return attachmentList;
    }
}