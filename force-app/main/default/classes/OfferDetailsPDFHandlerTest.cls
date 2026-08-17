@isTest
public class OfferDetailsPDFHandlerTest {
	@isTest
    static void testOfferDetailsPDFHandler() {
        
        Project__c testProject=new Project__c(
        	Name='Test Project'
        );
        insert testProject;
        
         Id AccountRecordTypeId = [Select id,Name from RecordType where Name='Organization Account'].id;
        Account tempAcc=new Account(
            RecordTypeId=AccountRecordTypeId,
            Name= 'test'
            
        );
        
        insert tempAcc;
               
        
        Contact tempContact =new Contact(
            LastName='test',
            AccountId=tempAcc.id,
            Email='test@gmail.com'
        );
        insert tempContact;
        Opportunity tempOpp=new Opportunity(
            Name='tempOpp',
            StageName='New',
            CloseDate=system.today(),
            LeadChannel__c='Call',
            AccountId=tempAcc.Id,
            ContactId=tempContact.id,
            Contact__c=tempContact.id,
            WinReason__c='Loyalty'
        );
        insert tempOpp;
       
        
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
            BuildingSectionName__c=testBuilding.id,
            Project__c=testProject.Id,
            PropertyUsage__c='Residential',
            UnitView__c  ='Beach Side',
            FloorNumber__c='01',
            NumberOfBedrooms__c='3',
            UnitModel__c='1BHK',
            SellingPrice__c= 700000,
            Internal_Saleable_Area__c=200,
            External_Saleable_Area__c=300,
            SaleableArea__c=500
        );
        insert testUnit;
       
        
        OffersPromotions__c testOffer=new OffersPromotions__c(
        	Name='testOffer',
            OfferName__c='testOffer',
            Project__c=testProject.id,
            StartDate__c=system.today(),
            EndDate__c=system.today().addDays(2)
        );
        insert testOffer;
        
        UnitDesign__c testUnitDesign=new UnitDesign__c(
        	
            Unit__c=testUnit.id,
            DesignType__c='Standard Price'
        );
		insert testUnitDesign;
        
        Document__c testDocument = new Document__c(Unit__c = testUnit.Id, Document_Name__c = 'Test Document', Document_Type__c = 'Floor Plan');
        insert testDocument;
        
        


      /*  ApexPages.currentPage().getParameters().put('currentUnit', testUnit.Id);
        ApexPages.currentPage().getParameters().put('customerName', 'Test Customer');
        ApexPages.currentPage().getParameters().put('currentOffer', testOffer.Id);
        ApexPages.currentPage().getParameters().put('selectedDesign', testUnitDesign.id);*/

       	SalesOfferUtilityHandler.SalesOfferDetails testSalesOfferDetails = new SalesOfferUtilityHandler.SalesOfferDetails();
        string todayDate=String.valueOf(system.today());
        string customerName='Name';
        
        
       // OfferDetailsPDFHandler handler = new OfferDetailsPDFHandler();
        //handler.getOppDetails();
         //  handler.getBrochureLink();
        //handler.offerDetails = testSalesOfferDetails;
        //OfferDetailsPDFHandler.getDocumentInfo(); 
        //OfferDetailsPDFHandler.getBrochureLink();
        //Test.stopTest();
        PageReference pageRef = Page.OfferDetailsPDF;
        Test.setCurrentPage(pageRef);   
        // Put Id into the current page Parameters
	    ApexPages.currentPage().getParameters().put('id',tempOpp.Id);
       ApexPages.currentPage().getParameters().put('currentUnit', testUnit.Id);
        ApexPages.currentPage().getParameters().put('customerName', 'Test Customer');
        ApexPages.currentPage().getParameters().put('currentOffer', testOffer.Id);
        ApexPages.currentPage().getParameters().put('selectedDesign', testUnitDesign.id);
        
        OfferDetailsPDFHandler handler = new OfferDetailsPDFHandler();
        handler.getBrochureLink();
        //fetch Created Link
        //obj.createPublickLink();
 

    }
}