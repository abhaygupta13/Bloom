public class BCAPP_SapInvoiceClearingItem {
    public String Amount;
    public String Bnkname;
    public String Bukrs;
    public String Buyer;
    public String Contract;
    public String Name;
    public String RefDoc;
    public String ReqType;
    public String SFId;
    public String SFrono;
    public String VerifiedDate;
    public String TransType;
    public String DueDate;
    public String FiscalYear;
    public String Invoice;
    public String MsgTxt;
    public String Msgtyp;
    public String ProfitCenter;
    public String Status;
    public String TransCharges;
    public String TransChargeVat;

    public static List<BCAPP_SapInvoiceClearingItem> parseFromResponse(String responseBody) {
        if (String.isBlank(responseBody)) return new List<BCAPP_SapInvoiceClearingItem>();
        List<BCAPP_SapInvoiceClearingItem> out = new List<BCAPP_SapInvoiceClearingItem>();
        try {
            Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
            Map<String, Object> d    = (Map<String, Object>) root.get('d');
            if (d == null) return out;
            Map<String, Object> invDetails = (Map<String, Object>) d.get('InvoiceDetails');
            if (invDetails == null) return out;
            List<Object> results = (List<Object>) invDetails.get('results');
            if (results == null) return out;

            for (Object o : results) {
                Map<String, Object> m = (Map<String, Object>) o;
                BCAPP_SapInvoiceClearingItem x = new BCAPP_SapInvoiceClearingItem();
                x.Amount         = (String) m.get('Amount');
                x.Bnkname        = (String) m.get('Bnkname');
                x.Bukrs          = (String) m.get('Bukrs');
                x.Buyer          = (String) m.get('Buyer');
                x.Contract       = (String) m.get('Contract');
                x.Name           = (String) m.get('Name');
                x.RefDoc         = (String) m.get('RefDoc');
                x.ReqType        = (String) m.get('ReqType');
                x.SFId           = (String) m.get('SFId');
                x.SFrono         = (String) m.get('SFrono');
                x.VerifiedDate   = (String) m.get('VerifiedDate');
                x.TransType      = (String) m.get('TransType');
                x.DueDate        = (String) m.get('DueDate');
                x.FiscalYear     = (String) m.get('FiscalYear');
                x.Invoice        = (String) m.get('Invoice');
                x.MsgTxt         = (String) m.get('MsgTxt');
                x.Msgtyp         = (String) m.get('Msgtyp');
                x.ProfitCenter   = (String) m.get('ProfitCenter');
                x.Status         = (String) m.get('Status');
                x.TransCharges   = (String) m.get('TransCharges');
                x.TransChargeVat = (String) m.get('TransChargeVat');
                out.add(x);
            }
        } catch (Exception e) {
            // swallow per logging policy, return what we have
        }
        return out;
    }
}