@isTest
public class customImageCarouselHandlerTest {
    @isTest static void customImageCarouselHandlerTestMethod(){
               Project__c testProject=new Project__c(
        	Name='Test Project'
        );
        insert testProject;
        BuildingSection__c testBuilding=new BuildingSection__c(
        	Name='Test Building',
            BuildingSectionCode__c='BL-CAS',
            Project__c=testProject.Id
        );
        insert testBuilding;
        Unit__c testUnit=new Unit__c(
        	Name='test Unit',
            Status__c='Available',
            UnitType__c='Townhouse',
            BuildingSectionName__c=testBuilding.Id,
            Project__c=testProject.Id
        );
        insert testUnit;
        
     
        
        
      List<Custom_Carousel_Config__mdt> carouselMetadata = [SELECT Id, Parent_Field_Api_Name__c FROM Custom_Carousel_Config__mdt WHERE MasterLabel ='Project__c'];
       
       System.debug(carouselMetadata);
       customImageCarouselHandler.getImages(testProject.Id);
        customImageCarouselHandler.getImages(testUnit.Id);
        

       
    }
}