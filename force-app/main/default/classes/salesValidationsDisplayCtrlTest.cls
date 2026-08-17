@isTest
public class salesValidationsDisplayCtrlTest {
    
     @isTest static void getSalesValidation(){
        Project__c testProject=new Project__c(
        	Name='Test Project'
        );
        insert testProject;
         
       Account tempAcc=new Account(
            Name= 'test'
            
        );
         insert tempAcc;
        
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
            Project__c=testProject.Id
        );
        insert testUnit;
        SalesOrder__c testOrder = new SalesOrder__c(
            Name = 'Test Order',
            Status__c = 'Booked',
            Account__c= tempAcc.id,
            //SalesManager__c = sm[0].id,
            Unit__c =testUnit.id
        );
        insert testOrder;
        Sales_Validation__c testValidation= new Sales_Validation__c(
        	Sales_Order__c=testOrder.id
        );
        insert testValidation;
        List<Sobject> records=new List<Sobject>();
        records.add(testValidation);
        //string profileName='System Administrator';
        salesValidationsDisplayCtrl.getSalesValidation(testOrder.id);
        salesValidationsDisplayCtrl.updateSalesValidationInfo(records);
     }
}