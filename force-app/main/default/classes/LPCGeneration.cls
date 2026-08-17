/***
Class       : LPCGeneration
Author      : Smaartt
Description : 
TestClass   : LPCGenerationTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.          V1.0              29/08/23           Initial Version 
****************************************************************************************************************/


public class LPCGeneration 
{
    //LPCGeneration.genLpcs('Casares', 'BL-CAS-C-TH-202-230821', 'Y')
    //LPCGeneration.genLpcssalesorder('BL-CAS-C-TH-202-230821')
    public static void genLpcs(String Project, String CreateChargeFlag) 
    {
        List<InstallmentLines__c> InstLinesqrylst = 
            [SELECT id, Name, InstallmentNumber__c, SalesOrder__r.ProjectName__c, SalesOrder__r.Unit__r.BuildingSectionName__c, SalesOrder__r.Unit__r.UnitNumber__c, SalesOrder__r.Name, SalesOrder__r.AccountName__c,SalesOrder__r.Account__c, SalesOrder__r.Opportunity__c,
                GracePeriod__c, CutOffDate__c, LPCCutOffAmt__c, MinInvAmtrem__c, LPCAmount__c, LPCAmountGen__c, LPCAmounttoGen__c, PrevLPCAmount__c,
                RevisedDate__c, InstallmentDate__c, LPCRate__c, InstallmentAmount__c
                FROM InstallmentLines__c WHERE SalesOrder__r.Status__c = 'Sold' AND  SalesOrder__r.ProjectName__c = :Project
                AND PendingAmount__c > 100 //MinInvAmtrem__c
                AND InstallmentDate__c < TODAY //().addDays(Integer.valueOf(GracePeriod_cc) should also take into consideration Revised Due Date
                ORDER BY SalesOrder__r.ProjectName__c, SalesOrder__r.Unit__r.BuildingSectionName__c, SalesOrder__r.Unit__r.UnitNumber__c ]; 
   
        List<SalesOrderOtherCharges__c> SOOtherChargeslst = new List<SalesOrderOtherCharges__c>();
        List<InstallmentLines__c> UpdInstLinesLPClst = new List<InstallmentLines__c>();
        Decimal LPCCalculated = 0;
        Decimal LPCToCreate = 0;
        Decimal LPCAmtGenerated = 0;
        Decimal LPCAmtToGenerate = 0;
        Integer TotalDueDays = 0;
        integer UpdateLPCBackFlag = 0;
        integer InsertLPCInOthChgs = 0;
        Date TrxDate = Null;
        System.debug(InstLinesqrylst);
        system.debug('genLpcs: before loop');
        // Loop through installment invoices
        for (InstallmentLines__c Installmentlinesrec : InstLinesqrylst) 
        {   
            system.debug('genLpcs: inside loop ' + Installmentlinesrec.name);
            TrxDate = Installmentlinesrec.RevisedDate__c != null ? Installmentlinesrec.RevisedDate__c : Installmentlinesrec.InstallmentDate__c ;
            TotalDueDays =  (system.today()).daysBetween(Date.valueOf(TrxDate));//(System.today() - TrxDate).days;
            LPCCalculated = 0;
            LPCToCreate = 0;
            LPCAmtGenerated = 0;
            system.debug('genLpcs: TotalDueDays ' + TotalDueDays);
            TotalDueDays = -1 * TotalDueDays ;
            system.debug('genLpcs: TotalDueDays ' + TotalDueDays);
            
            if (TotalDueDays > Installmentlinesrec.GracePeriod__c)
            {
                system.debug('genLpcs: inside loop 1');
                LPCCalculated = 0 ;
                LPCCalculated = calcLpcForInv(Installmentlinesrec.id, TrxDate, TotalDueDays, Installmentlinesrec.GracePeriod__c, Installmentlinesrec.CutOffDate__c, Installmentlinesrec.LPCCutOffAmt__c, Installmentlinesrec.MinInvAmtrem__c, Installmentlinesrec.LPCRate__c, Installmentlinesrec.InstallmentAmount__c);
                LPCToCreate = LPCCalculated.setScale(2) - ReplaceNull(Installmentlinesrec.LPCAmountGen__c, 0);
                System.debug('lpctocrate'+LPCToCreate); 
                 System.debug('CreateChargeFlag'+CreateChargeFlag); 
                if (CreateChargeFlag != 'N' && LPCToCreate > 0 && LPCToCreate > Installmentlinesrec.LPCCutOffAmt__c) 
                {
                    system.debug('genLpcs: inside loop 2');
                    SOOtherChargeslst.add(new 	SalesOrderOtherCharges__c(TypeOfCharge__c='Late Payment Charges', SalesOrder__c=Installmentlinesrec.SalesOrder__c, Account__c=Installmentlinesrec.SalesOrder__r.Account__c, Opportunity__c=Installmentlinesrec.SalesOrder__r.Opportunity__c, 
                    Due_Date__c=System.today(), Amount__c=LPCToCreate, Installment_Line__c = Installmentlinesrec.id));
                    LPCAmtGenerated = Installmentlinesrec.LPCAmountGen__c + LPCToCreate;
                    LPCAmtToGenerate = 0;
                    InsertLPCInOthChgs = 1;
                }
                else
                {
                    system.debug('inside loop 3');
                    LPCAmtGenerated = Installmentlinesrec.LPCAmountGen__c;
                    LPCAmtToGenerate = LPCToCreate;
                    UpdateLPCBackFlag = 1;
                }
                if (LPCToCreate > 0)
                {
                    UpdateLPCBackFlag = 1;
                    system.debug('genLpcs: inside loop 4');
                    UpdInstLinesLPClst.add(new InstallmentLines__c(id=Installmentlinesrec.id, LPCAmount__c=LPCCalculated, LPCAmountGen__c=LPCAmtGenerated, LPCAmounttoGen__c=LPCAmtToGenerate, PrevLPCAmount__c=Installmentlinesrec.LPCAmount__c));
                }
            }
        }
        if (InsertLPCInOthChgs > 0) {
            system.debug('genLpcs: outside loop insert');
            insert SOOtherChargeslst;
        }
        if (UpdateLPCBackFlag > 0) {
            system.debug('genLpcs: outside loop update');
            update UpdInstLinesLPClst;
        }
    }
    
