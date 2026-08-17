public class EmailUtil {
    public static EmailTemplate getEmailTemplateByName(String templateName){
        EmailTemplate mailTemplate = null;        
        if(String.isNotBlank(templateName)){
            mailTemplate = [SELECT Id, Name, DeveloperName, OwnerId, IsActive, Subject, FolderId, FolderName, Description, Body, HTMLValue, TemplateType FROM EmailTemplate WHERE Name =: templateName LIMIT 1];
        }
        return mailTemplate;
    }    
}