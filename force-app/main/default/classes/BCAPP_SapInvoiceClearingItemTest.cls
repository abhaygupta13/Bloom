@isTest
private class BCAPP_SapInvoiceClearingItemTest {

    @isTest static void test_parse_valid_response_returns_items() {
        String body = JSON.serialize(new Map<String, Object>{
            'd' => new Map<String, Object>{
                'InvoiceDetails' => new Map<String, Object>{
                    'results' => new List<Object>{
                        new Map<String, Object>{
                            'Amount' => '150.25',
                            'Bnkname' => 'ABC Bank',
                            'Bukrs' => '1000',
                            'Buyer' => 'ACC-001',
                            'Contract' => 'UNIT-001',
                            'Name' => 'INV-0001',
                            'RefDoc' => 'REF-001',
                            'ReqType' => 'Service',
                            'SFId' => 'a1b2c3',
                            'SFrono' => 'SO-1',
                            'VerifiedDate' => '2024-01-02',
                            'TransType' => 'CARD',
                            'DueDate' => '2024-01-10',
                            'FiscalYear' => '2024',
                            'Invoice' => 'INV-0001',
                            'MsgTxt' => 'OK',
                            'Msgtyp' => 'S',
                            'ProfitCenter' => 'PC01',
                            'Status' => 'Paid',
                            'TransCharges' => '0',
                            'TransChargeVat' => '0'
                        },
                        new Map<String, Object>{
                            'Amount' => '75.00',
                            'Buyer' => 'ACC-002',
                            'Invoice' => 'INV-0002'
                        }
                    }
                }
            }
        });

        List<BCAPP_SapInvoiceClearingItem> rows = BCAPP_SapInvoiceClearingItem.parseFromResponse(body);
        System.assertEquals(2, rows.size());
        System.assertEquals('150.25', rows[0].Amount);
        System.assertEquals('ABC Bank', rows[0].Bnkname);
        System.assertEquals('INV-0001', rows[0].Invoice);
        System.assertEquals('75.00', rows[1].Amount);
        System.assertEquals('INV-0002', rows[1].Invoice);
    }

    @isTest static void test_parse_missing_nodes_returns_empty() {
        // No d.InvoiceDetails
        String body = JSON.serialize(new Map<String, Object>{ 'd' => new Map<String, Object>() });
        List<BCAPP_SapInvoiceClearingItem> rows = BCAPP_SapInvoiceClearingItem.parseFromResponse(body);
        System.assertEquals(0, rows.size());
    }

    @isTest static void test_parse_blank_response_returns_empty() {
        System.assertEquals(0, BCAPP_SapInvoiceClearingItem.parseFromResponse(null).size());
        System.assertEquals(0, BCAPP_SapInvoiceClearingItem.parseFromResponse('').size());
        System.assertEquals(0, BCAPP_SapInvoiceClearingItem.parseFromResponse('   ').size());
    }

    @isTest static void test_parse_invalid_json_is_swallowed() {
        // Invalid JSON should not throw (caught in method) and return empty list
        List<BCAPP_SapInvoiceClearingItem> rows = BCAPP_SapInvoiceClearingItem.parseFromResponse('{ not-json }');
        System.assertEquals(0, rows.size());
    }

    @isTest static void test_parse_partial_fields_allow_nulls() {
        String body = JSON.serialize(new Map<String, Object>{
            'd' => new Map<String, Object>{
                'InvoiceDetails' => new Map<String, Object>{
                    'results' => new List<Object>{ new Map<String, Object>{ 'Invoice' => 'INV-ONLY' } }
                }
            }
        });
        List<BCAPP_SapInvoiceClearingItem> rows = BCAPP_SapInvoiceClearingItem.parseFromResponse(body);
        System.assertEquals(1, rows.size());
        System.assertEquals('INV-ONLY', rows[0].Invoice);
        System.assertEquals(null, rows[0].Amount);
        System.assertEquals(null, rows[0].Bnkname);
    }
}