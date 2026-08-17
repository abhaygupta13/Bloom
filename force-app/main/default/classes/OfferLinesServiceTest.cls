@isTest

public class OfferLinesServiceTest {
    @isTest static void OfferLinesServiceTestMethod(){
        
        Project__c testProject=new Project__c(
            Name='Test Project'
        );
        insert testProject;
        OffersPromotions__c  offername = new OffersPromotions__c();
        offerName.OfferName__c = 'test offer';
        offerName.StartDate__c = system.today();
        offerName.EndDate__c=system.today().addDays(10);
        offerName.Project__c = testProject.id;
        
        
        insert offername;
        
        OfferLines__c offerLine = new OfferLines__c();
        offerLine.OfferName__c = offername.Id;
        offerLine.OfferType__c='Additional Discount';
        offerLine.OfferOn__c= 'Selling Price';
        offerLine.OfferValue__c =20000;
        
        insert offerLine;
        
        String testQuery = 'SELECT Id, Name FROM OfferLines__c WHERE Name = \'test offer\''; 
       
        OfferLinesService.getOfferLinesQuery(testQuery);
        
        
        
        
    }}