/*****************************************************************************************
Class       : RenewalOfferPDFController
Author      : Kalpana
Description : Controller Class for Generate Renewal Offer PDF.
Created Date: 03/08/26
*****************************************************************************************/
public with sharing class RenewalOfferPDFController {

    public RenewalOfferWrapper wrapper { get; private set; }

    public RenewalOfferPDFController() {

        Id leasingOrderId = ApexPages.currentPage().getParameters().get('id');

        if (leasingOrderId == null) {
            throw new AuraHandledException('Leasing Order Id is required.');
        }

        wrapper = RenewalOfferService.getRenewalOffer(leasingOrderId);
    }
}