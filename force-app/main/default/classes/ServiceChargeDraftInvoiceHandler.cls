public class ServiceChargeDraftInvoiceHandler {
    @AuraEnabled
    Public Static list<saveResultWrapper> Generatedraftinvoicesexcecution(id Servicecongid,string Method){
        system.debug(Method); 
        Service_Charge_Configuration__c scctoupdate = [select id,status__c from Service_Charge_Configuration__c where id =: Servicecongid];
        List<Service_Charge_Configuration__c> Scclisttoupdate = New List<Service_Charge_Configuration__c>();
        List<Unit__C> ulisttoupdate = New List<Unit__C>(); 
        Service_Charge_Configuration__c scc = [SELECT id,Project__c,Building_Phase__c,Unit_Type__c,Reserve_Fund_Rate_Psqft__c,General_Fund_Rate_Psqft__c from Service_Charge_Configuration__c where id=: Servicecongid];
        String query = 'SELECT id, Project__c,BuildingSectionName__c,UnitType__c,Internal_Saleable_Area__c from unit__C where id !=null';
        If (scc.Project__c != null) {
            query+= ' AND Project__c = \''+ scc.Project__c + '\'';
        } 
        if (scc.Building_Phase__c != null){
            query+= 'AND BuildingSectionName__c = \''+scc.Building_Phase__c + '\'';
        }
        if (scc.Unit_Type__c != null){
            query+= 'AND UnitType__c = \''+scc.Unit_Type__c + '\'';
        }
        List<Unit__C> Ulist = Database.query(query);
        for(Unit__C U : Ulist){
            IF(scc.Reserve_Fund_Rate_Psqft__c != null && Method == 'Generate'){
                u.Draft_GeneratedReserveFundServiceCharge__c = u.Internal_Saleable_Area__c * scc.Reserve_Fund_Rate_Psqft__c;
                u.Draft_Year_Service_Charge_Configuration__c = scc.id; 
            }
            if (scc.General_Fund_Rate_Psqft__c != null && Method == 'Generate'){
                u.Draft_GeneratedGeneralFundServiceCharge__c = u.Internal_Saleable_Area__c * scc.General_Fund_Rate_Psqft__c;
                u.Draft_Year_Service_Charge_Configuration__c = scc.id; 
            } 
            if( Method == 'Delete'){
                u.Draft_GeneratedReserveFundServiceCharge__c = 0; 
                u.Draft_GeneratedGeneralFundServiceCharge__c = 0;
               
            }
            ulisttoupdate.add(u); 
        }
       
        
        list<saveResultWrapper> saveResult = new list<saveResultWrapper>();        
        
        List<Database.SaveResult> updateResults = Database.update(ulisttoupdate, False);
         if( ulisttoupdate.size()>0){
             if(Method == 'Generate'){
            scctoupdate.Status__c = 'Draft Generated';
             }
             if(Method == 'Delete'){
               scctoupdate.Status__c =  'New';
             }
            Scclisttoupdate.add(scctoupdate);
        }
         Update Scclisttoupdate;
        for(Database.SaveResult ds :updateResults){
            if(!ds.isSuccess()){
                saveResultWrapper srw = new saveResultWrapper();
                srw.Id = ds.getId();
                srw.isSuccess = ds.isSuccess();
                srw.error = ds.getErrors()[0].getMessage();
                srw.statusCode = string.valueOf(ds.getErrors()[0].getStatusCode());
                saveResult.add(srw);
            }
        }
        system.debug(saveResult);
        
        return saveResult;
    } 
    @AuraEnabled
       Public Static list<saveResultWrapper> Finiliseservicechargeinvoice(id Servicecongid){
        Service_Charge_Configuration__c scctoupdate = [select id,status__c from Service_Charge_Configuration__c where id =: Servicecongid];
        List<Service_Charge_Configuration__c> Scclisttoupdate = New List<Service_Charge_Configuration__c>();
        List<Unit__C> ulisttoupdate = New List<Unit__C>();
        List<SalesOrderOtherCharges__c> Scllist = New List<SalesOrderOtherCharges__c>();
        Service_Charge_Configuration__c scc = [SELECT id,Project__c,Year_Opening_Date__c,Year__c,No_Of_Invoices_Per_Year__c,Building_Phase__c,Unit_Type__c,Reserve_Fund_Rate_Psqft__c,General_Fund_Rate_Psqft__c from Service_Charge_Configuration__c where id=: Servicecongid];
        String query = 'SELECT id, Project__c,BuildingSectionName__c,Current_Year_Service_Charge_Configuratio__c,Active_Sales_Order__r.Account__C,Status__c,Current_Year_Reserve_Fund_Service_Charge__c,Draft_Generated_Service_Charge__c,Active_Sales_Order__c,UnitType__c,Prior_Year_General_Fund_Service_Charge__c, Current_Year_General_Fund_Service_Charge__c,Draft_GeneratedReserveFundServiceCharge__c,Internal_Saleable_Area__c, Draft_GeneratedGeneralFundServiceCharge__c from unit__C where id !=null';
        If (scc.Project__c != null) {
            query+= ' AND Project__c = \''+ scc.Project__c + '\'';
        } 
        if (scc.Building_Phase__c != null){
            query+= 'AND BuildingSectionName__c = \''+scc.Building_Phase__c + '\'';
        }
        if (scc.Unit_Type__c != null){
            query+= 'AND UnitType__c = \''+scc.Unit_Type__c + '\'';
        }
           system.debug(scc.No_Of_Invoices_Per_Year__c); 
           system.debug(integer.valueof(scc.No_Of_Invoices_Per_Year__c));
           
        integer noofmonths = 12/integer.valueof(scc.No_Of_Invoices_Per_Year__c);
       
        Date currentDate = Date.today();
        Integer currentYear = System.now().year();        
        
        List<Unit__C> Ulist = Database.query(query);
        for(Unit__C U : Ulist){
            U.Prior_Year_General_Fund_Service_Charge__c = u.Current_Year_General_Fund_Service_Charge__c;
            u.Current_Year_General_Fund_Service_Charge__c = u.Draft_GeneratedGeneralFundServiceCharge__c;
            u.Prior_Year_Reserve_Fund_Service_Charge__c = u.Current_Year_Reserve_Fund_Service_Charge__c;
            u.Current_Year_Reserve_Fund_Service_Charge__c = u.Draft_GeneratedReserveFundServiceCharge__c;
            if(u.Current_Year_Service_Charge_Configuratio__c != null){
            u.Prior_Year_Service_Charge_Configuration__c = u.Current_Year_Service_Charge_Configuratio__c;
            }   
            u.Current_Year_Service_Charge_Configuratio__c = scc.Id;
            
           
            ulisttoupdate.add(u); 
            if(u.Status__c == 'Sold'){
                for (Integer i = 0; i < integer.valueof(scc.No_Of_Invoices_Per_Year__c); i++) {
                    integer tempMonths   = noofmonths*i; 
                    SalesOrderOtherCharges__c soc = new SalesOrderOtherCharges__c();
                    Date futureDate =  scc.Year_Opening_Date__c.addMonths(tempMonths);  
                    soc.SalesOrder__c = u.Active_Sales_Order__c;
                    soc.Amount__c = u.Draft_Generated_Service_Charge__c/integer.valueof(scc.No_Of_Invoices_Per_Year__c);
                    soc.Due_Date__c =   futureDate;
                    soc.Account__c = u.Active_Sales_Order__r.Account__C;
                    soc.Installment_Number__c = Decimal.valueof(i+1);
                    soc.ScPercentage__c = 100/integer.valueof(scc.No_Of_Invoices_Per_Year__c);
                    soc.Sc_Amount_General_Fund__c = u.Draft_GeneratedGeneralFundServiceCharge__c/integer.valueof(scc.No_Of_Invoices_Per_Year__c);
                    soc.Sc_Amount_Reserve_Fund__c = u.Draft_GeneratedReserveFundServiceCharge__c/integer.valueof(scc.No_Of_Invoices_Per_Year__c);
                    soc.TypeOfCharge__c = 'Service Charge';
                    soc.Description__c = currentYear +' & '+ scc.Year__c+ ' & '+ (i+1)+ ' & '+ integer.valueof(scc.No_Of_Invoices_Per_Year__c);
                    soc.Service_Charge_Configuration__c = scc.id;
                    Scllist.add(soc); 
                }
            }
        } 
           
        Try{
            
            list<saveResultWrapper> saveResult = new list<saveResultWrapper>(); 
            List<Database.SaveResult> updateResults = Database.update(ulisttoupdate, False);
            List<Database.SaveResult> insertResults = Database.insert(Scllist, False);
             if( ulisttoupdate.size()>0){
            scctoupdate.Status__c = 'Finalized';
            Scclisttoupdate.add(scctoupdate);
        }
            
         Update Scclisttoupdate;
            for(Database.SaveResult ds :updateResults){
                if(!ds.isSuccess()){
                    saveResultWrapper srw = new saveResultWrapper();
                    srw.Id = ds.getId();
                    srw.isSuccess = ds.isSuccess();
                    srw.error = ds.getErrors()[0].getMessage();
                    srw.statusCode = string.valueOf(ds.getErrors()[0].getStatusCode());
                    saveResult.add(srw);
                }
            }
            system.debug(saveResult);
            
            return saveResult;
        }
           Catch(Exception e){
            list<string> sfs = e.getMessage().split(',');
            sfs.remove(0);
            String errorMessage = String.join(sfs, ', ');
            errorMessage = errorMessage.removeEnd(': []');
            throw new Auraexception(errorMessage);
        } 
    } 
    
    public class saveResultWrapper{
        @AuraEnabled public string Id;
        @AuraEnabled public boolean isSuccess;
        @AuraEnabled public string error;
        @AuraEnabled public string statusCode;
        
    }
}