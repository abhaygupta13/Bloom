@isTest
public class approvalProcessSubmitHandlerTest {
    @isTest  static void callApprovalProcess1(){
        Profile pf= [Select Id from profile where Name='System Administrator'];
        //list<User>smUser=[select id,name,ManagerId from User where Profile.Name='System Administrator' and ManagerId!=null];
        String orgId=UserInfo.getOrganizationId(); 
        String dateString=String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','') ;
        Integer RandomId=Integer.valueOf(Math.rint(Math.random()*1000000)); 
        String uniqueName=orgId+dateString+RandomId; 
        User uu=new User(firstname = 'ABC', 
                         lastName = 'XYZ', 
                         email = uniqueName + '@test' + orgId + '.org', 
                         Username = uniqueName + '@test' + orgId + '.org', 
                         EmailEncodingKey = 'ISO-8859-1', 
                         Alias = uniqueName.substring(18, 23), 
                         TimeZoneSidKey = 'America/Los_Angeles', 
                         LocaleSidKey = 'en_US', 
                         LanguageLocaleKey = 'en_US', 
                         ProfileId = pf.Id
                        ); 
        
        
        insert uu;
        
        User uu2=new User(firstname = 'ABC1', 
                         lastName = 'XYZ1', 
                         email = uniqueName + '@test' + orgId + '.org', 
                         Username = uniqueName + '@test123' + orgId + '.org', 
                         EmailEncodingKey = 'ISO-8859-1', 
                         Alias = uniqueName.substring(18, 23), 
                         TimeZoneSidKey = 'America/Los_Angeles', 
                         LocaleSidKey = 'en_US', 
                         LanguageLocaleKey = 'en_US', 
                         ProfileId = pf.Id,
                         ManagerId = uu.Id
                        ); 
        
        
        insert uu2;
        
        Project__c testProject=new Project__c(
        	Name='Test Project'
        );
        insert testProject;
        
       
            Account tempAcc=new Account(
            
            Name= 'test',
            MobileNumber__c = '12345678'   
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
        //list<Unit__C> unit=[select id from Unit__c];
        SalesOrder__c testOrder = new SalesOrder__c(
            Name = 'Test Order',
            Status__c = 'Booked',
            //SalesManager__c = smUser[0].Id,
            SalesManager__c = uu2.Id,
            Unit__c =testUnit.id,
            Account__c=tempAcc.id
        );
        insert testOrder;
        approvalProcessSubmitHandler.callApprovalProcess(testOrder.Id);
        approvalProcessSubmitHandler.updateSalesOrder(testOrder);
    }
}