    //@InvocableMethod(label='Sales Order Generate LPC' description='Sales Order Generate LPC')
    @AuraEnabled
    public static void genLpcssalesorder(List<String> OrderNumber) 
    {
        System.debug(OrderNumber);
        List<InstallmentLines__c> InstLinesqrylst = 
            [SELECT id, Name, InstallmentNumber__c, SalesOrder__r.ProjectName__c, SalesOrder__r.Unit__r.BuildingSectionName__c, SalesOrder__r.Unit__r.UnitNumber__c, SalesOrder__r.Name, SalesOrder__r.AccountName__c,SalesOrder__r.Account__c, SalesOrder__r.Opportunity__c,
                GracePeriod__c, CutOffDate__c, LPCCutOffAmt__c, MinInvAmtrem__c, LPCAmount__c, LPCAmountGen__c, LPCAmounttoGen__c, PrevLPCAmount__c,
                RevisedDate__c, InstallmentDate__c, LPCRate__c, InstallmentAmount__c
                FROM InstallmentLines__c WHERE SalesOrder__r.Status__c = 'Sold' 
                AND SalesOrder__r.Name = :OrderNumber[0] 
                AND PendingAmount__c > 50 //MinInvAmtrem__c
                AND InstallmentDate__c < TODAY //().addDays(Integer.valueOf(GracePeriod_cc) should also take into consideration Revised Due Date
                ORDER BY SalesOrder__r.ProjectName__c, SalesOrder__r.Unit__r.BuildingSectionName__c, SalesOrder__r.Unit__r.UnitNumber__c ]; 
              System.debug(InstLinesqrylst);
        List<SalesOrderOtherCharges__c> SOOtherChargeslst = new List<SalesOrderOtherCharges__c>();
        List<InstallmentLines__c> UpdInstLinesLPClst = new List<InstallmentLines__c>();
        Decimal LPCCalculated = 0;
        Decimal LPCToCreate = 0;
        Decimal LPCAmtGenerated = 0;
        Decimal LPCAmtToGenerate = 0;
        Integer TotalDueDays = 0;
        integer UpdateLPCBackFlag = 0;
        integer InsertLPCInOthChgs = 0;
        Date TrxDate = Null;
        system.debug('genLpcs: before loop');
        // Loop through installment invoices
        for (InstallmentLines__c Installmentlinesrec : InstLinesqrylst) 
        {   
            system.debug('genLpcs: inside loop ' + Installmentlinesrec.name);
            TrxDate = Installmentlinesrec.RevisedDate__c != null ? Installmentlinesrec.RevisedDate__c : Installmentlinesrec.InstallmentDate__c ;
            TotalDueDays =  (system.today()).daysBetween(Date.valueOf(TrxDate));//(System.today() - TrxDate).days;
            LPCCalculated = 0;
            LPCToCreate = 0;
            LPCAmtGenerated = 0;
            system.debug('genLpcs: TotalDueDays ' + TotalDueDays);
            TotalDueDays = -1 * TotalDueDays ;
            system.debug('genLpcs: TotalDueDays ' + TotalDueDays);
            
            if (TotalDueDays > Installmentlinesrec.GracePeriod__c)
            {
                system.debug('genLpcs: inside loop 1');
                LPCCalculated = 0 ;
                LPCCalculated = calcLpcForInv(Installmentlinesrec.id, TrxDate, TotalDueDays, Installmentlinesrec.GracePeriod__c, Installmentlinesrec.CutOffDate__c, Installmentlinesrec.LPCCutOffAmt__c, Installmentlinesrec.MinInvAmtrem__c, Installmentlinesrec.LPCRate__c, Installmentlinesrec.InstallmentAmount__c);
                LPCToCreate = LPCCalculated.setScale(2) - ReplaceNull(Installmentlinesrec.LPCAmountGen__c, 0);
                            
                if (LPCToCreate > 0) 
                {
                    system.debug('genLpcs: inside loop 2');
                    SOOtherChargeslst.add(new 	SalesOrderOtherCharges__c(TypeOfCharge__c='Late Payment Charges', SalesOrder__c=Installmentlinesrec.SalesOrder__c, Account__c=Installmentlinesrec.SalesOrder__r.Account__c, Opportunity__c=Installmentlinesrec.SalesOrder__r.Opportunity__c, 
                        Due_Date__c=System.today(), Amount__c=LPCToCreate, Installment_Line__c = Installmentlinesrec.id));
                        LPCAmtGenerated = ReplaceNull(Installmentlinesrec.LPCAmountGen__c, 0) + LPCToCreate;
                        LPCAmtToGenerate = 0;
                    system.debug('genLpcs: inside loop 4');
                    UpdInstLinesLPClst.add(new InstallmentLines__c(id=Installmentlinesrec.id, LPCAmount__c=LPCCalculated.setScale(2), LPCAmountGen__c=LPCAmtGenerated, LPCAmounttoGen__c=LPCAmtToGenerate, PrevLPCAmount__c=Installmentlinesrec.LPCAmount__c));
                    InsertLPCInOthChgs = 1;
                }
            }
        }
        if (InsertLPCInOthChgs > 0) 
        {
            system.debug('genLpcs: outside loop insert');
            insert SOOtherChargeslst;
            system.debug('genLpcs: outside loop update');
            update UpdInstLinesLPClst;
        }
    }
    
