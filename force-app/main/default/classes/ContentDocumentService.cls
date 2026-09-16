/*
* @Author : EaglesDev
* @CreatedDate : 9th Nov 2024
* @Description :  ContentDocument Service class
*/
/*****************************************************************************************************
* Version       Author      Date             Comment                                                                       
* 1.0           EaglesDev   9th Nov 2024    Initial draft 
*****************************************************************************************************/

public class ContentDocumentService {
    
    public List<ContentVersion> fetchContentVersion( List<ContentVersion> contentVersions){ 
        return [SELECT ContentDocumentId,Title FROM ContentVersion WHERE Id In :contentVersions];
    }
    public List<ContentDocumentLink> getContentDocLinkFromLinkEntityId(Set<Id> documentIds){
        return [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN :documentIds];
    }
    
    public List<ContentDocument> getContentDocuments(Set<Id> documentIds){

        return [SELECT Id, Title, LatestPublishedVersionId
                    FROM ContentDocument
                    WHERE Id IN :documentIds ];
    }
    public List<ContentVersion>  fetchContentVersionByContentIds(Set<Id> contentDocumentIds){
        return [SELECT ContentDocumentId, Title, FileExtension, VersionData
                    FROM ContentVersion
                    WHERE ContentDocumentId IN :contentDocumentIds
                ];
    }
    public List<ContentDocumentLink>  fetchContentDocLinksByLinkEntityIds(List<Id> recordIds){
        return [
            SELECT LinkedEntityId, ContentDocumentId 
            FROM ContentDocumentLink 
            WHERE LinkedEntityId IN :recordIds order by SystemModstamp desc
        ];
    }

}