/**
* @File Name : EmailTemplateService.cls
* @Description :
* @Author : EaglesDev
* @Last Modified By :
* @Last Modified On : November 8, 2024
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | November 8, 2024 |   | Initial Version
**/
public inherited sharing class EmailTemplateService {
    private static EmailTemplateService inst;
    public static EmailTemplateService getInstance() {
        if (inst == null) inst = new EmailTemplateService();
        return inst;
    }
    private EmailTemplateService() {}
    
    public static EMailTemplate getEmailTemplateByName(String name){
        return [SELECT Id, HtmlValue, Body, Subject,Name FROM EmailTemplate WHERE Name =:name LIMIT 1];
    }

    public static EMailTemplate getEmailTemplateByDeveloperName(String developerName){
        return [SELECT Id, HtmlValue, Body, Subject,DeveloperName FROM EmailTemplate WHERE DeveloperName =:developerName LIMIT 1];
    }
    public List<EMailTemplate> getEmailTemplateByDeveloperNames(Set<String> allTemplateNames){
        return [SELECT Id, HtmlValue, Body, Subject,DeveloperName FROM EmailTemplate WHERE DeveloperName IN:allTemplateNames ];
    }
     public EmailTemplate getByDeveloperName(String devName) {
        return [
            SELECT Id, HtmlValue, Body
            FROM EmailTemplate
            WHERE DeveloperName = :devName
            LIMIT 1
        ];
    }
    
}