    public static Decimal calcLpcForInv(id InstallmentNumberid, Date DueDate, Integer DayssinceDue, Decimal GracePeriod, Date CutOffDate, Decimal LPCCutOffAmt, Decimal MinInvAmtrem, Decimal LPCRate, Decimal InstallmentAmt) 
    {
        Decimal LPCAmt = 0;
        Decimal TotalLPCAmt = 0;
        Date ReceiptMaturityDate = Null;
        Date ReceiptDate = Null;
        Integer TotalRemDays = 0;
        Date TrxDate = Null;
        Date NewDueDate = Null;
        Date CalcTillDate = null;
        Date LastReceiptDate = null;
        Integer RemNoofDays = 0;
        Decimal RemAmount = null ;
        Integer i = 0;

        system.debug('calcLpcForInv: start');
        system.debug('calcLpcForInv: InstallmentNumberid ' + InstallmentNumberid + ' DueDate' + DueDate + ' DayssinceDue ' + DayssinceDue) ;
        system.debug('calcLpcForInv: GracePeriod ' + GracePeriod + ' CutOffDate ' + CutOffDate + ' LPCCutOffAmt ' + LPCCutOffAmt);
        system.debug('calcLpcForInv: MinInvAmtrem ' + MinInvAmtrem + ' LPCRate ' + LPCRate + ' InstallmentAmt ' + InstallmentAmt);

        List<ReceiptAllocation__c> lstReceiptAllocations = getreceiptallocdetails(InstallmentNumberid);
        System.debug(lstReceiptAllocations);
        system.debug('calcLpcForInv: call to get receipt alloc done');
        if (!lstReceiptAllocations.isEmpty()) {
            TotalLPCAmt = 0;
            RemAmount = InstallmentAmt;
            system.debug('lstReceiptAllocations.size'+lstReceiptAllocations);
        }
        else
        {   system.debug('lstReceiptAllocations.size'+lstReceiptAllocations);
            for (ReceiptAllocation__c vallocrec : lstReceiptAllocations)
            {
                system.debug('lstReceiptAllocations.size'+lstReceiptAllocations);
                system.debug('calcLpcForInv: inside loop');
                ReceiptMaturityDate = vallocrec.ReceiptMaturityDate__c;
                ReceiptDate = vallocrec.ReceiptMaturityDate__c != null ? vallocrec.ReceiptMaturityDate__c : vallocrec.ReceiptDate__c ;
                TotalRemDays = (system.today()).daysBetween(Date.valueOf(DueDate));
                NewDueDate = DueDate.addDays(Integer.valueOf(GracePeriod));
                if (NewDueDate >= ReceiptDate)
                {
                    TrxDate = NewDueDate;
                }
                else
                {
                    TrxDate = DueDate;
                }
                system.debug('calcLpcForInv: inside loop 1');
                TrxDate = LastReceiptDate != null ? LastReceiptDate : TrxDate;
                CalcTillDate = vallocrec.ReceiptMaturityDate__c != null ? vallocrec.ReceiptMaturityDate__c : vallocrec.ReceiptDate__c;
                if (CalcTillDate > System.today()) 
                {
                    CalcTillDate = System.today();
                }
                system.debug('calcLpcForInv: inside loop 2');
                TotalRemDays = (system.today()).daysBetween(Date.valueOf(DueDate));
                RemNoofDays = (CalcTillDate.daysBetween(TrxDate));
                
                if (i == 0) {
                    RemAmount = InstallmentAmt;
                }
                LPCAmt = 0;
                if (RemNoofDays > 0) 
                {
                    if (RemAmount > MinInvAmtrem) 
                    {
                        LPCAmt = RemAmount * RemNoofDays * LPCRate / 36500;
                    } 
                    else 
                    {
                        LPCAmt = 0;
                    }
                } 
                else 
                {
                    System.debug('Rem No of Days ' + RemNoofDays + ' is less than 0');
                    LPCAmt = 0;
                }
                system.debug('calcLpcForInv: inside loop 3');
                TotalLPCAmt += LPCAmt;
                RemAmount -= vallocrec.AmountApplied__c != null ? vallocrec.AmountApplied__c : 0;
                if (RemNoofDays > 0) 
                {
                    LastReceiptDate = vallocrec.ReceiptMaturityDate__c != null ? vallocrec.ReceiptMaturityDate__c : vallocrec.ReceiptDate__c;
                }
                system.debug('calcLpcForInv: inside loop 4');
                
                i++;
            }            
        }
        //For calculation from Last Receipt date to today or if no allocations from trx date to today
        CalcTillDate = LastReceiptDate != null ? LastReceiptDate : DueDate; //TrxDate;
        if (CalcTillDate > System.today()) 
        { //This condition will never happen as it is already taken care in SOQL query
            CalcTillDate = System.today();
        }
        system.debug('calcLpcForInv: inside loop CalcTillDate' + CalcTillDate);
        RemNoofDays = (system.today()).daysBetween(Date.valueOf(CalcTillDate));
        RemNoofDays = -1 * RemNoofDays;
        RemAmount = RemAmount != null ? RemAmount : InstallmentAmt;
        system.debug('calcLpcForInv: inside loop RemNoofDays' + RemNoofDays + ' RemAmount ' + RemAmount);        
        LPCAmt = 0;

        if (RemNoofDays > 0 && RemAmount > 0 && RemAmount > MinInvAmtrem) 
        {
            LPCAmt = RemAmount * RemNoofDays * 12 / 36500;
            System.debug('New LPCAmt ' + LPCAmt);
        } else 
        {
            LPCAmt = 0;
        }
        
        if (LPCAmt > 0) 
        {
            TotalLPCAmt += LPCAmt;
        }
        
        System.debug('returnReceiptModel TotalLPCAmt' + TotalLPCAmt);

        return TotalLPCAmt;
    }
        
    public static List<ReceiptAllocation__c> getReceiptAllocDetails(Id instId) 
    {
        system.debug('getreceiptallocdetails: before call');
        String query = 'select name, AmountApplied__c, InstallmentLine__c, InstallmentNumberOrChargeType__c, InstallmentLine__r.InstallmentAmount__c, InstallmentLine__r.PendingAmount__c, InstallmentLine__r.InstallmentDate__c, InstallmentLine__r.RevisedDate__c, ReceiptMaturityDate__c, ReceiptDate__c, ReceiptAcknowledgement__c from ReceiptAllocation__c Where InstallmentLine__c = :instId and AmountApplied__c <> 0' ;
        List<ReceiptAllocation__c> LstReceiptAllocations = Database.Query(query);
        system.debug('getreceiptallocdetails: after call'+LstReceiptAllocations);
        return LstReceiptAllocations;
    }    

    public static Decimal ReplaceNull(Decimal value, Decimal replacevalue) 
    {
        if (value == null) value = replacevalue;
        return value;
    }
}