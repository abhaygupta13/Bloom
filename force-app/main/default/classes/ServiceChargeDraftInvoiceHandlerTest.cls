@istest
public class ServiceChargeDraftInvoiceHandlerTest {
   @istest
   static void Generatedraftinvoicesexcecutiontest(){
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
            Status__c='Sold',
            UnitType__c='Townhouse',
            BuildingSectionName__c=testBuilding.id,
            Project__c=testProject.Id,
            PropertyUsage__c='Residential',
            UnitView__c  ='Beach Side',
            FloorNumber__c='01',
            NumberOfBedrooms__c='3',
            UnitModel__c='1BHK',
            SellingPrice__c= 700000,
            EndDate__c= date.today()+10,
            StartDate__c=date.today()-10
            
        );
        insert testUnit;
              Service_Charge_Configuration__c scc = new  Service_Charge_Configuration__c();
              scc.Status__c  = 'New';
              scc.Project__c = testProject.id;
              scc.Building_Phase__c = testBuilding.id;
              scc.Unit_Type__c = 'Townhouse';
              scc.General_Fund_Rate_Psqft__c = 10;
              scc.Reserve_Fund_Rate_Psqft__c = 10;
              scc.No_Of_Invoices_Per_Year__c = '2';
              scc.Year_Opening_Date__c = Date.today();
              scc.Year__c = '2024';
              insert scc;
        ServiceChargeDraftInvoiceHandler.saveResultWrapper result = new ServiceChargeDraftInvoiceHandler.saveResultWrapper();
        result.Id = scc.Id;
        result.isSuccess = true;
        result.error = null;
        result.statusCode = '200';
      
      
           Test.startTest();               
          List<ServiceChargeDraftInvoiceHandler.saveResultWrapper> result1= ServiceChargeDraftInvoiceHandler.Generatedraftinvoicesexcecution(scc.id,'Delete');
          List<ServiceChargeDraftInvoiceHandler.saveResultWrapper> result2 =  ServiceChargeDraftInvoiceHandler.Finiliseservicechargeinvoice(scc.id);
          Test.stopTest();
    } 
    
   
}