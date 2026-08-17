/*
* @Author : EaglesDev
* @CreatedDate : 9th Nov 2024
* @Description :  ServiceCatalogDocument Service class
*/
/*****************************************************************************************************
* Version       Author      Date             Comment                                                                       
* 1.0           EaglesDev   9th Nov 2024    Initial draft 
*****************************************************************************************************/

public class ServiceCatalogDocumentService {
    
    public static List<Service_Catolog_Documents__c> getCatalogDocumentsByService(Set<Id> docIds,String srId){
        return [select Name,Document_Name__c,Document_Size__c,Document_Type__c,Required_For__c, is_Chiller_Enabled__c,Service_Catalog__r.Name  from Service_Catolog_Documents__c where Id IN:docIds AND Service_Catalog__c=:srId];
    }
    
    public static List<Service_Catolog_Documents__c> getCatalogDocumentsByCatalogName(String serviceCatalogName){
        return [select Name,Required_For__c,Document_Name__c  from Service_Catolog_Documents__c  where Service_Catalog__r.Name =:serviceCatalogName];
    }

}